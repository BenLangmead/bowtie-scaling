#!/bin/sh

#$1: path to local FS
#$2: filename of original input file
#$3: # of reads per thread
#$4: # of procs

#T=272
N=4
D2="/local"
D="/local"
F="ERR050082_1.fastq.shuffled2_extended.fq.block"
F2="ERR050082_2.fastq.shuffled2.fq.block"
#TOOL="build/bt-batch32-cleanparse-tbbpin-q-out32-td/bowtie-align-s"
TOOL="build/bt-tt/bowtie-align-s"
OUTDIR='bt1_mp_mt_tt'

for T in 4,8,16,20,28,36,44,56,68,76,84,92,100,104,108
#for T in 4,20
do
	R=450000
	tpp=$((${T} / ${N}))
	rpp=$((${tpp} * ${R}))
	echo $tpp $rpp
	cat $D2/$F | awk -f shorten.awk | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	perl -e '$N='${N}'; $rpt='${R}'; $T='${T}'; $tpp=$T/$N; $rpp=$rpt*$tpp; for $i (1..$N) {  $p=fork(); if($p==0) { $outf="'${OUTDIR}'1_".$tpp."_".$rpp."_$i"; print "$tpp $rpp $i $T $N $rpt\n"; `'${TOOL}' -p $tpp -u $rpp /storage/indexes/hg19 '${D}'/err.$i.mt /dev/null -t -S -I 250 -X 800  --mm 2> '${OUTDIR}'/$outf.err | sort > '${OUTDIR}'/$outf`; exit(0); }} wait();'


	sleep 5

	R=180000
	rpp=$((${tpp} * ${R}))
	rpp2=$((${rpp} / 2))
	echo $tpp $rpp
	cat $D2/$F | awk -f shorten.awk | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp2}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	cat $D2/$F2 | awk -f shorten.awk | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt2"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp2}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt2"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	perl -e '$N='${N}'; $rpt='${R}'; $T='${T}'; $tpp=$T/$N; $rpp=$rpt*$tpp/2; for $i (1..$N) {  $p=fork(); if($p==0) { $outf="'${OUTDIR}'2_".$tpp."_".$rpp."_$i"; print "$tpp $rpp $i $T $N $rpt\n"; `'${TOOL}' -p $tpp -u $rpp /storage/indexes/hg19 -1 '${D}'/err.$i.mt -2 '${D}'/err.$i.mt2 /dev/null -t -S -I 250 -X 800  --mm 2> '${OUTDIR}'/$outf.err | sort > '${OUTDIR}'/$outf`; exit(0); }} wait();'
	
	sleep 5
done
