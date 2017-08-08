#!/bin/bash -l

TEMP=/storage/bowtie-scaling/temp
mkdir ${TEMP}
d=`dirname $PWD`
sh $d/bt.sh marcc_lbm unp ${TEMP}
