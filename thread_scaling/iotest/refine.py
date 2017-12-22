#!/usr/bin/env python

# 1 processes, 17179869184 bytes each
# 536870912,00:00:24.515,00:00:22.465,00:00:04.653

import sys


def parse_time(tmst):
    # 00:00:20.798
    toks = tmst.split(':')
    assert len(toks) == 3
    secs = float(toks[2])
    secs += float(toks[1]) * 60
    return secs + float(toks[0]) * 60 * 60


print('nproc,out,block,tnobuf,tbuf,tdd')
num_procs, out_type = None, None
for ln in sys.stdin:
    if 'processes' in ln:
        num_procs = int(ln.split()[0])
    elif ln.startswith('Writing'):
        continue
    elif 'stubbed out' in ln:
        out_type = 'devnull'
    # Lustre out ($SCRATCH) (1 OST stripes)
    elif 'Lustre out' in ln:
        toks = ln.split()
        stripes = int(toks[3][1:])
        out_type = 'lustre_%d_ost' % stripes
    elif 'SSD out' in ln:
        out_type = 'ssd'
    elif ln.count(',') == 3:
        toks = ln.rstrip().split(',')
        block_sz = int(toks[0])
        t1, t2, t3 = parse_time(toks[1]), parse_time(toks[2]), parse_time(toks[3])
        print(','.join(map(str, [num_procs, out_type, block_sz, t1, t2, t3])))
    else:
        raise RuntimeError('Bad line: "%s"' % ln.rstrip())
