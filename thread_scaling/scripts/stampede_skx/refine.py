#!/usr/bin/env python

# 1 processes, 17179869184 bytes each
# 536870912,00:00:24.515,00:00:22.465,00:00:04.653

import sys

print('input,output,mp,mt,min,max,sum,mean,stddev')
inp, out, mp, mt = None, None, None, None
for ln in sys.stdin:
    toks = ln.split()
    
    # Input: /tmp output: /dev/null mp: 1 mt: 256
    if ln.startswith('Input:'):
        assert len(toks) == 8
        inp, out, mp, mt = toks[1], toks[3], toks[5], toks[7]
        if 'fstest-16OST' in inp:
            inp = 'lustre16ost'
        if 'fstest-16OST' in out:
            out = 'lustre16ost'
        if 'fstest-01OST' in inp:
            inp = 'lustre1ost'
        if 'fstest-01OST' in out:
            out = 'lustre1ost'
        if inp == '/dev/null': inp = 'devnull'
        if out == '/dev/null': out = 'devnull'
        if inp == '/tmp': inp = 'ssd'
        if out == '/tmp': out = 'ssd'
    elif ln.rstrip().endswith('stddev'):
        continue
    elif len(toks) == 7:
        # ht-final-block N        min     max     sum     mean    stddev
        # ht-final-block 256      22.144  26.062  6215.41 24.2789 1.12638
        print(','.join(map(str, [inp, out, mp, mt, toks[2], toks[3], toks[4], toks[5], toks[6]])))
    elif ln[0] == '#' or ln.startswith('stripe'):
        continue
    else:
        raise RuntimeError('Bad line: "%s"' % ln.rstrip())
