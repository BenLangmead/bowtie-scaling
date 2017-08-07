#!/usr/bin/env bash

normalize() {
    TMP=`basename $1`
    echo `echo $TMP | sed 's/\.gz$//'`
}

for READLEN in 50 100 ; do
    RURL_1="http://www.cs.jhu.edu/~langmea/resources/mix${READLEN}_1.fq.gz"
    RURL_2="http://www.cs.jhu.edu/~langmea/resources/mix${READLEN}_2.fq.gz"
    RURL_B_1="http://www.cs.jhu.edu/~langmea/resources/mix${READLEN}_block_1.fq.gz"
    RURL_B_2="http://www.cs.jhu.edu/~langmea/resources/mix${READLEN}_block_2.fq.gz"

    # Download reads to temp dir
    for RD in $RURL_1 $RURL_2 $RURL_B_1 $RURL_B_2 ; do
        FN=`normalize ${RD}`
        if [ ! -f "${FN}" ] ; then
            curl -O -J -L ${RD}
            gunzip `basename $RD`
        fi
        [ ! -f "${FN}" ] && echo "Failed to download and unzip" && exit 1
    done
done
