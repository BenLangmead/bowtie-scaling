#!/bin/bash -l

TEMP=/storage/bowtie-scaling/temp
mkdir ${TEMP}
d=`dirname $PWD`
sh $d/ht.sh marcc_lbm pe ${TEMP}
