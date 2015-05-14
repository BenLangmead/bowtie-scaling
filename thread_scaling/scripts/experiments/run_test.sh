#!/bin/bash

# TODO: this is ugly but better ugly than more complicated parameters
cmd_templ="/home/vanton/work/bowtie2/bowtie2-align-s -x /home/vanton/work/hg19/hg19 -U /home/vanton/work/bowtie2/example/reads/longreads.fq -p"

if [[ $# < 1 ]]; then
  echo -e "Quick way to run some experiments.\n"
  echo -e "\t$0 [prefix_for_data_files]\n"
  echo -e "\nExample:\n"
  echo -e "\t$0 /home/runs/experiment_\n"
  echo "This will run bowtie2 and will store the timing for each thread into /home/runs/experiment_[n].out"
  echo "where [n] will be replaced with the number of threads used for bowtie2 -p parameter."
  exit 0
fi
data_templ="/home/vanton/b2_scale_data/no_IO_"

for ((t=1; t<40; t++)); do
  cmd="$cmd_templ $t "
  data_file="${data_templ}${t}.out"
  echo $cmd
  $cmd | grep thread > $data_file
done

