#!/bin/bash

THREAD_SERIES="1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272"

BWA_CMD=/home1/04620/cwilks/bwa
OUTDIR="bwa0.7.15"

export ROOT1=/work/04620/cwilks/data
export ROOT2=/tmp
rsync -av $ROOT1/ERR050082_1.fastq.shuffled2_extended.fq.block $ROOT2/
rsync -av $ROOT1/ERR050082_2.fastq.shuffled2.fq.block $ROOT2/
export READS1=$ROOT2/ERR050082_1.fastq.shuffled2_extended.fq.block
export READS2=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block

export INDEX_ROOT=/dev/shm
rsync -av $ROOT1/hg19.fa* $INDEX_ROOT/


#single
python master_external.py --cmd "$BWA_CMD mem" --genome $INDEX_ROOT/hg19.fa --U $READS1 --nthread-series $THREAD_SERIES  --tempdir $ROOT2 --output-dir ./${1}/$OUTDIR/sensitive/unp --reads-per-thread 12500

#paired
python master_external.py --cmd "$BWA_CMD mem" --genome $INDEX_ROOT/hg19.fa --U $READS1 --U2 $READS2 --nthread-series $THREAD_SERIES  --tempdir $ROOT2 --output-dir ./${1}/$OUTDIR/sensitive/pe --reads-per-thread 18000
