#!/bin/bash -l

#SBATCH --job-name=TsSkxHtMuPe
#SBATCH --output=.TsSkxHtMuPe.out
#SBATCH --error=.TsSkxHtMuPe.err
#SBATCH --partition=skx-normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh ht ht_multiout.tsv stampede_skx pe 550000
