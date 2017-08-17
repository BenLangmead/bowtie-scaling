#!/bin/sh

for i in *.sh ; do
    sh "${i}" > ".${i}.out" 2> ".${i}.err"
done
