#!/bin/bash -l

#SBATCH --job-name=TsSkxHtBasePe
#SBATCH --output=.TsSkxHtBasePe.out
#SBATCH --error=.TsSkxHtBasePe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh ht ht_base.tsv stampede_skx pe 550000
