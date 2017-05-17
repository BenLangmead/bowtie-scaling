#!/bin/bash
#filter original complete set of thread-scaling results into 3 plots (each with the aligners): baseline, parsing, and final

#baseline: TT, TBB locks, MP, MP+MT (TTthreads) (no batch variations)
egrep -v -e '-batch.*-' $1 | egrep -v -e '-bbatch.*-' | egrep -v -e '-cleanparse-' | egrep -v -e 'bwa' > ${1}.baseline.tsv

#parsing with just queuelock and tthreads MP (across all batch modes)
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.parsing.tsv
egrep -e 'batch' $1 | egrep -v -e 'heavy' | egrep -v -e 'spin' | egrep -v -e 'MP' | egrep -v -e 'tt' | egrep -v -e 'TBB queuing_mutex MP' >> ${1}.parsing
egrep -e 'queuing' ${1}.parsing | egrep "Stack" >> ${1}.parsing.tsv
egrep -e 'TBB queuing_mutex' ${1} | egrep -e 'Original parsing' >> ${1}.parsing.tsv
rm ${1}.parsing

#final: Queuing Batch=32 (in/out) Stack/mem, Queuing Batch=32 (in/out) Stack/mem w Fixed, MP, MP+MT, BWA (BT2)
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.final.tsv
egrep -e 'TBB queuing_mutex' $1 | egrep -e 'Batch parsing input=32 & output=32' | egrep -e 'Stack' | egrep -v -e 'MP' >> ${1}.final.tsv
#includes MP+MT
grep "MP" $1 | egrep -e 'Original parsing' >> ${1}.final.tsv
egrep -e 'bwa' $1 >> ${1}.final.tsv
