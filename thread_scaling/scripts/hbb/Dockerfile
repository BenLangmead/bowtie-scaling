FROM phusion/holy-build-box-64

RUN yum -y install git zip unzip gcc g++ emacs-nox libasan wget

RUN source /hbb_exe/activate && \
    mkdir /mybin && \
    echo  'res=`echo $@ | sed "s/-L.*$//"`; echo $res; echo $res; /opt/rh/devtoolset-2/root/usr/bin/ar $res;' > /mybin/ar && \
    chmod +x /mybin/ar && export PATH=/mybin:$PATH && \
    TBB_ROOT=/io && \
    TBB_LIB=/io/lib && \
    curl -LO https://github.com/01org/tbb/archive/2017_U5.tar.gz && \
    TBB_ROOT="/`tar -tzf /2017_U5.tar.gz | head -1`" && \
    tar xzf 2017_U5.tar.gz && pushd $TBB_ROOT && make extra_inc=big_iron.inc && popd && \
    rm -f 2017_U5.tar.gz && \
    TBB_LIB=`ls -d $TBB_ROOT/build/linux*release` && \
    cp -r $TBB_ROOT/include/* /usr/local/include/ && \
    cp $TBB_LIB/*.a /usr/local/lib/ && \
    rm -rf $TBB_ROOT
