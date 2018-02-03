#!/usr/bin/env python

from __future__ import print_function

# === /tmp /dev/null 1

def parse_time(tmst):
    toks = tmst.split(':')
    assert len(toks) == 3
    secs = float(toks[2])
    secs += float(toks[1]) * 60
    return secs + float(toks[0]) * 60 * 60


print(','.join(['input,output,num_outputs,secs']))


def rename(st):
    if 'fstest-16OST' in st:
        return 'lustre16'
    elif 'fstest-01OST' in st:
        return 'lustre1'
    elif st == '/tmp':
        return 'ssd'
    return 'devnull'


with open('.fstest.sh.err') as fh:
    for ln in fh:
        ln = ln.rstrip()
        if ln.startswith('==='):
            toks = ln.split()[1:]
            if len(toks) != 3:
                raise ValueError('invalid === line: ' + ln)
            inp, outp, nout = toks
            inp = rename(inp)
            outp = rename(outp)
            continue
        if ln.startswith('Time searching'):
            secs = parse_time(ln.split()[-1])
            print(','.join([inp, outp, nout, str(secs)]))
