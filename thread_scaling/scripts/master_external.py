"""
Master script for setting up thread-scaling experiments for non-Bowtie related tools (e.g. Kraken, Jellyfish, BWA)
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
import master

#use methods from master.py to implement a "light" version 
#that doesn't have tool specific code

#options:
#1) tool command line (except reads file and # of threads)
#2) source reads file
#3) thread series (e.g. 1,5,10)
#)  multiprocess mode
#4) reads count per thread
#5) don't generate reads (if already present)

def head(in_fn, num_seqs, process_cmd, out_fn):
    extra_cmd = ''
    if process_cmd:
        extra_cmd = "| %s" % (process_cmd)
    cmd = 'head -%d %s %s > %s' % (master.LINES_PER_FASTQ_REC * num_seqs, in_fn, extra_cmd, out_fn)
    os.system(cmd)
    return out_fn 

#assumes input reads file (either real or no-io derived) has already been shortened for tools like bowtie
def prepare_reads(args, tmpdir, max_threads, tool, input_fn, cat_reads=False, generate_reads=True):
    num_seqs = max_threads * args.reads_per_thread
    if args.multiprocess >= master.MP_SEPARATE:
        num_seqs = args.reads_per_thread
    (in_path, in_fn) = os.path.split(input_fn)
    #out_fn = "%s.%s.%d" % (os.path.join(tmpdir, in_fn), tool, num_seqs)
    out_fn = "%s.fq" % os.path.join(tmpdir, in_fn)
    if args.multiprocess >= master.MP_SEPARATE:
        out_fn = os.path.join(tmpdir, ("%s." % in_fn) + '%d.fq')
    sys.stdout.write("Preparing reads: %s %s %d\n" % (input_fn, out_fn, num_seqs))
    #if doing a small set of input reads which needs to be copied to be amplified for the # of threads (e.e. no-io derived reads)
    if cat_reads:
        num_cats = num_seqs / master.DEFAULT_BASE_READS_COUNT
        if num_cats < 1:
            sys.stderr.write("total number of sequences for maximum threads in series %d must be >= %d, exiting\n" % (max_threads, master.DEFAULT_BASE_READS_COUNT))
            sys.exit(-1)
        if args.multiprocess >= master.MP_SEPARATE:
            num_cats = args.reads_per_thread / master.DEFAULT_BASE_READS_COUNT
            master.copy_read_set(input_fn, tmpdir, num_cats, max_threads) 
        else:
            master.cat([input_fn], out_fn, num_cats) 
    #instead we just assume the input file is large enough for the number of reads we want
    else:
        if args.multiprocess >= master.MP_SEPARATE:
            master.split_read_set(input_fn, tmpdir, args.reads_per_thread, max_threads) 
        else:
            head(input_fn, num_seqs, '', out_fn)
    #TODO implement MP version (split vs. copy depending on real vs. io)
    return out_fn

#mapping exec name => (tool_name, input param, thread param, additional params, output param)
tool_map = {'bwa':['bwa','','-t','','> /dev/null 2> %s'], 'classify':['kraken', '-f', '-t', '-M -u %d', '> /dev/null 2> %s'], 'jellyfish':['jellyfish', '', '-t', '-m 21 -s 100M -C','--no-write --timing=%s']}
def get_tool_params(args):
    tool_fields = args.cmd.split(' ')
    tool_path = tool_fields[0]
    (tool_path_, tool) = os.path.split(tool_path)
    (tool, input_opt, threads_opt, additional_opts, output) = tool_map[tool]
    tool_cmd = "%s %s" % (args.cmd, args.genome)
    if tool == 'kraken':
        additional_opts = additional_opts % args.reads_per_thread
    return (tool, tool_path, tool_cmd, input_opt, threads_opt, additional_opts, output) 

def load_genome_index(args, tool, tool_path):
    if tool == 'bwa':
        os.system("%s shm %s" % (tool_path, args.genome))

def unload_genome_index(args, tool, tool_path):
    if tool == 'bwa':
        os.system("%s shm -d" % (tool_path))

def go(args):
    nnodes, ncpus = master.get_num_nodes(), master.get_num_cores()
    print('# NUMA nodes = %d' % nnodes, file=sys.stderr)
    print('# CPUs = %d' % ncpus, file=sys.stderr)
    
    tmpdir = args.tempdir
    if tmpdir is None:
        tmpdir = tempfile.mkdtemp()
    if not os.path.exists(tmpdir):
        mkdir_quiet(tmpdir)
    if not os.path.isdir(tmpdir):
        raise RuntimeError('Temporary directory isn\'t a directory: "%s"' % tmpdir)
    
    print('Generating thread series', file=sys.stderr)
    series = master.gen_thread_series(args, ncpus)
    print(' series = %s' % str(series))
    
    (tool, tool_path, tool_cmd, input_opt, threads_opt, additional_opts, output) = get_tool_params(args)
    if args.multiprocess != master.MP_DISABLED:
        output = '> /dev/null 2>> %s'
        #load shared memory with genome index
        load_genome_index(args, tool, tool_path)
   
    odir = os.path.join(args.output_dir)
    if not os.path.exists(odir):
        print('  Creating output directory "%s"' % odir, file=sys.stderr)
        master.mkdir_quiet(odir)

    #TODO: implement read counting if not passed in
    reads_count = args.reads_count
    cat_reads = False
    #if we get the exact # of reads as in the default no-io derived reads
    #we'll concatenate, otherwise assume we have enough to get to # of reads
    #for max thread count
    if reads_count == master.DEFAULT_BASE_READS_COUNT:
       cat_reads = True 

    #now loop over series generating reads for each thread point
    for i in series:
        processed_fn = prepare_reads(args, tmpdir, i, tool, args.U, cat_reads=cat_reads, generate_reads=(not args.no_reads))
        cmd = [tool_cmd]
        cmd.append(threads_opt)
        num_threads = i
        input_fn = processed_fn
        if args.multiprocess != master.MP_DISABLED:
            num_threads = 1
        cmd.append(num_threads)
        cmd.append(additional_opts)
        cmd.append(input_opt)
        cmd.append(input_fn)
        output_ = output % (os.path.join(odir, "%d.txt" % int(i)))
        cmd.append(output_)
        cmd = ' '.join([str(x) for x in cmd])
        print(cmd)
        paired = False
        master.run_cmd(cmd, odir, num_threads, i, paired, args)
        if args.multiprocess >= master.MP_SEPARATE:
            (in_path, in_fn) = os.path.split(args.U)
            input_fns = os.path.join(tmpdir, "%s*.fq" % in_fn)
            sys.stderr.write("deleting %s\n" % input_fns)
            os.system('rm %s' % input_fns)
        else:
            os.remove(processed_fn)

    if args.multiprocess != master.MP_DISABLED:
        unload_genome_index(args, tool, tool_path)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Set up thread scaling experiments.')
    
    requiredNamed = parser.add_argument_group('required named arguments')
    requiredNamed.add_argument('--cmd', metavar='tool command line', type=str, required=True,
                               help="path to aligner + command to run (e.g. /path/to/bwa mem)")
    requiredNamed.add_argument('--U', metavar='path', type=str, required=False,
                        help='Path to file to use for unpaired reads; will concatenate multiple copies according to # threads.')
    requiredNamed.add_argument('--output-dir', metavar='path', type=str, required=True,
                        help='Directory to put thread timings in.')
    requiredNamed.add_argument('--reads-per-thread', metavar='int', type=int, required=True,
                        help='set # of reads to align per thread/process directly')
    parser.add_argument('--genome', metavar='path to genome index', type=str, default="",
                               help="index genome file appropriate for current tool (e.g. /path/to/hg19.fa for bwa)")
    parser.add_argument('--tempdir', metavar='path', type=str, required=False,
                        help='Picks a path for temporary files.')
    parser.add_argument('--nthread-series', metavar='int,int,...', type=str, required=False,
                        help='Series of comma-separated ints giving the number of threads to use.  E.g. --nthread-series 10,20,30 will run separate experiments using 10, 20 and 30 threads respectively.  Deafult: just one experiment using max # threads.')
    parser.add_argument('--no-reads', action='store_const', const=True, default=False,
                        help='skip read generation step; assumes reads have already been generated in the --tempdir location')
    parser.add_argument('--multiprocess', metavar='int', type=int, default=master.MP_DISABLED,
                        help='run n independent processes instead of n threads in one process where n is the current thread count. 0=disable, 1=use same source reads file for every process, >1=use pre-split sources files one per process and assume # passed in is the # of reads to input per process')
    parser.add_argument('--shorten-reads', action='store_const', const=True, default=False,
                        help='if running Bowtie or something similar set this so that generated reads will be half the normal size (e.g. 50 vs. 100 bp)')
    #here for compatibility with master.py only
    parser.add_argument('--paired-mode', metavar='int', type=int, default=2,
                        help='Which of the three modes to run: both unpaired and paired (1), unpaired only (2), paired only (3)')
    parser.add_argument('--no-no-io-reads', action='store_const', const=True, default=False,
                        help='Don\'t Extract compiled reads from no-io branches of Bowtie2 and Hisat; instead use what\'s passed in')
    parser.add_argument('--multiply-reads', metavar='int', type=int, default=1,
                        help='Duplicate the input reads file this many times before scaling according to the number of reads.')
    parser.add_argument('--short-factor', metavar='float', type=int, default=1,
                        help='For unpaired experiments, multiple base number of reads by this factor.')
    parser.add_argument('--paired-end-factor', metavar='float', type=int, default=1,
                        help='For paired-end experiments, multiply base number of reads by this factor.')
    parser.add_argument('--reads-count', metavar='int', type=int, default=0,
                        help='set explicitly to # of reads in source reads file to avoid the cost of counting each time')

    go(parser.parse_args())


