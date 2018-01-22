#!/bin/bash

set -ex

if [[ $# -lt 1 ]]; then
    echo "$0 bowtie|bowtie2|hisat|hisat2|bwa [branch]"
    exit 1
fi

version=$1
branch=$2
name=$3

shift 3

source /hbb_exe/activate

git clone https://github.com/BenLangmead/$version.git -- $version
pushd $version
if [[ -n "${commit}" && "${commit}" != "NA" ]] ; then
    git reset --hard "${commit}"
else
    commit=`git log | head -n 1 | cut -d' ' -f2-`
fi
if [[ `echo -n $branch | wc -c` == 40 ]] && echo -n $branch | grep -q '^[a-z0-9]*$' ; then
    git reset --hard $branch
else
    git checkout $branch
fi
if [[ $version == "bwa" ]] ; then
    sed -e 's/CFLAGS=/CFLAGS=\$(LDFLAGS)/' -i'' Makefile
else
    sed -e 's/\$(EXTRA_FLAGS)/\$(EXTRA_FLAGS) \$(LDFLAGS)/' \
	-e s/tbbmalloc_proxy/tbbmalloc/g -i'' Makefile    
fi

bin=${version}-align-s

if [[ $version == "bwa" ]] ; then
    bin=${version}
    bins="${bin}"
else
    bins="${bin} ${bin}-debug"
fi

make -j2 $* ${bins}
for b in ${bins} ; do
    libcheck ${b}
done

if [[ $version == "bwa" ]] ; then
    ${bin} 2>&1 | tee /io/${nm}.version
else
    ${bin} --version 2>&1 | tee /io/${nm}.version
fi

for b in ${bins} ; do
    nm=${b}-${name}
    cp ${b} /io/${nm}
done

popd
