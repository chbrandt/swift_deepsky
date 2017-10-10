#!/usr/bin/env bash
set -u

event_files(){
  DATA_ARCHIVE="$1"
  OBS_ADDR_LIST="$2"

  SWIFT_OBS_ARCHIVE="${DATA_ARCHIVE}/swift/data/obs"

  # echo "# Event files"
  for ln in `cat $OBS_ADDR_LIST`
  do
    OIFS=$IFS
    IFS='/' read -ra FLDS <<< "$ln"
    IFS=$OIFS
    DATADIR="${SWIFT_OBS_ARCHIVE}/${FLDS[0]}/${FLDS[1]}"
    [ -d $DATADIR ] || continue
    XRTDIR=${DATADIR}/xrt
    EVTDIR=${XRTDIR}/event
    ls ${EVTDIR}/*pc*po_cl.evt.gz
  done
}

exposure_maps() {
  DATA_ARCHIVE="$1"
  OBS_ADDR_LIST="$2"

  SWIFT_OBS_ARCHIVE="${DATA_ARCHIVE}/swift/data/obs"

  # echo "# Exposure maps:"
  for ln in `cat $OBS_ADDR_LIST`
  do
    OIFS=$IFS
    IFS='/' read -ra FLDS <<< "$ln"
    IFS=$OIFS
    DATADIR="${SWIFT_OBS_ARCHIVE}/${FLDS[0]}/${FLDS[1]}"
    [ -d $DATADIR ] || continue
    XRTDIR=${DATADIR}/xrt
    EXPDIR=${XRTDIR}/products
    ls ${EXPDIR}/*pc*ex.img.gz
  done
}

create_xselect_script() {
  NAME="$1"
  EVTLIST="$2"
  RESULT="$3"

  TMPDIRREL="./${TMPDIR#$PWD}"

  NAME=$(echo $NAME | tr -c "[:alnum:]\n" "_")

  read -a EVTFILES <<< `grep -v "^#" ${EVTLIST}`

  NUMEVTFILES=${#EVTFILES[@]}

  echo "xsel"
  # echo "log ${TMPDIR}/xselect_eventssum.log"

  i=0
  _FILE=${EVTFILES[$i]##*/}
  cp ${EVTFILES[$i]} "${TMPDIR}/${_FILE}"
  echo "read ev $_FILE"
  echo "${TMPDIRREL}/"
  echo "yes"
  for ((i=1; i<$NUMEVTFILES; i++)); do
    _FILE=${EVTFILES[$i]##*/}
    cp ${EVTFILES[$i]} "${TMPDIR}/${_FILE}"
    echo "read ev $_FILE"
    if [ $i -ge 20 ]; then
      echo 'yes'
    fi
  done
  echo 'extract ev'
  echo "save ev $RESULT"
  echo "yes"
  echo "quit"
  echo "no"
}

create_ximage_script() {
  NAME="$1"
  IMGLIST="$2"
  RESULT="$3"

  TMPDIRREL="./${TMPDIR#$PWD}"

  NAME=$(echo $NAME | tr -c "[:alnum:]\n" "_")

  # echo "log ${TMPDIR}/ximage_expossum.log"

  echo "cpd  ${NAME}_sum.gif/gif"
  read -a IMAGES <<< `grep -v "^#" $IMGLIST`
  NUMIMAGES=${#IMAGES[@]}

  i=0
  _FILE=${IMAGES[$i]##*/}
  _FILE=${TMPDIRREL}/${_FILE}
  cp ${IMAGES[$i]} "${_FILE}"
  echo "read/size=1024  ${_FILE}"
  for ((i=1; i<$NUMIMAGES; i++)); do
    _FILE=${IMAGES[$i]##*/}
    _FILE=${TMPDIRREL}/${_FILE}
    cp ${IMAGES[$i]} "${_FILE}"
    echo "read/size=1024  ${_FILE}"
    echo 'sum_image'
    echo 'save_image'
  done
  echo "display"
  echo "write_ima/template=all/file=\"$RESULT\""
  echo "exit"
}

# EVENTSFILE='object_events.txt'
# EXMAPSFILE='object_exmaps.txt'
# create_obsfilelist $PWD 'object_observations.csv' $EVENTSFILE $EXMAPSFILE
# script_xselect_sum 'object' $EVENTSFILE 'events_sum.xco' 'evts'
# script_ximage_sum 'object' $EXMAPSFILE 'exmaps_sum.xco' 'expo'
