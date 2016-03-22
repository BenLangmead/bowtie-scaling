#!/usr/bin/env sh

for d in ERR050082 ERR050083 ; do
    for m in 1 2 ; do
        python fastq_sample.py \
            --in ${d}_${m}.fastq \
            --out ${d}_${m}.sample10k.fastq \
            --seed 72436 \
            --n 10000
    done
done

