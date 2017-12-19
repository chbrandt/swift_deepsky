#!/usr/bin/env bash

compile(){
  local HERE=$(cd `dirname $BASH_SOURCE`; pwd)
  (
    cd $HERE
    gfortran -Wall -fno-second-underscore -fcommon -ffixed-line-length-160 \
            -o conv2sedfile conv2sedfile.f countrates/mylib.f
  )
}
compile
