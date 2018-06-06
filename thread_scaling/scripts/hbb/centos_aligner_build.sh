#!/bin/sh

version=$1
echo "Version is ${version}"

if [ ! -d ${version}-orig ] ; then
    git clone https://github.com/BenLangmead/$version.git -- ${version}-orig
fi

docker run -t -i --rm -v `pwd`:/io \
    benlangmead/bowtie-dev-centos7 \
    /io/centos_aligner.bash $*
