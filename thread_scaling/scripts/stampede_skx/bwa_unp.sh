#!/bin/bash -l

#SBATCH --job-name=TsSkxBwaUnp
#SBATCH --output=.TsSkxBwaUnp.out
#SBATCH --error=.TsSkxBwaUnp.err
#SBATCH --partition=skx-normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bwa bwa.tsv stampede_skx unp 200000
