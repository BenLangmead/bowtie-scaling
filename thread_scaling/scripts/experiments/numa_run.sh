#!/bin/bash

# TODO: command line params
cmd_tmpl="./bowtie2-align-s -x /home/vanton/work/hg19/hg19 -U seqs_by_100.fq "
# Actually langmead-login preffered node: current

max_cores=0
max_running_threads=0 
numa_nodes=0
xp_subdir="numa_runs"

run_th () {
  local cmd_same_node
  local cmd_different_node
  local data_file_same_node
  local data_file_different_node
  local last_node=$((numa_nodes - 1))
  local prev_node=$((last_node - 1))

  for ((t=1; t<=max_running_threads; t++)); do
    cmd_same_node="numactl --cpunodebind=${last_node} --membind=${last_node} ${cmd_tmpl} $t "
    cmd_different_node="numactl --cpunodebind=${last_node} --membind=${prev_node} ${cmd_tmpl} $t "
    data_file_same_node="./${xp_subdir}/${1}cpu${last_node}mem${last_node}_${t}.out"
    data_file_different_node="./${xp_subdir}/${1}cpu${last_node}mem${prev_node}_${t}.out"
    echo $cmd_same_node
    $cmd_same_node | grep thread > $data_file_same_node
    echo $cmd_different_node
    $cmd_different_node | grep thread > $data_file_different_node
  done
}

get_cores () {
  echo $(cat /proc/cpuinfo |grep processor|wc -l)
}

get_numa_nodes () {
  echo $(numactl --show|grep nodebind | cut -d':' -f2|awk '{print NF}')
}

max_cores=$(get_cores)
numa_nodes=$(get_numa_nodes)
((max_running_threads=max_cores/numa_nodes)) # TODO: division by zero

cmd_tmpl+="$1"
cmd_tmpl+=" -p "

mkdir -p $xp_subdir

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

