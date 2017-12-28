#!/bin/bash -l

#SBATCH --job-name=TsSkxBtBasePe
#SBATCH --output=.TsSkxBtBasePe.out
#SBATCH --error=.TsSkxBtBasePe.err
#SBATCH --partition=skx-normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt bt_base.tsv stampede_skx pe 110000
