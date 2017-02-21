#export LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb4.1/tbb41_20130613oss/lib/intel64/gcc4.1
#export CPATH=/home-1/cwilks3@jhu.edu/tbb4.1/tbb41_20130613oss/include
#export LIBS="-lpthread -ltbb -ltbbmalloc -ltbbmalloc_proxy"

export LIBRARY_PATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/lib/intel64/gcc4.1:$LIBRARY_PATH
export CPATH=/home-1/cwilks3@jhu.edu/tbb2017_20161128oss.bin/include:$CPATH
export LIBS="-lpthread -ltbb -ltbbmalloc -ltbbmalloc_proxy"

cut -f 1 ../$1.tsv | perl -ne 'chomp; `cd $_ ; git pull ; make clean`;'
cut -f 1,4 ../$1.tsv | perl -ne 'chomp; ($d,$c)=split(/\t/,$_); `cd $d ; make -e -j 10 $c &`;'
