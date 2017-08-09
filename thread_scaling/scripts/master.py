"""
master.py

Drives a series of thread-scaling experiments with Bowtie, Bowtie 2 or HISAT.

Works for experiments that are:
1. MT    (one process, add threads)
2. MP+MT (fixed # threads / process, add processes)
3. MP    (MP+MT but with 1 thread / process)

Experiments scale the amount of input data with the total number of threads.
Input data is assumed to be pre-shuffled
"""

from __future__ import print_function
import os
import sys
import shutil
import argparse
import subprocess
import tempfile
import datetime
import multiprocessing


join = os.path.join


def mkdir_quiet(dr):
    """ Create directories needed to ensure 'dr' exists; no complaining """
    import errno
    if not os.path.isdir(dr):
        try:
            os.makedirs(dr)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise


def tool_exe(tool):
    if tool == 'bowtie2' or tool == 'bowtie' or tool == 'hisat':
        return tool + '-align-s'
    elif tool == 'bwa':
        return 'bwa'
    else:
        raise RuntimeError('Unknown tool: "%s"' % tool)


def tool_ext(tool):
    if tool == 'bowtie2' or tool == 'hisat':
        return 'bt2'
    elif tool == 'bowtie':
        return 'ebwt'
    else:
        raise RuntimeError('Unknown tool: "%s"' % tool)


def make_tool_version(name, tool, preproc, build_dir):
    """ Builds target in specified clone """
    exe = tool_exe(tool)
    cmd = "make -e -C %s %s %s" % (build_dir, preproc, exe)
    print(cmd)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('non-zero return from make for %s version "%s"' % (tool, name))


def install_tool_version(name, tool, url, branch, preproc, build_dir, make_tool=True):
    """ Clones appropriate branch """
    if len(branch) == 40 and branch.isalnum():
        cmd = "git clone %s -- %s && cd %s && git reset --hard %s" % (url, build_dir, build_dir, branch)
    else:
        cmd = "git clone %s -b %s -- %s" % (url, branch, build_dir)
    print(cmd)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('non-zero return from git clone for %s version "%s"' % (tool, name))
    if make_tool:
        make_tool_version(name, tool, preproc, build_dir)


def get_configs(config_fn):
    """ Generator that parses and yields the lines of the config file """
    with open(config_fn) as fh:
        for ln in fh:
            toks = ln.split('\t')
            if toks[0] == 'name' and toks[1] == 'tool' and toks[2] == 'branch':
                continue
            if len(toks) == 0 or ln.startswith('#'):
                continue
            if len(toks) != 6:
                raise RuntimeError('Expected 6 tokens, got %d: %s' % (len(toks), ln))
            name, tool, branch, mp_mt, preproc, args = toks
            yield name, tool, branch, int(mp_mt), preproc, args.rstrip()


def verify_index(basename, tool):
    """ Check that all index files exist """
    def _ext_exists(ext):
        print('#  checking for "%s"' % (basename + ext), file=sys.stderr)
        return os.path.exists(basename + ext)
    if tool == 'bwa':
        ret = all(_ext_exists(x) for x in ['.amb', '.ann', '.pac'])
    else:
        te = tool_ext(tool)
        ret = all(_ext_exists(x + te) for x in ['.1.', '.2.', '.3.', '.4.', '.rev.1.', '.rev.2.'])
        if ret and tool == 'hisat':
            return all(_ext_exists(x + te) for x in ['.5.', '.6.', '.rev.5.', '.rev.6.'])
    return ret


def verify_reads(fns):
    """ Check that files exist """
    for fn in fns:
        if fn is not None and (not os.path.exists(fn) or not os.path.isfile(fn)):
            raise RuntimeError('No such reads file as "%s"' % fn)
    return True


def wcl(fn):
    return int(subprocess.check_output('wc -l ' + fn, shell=True).strip().split()[0])


def slice_fastq(begin, end, ifn, ofn, sanity=True):
    cmd = "sed -n '%d,%dp;%dq' < %s > %s" % (begin * 4 + 1, end * 4, end * 4 + 1, ifn, ofn)
    print(cmd)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('Exitlevel %d from command "%s"' % (ret, cmd))
    if sanity:
        actual_nlines = wcl(ofn)
        if actual_nlines != (end - begin) * 4:
            raise RuntimeError('Expected %d lines, found %d in "%s"' % ((end - begin)*4, actual_nlines, ofn))


def prepare_reads(args, nthread, mp_mt, tmpdir, blocked=False):
    read_sets = []
    if mp_mt > 0:
        assert nthread % mp_mt == 0
        nprocess = int(nthread / mp_mt + 0.01)
        nreads_per_process = int((args.reads_per_thread * nthread) / nprocess + 0.01)
        for i in range(nprocess):
            rds_1 = join(tmpdir, "1_p%d.fq" % i)
            rds_2 = join(tmpdir, "2_p%d.fq" % i)
            slice_fastq(i * nreads_per_process, (i+1) * nreads_per_process, args.m1b if blocked else args.m1, rds_1)
            if args.m2 is not None:
                slice_fastq(i * nreads_per_process, (i+1) * nreads_per_process, args.m2b if blocked else args.m2, rds_2)
                read_sets.append([rds_1, rds_2])
            else:
                read_sets.append([rds_1])
    else:
        rds_1 = join(tmpdir, "1.fq")
        rds_2 = join(tmpdir, "2.fq")
        nreads = args.reads_per_thread * nthread
        slice_fastq(0, nreads, args.m1b if blocked else args.m1, rds_1)
        if args.m2 is not None:
            slice_fastq(0, nreads, args.m2b if blocked else args.m2, rds_2)
            read_sets.append([rds_1, rds_2])
        else:
            read_sets.append([rds_1])
    return read_sets


repos = {'bowtie': 'https://github.com/BenLangmead/bowtie.git',
         'bowtie2': 'https://github.com/BenLangmead/bowtie2.git',
         'hisat': 'https://github.com/BenLangmead/hisat.git',
         'bwa': 'https://github.com/ChristopherWilks/bwa.git'}


def go(args):
    # Set up temporary directory, used for holding read inputs and SAM output.
    # Strongly suggest that it be local, non-networked storage.
    print('# Setting up temporary directory', file=sys.stderr)
    tmpdir = args.tempdir
    if tmpdir is None:
        tmpdir = tempfile.mkdtemp()
    if not os.path.exists(tmpdir):
        mkdir_quiet(tmpdir)
    if not os.path.isdir(tmpdir):
        raise RuntimeError('Temporary directory isn\'t a directory: "%s"' % tmpdir)

    if not os.path.exists(args.output_dir):
        print('# Creating output directory "%s"' % args.output_dir, file=sys.stderr)
        mkdir_quiet(args.output_dir)

    print('# Setting up binaries', file=sys.stderr)
    last_name, last_tool, last_branch, last_preproc, last_build_dir = '', '', '', '', ''
    npull, nbuild, ncopy, nlink = 0, 0, 0, 0
    for name, tool, branch, _, preproc, _ in get_configs(args.config):
        if args.preproc is not None:
            preproc += ' ' + args.preproc
        if name == 'name' and branch == 'branch':
            continue  # skip header line
        if len(last_tool) == 0:
            last_tool = tool
        assert tool == last_tool
        build, pull = False, False
        build_dir = join(args.build_dir, name)
        if os.path.exists(build_dir) and args.force_builds:
            print('#   Removing existing "%s" subdir because of --force' % build_dir, file=sys.stderr)
            shutil.rmtree(build_dir)
            build = True
        elif os.path.exists(build_dir):
            pull = True
        elif not os.path.exists(build_dir):
            build = True

        if pull and args.pull:
            npull += 1
            print('#   Pulling "%s"' % name, file=sys.stderr)
            os.system('cd %s && git pull' % build_dir)
            make_tool_version(name, tool, preproc, build_dir)
        elif build and tool == last_tool and branch == last_branch and preproc == last_preproc:
            nlink += 1
            print('#   Linking "%s"' % name, file=sys.stderr)
            os.system('ln -s -f %s %s' % (last_name, build_dir))
        elif build and tool == last_tool and branch == last_branch:
            ncopy += 1
            print('#   Copying "%s"' % name, file=sys.stderr)
            os.system('cp -r %s %s' % (last_build_dir, build_dir))
            os.remove(os.path.join(build_dir, tool_exe(tool)))
            make_tool_version(name, tool, preproc, build_dir)
        elif build:
            nbuild += 1
            print('#   Building "%s"' % name, file=sys.stderr)
            install_tool_version(name, tool, repos[tool], branch, preproc, build_dir)
        last_name, last_tool, last_branch, last_preproc, last_build_dir = name, tool, branch, preproc, build_dir

    print('# Finished setting up binaries; built %d, pulled %d, copied %d, linked %d' %
          (nbuild, npull, ncopy, nlink), file=sys.stderr)

    series = list(map(int, args.nthread_series.split(',')))
    assert len(series) > 0
    print('#   series = %s' % str(series), file=sys.stderr)

    print('# Verifying reads', file=sys.stderr)
    verify_reads([args.m1, args.m2, args.m1b, args.m2b])
    nlines_tot = wcl(args.m1)
    nlines_tot_b = wcl(args.m1b)
    if nlines_tot != nlines_tot_b:
        raise RuntimeError('Mismatch in # lines between unblocked (%d) and blocked (%d) inputs' % \
                           (nlines_tot, nlines_tot_b))

    nreads_tot = nlines_tot // 4
    nreads_needed = args.reads_per_thread * max(series)
    if nreads_needed > nreads_tot:
        raise RuntimeError('# reads required for biggest experiment (%d) exceeds number of input reads (%d)'
                           % (nreads_needed, nreads_tot))

    print('# Generating %scommands' % ('' if args.dry_run else 'and running '), file=sys.stderr)

    indexes_verified = set()
    pe_str = 'pe' if args.m2 is not None else 'unp'

    read_set = None

    # iterate over numbers of threads
    for nthreads in series:

        last_mp_mt = None

        # iterate over configurations
        for name, tool, branch, mp_mt, preproc, aligner_args in get_configs(args.config):
            build_dir = join(args.build_dir, name)

            odir = join(args.output_dir, name, pe_str)
            if not os.path.exists(odir):
                print('#   Creating output directory "%s"' % odir, file=sys.stderr)
                mkdir_quiet(odir)

            redo = 1

            if tool not in indexes_verified:
                print('#   Verifying index for ' + tool, file=sys.stderr)
                verify_index(args.index, tool)
                indexes_verified.add(tool)
                redo = 2

            if mp_mt != 0 and (nthreads % mp_mt != 0):
                continue  # skip experiment if # threads isn't evenly divisible

            if last_mp_mt is None or mp_mt != last_mp_mt:
                # Purge previous read set?
                print('#   Purging some old reads', file=sys.stderr)
                if read_set is not None:
                    for read_list in read_set:
                        for read_fn in read_list:
                            os.remove(read_fn)
                blocked = aligner_args is not None and 'block-bytes' in aligner_args
                blocked_str = 'blocked' if blocked else 'unblocked'
                print('#   Preparing reads (%s) for nthreads=%d, mp_mt=%d' %
                      (blocked_str, nthreads, mp_mt), file=sys.stderr)
                read_set = prepare_reads(args, nthreads, mp_mt, tmpdir, blocked=blocked)
                redo = 2
                last_mp_mt = mp_mt

            nprocess = 1 if mp_mt == 0 else nthreads // mp_mt
            assert nprocess >= 1
            nthreads_per_process = nthreads if mp_mt == 0 else mp_mt
            print('# %s: nthreads=%d, nprocs=%d, threads per proc=%d' %
                  (name, nthreads, nprocess, nthreads_per_process), file=sys.stderr)

            for idx in range(redo):
                idx_rev = redo - idx
                print('# --- Attempt %d/%d ---' % (idx+1, redo))

                # Set up output files
                run_names = ['%s_%s_%d_%d_%d_%d' % (name, pe_str, mp_mt, i, nthreads, idx_rev) for i in range(nprocess)]
                stdout_ofns = ['/dev/null'] * nprocess
                stderr_ofns = ['/dev/null'] * nprocess
                sam_ofns = ['/dev/null'] * nprocess
                if idx_rev == 1:
                    stdout_ofns = [join(odir, '%s.out' % runname) for runname in run_names]
                    stderr_ofns = [join(odir, '%s.err' % runname) for runname in run_names]
                    if not args.sam_dev_null:
                        samdir = odir if args.sam_output_dir else tmpdir
                        sam_ofns = [join(samdir, '%s.sam' % runname) for runname in run_names]
                sh_ofns = [join(odir, '%s.sh' % runname) for runname in run_names]

                procs = []
                for i in range(nprocess):
                    cmd = ['%s/%s' % (build_dir, tool_exe(tool))]
                    if tool == 'bwa':
                        cmd.append('mem')
                    cmd.extend(['-t' if tool == 'bwa' else '-p', str(nthreads_per_process)])
                    if tool == 'bowtie2' or tool == 'hisat':
                        cmd.append('-x')
                    cmd.append(args.index)
                    if tool != 'bwa':
                        cmd.append('-t')
                        if args.m2 is not None:
                            cmd.extend(['-1', read_set[i][0]])
                            cmd.extend(['-2', read_set[i][1]])
                        elif tool == 'bowtie2' or tool == 'hisat':
                            cmd.extend(['-U', read_set[i][0]])
                        else:
                            cmd.append(read_set[i][0])
                    else:
                        cmd.append(read_set[i][0])
                        if args.m2 is not None:
                            cmd.append(read_set[i][1])

                    cmd.extend(['-S', sam_ofns[i]])
                    if aligner_args is not None and len(aligner_args) > 0:
                        cmd.extend(aligner_args.split())
                    if mp_mt > 0:
                        cmd.append('--mm')
                    cmd.extend(['>', stdout_ofns[i]])
                    cmd.extend(['2>', stderr_ofns[i]])
                    cmd = ' '.join(cmd)
                    with open(sh_ofns[i], 'w') as ofh:
                        ofh.write("#!/bin/sh\n")
                        ofh.write("set -e\n")
                        ofh.write(cmd + '\n')
                    print(cmd)

                    def spawn_worker(shfn):
                        def worker():
                            sys.exit(0 if os.system('sh ' + shfn) == 0 else 1)
                        return worker

                    procs.append(multiprocessing.Process(target=spawn_worker(sh_ofns[i])))

                print('#   Starting processes', file=sys.stderr)
                ti = datetime.datetime.now()
                for proc in procs:
                    proc.start()
                exitlevels = []
                for proc in procs:
                    proc.join()
                    exitlevels.append(proc.exitcode)
                delt = datetime.datetime.now() - ti
                print('#   All processes joined; took %f seconds' % delt.total_seconds(), file=sys.stderr)
                if sum(exitlevels) > 0:
                    raise RuntimeError('At least one subprocess exited with non-zero exit level. '
                                       'Exit levels: %s' % str(exitlevels))

                if args.delete_sam and not args.sam_dev_null:
                    print('#   Deleting SAM outputs', file=sys.stderr)
                    for sam_ofn in sam_ofns:
                        os.remove(sam_ofn)

    print('#   Purging some old reads', file=sys.stderr)
    if read_set is not None:
        for read_list in read_set:
            for read_fn in read_list:
                os.remove(read_fn)


if __name__ == '__main__':

    # Output-related options
    parser = argparse.ArgumentParser(description='Run a single series of thread-scaling experiments.')

    requiredNamed = parser.add_argument_group('required named arguments')
    requiredNamed.add_argument('--index', metavar='index_basename', type=str, required=True,
                        help='Path to indexes; omit final ".1.bt2" or ".1.ebwt".  Should usually be a human genome '
                             'index, with filenames like hg19.* or hg38.*')
    requiredNamed.add_argument('--config', metavar='pct,pct,...', type=str, required=True,
                        help='Specifies path to config file giving configuration short-names, tool names, branch '
                             'names, compilation macros, and command-line args.  (Provided master_config.tsv is '
                             'probably sufficient)')
    requiredNamed.add_argument('--output-dir', metavar='path', type=str, required=True,
                        help='Directory to put thread timings in.')
    requiredNamed.add_argument('--build-dir', metavar='path', type=str, default='build',
                        help='Directory to put git working copies & built binaries in.')
    requiredNamed.add_argument('--m1', metavar='path', type=str, required=True,
                        help='FASTQ file with mate 1s.  Will take subsets to construct inputs.')
    requiredNamed.add_argument('--m1b', metavar='path', type=str, required=True,
                        help='Blocked FASTQ file with mate 1s.  Will take subsets to construct inputs.')
    parser.add_argument('--m2', metavar='path', type=str,
                        help='FASTQ file with mate 2s.  Will take subsets to construct inputs.')
    parser.add_argument('--m2b', metavar='path', type=str,
                        help='Blocked FASTQ file with mate 1s.  Will take subsets to construct inputs.')
    parser.add_argument('--input-block-bytes', metavar='int', type=int, default=12288,
                        help='# bytes per input block')
    parser.add_argument('--input-reads-per-block', metavar='int', type=int, default=70,  # 44 for 100 bp reads
                        help='# reads in each input block')
    parser.add_argument('--nthread-series', metavar='int,int,...', type=str, required=False,
                        help='Series of comma-separated ints giving the number of threads to use. '
                             'E.g. --nthread-series 10,20,30 will run separate experiments using '
                             '10, 20 and 30 threads respectively.  Deafult: just one experiment '
                             'using max # threads.')
    parser.add_argument('--repo', metavar='url', type=str, default=repos['bowtie'],
                        help='Path to repo for tool, cloned as needed (default: %s)' % repos['bowtie'])
    parser.add_argument('--tempdir', metavar='path', type=str, required=False,
                        help='Path for temporary files.  Used for reads files and output SAM.  Should be local, '
                             'non-networked storage.')
    parser.add_argument('--preproc', metavar='args', type=str, required=False,
                        help='Add preprocessing macros to be added to all build jobs.')
    parser.add_argument('--force-builds', action='store_const', const=True, default=False,
                        help='Overwrite binaries that already exist')
    parser.add_argument('--pull', action='store_const', const=True, default=False,
                        help='git pull into existing build directories (note: some might be tags rather than branches)')
    parser.add_argument('--dry-run', action='store_const', const=True, default=False,
                        help='Just verify that jobs can be run, then print out commands without running them; useful '
                             'for when you need to wrap the bowtie2 commands for profiling or other reasons')
    parser.add_argument('--sam-output-dir', action='store_const', const=True, default=False,
                        help='Put SAM output in the output directory rather than in the temporary directory.  '
                             'Usually we don\'t really care to examine the SAM output, so the default is reasonable.')
    parser.add_argument('--sam-dev-null', action='store_const', const=True, default=False,
                        help='Send SAM output directly to /dev/null.')
    parser.add_argument('--delete-sam', action='store_const', const=True, default=False,
                        help='Delete SAM file as soon as aligner finishes; useful if you need to avoid exhausting a '
                             'partition')
    parser.add_argument('--reads-per-thread', metavar='int', type=int, default=0,
                        help='set # of reads to align per thread/process directly, overrides --multiply-reads setting')

    go(parser.parse_args())
