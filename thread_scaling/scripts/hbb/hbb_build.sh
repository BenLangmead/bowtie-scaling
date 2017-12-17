#!/bin/sh

docker run -t -i --rm -v `pwd`:/io \
    benlangmead/bbb:latest \
    /hbb_exe_gc_hardened/activate-exec bash \
    /io/static_tbb.bash $*
