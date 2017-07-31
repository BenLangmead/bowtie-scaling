#!/bin/bash

#bwa tests
if [ $1 -ne 2 -a $1 -ne 3 ]; then 
python master_external.py --cmd '/home/cwilks3/bwa mem' --genome /home/cwilks3/scratch/data/hg19.fa --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5 --tempdir ~/scratch/tmp3 --output-dir ./test/bwa-id --reads-per-thread 100000 --reads-count 42245074

python master_external.py --cmd '/home/cwilks3/bwa mem' --genome /home/cwilks3/scratch/data/hg19.fa --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5 --tempdir ~/scratch/tmp3 --output-dir ./test/bwa-nid --reads-per-thread 100000 --reads-count 10000

python master_external.py --multiprocess 2 --cmd '/home/cwilks3/bwa mem' --genome /home/cwilks3/scratch/data/hg19.fa --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9 --tempdir ~/scratch/tmp3 --output-dir ./test/bwa-mp-nid --reads-per-thread 100000 --reads-count 10000

python master_external.py --multiprocess 2 --cmd '/home/cwilks3/bwa mem' --genome /home/cwilks3/scratch/data/hg19.fa --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9 --tempdir ~/scratch/tmp3 --output-dir ./test/bwa-mp-id --reads-per-thread 100000 --reads-count 42245074
fi

#kraken tests
if [ $1 == 2 -o $1 == 4 ]; then
python master_external.py --cmd '/home/cwilks3/k2/src/classify -d /home/cwilks3/k2/src/minikraken/database.kdb -i /home/cwilks3/k2/src/minikraken/database.idx -n /home/cwilks3/k2/src/minikraken/taxonomy/nodes.dmp' --genome '' --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5 --tempdir ~/scratch/tmp3 --output-dir ./test/k-id --reads-per-thread 100000 --reads-count 42245074

python master_external.py --cmd '/home/cwilks3/k2/src/classify -d /home/cwilks3/k2/src/minikraken/database.kdb -i /home/cwilks3/k2/src/minikraken/database.idx -n /home/cwilks3/k2/src/minikraken/taxonomy/nodes.dmp' --genome '' --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5 --tempdir ~/scratch/tmp3 --output-dir ./test/k-nid --reads-per-thread 100000 --reads-count 10000

python master_external.py --multiprocess 2 --cmd '/home/cwilks3/k2/src/classify -d /home/cwilks3/k2/src/minikraken/database.kdb -i /home/cwilks3/k2/src/minikraken/database.idx -n /home/cwilks3/k2/src/minikraken/taxonomy/nodes.dmp' --genome '' --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9 --tempdir ~/scratch/tmp3 --output-dir ./test/k-mp-id --reads-per-thread 100000 --reads-count 42245074

python master_external.py --multiprocess 2 --cmd '/home/cwilks3/k2/src/classify -d /home/cwilks3/k2/src/minikraken/database.kdb -i /home/cwilks3/k2/src/minikraken/database.idx -n /home/cwilks3/k2/src/minikraken/taxonomy/nodes.dmp' --genome '' --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9 --tempdir ~/scratch/tmp3 --output-dir ./test/k-mp-nid --reads-per-thread 100000 --reads-count 10000

fi

#jellyfish tests
if [ $1 == 3 -o $1 == 4 ]; then
python master_external.py --cmd '/home/cwilks3//jellyfish count' --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5 --tempdir ~/scratch/tmp3 --output-dir ./test/jf-nid --reads-per-thread 2500000 --reads-count 10000

python master_external.py --cmd '/home/cwilks3//jellyfish count' --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5 --tempdir ~/scratch/tmp3 --output-dir ./test/jf-id --reads-per-thread 1500000 --reads-count 42245074

python master_external.py --multiprocess 2 --cmd '/home/cwilks3//jellyfish count' --U /export/scratch0/cwilks/noio_reads/bowtie2.noio.fastq.10k.fq --nthread-series 1,5,9 --tempdir ~/scratch/tmp3 --output-dir ./test/jf-mp-nid --reads-per-thread 2500000 --reads-count 10000

python master_external.py --multiprocess 2 --cmd '/home/cwilks3//jellyfish count' --U /export/scratch0/cwilks/ERR050082_1.fastq --nthread-series 1,5,9 --tempdir ~/scratch/tmp3 --output-dir ./test/jf-mp-id --reads-per-thread 1500000 --reads-count 42245074
fi
