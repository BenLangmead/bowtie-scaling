#!/bin/bash

export INDEX_ROOT=/export/scratch0/langmead/data

export BT2_INDEX=$INDEX_ROOT
export HISAT_INDEX=$INDEX_ROOT

export ROOT2=/export/scratch0/cwilks

export HISAT_READS=$ROOT2/SRR651662_1.fastq.shuffled2.fq
export HISAT_READS_1=$ROOT2/SRR651662_1.fastq.shuffled2.fq
export HISAT_READS_2=$ROOT2/SRR651662_2.fastq.shuffled2.fq

#1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120

#hisat sp
python ./master.py --reads-per-thread 165000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116 --config hisat_pub_noaff.tsv --multiply-reads 16 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

#hisat mp batch-cleanparse
python ./master.py --multiprocess 165000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116 --config hisat_pub_mp.tsv --multiply-reads 16 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads --reads-count 125531901

python ./master.py --reads-per-thread 160000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116 --config hisat_pub_noaff.tsv --multiply-reads 16 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901

#hisat mp batch-cleanparse
python ./master.py --multiprocess 160000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --hisat-U $HISAT_READS --hisat-m1 $HISAT_READS_1 --hisat-m2 $HISAT_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116 --config hisat_pub_mp.tsv --multiply-reads 16 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads --reads-count 125531901
