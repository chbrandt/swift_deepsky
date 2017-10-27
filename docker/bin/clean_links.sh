#!/usr/bin/env bash

HERE=$(cd `dirname $BASH_SOURCE`; pwd)
HSRC=${HERE}/src

for f in `cat ${HSRC}/heasoft_binaries.txt`; do
  [[ -h ${HERE}/links/$f ]] && rm ${HERE}/links/$f
done
rmdir ${HERE}/links 

