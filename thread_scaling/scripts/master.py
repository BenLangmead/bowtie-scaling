"""
Master script for setting up thread-scaling experiments with Bowtie 2.
"""

from __future__ import print_function
import os
import shutil
import argparse
import subprocess
import tempfile


def mkdir_quiet(dr):
    # Create output directory if needed
    import errno
    if not os.path.isdir(dr):
        try:
            os.makedirs(dr)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise


def get_num_cores():
    p = subprocess.Popen("grep 'processor\s*:' /proc/cpuinfo | wc -l", shell=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()
    assert len(err) == 0
    ncores = int(out.split()[0])
    return ncores


def get_num_nodes():
    p = subprocess.Popen('numactl -H | grep available', shell=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()
    assert len(err) == 0
    nnodes = int(out.split()[1])
    return nnodes


def make_bt2_version(name, preproc):
    ret = os.system("make -C %s %s bowtie2-align-s" % (name, preproc))
    if ret != 0:
        raise RuntimeError('non-zero return from make for bt2 version "%s"' % name)


def install_bt2_version(name, url, branch, preproc):
    ret = os.system("git clone -b %s %s %s" % (branch, url, name))
    if ret != 0:
        raise RuntimeError('non-zero return from git clone for bt2 version "%s"' % name)
    make_bt2_version(name, preproc)


def get_configs(config_fn):
    with open(config_fn) as fh:
        for ln in fh:
            if len(ln.split('\t')) == 0 or ln.startswith('#'):
                continue
            if len(ln.split('\t')) == 3:
                name, branch, preproc = ln.split('\t')
                yield name, branch, preproc, None
            else:
                name, branch, preproc, args = ln.split('\t')
                yield name, branch, preproc, args


def verify_index(basename):
    def _ext_exists(ext):
        return os.path.exists(basename + ext)
    return _ext_exists('.1.bt2') and\
           _ext_exists('.2.bt2') and\
           _ext_exists('.3.bt2') and\
           _ext_exists('.4.bt2') and\
           _ext_exists('.rev.1.bt2') and\
           _ext_exists('.rev.2.bt2')


def verify_reads(basename):
    return True


def gen_thread_series(args, ncpus):
    if args.nthread_series is not None:
        series = map(int, args.nthread_series.split(','))
    elif args.nthread_pct_series is not None:
        pcts = map(lambda x: float(x)/100.0, args.nthread_pct_series.split(','))
        series = map(lambda x: int(round(x * ncpus)), pcts)
    else:
        series = [ncpus]
    return series


def count_reads(fns):
    nlines = 0
    for fn in fns:
        with open(fn) as fh:
            for _ in fh:
                nlines += 1
    return nlines / 4


def cat(fns, dest_fn, n):
    with open(dest_fn, 'w') as ofh:
        for _ in range(n):
            for fn in fns:
                with open(fn) as fh:
                    for ln in fh:
                        ofh.write(ln)


def go(args):
    nnodes, ncpus = get_num_nodes(), get_num_cores()
    print('# NUMA nodes = %d' % nnodes)
    print('# CPUs = %d' % ncpus)

    print('Setting up Bowtie 2 binaries')
    for name, branch, preproc, bt2_args in get_configs(args.config):
        if name == 'name' and branch == 'branch':
            continue  # skip header line
        build, pull = False, False
        if os.path.exists(name) and args.force:
            print('  Removing existing "%s" subdir because of --force' % name)
            shutil.rmtree(name)
            build = True
        elif os.path.exists(name):
            pull = True
        elif not os.path.exists(name):
            build = True

        if pull:
            print('  Pulling "%s"' % name)
            os.system('cd %s && git pull' % name)
            make_bt2_version(name, preproc)
        elif build:
            print('  Building "%s"' % name)
            install_bt2_version(name, args.repo, branch, preproc)

    print('Checking that index files exist')
    if not verify_index(args.index):
        raise RuntimeError('Could not verify index files')

    print('Checking that reads exist')
    if not verify_reads(args.reads):
        raise RuntimeError('Could not verify reads file(s)')

    print('Generating thread series')
    series = gen_thread_series(args, ncpus)
    print('  series = %s' % str(series))

    print('Counting reads')
    nreads = count_reads([args.reads])
    nreads_full = nreads * max(series)
    print('  counted %d reads, %d for a full series w/ %d threads' % (nreads, nreads_full, max(series)))

    tmpdir = tempfile.mkdtemp()
    tmpfile = os.path.join(tmpdir, "reads.fq")
    print('Concatenating new read file and storing in "%s"' % tmpfile)
    cat([args.reads], tmpfile, max(series))

    sensitivities = [('--sensitive', 's')]

    print('Creating output directory "%s"' % args.output_dir)
    mkdir_quiet(args.output_dir)

    print('Generating bowtie2 commands')
    for name, branch, preproc, bt2_args in get_configs(args.config):
        for nthreads in series:
            for sens, sens_short in sensitivities:
                cmd = ['%s/bowtie2-align-s' % name]
                cmd.extend(['-p', str(nthreads)])
                cmd.append(sens)
                cmd.extend(['-u', str(nreads * nthreads)])
                cmd.extend(['-S', os.path.join(tmpdir, '%s_%s_%d.sam' % (name, sens_short, nthreads))])
                cmd.extend(['-x', args.index])
                cmd.extend(['-U', tmpfile])
                cmd.extend(['>', os.path.join(args.output_dir, '%s_%s_%d.sam' % (name, sens_short, nthreads))])
                if len(bt2_args) > 0:
                    cmd.extend(bt2_args.split())
                print(' '.join(cmd))


if __name__ == '__main__':

    # Output-related options
    parser = argparse.ArgumentParser(description='Set up thread scaling experiments.')

    parser.add_argument('--nthread-series', metavar='int,int,...', type=str, required=False,
                        help='Series of comma-separated ints giving the number of threads to use')
    parser.add_argument('--nthread-pct-series', metavar='pct,pct,...', type=str, required=False,
                        help='Series of comma-separated percentages giving the number of threads to use as fraction of max # threads')
    parser.add_argument('--config', metavar='pct,pct,...', type=str, required=True,
                        help='Specifies path to config file giving Bowtie 2 configuration short-names, branch names, compilation macros, and command-line args')
    parser.add_argument('--repo', metavar='url', type=str, default="git@github.com:BenLangmead/bowtie2.git",
                        help='Path to bowtie 2 repo, which we clone for each bt2 version we test')
    parser.add_argument('--sensitivities', metavar='level,level,...', type=str, required=False,
                        help='Series of comma-separated sensitivity levels, each from {vf, vfl, f, fl, s, sl, vs, vsl}.  Default: just --sensitive.')
    parser.add_argument('--index', metavar='bt2_index_basename', type=str, required=True,
                        help='Path to bowtie 2 index; omit final ".1.bt2"')
    parser.add_argument('--reads', metavar='int,int,...', type=str, required=True,
                        help='Path to reads file to use.  Will concatenate multiple copies according to # threads.')
    parser.add_argument('--tempdir', metavar='path', type=str, required=False,
                        help='Picks a path for temporary files.')
    parser.add_argument('--output-dir', metavar='path', type=str, required=True,
                        help='Directory to put thread timings in.')
    parser.add_argument('--force', action='store_const', const=True, default=False,
                        help='Overwrite Bowtie 2 binaries that already exist')
    parser.add_argument('--dry-run', action='store_const', const=True, default=False,
                        help='Just verify that bt2 jobs can be run, then print out bt2 commands without running them')

    go(parser.parse_args())
