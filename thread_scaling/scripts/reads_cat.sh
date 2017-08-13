#!/bin/sh

BLOCK_BYTES=12288

for m in 1 2 ; do
	for l in 50 100 ; do
		READS_PER_BLOCK=70
		if [ "${l}" = "100" ] ; then
			READS_PER_BLOCK=44
		fi
		for b in "" "_block" ; do
			if [ ! -f "mix${l}${b}_${m}.fq.gz" ] ; then
				cat >.zip${l}${b}_${m}.sh <<EOF
#!/bin/bash -l
#SBATCH
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --mem=1G
#SBATCH --time=12:00:00
#SBATCH --ntasks-per-node=1

set -ex

cat mix${l}_?${b}_${m}.fq > mix${l}${b}_${m}.fq

if [ -n "${b}" ] ; then
    pypy check_blocked.py --fastq mix${l}${b}_${m}.fq --block-bytes $BLOCK_BYTES --reads-per-block $READS_PER_BLOCK
fi

EOF
				echo "sbatch .zip${l}${b}_${m}.sh"
			fi
		done
	done
done
