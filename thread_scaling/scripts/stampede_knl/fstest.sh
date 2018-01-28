#!/bin/sh

#SBATCH --job-name=fst
#SBATCH --output=.fstest.out
#SBATCH --error=.fstest.err
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=8:00:00
#SBATCH -A TG-CIE170020

set -e

HOST=`hostname`
NREADS=16000512
NOUT_LIST="1 2 4 8 16"
MT_MAX=256

INPUT_01OST=${SCRATCH}/fstest-01OST/${HOST}/pe
INPUT_16OST=${SCRATCH}/fstest-16OST/${HOST}/pe
SCR_DIR=${WORK}/git/bowtie-scaling/thread_scaling/scripts
INDEXES=/work/04265/benbo81/stampede2/indexes
NTRIALS=3
VERSIONS="ht-final-block-multi"

echo "# Deleting directories"
rm -rf ${INPUT_01OST}
rm -rf ${INPUT_16OST}

echo "# Creating directories"
mkdir -p ${INPUT_01OST} ${INPUT_16OST}
lfs setstripe --count  1 ${INPUT_01OST}
lfs setstripe --count 16 ${INPUT_16OST}

lfs getstripe -d ${INPUT_01OST}
lfs getstripe -d ${INPUT_16OST}

align() {
    ver=$1
    input_dir=$2
    output_dir=$3
    nout=$4
    of="/dev/null"
    if [ ${output_dir} != "/dev/null" ] ; then
        of="${output_dir}/out.sam"
    fi
    test -f ${input_dir}/1.fastq
    test -f ${input_dir}/2.fastq
    ${SCR_DIR}/bin/hisat-align-s-${ver} \
        -p ${MT_MAX} -I 250 -X 800 --reads-per-batch 32 \
        --block-bytes 12288 --reads-per-block 44 \
        --no-spliced-alignment --no-temp-splicesite \
        -x ${INDEXES}/hisat/hg38 -t \
        -1 ${input_dir}/1.fastq -2 ${input_dir}/2.fastq \
        -S ${of} >.fstest.sh.out 2>.fstest.sh.err
    if [ ${output_dir} != "/dev/null" ] ; then
        rm -f ${output_dir}/out*.sam
    fi
}

for nout in ${NOUT_LIST} ; do

    # Input directories
    for d in "/tmp" "${INPUT_01OST}" "${INPUT_16OST}" ; do
        echo "# Copying input data"
        head -n `expr $NREADS \* 4` ${SCR_DIR}/mix100_block_1.fq > ${d}/1.fastq
        head -n `expr $NREADS \* 4` ${SCR_DIR}/mix100_block_2.fq > ${d}/2.fastq 

        for VERSION in ${VERSIONS} ; do
            echo "#   Aligning ${VERSION}"
            
            # Output directories
            for outd in /dev/null /tmp ${INPUT_01OST} ${INPUT_16OST} ; do
                echo "Input: ${d} output: ${outd} nout: ${nout}"
                for i in `seq 1 ${NTRIALS}` ; do
                    align "${VERSION}" "${d}" "${outd}" "${nout}"
                done
            done
        done
        
        echo "Deleting inputs"
        rm -f ${d}/1.fastq ${d}/2.fastq
    done
done
