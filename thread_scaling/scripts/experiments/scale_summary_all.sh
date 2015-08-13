#!/bin/sh
REZ_DIR=../../../results/elephant6
RAW_DIR=$REZ_DIR/raw

python ../scale_summary.py --in $RAW_DIR/fast/normal_* --scatter $REZ_DIR/fast_normal.tsv  --min-max-avg $REZ_DIR/avg_fast_normal.tsv
python ../scale_summary.py --in $RAW_DIR/fast/no_in_* --scatter $REZ_DIR/fast_no_in.tsv  --min-max-avg $REZ_DIR/avg_fast_no_in.tsv
python ../scale_summary.py --in $RAW_DIR/fast/no_io_* --scatter $REZ_DIR/fast_no_io.tsv  --min-max-avg $REZ_DIR/avg_fast_no_io.tsv

python ../scale_summary.py --in $RAW_DIR/sensitive/normal_* --scatter $REZ_DIR/sensitive_normal.tsv  --min-max-avg $REZ_DIR/avg_sensitive_normal.tsv
python ../scale_summary.py --in $RAW_DIR/sensitive/no_in_* --scatter $REZ_DIR/sensitive_no_in.tsv  --min-max-avg $REZ_DIR/avg_sensitive_no_in.tsv
python ../scale_summary.py --in $RAW_DIR/sensitive/no_io_* --scatter $REZ_DIR/sensitive_no_io.tsv  --min-max-avg $REZ_DIR/avg_sensitive_no_io.tsv

python ../scale_summary.py --in $RAW_DIR/very-fast/normal_* --scatter $REZ_DIR/very-fast_normal.tsv  --min-max-avg $REZ_DIR/avg_very-fast_normal.tsv
python ../scale_summary.py --in $RAW_DIR/very-fast/no_in_* --scatter $REZ_DIR/very-fast_no_in.tsv  --min-max-avg $REZ_DIR/avg_very-fast_no_in.tsv
python ../scale_summary.py --in $RAW_DIR/very-fast/no_io_* --scatter $REZ_DIR/very-fast_no_io.tsv  --min-max-avg $REZ_DIR/avg_very-fast_no_io.tsv

python ../scale_summary.py --in $RAW_DIR/very-sensitive/normal_* --scatter $REZ_DIR/very-sensitive_normal.tsv  --min-max-avg $REZ_DIR/avg_very-sensitive_normal.tsv
python ../scale_summary.py --in $RAW_DIR/very-sensitive/no_in_* --scatter $REZ_DIR/very-sensitive_no_in.tsv  --min-max-avg $REZ_DIR/avg_very-sensitive_no_in.tsv
python ../scale_summary.py --in $RAW_DIR/very-sensitive/no_io_* --scatter $REZ_DIR/very-sensitive_no_io.tsv  --min-max-avg $REZ_DIR/avg_very-sensitive_no_io.tsv

