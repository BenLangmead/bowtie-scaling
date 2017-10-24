## Scaling read aligners to hundreds of threads on general-purpose processors

This repository contains scripts used to drive the experiments and compile the figures and tables for the manuscript "Scaling read aligners to hundreds of threads on general-purpose processors."  All relevant scripts are in the `thread_scaling/scripts` subdirectory.

### Generating reads

Links for downloading the reads are in Supplementary Note 2.  The process of generating the reads involves downloading the source read files, sampling 100M reads from each, and randomizing the overall order of the reads.

The scripts we used to generate these shuffled samples are in:

* `reads.py`

The scripts use to submit SLURM jobs to run this script releatedly and then concatenate the results are in: 

* `reads.sh`
* `reads_cat.sh`

Read file sizes were measured with `ls -l` and these are reported in Supplementary Table 2.

### Thread scaling experiments

Running times for all thread counts and for every combinations of (a) configuration (aligner and arguments), (b) system (KNL or Broadwell), and (c) paired-end status were performed and results are shown in Figures 3-5, Tables 2-4 and Supplementary Figures 1-3.  Important scripts driving this process are:

* `master.py` master script for driving one or more configurations through a complete series of tests.  Handles building the various configurations with appropriate preprocessor macros.  Also handles preparing the read files for each run, conducting the runs, running `top` and/or `iostat` in the background during runs to collect system measurements, and killing runs when the time limit is exceeded. 
* `stampede_knl/*.sh` SLURM scripts for driving all the KNL-based configurations.  These scripts depend on and invote `common.sh`.
* `marcc_lbm/*.sh` SLURM scripts for driving all the Broadwell-based configurations.  These scripts depend on and invote `common.sh`.

Important configuration files governing these experiments are in `.tsv` files.  Each line of each file defines the repository, tag, preprocessor macros, aligner command-line arguments, and multithreading/multiprocessing balances to use for a configuration.  Specifically: 

* `bt_base.tsv` defines the configurations for the Bowtie lock-type experiments described in Figure 3/Table 2.
* `bt.tsv` defines the configurations for all other Bowtie experiments, as described in Figures 4 and 5 and Tables 3 and 4.
* `bt2_base.tsv` like `bt_base.tsv` but for Bowtie 2.
* `bt2.tsv` like `bt.tsv` but for Bowtie 2.
* `ht_base.tsv` like `bt_base.tsv` but for HISAT.
* `ht.tsv` like `bt.tsv` but for HISAT.
* `bwa.tsv` defines the configurations for the BWA-MEM experiments described in Figure 5/Table 4.

These configurations are also described in Supplementary Note 1.

The thread count series used in the experiments are in:

* `marcc_lbm/thread_series.txt` for all Broadwell series
* `stampede_knl/thread_series.txt` for all KNL series

### Tabulating and plotting running time versus thread count

The KNL and Broadwell experiments write results to the `stampede_knl/results` and `marcc_lbm/results` subdirectories.  These are tabulated into CSV files using the script:

* `tabulate.py`

These scripts are then used as inputs to the `scaling_results.Rmd` R Markdown notebook.  We then run the R Markdown notebook to generate all the thread scaling plots.  The find the code for generating these plots, look in the following named code blocks in `scaling_results.Rmd`:

* `baseline_plots_all`
* `baseline_plots_all_unp`
* `baseline_plots_all_pe`
* `parsing_plots_all`
* `parsing_plots_all_unp`
* `parsing_plots_all_pe`
* `final_plots_all`
* `final_plots_all_unp`
* `final_plots_all_pe`

### Tabulating peak throughputs

Using the same data used to generate Tables 2-4 and Supplementary Tables 1-3, we used the `peak_throughput_table` code block in the `thread_scaling/scripts/scaling_results.Rmd` R Markdown notebook to compile a master table giving the peak throughput for every combination of configuration, system and paired-end status.

### Measuring peak memory footprint

Since `top` is run in the background during thread scaling experiments, we can parse the `top` log to find the peak resident set size, as plotted in Supplementary Figure 4.  The script for doing this is:

* `thread_scaling/scripts/peak_res.py`

### Reads per thread

The number of reads per thread used in each experiment as shown in Supplementary Table 1 were determined manually, with the goal of making all runs last a minute or longer.  These numbers were then coded into the scripts in the `thread_scaling/scripts/stampede_knl` for the KNL experiments and `thread_scaling/scripts/marcc_lbm` for the Broadwell experiments.

### Miscellaneous

* `check_blocked.py` sanity-checks a file with padding appropriate for L-parsing.
* `get_reads.sh` downloads all the read files at the links shown in Supplementary Note 2.  They are downloaded compressed and you will have to decompress before running the experiments.