#!/bin/sh

#$1: path to local FS
#$2: filename of original input file
#$3: # of reads per thread
#$4: # of procs

#T=272
#N=17
T=16
D2="/home1/04620/cwilks/work/data/"
D="/tmp"
F="ERR050082_1.fastq.shuffled2_extended.fq.block"
F2="ERR050082_2.fastq.shuffled2.fq.block"
#TOOL="build/hisat-batch32-tbb-q-tbbd-out32-p-s/hisat-align-s"
TOOL="build/hisat-tt/hisat-align-s"
#OUTDIR='hisat_mp_mt_tt'
OUTDIR=$1

#for T in 17 34 51 68 85 102 119 136 153 170 187 204 221 238 255 272
for N in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17
do
	R=24000
	tpp=$T
	rpp=$((${tpp} * ${R}))
	echo $tpp $rpp
	cat $D2/$F | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	perl -e '$N='${N}'; $rpt='${R}'; $T='${T}'; $tpp=$T; $rpp=$rpt*$tpp; $tt=$tpp*$N; for $i (1..$N) {  $p=fork(); if($p==0) { $outf="'${OUTDIR}'1_".$tt."_".$rpp."_$i"; print "$tt $tpp $rpp $i $T $N $rpt\n"; `'${TOOL}' -p $tpp -u $rpp --sensitive -S /dev/null -x /dev/shm/hg19_hisat -U '${D}'/err.$i.mt -t --no-spliced-alignment --no-temp-splicesite --mm 2> '${OUTDIR}'/$outf.err | sort > '${OUTDIR}'/$outf`; exit(0); }} wait();'

	sleep 5

	R=20000
	rpp=$((${tpp} * ${R}))
	rpp2=$((${rpp} / 2))
	echo $tpp $rpp $rpp2
	cat $D2/$F | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp2}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	cat $D2/$F2 | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt2"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp2}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt2"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	perl -e '$N='${N}'; $rpt='${R}'; $T='${T}'; $tpp=$T; $rpp=$rpt*$tpp/2; $tt=$tpp*$N; for $i (1..$N) {  $p=fork(); if($p==0) { $outf="'${OUTDIR}'2_".$tt."_".$rpp."_$i"; print "$tt $tpp $rpp $i $T $N $rpt\n"; `'${TOOL}' -p $tpp -u $rpp --sensitive -S /dev/null -x /dev/shm/hg19_hisat -1 '${D}'/err.$i.mt -2 '${D}'/err.$i.mt2 -t --no-spliced-alignment --no-temp-splicesite --mm 2> '${OUTDIR}'/$outf.err | sort > '${OUTDIR}'/$outf`; exit(0); }} wait();'
	
	sleep 5
done
