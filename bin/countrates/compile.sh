#!/usr/bin/env bash
gfortran -Wall -fno-second-underscore -fcommon -ffixed-line-length-160 -o countrates countrates.f mylib.f
