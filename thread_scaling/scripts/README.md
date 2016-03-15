Scripts related to collecting, tabulating and plotting thread-scaling performance measurements.

The `master.py` script and the companion `master_config.tsv` file is an attempt at making a single master script that can drive all the key experiments.

Some examples of useful invocations of `master.py`:

```
# The experiments we're asking Intel to perform

# Assuming BT2_INDEX is set to directory containing unzipped hg19 index:
# ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/hg19.zip

# And assuming BT2_READS is set to path to the `seqs_by_100.fq` file
# e.g. if bowtie-scaling repo is cloned in /path/to/repo:
# export BT2_READS=/path/to/bowtie-scaling/thread_scaling/scripts/experiments/seqs_by_100.fq

python master.py \
    --index $BT2_INDEX/hg19 \
    --reads $BT2_READS \
    --nthread-pct 1,5,10,20,30,40,50,60,70,80,90,95,100 \
    --output-dir out \
    --config master_config.tsv
```
