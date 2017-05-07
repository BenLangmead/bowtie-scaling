#!/bin/bash

module load git
export LIBRARY_PATH=/work/04620/cwilks/tbb_gcc5.4_lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=/work/04620/cwilks/tbb_gcc5.4_lib:$LD_LIBRARY_PATH
export CPATH=/work/04620/cwilks/tbb2017_20161128oss/include:$CPATH
export LIBS='-lpthread -ltbb -ltbbmalloc -ltbbmalloc_proxy'

export INDEX_ROOT=/work/04620/cwilks/data

export ROOT1=$INDEX_ROOT
export ROOT2=/tmp
rsync -av $INDEX_ROOT/ERR050082_1.fastq.shuffled2.fq.block $ROOT2/
rsync -av $INDEX_ROOT/ERR050082_2.fastq.shuffled2.fq.block $ROOT2/
#rsync -av $INDEX_ROOT/*.bt2 $ROOT2/

export INDEX_ROOT=/dev/shm

export BT2_INDEX=$INDEX_ROOT
export HISAT_INDEX=$INDEX_ROOT

export HISAT_READS=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export HISAT_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2.fq.block
export HISAT_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq.block

#CONFIG=hisat_pub_s.tsv
CONFIG=hisat_pub.tsv
CONFIG_MP=hisat_pub_mp.tsv
CONFIG_MP2=hisat_pub_mp2.tsv


#hisat sp
python ./master.py --reads-per-thread 24000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG} --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

#hisat mp batch-cleanparse
python ./master.py --multiprocess 24000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG_MP} --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

python ./master.py --reads-per-thread 20000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG} --multiply-reads 32 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901

#hisat mp batch-cleanparse
python ./master.py --multiprocess 20000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG_MP} --multiply-reads 32 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901


#UNP out MP
python ./master.py --multiprocess 24000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /tmp --output-dir ${1} --nthread-series 1,4,8,12,16,17,34,51,68,85,100,102,119,136,150,153,170,200,204,221,238,255,272 --config ${CONFIG_MP2} --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

./run_mp_mt_hisat.sh > hmpmt.run 2>&1
