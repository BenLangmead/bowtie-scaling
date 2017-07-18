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
import re
import multiprocessing


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
    else:
        raise RuntimeError('Unknown tool: "%s"' % tool)


def tool_ext(tool):
    if tool == 'bowtie2' or tool == 'hisat':
        return 'bt2'
    elif tool == 'bowtie':
        return 'ebwt'
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
    cmd = "make -e -C build/%s %s %s" % (name, preproc, exe)
    print('  command: ' + cmd, file=sys.stderr)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('non-zero return from make for %s version "%s"' % (tool, name))


def install_tool_version(name, tool, url, branch, preproc, build_dir='build', make_tool=True):
    """ Clones appropriate branch """
    mkdir_quiet(os.path.join(build_dir, name))
    cmd = "git clone -b %s %s %s/%s" % (branch, url, build_dir, name)
    print('  command: ' + cmd, file=sys.stderr)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('non-zero return from git clone for %s version "%s"' % (tool, name))
    if make_tool:
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
    ret = all(_ext_exists(x + te) for x in ['.1.', '.2.', '.3.', '.4.', '.rev.1.', '.rev.2.'])
    if ret and tool == 'hisat':
        return all(_ext_exists(x + te) for x in ['.5.', '.6.', '.rev.5.', '.rev.6.'])
    return ret


def verify_reads(fns):
    """ Check that files exist """
    for fn in fns:
        if not os.path.exists(fn) or not os.path.isfile(fn):
            raise RuntimeError('No such reads file as "%s"' % fn)
    return True


def count_reads(fns):
    """ Count the total number of reads in one or more fastq files """
    def _count_lines(x):
        return int(subprocess.check_output('wc -l ' + x, shell=True).strip().split()[0])
    return sum([_count_lines(fn) for fn in fns]) / 4


# seqs_to_cat is just for compatibility with cat_shorten's signature
def cat(fns, dest_fn, n, seqs_to_cat=0):
    """ Concatenate one or more read files into one output file """
    with open(dest_fn, 'wb') as ofh:
        for _ in range(n):
            for fn in fns:
                with open(fn, 'rb') as fh:
                    shutil.copyfileobj(fh, ofh, 1024*1024*10)


def shorten(source_fns, dest_fn, input_cmd='cat %s'):
    """ Reduces the read/qual length by half (100bp=>50bp); used for shorter read aligners (bowtie) """
    output_fn = dest_fn
    os.system((input_cmd % ' '.join(source_fns)) + " | awk -f shorten.awk > %s" % output_fn)
    return output_fn


def cat_shorten(fns, dest_fn, n, seqs_to_cat=0):
    """ Concatenate one or more read files into one output file """
    if os.path.exists(dest_fn):
        os.remove(dest_fn)
    if os.path.exists(dest_fn + ".short"):
        os.remove(dest_fn + ".short")
    # if # of lines are requested, don't do a copy as well
    if seqs_to_cat > 0:
        input_cmd = 'head -n %d' % (LINES_PER_FASTQ_REC*seqs_to_cat)
        output_fn = shorten(fns, dest_fn, input_cmd=(input_cmd + " %s"))
        os.rename(output_fn, dest_fn)
    else:
        output_fn = shorten(fns, "%s.short" % dest_fn)
        cat([output_fn], dest_fn, n)


def split_read_set(source_path, dest_dir, reads_per_file, nfiles, shorten_first=False):
    """ Similar to the split command, but stops after nfiles has been reached; also supports shortening first """
    source_dir, source_fn = os.path.split(source_path)
    dest_path = os.path.join(dest_dir, source_fn)
    fctr = 0  # file counter
    rctr = 0  # read counter
    fout = None
    infix = ''
    if shorten_first:
        total_lines_needed = LINES_PER_FASTQ_REC * reads_per_file * nfiles
        input_cmd = "head -n %d" % total_lines_needed
        source_path = shorten([source_path], "%s.short" % dest_path, input_cmd=input_cmd + " %s")
        infix = '.short'
    lines_per_file_limit = LINES_PER_FASTQ_REC * reads_per_file
    with open(source_path, "r") as fin:
        for line in fin:
            line = line.rstrip()
            if rctr % lines_per_file_limit == 0:
                if fout:
                    fout.close()
                fctr += 1
                if fctr > nfiles:
                    break
                fout = open("%s%s.%d.fq" % (dest_path, infix, fctr), "w")
            rctr += 1
            fout.write("%s\n" % line)
    if fout:
        fout.close()


def calculate_read_partitions(args, max_threads, input_fns, tmpfiles, multiply_reads, paired_end_factor):
    """ Determines 1) # reads per thread 2) # of base units of copy (for catting)
        3) whether to generate reads 4) which read files to use as source """
    multiplier = multiply_reads
    if args.shorten_reads:
        short_read_multiplier = int(round(args.short_factor))
        multiplier *= short_read_multiplier
    paired_end_divisor = int(round(1.0 / paired_end_factor))
    nreads = DEFAULT_BASE_READS_COUNT
    nreads_per_thread = nreads * multiplier / paired_end_divisor
    #this is the unit of reads to repeat for repetitive read generation
    #if not paired, paired_end_divisor is just 1
    nreads_full = multiplier * max_threads / paired_end_divisor

    if args.reads_per_thread > 0:
        nreads_per_thread = args.reads_per_thread / paired_end_divisor

    if input_fns[0]:
        nreads = args.reads_count
        if nreads <= 0:
            nreads = count_reads([input_fns[0]])
        #sepcial case where the # of reads is greater than our base unit of concatenation
        #means we don't do an catting/repeating  
        if nreads > DEFAULT_BASE_READS_COUNT:
            #assume we've been passed enough reads in the origin file for the max thread count in the series
            #and therefore no need to copy/repeat reads to up the total number
            generate_reads = False
            if paired_end_factor < 1:
                tmpfiles[0] = input_fns[0]
                tmpfiles[1] = input_fns[1]
            else:
                tmpfiles[0] = input_fns[0]
            assert args.reads_per_thread > 0
            #if we;re just pulling reads from a full source file (no repeats)
            #just set this to be the entire set we'll need
            nreads_full = nreads_per_thread * max_threads

    # TODO: what does "for a full series" mean?
    print('  counted %d paired-end reads, %d for a full series w/, %d reads per thread, %d threads (multiplier=%f, divisor=%d)' %
          (nreads, nreads_full, nreads_per_thread, max_threads, multiplier, paired_end_divisor), file=sys.stderr)

    return tmpfiles, nreads_per_thread, nreads_full


def prepare_mp_reads(args, tmpdir, max_threads, tool, args_U, args_m1, args_m2, generate_reads=True):
    """ Calculates read units (e.g. # per thread) and possibly generates read sets for multiprocess aligning """

    #if we've been passed in the # of reads explicitly
    #set it here and assume the original files are also 
    #fine for using for a source
    nreads_unp_per_thread = args.multiprocess
    nreads_pe_per_thread = args.multiprocess / 2
    tmpfile = args_U
    tmpfile_1 = args_m1
    tmpfile_2 = args_m2    

    #if we didn't get the explicit # of reads per unp process passed in
    #do the default/normal calculation based on multiply-reads and related options
    #**but** we don't care about re-assigning the input reads files as in the multithread case
    if args.multiprocess <= MP_SEPARATE:
        print('Counting %s reads' % tool, file=sys.stderr)
        generic_args_U = args_U
        #caculate for single end reads (tmpfile_1 and tmpfile_2 don't change)
        (_, _, nreads_unp_per_thread, nreads_unp_full) = \
            calculate_read_partitions(args, max_threads, tool, [args_U], [tmpfile],
                      args.multiply_reads, 1, generate_reads)
    
        #now calculate for paired ends (same as above except tmpfile doesn't change)
        (_, _, nreads_pe_per_thread, nreads_pe_full) = \
            calculate_read_partitions(args, max_threads, tool, [args_m1, args_m2], [tmpfile_1, tmpfile_2],
                     args.multiply_reads, args.paired_end_factor, generate_reads)

    shorten = args.shorten_reads or tool == 'bowtie'    
 
    if generate_reads:

        if args.paired_mode != PAIRED_ONLY:
            split_read_set(args_U, tmpdir, nreads_unp_per_thread, max_threads, shorten_first=shorten)
            tmpfile_dir, tmpfile = os.path.split(tmpfile)
            tmpfile = os.path.join(tmpdir, tmpfile)

        if args.paired_mode != UNPAIRED_ONLY:
            split_read_set(args_m1, tmpdir, nreads_pe_per_thread, max_threads, shorten_first=shorten)
            split_read_set(args_m2, tmpdir, nreads_pe_per_thread, max_threads, shorten_first=shorten)
            tmpfile_dir, tmpfile_1 = os.path.split(tmpfile_1)
            tmpfile_1 = os.path.join(tmpdir, tmpfile_1)
            tmpfile_dir, tmpfile_2 = os.path.split(tmpfile_2)
            tmpfile_2 = os.path.join(tmpdir, tmpfile_2)

    infix = ''
    if shorten:
        infix = '.short'
    tmpfile = tmpfile + infix + ".%d.fq" 
    tmpfile_1 = tmpfile_1 + infix + ".%d.fq" 
    tmpfile_2 = tmpfile_2 + infix + ".%d.fq" 

    return tmpfile, tmpfile_1, tmpfile_2, nreads_unp_per_thread, nreads_pe_per_thread


def prepare_reads(args, tmpdir, max_threads, tool, args_U, args_m1, args_m2):
    """ Calculates read units (e.g. # per thread) and possibly generates read sets for multithread aligning """

    # TODO: why do these get overriden so soon after this?
    tmpfile = os.path.join(tmpdir, tool + '_' + "reads.fq")
    tmpfile_1 = os.path.join(tmpdir, tool + '_' + "reads_1.fq")
    tmpfile_2 = os.path.join(tmpdir, tool + '_' + "reads_2.fq")

    print('Counting %s reads' % tool, file=sys.stderr)

    #caculate for single end reads (tmpfile_1 and tmpfile_2 don't change)
    (generate_reads, tmpfiles, nreads_unp_per_thread, nreads_unp_full) = \
        calculate_read_partitions(args, max_threads, tool, [args_U], [tmpfile],
                  args.multiply_reads, 1, generate_reads)
    tmpfile = tmpfiles[0]

    #now calculate for paired ends (same as above except tmpfile doesn't change)
    (generate_reads, tmpfiles, nreads_pe_per_thread, nreads_pe_full) = \
        calculate_read_partitions(args, max_threads, tool, [args_m1, args_m2], [tmpfile_1, tmpfile_2],
                  args.multiply_reads, args.paired_end_factor, generate_reads)
    tmpfile_1 = tmpfiles[0]
    tmpfile_2 = tmpfiles[1]

    cat_func = cat
    seqs_to_cat_unp = 0
    seqs_to_cat_pe = 0
    #special case: short reads (e.g. bowtie) get generated even with an
    #intact, full-sized original souce file, but not if explicitly told NOT
    #to generate reads
    if args.shorten_reads or tool == 'bowtie':
        tmpfile = os.path.join(tmpdir, tool + '_' + "reads_short.fq")
        tmpfile_1 = os.path.join(tmpdir, tool + '_' + "reads_1_short.fq")
        tmpfile_2 = os.path.join(tmpdir, tool + '_' + "reads_2_short.fq")
        cat_func = cat_shorten

    #need the default generate reads to be still enabled OR an explicit setting of shorten_reads
    #doesn't include an OR check here for bowtie as the tool since there will be times when 
    #we're running for bowtie but don't want to actually generate reads
    if args.paired_mode != PAIRED_ONLY:
        print('Concatenating new unpaired long-read file of %d reads and storing in "%s"' %
              (nreads_unp_full, tmpfile), file=sys.stderr)
        cat_func([args_U], tmpfile, nreads_unp_full, seqs_to_cat=seqs_to_cat_unp)
    #paired
    if args.paired_mode != UNPAIRED_ONLY:
        print('Concatenating new long paired-end mate 1s of %d reads and storing in "%s"' %
              (nreads_pe_full, tmpfile_1), file=sys.stderr)
        cat_func([args_m1], tmpfile_1, nreads_pe_full, seqs_to_cat=seqs_to_cat_pe)
        print('Concatenating new long paired-end mate 2s of %d reads and storing in "%s"' %
              (nreads_pe_full, tmpfile_2), file=sys.stderr)
        cat_func([args_m2], tmpfile_2, nreads_pe_full, seqs_to_cat=seqs_to_cat_pe)

    return tmpfile, tmpfile_1, tmpfile_2, nreads_unp_per_thread, nreads_pe_per_thread


def run_cmd(cmd, odir, nthreads, nthreads_total, paired, args):
    #if we're running with multiprocess
    if args.multiprocess != MP_DISABLED:
        running = []
        for thread in (xrange(0,nthreads_total)):
            cmd_ = cmd
            if args.multiprocess >= MP_SEPARATE:
                if paired:
                    cmd_ = cmd_ % (thread+1,thread+1,"_%d" % (thread+1))
                else:
                    cmd_ = cmd_ % (thread+1,"_%d" % (thread+1))
            print(cmd_)
            subp = subprocess.Popen(cmd_,shell=True,bufsize=-1)
            running.append(subp)
        for i, subp in enumerate(running):
            ret = subp.wait()
            if ret != 0:
                return ret
        with open(os.path.join(odir, 'cmd_%d.sh' % nthreads_total), 'a') as ofh:
            ofh.write(cmd + "\n")
        return 0
    ret = os.system(cmd)
    with open(os.path.join(odir, 'cmd_%d.sh' % nthreads), 'w') as ofh:
        ofh.write("#!/bin/sh\n")
        ofh.write(cmd + "\n")
    return ret


def go(args):
    if not args.U and not args.m1 and not args.m2:
        raise RuntimeError('Must specify --U or --m1/--m2')

    sensitivity_map = {'vs': '--very-sensitive',
                       'vsl': '--very-sensitive-local',
                       's': '--sensitive',
                       'sl': '--sensitive-local',
                       'f': '--fast',
                       'fl': '--fast-local',
                       'vf': '--very-fast',
                       'vfl': '--very-fast-local'}
    
    tmpdir = args.tempdir
    if tmpdir is None:
        tmpdir = tempfile.mkdtemp()
    if not os.path.exists(tmpdir):
        mkdir_quiet(tmpdir)
    if not os.path.isdir(tmpdir):
        raise RuntimeError('Temporary directory isn\'t a directory: "%s"' % tmpdir)

    print('Setting up binaries', file=sys.stderr)
    for name, tool, branch, preproc, aligner_args in get_configs(args.config):
        if name == 'name' and branch == 'branch':
            continue  # skip header line
        build, pull = False, False
        build_dir = os.path.join(args.build_dir, name)
        if os.path.exists(build_dir) and args.force_builds:
            print('  Removing existing "%s" subdir because of --force' % build_dir, file=sys.stderr)
            shutil.rmtree(build_dir)
            build = True
        elif os.path.exists(build_dir):
            pull = True
        elif not os.path.exists(build_dir):
            build = True

        if pull and not args.no_pull:
            print('  Pulling "%s"' % name, file=sys.stderr)
            os.system('cd %s && git pull' % build_dir)
            make_tool_version(name, tool, preproc)
        elif build:
            print('  Building "%s"' % name, file=sys.stderr)
            install_tool_version(name, tool, tool_repo(tool, args), branch, preproc)

    series = list(map(int, args.nthread_series.split(',')))
    assert len(series) > 0
    print('  series = %s' % str(series))

    print('Preparing reads', file=sys.stderr)


    sensitivities = args.sensitivities.split(',')
    sensitivities = zip(map(sensitivity_map.get, sensitivities), sensitivities)
    print('Generating sensitivity series: "%s"' % str(sensitivities), file=sys.stderr)

    print('Creating output directory "%s"' % args.output_dir, file=sys.stderr)
    mkdir_quiet(args.output_dir)

    print('Generating %scommands' % ('' if args.dry_run else 'and running '), file=sys.stderr)

    #allows for doing one or both paired modes
    paired_modes = []
    if args.paired_mode != PAIRED_ONLY:
    paired_modes.append(False)
    if args.paired_mode != UNPAIRED_ONLY:
    paired_modes.append(True)
    # iterate over sensitivity levels
    for sens, sens_short in sensitivities:

        # iterate over unpaired / paired-end
        for paired in paired_modes:

            # iterate over numbers of threads
            for nthreads in series:

                last_tool = ''
                # iterate over configurations
                for name, tool, branch, preproc, aligner_args in get_configs(args.config):
                    name_ = name
                    if args.no_no_io_reads:
                        name_ = "%s-id" % (name)
                    else:
                        name_ = "%s-nid" % (name)
                    odir = os.path.join(args.output_dir, name_, sens[2:], 'pe' if paired else 'unp')
                    if tool != last_tool:
                        print('Checking that index files exist', file=sys.stderr)
                        index = args.hisat_index if tool == 'hisat' else args.index
                        if not verify_index(index, tool):
                            raise RuntimeError('Could not verify index files')
                        last_tool = tool


                    if not os.path.exists(odir):
                        print('  Creating output directory "%s"' % odir, file=sys.stderr)
                        mkdir_quiet(odir)

                    # Compose command
                    runname = '%s_%s_%s_%d' % (name, 'pe' if paired else 'unp', sens_short, nthreads)
                    stdout_ofn = os.path.join(odir, '%d.txt' % nthreads)
                    sam_ofn = os.path.join(odir if args.sam_output_dir else tmpdir, '%s.sam' % runname)
                    sam_ofn = '/dev/null' if args.sam_dev_null else sam_ofn
                    cmd = ['build/%s/%s' % (name, tool_exe(tool))]
                    nthreads_total = nthreads
                    if args.multiprocess != MP_DISABLED:
                        stdout_ofn = os.path.join(odir, '%d%%s.txt' % (nthreads))
                        nthreads = 1
                    cmd.extend(['-p', str(nthreads)])
                    if tool == 'bowtie2' or tool == 'hisat':
                        nr_pe = nreads_pe if tool == 'bowtie2' else nreads_pe_hs
                        nr_unp = nreads_unp if tool == 'bowtie2' else nreads_unp_hs
                        nreads = (nr_pe * nthreads) if paired else (nr_unp * nthreads)
                        cmd.extend(['-u', str(nreads)])
                        cmd.append(sens)
                        cmd.extend(['-S', sam_ofn])
                        cmd.extend(['-x', index])
                        if paired:
                            cmd.extend(['-1', tmpfile_1 if tool == 'bowtie2' else tmpfile_1_hs])
                            cmd.extend(['-2', tmpfile_2 if tool == 'bowtie2' else tmpfile_2_hs])
                        else:
                            cmd.extend(['-U', tmpfile if tool == 'bowtie2' else tmpfile_hs])
                        cmd.append('-t')
                        if aligner_args is not None and len(aligner_args) > 0:  # from config file
                            cmd.extend(aligner_args.split())
                        if args.multiprocess != MP_DISABLED:
                            cmd.append('--mm')
                        cmd.extend(['>', stdout_ofn])
                    elif tool == 'bowtie':
                        nreads = (nreads_pe_short * nthreads) if paired else (nreads_unp_short * nthreads)
                        cmd.extend(['-u', str(nreads)])
                        cmd.extend([index])
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
                        if args.multiprocess != MP_DISABLED:
                            cmd.append('--mm')
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
                        run_cmd(cmd, odir, nthreads, nthreads_total, paired, args)
                        if args.multiprocess == MP_DISABLED:
                            assert os.path.exists(sam_ofn)
                            if args.delete_sam and not args.sam_dev_null:
                                os.remove(sam_ofn)
                        else:
                            consolidate_mp_output(stdout_ofn)
                    #put nthreads back to the total for the next run
                    nthreads = nthreads_total


if __name__ == '__main__':

    # Output-related options
    parser = argparse.ArgumentParser(description='Run a single series of thread-scaling experiments.')
    default_bt_repo = "https://github.com/BenLangmead/bowtie.git"
    default_bt2_repo = "https://github.com/BenLangmead/bowtie2.git"
    default_hs_repo = "https://github.com/BenLangmead/hisat.git"  # this is my fork

    requiredNamed = parser.add_argument_group('required named arguments')
    requiredNamed.add_argument('--index', metavar='index_basename', type=str, required=True,
                        help='Path to indexes; omit final ".1.bt2" or ".1.ebwt".  Should usually be a human genome index, with filenames like hg19.* or hg38.*')
    requiredNamed.add_argument('--config', metavar='pct,pct,...', type=str, required=True,
                        help='Specifies path to config file giving configuration short-names, tool names, branch names, compilation macros, and command-line args.  (Provided master_config.tsv is probably sufficient)')
    requiredNamed.add_argument('--output-dir', metavar='path', type=str, required=True,
                        help='Directory to put thread timings in.')
    requiredNamed.add_argument('--build-dir', metavar='path', type=str, default='build',
                        help='Directory to put git working copies & built binaries in.')
    parser.add_argument('--U', metavar='path', type=str, required=False,
                        help='Path to file to use for unpaired reads.  Will concatenate multiple copies according to # threads.')
    parser.add_argument('--m1', metavar='path', type=str, required=False,
                        help='Path to file to use for mate 1s for paried-end runs.  Will concatenate multiple copies according to # threads.')
    parser.add_argument('--m2', metavar='path', type=str, required=False,
                        help='Path to file to use for mate 2s for paried-end runs.  Will concatenate multiple copies according to # threads.')
    parser.add_argument('--nthread-series', metavar='int,int,...', type=str, required=False,
                        help='Series of comma-separated ints giving the number of threads to use.  E.g. --nthread-series 10,20,30 will run separate experiments using 10, 20 and 30 threads respectively.  Deafult: just one experiment using max # threads.')
    parser.add_argument('--repo', metavar='url', type=str, default=default_bt_repo,
                        help='Path to repo for tool, which we clone for each version we test (deafult: %s)' % default_bt_repo)
    parser.add_argument('--sensitivities', metavar='level,level,...', type=str, default='s',
                        help='Series of comma-separated sensitivity levels, each from the set {vf, vfl, f, fl, s, sl, vs, vsl}.  Default: s (just --sensitive).')
    parser.add_argument('--tempdir', metavar='path', type=str, required=False,
                        help='Picks a path for temporary files.')
    parser.add_argument('--force-builds', action='store_const', const=True, default=False,
                        help='Overwrite binaries that already exist')
    parser.add_argument('--force-runs', action='store_const', const=True, default=False,
                        help='Overwrite run output files that already exist')
    parser.add_argument('--no-pull', action='store_const', const=True, default=False,
                        help='Do not git pull into the existing build directories')
    parser.add_argument('--dry-run', action='store_const', const=True, default=False,
                        help='Just verify that jobs can be run, then print out commands without running them; useful for when you need to wrap the bowtie2 commands for profiling or other reasons')
    parser.add_argument('--sam-output-dir', action='store_const', const=True, default=False,
                        help='Put SAM output in the output directory rather than in the temporary directory.  Usually we don\'t really care to examine the SAM output, so the default is reasonable.')
    parser.add_argument('--sam-dev-null', action='store_const', const=True, default=False,
                        help='Send SAM output directly to /dev/null.')
    parser.add_argument('--delete-sam', action='store_const', const=True, default=False,
                        help='Delete SAM file as soon as aligner finishes; useful if you need to avoid exhausting a partition')
    parser.add_argument('--mp', metavar='int', type=int, default=0,
                        help='Use multiprocessing with <int> threads per process.  Default: use one process and add threads.')
    parser.add_argument('--reads-per-thread', metavar='int', type=int, default=0,
                        help='set # of reads to align per thread/process directly, overrides --multiply-reads setting')
    parser.add_argument('--shorten-reads', action='store_const', const=True, default=False,
                        help='if running Bowtie or something similar set this so that generated reads will be half the normal size (e.g. 50 vs. 100 bp)')

    go(parser.parse_args())
