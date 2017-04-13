#!/bin/bash

module load git
export LIBRARY_PATH=/work/04620/cwilks/tbb_gcc5.4_lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=/work/04620/cwilks/tbb_gcc5.4_lib:$LD_LIBRARY_PATH
export CPATH=/work/04620/cwilks/tbb2017_20161128oss/include:$CPATH
export LIBS='-lpthread -ltbb -ltbbmalloc -ltbbmalloc_proxy'

#export INDEX_ROOT=/work/04620/cwilks/data
export INDEX_ROOT=/dev/shm

export BT2_INDEX=$INDEX_ROOT
export HISAT_INDEX=$INDEX_ROOT

export ROOT2=/tmp
#rsync -av $INDEX_ROOT/ERR050082_1.fastq.shuffled2.fq.block $ROOT2/
#rsync -av $INDEX_ROOT/ERR050082_2.fastq.shuffled2.fq.block $ROOT2/

export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export BT2_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq.block

CONFIG=bt2_pub.tsv
CONFIG_MP=bt2_pub_mp.tsv
CONFIG_MP2=bt2_pub_mp.tsv

#single
python ./master.py --reads-per-thread 12500 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG} --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads

python ./master.py --multiprocess 12500 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG_MP} --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads


#paired
python ./master.py --reads-per-thread 18000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG} --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads

python ./master.py --multiprocess 18000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG_MP} --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads

#UNP for out MP
python ./master.py --multiprocess 12500 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG_MP2} --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads
