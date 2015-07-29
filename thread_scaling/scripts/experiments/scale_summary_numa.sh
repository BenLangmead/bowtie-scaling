#!/bin/sh

python scale_summary.py --in numa_runs/normal_cpu1mem1_* --ignore-above 24 --scatter tt_normal_c1m1.tsv 
python scale_summary.py --in numa_runs/normal_cpu1mem0_* --ignore-above 24 --scatter tt_normal_c1m0.tsv 
python scale_summary.py --in numa_runs/no_in_cpu1mem1_* --ignore-above 24 --scatter tt_no_in_c1m1.tsv 
python scale_summary.py --in numa_runs/no_in_cpu1mem0_* --ignore-above 24 --scatter tt_no_in_c1m0.tsv 
python scale_summary.py --in numa_runs/no_io_cpu1mem1_* --ignore-above 24 --scatter tt_no_io_c1m1.tsv 
python scale_summary.py --in numa_runs/no_io_cpu1mem0_* --ignore-above 24 --scatter tt_no_io_c1m0.tsv 
