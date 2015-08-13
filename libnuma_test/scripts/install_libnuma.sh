#!/bin/sh

# First I had to install updated versions of autoconf and automake on HHPC
# pushd $SHARED_DIR

wget ftp://oss.sgi.com/www/projects/libnuma/download/numactl-2.0.10.tar.gz
tar zxvf numactl-2.0.10.tar.gz
cd numactl-2.0.10

# make following change to configure.ac:
# #AM_SILENT_RULES([yes])
# m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

# ./autogen.sh
# ./configure
# make
# make install
