#!/bin/bash

HG19_INDEX=$HOME/data/hg19
MAX_THREADS=`grep 'processor\s*:' /proc/cpuinfo | wc -l`
DR=`dirname $0`
READS="$DR/seqs_by_100.fq"
cmd_tmpl="-x $HG19_INDEX "
NODES=`numactl --hardware | grep available: | awk '{print $2}'`

echo "Max threads = $MAX_THREADS"
echo "NUMA nodes = $NODES"

if [[ $# < 1 ]]; then
  echo -e "Run all experiments.\n"
  echo -e "\t$0 [bowtie-extra-parameters]"
  echo "This will run all bowtie2 experiments and store the timing for each thread into ./runs/[experiment]_[n].out"
  echo "where [n] will be replaced with the number of threads used for bowtie2 -p parameter."
  exit 0
fi
cmd_tmpl="$cmd_tmpl $1"

run_th () {
for mode in very-fast fast sensitive very-sensitive ; do
  for ((t=$NODES; t<=$MAX_THREADS; t+=$NODES)); do
    ((nthread=$t/$NODES))
    cmd="./${1} $cmd_tmpl --$mode -U "
    mkdir -p numabind_runs/$mode
    mkdir -p ../../../results/elephant6/numabind_raw/$mode
    echo "mode: $mode, threads: $t"
    echo "Concatenating input reads"
    for ((i=0; i<$NODES; i++)); do
        in="/tmp/.nodebind_test_reads_${i}.fq"
        cp $READS $in
        for ((j=1;j<$nthread;j++)); do cat $READS >> $in; done
    done
    # make sure input and output are on a local filesystem, not NFS
    echo "Running bowtie2"
    pids=""
    for ((i=0; i<$NODES; i++)); do
        in="/tmp/.nodebind_test_reads_${i}.fq"
        out="/tmp/.nodebind_test_reads_${i}.sam"
        data_file="../../../results/elephant6/numabind_raw/$mode/${2}${t}_${i}.out"
        (numactl -N $i $cmd $in -p $nthread -S $out | grep "thread:" > $data_file) &
        echo "  spawned node $i process with pid $!"
        pids="$! $pids"
    done
    for pid in $pids ; do
        echo "  waiting for PID $pid"
        wait $pid
    done
    ((nthread++))
  done
done
}

# Normal (all synchronization enabled), no TBB
#if [ ! -f "bowtie2-align-s-master" ] ; then
  #git checkout master
  #rm -f bowtie2-align-s-master bowtie2-align-s
  #make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" bowtie2-align-s
  #mv bowtie2-align-s bowtie2-align-s-master
#fi
#run_th bowtie2-align-s-master normal_

## Normal (all synchronization enabled), with TBB
#if [ ! -f "bowtie2-align-s-master-tbb" ] ; then
  #git checkout master
  #rm -f bowtie2-align-s-master-tbb bowtie2-align-s
  #make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" WITH_TBB=1 bowtie2-align-s
  #mv bowtie2-align-s bowtie2-align-s-master-tbb
#fi
#run_th bowtie2-align-s-master-tbb normaltbb_

# Normal (all synchronization enabled), with TBB and thread affinitization
if [ ! -f "bowtie2-align-s-master-tbb-pin" ] ; then
  git checkout master
  rm -f bowtie2-align-s-master-tbb-pin bowtie2-align-s
  make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" WITH_TBB=1 WITH_AFFINITY=1 bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-master-tbb-pin
fi
run_th bowtie2-align-s-master-tbb-pin normaltbbpin_

# Only no input sync
#if [ ! -f "bowtie2-align-s-no-in-sync" ] ; then
  #git checkout no_in_sync
  #rm -f bowtie2-align-s-no-in-sync bowtie2-align-s
  #make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" bowtie2-align-s
  #mv bowtie2-align-s bowtie2-align-s-no-in-sync
#fi
#run_th bowtie2-align-s-no-in-sync no_in_

## No input/output sync
#if [ ! -f "bowtie2-align-s-no-io" ] ; then
  #git checkout no_IO_2000seq
  #rm -f bowtie2-align-s-no-io bowtie2-align-s
  #make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" bowtie2-align-s
  #mv bowtie2-align-s bowtie2-align-s-no-io
#fi
#run_th bowtie2-align-s-no-io no_io_

# No input/output sync but with TBB and Affinitization
if [ ! -f "bowtie2-align-s-no-io-tbb-pin" ] ; then
  git checkout no_IO_2000seq
  rm -f bowtie2-align-s-no-io-tbb-pin bowtie2-align-s
  make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" WITH_TBB=1 WITH_AFFINITY=1 bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-no-io-tbb-pin
fi
run_th bowtie2-align-s-no-io-tbb-pin no_io_tbb_pin_


