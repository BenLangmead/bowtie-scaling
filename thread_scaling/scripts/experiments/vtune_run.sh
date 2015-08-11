#!/bin/bash

for thread in 1 12 24 52 100 120; do
    amplxe-cl -collect general-exploration \
      -app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
      -- ./bowtie2-align-s-no-io \
         -x $HOME/data/hg19 \
         -U seqs_by_100.fq \
         -p $thread \
         -S /dev/null
done

for thread in 1 12 24 ; do
    amplxe-cl -collect general-exploration \
      -app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
      -- numactl --cpunodebind=0 --membind=0 ./bowtie2-align-s-no-io \
         -x $HOME/data/hg19 \
         -U seqs_by_100.fq \
         -p $thread \
         -S /dev/null
done








