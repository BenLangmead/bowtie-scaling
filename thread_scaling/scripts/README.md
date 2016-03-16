The `master.py` script and the companion `master_config.tsv` file together make it simple to drive a whole series of experiments.
Type `python master.py --help` for more information about how to run `master.py`.

The only preliminary work required is to:

* Download the hg19 index (ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/hg19.zip) and set `BT2_INDEX` environment variable to point to the directory containing the index.  For example, if the index is in `/path/to/index/hg19.*`, then set `export BT2_INDEX=/path/to/index`.
* Set the `BT2_READS` environment variable to point to the `seqs_by_100.fq` file from the archive.  So if the archive was expanded in `/path/to/archive`, then set `export BT2_READS=/path/to/archive/thread_scaling/scripts/experiments/seqs_by_100.fq`.

Example invocation of `master.py`:

```
python master.py \
    --index $BT2_INDEX/hg19 \
    --reads $BT2_READS \
    --nthread-pct 1,5,10,20,30,40,50,60,70,80,90,95,100 \
    --output-dir out \
    --config master_config.tsv \
    --delete-sam
```

Use the `--dry-run` parameter if you want the script to do all the set up but *not* actually run the `bowtie2` commands.
This is useful for the case where you would like to wrap the `bowtie2` commands somehow, e.g. so that they can be profiled with VTune.
The commands themselves will still dump the desired output in the right places.

When you've done a complete set of runs, all the relevant output will be in the `--output-dir` directory.
If you wrapped the `bowtie2` commands with VTune or similar, then the relevant output is wherever you decided to put it.
But, altogether, the results in `--output-dir` and the profiling results are all the results we care about.
Note that we don't care about the SAM output from `bowtie2`.
