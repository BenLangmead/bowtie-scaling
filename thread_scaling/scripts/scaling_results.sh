#!/bin/sh

/usr/local/bin/R -e "rmarkdown::render('scaling_results.Rmd',output_file='scaling_results.html')"
