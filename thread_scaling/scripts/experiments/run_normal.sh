#!/bin/bash

cmd_templ="/home/vanton/work/bowtie2/bowtie2-align-s -x /home/vanton/work/hg19/hg19 -U "
fastq_file="seqs_by_100.fq"
sub_proc_templ_1="<(for ((i=0;i<"
sub_proc_templ_2=";i++)); do cat $fastq_file; done)"

data_templ=$1

for ((t=1; t<40; t++)); do
  cmd="$cmd_templ ${sub_proc_templ_1}${t}${sub_proc_templ_2} -p $t "
  data_file="${data_templ}${t}.out"
  echo $cmd
  $cmd | grep "thread:" > $data_file
done

