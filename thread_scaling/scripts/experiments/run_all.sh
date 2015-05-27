#!/bin/bash

# TODO: this is ugly but better ugly than more complicated parameters
cmd_tmpl="./bowtie2-align-s -x /home/vanton/work/hg19/hg19 -U seqs_by_100.fq "

run_th () {
for ((t=1; t<24; t++)); do
  cmd="$cmd_templ $t "
  data_file="./runs/${1}${t}.out"
  echo $cmd
  $cmd | grep thread > $data_file
done
}

if [[ $# < 1 ]]; then
  echo -e "Run all experiments.\n"
  echo -e "\t$0 [bowtie-extra-parameters]"
  echo "This will run all bowtie2 experiments and store the timing for each thread into ./runs/[experiment]_[n].out"
  echo "where [n] will be replaced with the number of threads used for bowtie2 -p parameter."
  exit 0
fi
cmd_tmpl+=$1
cmd_tmpl+=" -p "

mkdir -p runs

#start with normal 
git checkout master
rm bowtie2-align-s
make -j bowtie2-align-s
run_th normal_

# Only no input sync
git checkout no_in_sync
rm bowtie2-align-s
make -j bowtie2-align-s
run_th no_in_

# No input/output sync
git checkout no_IO_2000seq
rm bowtie2-align-s
make -j bowtie2-align-s
run_th no_io_

