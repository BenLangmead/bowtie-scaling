"""
Script for tabulating results from master.py
"""

from __future__ import print_function
import subprocess
import sys
from operator import itemgetter
import re

if len(sys.argv) < 2:
    raise RuntimeError('Too few arguments')

print('\t'.join(['experiment', 'run', 'tool', 'lock', 'version', 'sensitivity', 'paired', 'threads', 'seconds']))
for mydr in sys.argv[1:]:
    p = subprocess.Popen("find -L %s -name '*.txt' -not -name \"*_*\" | xargs grep \"thread:.*time\" | sed 's/:thread:.*time: /|/'" % mydr,
                         stdout=subprocess.PIPE, shell=True)
    dr = None
    dedup = {}
    for ln in p.stdout:
        (dr, time_) = ln.rstrip().split('|')
        exp, run, sens, pe, thr = dr.split('/')
        dr_ = '/'.join([exp, run, sens, pe])
        thr = int(thr[:-4])
        toks = map(float, time_.split(':'))
        secs = toks[-1]
        secs += toks[-2] * 60
        secs += toks[-3] * 60 * 60
        if dr in dedup:
            if secs < dedup[dr][2]:
                secs = dedup[dr][2]
        dedup[dr] = [dr_, thr, secs]
    for (dr_, thr, secs) in sorted(dedup.values(), key=itemgetter(0,1,2)):
        exp, run, sens, pe = dr_.split('/')
        tool = 'hisat'
        outbuff = ''
        m1=re.compile(r'output(\d+)-').search(run)
        if m1 is not None:
            outbuff = m1.group(1)            
        #if '-tbb-' in run or ('batch' in run and 'cleanparse' not in run):
        #    continue
        if run.startswith('bt2-'):
            tool = 'bowtie2'
        elif run.startswith('bt-'):
            tool = 'bowtie'
        lock = 'tinythreads fast_mutex'
        if 'batch-tt' in run:
            lock = 'batch tinythreads fast_mutex'
        elif 'tdelay' in run:
            lock = 'Delayed TBB Threads Queuelock'
        elif 'tndelay' in run:
            lock = 'TBB Threads Queuelock'
        elif 'tbbpin-q' in run and 'rawseqs' in run:
            lock = 'TBB queuing_mutex noio reads'
        #elif 'batch-tbbpin-q' in run:
        #    lock = 'batch TBB queuing_mutex'
        elif 'tbbpin-spin' in run or 'tbb-spin' in run:
            lock = 'TBB spin_mutex'
        elif 'tbbpin-heavy' in run or 'tbb-heavy' in run:
            lock = 'TBB mutex'
        elif 'tbbpin-q' in run or 'tbb-q' in run:
            lock = 'TBB queuing_mutex'
        elif 'tbbpin-co-q' in run:
            lock = 'TBB/JHU CohortLock queue'
        elif 'tbbpin-co-tktptl' in run:
            lock = 'TBB/JHU CohortLock tktptl'
        elif 'no-io' in run or 'noio' in run:
            lock = 'None (stubbed I/O)'
        elif '-mp' in run:
            lock = 'MP tinythreads fast_mutex'
        version = 'Original parsing'
        #since batch_parsing is built on cleanparse
        if 'cleanparse' in run:
            version = 'Two-phase parsing'
        if 'batch' in run or 'delay' in run:
            version = 'Batch parsing'
        if '_bbp_' in run or 'obbatch' in run or '-bbatch' in run:
            version = 'Fixed Batch parsing'
        if 'output' in run or '-out' in run:
            version = "%s New Output" % (version)
        if 'mem' in run or '-p' in run:
            #version = "%s Large Pool" % (version)
            lock = "%s Large Pool" % (lock)
        if len(outbuff) > 0:
            lock = "%s OutBuff=%s" % (lock,outbuff) 
        if 'norandom' in run:
            version = "%s, No randomization" % (version)
        print('\t'.join(map(str, [exp, run, tool, lock, version, sens, pe, thr, secs])))
