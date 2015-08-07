#!/bin/bash

HG19_INDEX=$HOME/hg19
MAX_THREADS=24
DR=`dirname $0`
READS="$DR/seqs_by_100.fq"
cmd_tmpl="-x $HG19_INDEX "

run_th () {
for mode in very-fast fast sensitive very-sensitive ; do
  for ((t=1; t<=$MAX_THREADS; t++)); do
    cmd="./${1} $cmd_tmpl --$mode -U "
    mkdir -p runs/$mode
    data_file="./runs/$mode/${2}${t}.out"
    echo "mode: $mode, threads: $t"
    $cmd <(for ((i=0;i<${t};i++)); do cat $READS; done) -p $t | grep "thread:" > $data_file
  done
done
}

if [[ $# < 1 ]]; then
  echo -e "Run all experiments.\n"
  echo -e "\t$0 [bowtie-extra-parameters]"
  echo "This will run all bowtie2 experiments and store the timing for each thread into ./runs/[experiment]_[n].out"
  echo "where [n] will be replaced with the number of threads used for bowtie2 -p parameter."
  exit 0
fi
cmd_tmpl="$cmd_tmpl $1"

#start with normal 
if [ ! -f "bowtie2-align-s-master" ] ; then
  git checkout master
  rm -f bowtie2-align-s-master
  make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-master
fi
run_th bowtie2-align-s-master normal_

# Only no input sync
if [ ! -f "bowtie2-align-s-no-in-sync" ] ; then
  git checkout no_in_sync
  rm -f bowtie2-align-s-no-in-sync
  make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-no-in-sync
fi
run_th bowtie2-align-s-no-in-sync no_in_

# No input/output sync
if [ ! -f "bowtie2-align-s-no-io" ] ; then
  git checkout no_IO_2000seq
  rm -f bowtie2-align-s-no-io
  make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-no-io
fi
run_th bowtie2-align-s-no-io no_io_
