#!/bin/sh

cat >.columns.txt <<EOF
UserSecs
SystemSecs
Utilization
WallClock
AvgShrText
AvgUnshareData
AvgStack
AvgTotal
MaxRes
AvgRes
MajorPageFaults
MinorPageFaults
VolSwitches
InvolSwitches
Swaps
Inputs
Outputs
SockSent
SockRecv
SigsDelivered
PageSize
ExitStatus
EOF

parse_strace() {
    cat $1 | awk -v OFS=',' '{print $2,$4,$NF}' | grep -v '-' | grep -v total | grep -v syscall
}

parse_strace .fstest.sh.ht-final-block.1.0.tmp.devnull.strace | sed 's/$/,mt_devnull,0/'
parse_strace .fstest.sh.ht-final-block.1.0.tmp.scratch04265benbo81fstest-01OST*.stampede2.tacc.utexas.edupe.strace | sed 's/$/,mt_lustre,0/'

for i in `seq 0 15` ; do
    parse_strace .fstest.sh.ht-final-block.16.${i}.tmp.scratch04265benbo81fstest-01OST*.stampede2.tacc.utexas.edupe.strace | sed "s/\$/,mp_lustre,$i/"
done
