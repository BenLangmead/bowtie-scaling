#!/bin/bash -l

#SBATCH --job-name=TsKnlBt2BIBPe
#SBATCH --output=.TsKnlBt2BIBPe.out
#SBATCH --error=.TsKnlBt2BIBPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt2 bt2_inbuf.tsv stampede_knl pe 16000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
