#!/usr/bin/env python

from __future__ import print_function
import sys
import random
import gzip
import urllib


class ReservoirSampler(object):
    """ Simple reservoir sampler """

    def __init__(self, k):
        self.k = k  # # elts to collect
        self.r = []  # the elts
        self.n = 0  # # elts scanned

    def add(self, obj):
        if self.n < self.k:
            self.r.append(obj)
        else:
            j = random.randint(0, self.n)
            if j < self.k:
                self.r[j] = obj
        self.n += 1


reads = [
    # https://www.ncbi.nlm.nih.gov/sra/?term=ERR194147
    {'srr': 'ERR194147',
     'url1': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR194/ERR194147/ERR194147_1.fastq.gz',
     'url2': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR194/ERR194147/ERR194147_2.fastq.gz',
     'tech': 'Illumina HiSeq 2000', 'paired': True, 'length': (101, 101)},
    # https://www.ncbi.nlm.nih.gov/sra/?term=SRR642636
    {'srr': 'SRR642636',
     'url1': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR642/SRR642636/SRR642636_1.fastq.gz',
     'url2': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR642/SRR642636/SRR642636_2.fastq.gz',
     'tech': 'Illumina HiSeq 2000', 'paired': True, 'length': (101, 101)},
    # https://trace.ncbi.nlm.nih.gov/Traces/sra/?run=SRR3947551
    {'srr': 'SRR3947551',
     'url1': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR394/001/SRR3947551/SRR3947551_1.fastq.gz',
     'url2': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR394/001/SRR3947551/SRR3947551_2.fastq.gz',
     'tech': 'Illumina HiSeq 2000', 'paired': True, 'length': (101, 101)}]


def go(args):
    random.seed(args.seed)
    samplers = [ReservoirSampler(args.reads_per_accession) for _ in reads]
    n = 0
    ival = 100
    ival_mult = 1.2
    for rd, samp in zip(reads, samplers):
        print('Handling ' + rd['srr'], file=sys.stderr)
        r1 = gzip.open(urllib.urlretrieve(rd['url1'])[0])
        r2 = gzip.open(urllib.urlretrieve(rd['url2'])[0])
        while True:
            l1 = r1.readline().rstrip()
            l2 = r2.readline().rstrip()
            if len(l1) == 0:
                break
            seq1 = r1.readline().rstrip()
            seq2 = r2.readline().rstrip()
            assert len(seq1) > 0
            assert len(seq1) == len(seq2)
            r1.readline()
            r2.readline()
            qual1 = r1.readline().rstrip()
            qual2 = r2.readline().rstrip()
            assert len(qual1) > 0
            assert len(qual1) == len(seq1)
            assert len(qual1) == len(qual2)
            samp.add([l1, seq1, '+', qual1, l2, seq2, '+', qual1])
            if n == ival:
                ival = int(ival * ival_mult)
                print('Handled %d reads, sampled %d' % (n, sum([len(x.r) for x in samplers])))
            n += 1
    big_list = [x for n in [y.r for y in samplers] for x in n]
    del samplers
    random.shuffle(big_list)
    with open('out_1.fq', 'wb') as ofh1:
        with open('out_2.fq', 'wb') as ofh2:
            for o in big_list:
                print('\n'.join(o[:4]), file=ofh1)
                print('\n'.join(o[4:]), file=ofh2)


if __name__ == '__main__':

    import argparse
    parser = argparse.ArgumentParser(description='Compose read files for experiments.')

    parser.add_argument('--reads-per-accession', metavar='int', type=int, default=1000000,
                        help='# reads per accession to keep')
    parser.add_argument('--block-boundary', metavar='int', type=int, default=16 * 1024,
                        help='# characters constituting a single fixed-size block of FASTQ input')
    parser.add_argument('--seed', metavar='int', type=int, default=5744,
                        help='Pseudo-random seed.')
    go(parser.parse_args())
