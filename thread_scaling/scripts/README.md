# Original Single Run Instructions

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

# Tailored Runner Script Instructions

Currently (5/8/2017) there are two environments thread-scaling tests are run in:

* MARCC Langmead-Bigmem (112 HTx2 cores)
* Stampede KNL (272 HTx4 cores) 

Further there are 3 tools being run:

* Bowtie
* Bowtie2
* Hisat

Each environment-tool combination has its own runner script.
These will eventually be collapsed into a single script, but for
now are separate.

The runner scripts themselves live in the appropriately named
subdirectory of `thread_scaling/scripts/experiments` (`marcc_lbm` or `stampede_knl`).

The runner scripts hardcode the locations of the following:

* TBB libraries
* Index and input file paths
* Temporary (local) paths for copying indices and input files to
* Thread series (e.g. 1,4,6,...,272)
* Reads per thread per run

The runner scripts will also copy over indices and input files to
the temporary (local) paths specified if not already there (via rsync).

Each runner script has 5 invocations of the master.py script split
between single/paired and normal (MT)/multiprocess (MP) modes. 
These invocations rely on separate run config files (e.g. `bt2_pub.tsv`).

Each runner script also runs a separate script to do the MP+MT using TinyThreads run.
In addition the Bowtie2 runner script also runs BWA for single and paired modes.

The runner scripts should be run from `thread_scaling/scripts`.
Once there, the way to run any of the customized runner scripts is:

`./experiments/<environment>/runner_script.sh <output_directory> > runner.out 2> runner.err`

where `<environment>` is either `marcc_lbm` or `stampede_knl`.

Example:

`./experiments/marcc_lbm/bt2_pub.sh final_runs > bt2.run.out 2> bt2.run.err`
