#!/bin/sh

#SBATCH --job-name=fstXXX
#SBATCH --output=.fstestXXX.out
#SBATCH --error=.fstestXXX.err
#SBATCH --begin=now+XXXhour
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=2:00:00
#SBATCH -A TG-CIE170020

set -e

HOST=`hostname`
NREADS=8000000


INPUT_01OST=${SCRATCH}/fstest-01OST/${HOST}/pe
INPUT_16OST=${SCRATCH}/fstest-16OST/${HOST}/pe
SCR_DIR=${WORK}/git/bowtie-scaling/thread_scaling/scripts
INDEXES=/work/04265/benbo81/stampede2/indexes
NTRIALS=5

echo "# Deleting directories"
rm -rf ${INPUT_01OST}
rm -rf ${INPUT_16OST}
rm -f /tmp/?.fq

echo "# Creating directories"
mkdir -p ${INPUT_01OST} ${INPUT_16OST}
lfs setstripe --count  1 ${INPUT_01OST}
lfs setstripe --count 16 ${INPUT_16OST}

lfs getstripe -d ${INPUT_01OST}
lfs getstripe -d ${INPUT_16OST}

echo "# Copying input data"
for d in "/tmp" "${INPUT_01OST}" "${INPUT_16OST}" ; do
    if [ ! -f ${d}/1.fq ] ; then
        # Blocked
        head -n `expr $NREADS \* 4` ${SCR_DIR}/mix100_block_1.fq > ${d}/1.fq
        head -n `expr $NREADS \* 4` ${SCR_DIR}/mix100_block_2.fq > ${d}/2.fq
    fi
done

align() {
    ${SCR_DIR}/stampede_knl/build-pe/ht/pe/${1}/hisat-align-s \
        -p 248 -I 250 -X 800 --reads-per-batch 32 \
            --block-bytes 12288 --reads-per-block 44 \
            --no-spliced-alignment --no-temp-splicesite \
            -x ${INDEXES}/hisat/hg38 -t \
            -1 ${2}/1.fq -2 ${2}/2.fq \
            -S ${3} 2>/dev/null | \
                awk -v FS=':' '$1 == "thread" && $2 ~ /time/ {print($2" "$3*60*60+$4*60+$5)}' | \
                awk '{print $NF}' | st
}

for VERSION in ht-final-block ht-final-block-heavy ; do

    echo "#   Aligning ${VERSION}"
    for ind in /tmp ${INPUT_01OST} ${INPUT_16OST} ; do
        for outd in /dev/null /tmp/out.sam ${INPUT_01OST}/out.sam ${INPUT_16OST}/out.sam ; do
            echo "Input: ${ind} output: ${outd}"
            for i in `seq 1 ${NTRIALS}` ; do
                align "${VERSION}" "${ind}" "${outd}"
            done
        done
    done

done
