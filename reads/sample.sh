#!/usr/bin/env sh

# WGS DNA-seq data for bowtie/bowtie2
for d in ERR050082 ERR050083 ; do
    for m in 1 2 ; do
        if [ ! -f "${d}_${m}.sample10k.fastq" ] ; then
            python fastq_sample.py \
                --in ${d}_${m}.fastq \
                --out ${d}_${m}.sample10k.fastq \
                --seed 72436 \
                --n 10000
        fi
    done
done

# RNA-seq data for HISAT
for m in 1 2 ; do
    if [ ! -f "SRR651662_10k_${m}.fastq" ] ; then
        python fastq_sample.py \
            --in SRR651662_100k_${m}.fastq \
            --out SRR651662_10k_${m}.fastq \
            --seed 72436 \
            --n 10000
    fi
done
