#!/bin/bash -l

#SBATCH --job-name=TsKnlBt2LustPe
#SBATCH --output=.TsKnlBt2LustPe.out
#SBATCH --error=.TsKnlBt2LustPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt2 bt2_lustre.tsv stampede_knl pe 16000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
