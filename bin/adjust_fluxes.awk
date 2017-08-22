#!/usr/bin/env awk

BEGIN{
  print "[FULL]cts/s err [full_sosta]CTS ERR [SOFT]cts/s err [soft_sosta]CTS ERR UL_soft [HARD]cts/s err [hard_sosta]CTS ERR UL_hard"
}
{
  det_cts=$1;
  det_err=$2;

  cts_full=$3;
  err_full=$4;
  cts_soft=$8;
  err_soft=$9;
  ul_soft=$10;
  cts_hard=$13;
  err_hard=$14;
  ul_hard=$15;

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

  printf "%.3E %.3E %.3E %.3E %.3E %.3E %.3E %.3E %.3E %.3E %.3E %.3E %.3E %.3E\n",det_cts,det_err,cts_full,err_full,corr_soft,corr_soft_err,cts_soft,err_soft,ul_soft,corr_hard,corr_hard_err,cts_hard,err_hard,ul_hard
}
