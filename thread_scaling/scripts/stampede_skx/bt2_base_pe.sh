#!/bin/bash -l

#SBATCH --job-name=TsSkxBt2BasePe
#SBATCH --output=.TsSkxBt2BasePe.out
#SBATCH --error=.TsSkxBt2BasePe.err
#SBATCH --partition=skx-normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt2 bt2_base.tsv stampede_skx pe 85000
