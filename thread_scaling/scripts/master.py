"""
Master script for setting up thread-scaling experiments with Bowtie 2.
"""

from __future__ import print_function
import os
import sys
import shutil
import argparse
import subprocess
import tempfile


def mkdir_quiet(dr):
    """ Create directories needed to ensure 'dr' exists; no complaining """
    import errno
    if not os.path.isdir(dr):
        try:
            os.makedirs(dr)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise


def get_num_cores():
    """ Get # cores on this machine, assuming we have /proc/cpuinfo """
    p = subprocess.Popen("grep 'processor\s*:' /proc/cpuinfo | wc -l", shell=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()
    assert len(err) == 0
    ncores = int(out.split()[0])
    return ncores


def get_num_nodes():
    """ Get # NUMA nodes on this machine, assuming numactl is available """
    p = subprocess.Popen('numactl -H | grep available', shell=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()
    assert len(err) == 0
    nnodes = int(out.split()[1])
    return nnodes


def make_bt2_version(name, preproc):
    """ Builds bowtie2-align-s target in specified clone """
    cmd = "make -C %s %s bowtie2-align-s" % (name, preproc)
    print('  command: ' + cmd, file=sys.stderr)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('non-zero return from make for bt2 version "%s"' % name)


def install_bt2_version(name, url, branch, preproc):
    """ Clones appropriate branch """
    cmd = "git clone -b %s %s %s" % (branch, url, name)
    print('  command: ' + cmd, file=sys.stderr)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('non-zero return from git clone for bt2 version "%s"' % name)
    make_bt2_version(name, preproc)


def get_configs(config_fn):
    """ Generator that parses and yields the lines of the config file """
    with open(config_fn) as fh:
        for ln in fh:
            toks = ln.split('\t')
            if toks[0] == 'name' and toks[1] == 'branch':
                continue
            if len(toks) == 0 or ln.startswith('#'):
                continue
            if len(toks) == 3:
                name, branch, preproc = toks
                yield name, branch, preproc.rstrip(), None
            else:
                name, branch, preproc, args = toks
                yield name, branch, preproc, args.rstrip()


def verify_index(basename):
    """ Check that all bt2 index files exist """
    def _ext_exists(ext):
        return os.path.exists(basename + ext)
    return _ext_exists('.1.bt2') and\
           _ext_exists('.2.bt2') and\
           _ext_exists('.3.bt2') and\
           _ext_exists('.4.bt2') and\
           _ext_exists('.rev.1.bt2') and\
           _ext_exists('.rev.2.bt2')


def verify_reads(fns):
    """ Check that files exist """
    for fn in fns:
        if not os.path.exists(fn) or not os.path.isfile(fn):
            raise RuntimeError('No such reads file as "%s"' % fn)
    return True


def gen_thread_series(args, ncpus):
    """ Generate list with the # threads to use in each experiment """
    if args.nthread_series is not None:
        series = map(int, args.nthread_series.split(','))
    elif args.nthread_pct_series is not None:
        pcts = map(lambda x: float(x)/100.0, args.nthread_pct_series.split(','))
        series = map(lambda x: int(round(x * ncpus)), pcts)
    else:
        series = [ncpus]
    return series


def count_reads(fns):
    """ Count the total number of reads in one or more fastq files """
    nlines = 0
    for fn in fns:
        with open(fn) as fh:
            for _ in fh:
                nlines += 1
    return nlines / 4


def cat(fns, dest_fn, n):
    """ Concatenate one or more read files into one output file """
    with open(dest_fn, 'wb') as ofh:
        for _ in range(n):
            for fn in fns:
                with open(fn,'rb') as fh:
                    shutil.copyfileobj(fh, ofh, 1024*1024*10)


def go(args):
    nnodes, ncpus = get_num_nodes(), get_num_cores()
    print('# NUMA nodes = %d' % nnodes, file=sys.stderr)
    print('# CPUs = %d' % ncpus, file=sys.stderr)

    sensitivity_map = {'vs': '--very-sensitive',
                       'vsl': '--very-sensitive-local',
                       's': '--sensitive',
                       'sl': '--sensitive-local',
                       'f': '--fast',
                       'fl': '--fast-local',
                       'vf': '--very-fast',
                       'vfs': '--very-fast-local'}

    print('Setting up Bowtie 2 binaries', file=sys.stderr)
    for name, branch, preproc, bt2_args in get_configs(args.config):
        if name == 'name' and branch == 'branch':
            continue  # skip header line
        build, pull = False, False
        if os.path.exists(name) and args.force_builds:
            print('  Removing existing "%s" subdir because of --force' % name, file=sys.stderr)
            shutil.rmtree(name)
            build = True
        elif os.path.exists(name):
            pull = True
        elif not os.path.exists(name):
            build = True

        if pull:
            print('  Pulling "%s"' % name, file=sys.stderr)
            os.system('cd %s && git pull' % name)
            make_bt2_version(name, preproc)
        elif build:
            print('  Building "%s"' % name, file=sys.stderr)
            install_bt2_version(name, args.repo, branch, preproc)

    print('Checking that index files exist', file=sys.stderr)
    if not verify_index(args.index):
        raise RuntimeError('Could not verify index files')

    print('Checking that reads exist', file=sys.stderr)
    if not verify_reads([args.reads]):
        raise RuntimeError('Could not verify reads file(s)')

    print('Generating thread series', file=sys.stderr)
    series = gen_thread_series(args, ncpus)
    print('  series = %s' % str(series))

    print('Counting reads', file=sys.stderr)
    nreads = count_reads([args.reads])
    nreads_full = nreads * max(series)
    print('  counted %d reads, %d for a full series w/ %d threads' % (nreads, nreads_full, max(series)), file=sys.stderr)

    tmpdir = args.tempdir
    if tmpdir is None:
        tmpdir = tempfile.mkdtemp()
    if not os.path.exists(tmpdir):
        mkdir_quiet(tmpdir)
    if not os.path.isdir(tmpdir):
        raise RuntimeError('Temporary directory isn\'t a directory: "%s"' % tmpdir)

    tmpfile = os.path.join(tmpdir, "reads.fq")
    print('Concatenating new read file and storing in "%s"' % tmpfile, file=sys.stderr)
    cat([args.reads], tmpfile, max(series))

    sensitivities = zip(map(sensitivity_map.get, args.sensitivities), args.sensitivities)
    print('Generating sensitivity series: "%s"' % str(sensitivities), file=sys.stderr)

    print('Creating output directory "%s"' % args.output_dir, file=sys.stderr)
    mkdir_quiet(args.output_dir)

    print('Generating bowtie2 commands', file=sys.stderr)

    # iterate over Bowtie 2 configurations
    for name, branch, preproc, bt2_args in get_configs(args.config):
        odir_outer = os.path.join(args.output_dir, name)
        # iterate over sensitivity levels
        for sens, sens_short in sensitivities:
            odir = os.path.join(odir_outer, sens[2:])
            print('  Creating output directory "%s"' % odir, file=sys.stderr)
            mkdir_quiet(odir)
            # iterate over numbers of threads
            for nthreads in series:
                # Compose Bowtie 2 command
                runname = '%s_%s_%d' % (name, sens_short, nthreads)
                stdout_ofn = os.path.join(odir, '%d.txt' % nthreads)
                sam_ofn = os.path.join(tmpdir if args.sam_temporary else odir, '%s.sam' % runname)
                cmd = ['%s/bowtie2-align-s' % name]
                cmd.extend(['-p', str(nthreads)])
                cmd.append(sens)
                cmd.extend(['-u', str(nreads * nthreads)])
                cmd.extend(['-S', sam_ofn])
                cmd.extend(['-x', args.index])
                cmd.extend(['-U', tmpfile])
                cmd.append('-t')
                cmd.extend(['>', stdout_ofn])
                if len(bt2_args) > 0:  # from config file
                    cmd.extend(bt2_args.split())
                cmd = ' '.join(cmd)
                print(cmd)
                run = False
                if not args.dry_run:
                    if os.path.exists(stdout_ofn):
                        if args.force_runs:
                            print('  "%s" exists; overwriting because --force-runs was specified' % stdout_ofn, file=sys.stderr)
                            run = True
                        else:
                            print('  skipping run "%s" since output file "%s" exists' % (runname, stdout_ofn), file=sys.stderr)
                    else:
                        run = True
                if run:
                    os.system(cmd)
                    if args.delete_sam:
                        os.remove(sam_ofn)


if __name__ == '__main__':

    # Output-related options
    parser = argparse.ArgumentParser(description='Set up thread scaling experiments.')

    parser.add_argument('--nthread-series', metavar='int,int,...', type=str, required=False,
                        help='Series of comma-separated ints giving the number of threads to use')
    parser.add_argument('--nthread-pct-series', metavar='pct,pct,...', type=str, required=False,
                        help='Series of comma-separated percentages giving the number of threads to use as fraction of max # threads')
    parser.add_argument('--config', metavar='pct,pct,...', type=str, required=True,
                        help='Specifies path to config file giving bowtie2 configuration short-names, branch names, compilation macros, and command-line args')
    parser.add_argument('--repo', metavar='url', type=str, default="https://github.com/BenLangmead/bowtie2.git",
                        help='Path to bowtie2 repo, which we clone for each bowtie2 version we test')
    parser.add_argument('--sensitivities', metavar='level,level,...', type=str, default='s',
                        help='Series of comma-separated sensitivity levels, each from {vf, vfl, f, fl, s, sl, vs, vsl}.  Default: just --sensitive.')
    parser.add_argument('--index', metavar='bt2_index_basename', type=str, required=True,
                        help='Path to bowtie2 index; omit final ".1.bt2"')
    parser.add_argument('--reads', metavar='int,int,...', type=str, required=True,
                        help='Path to reads file to use.  Will concatenate multiple copies according to # threads.')
    parser.add_argument('--tempdir', metavar='path', type=str, required=False,
                        help='Picks a path for temporary files.')
    parser.add_argument('--output-dir', metavar='path', type=str, required=True,
                        help='Directory to put thread timings in.')
    parser.add_argument('--force-builds', action='store_const', const=True, default=False,
                        help='Overwrite bowtie2 binaries that already exist')
    parser.add_argument('--force-runs', action='store_const', const=True, default=False,
                        help='Overwrite bowtie2 run output files that already exist')
    parser.add_argument('--dry-run', action='store_const', const=True, default=False,
                        help='Just verify that bowtie2 jobs can be run, then print out bt2 commands without running them')
    parser.add_argument('--sam-temporary', action='store_const', const=True, default=False,
                        help='Put SAM output in temporary directory rather than output directory')
    parser.add_argument('--delete-sam', action='store_const', const=True, default=False,
                        help='Delete SAM file as soon as bowtie2 finishes')

    go(parser.parse_args())
