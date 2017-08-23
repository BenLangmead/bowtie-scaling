#!/bin/bash -l

#SBATCH --job-name=TsSmBwaPe
#SBATCH --output=.TsSmBwaPe.out
#SBATCH --error=.TsSmBwaPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/common.sh bwa bwa.tsv small pe 25000
