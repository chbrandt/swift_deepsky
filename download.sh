#!/usr/bin/env bash
set -eu

# Base url of (NASA's) data archive, from where we gonna download the data
#
ARCHIVE_SERVER='ftp://legacy.gsfc.nasa.gov'
ARCHIVE_DIRECTORY='swift/data/obs'
ARCHIVE_URL="${ARCHIVE_SERVER}/${ARCHIVE_DIRECTORY}"


usage() {
  echo
  _file=$(basename $BASH_SOURCE)
  echo "Usage: $_file -d <date> -o <obsid>"
  echo
  echo "  -d : observation date; format is YYYY_MM"
  echo "  -o : swift observation id"
  echo
  exit 1
}


function download(){
  YYYYMM="$1"
  OBSID="$2"

  LOCAL_DIR="${PWD}/log"
  [ -d $LOCAL_DIR ] || mkdir -p $LOCAL_DIR

  FILE_LOG="${LOCAL_DIR}/${YYYYMM}_${OBSID}.log"
  TARGET_DIR="${ARCHIVE_URL}/${YYYYMM}/${OBSID}/"    # NOTICE the trailing '/'! This shit is important!

  curl -s -l "$TARGET_DIR" > /dev/null || { 1>&2 echo "Could not reach '$TARGET_DIR'."; exit 1; }

  echo "    - things will be written to ${LOCAL_DIR}"
  echo "    - archive being recursively downloaded: ${TARGET_DIR}"

  echo "Transfer START time: `date`" >> "${FILE_LOG}"

  wget -r --no-verbose --no-parent -nH --wait=2 --random-wait "${TARGET_DIR}" &>> "${FILE_LOG}"

  echo "Transfer STOP time: `date`" >> "${FILE_LOG}"
}



while getopts ":d:o:a:" OPT; do
    case "${OPT}" in
        d)
            DATE=${OPTARG}
            ;;
        o)
            OBSID=${OPTARG}
            ;;
        a)
            ARCHIVE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

[ -n "${DATE}" -a -n "${OBSID}" -a -n "${ARCHIVE}" ] || usage

LOCAL_ARCHIVE_DIR="${ARCHIVE}/${ARCHIVE_DIRECTORY}/${DATE}/${OBSID}/"
if [ -d "$LOCAL_ARCHIVE_DIR" ]; then
  echo "========================================================="
  echo "Data '${DATE}/${OBSID}' already downloaded"
  echo "========================================================="
  exit 0
fi

echo "========================================================="
TIME_INIT=$(date +%s)
echo "Downloading ${DATE}, observation $OBSID.."

download "${DATE}" "${OBSID}"

echo "..done."
TIME_DONE=$(date +%s)
TIME_ELAP=$((TIME_DONE-TIME_INIT))
echo "-------"
echo " - Time elapsed: $TIME_ELAP"s
echo "========================================================="
