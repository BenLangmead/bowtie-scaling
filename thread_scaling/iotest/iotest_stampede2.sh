#!/bin/sh

# iotest -l <lo block size> -h <hi block size> -s <step size> -b <bytes> -o <output file>

echo "Writing 16GB file with block sizes from 512K-2GB"
SZ=`expr 16 \* 1024 \* 1024`
LO=`expr 512 \* 1024`
HI=`expr 2 \* 1024 \* 1024`
STEP=`expr 512 \* 1024`
IOTEST="./iotest -l ${LO} -s ${STEP} -h ${HI}"

for mp in 1 2 4 ; do

    sz_mp=`expr ${SZ} / ${mp}`

    echo "${mp} processes, ${sz_mp} bytes each"
    pids=""

    echo "  stubbed out (/dev/null)"
    for i in `seq 1 ${mp}` ; do
        ${IOTEST} -b ${sz_mp} -o /dev/null &
        pids="${pids} $!"
    done
    for pid in ${pids} ; do
        wait ${pid}
    done
    pids=""

    echo "  SSD out (/tmp)"
    for i in `seq 1 ${mp}` ; do
        ${IOTEST} -b ${sz_mp} -o "/tmp/test${i}.img" &
        pids="${pids} $!"
    done
    for pid in ${pids} ; do
        wait ${pid}
    done
    pids=""

    for ost in 1 16 ; do
        dr="/scratch/04265/benbo81/ost${ost}"
        nstripes=`lfs getstripe -c ${dr}`
        echo "  Lustre out (\$SCRATCH) (${nstripes} OST stripes)"
        for i in `seq 1 ${mp}` ; do
            ${IOTEST} -b ${sz_mp} -o "${dr}/test${i}.img" &
            pids="${pids} $!"
        done
        for pid in ${pids} ; do
            wait ${pid}
        done
        pids=""
    done
done
