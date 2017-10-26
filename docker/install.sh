#!/usr/bin/env bash

source_create(){
  local HERE=$(cd `dirname $BASH_SOURCE`; pwd)
  
  source ${HERE}/bin/create_heabins.sh
  
  echo "Run the following line to make docker-heasoft binaries available"
  echo "on your environment:"
  echo "#----------"
  echo "export PATH=\"${HERE}/bin/links:\$PATH\""
  echo "#----------"
}
source_create

