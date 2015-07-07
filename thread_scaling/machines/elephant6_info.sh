#!/bin/sh

cat /proc/cpuinfo
numactl --show
numactl --hardware
uname -a
sudo dmidecode -t processor | grep HTT
