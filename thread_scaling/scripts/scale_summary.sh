#!/bin/sh

python scale_summary.py --in b2_scale_data/no_io_* --ignore-above 24 --scatter thread_times_no_IO.tsv --min-max-avg min_max_avg_no_IO.tsv
python scale_summary.py --in b2_scale_data/no_in_* --ignore-above 24 --scatter thread_times_no_I.tsv --min-max-avg min_max_avg_no_I.tsv
python scale_summary.py --in b2_scale_data/normal_* --ignore-above 24 --scatter thread_times_default.tsv --min-max-avg min_max_avg_default.tsv
