#!/bin/bash -l
#SBATCH
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --mem=32G
#SBATCH --time=20:00:00
#SBATCH --ntasks-per-node=8

set -ex

grep ftp reads.py | awk '{print $2}' | sed "s/[',]//g" > .reads.txt
for i in `cat .reads.txt` ; do
    if [ ! -f `basename $i` ] ; then
        curl -O -J -L $i
    fi
done

# For HISAT unpaired to run about a minute, we need about 300M reads
python reads.py --prefix=mix100 --reads-per-accession 100000000

# For Bowtie 1 unpaired to run about a mnute, we need about 300M reads
python reads.py --trim-to 50 --max-read-size 175 --prefix=mix50 --reads-per-accession 100000000

for i in `cat .reads.txt` ; do
    rm -f `basename $i`
done
rm -f .reads.txt
