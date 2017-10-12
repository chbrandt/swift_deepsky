#!/usr/bin/env bash
binlink=$(basename ${BASH_SOURCE})
docker run --rm -v $PWD:/work chbrandt/heasoft $binlink "$@"
