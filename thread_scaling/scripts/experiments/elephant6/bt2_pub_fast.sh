#!/bin/bash

export INDEX_ROOT=/export/scratch0/langmead/data

export BT2_INDEX=$INDEX_ROOT
export HISAT_INDEX=$INDEX_ROOT

export ROOT2=/export/scratch0/cwilks

export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled2.fq
export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2.fq
export BT2_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq

export CONFIG='bt2_pub_new_master.tsv'

#single
python ./master.py --reads-per-thread 42500 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116 --config ${CONFIG} --multiply-reads 4 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads

python ./master.py --multiprocess 42500 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116 --config bt2_pub_mp.tsv --multiply-reads 4 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads


#paired
python ./master.py --reads-per-thread 60000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116 --config ${CONFIG} --multiply-reads 3 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads

python ./master.py --multiprocess 60000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116 --config bt2_pub_mp.tsv --multiply-reads 3 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads
