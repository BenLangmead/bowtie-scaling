# bowtie-scaling

Experiments regarding how bowtie/bowtie2 scale to many threads

## Highlights

* `results/stampede_knl` for Stampede KNL results
* `results/marcc_langmead_bigmem` for MARCC Broadwell results
* `results/pub_singleplot_results.R` has key R code for making plots
* `thread_scaling/scripts/master.py` master script for driving one series of tests
* `thread_scaling/scripts/experiments/stampede_knl/*.sh` drives different tool-specific series for Stampede KNL
* `thread_scaling/scripts/experiments/marcc_lbm/*.sh` drives different tool-specific series for MARCC Broadwell
    * toplevel scripts are `bt1_pub.sh`, `bt2_pub.sh`, `hisat_pub.sh`
* `thread_scaling/scripts/master_tabulate.py` used on the test machines to compile the big tsv
* `thread_scaling/scripts/experiments/*.tsv` give the configurations for each tool version tested

## Auxilliary

* `results/filter_result_table_for_plots.sh` splits big tsv into many little ones
