"""
Master script for setting up thread-scaling experiments with Bowtie, Bowtie 2
and HISAT.
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


def tool_exe(tool):
    if tool == 'bowtie2':
        return 'bowtie2-align-s'
    elif tool == 'bowtie':
        return 'bowtie-align-s'
    elif tool == 'hisat':
        return 'hisat'
    else:
        raise RuntimeError('Unknown tool: "%s"' % tool)


def tool_ext(tool):
    if tool == 'bowtie2':
        return 'bt2'
    elif tool == 'bowtie':
        return 'ebwt'
    elif tool == 'hisat':
        return 'hisat'
    else:
        raise RuntimeError('Unknown tool: "%s"' % tool)


def tool_repo(tool, args):
    if tool == 'bowtie2':
        return args.bowtie2_repo
    elif tool == 'bowtie':
        return args.bowtie_repo
    elif tool == 'hisat':
        return args.hisat_repo
    else:
        raise RuntimeError('Unknown tool: "%s"' % tool)



def make_tool_version(name, tool, preproc):
    """ Builds target in specified clone """
    exe = tool_exe(tool)
    cmd = "make -C build/%s %s %s" % (name, preproc, exe)
    print('  command: ' + cmd, file=sys.stderr)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('non-zero return from make for %s version "%s"' % (tool, name))


def install_tool_version(name, tool, url, branch, preproc):
    """ Clones appropriate branch """
    mkdir_quiet(os.path.join('build', name))
    cmd = "git clone -b %s %s build/%s" % (branch, url, name)
    print('  command: ' + cmd, file=sys.stderr)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('non-zero return from git clone for %s version "%s"' % (tool, name))
    make_tool_version(name, tool, preproc)


def get_configs(config_fn):
    """ Generator that parses and yields the lines of the config file """
    with open(config_fn) as fh:
        for ln in fh:
            toks = ln.split('\t')
            if toks[0] == 'name' and toks[1] == 'tool' and toks[2] == 'branch':
                continue
            if len(toks) == 0 or ln.startswith('#'):
                continue
            if len(toks) == 4:
                name, tool, branch, preproc = toks
                yield name, tool, branch, preproc.rstrip(), None
            else:
                name, tool, branch, preproc, args = toks
                yield name, tool, branch, preproc, args.rstrip()


def verify_index(basename, tool):
    """ Check that all index files exist """
    te = tool_ext(tool)
    def _ext_exists(ext):
        return os.path.exists(basename + ext)
    print('  checking for "%s"' % (basename + '.1.' + te), file=sys.stderr)
    return _ext_exists('.1.' + te) and\
           _ext_exists('.2.' + te) and\
           _ext_exists('.3.' + te) and\
           _ext_exists('.4.' + te) and\
           _ext_exists('.rev.1.' + te) and\
           _ext_exists('.rev.2.' + te)


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


def cat_shorten(fns, dest_fn, n):
    """ Concatenate one or more read files into one output file """
    if os.path.exists(dest_fn):
        os.remove(dest_fn)
    for _ in range(n):
        os.system("cat %s | awk -f shorten.awk >> %s" % (' '.join(fns), dest_fn))


def prepare_reads(args, tmpdir, max_threads):

    print('Counting reads', file=sys.stderr)

    # TODO: make these command-line parameters
    # with these settings, I'm trying to roughly even out how long the runs take
    short_read_multiplier = 2
    paired_end_divisor = 2

    nreads_unp = count_reads([args.U])
    nreads_unp_full = nreads_unp * max_threads * args.multiply_reads
    print('  counted %d unpaired reads, %d for a full series w/ %d threads (multiplier=%d)' %
          (nreads_unp, nreads_unp_full, max_threads, args.multiply_reads), file=sys.stderr)

    nreads_pe = count_reads([args.m1])
    nreads_pe_full = nreads_pe * max_threads * args.multiply_reads / paired_end_divisor
    print('  counted %d paired-end reads, %d for a full series w/ %d threads (multiplier=%d, divisor=%d)' %
          (nreads_pe, nreads_pe_full, max_threads, args.multiply_reads, paired_end_divisor), file=sys.stderr)

    tmpfile = os.path.join(tmpdir, "reads.fq")
    print('Concatenating new unpaired long-read file and storing in "%s"' % tmpfile, file=sys.stderr)
    cat([args.U], tmpfile, max_threads * args.multiply_reads)

    tmpfile_short = os.path.join(tmpdir, "reads_short.fq")
    print('Concatenating new unpaired short-read file and storing in "%s"' % tmpfile_short, file=sys.stderr)
    cat_shorten([args.U], tmpfile_short, max_threads * short_read_multiplier * args.multiply_reads)

    tmpfile_1 = os.path.join(tmpdir, "reads_1.fq")
    print('Concatenating new long paired-end mate 1s and storing in "%s"' % tmpfile_1, file=sys.stderr)
    cat([args.m1], tmpfile_1, (max_threads * args.multiply_reads) / paired_end_divisor)

    tmpfile_short_1 = os.path.join(tmpdir, "reads_1_short.fq")
    print('Concatenating new short paired-end mate 1s and storing in "%s"' % tmpfile_short_1, file=sys.stderr)
    cat_shorten([args.m1], tmpfile_short_1,
                (max_threads * short_read_multiplier * args.multiply_reads) / paired_end_divisor)

    tmpfile_2 = os.path.join(tmpdir, "reads_2.fq")
    print('Concatenating new long paired-end mate 2s and storing in "%s"' % tmpfile_2, file=sys.stderr)
    cat([args.m2], tmpfile_2, (max_threads * args.multiply_reads) / paired_end_divisor)

    tmpfile_short_2 = os.path.join(tmpdir, "reads_2_short.fq")
    print('Concatenating new short paired-end mate 2s and storing in "%s"' % tmpfile_short_2, file=sys.stderr)
    cat_shorten([args.m2], tmpfile_short_2,
                (max_threads * short_read_multiplier * args.multiply_reads) / paired_end_divisor)

    return tmpfile, tmpfile_short, tmpfile_1, tmpfile_short_1, tmpfile_2, tmpfile_short_2, \
           nreads_unp * args.multiply_reads,\
           nreads_pe * args.multiply_reads / paired_end_divisor,\
           nreads_unp * args.multiply_reads * short_read_multiplier,\
           nreads_pe * args.multiply_reads * short_read_multiplier / paired_end_divisor


def run_cmd(cmd, odir):
    ret = os.system(cmd)
    with open(os.path.join(odir, 'cmd.sh'), 'w') as ofh:
        ofh.write("#!/bin/sh\n")
        ofh.write(cmd + "\n")
    return ret


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
                       'vfl': '--very-fast-local'}

    print('Setting up binaries', file=sys.stderr)
    for name, tool, branch, preproc, aligner_args in get_configs(args.config):
        if name == 'name' and branch == 'branch':
            continue  # skip header line
        build, pull = False, False
        build_dir = os.path.join('build', name)
        if os.path.exists(build_dir) and args.force_builds:
            print('  Removing existing "%s" subdir because of --force' % build_dir, file=sys.stderr)
            shutil.rmtree(build_dir)
            build = True
        elif os.path.exists(build_dir):
            pull = True
        elif not os.path.exists(build_dir):
            build = True

        if pull:
            print('  Pulling "%s"' % name, file=sys.stderr)
            os.system('cd %s && git pull' % build_dir)
            make_tool_version(name, tool, preproc)
        elif build:
            print('  Building "%s"' % name, file=sys.stderr)
            install_tool_version(name, tool, tool_repo(tool, args), branch, preproc)

    print('Generating thread series', file=sys.stderr)
    series = gen_thread_series(args, ncpus)
    print('  series = %s' % str(series))

    tmpdir = args.tempdir
    if tmpdir is None:
        tmpdir = tempfile.mkdtemp()
    if not os.path.exists(tmpdir):
        mkdir_quiet(tmpdir)
    if not os.path.isdir(tmpdir):
        raise RuntimeError('Temporary directory isn\'t a directory: "%s"' % tmpdir)

    tmpfile, tmpfile_short, tmpfile_1, tmpfile_short_1, tmpfile_2, tmpfile_short_2, \
        nreads_unp, nreads_pe, nreads_unp_short, nreads_pe_short = prepare_reads(args, tmpdir, max(series))

    sensitivities = args.sensitivities.split(',')
    sensitivities = zip(map(sensitivity_map.get, sensitivities), sensitivities)
    print('Generating sensitivity series: "%s"' % str(sensitivities), file=sys.stderr)

    print('Creating output directory "%s"' % args.output_dir, file=sys.stderr)
    mkdir_quiet(args.output_dir)

    print('Generating %scommands' % ('' if args.dry_run else 'and running '), file=sys.stderr)

    # iterate over configurations
    for name, tool, branch, preproc, aligner_args in get_configs(args.config):
        odir_outer = os.path.join(args.output_dir, name)

        print('Checking that index files exist', file=sys.stderr)
        if not verify_index(args.index, tool):
            raise RuntimeError('Could not verify index files')

        # iterate over sensitivity levels
        for sens, sens_short in sensitivities:
            odir_sens = os.path.join(odir_outer, sens[2:])
            # iterate over numbers of threads
            for nthreads in series:
                # iterate over unpaired / paired-end
                for paired in [False, True]:
                    # Compose command
                    odir = os.path.join(odir_sens, 'pe' if paired else 'unp')
                    print('  Creating output directory "%s"' % odir, file=sys.stderr)
                    mkdir_quiet(odir)

                    runname = '%s_%s_%s_%d' % (name, 'pe' if paired else 'unp', sens_short, nthreads)
                    stdout_ofn = os.path.join(odir, '%d.txt' % nthreads)
                    sam_ofn = os.path.join(odir if args.sam_output_dir else tmpdir, '%s.sam' % runname)
                    sam_ofn = '/dev/null' if args.sam_dev_null else sam_ofn
                    cmd = ['build/%s/%s' % (name, tool_exe(tool))]
                    cmd.extend(['-p', str(nthreads)])
                    if tool == 'bowtie2':
                        nreads = (nreads_pe * nthreads) if paired else (nreads_unp * nthreads)
                        cmd.extend(['-u', str(nreads)])
                        cmd.append(sens)
                        cmd.extend(['-S', sam_ofn])
                        cmd.extend(['-x', args.index])
                        if paired:
                            cmd.extend(['-1', tmpfile_1])
                            cmd.extend(['-2', tmpfile_2])
                        else:
                            cmd.extend(['-U', tmpfile])
                        cmd.append('-t')
                        if aligner_args is not None and len(aligner_args) > 0:  # from config file
                            cmd.extend(aligner_args.split())
                        cmd.extend(['>', stdout_ofn])
                    elif tool == 'bowtie':
                        nreads = (nreads_pe_short * nthreads) if paired else (nreads_unp_short * nthreads)
                        cmd.extend(['-u', str(nreads)])
                        cmd.extend([args.index])
                        if paired:
                            cmd.extend(['-1', tmpfile_short_1])
                            cmd.extend(['-2', tmpfile_short_2])
                        else:
                            cmd.extend([tmpfile_short])
                        cmd.extend([sam_ofn])
                        cmd.append('-t')
                        cmd.append('-S')
                        if aligner_args is not None and len(aligner_args) > 0:  # from config file
                            cmd.extend(aligner_args.split())
                        cmd.extend(['>', stdout_ofn])
                    else:
                        raise RuntimeError('Unsupported tool: "%s"' % tool)
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
                        run_cmd(cmd, odir)
                        assert os.path.exists(sam_ofn)
                        if args.delete_sam and not args.sam_dev_null:
                            os.remove(sam_ofn)


if __name__ == '__main__':

    # Output-related options
    parser = argparse.ArgumentParser(description='Set up thread scaling experiments.')
    default_bt_repo = "https://github.com/BenLangmead/bowtie.git"
    default_bt2_repo = "https://github.com/BenLangmead/bowtie2.git"
    default_hs_repo = "https://github.com/BenLangmead/hisat.git"  # this is my fork

    requiredNamed = parser.add_argument_group('required named arguments')
    requiredNamed.add_argument('--index', metavar='index_basename', type=str, required=True,
                        help='Path to index; omit final ".1.bt2".  Should usually be a human genome index, with filenames like hg19.* or hg38.*')
    requiredNamed.add_argument('--U', metavar='path', type=str, required=True,
                        help='Path to file to use for unpaired reads.  Will concatenate multiple copies according to # threads.')
    requiredNamed.add_argument('--m1', metavar='path', type=str, required=True,
                        help='Path to file to use for mate 1s for paried-end runs.  Will concatenate multiple copies according to # threads.')
    requiredNamed.add_argument('--m2', metavar='path', type=str, required=True,
                        help='Path to file to use for mate 2s for paried-end runs.  Will concatenate multiple copies according to # threads.')
    requiredNamed.add_argument('--config', metavar='pct,pct,...', type=str, required=True,
                        help='Specifies path to config file giving configuration short-names, tool names, branch names, compilation macros, and command-line args.  (Provided master_config.tsv is probably sufficient)')
    requiredNamed.add_argument('--output-dir', metavar='path', type=str, required=True,
                        help='Directory to put thread timings in.')
    parser.add_argument('--nthread-series', metavar='int,int,...', type=str, required=False,
                        help='Series of comma-separated ints giving the number of threads to use.  E.g. --nthread-series 10,20,30 will run separate experiments using 10, 20 and 30 threads respectively.  Deafult: just one experiment using max # threads.')
    parser.add_argument('--multiply-reads', metavar='int', type=int, default=20,
                        help='Duplicate the input reads file this many times before scaling according to the number of reads.')
    parser.add_argument('--nthread-pct-series', metavar='pct,pct,...', type=str, required=False,
                        help='Series of comma-separated percentages giving the number of threads to use as fraction of max # threads')
    parser.add_argument('--bowtie-repo', metavar='url', type=str, default=default_bt_repo,
                        help='Path to bowtie repo, which we clone for each bowtie version we test (deafult: %s)' % default_bt_repo)
    parser.add_argument('--bowtie2-repo', metavar='url', type=str, default=default_bt2_repo,
                        help='Path to bowtie2 repo, which we clone for each bowtie2 version we test (deafult: %s)' % default_bt2_repo)
    parser.add_argument('--hisat-repo', metavar='url', type=str, default=default_hs_repo,
                        help='Path to HISAT repo, which we clone for each HISAT version we test (deafult: %s)' % default_hs_repo)
    parser.add_argument('--sensitivities', metavar='level,level,...', type=str, default='s',
                        help='Series of comma-separated sensitivity levels, each from the set {vf, vfl, f, fl, s, sl, vs, vsl}.  Default: s (just --sensitive).')
    parser.add_argument('--tempdir', metavar='path', type=str, required=False,
                        help='Picks a path for temporary files.')
    parser.add_argument('--force-builds', action='store_const', const=True, default=False,
                        help='Overwrite binaries that already exist')
    parser.add_argument('--force-runs', action='store_const', const=True, default=False,
                        help='Overwrite run output files that already exist')
    parser.add_argument('--dry-run', action='store_const', const=True, default=False,
                        help='Just verify that jobs can be run, then print out commands without running them; useful for when you need to wrap the bowtie2 commands for profiling or other reasons')
    parser.add_argument('--sam-output-dir', action='store_const', const=True, default=False,
                        help='Put SAM output in the output directory rather than in the temporary directory.  Usually we don\'t really care to examine the SAM output, so the default is reasonable.')
    parser.add_argument('--sam-dev-null', action='store_const', const=True, default=False,
                        help='Send SAM output directly to /dev/null.')
    parser.add_argument('--delete-sam', action='store_const', const=True, default=False,
                        help='Delete SAM file as soon as aligner finishes; useful if you need to avoid exhausting a partition')

    go(parser.parse_args())
