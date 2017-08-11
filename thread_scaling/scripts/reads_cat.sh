#!/bin/sh

BLOCK_BYTES=12288

for m in 1 2 ; do
	for l in 50 100 ; do
		READS_PER_BLOCK=70
		if [ "${l}" = "100" ] ; then
			READS_PER_BLOCK=44
		fi
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

rm -f mix${l}_block_${m}.fq mix${l}_${m}.fq
touch mix${l}_block_${m}.fq mix${l}_${m}.fq

for bfn in mix${l}_?_block_${m}.fq ; do
    fn=`echo \${bfn} | sed 's/_block//'`
    BYTES=`wc -c \${bfn} | awk '{print \$1}'`
    HEADC=`python -c "print (\$BYTES - (\$BYTES % $BLOCK_BYTES))"`
    LINES=`head -c $HEADC \${bfn} | wc -l`
    # make sure we're taking the same (and same # of) reads from both
    head -c $HEADC \${bfn} >> mix${l}_block_${m}.fq
    head -n $LINES \${fn}  >> mix${l}_${m}.fq
done

# check the blocked output to ensure boundaries are correct
pypy check_blocked.py --fastq mix${l}_block_${m}.fq \
                      --block-bytes $BLOCK_BYTES \
                      --reads-per-block $READS_PER_BLOCK
EOF
			echo "sbatch .zip${l}${b}_${m}.sh"
		fi
	done
done

