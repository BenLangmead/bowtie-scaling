#!/bin/bash

THREAD_SERIES="1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104,108"

module load git
export LD_LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/lib/intel64/gcc4.1:$LD_LIBRARY_PATH
export LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/lib/intel64/gcc4.1:$LIBRARY_PATH
export CPATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/include:$CPATH
export LIBS="-lpthread -ltbb -ltbbmalloc -ltbbmalloc_proxy"

export INDEX_ROOT=/storage/indexes

export BT2_INDEX=$INDEX_ROOT
export HISAT_INDEX=$INDEX_ROOT

export ROOT1=/home-1/cwilks3@jhu.edu/scratch
export ROOT2=/local
rsync -av $ROOT1/ERR050082_1.fastq.shuffled2_extended.fq.block  $ROOT2/
rsync -av $ROOT1/ERR050082_2.fastq.shuffled2.fq.block $ROOT2/

export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled2_extended.fq.block
export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2_extended.fq.block
export BT2_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq.block

CONFIG=./experiments/bt2_pub.tsv
CONFIG_MP=./experiments/bt2_pub_mp.tsv

./experiments/marcc_lbm/run_bwa ${1} > rbwa 2>&1 

if [ ! -d "${1}/mp_mt_bt2" ]; then
	mkdir -p ${1}/mp_mt_bt2
fi

./experiments/marcc_lbm/run_mp_mt_bt2.sh ${1}/mp_mt_bt2 > run_mp_mt_bt2.run 2>&1

#single
python ./master.py --reads-per-thread 85000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series $THREAD_SERIES --config ${CONFIG} --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads

#paired MP
python ./master.py --multiprocess 85000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series $THREAD_SERIES --config ${CONFIG_MP} --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads


#paired
python ./master.py --reads-per-thread 120000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series $THREAD_SERIES --config ${CONFIG} --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads

#paired MP
python ./master.py --multiprocess 120000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series $THREAD_SERIES --config ${CONFIG_MP} --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads
