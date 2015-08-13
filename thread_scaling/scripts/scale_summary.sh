#!/bin/sh

echo "Warning: # CPUs is hard coded in here"

python scale_summary.py --in b2_scale_data/no_io_* --ignore-above 24 --scatter thread_times_no_IO.tsv --min-max-avg min_max_avg_no_IO.tsv
python scale_summary.py --in b2_scale_data/no_in_* --ignore-above 24 --scatter thread_times_no_I.tsv --min-max-avg min_max_avg_no_I.tsv
python scale_summary.py --in b2_scale_data/normal_* --ignore-above 24 --scatter thread_times_default.tsv --min-max-avg min_max_avg_default.tsv

python scale_summary.py \
    --in scale_data_c4_8xlarge/no_io_* \
    --ignore-above 36 \
    --scatter c4_8xlarge_thread_times_no_IO.tsv \
    --min-max-avg c4_8xlarge_min_max_avg_no_IO.tsv
python scale_summary.py \
    --in scale_data_c4_8xlarge/no_in_* \
    --ignore-above 36 \
    --scatter c4_8xlarge_thread_times_no_I.tsv \
    --min-max-avg c4_8xlarge_min_max_avg_no_I.tsv
python scale_summary.py \
    --in scale_data_c4_8xlarge/normal_* \
    --ignore-above 36 \
    --scatter c4_8xlarge_thread_times_default.tsv \
    --min-max-avg c4_8xlarge_min_max_avg_default.tsv
