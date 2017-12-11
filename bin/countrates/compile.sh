#!/usr/bin/env bash

compile(){
  local HERE=$(cd `dirname $BASH_SOURCE`; pwd)
  (
    cd $HERE
    gfortran -Wall -fno-second-underscore -fcommon -ffixed-line-length-160 \
            -o countrates countrates.f mylib.f
  )
}
compile
