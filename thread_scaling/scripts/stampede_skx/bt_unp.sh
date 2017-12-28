#!/bin/bash -l

#SBATCH --job-name=TsSkxBtUnp
#SBATCH --output=.TsSkxBtUnp.out
#SBATCH --error=.TsSkxBtUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt bt.tsv stampede_skx unp 1000000
