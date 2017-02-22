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
rsync -av $ROOT1/SRR651662_1.fastq.shuffled2.fq $ROOT2/
rsync -av $ROOT1/SRR651662_2.fastq.shuffled2.fq $ROOT2/

export HISAT_READS=$ROOT2/SRR651662_1.fastq.shuffled2.fq
export HISAT_READS_1=$ROOT2/SRR651662_1.fastq.shuffled2.fq
export HISAT_READS_2=$ROOT2/SRR651662_2.fastq.shuffled2.fq

CONFIG=hisat_pub.tsv
#CONFIG=hisat_tt.tsv
#CONFIG=hisat_tt.tsv
CONFIG_MP=hisat_pub_mp.tsv

#hisat mp batch-cleanparse
python ./master.py --multiprocess 330000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104 --config ${CONFIG_MP} --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

#hisat sp
python ./master.py --reads-per-thread 330000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104 --config ${CONFIG} --multiply-reads 32 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

python ./master.py --reads-per-thread 320000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104 --config ${CONFIG} --multiply-reads 32 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901

#hisat mp batch-cleanparse
python ./master.py --multiprocess 320000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104 --config ${CONFIG_MP} --multiply-reads 32 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901
