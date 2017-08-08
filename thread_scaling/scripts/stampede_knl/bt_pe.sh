#!/bin/bash -l

#SBATCH --job-name=TsKnlBtPe
#SBATCH --output=.TsKnlBtPe.out
#SBATCH --error=.TsKnlBtPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/bt.sh stampede_knl pe "EXTRA_FLAGS+=\"-ltbbmalloc\""
