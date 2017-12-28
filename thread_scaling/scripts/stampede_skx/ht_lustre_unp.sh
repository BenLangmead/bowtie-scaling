#!/bin/bash -l

#SBATCH --job-name=TsSkxHtLustUnp
#SBATCH --output=.TsSkxHtLustUnp.out
#SBATCH --error=.TsSkxHtLustUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh ht ht_lustre.tsv stampede_skx unp 1200000
