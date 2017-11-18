#!/usr/bin/env python

from __future__ import print_function

inputs = {
    '/tmp': 'ssd_tmp',
    '/scratch/04265/benbo81/ht-final-block-01OST': 'lustre_01ost',
    '/scratch/04265/benbo81/ht-final-block-16OST': 'lustre_16ost'}

outputs = {
    '/dev/null': 'stub_devnull',
    '/tmp/out.sam': 'ssd_tmp',
    '/scratch/04265/benbo81/ht-final-block-01OST': 'lustre_01ost',
    '/scratch/04265/benbo81/ht-final-block-16OST': 'lustre_16ost'}

maxlen = len('/scratch/04265/benbo81/ht-final-block-01OST')

for i in range(1, 11):
    fn = '.fstest0%02d.out' % i
    inp, out = None, None
    trial = 0
    with open(fn) as fh:
        for ln in fh:
            ln = ln.rstrip()
            if ln.endswith('directories'):
                continue
            if ln.startswith('stripe_count'):
                continue
            if ln.startswith('Copying') or ln.startswith('Aligning'):
                continue
            toks = ln.rstrip().split()
            if ln.startswith('Input:'):
                inp, out = inputs[toks[1][:maxlen]], outputs[toks[3][:maxlen]]
                trial = 0
            elif 'stddev' not in ln:
                print(','.join(list(map(str, [i, trial, inp, out] + toks[:6]))))
                trial += 1
