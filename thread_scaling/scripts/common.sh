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
CONFIG=$2
SYSTEM=$3
PE=$4
NREADS=$5
REF=hg38

shift 5

[ "${PE}" != "unp" -a "${PE}" != "pe" ] && echo "Third arg must be unp or pe" && exit 1

d=`dirname $0`
pushd $d
[ ! -f "${SYSTEM}/thread_series.txt" ] && echo "No thread_series.txt file for system ${SYSTEM}" && exit 1
[ ! -f "${SYSTEM}/temp_dir.txt" ] && echo "No temp_dir.txt file for system ${SYSTEM}" && exit 1
[ ! -f "${CONFIG}" ] && echo "No such config file: \"${CONFIG}\"" && exit 1

THREAD_SERIES=`cat ${SYSTEM}/thread_series.txt`
TEMP=`cat ${SYSTEM}/temp_dir.txt`

READLEN=100
if [ "${TOOL_SHORT}" = "bt2" ] ; then
    TOOL=bowtie2
elif [ "${TOOL_SHORT}" = "bt" ] ; then
    TOOL=bowtie
    READLEN=50
elif [ "${TOOL_SHORT}" = "ht" ] ; then
    TOOL=hisat
elif [ "${TOOL_SHORT}" = "bwa" ] ; then
    TOOL=bwa
else
    echo "Bad tool shortname: ${TOOL_SHORT}"
    exit 1
fi

normalize() {
    TMP=`basename $1`
    echo `echo $TMP | sed 's/\.gz$//'`
}

PREF="http://www.cs.jhu.edu/~langmea/resources/mix"
RURL_1="${PREF}${READLEN}_1.fq.gz"
RURL_2="${PREF}${READLEN}_2.fq.gz"
RURL_B_1="${PREF}${READLEN}_block_1.fq.gz"
RURL_B_2="${PREF}${READLEN}_block_2.fq.gz"

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

#
# Paired
#
if [ "${PE}" = "pe" ] ; then
    python master.py \
        --repo "${REPO}" \
        --reads-per-thread ${NREADS} \
        --index "${TS_INDEXES}/${TOOL}/${REF}" \
        --m1 `normalize ${RURL_1}` --m2 `normalize ${RURL_2}` \
        --m1b `normalize ${RURL_B_1}` --m2b `normalize ${RURL_B_2}` \
        --input-block-bytes 12288 \
        --input-reads-per-block 44 \
        --sam-dev-null \
        --tempdir "${TEMP}" \
        --preproc "$*" \
        --output-dir "${SYSTEM}/results/${TOOL_SHORT}" \
        --build-dir "${SYSTEM}/build-pe/${TOOL_SHORT}" \
        --nthread-series "${THREAD_SERIES}" \
        --no-count \
        --config "${CONFIG}"
fi

#
# Unpaired
#
if [ "${PE}" = "unp" ] ; then
    python master.py \
        --repo "${REPO}" \
        --reads-per-thread ${NREADS} \
        --index "${TS_INDEXES}/${TOOL}/${REF}" \
        --m1 `normalize ${RURL_1}` \
        --m1b `normalize ${RURL_B_1}` \
        --input-block-bytes 12288 \
        --input-reads-per-block 44 \
        --sam-dev-null \
        --tempdir "${TEMP}" \
        --preproc "$*" \
        --output-dir "${SYSTEM}/results/${TOOL_SHORT}" \
        --build-dir "${SYSTEM}/build-unp/${TOOL_SHORT}" \
        --nthread-series "${THREAD_SERIES}" \
        --no-count \
        --config "${CONFIG}"
fi

popd
