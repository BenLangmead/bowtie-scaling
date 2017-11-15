#!/bin/sh

echo "Writing 1GB file with block sizes from 512K-2GB"

echo "Stubbed out (/dev/null)"
./iotest -l `expr 512 \* 1024` -s `expr 512 \* 1024` -h `expr 2 \* 1024 \* 1024` -b 1073741824 -o /dev/null

echo "SSD out (/tmp)"
./iotest -l `expr 512 \* 1024` -s `expr 512 \* 1024` -h `expr 2 \* 1024 \* 1024` -b 1073741824 -o /tmp/test1.img

echo "Lustre out (\$SCRATCH)"
./iotest -l `expr 512 \* 1024` -s `expr 512 \* 1024` -h `expr 2 \* 1024 \* 1024` -b 1073741824 -o /scratch/04265/benbo81/ost1/test1.img
