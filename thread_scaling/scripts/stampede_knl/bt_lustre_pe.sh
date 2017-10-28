#!/bin/bash -l

#SBATCH --job-name=TsKnlBtLustPe
#SBATCH --output=.TsKnlBtLustPe.out
#SBATCH --error=.TsKnlBtLustPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt bt_lustre.tsv stampede_knl pe 37500 "EXTRA_FLAGS+=\"-ltbbmalloc\""
