#!/bin/bash

set -ex

if ! which git ; then
    module load git
fi

! which git && echo "No git in PATH" && exit 1

# ','.join(map(str, sorted(set([i for i in range(12, 112+1, 12)] + [i for i in range(8, 112+1, 8)] + [1]))))
THREAD_SERIES="2,3,4,6"

TOOL_SHORT=$1
REF=hg38

if [ "${TOOL_SHORT}" = "bt2" ] ; then
    TOOL=bowtie2
    TOOL_IDX_EXT=bt2
    TOOL_UNP_READS=200000
    TOOL_PAIRED_READS=20000
    READLEN=100
elif [ "${TOOL_SHORT}" = "bt" ] ; then
    TOOL=bowtie
    TOOL_IDX_EXT=ebwt
    TOOL_UNP_READS=450000
    TOOL_PAIRED_READS=60000
    READLEN=50
elif [ "${TOOL_SHORT}" = "ht" ] ; then
    TOOL=hisat
    TOOL_IDX_EXT=bt2
    TOOL_UNP_READS=1200000
    TOOL_PAIRED_READS=600000
    READLEN=100
else
    echo "Bad tool shortname: ${TOOL_SHORT}"
    exit 1
fi

normalize() {
    TMP=`basename $1`
    echo `echo $TMP | sed 's/\.gz$//'`
}

RURL_1="http://www.cs.jhu.edu/~langmea/resources/mix${READLEN}_1.fq.gz"
RURL_2="http://www.cs.jhu.edu/~langmea/resources/mix${READLEN}_2.fq.gz"
RURL_B_1="http://www.cs.jhu.edu/~langmea/resources/mix${READLEN}_block_1.fq.gz"
RURL_B_2="http://www.cs.jhu.edu/~langmea/resources/mix${READLEN}_block_2.fq.gz"

REPO="https://github.com/BenLangmead/${TOOL}.git"

# Download reads to temp dir
for RD in $RURL_1 $RURL_2 $RURL_B_1 $RURL_B_2 ; do
    FN=`normalize ${RD}`
    if [ ! -f "${FN}" ] ; then
        curl -O -J -L ${RD}
        gunzip `basename $RD`
    fi
    [ ! -f "${FN}" ] && echo "Failed to download and unzip" && exit 1
done

if [ -z "${TS_INDEXES}" ] ; then
    echo "Set TS_INDEXES to directory containing indexes in bowtie, bowtie2 and hisat subdirectories" && exit 1
fi

[ ! -f "${TS_INDEXES}/${TOOL}/${REF}.1.${TOOL_IDX_EXT}" ] && echo "Missing index: ${TS_INDEXES}/${TOOL}/${REF}" && exit 1

BASEDIR=$(dirname "$0")
CONFIG=${BASEDIR}/../${TOOL_SHORT}.tsv
[ ! -f "${CONFIG}" ] && echo "No such config file: \"${CONFIG}\"" && exit 1

#
# Paired
#
python ${BASEDIR}/../../master.py \
    --repo "${REPO}" \
    --reads-per-thread ${TOOL_PAIRED_READS} \
    --index "${TS_INDEXES}/${TOOL}/${REF}" \
    --m1 `normalize ${RURL_1}` --m2 `normalize ${RURL_2}` \
    --m1b `normalize ${RURL_B_1}` --m2b `normalize ${RURL_B_2}` \
    --input-block-bytes 12288 \
    --input-reads-per-block 44 \
    --sam-dev-null \
    --tempdir /tmp \
    --output-dir "results/${TOOL_SHORT}" \
    --nthread-series "${THREAD_SERIES}" \
    --config "${CONFIG}"

#
# Unpaired
#
python ${BASEDIR}/../../master.py \
    --repo "${REPO}" \
    --reads-per-thread ${TOOL_UNP_READS} \
    --index "${TS_INDEXES}/${TOOL}/${REF}" \
    --m1 `normalize ${RURL_1}` \
    --m1b `normalize ${RURL_B_1}` \
    --input-block-bytes 12288 \
    --input-reads-per-block 44 \
    --sam-dev-null \
    --tempdir /tmp \
    --output-dir "results/${TOOL_SHORT}" \
    --nthread-series "${THREAD_SERIES}" \
    --config "${CONFIG}"
