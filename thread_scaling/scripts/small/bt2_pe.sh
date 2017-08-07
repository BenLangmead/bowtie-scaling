#!/bin/bash -l

#SBATCH --job-name=TsSmBt2Pe
#SBATCH --output=.TsSmBt2Pe.out
#SBATCH --error=.TsSmBt2Pe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/bt2.sh small pe
