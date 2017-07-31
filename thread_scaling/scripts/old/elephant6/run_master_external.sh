#!/bin/bash

dir=extern1

#bwa tests
if [ $1 -ne 2 -a $1 -ne 3 ]; then
out='bwa-15'
python master_external.py --cmd '/home/cwilks3/bwa mem' --genome /home/cwilks3/scratch/data/hg19.fa --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/${out}-id --reads-per-thread 100000 --reads-count 42245074

python master_external.py --cmd '/home/cwilks3/bwa mem' --genome /home/cwilks3/scratch/data/hg19.fa --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/${out}-nid --reads-per-thread 100000 --reads-count 10000

python master_external.py --multiprocess 2 --cmd '/home/cwilks3/bwa mem' --genome /home/cwilks3/scratch/data/hg19.fa --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/${out}-mp-nid --reads-per-thread 100000 --reads-count 10000

python master_external.py --multiprocess 2 --cmd '/home/cwilks3/bwa mem' --genome /home/cwilks3/scratch/data/hg19.fa --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/${out}-mp-id --reads-per-thread 100000 --reads-count 42245074
fi

#kraken tests
if [ $1 == 2 -o $1 == 4 ]; then
python master_external.py --cmd '/home/cwilks3/k2/src/classify -d /home/cwilks3/k2/src/minikraken/database.kdb -i /home/cwilks3/k2/src/minikraken/database.idx -n /home/cwilks3/k2/src/minikraken/taxonomy/nodes.dmp' --genome '' --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/k-id --reads-per-thread 100000 --reads-count 42245074

python master_external.py --cmd '/home/cwilks3/k2/src/classify -d /home/cwilks3/k2/src/minikraken/database.kdb -i /home/cwilks3/k2/src/minikraken/database.idx -n /home/cwilks3/k2/src/minikraken/taxonomy/nodes.dmp' --genome '' --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/k-nid --reads-per-thread 100000 --reads-count 10000

python master_external.py --multiprocess 2 --cmd '/home/cwilks3/k2/src/classify -d /home/cwilks3/k2/src/minikraken/database.kdb -i /home/cwilks3/k2/src/minikraken/database.idx -n /home/cwilks3/k2/src/minikraken/taxonomy/nodes.dmp' --genome '' --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/k-mp-id --reads-per-thread 100000 --reads-count 42245074

python master_external.py --multiprocess 2 --cmd '/home/cwilks3/k2/src/classify -d /home/cwilks3/k2/src/minikraken/database.kdb -i /home/cwilks3/k2/src/minikraken/database.idx -n /home/cwilks3/k2/src/minikraken/taxonomy/nodes.dmp' --genome '' --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/k-mp-nid --reads-per-thread 100000 --reads-count 10000

fi

#jellyfish tests
if [ $1 == 3 -o $1 == 4 ]; then
python master_external.py --cmd '/home/cwilks3//jellyfish count' --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/jf-nid --reads-per-thread 2500000 --reads-count 10000

python master_external.py --cmd '/home/cwilks3//jellyfish count' --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/jf-id --reads-per-thread 1500000 --reads-count 42245074

python master_external.py --multiprocess 2 --cmd '/home/cwilks3//jellyfish count' --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/jf-mp-nid --reads-per-thread 2500000 --reads-count 10000

python master_external.py --multiprocess 2 --cmd '/home/cwilks3//jellyfish count' --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9,13,17,101,105,109,113,117,120 --tempdir ~/scratch/tmp3 --output-dir ./${dir}/jf-mp-id --reads-per-thread 1500000 --reads-count 42245074
fi
