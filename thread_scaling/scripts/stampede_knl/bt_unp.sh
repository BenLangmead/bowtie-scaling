#!/bin/bash -l

#SBATCH --job-name=TsKnlBtUnp
#SBATCH --output=.TsKnlBtUnp.out
#SBATCH --error=.TsKnlBtUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=32:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/bt.sh stampede_knl unp 450000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
