#!/bin/bash -l

#SBATCH --job-name=TsKnlBt2BLUnp
#SBATCH --output=.TsKnlBt2BLUnp.out
#SBATCH --error=.TsKnlBt2BLUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt2 bt2_batchlo.tsv stampede_knl unp 65000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
