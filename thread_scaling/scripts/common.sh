#!/bin/bash

set -ex

if ! which git ; then
    module load git
fi
! which git && echo "No git in PATH" && exit 1

[ -z "$1" ] && echo "Specify tool shortname as first arg" && exit 1
[ -z "$2" ] && echo "Specify system as second arg" && exit 1
[ -z "$3" ] && echo "Specify unp or pe as third arg" && exit 1

TOOL_SHORT=$1
SYSTEM=$2
PE=$3
REF=hg38

[ "${PE}" != "unp" -a "${PE}" != "pe" ] && echo "Third arg must be unp or pe" && exit 1

d=`dirname $0`
pushd $d
[ ! -f "${SYSTEM}/thread_series.txt" ] && echo "No thread_series.txt file for system ${SYSTEM}" && exit 1


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
    TOOL_UNP_READS=500000
    TOOL_PAIRED_READS=500000
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

CONFIG=${TOOL_SHORT}.tsv
[ ! -f "${CONFIG}" ] && echo "No such config file: \"${CONFIG}\"" && exit 1

#
# Paired
#
if [ "${PE}" = "pe" ] ; then
    python master.py \
        --repo "${REPO}" \
        --reads-per-thread ${TOOL_PAIRED_READS} \
        --index "${TS_INDEXES}/${TOOL}/${REF}" \
        --m1 `normalize ${RURL_1}` --m2 `normalize ${RURL_2}` \
        --m1b `normalize ${RURL_B_1}` --m2b `normalize ${RURL_B_2}` \
        --input-block-bytes 12288 \
        --input-reads-per-block 44 \
        --sam-dev-null \
        --tempdir /tmp \
        --output-dir "${SYSTEM}/results/${TOOL_SHORT}" \
        --build-dir "${SYSTEM}/build-pe/${TOOL_SHORT}" \
        --nthread-series `cat ${SYSTEM}/thread_series.txt` \
        --config "${CONFIG}"
fi

#
# Unpaired
#
if [ "${PE}" = "unp" ] ; then
    python master.py \
        --repo "${REPO}" \
        --reads-per-thread ${TOOL_UNP_READS} \
        --index "${TS_INDEXES}/${TOOL}/${REF}" \
        --m1 `normalize ${RURL_1}` \
        --m1b `normalize ${RURL_B_1}` \
        --input-block-bytes 12288 \
        --input-reads-per-block 44 \
        --sam-dev-null \
        --tempdir /tmp \
        --output-dir "${SYSTEM}/results/${TOOL_SHORT}" \
        --build-dir "${SYSTEM}/build-unp/${TOOL_SHORT}" \
        --nthread-series `cat ${SYSTEM}/thread_series.txt` \
        --config "${CONFIG}"
fi

popd
