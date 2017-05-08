#!/bin/bash

export INDEX_ROOT=/storage/indexes
export ROOT1=/home-1/cwilks3@jhu.edu/scratch
export ROOT2=/local
rsync -av $ROOT1/ERR050082_1.fastq.shuffled2.fq.block $ROOT2/
rsync -av $ROOT1/ERR050082_2.fastq.shuffled2.fq.block $ROOT2/

export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export BT2_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq.block


wget https://github.com/lh3/bwa/releases/download/v0.7.15/bwa-0.7.15.tar.bz2
bunzip2 bwa-0.7.15.tar.bz2
tar -xvf bwa-0.7.15.tar
mv bwa-0.7.15 build/
make -C build/bwa-0.7.15
ln -s build/bwa-0.7.15/bwa ./bwa

#unp
python master_external.py --cmd './bwa mem' --genome $BT2_INDEX/hg19.fa --U $BT2_READS --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104,108  --tempdir $ROOT2 --output-dir ./${1}/bwa-unp-id --reads-per-thread 85000

#paired
python master_external.py --cmd './bwa mem' --genome $BT2_INDEX/hg19.fa --U $BT2_READS_1 --U2 $BT2_READS_2 --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104,108  --tempdir $ROOT2 --output-dir ./${1}/bwa-pe-id --reads-per-thread 120000
