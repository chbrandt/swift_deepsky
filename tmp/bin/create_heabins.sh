#!/usr/bin/env bash
for bin in `cat heasoft_binaries.txt`; do
  ln -s _headocker.sh $bin
done
