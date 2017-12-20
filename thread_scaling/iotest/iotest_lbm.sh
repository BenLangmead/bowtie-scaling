#!/bin/sh

echo "Writing 5GB file with block sizes from 512K-2GB"
# 1GB = 1073741824
# 5GB = 5368709120
SZ=5368709120

echo "Stubbed out (/dev/null)"
./iotest -l `expr 512 \* 1024` -s `expr 512 \* 1024` -h `expr 2 \* 1024 \* 1024` -b ${SZ} -o /dev/null

echo "Temp (/tmp)"
./iotest -l `expr 512 \* 1024` -s `expr 512 \* 1024` -h `expr 2 \* 1024 \* 1024` -b ${SZ} -o /tmp/test1.img
rm -f /tmp/test1.img

echo "Disk array (/storage/bowtie-scaling/temp/iotest)"
./iotest -l `expr 512 \* 1024` -s `expr 512 \* 1024` -h `expr 2 \* 1024 \* 1024` -b ${SZ} -o /storage/bowtie-scaling/temp/iotest/test1.img
rm -f /storage/bowtie-scaling/temp/iotest/test1.img

echo "Lustre out (/scratch/groups/blangme2/bowtie-scaling-temp/iotest)"
./iotest -l `expr 512 \* 1024` -s `expr 512 \* 1024` -h `expr 2 \* 1024 \* 1024` -b ${SZ} -o /scratch/groups/blangme2/bowtie-scaling-temp/iotest/test1.img
