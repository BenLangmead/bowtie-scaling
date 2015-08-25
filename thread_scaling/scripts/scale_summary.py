__author__ = 'langmead'

import re
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--ignore-above', type=int, default=9999,
                    help='Ignore experiments with more than this many threads')
parser.add_argument('--input', nargs='+', help='Input files')
parser.add_argument('--min-max-avg', type=str, default=None, help='Write min, max, avg table here')
parser.add_argument('--scatter', type=str, default=None, help='Write scatter plot here')
args = parser.parse_args()

scatter_fh = None
if args.scatter is not None:
    scatter_fh = open(args.scatter, 'w')

table = []
for fn in args.input:
    print("Processing '%s'" % fn, file=sys.stderr)
    m = re.match('.*_([0-9]*)\.out', fn)
    nthreads = int(m.group(1))
    if nthreads > args.ignore_above:
        continue
    thread_times, cpu_changeovers, node_changeovers = {}, {}, {}
    with open(fn) as fh:
        for ln in fh:
            if not ln.startswith('thread:'):
                continue
            if 'node_changeovers:' in ln:
                m2 = re.match('thread: ([0-9]*) node_changeovers: ([0-9]*)', ln)
                assert m2 is not None
                thread_id = int(m2.group(1))
                node_changeovers[thread_id] = int(m2.group(2))
            elif 'cpu_changeovers' in ln:
                m2 = re.match('thread: ([0-9]*) cpu_changeovers: ([0-9]*)', ln)
                assert m2 is not None
                thread_id = int(m2.group(1))
                cpu_changeovers[thread_id] = int(m2.group(2))
            elif 'time:' in ln:
                m2 = re.match('thread: ([0-9]*) time: ([0-9]*):([0-9]*):([0-9.]*)', ln)
                assert m2 is not None
                thread_id = int(m2.group(1))
                hr, mn, sc = m2.group(2), m2.group(3), m2.group(4)
                sc = float(sc) + (int(mn) * 60) + (int(hr) * 60 * 60)
                thread_times[thread_id] = sc
                if scatter_fh is not None:
                    scatter_fh.write('%d\t%0.03f\n' % (nthreads, sc))
    assert len(thread_times) == nthreads
    sm = sum(thread_times.values())
    cpu_tot = sum(cpu_changeovers.values())
    node_tot = sum(node_changeovers.values())
    table.append([nthreads, min(thread_times.values()), max(thread_times.values()), float(sm)/nthreads,
                  min(cpu_changeovers.values()), max(cpu_changeovers.values()), float(cpu_tot)/nthreads,
                  min(node_changeovers.values()), max(node_changeovers.values()), float(node_tot)/nthreads])

if scatter_fh is not None:
    scatter_fh.close()

if args.min_max_avg is not None:
    with open(args.min_max_avg, 'w') as ofh:
        for tup in sorted(table):
            ofh.write(('\t'.join(map(str, tup))) + '\n')
