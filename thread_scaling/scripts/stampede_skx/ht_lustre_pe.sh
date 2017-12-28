#!/bin/bash -l

#SBATCH --job-name=TsSkxHtLustPe
#SBATCH --output=.TsSkxHtLustPe.out
#SBATCH --error=.TsSkxHtLustPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh ht ht_lustre.tsv stampede_skx pe 550000
