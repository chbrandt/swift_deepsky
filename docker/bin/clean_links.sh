#!/usr/bin/env bash
for f in `cat heasoft_binaries.txt`; do
  [[ -h links/$f ]] && rm links/$f
done
rmdir links 
