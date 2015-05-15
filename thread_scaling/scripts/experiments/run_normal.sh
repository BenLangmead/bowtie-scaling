#!/bin/bash

cmd_templ="/home/vanton/work/bowtie2/bowtie2-align-s -x /home/vanton/work/hg19/hg19 -U "
fastq_file="seqs_by_100.fq"

data_templ=$1

for ((t=1; t<40; t++)); do
  data_file="${data_templ}${t}.out"
  echo "threads: " $t
  $cmd_templ <(for ((i=0;i<${t};i++)); do cat $fastq_file; done) | grep "thread:" > $data_file
done

