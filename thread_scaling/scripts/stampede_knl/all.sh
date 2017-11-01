#!/bin/sh

ALIGNERS="bt bt2 ht"
DO_BWA=1
ENDS="unp pe"
TYPES="base batchlo batchhi batchinbuf lustre"

for en in ${ENDS} ; do
    for al in ${ALIGNERS} ; do
        for typ in ${TYPES} ; do
            FN="${al}_${typ}_${en}.sh"
            echo ${FN}
            sbatch ${FN}
        done
        FN="${al}_${en}.sh"
        echo ${FN}
        sbatch ${FN}
    done
    if [ "${DO_BWA}" = "1" ] ; then
        FN="bwa_${en}.sh"
        echo ${FN}
        sbatch ${FN}
    fi
done
