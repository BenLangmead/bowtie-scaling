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
fi
cmd_tmpl="$cmd_tmpl $1"

# This will spawn a bowtie process for each NUMA node and will continue to
# increase the number of threads for each iteration. Therefore this function
# will run n*t threads at any step, where n is the total number of NUMA nodes
# and t is the thread step from 1 to MAX_THREADS.
run_th () {
    local TIMING_DIR="../../../results/elephant6/raw/"
    declare -a INPUT_READS=()
    declare -a OUTPUT_SAMFILE=()
    local timing_file
    local cmd
    mkdir -p $TIMING_DIR
    for mode in very-fast fast sensitive very-sensitive ; do
      for ((t=$NODES; t<=$MAX_THREADS; t+=$NODES)); do
        ((nthread=$t/$NODES))
        cmd="./${1} $cmd_tmpl --$mode -U "
        
        echo "mode: $mode, threads: $t"
        echo "Concatenating input reads"
        for ((i=0; i<$NODES; i++)); do
            INPUT_READS[$i]=$(mktemp -p /tmp bowtie2_test_XXXX_${i}.fq)
            OUTPUT_SAMFILE[$i]=$(mktemp -p /tmp bowtie2_test_XXXX_${i}.sam)
            for ((j=0; j<$nthread; j++)); do
                cat $READS >> ${INPUT_READS[$i]}
            done
        done
        # make sure input and output are on a local filesystem, not NFS
        echo "Running bowtie2"
        pids=""
        for ((i=0; i<$NODES; i++)); do
            timing_file="${TIMING_DIR}/$mode/${2}${t}_${i}.out"
            mkdir -p "${TIMING_DIR}/$mode"
            (numactl -N $i $cmd ${INPUT_READS[$i]} -p $nthread -S ${OUTPUT_SAMFILE[$i]} | grep "thread:" > $timing_file) &
            echo "  spawned node $i process with pid $!"
            pids="$! $pids"
        done
        for pid in $pids ; do
            echo "  waiting for PID $pid"
            wait $pid
        done
        # cleanup
        for fs in "${INPUT_READS[@]}"; do
            echo " removing $fs"
            rm $fs
        done
        for fs in "${OUTPUT_SAMFILE[@]}"; do
            echo "removing $fs"
            rm $fs
        done
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

#Normal TBB queue lock and Affinitization
if [ ! -f "bowtie2-align-s-tbb-pin-queue" ] ; then
  git checkout cohort_locking_ptl_tkt
  rm -f bowtie2-align-s-tbb-pin-queue bowtie2-align-s
  make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" WITH_TBB=1 WITH_AFFINITY=1 NO_SPINLOCK=1 WITH_QUEUELOCK=1 bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-tbb-pin-queue
fi
run_th bowtie2-align-s-tbb-pin-queue tbb_pin_queue_

#Normal TBB but using Cohort Locks implemented via TBB (normal/default) and Queue mutexes
#NOTE WITH_AFFINITY is required for Cohort locks as we don't want threads automatically migrating
#across numa nodes defeating the purpose of the Cohort lock
if [ ! -f "bowtie2-align-s-tbb-pin-ctbbqueue" ] ; then
  git checkout cohort_locking_ptl_tkt
  rm -f bowtie2-align-s-tbb-pin-ctbbqueue bowtie2-align-s
  make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" WITH_TBB=1 WITH_AFFINITY=1 WITH_QUEUELOCK_=1 WITH_COHORTLOCK=1 bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-tbb-pin-ctbbqueue
fi
run_th bowtie2-align-s-tbb-pin-ctbbqueue tbb_pin_ctbbqueue_

#Normal TBB but using Cohort Locks implemented via Ticket and Partition mutexes
#NOTE WITH_AFFINITY is required for Cohort locks as we don't want threads automatically migrating
#across numa nodes defeating the purpose of the Cohort lock
if [ ! -f "bowtie2-align-s-tbb-pin-ctktptl" ] ; then
  git checkout cohort_locking_ptl_tkt
  rm -f bowtie2-align-s-tbb-pin-ctktptl bowtie2-align-s
  make WITH_THREAD_PROFILING=1 EXTRA_FLAGS="-DUSE_FINE_TIMER" WITH_TBB=1 WITH_AFFINITY=1 WITH_COHORTLOCK=1 bowtie2-align-s
  mv bowtie2-align-s bowtie2-align-s-tbb-pin-ctktptl
fi
run_th bowtie2-align-s-tbb-pin-ctktptl tbb_pin_ctktptl_
