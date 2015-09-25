#!/bin/bash

work_dir=$(pwd)
vtune="/opt/intel/vtune_amplifier_xe/bin64/amplxe-cl"

#for thread in 1 12 24 52 100 120; do
    #$vtune -collect general-exploration \
      #-app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
      #-- ./bowtie2-align-s-no-io \
         #-x $HOME/data/hg19 \
         #-U seqs_by_100.fq \
         #-p $thread \
         #-S /dev/null
#done

#for thread in 1 12 24 ; do
    #$vtune -collect general-exploration \
      #-app-working-dir $HOME/bowtie-scaling/thread_scaling/scripts/experiments \
      #-- numactl --cpunodebind=0 --membind=0 ./bowtie2-align-s-no-io \
         #-x $HOME/data/hg19 \
         #-U seqs_by_100.fq \
         #-p $thread \
         #-S /dev/null
#done

for thread in 1 12 24 48 96 120; do
    # generate input reads on local file system
    INPUT_READS=$(mktemp -p /tmp bowtie2_test_XXXX.fq)
    for ((i=0; i<${thread}; i++)); do 
        cat seqs_by_100.fq >> $INPUT_READS 
    done
    for mode in very-fast fast sensitive very-sensitive ; do
        # master/TBB/pin
        $vtune -collect general-exploration \
          -app-working-dir $work_dir \
          -data-limit 0 \
          -r masterTBBpin_${mode}_${thread} \
          -- ./bowtie2-align-s-master-tbb-pin \
            -x $HOME/data/hg19 \
            -U $INPUT_READS \
            -p $thread \
            -S /dev/null
        # no IO 2000seq
        $vtune -collect general-exploration \
          -app-working-dir $work_dir \
          -data-limit 0 \
          -r noIO_TBBpin_${mode}_${thread} \
          -- ./bowtie2-align-s-no-io-tbb-pin \
            -x $HOME/data/hg19 \
            -U $INPUT_READS \
            -p $thread \
            -S /dev/null
    done
    # cleanup
    rm $INPUT_READS
done







