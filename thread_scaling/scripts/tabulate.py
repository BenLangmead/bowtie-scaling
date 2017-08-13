#!/usr/bin/env python

# results are in subdirectories like:
# small/results/ht/ht-baseline-tbbq/unp/ht-baseline-old_unp_0_0_2.err/out

from __future__ import print_function
import sys
import os

if len(sys.argv) < 2:
    raise RuntimeError('Specify system as first arg')

system = sys.argv[1]
system_dir = os.path.join(system, 'results')

if not os.path.exists(system_dir):
    raise RuntimeError('No such directory as "%s"' % system_dir)

def parse_dir(dr):
    toks = dr.split('/')
    assert toks[0] == system
    assert toks[1] == 'results'
    aligner = toks[2]
    assert aligner in ['bt', 'bt2', 'ht']
    series = toks[3]
    assert series.startswith(aligner)
    series = series[len(aligner) + 1:]
    pe = toks[4]
    return aligner, series, pe


def parse_file(fn, pe=None):
    fn = fn[:-4]  # remove .err/.out
    assert len(fn.split('_')) == 6, fn
    prefix, pe2, threads_per_proc, proc_id, tot_threads, attempt = fn.split('_')
    if pe2 is not None and pe2 != pe:
        raise RuntimeError('Unexpected prefix: "%s"' % (prefix + '_' + pe2))
    assert len(threads_per_proc) > 0, fn
    assert len(proc_id) > 0, fn
    assert len(tot_threads) > 0, fn
    threads_per_proc, proc_id, tot_threads = int(threads_per_proc), int(proc_id), int(tot_threads)
    attempt = int(attempt)
    return threads_per_proc, proc_id, tot_threads, attempt


def parse_time(tmst):
    # 00:00:20.798
    toks = tmst.split(':')
    assert len(toks) == 3
    secs = float(toks[2])
    secs += float(toks[1]) * 60
    return secs + float(toks[0]) * 60 * 60


"""
Unpaired HISAT:

Time loading reference: 00:00:00.476
Time loading forward index: 00:00:02.965
Multiseed full-index search: 00:00:20.798
2000000 reads; of these:
  2000000 (100.00%) were unpaired; of these:
    291886 (14.59%) aligned 0 times
    1632225 (81.61%) aligned exactly 1 time
    75889 (3.79%) aligned >1 times
85.41% overall alignment rate
Time searching: 00:00:24.839
Overall time: 00:00:24.854

Unpaired Bowtie 2:

Time loading reference: 00:00:00.659
Time loading forward index: 00:00:01.352
Time loading mirror index: 00:00:00.890
Multiseed full-index search: 00:00:55.985
400000 reads; of these:
  400000 (100.00%) were unpaired; of these:
    18911 (4.73%) aligned 0 times
    222489 (55.62%) aligned exactly 1 time
    158600 (39.65%) aligned >1 times
95.27% overall alignment rate
Time searching: 00:00:59.308
Overall time: 00:00:59.309


Paired-end HISAT:

Time loading reference: 00:00:00.587
Time loading forward index: 00:00:04.059
Multiseed full-index search: 00:00:46.332
2000000 reads; of these:
  2000000 (100.00%) were paired; of these:
    410334 (20.52%) aligned concordantly 0 times
    1544366 (77.22%) aligned concordantly exactly 1 time
    45300 (2.27%) aligned concordantly >1 times
    ----
    410334 pairs aligned concordantly 0 times; of these:
      16326 (3.98%) aligned discordantly 1 time
    ----
    394008 pairs aligned 0 times concordantly or discordantly; of these:
      788016 mates make up the pairs; of these:
        587992 (74.62%) aligned 0 times
        174173 (22.10%) aligned exactly 1 time
        25851 (3.28%) aligned >1 times
85.30% overall alignment rate
Time searching: 00:00:51.771
Overall time: 00:00:51.792

Paired-end Bowtie 2:

Time loading reference: 00:00:00.480
Time loading forward index: 00:00:01.278
Time loading mirror index: 00:00:00.799
Multiseed full-index search: 00:00:14.146
40000 reads; of these:
  40000 (100.00%) were paired; of these:
    16255 (40.64%) aligned concordantly 0 times
    14263 (35.66%) aligned concordantly exactly 1 time
    9482 (23.70%) aligned concordantly >1 times
    ----
    16255 pairs aligned concordantly 0 times; of these:
      8477 (52.15%) aligned discordantly 1 time
    ----
    7778 pairs aligned 0 times concordantly or discordantly; of these:
      15556 mates make up the pairs; of these:
        5481 (35.23%) aligned 0 times
        2222 (14.28%) aligned exactly 1 time
        7853 (50.48%) aligned >1 times
93.15% overall alignment rate
Time searching: 00:00:17.001
Overall time: 00:00:17.003
"""

def new_dat():
    return {'refload': 'NA', 'fwload': 'NA', 'rvload': 'NA', 'search_time': 'NA',
            'nunp': 'NA', 'nunp_0al': 'NA', 'nunp_1al': 'NA', 'nunp_multial': 'NA',
            'nconc_0al': 'NA', 'nconc_1al': 'NA', 'nconc_multial': 'NA',
            'ndisc_1al': 'NA',
            'nconcdisc_0al': 'NA',
            'thread_times': [], 'cpu_changeovers': [], 'node_changeovers': []}


def tabulate():
    dat = new_dat()
    keys = [ k for k, _ in sorted(dat.items()) ]
    print(','.join(keys))
    for root, dirs, files in os.walk(system_dir):
        print('Examining "%s"' % root, file=sys.stderr)
        if any(map(lambda x: x.endswith('.err'), files)):
            print('  Has .err files', file=sys.stderr)
            aligner, series, pe = parse_dir(root)
            for fn in filter(lambda x: x.endswith('.err'), files):
                print('  Examining "%s/%s"' % (root, fn), file=sys.stderr)
                dat = new_dat()
                threads_per_proc, proc_id, tot_threads, attempt = parse_file(fn, pe)
                dat.update({'aligner': aligner, 'series': series, 'pe': pe,
                            'threads_per_proc' : threads_per_proc, 'proc_id': proc_id,
                            'totthreads': tot_threads, 'attempt': attempt})
                if threads_per_proc == 0:
                    threads_per_proc = tot_threads
                if fn.endswith('.err'):
                    fn = os.path.join(root, fn)
                    fn_out = fn[:-4] + '.out'
                    if not os.path.exists(fn_out):
                        raise RuntimeError('.err file without .out companion: ' + fn_out)
                    with open(fn) as ifh:
                        for ln in ifh:
                            if ln.startswith('Time loading reference'):
                                dat['refload'] = parse_time(ln.split()[-1])
                            elif ln.startswith('Time loading forward index'):
                                dat['fwload'] = parse_time(ln.split()[-1])
                            elif ln.startswith('Time loading mirror index'):
                                dat['rvload'] = parse_time(ln.split()[-1])
                            elif ln.startswith('Multiseed full-index'):
                                dat['search'] = parse_time(ln.split()[-1])
                            elif 'were unpaired; of these' in ln:
                                dat['nunp'] = int(ln.split()[0])
                            elif 'aligned 0 times' in ln:
                                dat['nunp_0al'] = int(ln.split()[0])
                            elif 'aligned exactly 1 time' in ln:
                                dat['nunp_1al'] = int(ln.split()[0])
                            elif 'aligned >1 times' in ln:
                                dat['nunp_multial'] = int(ln.split()[0])
                            elif 'aligned concordantly 0 times' in ln:
                                dat['nconc_0al'] = int(ln.split()[0])
                            elif 'aligned concordantly exactly 1 time' in ln:
                                dat['nconc_1al'] = int(ln.split()[0])
                            elif 'aligned concordantly >1 times' in ln:
                                dat['nconc_multial'] = int(ln.split()[0])
                            elif 'pairs aligned concordantly 0 times; of these' in ln:
                                dat['nconc_0al'] = int(ln.split()[0])
                            elif 'aligned discordantly 1 time' in ln:
                                dat['ndisc_1al'] = int(ln.split()[0])
                            elif 'pairs aligned 0 times concordantly or discordantly; of these' in ln:
                                dat['nconcdisc_0al'] = int(ln.split()[0])
                            elif ln.startswith('Time searching:'):
                                dat['search_time'] = parse_time(ln.split()[-1])
                    with open(fn_out) as iofh:
                        for ln in iofh:
                            toks = ln.split()
                            assert toks[0] == 'thread:'
                            if toks[2] == 'time:':
                                dat['thread_times'].append(parse_time(toks[-1]))
                            elif toks[2] == 'cpu_changeovers:':
                                dat['cpu_changeovers'].append(int(toks[-1]))
                            elif toks[2] == 'node_changeovers:':
                                dat['node_changeovers'].append(int(toks[-1]))
                            else:
                                raise RuntimeError('Unrecognized output line: ' + ln)
                    assert len(dat['thread_times']) > 0
                    assert len(dat['thread_times']) == threads_per_proc
                    for tcol in ['thread_times', 'cpu_changeovers', 'node_changeovers']:
                        dat[tcol] = ' '.join(map(str, dat[tcol]))
                    print(','.join(map(str, [v for _, v in sorted(dat.items())])))

if __name__ == '__main__':
    tabulate()
