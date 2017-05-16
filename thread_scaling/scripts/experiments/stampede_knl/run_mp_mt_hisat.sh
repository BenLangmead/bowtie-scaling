#!/bin/sh

#$1: path to local FS
#$2: filename of original input file
#$3: # of reads per thread
#$4: # of procs

#T=272
N=17
D2="/home1/04620/cwilks/work/data/"
D="/tmp"
F="ERR050082_1.fastq.shuffled2.fq.block"
F2="ERR050082_2.fastq.shuffled2.fq.block"
#TOOL="build/hisat-batch32-tbb-q-tbbd-out32-p-s/hisat-align-s"
TOOL="build/hisat-tt/hisat-align-s"
OUTDIR='hisat_mp_mt_tt'

#for T in 4 12 20 28 36 44 52 60 68 76 84 92 100 108 112 120 128 136 144 152 160 168 176 184 192 200 208 216 224 232 240 248 256 264 272
for T in 17 34 51 68 85 102 119 136 153 170 187 204 221 238 255 272
do
	R=24000
	tpp=$((${T} / ${N}))
	rpp=$((${tpp} * ${R}))
	echo $tpp $rpp
	cat $D2/$F | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	perl -e '$N='${N}'; $rpt='${R}'; $T='${T}'; $tpp=$T/$N; $rpp=$rpt*$tpp; for $i (1..$N) {  $p=fork(); if($p==0) { $outf="'${OUTDIR}'1_".$tpp."_".$rpp."_$i"; print "$tpp $rpp $i $T $N $rpt\n"; `'${TOOL}' -p $tpp -u $rpp --sensitive -S /dev/null -x /dev/shm/hg19_hisat -U '${D}'/err.$i.mt -t --no-spliced-alignment --no-temp-splicesite --mm 2> '${OUTDIR}'/$outf.err | sort > '${OUTDIR}'/$outf`; exit(0); }} wait();'

	sleep 5

	R=20000
	rpp=$((${tpp} * ${R}))
	rpp2=$((${rpp} / 2))
	echo $tpp $rpp $rpp2
	cat $D2/$F | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp2}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	cat $D2/$F2 | perl -ne 'BEGIN{ open(OUT,">'${D}'/err.1.mt2"); $i=1; $c=0;} chomp; $s=$_; $c++; if($c=='${rpp2}'*4+1) { $i++; close(OUT); if($i>'${N}') {exit(0);} open(OUT,">'${D}'/err.$i.mt2"); $c=1;} print OUT "$s\n"; END { close(OUT);}'

	perl -e '$N='${N}'; $rpt='${R}'; $T='${T}'; $tpp=$T/$N; $rpp=$rpt*$tpp/2; for $i (1..$N) {  $p=fork(); if($p==0) { $outf="'${OUTDIR}'2_".$tpp."_".$rpp."_$i"; print "$tpp $rpp $i $T $N $rpt\n"; `'${TOOL}' -p $tpp -u $rpp --sensitive -S /dev/null -x /dev/shm/hg19_hisat -1 '${D}'/err.$i.mt -2 '${D}'/err.$i.mt2 -t --no-spliced-alignment --no-temp-splicesite --mm 2> '${OUTDIR}'/$outf.err | sort > '${OUTDIR}'/$outf`; exit(0); }} wait();'
	
	sleep 5
done
