#!/bin/bash


amplxe-cl -collect general-exploration \
  -app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
  -- ./bowtie2-align-s-no-io \
     -x $HOME/data/hg19 \
     -U seqs_by_100.fq \
     -p 1 \
     -S /dev/null

amplxe-cl -collect general-exploration \
  -app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
  -- ./bowtie2-align-s-no-io \
     -x $HOME/data/hg19 \
     -U seqs_by_100.fq \
     -p 12 \
     -S /dev/null
  
amplxe-cl -collect general-exploration \
  -app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
  -- ./bowtie2-align-s-no-io \
     -x $HOME/data/hg19 \
     -U seqs_by_100.fq \
     -p 24 \
     -S /dev/null

amplxe-cl -collect general-exploration \
  -app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
  -- ./bowtie2-align-s-no-io \
     -x $HOME/data/hg19 \
     -U seqs_by_100.fq \
     -p 52 \
     -S /dev/null


amplxe-cl -collect general-exploration \
  -app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
  -- ./bowtie2-align-s-no-io \
     -x $HOME/data/hg19 \
     -U seqs_by_100.fq \
     -p 100 \
     -S /dev/null

amplxe-cl -collect general-exploration \
  -app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
  -- ./bowtie2-align-s-no-io \
     -x $HOME/data/hg19 \
     -U seqs_by_100.fq \
     -p 120 \
     -S /dev/null









