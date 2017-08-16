#!/bin/bash -l

#SBATCH --job-name=TsKnlBwaUnp
#SBATCH --output=.TsKnlBwaUnp.out
#SBATCH --error=.TsKnlBwaUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=32:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/bwa.sh stampede_knl unp 100000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
