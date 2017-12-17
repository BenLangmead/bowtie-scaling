#!/bin/bash

set -e

if [[ $# -lt 1 ]]; then
    echo "$0 bowtie|bowtie2|hisat|hisat2 [branch]"
    exit 1
fi

bowtie_version=$1
bowtie_branch=$2
bowtie_commit=$3
shift 3

source /hbb_exe/activate

set -x

[[ -e /io/$bowtie_version ]] && echo "Error, clone already there" && exit 1
git clone https://github.com/BenLangmead/$bowtie_version.git -- $bowtie_version
pushd $bowtie_version
[[ -n "${bowtie_commit}" && "${bowtie_commit}" != "NA" ]] && git reset --hard "${bowtie_commit}"
makefile_var="LIBS"
if [[ $bowtie_version == "bowtie" ]]; then makefile_var=EXTRA_FLAGS; fi
if [[ ! -z $bowtie_branch ]]; then git checkout $bowtie_branch; fi
sed -e "/^${makefile_var}/s/${makefile_var} =\(.*\)/${makefile_var} = $\(LDFLAGS\) \1/"\
    -e s/tbbmalloc_proxy/tbbmalloc/g -i'' Makefile
cp -r ../$bowtie_version /io

make EXTRA_ARGS="$*" ${bowtie_version}-`[ $bowtie_version == "bowtie2" ] && echo "pkg" || echo "bin.zip"`
libcheck ${bowtie_version}-{align,build,inspect}-*
cp *.zip /io
rm -rf /io/$bowtie_version
