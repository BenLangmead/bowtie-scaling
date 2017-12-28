#!/bin/bash -l

#SBATCH --job-name=TsSkxBwaUnp
#SBATCH --output=.TsSkxBwaUnp.out
#SBATCH --error=.TsSkxBwaUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=48:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bwa bwa.tsv stampede_skx unp 200000
