#!/bin/sh

ALIGNERS="bt bt2 ht"
ENDS="unp pe"
TYPES="base batchlo batchhi batchinbuf lustre"

for al in ${ALIGNERS} ; do
    for typ in ${TYPES} ; do
        for en in ${ENDS} ; do
            FN="${al}_${typ}_${en}.sh"
            echo ${FN}
            sbatch ${FN}
        done
    done
done
