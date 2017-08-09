#!/usr/bin/env python


def go(args):
    next_boundary = args.block_bytes
    lines_per_block = args.reads_per_block * 4
    with open(args.fastq, 'rb') as ifh:
        i = 0
        while True:
            ln = ifh.readline()
            if len(ln) == 0:
                break
            i += 1
            if i % lines_per_block == 0:
                if ifh.tell() != next_boundary:
                    raise RuntimeError('Expected boundary %d, got %d at line %d' %
                                       (next_boundary, ifh.tell(), i))
                next_boundary += args.block_bytes
    print('PASSED')


if __name__ == '__main__':

    import argparse
    parser = argparse.ArgumentParser(description='Check that a blocked FASTQ file has appropriate block boundaries')

    parser.add_argument('--fastq', metavar='path', type=str, required=True,
                        help='FASTQ file to check.')
    parser.add_argument('--stop-after', metavar='int', type=int,
                        help='stop after parsing this many reads in an input file')
    parser.add_argument('--block-bytes', metavar='int', type=int, default=12288,
                        help='# characters constituting a single fixed-size block of FASTQ input')
    parser.add_argument('--reads-per-block', metavar='int', type=int, default=70,
                        help='# reads in a single fixed-size block')
    go(parser.parse_args())
