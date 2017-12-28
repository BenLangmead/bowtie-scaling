#!/bin/bash -l

#SBATCH --job-name=TsSkxHtBaseUnp
#SBATCH --output=.TsSkxHtBaseUnp.out
#SBATCH --error=.TsSkxHtBaseUnp.err
#SBATCH --partition=skx-normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh ht ht_base.tsv stampede_skx unp 1200000
