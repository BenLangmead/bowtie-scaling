#!/bin/bash

cmd_templ_11="numactl --cpunodebind=1 --membind=1 ./bowtie2-align-s -x /home/vanton/work/hg19/hg19 -U "
cmd_templ_10="numactl --cpunodebind=1 --membind=0 ./bowtie2-align-s -x /home/vanton/work/hg19/hg19 -U "
fastq_file="seqs_by_100.fq"

data_templ=$1

for ((t=1; t<=12; t++)); do
  data_file_11="${data_templ}cpu1mem1_${t}.out"
  data_file_10="${data_templ}cpu1mem0_${t}.out"
  echo "threads: " $t
  $cmd_templ_11 <(for ((i=0;i<${t};i++)); do cat $fastq_file; done) -p $t | grep "thread:" > $data_file_11
  $cmd_templ_10 <(for ((i=0;i<${t};i++)); do cat $fastq_file; done) -p $t | grep "thread:" > $data_file_10
done

