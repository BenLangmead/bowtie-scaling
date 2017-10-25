#!/bin/bash -l

#SBATCH --job-name=TsKnlHtBHUnp
#SBATCH --output=.TsKnlHtBHUnp.out
#SBATCH --error=.TsKnlHtBHUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh ht ht_batchhi.tsv stampede_knl unp 400000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
