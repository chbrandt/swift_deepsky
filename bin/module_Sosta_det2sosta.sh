#!/usr/bin/env bash
set -u

# TODO: verify the output of 'detect', specifically if the countrates were
# estimated after 'Exposure' time from header, of the corrected exposure time.

det2sosta() {
  # FILE is the .det
  # A '.det' file example:
  ##
  # ! Field Name     : 1WHSPJ012657.2+330730
  # ! Instrument     : SWIFT XRT NONE
  # ! No of sources  : 2
  # ! Exposure (sec) : 3720.8332
  # ! Input file     : 22_33_15_sum.evt
  # ! Image zoom     : 1.0000
  # ! Back/orig-pix/s: 5.2134999E-07
  # ! Equinox        : 2000
  # ! RA  Image Center: 21.733950
  # ! Dec Image Center: 33.069150
  # ! Start Time : 2014-11-07T08:16:13.00
  # ! End Time   : 2015-06-06T20:47:54.00
  # !  #   count/s    err         pixel      Exp  RA(2000)   Dec(2000)   Err  H-Box
  # !                            x     y     corr                        rad  (sec)    prob    snr
  #     1 5.01E-02+/-4.1E-03 495.07742 584.54193 3493.07 01 26 57.166 +33 07 27.053  -1     55 0.000E+00 1.237E+01
  #     2 7.03E-03+/-1.6E-03 318.00000 464.56250 3628.29 01 27 30.363 +33 02 43.932  -1     27 0.000E+00 4.313E+00
  #
  local FILE="$1"
  local BACKFILE="$2"
  local EMIN="$3"
  local EMAX="$4"
  local EXPOFILE="$5"
  local LOGFILE="$6"
  # Independent of the band we'are processing,
  # drop the full-band detection countrates to this file:
  local CTSFILE="$7"
  local NAME="$8"
  local OUTFILE="$9"
  local SMOOTH="${10}"

  file=$(grep "^! Input" $FILE | awk '{print $NF}')
  expo=$(grep "^! Exposure" $FILE | awk '{print $NF}')
  back=$(grep "^! Back" $BACKFILE | awk '{print $NF}')

  # echo "log test_$EMIN-$EMAX.txt"
  # echo "cpd ${NAME}_sum_band${EMIN}-${EMAX}daeV.gif/gif"        >> $OUTFILE
  echo "log ./${LOGFILE#$PWD}"                                  >> $OUTFILE
  echo "read/size=800/ecol=PI/emin=${EMIN}/emax=${EMAX} $file"  >> $OUTFILE
  if [[ $SMOOTH == yes ]]
  then
    echo "smooth/wave/sigma=5/back=1.0"                           >> $OUTFILE
    echo "cpd ${NAME}_sum.smooth.band${EMIN}-${EMAX}daeV.gif/gif" >> $OUTFILE
    echo "disp"                                                   >> $OUTFILE
    echo "read/size=800/ecol=PI/emin=${EMIN}/emax=${EMAX} $file"  >> $OUTFILE
  fi
  echo "read/size=800/expo ./${EXPOFILE#$PWD}"                    >> $OUTFILE

  # Full-band countrates sub-product (CTSFILE)
  echo "#RA DEC photon_flux[cts/s] photon_flux_error[cts/s] exptime[s]" > $CTSFILE

  OLDIFS="$IFS"
  IFS=$'\n' DETECTS=($(grep -v "^!" $FILE))
  IFS="$OLDIFS"
  NUMDETECTS=${#DETECTS[@]}
  for ((i=0; i<$NUMDETECTS; i++)); do

    read -a FIELDS <<< "${DETECTS[$i]}"

    ctrate=${FIELDS[1]%%+*}
    _err=${FIELDS[1]##*+}
    errate=${_err#*-}

    expo_corr="${FIELDS[4]}"

    ra="${FIELDS[5]}:${FIELDS[6]}:${FIELDS[7]}"
    dec="${FIELDS[8]}:${FIELDS[9]}:${FIELDS[10]}"

    # Full-band countrates sub-product (CTSFILE)
    echo "$ra $dec $ctrate $errate $expo_corr" >> $CTSFILE

    # Correction to countrates, assuming they have been estimated using
    # GTI (header) exposure time.
    #ctrate=$(echo "$expo $expo_corr $ctrate" | awk '{print ($1/$2)*$3 }')
    #back=$(echo "$expo_corr $expo $back" | awk '{print ($1/$2)*$3 }')

    counts=$(echo "$ctrate $expo_corr" | awk '{print $1 * $2}')
    counts=${counts%%.*}

    xpx=${FIELDS[2]}
    ypx=${FIELDS[3]}

    eef_size=0.8
    if [ $counts -lt 100 ]; then
     eef_size=0.6
    elif [ $counts -lt 500 ]; then
     eef_size=0.7
    elif [ $counts -lt 2000 ]; then
     eef_size=0.8
    fi

    echo "sosta/xpix=${xpx}/ypix=${ypx}/back=${back}/eef_s=${eef_size}" >> $OUTFILE
  done
  echo 'exit'                                                           >> $OUTFILE
}
