#!/usr/bin/env bash

create_links(){
  local HERE=$(cd `dirname $BASH_SOURCE`; pwd)
  local HSRC=${HERE}/src
  local LINKS=${HERE}/links 
  [[ -d $LINKS ]] || mkdir $LINKS
  
  for bin in `cat ${HSRC}/heasoft_binaries.txt`; do
    ln -s ${HSRC}/_headocker.sh ${LINKS}/$bin
  done
}
create_links

