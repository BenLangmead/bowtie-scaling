#!/bin/bash -l

#SBATCH --job-name=TsSmHtUnp
#SBATCH --output=.TsSmHtUnp.out
#SBATCH --error=.TsSmHtUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh ht ht.tsv small unp 400000
