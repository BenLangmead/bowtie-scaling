#!/usr/bin/env python

from __future__ import print_function
import sys
import glob


def convert(st):
    if st[-1] == 't':
        return float(st[:-1]) * 1024 * 1024 * 1024 * 1024
    elif st[-1] == 'g':
        return float(st[:-1]) * 1024 * 1024 * 1024
    elif st[-1] == 'm':
        return float(st[:-1]) * 1024 * 1024
    elif st[-1] == 'k':
        return float(st[:-1]) * 1024
    return float(st)


def gt(m1, m2):
    return convert(m1) > convert(m2)


for fn in glob.glob('*.top'):
    # bwa_unp_0_0_48_2.top
    fntoks = fn.split('_')
    if fntoks[-1] != '1.top':
        continue
    nthreads = int(fntoks[-2])
    high_mem = '0.0m'
    with open(fn) as fh:
        for ln in fh:
            toks = ln.strip().split()
            if len(toks) == 0:
                continue
            if toks[-1] == 'bwa':
                mem = toks[5]
                #print((mem, high_mem))
                if gt(mem, high_mem):
                    high_mem = mem
    print('%d %0.3f' % (nthreads, convert(high_mem)))
