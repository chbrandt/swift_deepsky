#!/usr/bin/env awk

# This script adjust the measurements made by SOSTA; for each detected
# source it takes SOSTA's measurement ratios (e.g, soft/full, hard/full)
# and multiplies by the previously measured full-band value made by
# XImage's DETECT (which looks more reliable).
#
# The input file is like the example below:
#-----------------------------------------------------------------------


BEGIN{
  printf "#RA;DEC";
  printf ";(FULL:photon_flux[ph.s-1]);(FULL:photon_flux_error[ph.s-1])";
  printf ";(SOFT:photon_flux[ph.s-1]);(SOFT:photon_flux_error[ph.s-1]);(SOFT:upper_limit[ph.s-1])";
  printf ";(MEDIUM:photon_flux[ph.s-1]);(MEDIUM:photon_flux_error[ph.s-1]);(MEDIUM:upper_limit[ph.s-1])";
  printf ";(HARD:photon_flux[ph.s-1]);(HARD:photon_flux_error[ph.s-1]);(HARD:upper_limit[ph.s-1])";
  printf "\n";
}
{
  ra=$1;
  dec=$2;
  det_cts=$3;
  det_err=$4;

  cts_full=$5;
  err_full=$6;
  cts_soft=$10;
  err_soft=$11;
  ul_soft=$12;
  cts_medium=$15;
  err_medium=$16;
  ul_medium=$17;
  cts_hard=$20;
  err_hard=$21;
  ul_hard=$22;

  if(ul_soft == "None"){
    ul_soft = -999
    ratio_soft=cts_soft/cts_full;
    ratio_soft_err=err_soft/err_full;
  }else{
    ul_soft = ul_soft/cts_full;
    ratio_soft_err = -999;
  }
  corr_soft=det_cts*ratio_soft;
  corr_soft_err=det_err*ratio_soft_err;

  if(ul_medium == "None"){
    ul_medium = -999
    ratio_medium=cts_medium/cts_full;
    ratio_medium_err=err_medium/err_full;
  }else{
    ul_medium = ul_medium/cts_full;
    ratio_medium_err = -999;
  }
  corr_medium=det_cts*ratio_medium;
  corr_medium_err=det_err*ratio_medium_err;

  if(ul_hard == "None"){
    ul_hard = -999
    ratio_hard=cts_hard/cts_full;
    ratio_hard_err=err_hard/err_full;
  }else{
    ul_hard = ul_hard/cts_full;
    ratio_hard_err = -999;
  }
  corr_hard=det_cts*ratio_hard;
  corr_hard_err=det_err*ratio_hard_err;

  printf "%s;%s",ra,dec;
  printf ";%.3E;%.3E",det_cts,det_err;
  printf ";%.3E;%.3E;%.3E",corr_soft,corr_soft_err,ul_soft;
  printf ";%.3E;%.3E;%.3E",corr_medium,corr_medium_err,ul_medium;
  printf ";%.3E;%.3E;%.3E",corr_hard,corr_hard_err,ul_hard;
  printf "\n";
}
