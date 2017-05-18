#!/bin/bash

THREAD_SERIES="1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104,108"

OUTDIR="bwa0.7.15"
export INDEX_ROOT=/storage/indexes
export ROOT1=/home-1/cwilks3@jhu.edu/scratch
export ROOT2=/local
rsync -av $ROOT1/ERR050082_1.fastq.shuffled2_extended.fq.block $ROOT2/
rsync -av $ROOT1/ERR050082_2.fastq.shuffled2.fq.block $ROOT2/

export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2_extended.fq.block
export BT2_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq.block

if [ ! -d "build/bwa-0.7.15" ]; then
	wget https://github.com/lh3/bwa/releases/download/v0.7.15/bwa-0.7.15.tar.bz2
	bunzip2 bwa-0.7.15.tar.bz2
	tar -xvf bwa-0.7.15.tar
	mv bwa-0.7.15 build/
	make -C build/bwa-0.7.15
	ln -s build/bwa-0.7.15/bwa ./bwa
fi

#unp
python master_external.py --cmd './bwa mem' --genome $BT2_INDEX/hg19.fa --U $BT2_READS_1 --nthread-series $THREAD_SERIES  --tempdir $ROOT2 --output-dir ./${1}/$OUTDIR/sensitive/unp --reads-per-thread 85000

#paired
python master_external.py --cmd './bwa mem' --genome $BT2_INDEX/hg19.fa --U $BT2_READS_1 --U2 $BT2_READS_2 --nthread-series $THREAD_SERIES  --tempdir $ROOT2 --output-dir ./${1}/$OUTDIR/sensitive/pe --reads-per-thread 120000
