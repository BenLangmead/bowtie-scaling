#!/bin/bash

cmd_templ="/home/vanton/work/bowtie2/bowtie2-align-s -x /home/vanton/work/hg19/hg19 -U "
fastq_file="seqs_by_100.fq"
data_templ=$1

for ((t=1; t<40; t++)); do
  f_file=$fastq_file
  for (( i=1; i<t; i++ )); do
    f_file+=",$f_file"
  done
  cmd="$cmd_templ $f_file -p $t "
  data_file="${data_templ}${t}.out"
  echo $cmd
  $cmd | grep "thread:" > $data_file
done

