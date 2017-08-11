#!/bin/bash -l

#SBATCH --job-name=TsKnlBt2Pe
#SBATCH --output=.TsKnlBt2Pe.out
#SBATCH --error=.TsKnlBt2Pe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/bt2.sh stampede_knl pe 17500 "EXTRA_FLAGS+=\"-ltbbmalloc\""
