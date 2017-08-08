#!/bin/bash -l

#SBATCH --job-name=TsKnlHtUnp
#SBATCH --output=.TsKnlHtUnp.out
#SBATCH --error=.TsKnlHtUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/ht.sh stampede_knl unp "EXTRA_FLAGS+=\"-ltbbmalloc\""
