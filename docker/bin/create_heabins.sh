#!/usr/bin/env bash

create_links(){
  local HERE=$(cd `dirname $BASH_SOURCE`; pwd)
  
  local LINKS=${HERE}/links 
  [[ -d $LINKS ]] || mkdir $LINKS
  
  for bin in `cat ${HERE}/heasoft_binaries.txt`; do
    ln -s ${HERE}/_headocker.sh ${LINKS}/$bin
  done
}
create_links
