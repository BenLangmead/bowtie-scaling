"""
Script for tabulating results from master.py
"""

from __future__ import print_function
import subprocess
import sys

if len(sys.argv) < 2:
    raise RuntimeError('Too few arguments')

print('\t'.join(['experiment', 'run', 'tool', 'sensitivity', 'paired', 'threads', 'seconds']))
for mydr in sys.argv[1:]:
    p = subprocess.Popen("find %s -name '*.txt' | xargs tail -n 1 | sed 's/.*: //'" % mydr,
                         stdout=subprocess.PIPE, shell=True)
    dr = None
    for ln in p.stdout:
        if ln.startswith("==>"):
            dr = ln.split()[1]
        elif ':' in ln:
            toks = map(float, ln.rstrip().split(':'))
            secs = toks[-1]
            secs += toks[-2] * 60
            secs += toks[-3] * 60 * 60
            exp, run, sens, pe, thr = dr.split('/')
            thr = thr[:-4]
            tool = 'hisat'
            if run.startswith('bt2-'):
                tool = 'bowtie2'
            elif run.startswith('bt-'):
                tool = 'bowtie'
            print('\t'.join(map(str, [exp, run, tool, sens, pe, thr, secs])))
