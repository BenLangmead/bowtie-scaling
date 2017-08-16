#!/bin/bash -l

#SBATCH --job-name=TsSmBwaUnp
#SBATCH --output=.TsSmBwaUnp.out
#SBATCH --error=.TsSmBwaUnp.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/bwa.sh small unp 100000
