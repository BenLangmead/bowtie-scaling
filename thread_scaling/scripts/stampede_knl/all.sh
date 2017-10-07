#!/bin/sh

for i in bt*.sh ht*.sh ; do 
    echo $i
    sbatch $i
done
