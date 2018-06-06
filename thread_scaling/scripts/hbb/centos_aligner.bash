#!/bin/bash

set -ex

DO_CLONE=0

if [[ $# -lt 1 ]]; then
    echo "$0 bowtie|bowtie2|hisat|hisat2|bwa [branch]"
    exit 1
fi

version=$1
branch=$2
name=$3

shift 3

# For the ar workaround
export PATH="/mybin:$PATH"

if [ ${DO_CLONE} = 1 ] ; then
    git clone https://github.com/BenLangmead/$version.git -- $version
else
    if [ ! -d /io/${version}-orig ] ; then
        echo "NO_CLONE is not set, so I need the ${version}-orig dir to exist for cp -r"
        exit 1
    fi
    cp -r /io/${version}-orig ${version}
fi
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
prebin=

if [[ $version == "bwa" ]] ; then
    bin=${version}
    bins="${bin}"
else
    bins="${bin} ${bin}-debug"
    prebin="static-libs"
fi

make RELEASE_BUILD=1 $* ${prebin} ${bins}

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
