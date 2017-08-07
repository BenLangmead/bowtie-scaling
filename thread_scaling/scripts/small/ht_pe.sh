#!/bin/bash -l

#SBATCH --job-name=TsSmHtPe
#SBATCH --output=.TsSmHtPe.out
#SBATCH --error=.TsSmHtPe.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH -A TG-CIE170020

d=`dirname $PWD`
sh $d/ht.sh small pe
