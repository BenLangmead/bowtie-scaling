#!/bin/bash -l

#SBATCH --job-name=TsSkxBtPe
#SBATCH --output=.TsSkxBtPe.out
#SBATCH --error=.TsSkxBtPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt bt.tsv stampede_skx pe 110000
