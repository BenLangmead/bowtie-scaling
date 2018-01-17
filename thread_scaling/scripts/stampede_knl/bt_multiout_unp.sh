#!/bin/bash -l

#SBATCH --job-name=TsKnlBtMeUnp
#SBATCH --output=.TsKnlBtMeUnp.out
#SBATCH --error=.TsKnlBtMeUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt bt_multiout.tsv stampede_knl unp 450000 "EXTRA_FLAGS+=\"-ltbbmalloc\""
