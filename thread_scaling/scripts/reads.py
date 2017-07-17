#!/usr/bin/env python

"""
Constructs reads files for thread-scaling experiments.
- Can produce blocked output for use with `blocked_input` branches of bowtie,
  bowtie2 and hisat
- Can trim reads as it goes, so can produce either reads the same length as
  input, or shorter for tools like bowtie

To construct inputs for our experiments:
- pypy reads.py --prefix=mix100
- pypy reads.py --trim-to 50 --max-read-size 175 --prefix=mix50
"""

from __future__ import print_function
import sys
import random
import gzip
import os


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
            j = random.randint(0, self.n+1)
            if j < self.k:
                self.r[j] = obj
        self.n += 1

    def add_pre(self):
        if self.n < self.k:
            self.n += 1
            return -1
        else:
            self.n += 1
            j = random.randint(0, self.n)
            return j if j < self.k else None

    def add_post(self, obj, j):
        if j == -1:
            self.r.append(obj)
        else:
            assert j < self.k
            self.r[j] = obj


reads = [
    # https://www.ncbi.nlm.nih.gov/sra/?term=ERR194147
    # Platinum genomes project, Illumina Cambridge
    {'srr': 'ERR194147',
     'url1': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR194/ERR194147/ERR194147_1.fastq.gz',
     'url2': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR194/ERR194147/ERR194147_2.fastq.gz',
     'tech': 'Illumina HiSeq 2000', 'paired': True, 'length': (101, 101)},
    # https://trace.ncbi.nlm.nih.gov/Traces/sra/?run=SRR424287
    # 1000 Genomes Project, Broad Institute
    {'srr': 'SRR069520',
     'url1': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR069/SRR069520/SRR069520_1.fastq.gz',
     'url2': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR069/SRR069520/SRR069520_2.fastq.gz',
     'tech': 'Illumina HiSeq 2000', 'paired': True, 'length': (101, 101)},
    # https://trace.ncbi.nlm.nih.gov/Traces/sra/?run=SRR3947551
    # Baylor, low-coverage WGS blood
    {'srr': 'SRR3947551',
     'url1': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR394/001/SRR3947551/SRR3947551_1.fastq.gz',
     'url2': 'ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR394/001/SRR3947551/SRR3947551_2.fastq.gz',
     'tech': 'Illumina HiSeq 2000', 'paired': True, 'length': (101, 101)}]


def go(args):
    block_sz = args.block_boundary
    reads_per_block = int(block_sz / args.max_read_size)
    random.seed(args.seed)
    samplers = [ReservoirSampler(args.reads_per_accession) for _ in reads]
    n = 0
    ival = 100
    ival_mult = 1.2
    last_seqlen = None
    for rd, samp in zip(reads, samplers):
        print('Handling ' + rd['srr'], file=sys.stderr)
        for ur in ['url1', 'url2']:
            if not os.path.exists(os.path.basename(rd[ur])):
                raise RuntimeError('No file for %s' % rd[ur])
        nfile = 0
        with gzip.open(os.path.basename(rd['url1']), 'rb') as r1:
            with gzip.open(os.path.basename(rd['url2']), 'rb') as r2:
                while True:
                    j = samp.add_pre()
                    if j is not None:
                        l1 = r1.readline().rstrip()
                        l2 = r2.readline().rstrip()
                        if len(l1) == 0:
                            break
                        seq1 = r1.readline().rstrip()
                        seq2 = r2.readline().rstrip()
                        assert last_seqlen is None or len(seq1) == last_seqlen
                        last_seqlen = len(seq1)
                        assert len(seq1) > 0
                        assert len(seq1) == len(seq2)
                        r1.readline()
                        r2.readline()
                        qual1 = r1.readline().rstrip()
                        qual2 = r2.readline().rstrip()
                        assert len(qual1) > 0
                        assert len(qual1) == len(seq1)
                        assert len(qual1) == len(qual2)
                        if len(seq1) > args.trim_to:
                            seq1 = seq1[:args.trim_to]
                            qual1 = qual1[:args.trim_to]
                        if len(seq2) > args.trim_to:
                            seq2 = seq2[:args.trim_to]
                            qual2 = qual2[:args.trim_to]
                        samp.add_post([l1, seq1, '+', qual1, l2, seq2, '+', qual2,
                                       len(l1) + len(seq1) + 1 + len(qual1) + 4,
                                       len(l2) + len(seq2) + 1 + len(qual2) + 4], j)
                    else:
                        # skip
                        if len(r1.readline()) == 0:
                            break
                        r2.readline()
                        for r in [r1, r2]:
                            for _ in range(3):
                                r.readline()
                    if n == ival:
                        ival = int(ival * ival_mult)
                        print('Handled %d reads, sampled %d' % (n, sum([len(x.r) for x in samplers])))
                    n += 1
                    nfile += 1
                    if args.stop_after is not None and nfile >= args.stop_after:
                        break

    big_list = [x for n in [y.r for y in samplers] for x in n]
    del samplers
    random.shuffle(big_list)
    with open(args.prefix + '_1.fq', 'wb') as ofh1:
        with open(args.prefix + '_2.fq', 'wb') as ofh2:
            for rec in big_list:
                ofh1.write(b'\n'.join(rec[0:4]) + b'\n')
                ofh2.write(b'\n'.join(rec[4:8]) + b'\n')
    with open(args.prefix + '_block_1.fq', 'wb') as ofhb1:
        with open(args.prefix + '_block_2.fq', 'wb') as ofhb2:
            block_i = 0
            while block_i < len(big_list):
                block_recs = big_list[block_i:block_i + reads_per_block]
                if block_i + reads_per_block <= len(big_list):  # not the last
                    block_len1 = sum(map(lambda x: x[-2], block_recs))
                    block_len2 = sum(map(lambda x: x[-1], block_recs))
                    assert block_len1 < block_sz, (block_len1, block_sz, reads_per_block)
                    assert block_len2 < block_sz, (block_len1, block_sz, reads_per_block)
                    block_recs[-1][0] += b' ' * (block_sz - block_len1)
                    block_recs[-1][4] += b' ' * (block_sz - block_len2)
                for rd in block_recs:
                    ofhb1.write(b'\n'.join(rd[0:4]) + b'\n')
                    ofhb2.write(b'\n'.join(rd[4:8]) + b'\n')
                block_i += reads_per_block


if __name__ == '__main__':

    import argparse
    parser = argparse.ArgumentParser(description='Compose read files for experiments.')

    parser.add_argument('--reads-per-accession', metavar='int', type=int, default=1000000,
                        help='# reads per accession to keep')
    parser.add_argument('--stop-after', metavar='int', type=int,
                        help='stop after parsing this many reads in an input file')
    parser.add_argument('--max-read-size', metavar='int', type=int, default=275,
                        help='max # bytes / read, for calculating # reads per block')
    parser.add_argument('--block-boundary', metavar='int', type=int, default=12288,
                        help='# characters constituting a single fixed-size block of FASTQ input')
    parser.add_argument('--seed', metavar='int', type=int, default=5744,
                        help='Pseudo-random seed.')
    parser.add_argument('--trim-to', metavar='int', type=int, default=9999,
                        help='If read is longer than this, trim to this length.')
    parser.add_argument('--prefix', metavar='str', type=str, default='out',
                        help='Prefix for output files.')
    go(parser.parse_args())
