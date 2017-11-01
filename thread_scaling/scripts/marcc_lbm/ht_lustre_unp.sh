#!/bin/bash -l

d=`dirname $PWD`
sh $d/common.sh ht ht_lustre.tsv marcc_lbm unp 1200000
