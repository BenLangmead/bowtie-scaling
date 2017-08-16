#!/bin/bash -l

#SBATCH --job-name=TsKnlBwaPe
#SBATCH --output=.TsKnlBwaPe.out
#SBATCH --error=.TsKnlBwaPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=32:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bwa bwa.tsv stampede_knl pe 20000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
