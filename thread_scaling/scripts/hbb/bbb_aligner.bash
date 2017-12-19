#!/bin/bash

set -e

if [[ $# -lt 1 ]]; then
    echo "$0 bowtie|bowtie2|hisat|hisat2|bwa [branch]"
    exit 1
fi

version=$1
branch=$2
name=$3

shift 3

source /hbb_exe/activate

set -x

if [[ $version == "bwa" ]] ; then
    ver=0.7.17
    arc=bwa-${ver}.tar.bz2
    curl -OL https://github.com/lh3/bwa/releases/download/v${ver}/${arc}
    tar xvfj ${arc}
    pushd bwa-${ver}
    sed -e 's/CFLAGS=/CFLAGS=\$(LDFLAGS)/' -i'' Makefile
    make
    bin=bwa
    libcheck ${bin}
else
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
    sed -e 's/\$(EXTRA_FLAGS)/\$(EXTRA_FLAGS) \$(LDFLAGS)/' \
	-e s/tbbmalloc_proxy/tbbmalloc/g -i'' Makefile

    bin=${version}-align-s
    make $* ${bin}
    libcheck ${bin}
    ${bin} --version 2>&1 | tee /io/${nm}.version
fi

nm=${bin}-${name}
cp ${bin} /io/${nm}

popd
