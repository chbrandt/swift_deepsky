#!/usr/bin/env bash

source_create(){
  local HERE=$(cd `dirname $BASH_SOURCE`; pwd)

  source ${HERE}/bin/create_links.sh

  echo "#=================================================================="
  echo "# Run the following line to make docker-heasoft binaries available"
  echo "# on your environment:"
  echo "#----------"
  echo "export PATH=\"${HERE}/bin/links:\$PATH\""
  echo "#----------"
  echo "#=================================================================="
}
source_create
