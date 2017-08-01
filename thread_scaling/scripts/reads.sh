#!/bin/sh

set -ex

grep ftp reads.py | awk '{print $2}' | sed "s/[',]//g" > .reads.txt
for i in `cat .reads.txt` ; do
    if [ ! -f `basename $i` ] ; then
        curl -O -J -L $i
    fi
done

for i in 0 1 2 3 4 5 6 7 8 9 ; do
    cat >.reads.${i}.sh <<EOF
#!/bin/bash -l
#SBATCH
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --mem=4G
#SBATCH --time=8:00:00
#SBATCH --ntasks-per-node=1

# For HISAT unpaired to run about a minute, we need about 300M reads
python reads.py --prefix=mix100_${i} --temp-dir=mix100_${i}_temp --reads-per-accession 10000000

# For Bowtie 1 unpaired to run about a mnute, we need about 300M reads
python reads.py --trim-to 50 --max-read-size 175 --prefix=mix50_${i} --temp-dir=mix50_${i}_temp --reads-per-accession 10000000

EOF
    echo "sbatch .reads.${i}.sh"
done

#for i in `cat .reads.txt` ; do
#    rm -f `basename $i`
#done
#rm -f .reads.txt
