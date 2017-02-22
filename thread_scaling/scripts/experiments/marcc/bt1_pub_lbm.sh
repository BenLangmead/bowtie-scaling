#!/bin/bash

module load git
#module load intel-tbb-oss/intel64/43_20150424oss
#export LD_LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb4.1/tbb41_20130613oss/lib/intel64/gcc4.1
export LD_LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/lib/intel64/gcc4.1:$LD_LIBRARY_PATH
export LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/lib/intel64/gcc4.1:$LIBRARY_PATH
export CPATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/include:$CPATH
export LIBS="-lpthread -ltbb -ltbbmalloc -ltbbmalloc_proxy"

export INDEX_ROOT=/scratch/groups/blangme2/indexes

export BT2_INDEX=$INDEX_ROOT
export HISAT_INDEX=$INDEX_ROOT


export ROOT1=/home-1/cwilks3@jhu.edu/scratch
export ROOT2=/local
rsync -av $ROOT1/ERR050082_1.fastq.shuffled2_extended.fq  $ROOT2/
rsync -av $ROOT1/ERR050082_1.fastq.shuffled2.fq  $ROOT2/
rsync -av $ROOT1/ERR050082_2.fastq.shuffled2.fq  $ROOT2/


#export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled.fq 
#use the extended version to have enough reads for bowtie
#this is the whole ~42m reads from the original catted
#with the first 30m reads again at the end to get ~72m reads
export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled2_extended.fq
export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2.fq 
export BT2_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq 

CONFIG=bt1_pub.tsv
#CONFIG=bt1_tt.tsv
CONFIG_MP=bt1_pub_mp.tsv

python ./master.py --reads-per-thread 450000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104 --config ${CONFIG} --multiply-reads 60 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --shorten-reads

python ./master.py --multiprocess 450000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104 --config ${CONFIG_MP} --multiply-reads 60 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --shorten-reads

python ./master.py --reads-per-thread 180000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104 --config ${CONFIG} --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --shorten-reads

python ./master.py --multiprocess 180000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104 --config ${CONFIG_MP} --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --shorten-reads
