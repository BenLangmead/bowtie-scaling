#!/bin/bash -l

#SBATCH --job-name=TsSkxBt2Pe
#SBATCH --output=.TsSkxBt2Pe.out
#SBATCH --error=.TsSkxBt2Pe.err
#SBATCH --partition=skx-normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt2 bt2.tsv stampede_skx pe 85000
