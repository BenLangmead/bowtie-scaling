#!/bin/bash

HG19_INDEX=/home/vanton/work/hg19/hg19
MAX_THREADS=24
DR=`dirname $0`

# TODO: this is ugly but better ugly than more complicated parameters
cmd_tmpl="-x $HG19_INDEX "

run_th () {
READS="$DR/seqs_by_100.fq"
for ((t=1; t<=$MAX_THREADS; t++)); do
  #nreads=$(($READS_PER_THREAD * 100 * $t))
  cmd="./${1} $cmd_tmpl $t -U $READS "
  data_file="./runs/${2}${t}.out"
  echo $cmd
  $cmd | grep thread > $data_file
  READS="$READS,$DR/seqs_by_100.fq"
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
cmd_tmpl="$cmd_tmpl -p"

mkdir -p runs

#start with normal 
if [ ! -f "bowtie2-align-s-master" ] ; then
  git checkout master
  rm bowtie2-align-s
  make EXTRA_FLAGS="-DUSE_FINE_TIMER -DPER_THREAD_TIMING" bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-master
fi
run_th bowtie2-align-s-master normal_

# Only no input sync
if [ ! -f "bowtie2-align-s-no-in-sync" ] ; then
  git checkout no_in_sync
  rm bowtie2-align-s
  make EXTRA_FLAGS="-DUSE_FINE_TIMER -DPER_THREAD_TIMING -Wtrigraphs" bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-no-in-sync
fi
run_th bowtie2-align-s-no-in-sync no_in_

# No input/output sync
if [ ! -f "bowtie2-align-s-no-io" ] ; then
  git checkout no_IO_2000seq
  rm bowtie2-align-s
  make EXTRA_FLAGS="-DUSE_FINE_TIMER -DPER_THREAD_TIMING -Wtrigraphs" bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-no-io
fi
run_th bowtie2-align-s-no-io no_io_
