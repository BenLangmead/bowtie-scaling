#!/bin/bash -l

#SBATCH --job-name=TsKnlHtPe
#SBATCH --output=.TsKnlHtPe.out
#SBATCH --error=.TsKnlHtPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=32:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/ht.sh stampede_knl pe 250000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
