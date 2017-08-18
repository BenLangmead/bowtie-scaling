#!/bin/sh

for i in bt*.sh bwa*.sh ht*.sh ; do
    sh "${i}" 2>&1 | tee ".${i}.out"
done
