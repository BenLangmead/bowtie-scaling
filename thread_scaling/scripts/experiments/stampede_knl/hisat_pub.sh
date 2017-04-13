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

export ROOT1=$INDEX_ROOT
export ROOT2=/tmp
#rsync -av $INDEX_ROOT/ERR050082_1.fastq.shuffled2.fq.block $ROOT2/
#rsync -av $INDEX_ROOT/ERR050082_2.fastq.shuffled2.fq.block $ROOT2/
#rsync -av $INDEX_ROOT/*.bt2 $ROOT2/

export HISAT_READS=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export HISAT_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export HISAT_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq.block

CONFIG=hisat_pub.tsv
#CONFIG=hisat_tt.tsv
CONFIG_MP=hisat_pub_mp.tsv
CONFIG_MP2=hisat_pub_mp2.tsv


#hisat sp
python ./master.py --reads-per-thread 16000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG} --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

#hisat mp batch-cleanparse
python ./master.py --multiprocess 16000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG_MP} --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901
#python ./master.py --multiprocess 330000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,8,16,24,32,40,48,56,60,68,76,84,92,96,100,104,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,272 --config hisat_pub_mp2.tsv --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

python ./master.py --reads-per-thread 12000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG} --multiply-reads 32 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901

#hisat mp batch-cleanparse
python ./master.py --multiprocess 12000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG_MP} --multiply-reads 32 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901
#python ./master.py --multiprocess 320000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,8,16,24,32,40,48,56,60,68,76,84,92,96,100,104,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,272 --config hisat_pub_mp2.tsv --multiply-reads 32 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901


#UNP out MP
python ./master.py --multiprocess 16000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,264,270 --config ${CONFIG_MP2} --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901
