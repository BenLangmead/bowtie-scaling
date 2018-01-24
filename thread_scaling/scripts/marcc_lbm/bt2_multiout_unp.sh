#!/bin/bash -l

d=`dirname $PWD`
sh $d/common.sh bt2 bt2_multiout.tsv marcc_lbm unp 200000
