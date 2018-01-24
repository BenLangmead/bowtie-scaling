#!/bin/bash -l

d=`dirname $PWD`
sh $d/common.sh bt bt_multiout.tsv marcc_lbm unp 1000000
