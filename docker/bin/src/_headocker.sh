#!/usr/bin/env bash
binlink=$(basename ${BASH_SOURCE})
VERSION="${HEASOFT_VERSION:-latest}"
docker run --rm -v $PWD:/work chbrandt/heasoft:$VERSION $binlink "$@"
