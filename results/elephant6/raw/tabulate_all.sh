#!/usr/bin/env bash

SUMM="python ../../../thread_scaling/scripts/scale_summary.py"
NUMA_PIN=numa_master_and_no_IO
NUMA_UNPIN=master-tbb-pinned

for n in ${NUMA_PIN} ${NUMA_UNPIN} ; do
    NUMA_STR="numa_together"
    if [ "$n" = "$NUMA_PIN" ] ; then
        NUMA_STR="numa_apart"
    fi
    for s in normaltbbpin no_io_tbb_pin ; do
        SYNC_STR="unsync"
        if [ "$s" = "normaltbbpin" ] ; then
            SYNC_STR="sync"
        fi
        for mode in very-fast fast sensitive very-sensitive ; do
            ${SUMM} \
                --input ${n}/${mode}/${s}_* \
                --min-max-avg avg-${NUMA_STR}-${SYNC_STR}-${mode}.tsv \
                --scatter scatter_${NUMA_STR}-${SYNC_STR}_${mode}.tsv
        done
    done
done
