#!/bin/bash -l

#SBATCH --job-name=TsSkxBtMuUnp
#SBATCH --output=.TsSkxBtMuUnp.out
#SBATCH --error=.TsSkxBtMuUnp.err
#SBATCH --partition=skx-normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bt bt_multiout.tsv stampede_skx unp 1000000
