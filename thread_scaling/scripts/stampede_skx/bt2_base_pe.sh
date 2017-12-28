#!/bin/bash -l

#SBATCH --job-name=TsSkxBt2BasePe
#SBATCH --output=.TsSkxBt2BasePe.out
#SBATCH --error=.TsSkxBt2BasePe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt2 bt2_base.tsv stampede_skx pe 85000
