#!/bin/bash -l
#SBATCH
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --mem=16G
#SBATCH --time=8:00:00
#SBATCH --ntasks-per-node=4

set -ex

grep ftp reads.py | awk '{print $2}' | sed "s/[',]//g" > .reads.txt
for i in `cat .reads.txt` ; do
    if [ ! -f `basename $i` ] ; then
        curl -O -J -L $i
    fi
done

pypy reads.py --prefix=mix100
pypy reads.py --trim-to 50 --max-read-size 175 --prefix=mix50

for i in `cat .reads.txt` ; do
    rm -f `basename $i`
done
rm -f .reads.txt
