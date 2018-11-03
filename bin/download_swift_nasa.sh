#!/usr/bin/env bash
set -e

# This script downloads Swift observations from NASA's archive;
# The archive is available at 'ftp://legacy.gsfc.nasa.gov'.
# Specifically, given a Observation-ID and its corresponding Date,
# this script will download everything from XRT's 'products' directory
# and XRT's "clean" eventfiles (xrt/event/*_cl.evt).
#
# The script accepts three input parameters:
# * Swift Observation ID (eg, 00035393001)
# * Observation Date (eg, 2006_03)
# * Optionally, local archive path (where 'swift/data/obs/' goes)

# Base url of (NASA's) data archive, from where we gonna download the data
#
ARCHIVE_SERVER='ftp://legacy.gsfc.nasa.gov'
ARCHIVE_DIRECTORY='swift/data/obs'
ARCHIVE_URL="${ARCHIVE_SERVER}/${ARCHIVE_DIRECTORY}"

# Local archive/storage.
# We organize our local archive similar to NASA and ASDC:
# > "swift/data/obs/DATE/OBSID"
# By default, we'll use the current working directory as local archive's
# root/top level.
LOCAL_ARCHIVE="$PWD"
# LOCAL_PATH='swift/data/obs'
LOCAL_PATH='./'

usage() {
  echo
  _file=$(basename $BASH_SOURCE)
  echo "Usage: $_file -o <OBSID> -d <DATE> [-a <LOCAL_ARCHIVE>]"
  echo
  echo "  -o : swift observation id (eg, 00035393001)."
  echo "  -d : observation date; format is YYYY_MM (eg, 2006_03)."
  echo "  -a : local data archive (directory hosting './swift/data/obs')"
  echo "       Default is $PWD."
  echo "  -f : (force) download data even if OBSID is already in LOCAL_ARCHIVE."
  echo "       Default is *not* download OBSID again (even if it has been partially downloaded)"
  echo
  echo "Observation will be stored under LOCAL_DIRECTORY/DATE/OBSID:"
  echo "> LOCAL_ARCHIVE/$LOCAL_PATH/DATE/OBSID"
  echo
  exit 1
}


function download(){
  local YYYYMM="$1"
  local OBSID="$2"
  local LOCAL_ARCHIVE="$3"

  local LOCAL_DIR="${PWD}/log"
  [ -d $LOCAL_DIR ] || mkdir -p $LOCAL_DIR

  local FILE_LOG="${LOCAL_DIR}/${YYYYMM}_${OBSID}.log"
  local TARGET_DIR="${ARCHIVE_URL}/${YYYYMM}/${OBSID}/"  # NOTICE the trailing '/'! This shit is important!

  curl -s "$TARGET_DIR" > /dev/null || { 1>&2 echo "Could not reach '$TARGET_DIR'."; exit 1; }

  echo "    - logs will be written in ${LOCAL_DIR}"
  echo "    - data being downloaded: ${TARGET_DIR}"

  echo "Transfer START time: `date`" >> "${FILE_LOG}"

  (
    # cd $LOCAL_ARCHIVE
    WAIT=$(echo "scale=2 ; 2*$RANDOM/32768" | bc -l)
    sleep "$WAIT"s
    #>> "${FILE_LOG}" \
    #wget -r --no-verbose --no-parent -nH --cut-dirs=3 \
    #                      --wait=2 --random-wait \
    #                      "${TARGET_DIR}/event/*_cl.evt.gz" 2>&1
    #>> "${FILE_LOG}" \
    #wget -r --no-verbose --no-parent -nH --cut-dirs=3 \
    #                      --wait=2 --random-wait \
    #                      "${TARGET_DIR}/products" 2>&1
    declare -a EVTS=($(curl -s -l ${TARGET_DIR}/xrt/event/ | grep "xpc.*_cl.evt.gz" ))
    declare -a HKS=($(curl -s -l ${TARGET_DIR}/xrt/hk/ | grep "xhd.hk.gz" ))
    declare -a AUXS=($(curl -s -l ${TARGET_DIR}/auxil/ | grep "[ps]at.fits.gz" ))

    echo ${EVTS[@]} | xargs -n1 -P3 -I{} wget -q --show-progress -c \
                                              --wait=2 --random-wait \
                                              -P "${LOCAL_ARCHIVE}/xrt/event/" \
                                              ${TARGET_DIR}/xrt/event/{}

    printf "%s\n" "${HKS[@]}" | xargs -n1 -P3 -I{} wget --no-verbose -c \
                                                    --wait=2 --random-wait \
                                                    -P "${LOCAL_ARCHIVE}/xrt/hk/" \
                                                    ${TARGET_DIR}/xrt/hk/{}

    printf "%s\n" "${AUXS[@]}" | xargs -n1 -P3 -I{} wget --no-verbose -c \
                                                    --wait=2 --random-wait \
                                                    -P "${LOCAL_ARCHIVE}/auxil/" \
                                                    ${TARGET_DIR}/auxil/{}
  )

  echo "Transfer STOP time: `date`" >> "${FILE_LOG}"
}

FORCE_DOWNLOAD=''

while getopts ":d:o:a:f" OPT; do
    case "${OPT}" in
        d)
            DATE=${OPTARG}
            ;;
        o)
            OBSID=${OPTARG}
            ;;
        a)
            LOCAL_ARCHIVE=${OPTARG}
            ;;
        f)
            FORCE_DOWNLOAD='yes'
            ;;
        *)
            usage
            ;;
    esac
done

[ -n "${DATE}" -a -n "${OBSID}" -a -n "${LOCAL_ARCHIVE}" ] || usage


LOCAL_ARCHIVE_OBS="${LOCAL_ARCHIVE}/${LOCAL_PATH}/${DATE}/${OBSID}/"
if [ -z "$FORCE_DOWNLOAD" ]; then
  if [ -d "$LOCAL_ARCHIVE_OBS" ]; then
    echo "========================================================="
    echo "Data '${DATE}/${OBSID}' already downloaded"
    echo "========================================================="
    exit 0
  fi
fi

# Guarantee destination directory exist
[ -d "$LOCAL_ARCHIVE_OBS" ] || mkdir -p $LOCAL_ARCHIVE_OBS 2> /dev/null

if [ ! -w ${LOCAL_ARCHIVE_OBS} ]; then
  1>&2 echo "You don't have enough permissions to write to '${LOCAL_ARCHIVE_OBS}'. Finishing."
  exit 1
fi

echo "========================================================="
TIME_INIT=$(date +%s)
echo "Downloading ${DATE}, observation $OBSID.."

# ========
# Download
download "${DATE}" "${OBSID}" "$LOCAL_ARCHIVE_OBS"
# ========

echo "..done."
TIME_DONE=$(date +%s)
TIME_ELAP=$((TIME_DONE-TIME_INIT))
echo "-------"
echo " - Time elapsed: $TIME_ELAP"s
echo "========================================================="
