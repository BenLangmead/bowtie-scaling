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
MP_LIST="1 16"
MT_MAX=256

INPUT_01OST=${SCRATCH}/fstest-01OST/${HOST}/pe
INPUT_16OST=${SCRATCH}/fstest-16OST/${HOST}/pe
SCR_DIR=${WORK}/git/bowtie-scaling/thread_scaling/scripts
INDEXES=/work/04265/benbo81/stampede2/indexes
NTRIALS=3
#VERSIONS="ht-final-block ht-final-block-heavy"
VERSIONS="ht-final-block"

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
    mp=$4
    mpm1=$((${mp} - 1))
    mt=$5
    ofs=""
    for i in `seq 0 ${mpm1}` ; do
        ii=`printf "%02d" ${i}`
        of=${output_dir}
        if [ ${of} != "/dev/null" ] ; then
            of="${output_dir}/${mp}_${ii}.sam"
            ofs="$ofs $of"
	    echo blah > ${of}
	    test -f ${of}
	    rm -f ${of}
        fi
	test -f ${input_dir}/1_${mp}_${ii}
	test -f ${input_dir}/2_${mp}_${ii}
        ${SCR_DIR}/bin/hisat-align-s-${ver} \
            -p ${mt} -I 250 -X 800 --reads-per-batch 32 \
                --block-bytes 12288 --reads-per-block 44 \
                --no-spliced-alignment --no-temp-splicesite \
                -x ${INDEXES}/hisat/hg38 -t \
                -1 ${input_dir}/1_${mp}_${ii} -2 ${input_dir}/2_${mp}_${ii} \
                -S ${of} >.fstest.sh.out.$i 2>/dev/null &
    done
    wait
    for i in `seq 0 ${mpm1}` ; do
	cat .fstest.sh.out.$i | \
	    awk -v FS=':' '$1 == "thread" && $2 ~ /time/ {print($2" "$3*60*60+$4*60+$5)}' | \
	    awk '{print $NF}' > .fstest.sh.times.$i
    done
    cat .fstest.sh.times.* | st | sed "s/^/${1} /"
    rm -f ${ofs} .fstest.sh.times.* .fstest.sh.out.*
}

for mp in ${MP_LIST} ; do

    # Input directories

    for d in "/tmp" "${INPUT_01OST}" "${INPUT_16OST}" ; do
        echo "# Copying input data"
        head -n `expr $NREADS \* 4` ${SCR_DIR}/mix100_block_1.fq | \
            split -l `expr $NREADS / $mp \* 4` -d - ${d}/1_${mp}_
        head -n `expr $NREADS \* 4` ${SCR_DIR}/mix100_block_2.fq | \
            split -l `expr $NREADS / $mp \* 4` -d - ${d}/2_${mp}_

        for VERSION in ${VERSIONS} ; do
            echo "#   Aligning ${VERSION}"
            
            # Output directories
            
            for outd in /dev/null /tmp ${INPUT_01OST} ${INPUT_16OST} ; do
                mt=`expr ${MT_MAX} / ${mp}`
                echo "Input: ${d} output: ${outd} mp: ${mp} mt: ${mt}"
                for i in `seq 1 ${NTRIALS}` ; do
                    align "${VERSION}" "${d}" "${outd}" "${mp}" "${mt}"
                done
            done
        done
        
        # Delete inputs
        rm -f ${d}/1_${mp}_* ${d}/2_${mp}_*
    done
done
