#!/bin/bash

#unp
python master_external.py --cmd '/home1/04620/cwilks/bwa mem' --genome /dev/shm/hg19.fa --U /tmp/ERR050082_1.fastq.shuffled2.fq.block --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208  --tempdir /tmp --output-dir ./${1}/bwa-unp-id --reads-per-thread 12500

#paired
python master_external.py --cmd '/home1/04620/cwilks/bwa mem' --genome /dev/shm/hg19.fa --U /tmp/ERR050082_1.fastq.shuffled2.fq.block --U2 /tmp/ERR050082_2.fastq.shuffled2.fq.block --nthread-series 1,4,12,20,28,36,44,52,60,68,76,84,92,100,108,112,120,128,136,144,152,160,168,176,184,192,200,208  --tempdir /tmp --output-dir ./${1}/bwa-pe-id --reads-per-thread 12500