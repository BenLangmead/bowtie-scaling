#!/bin/bash
#takes a pair of files with read mates in them and randomly shuffles the reads while keeping the mates in position
cat $1 | perl -ne "BEGIN {open(IN,'<$2');}"'chomp; $s=$_; $s2=<IN>; chomp($s2); if(($i % 4)==0) { print "\n" if($i>0); print "$s~~~$s2"; $i++; next; } print "\t$s~~~$s2"; $i++; END{close(IN);}' | shuf | perl -ne "BEGIN {open(OUT,'>$2.shuffled2.fq');}"'chomp; $s=$_; @s3=split(/\t/,$s); for $s (@s3) { ($s1,$s2)=split(/~~~/,$s); print "$s1\n"; print OUT "$s2\n"; } END{close(OUT);}' >$1.shuffled2.fq

#need to figure out how to shuffle in tandem the extended file
#cat $3 | perl -ne '$s=_; chomp($s); if(($i % 4)==0) { print "\n" if($i>0); print "$s"; $i++; next; } print "\t$s"; $i++; END{close(IN);}' | shuf | >$3.shuffled2.fq

#now pad the name field out as long as the length of the sequence for both mates
cat $1.shuffled2.fq | perl -ne 'chomp; $s=$_; if($s=~/^\@ERR.* /) { $p=$s; next; } if($p) { $pl=length($p); $sl=length($s); $d=$sl-$pl; $p1=$p.(" " x $d); print "$p1\n$s\n"; $p=undef; next;} print "$s\n";' > $1.shuffled2.fq.block

cat $2.shuffled2.fq | perl -ne 'chomp; $s=$_; if($s=~/^\@ERR.* /) { $p=$s; next; } if($p) { $pl=length($p); $sl=length($s); $d=$sl-$pl; $p1=$p.(" " x $d); print "$p1\n$s\n"; $p=undef; next;} print "$s\n";' > $2.shuffled2.fq.block
