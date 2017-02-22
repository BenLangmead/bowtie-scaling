#!/bin/bash

export INDEX_ROOT=/export/scratch0/langmead/data

export BT2_INDEX=$INDEX_ROOT
export HISAT_INDEX=$INDEX_ROOT

export ROOT2=/export/scratch0/cwilks

export BT2_READS=$ROOT2/ERR050082_1.fastq.shuffled2.fq
export BT2_READS_1=$ROOT2/ERR050082_1.fastq.shuffled2.fq
export BT2_READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq

export CONFIG='bt2_pub_cohort_small.tsv'
#export CONFIG='bt2_pub_tt.tsv'

#single
python ./master.py --reads-per-thread 85000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,16,24,32,40,48,56,64,72,84,92,96,100,104,108,112,116,120 --config ${CONFIG} --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads
#python ./master.py --reads-per-thread 85000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120 --config bt2_pub2.tsv --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads

#python ./master.py --multiprocess 85000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120 --config bt2_pub_mp.tsv --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads
#python ./master.py --multiprocess 85000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120 --config bt2_pub_mp2.tsv --multiply-reads 8 --reads-per-batch 32 --paired-mode 2 --no-no-io-reads


#paired
python ./master.py --reads-per-thread 120000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,16,24,32,40,48,56,64,72,84,92,96,100,104,108,112,116,120 --config ${CONFIG} --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads
#python ./master.py --reads-per-thread 120000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir pub_runs_tbb_redo --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120 --config bt2_pub_tbb.tsv --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads

#python ./master.py --multiprocess 120000 --index $BT2_INDEX/hg19 --hisat-index $HISAT_INDEX/hg19_hisat --U $BT2_READS --m1 $BT2_READS_1 --m2 $BT2_READS_2 --sensitivities s --sam-dev-null --tempdir /home/cwilks3/scratch/tmp2 --output-dir ${1} --nthread-series 1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120 --config bt2_pub_mp.tsv --multiply-reads 6 --reads-per-batch 32 --paired-mode 3 --no-no-io-reads
