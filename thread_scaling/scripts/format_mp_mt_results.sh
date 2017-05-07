#!/bin/bash
#$B=pub_baseline

for TOOL in bt1 bt2 hisat
do
	e=${TOOL}_mp_mt_tt
	cd $e && ls | perl -ne 'BEGIN { $D="../'${1}'/'${TOOL}'-tt-mp-mt";  $num_procs=17; `mkdir -p $D/sensitive/unp`; `mkdir -p $D/sensitive/pe`; }  chomp; $f=$_; next if($f=~/err/); ($a,$j1,$j2,$t,$s,$p)=split(/_/,$f); $t2=$t*$num_procs; $type="unp"; $type="pe" if($j2=~/2/); `cat $f >> $D/sensitive/$type/$t2.txt`;'
done
