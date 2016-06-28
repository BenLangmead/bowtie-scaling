"""
Script for tabulating results from master.py
"""

from __future__ import print_function
import subprocess
import sys

if len(sys.argv) < 2:
    raise RuntimeError('Too few arguments')

print('\t'.join(['experiment', 'run', 'tool', 'lock', 'version', 'sensitivity', 'paired', 'threads', 'seconds']))
for mydr in sys.argv[1:]:
    #bwa
    bwap = subprocess.Popen("find %s -wholename '*bwa-*.txt' | xargs grep \"M::mem_process_seqs.*Processed\" | sed 's/\[M::mem_process_seqs\].*CPU sec, //' | sed 's/ real sec$//'" % mydr,
                        stdout=subprocess.PIPE, shell=True)
    #kraken
    kp = subprocess.Popen("find %s -wholename '*k-*.txt' | xargs grep \"processed in \" | sed 's/:.*processed in /:/' | sed 's/s (.*$//'" % mydr,
                         stdout=subprocess.PIPE, shell=True)
    #jellyfish
    jfp = subprocess.Popen("find %s -wholename '*jf-*.txt' | xargs grep \"Counting \" | sed 's/Counting //'" % mydr,
                         stdout=subprocess.PIPE, shell=True)
    dr = None
    sens = 'default'
    pe = 'unp'
    for p in [bwap, kp, jfp]:
        dedup = {}
        #first find the longest time for each thread count
        for ln in p.stdout:
	    if True:
                sys.stderr.write("%s" % ln)
                (dr, secs) = ln.rstrip().split(":")
                secs = float(secs)
	        exp, run, thr = dr.split('/')
                if dr in dedup:
                    if secs < dedup[dr]:
                        secs = dedup[dr]
                dedup[dr] = secs
        #now print out
        for (dr,secs) in dedup.iteritems():
            if True: 
	        exp, run, thr = dr.split('/')
	        thr = thr[:-4]
	        tool = 'bwa'
	        if run.startswith('k-'):
		    tool = 'kraken'
	        elif run.startswith('jf-'):
		    tool = 'jellyfish'
	        lock = 'default'
	        version = 'Original parsing'
	        print('\t'.join(map(str, [exp, run, tool, lock, version, sens, pe, thr, secs])))
