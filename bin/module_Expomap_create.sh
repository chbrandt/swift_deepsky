#!/usr/bin/env bash
set +ue

create_xrtexpomap() {
  # This function creates the exposure map from the given events file, and
  # accordingly mission support files.
  local EVENTFILE="$1"
  local TMPDIR="$2"

  local ROOTFNAME=$(basename ${EVENTFILE%xpc*})
  local DATA_ARCHIVE_OBS=${EVENTFILE%/xrt/*}

  local ATTFLAG=$(fkeyprint ${EVENTFILE}+1 ATTFLAG exact=yes \
            | grep "ATTFLAG =" | cut -d'/' -f1 | tr -d "[:blank:]" \
            | cut -d'=' -f2 | tr -c -d "[:digit:]")
  if [[ "$ATTFLAG" -eq "110" ]]; then
    #ATTFLAG = '110     '           / Attitude file: 100=sat, x10=pat, xx1=uat
    ATTFILE="${ROOTFNAME}pat.fits.gz"
  else
    #ATTFLAG = '100     '           / Attitude file: 100=sat, x10=pat, xx1=uat
    ATTFILE="${ROOTFNAME}sat.fits.gz"
  fi
  ATTFILE="${DATA_ARCHIVE_OBS}/auxil/${ATTFILE}"
  HKFILE="${DATA_ARCHIVE_OBS}/xrt/hk/${ROOTFNAME}xhd.hk.gz"

  xrtexpomap infile=${EVENTFILE} \
             attfile=${ATTFILE} \
             hdfile=${HKFILE} \
             vigflag=yes outdir="${TMPDIR}/"
}

create_xrtexpomaps() {
  # This functions gets a list of event-files (through a text file in $2) and
  # the root path for the local Swift archive.
  # This function will simply call the above 'create_xrtexpomap' function for
  # each event-file.
  local EVTFILESLIST="$1"
  local TMPDIR="$2"

  read -a EVTFILES <<< `grep -v "^#" ${EVTFILESLIST}`
  NUMEVTFILES=${#EVTFILES[@]}

  for ((i=0; i<$NUMEVTFILES; i++)); do
    # _FILE=${EVTFILES[$i]##*/}
    create_xrtexpomap "${EVTFILES[$i]}" "$TMPDIR"
  done
}
