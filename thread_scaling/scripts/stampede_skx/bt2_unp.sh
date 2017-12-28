#!/bin/bash -l

#SBATCH --job-name=TsSkxBt2Unp
#SBATCH --output=.TsSkxBt2Unp.out
#SBATCH --error=.TsSkxBt2Unp.err
#SBATCH --partition=skx-normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt2 bt2.tsv stampede_skx unp 200000
