#!/bin/bash -l

#SBATCH --job-name=TsKnlBt2Unp
#SBATCH --output=.TsKnlBt2Unp.out
#SBATCH --error=.TsKnlBt2Unp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/bt2.sh stampede_knl unp /tmp "EXTRA_FLAGS+=\"-ltbbmalloc\""
