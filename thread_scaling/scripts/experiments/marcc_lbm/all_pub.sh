#!/bin/bash

#system specific vars

#local paths for storing 1) input reads 2) index 3) split-input reads (in MP and MP+MT modes)
export ROOT1=/home-1/cwilks3@jhu.edu/scratch
export ROOT2=/local
export INDEX_ROOT=/storage/indexes

#export THREAD_SERIES="1,4,8,12,16,20,24,28,32,36,40,44,48,56,60,68,76,84,92,96,100,104,108"
export THREAD_SERIES="1,4"

#READS PER THREAD settsings for each tool
export bt2_RPT_UNP=85000
export bt2_RPT_PE=120000
export hisat_RPT_UNP=330016
export hisat_RPT_PE=320000
export bt1_RPT_UNP=450000
export bt1_RPT_PE=180000

#need to have TBB libs/headers available for compilation and libs for running
export LD_LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/lib/intel64/gcc4.1:$LD_LIBRARY_PATH
export LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/lib/intel64/gcc4.1:$LIBRARY_PATH
export CPATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/include:$CPATH
export LIBS="-lpthread -ltbb -ltbbmalloc -ltbbmalloc_proxy"
module load git

#copy and set paths, same for all systems
rsync -av $ROOT1/ERR050082_1.fastq.shuffled2_extended.fq.block $ROOT2/
rsync -av $ROOT1/ERR050082_2.fastq.shuffled2.fq.block $ROOT2/
rsync -av $ROOT1/hg19* $INDEX_ROOT/

export READS_1=$ROOT2/ERR050082_1.fastq.shuffled2_extended.fq.block
export READS_2=$ROOT2/ERR050082_2.fastq.shuffled2.fq.block

for tool in hisat bt1 bt2
do
	CONFIG=${tool}_pub.tsv
	CONFIG_MP=${tool}_pub_mp.tsv

	if [ ! -d "${1}/run_mp_mt_${tool}" ]; then
		mkdir -p ${1}/run_mp_mt_${tool}
	fi

	#run MP+MT single and paired
	./experiments/marcc_lbm/run_mp_mt_${tool}.sh ${1}/run_mp_mt_${tool} > run_mp_mt_${tool}.run 2>&1
	#format and move results
	cd ${1}/run_mp_mt_${tool} && ls | perl -ne 'BEGIN { $D="../'${tool}'-tt-mp-mt";  $D=~s/bt1-/bt-/; $num_procs=4; `mkdir -p $D/sensitive/unp`; `mkdir -p $D/sensitive/pe`; }  chomp; $f=$_; next if($f=~/err/); ($a,$j1,$j2,$j3,$t,$s,$p)=split(/_/,$f); $t2=$t*$num_procs; $type="unp"; $type="pe" if($j3=~/2/); `cat $f >> $D/sensitive/$type/$t2.txt`;'
	cd ../../

	#run BWA single and paired
	if [ "$tool" == "bt2" ]; then
		./experiments/marcc_lbm/run_bwa.sh ${1} > bwa_run.run 2>&1 &
	fi

	#defaults are BT2
	eval RPT_UNP='$'${tool}_RPT_UNP
	eval RPT_PE='$'${tool}_RPT_PE
	export CMD="--U $READS_1 --m1 $READS_1 --m2 $READS_2"
	if [ "$tool" == "hisat" ]; then
		export CMD="--hisat-U $READS_1 --hisat-m1 $READS_1 --hisat-m2 $READS_2"
	fi
	if [ "$tool" == "bt1" ]; then
		export CMD="--U $READS_1 --m1 $READS_1 --m2 $READS_2 --shorten-reads"
	fi

	for paired_mode in 2 3
	do
		export RPT=$RPT_UNP
		if [ "$paired_mode" == "2" ]; then
			RPT=$RPT_PE
		fi

		for mp_mode in CONFIG 
		do
			export mode="--reads-per-thread"
			export config=$CONFIG
			if [ "$mp_mode" == "CONFIG_MP" ]; then
				export mode="--multiprocess"
				export config=$CONFIG_MP
			fi
			echo python ./master.py $mode $RPT --index $INDEX_ROOT/hg19 --hisat-index $INDEX_ROOT/hg19_hisat $CMD --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series $THREAD_SERIES --config ${config} --reads-per-batch 32 --no-no-io-reads --paired-mode $paired_mode
			python ./master.py $mode $RPT --index $INDEX_ROOT/hg19 --hisat-index $INDEX_ROOT/hg19_hisat $CMD --sensitivities s --sam-dev-null --tempdir $ROOT2 --output-dir ${1} --nthread-series $THREAD_SERIES --config ${config} --reads-per-batch 32 --no-no-io-reads --paired-mode $paired_mode
		done	
	done
done
