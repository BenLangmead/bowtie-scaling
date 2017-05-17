#!/bin/bash

#basic locks (no batch variations)
egrep -v -e '-batch.*-' $1 | egrep -v -e '-bbatch.*-' | egrep -v -e '-cleanparse-' > ${1}.locks

#parsing full
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.parsing
egrep -e 'batch' $1 | egrep -v -e 'heavy' | egrep -v -e 'spin' | egrep -v -e 'tt' | egrep -v -e 'TBB queuing_mutex MP' >> ${1}.parsing

#Bowtie2 vs. BWA
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.bwa
egrep -e 'bwa' $1 >> ${1}.bwa
egrep -e 'input=32 & output=32' $1 | egrep -e 'queuing' | egrep -e 'bowtie2' | egrep -v -e 'MP' >> ${1}.bwa

#memory
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.mem
egrep -e '-batch-tbb-q-id	' $1 >> ${1}.mem
egrep -e 'TBB queuing_mutex' $1 | egrep -e 'Stack' | egrep -e 'Batch parsing input=32 & output=32' | egrep -v -e 'MP' | egrep -v -e 'Fixed' >> ${1}.mem


#parsing for just queuelock and tthreads MP
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.qlock_parsing
egrep -e 'queuing' ${1}.parsing | egrep "Large Pool Stack" >> ${1}.qlock_parsing
grep "MP" $1 | egrep -v -e 'Large Pool Stack' >> ${1}.qlock_parsing

#baseline
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.baseline
egrep -e 'tinythreads fast_mutex' $1 | egrep -v -e '-batch.*-' | egrep -v -e 'cleanparse' >> ${1}.baseline
#egrep -e 'MP-MT' $1 >> ${1}.baseline
