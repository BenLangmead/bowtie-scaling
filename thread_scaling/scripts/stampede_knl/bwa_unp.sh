#!/bin/bash -l

#SBATCH --job-name=TsKnlBwaUnp
#SBATCH --output=.TsKnlBwaUnp.out
#SBATCH --error=.TsKnlBwaUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bwa bwa.tsv stampede_knl unp 60000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
