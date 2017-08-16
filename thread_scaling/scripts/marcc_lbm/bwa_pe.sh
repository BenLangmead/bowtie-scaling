#!/bin/bash -l

d=`dirname $PWD`
sh $d/common.sh bwa bwa.tsv marcc_lbm pe 85000
