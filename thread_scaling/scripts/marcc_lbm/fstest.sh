#!/bin/sh

set -e

HOST=`hostname`
NREADS=8000000
NTHREADS=112

GS=/scratch/groups/blangme2
US=/scratch/users/blangme2@jhu.edu
INPUT_01OST=${GS}/fstest-01OST/${HOST}/pe
INPUT_STORAGE=/storage/bowtie-scaling/temp/fstest
SCR_DIR=${US}/git/bowtie-scaling/thread_scaling/scripts
INDEXES=${GS}/indexes
NTRIALS=3

echo "# Deleting directories"
rm -rf ${INPUT_01OST} ${INPUT_STORAGE}

echo "# Creating directories"
mkdir -p ${INPUT_01OST} ${INPUT_STORAGE}

echo "# Copying input data"
for d in "${INPUT_01OST}" "${INPUT_STORAGE}" ; do
    if [ ! -f ${d}/1.fq ] ; then
        # Blocked
	for i in 1 2 ; do cp ${SCR_DIR}/${i}.fq ${d}/${i}.fq ; done
    fi
done

align() {
    ${SCR_DIR}/marcc_lbm/build-pe/ht/pe/${1}/hisat-align-s \
        -p ${NTHREADS} -I 250 -X 800 --reads-per-batch 32 \
            --block-bytes 12288 --reads-per-block 44 \
            --no-spliced-alignment --no-temp-splicesite \
            -x ${INDEXES}/hisat/hg38 -t \
            -1 ${2}/1.fq -2 ${2}/2.fq \
            -S ${3} 2>/dev/null | \
                awk -v FS=':' '$1 == "thread" && $2 ~ /time/ {print($2" "$3*60*60+$4*60+$5)}' | \
                awk '{print $NF}' | st | sed "s/^/${1} /"
    
}

# TODO: add ht-final-block-heavy and multiprocessing
for VERSION in ht-final-block ht-final-block-heavy ; do

    echo "#   Aligning ${VERSION}"
    for ind in ${INPUT_01OST} ${INPUT_STORAGE} ; do
        for outd in /dev/null ${INPUT_01OST}/out.sam ${INPUT_STORAGE}/out.sam ; do
            echo "Input: ${ind} output: ${outd}"
            for i in `seq 1 ${NTRIALS}` ; do
                align "${VERSION}" "${ind}" "${outd}"
            done
        done
    done

done
