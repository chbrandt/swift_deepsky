#!/usr/bin/env bash
for f in `cat heasoft_binaries.txt`; do
  [[ -h $f ]] && rm $f
done
