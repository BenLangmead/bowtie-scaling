#!/bin/bash

module load git
export LIBRARY_PATH=/work/04620/cwilks/tbb_gcc5.4_lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=/work/04620/cwilks/tbb_gcc5.4_lib:$LD_LIBRARY_PATH
export CPATH=/work/04620/cwilks/tbb2017_20161128oss/include:$CPATH
export LIBS='-lpthread -ltbb -ltbbmalloc -ltbbmalloc_proxy'

export ROOT1=/work/04620/cwilks/data
export ROOT2=/tmp
rsync -av $ROOT1/ERR050082_1.fastq.shuffled2_extended.fq.block $ROOT2/
#rsync -av $ROOT1/ERR050082_1.fastq.shuffled2.fq.block  $ROOT2/
rsync -av $ROOT1/ERR050082_2.fastq.shuffled2.fq.block  $ROOT2/

export INDEX_ROOT=/dev/shm
export ROOT1=$INDEX_ROOT

export BT2_INDEX=$INDEX_ROOT
export HISAT_INDEX=$INDEX_ROOT

#export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled.fq 
#use the extended version to have enough reads for bowtie
#this is the whole ~42m reads from the original catted
#with the first 30m reads again at the end to get ~72m reads
export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled2_extended.fq.block
#export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2_extended.fq.block
export BT2_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq.block

CONFIG=bt1_pub.tsv
CONFIG_MP=bt1_pub_mp.tsv
CONFIG_MP2=bt1_pub_mp2.tsv

python ./master.py --reads-per-thread 22000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG} --multiply-reads 10 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --shorten-reads

python ./master.py --multiprocess 22000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG_MP} --multiply-reads 10 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --shorten-reads

python ./master.py --reads-per-thread 8000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG} --multiply-reads 1 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --shorten-reads

python ./master.py --multiprocess 8000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG_MP} --multiply-reads 1 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --shorten-reads


#UNP out MP
python ./master.py --multiprocess 22000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG_MP2} --multiply-reads 10 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --shorten-reads

./run_mp_mt_bt1.sh > run_mp_mt_bt1.run 2>&1
