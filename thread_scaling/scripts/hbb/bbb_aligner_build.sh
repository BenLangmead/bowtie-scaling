#!/bin/sh

version=$1
echo "Version is ${version}"

if [ ! -d ${version}-orig ] ; then
    git clone https://github.com/BenLangmead/$version.git -- ${version}-orig
fi

docker run -t -i --rm -v `pwd`:/io \
    benlangmead/bbb:latest \
    /hbb_exe_gc_hardened/activate-exec bash \
    /io/bbb_aligner.bash $*
