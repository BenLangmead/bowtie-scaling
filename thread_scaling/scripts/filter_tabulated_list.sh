#!/bin/bash

#basic locks (no batch variations)
egrep -v -e '-batch.*-' $1 | egrep -v -e '-bbatch.*-' | egrep -v -e '-cleanparse-' > ${1}.locks

#parsing (batch variations)
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.parsing
egrep -e 'batch' $1 | egrep -v -e 'heavy' | egrep -v -e 'spin' | egrep -v -e 'tt' >> ${1}.parsing

#baseline
echo 'experiment	run	tool	lock	version	sensitivity	paired	threads	seconds' > ${1}.baseline
egrep -e 'tinythreads fast_mutex' $1 | egrep -v -e '-batch.*-' | egrep -v -e 'cleanparse' >> ${1}.baseline
#egrep -e 'MP-MT' $1 >> ${1}.baseline
