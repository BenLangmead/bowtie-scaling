#!/usr/bin/env python

"""
Constructs reads files for thread-scaling experiments.
- Can produce blocked output for use with `blocked_input` branches of bowtie,
  bowtie2 and hisat
- Can trim reads as it goes, so can produce either reads the same length as
  input, or shorter for tools like bowtie

To construct inputs for our experiments:
- pypy reads.py --prefix=mix100 --reads-per-accession=100000000
- pypy reads.py --trim-to 50 --max-read-size 175 --prefix=mix50 --reads-per-accession=100000000
"""

from __future__ import print_function
import sys
import random
import gzip
import os
import numpy as np


class ReservoirSampler(object):
    """ Simple reservoir sampler """

    def __init__(self, k, fn):
        self.k = k  # # elts to collect
        self.n = 0  # # elts scanned
        self.fn = fn
        self.ofh = open(fn, 'wb')

    def add_pre(self):
        if self.n < self.k:
            self.n += 1
            return self.n - 1
        else:
            self.n += 1
            j = random.randint(0, self.n)
            return j if j < self.k else None

    def add_post(self, obj, j):
        self.ofh.write('\t'.join([str(j)] + list(map(str, obj))) + '\n')

    def close(self):
        if self.ofh is not None:
            self.ofh.close()
        self.ofh = None


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


def reverse_readline(filename, buf_size=8192):
    """a generator that returns the lines of a file in reverse order"""
    with open(filename, 'rb') as fh:
        segment = None
        offset = 0
        fh.seek(0, os.SEEK_END)
        file_size = remaining_size = fh.tell()
        while remaining_size > 0:
            offset = min(file_size, offset + buf_size)
            fh.seek(file_size - offset)
            buffer = fh.read(min(remaining_size, buf_size))
            remaining_size -= buf_size
            lines = buffer.split('\n')
            # the first line of the buffer is probably not a complete line so
            # we'll save it and append it to the last line of the next buffer
            # we read
            if segment is not None:
                # if the previous chunk starts right from the beginning of line
                # do not concact the segment to the last line of new chunk
                # instead, yield the segment first
                if buffer[-1] is not '\n':
                    lines[-1] += segment
                else:
                    yield segment
            segment = lines[0]
            for index in range(len(lines) - 1, 0, -1):
                if len(lines[index]):
                    yield lines[index]
        # Don't yield None if the file was empty
        if segment is not None:
            yield segment


def go(args):
    random.seed(34635)
    np.random.seed(34635)
    block_sz = args.block_boundary
    reads_per_block = int(block_sz / args.max_read_size)
    random.seed(args.seed)
    tmpfns = ['.reads.py.tmp%d' % i for i in range(len(reads))]
    samplers = [ReservoirSampler(args.reads_per_accession, tmpfns[i]) for i in range(len(reads))]
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
                        samp.add_post([l1, seq1, '+', qual1, l2, seq2, '+', qual2], j)
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
                        print('Handled %d reads' % n)
                    n += 1
                    nfile += 1
                    if args.stop_after is not None and nfile >= args.stop_after:
                        break
        samp.close()

    nreads = args.reads_per_accession * len(samplers)
    print('Generating permutation with %d elements' % nreads, file=sys.stderr)
    idxs = np.random.permutation(nreads)
    unsrt_fn = '.reads.py.unsorted'
    n = 0
    ival = 100
    with open(unsrt_fn, 'wb') as ofh:
        for si, sampler in enumerate(samplers):
            seen_items = set()
            for ln in reverse_readline(sampler.fn):
                orig_rank = int(ln[:ln.find('\t')])
                if orig_rank not in seen_items:
                    i = orig_rank + si * args.reads_per_accession
                    ofh.write(str(idxs[i]) + '\t' + ln + '\n')
                    seen_items.add(orig_rank)
                if n == ival:
                    ival = int(ival * ival_mult)
                    print('Handled %d unsorted records' % n)
                n += 1
            del seen_items

    if not args.keep_intermediates:
        print('Deleting %d reservoir temporary files:' % len(samplers), file=sys.stderr)
        for fn in tmpfns:
            os.remove(fn)

    print('Deleting %d reservoir samplers and temporary files:' % len(samplers), file=sys.stderr)
    for samp in samplers:
        del samp

    print('Sorting temporary sample file by permuted index', file=sys.stderr)
    del idxs
    cmd = 'sort -n -k1,1 .reads.py.unsorted > .reads.py.sorted'
    print(cmd, file=sys.stderr)
    ret = os.system(cmd)
    if ret != 0:
        raise RuntimeError('sort command failed')

    if not args.keep_intermediates:
        print('Deleting temporary sample file', file=sys.stderr)
        os.remove('.reads.py.unsorted')

    print('Preparing unblocked reads:', file=sys.stderr)
    with open('.reads.py.sorted', 'rb') as fh:
        with open(args.prefix + '_1.fq', 'wb') as ofh1:
            with open(args.prefix + '_2.fq', 'wb') as ofh2:
                n = 0
                ival = 100
                for ln in fh:
                    toks = ln.split('\t')
                    ofh1.write(b'\n'.join(toks[1:5]) + b'\n')
                    ofh2.write(b'\n'.join(toks[5:9]) + b'\n')
                    if n == ival:
                        ival = int(ival * ival_mult)
                        print('Handled %d unsorted records' % n)
                    n += 1

    print('Preparing blocked reads:', file=sys.stderr)
    with open('.reads.py.sorted', 'rb') as fh:
        with open(args.prefix + '_block_1.fq', 'wb') as ofhb1:
            with open(args.prefix + '_block_2.fq', 'wb') as ofhb2:
                n = 0
                ival = 100
                toks1, toks2 = [], []
                nbytes1, nbytes2 = 0, 0
                for i, ln in enumerate(fh):
                    toks = ln.split('\t')
                    toks1.append(toks[1:5])
                    toks2.append(toks[5:9])
                    nbytes1 += sum(map(len, toks1[-1])) + 4
                    nbytes2 += sum(map(len, toks2[-1])) + 4
                    if (i+1) % reads_per_block == 0:
                        toks1[-1][0] += b' ' * (block_sz - nbytes1)
                        toks2[-1][0] += b' ' * (block_sz - nbytes2)
                        for rec in toks1:
                            ofhb1.write(b'\n'.join(rec) + b'\n')
                        for rec in toks2:
                            ofhb2.write(b'\n'.join(rec) + b'\n')
                        toks1, toks2 = [], []
                        nbytes1, nbytes2 = 0, 0
                    if n == ival:
                        ival = int(ival * ival_mult)
                        print('Handled %d sorted records' % n)
                    n += 1
                for rec in toks1:
                    ofhb1.write(b'\n'.join(rec) + b'\n')
                for rec in toks2:
                    ofhb2.write(b'\n'.join(rec) + b'\n')

    if not args.keep_intermediates:
        print('Deleting sorted sample file', file=sys.stderr)
        os.remove('.reads.py.sorted')


if __name__ == '__main__':

    import argparse
    parser = argparse.ArgumentParser(description='Compose read files for experiments.')

    parser.add_argument('--reads-per-accession', metavar='int', type=int, default=100000000,
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
    parser.add_argument('--keep-intermediates', action='store_const', const=True, default=False,
                        help='If set, intermediate files are not deleted.')
    parser.add_argument('--prefix', metavar='str', type=str, default='out',
                        help='Prefix for output files.')
    go(parser.parse_args())
