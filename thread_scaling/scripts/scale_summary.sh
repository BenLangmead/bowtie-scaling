#!/bin/sh

python scale_summary.py --in b2_scale_data/no_IO_* --ignore-above 24 --scatter thread_times_no_IO.tsv
python scale_summary.py --in b2_scale_data/no_input_* --ignore-above 24 --scatter thread_times_no_I.tsv
python scale_summary.py --in b2_scale_data/normal_sp_* --ignore-above 24 --scatter thread_times_default.tsv
