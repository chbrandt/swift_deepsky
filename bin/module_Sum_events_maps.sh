#!/usr/bin/env bash
set +u

select_event_files(){
  DATA_ARCHIVE="$1"
  OBS_ADDR_LIST="$2"
  OUT_FILE="$3"

  SWIFT_OBS_ARCHIVE="${DATA_ARCHIVE}"

  for ln in `cat $OBS_ADDR_LIST`
  do
    OIFS=$IFS
    IFS='/' read -ra FLDS <<< "$ln"
    IFS=$OIFS
    DATADIR="${SWIFT_OBS_ARCHIVE}/${FLDS[0]}/${FLDS[1]}"
    [ -d $DATADIR ] || continue
    XRTDIR=${DATADIR}/xrt
    EVTDIR=${XRTDIR}/event

    for f in ${EVTDIR}/*pc*po_cl.evt.gz; do
      if [ -e "$f" ]; then
        echo "$f" >> $OUT_FILE
      else
        1>&2 echo "Files not found for observation: $ln"
        break
      fi
    done
  done
}

select_exposure_maps() {
  DATA_ARCHIVE="$1"
  OBS_ADDR_LIST="$2"
  OUT_FILE="$3"

  SWIFT_OBS_ARCHIVE="${DATA_ARCHIVE}"

  for ln in `cat $OBS_ADDR_LIST`
  do
    OIFS=$IFS
    IFS='/' read -ra FLDS <<< "$ln"
    IFS=$OIFS
    DATADIR="${SWIFT_OBS_ARCHIVE}/${FLDS[0]}/${FLDS[1]}"
    [ -d $DATADIR ] || continue
    XRTDIR=${DATADIR}/xrt
    EXPDIR=${XRTDIR}/products

    for f in ${EXPDIR}/*pc*ex.img.gz; do
      if [ -e "$f" ]; then
        echo "$f" >> $OUT_FILE
      else
        1>&2 echo "Files not found for observation: $ln"
        break
      fi
    done
  done
}

create_xselect_sum_script() {
  NAME="$1"
  EVTLIST="$2"
  RESULT="$3"
  OUT_FILE="$4"

  TMPDIRREL="./${TMPDIR#$PWD}"

  NAME=$(echo $NAME | tr -c "[:alnum:]\n" "_")

  read -a EVTFILES <<< `grep -v "^#" ${EVTLIST}`
  NUMEVTFILES=${#EVTFILES[@]}

  echo "xsel"                                 >> $OUT_FILE
  # echo "log ${TMPDIR}/xselect_eventssum.log"

  i=0
  _FILE=${EVTFILES[$i]##*/}
  cp ${EVTFILES[$i]} "${TMPDIR}/${_FILE}"
  echo "read ev $_FILE"                       >> $OUT_FILE
  echo "${TMPDIRREL}/"                        >> $OUT_FILE
  echo "yes"                                  >> $OUT_FILE
  for ((i=1; i<$NUMEVTFILES; i++)); do
    _FILE=${EVTFILES[$i]##*/}
    cp ${EVTFILES[$i]} "${TMPDIR}/${_FILE}"
    echo "read ev $_FILE"                     >> $OUT_FILE
    if [ $i -ge 20 ]; then
      echo 'yes'                              >> $OUT_FILE
    fi
  done
  echo 'extract ev'                           >> $OUT_FILE
  echo "save ev $RESULT"                      >> $OUT_FILE
  echo "yes"                                  >> $OUT_FILE
  echo "quit"                                 >> $OUT_FILE
  echo "no"                                   >> $OUT_FILE
}

create_ximage_sum_script() {
  NAME="$1"
  IMGLIST="$2"
  RESULT="$3"
  OUT_FILE="$4"

  TMPDIRREL="./${TMPDIR#$PWD}"

  NAME=$(echo $NAME | tr -c "[:alnum:]\n" "_")

  read -a IMAGES <<< `grep -v "^#" $IMGLIST`
  NUMIMAGES=${#IMAGES[@]}

  # echo "log ${TMPDIR}/ximage_expossum.log"
  echo "cpd ${NAME}_sum.gif/gif"                  >> $OUT_FILE

  i=0
  _FILE=${IMAGES[$i]##*/}
  _FILE=${TMPDIRREL}/${_FILE}
  cp ${IMAGES[$i]} "${_FILE}"
  echo "read/size=800  ${_FILE}"                 >> $OUT_FILE
  for ((i=1; i<$NUMIMAGES; i++)); do
    _FILE=${IMAGES[$i]##*/}
    _FILE=${TMPDIRREL}/${_FILE}
    cp ${IMAGES[$i]} "${_FILE}"
    echo "read/size=800  ${_FILE}"               >> $OUT_FILE
    echo 'sum_image'                              >> $OUT_FILE
    echo 'save_image'                             >> $OUT_FILE
  done
  echo "display"                                  >> $OUT_FILE
  echo "write_ima/template=all/file=\"$RESULT\""  >> $OUT_FILE
  echo "exit"                                     >> $OUT_FILE
}
