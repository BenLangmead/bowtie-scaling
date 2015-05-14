#!/bin/bash

if [[ $# < 1 ]]; then
  echo -e "Quick way to compute the time mean value per thread.\n"
  echo -e "\t$0 [ data_file_prefix ] \n\n"
  echo " [ data_file_prefix ] is mandatory. The data for each bowtie2 run gets stored"
  echo "into [name][threads number].out filename. These are files where each line stores"
  echo "a tread timing report. [threads number] will reflect the number of threads bowtie2"
  echo "is run as given by parameter -p. Full path name can be used."
  echo -e "\nExample:\n"
  echo -e "\t$0 /home/runs/experiment_\n"
  echo "This looks into /home/run directory for files like experiment_[n].out and will"
  echo "output median timing for each run."
  exit 0
fi

file_templ=$1

sec_delta=$(date +"%s" -d "00:00:00")

for fs in $(ls -1 ${file_templ}*); do
  fname=${fs##*/}
  fname_only=${fname%%.*}
  threads=${fname_only##*_}
  total_duration=0

  for th_time in $(cat $fs | cut -d ' ' -f4); do
    sec_th=$(date +"%s" -d "$th_time")
    ((th_duration=sec_th-sec_delta))
    ((total_duration+=th_duration))
  done
  echo  "$threads,"$((total_duration/threads))
done

