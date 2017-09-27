#!/usr/bin/env bash
set -ue

SCRPT_DIR=$(cd `dirname $BASH_SOURCE`; pwd)

# Number of simultaneous processing slots available
# So far, this is being used only during data download
#
NPROCS=3

# Make the script verbose by default
VERBOSE=1

# Default size of the field to consider (in arc-minutes)
#
RADIUS=12

# Numerical value to be used as null
NULL_VALUE=-999

########################################################################
# Swift-Events stacking
# =====================
# Input:
# - Swift Master table
# - Object name or position
# - Root data archive directory
# Output:
#
#
# Swift Master table
# ------------------
# This is a CSV (sep=';') table where each row contains information
# about Swift observations. The table must contain the columns: 'OBSID',
# 'START_TIME','RA','DEC'.
#
# Object name or position
# -----------------------
# If an object name is given, the corresponding position, as published
# by Vizier/SIMBAD, will be retrieved. The position is used as the
# central coordinate from where a cone-search is performed using a
# 12 arcmin search radius throught the entire Swift Master table.
# All observations falling inside the region will be processed.
#
# Root data archive directory
# ---------------------------
# The directory where 'swift' archive tree is stored. Observational
# data will there be searched; If not there yet, it is downloaded.
#
########################################################################
help() {
  echo ""
  echo " Usage: $(basename $0) -d <data> { --ra <degrees> --dec <degrees> | --object <name> }"
  echo ""
  echo " Arguments:"
  echo "  --ra     VALUE    : Right Ascension (in DEGREES)"
  echo "  --dec    VALUE    : Declination (in DEGREES)"
  echo "  --object NAME     : name of object to use as center of the field."
  echo "                      If given, CDS/Simbad is queried for the position"
  echo "                      associated with 'NAME'"
  echo "  --radius VALUE    : Radius (in ARC-MINUTES) around RA,DEC to search for observations. Default is '$RADIUS' (arcmin)"
  echo "  -d|--data_archive : data archive directory; Where Swift directories-tree is."
  echo "                      This directory is supposed to contain the last 2 levels"
  echo "                      os Swift archive usual structure: 'data_archive'/START_TIME/OBSID"
  echo ""
  echo " Options:"
  echo "  -f|--master_table : Swift master-table. This table relates RA,DEC,START_TIME,OBSID."
  echo "                      The 'master_table' should be a CSV file with these columns"
  echo "  -o|--outdir       : output directory; default is the current one."
  echo "                      In 'outdir', a directory for every file from this run is created."
  echo ""
  echo "  -h|--help         : this help message"
  echo "  -q|--quiet        : verbose"
  echo ""
}
trap help ERR

# If no arguments given, print Help and exit.
[ "${#@}" -eq 0 ] && { help; exit 0; }


# Swift-XRT master table defaults to the one packaged
#
TABLE_MASTER="${SCRPT_DIR}/SwiftXrt_master.csv"

# Default output dir is the current working dir.
# By all means, a sub-directory will be created to hold every
# outputfile (temporary or final)
#
OUTDIR="$PWD"

# Empty field variables
POS_RA=''
POS_DEC=''
OBJECT=''

while [[ $# -gt 0 ]]
do
  case $1 in
    -h|--help)
      help;exit 0;;
    -q|--quiet)
      VERBOSE=0;;
    -f|--master_table)
      TABLE_MASTER=$2
      shift;;
    -d|--data_archive)
      DATA_ARCHIVE=$2
      shift;;
    -o|--outdir)
      OUTDIR=$2
      shift;;
    --object)
      OBJECT=$2
      shift;;
    --ra)
      POS_RA=$2
      shift;;
    --dec)
      POS_DEC=$2
      shift;;
    --radius)
      RADIUS=$2
      shift;;
    --)
      shift
      break;;
    --*)
      echo "$0: error - unrecognized option $1" 1>&2
      help;exit 1;;
    -?)
      echo "$0: error - unrecognized option $1" 1>&2
      help;exit 1;;
    *)
      break;;
    esac
    shift
done

# First of all, we verify and resolve the position/object argument(s)
# since they are the central figures here.
#
if [[ -z $POS_RA || -z $POS_DEC ]]; then
  if [ -z $OBJECT ]; then
    1>&2 echo -e "\nERROR: Provide a (central) position through RA,DEC or Object name\n"
    help
    exit 1
  else
    # Normalize object name to remove non-alphanumeric characters
    #
    RUN_LABEL=$(echo $OBJECT | tr -d '[:space:].' | tr "+" "p" | tr "-" "m")
    POS=$(python ${SCRPT_DIR}/object2position.py $OBJECT | cut -d':' -f2 | tr -d '[:space:]')
    POS_RA=$(echo $POS | cut -d',' -f1)
    POS_DEC=$(echo $POS | cut -d',' -f2)
  fi
else
  [[ ${POS_RA%.*} -lt 360 && ${POS_RA%.*} -ge 0 ]] || { 1>&2 echo -e "\nERROR: RA expected to be between [0:360], instead '$POS_RA' was given\n"; exit1; }
  [[ ${POS_DEC%.*} -gt -90 && ${POS_DEC%.*} -lt 90 ]] || { 1>&2 echo -e "\nERROR: DEC expected to be between [-90:90], instead '$POS_DEC' was given\n"; exit1; }
  RUN_LABEL=$(echo "${POS_RA}_${POS_DEC}_${RADIUS}" | tr '.' '_' | tr "+" "p" | tr "-" "m")
fi

# Sanity-check:
: ${POS_RA:?'Oops! RA is not defined!?'}
: ${POS_DEC:?'Oops! Dec is not defined!?'}
: ${RUN_LABEL:?'Oops! Label is not defined!?'}


: ${TABLE_MASTER:?'Argument -f must be specified'}
: ${DATA_ARCHIVE:?'Argument -d must be specified'}

# Guarantee input (table and data) files are in absolute-path format
#
[[ "${TABLE_MASTER}" = /* ]] || TABLE_MASTER="${PWD}/${TABLE_MASTER}"
[[ "${DATA_ARCHIVE}" = /* ]] || DATA_ARCHIVE="${PWD}/${DATA_ARCHIVE}"
[[ "${OUTDIR}" = /* ]] || OUTDIR="${PWD}/${OUTDIR}"

# Output and temporary directories to store averything accordingly
#
OUTDIR="${OUTDIR}/${RUN_LABEL}"
TMPDIR="${OUTDIR}/tmp"

if [ -d $OUTDIR ]; then
  touch ${OUTDIR}/bla.tmp
  rm ${OUTDIR}/*.*
  rm -rf ${TMPDIR}
else
  mkdir -p ${OUTDIR}
fi
[ -d $TMPDIR ] || mkdir -p ${TMPDIR}


LOGFILE="${OUTDIR}/pipeline_internals.log"
LOGERROR="${LOGFILE}.error"

function fecho() {
  [ $VERBOSE -eq 1 ] || return
  echo "$@" | tee -a $LOGFILE
}

# Summary
# -------
fecho "#==============================================================="
fecho "# Swift (XRT) deep-sky pipeline"
fecho "# -----------------------------"
fecho "# Pipeline arguments:"
fecho "#  * Swift master table: ${TABLE_MASTER}"
fecho "#  * Swift archive:      ${DATA_ARCHIVE}"
fecho "#  * Field:              ${OBJECT}"
fecho "#    * RA:               ${POS_RA}"
fecho "#    * Dec:              ${POS_DEC}"
fecho "#    * Radius:           ${RADIUS}"
fecho "#  * Run-label:          ${RUN_LABEL}"
fecho "#  * Output directory:   ${OUTDIR}"
fecho "#    * Temporary files:  ${TMPDIR}"
fecho "#  * Logfile:            ${LOGFILE}"
fecho "#    * Error log:        ${LOGERROR}"
fecho "#..............................................................."

fecho "# Workflow:"
fecho "# 1.1) Identify all XRT observations inside the requested field;"
fecho "#      Field size is $RADIUS arcmin around given object/position."
fecho "# 1.2) Check data archive, download necessary files if missing;"
fecho "#      A maximum of $NPROCS downloads will run concurrently."
fecho "#..............................................................."

# Selected swift table entries
#
TABLE_SELECT="${OUTDIR}/${RUN_LABEL}_selected_observations.csv"

# Stacked events/expomaps
#
EVENTSSUM_RESULT="${OUTDIR}/${RUN_LABEL}_sum.evt"
EXPOSSUM_RESULT="${OUTDIR}/${RUN_LABEL}_sum.exp"

# Final flux table
#
COUNTRATES_TABLE="${OUTDIR}/table_countrates_detections.csv"
FLUX_TABLE="${OUTDIR}/table_flux_detections.csv"

fecho "# Pipeline outputs:"
fecho "# * Filtered entries from Master table:"
fecho "    TABLE_SELECT=$TABLE_SELECT"
fecho "# * Stacked events file:"
fecho "    EVENTSSUM_RESULT=$EVENTSSUM_RESULT"
fecho "# * Stacked exposure-maps file:"
fecho "    EXPOSSUM_RESULT=$EXPOSSUM_RESULT"
fecho "# * Detected objects photon-flux table:"
fecho "    COUNTRATES_TABLE=$COUNTRATES_TABLE"
fecho "# * Detected objects final flux table:"
fecho "    FLUX_TABLE=$FLUX_TABLE"
fecho "#..............................................................."


# List of Swift archive observation addresses
#
OBSLIST="${TMPDIR}/${RUN_LABEL}.archive_addr.txt"
(
  # This first block reads the (internal) database
  BLOCK='DATA_SELECTION'
  fecho "# Block (1) $BLOCK"
  cd $OUTDIR

  # Select rows/obserations from master table in the field
  #
  fecho "# -> Selecting observations.."
  python ${SCRPT_DIR}/select_observations.py $TABLE_MASTER \
                                            $TABLE_SELECT \
                                            --position "${POS_RA},${POS_DEC}" \
                                            --radius $RADIUS \
                                            --archive_addr_list $OBSLIST \
                                            2>> $LOGERROR >> $LOGFILE

  [[ $? -eq 0 ]] || { 1>&2 echo "Observations selection failed. Exiting."; exit 1; }

  NOBS=$(grep -v "^#" $OBSLIST | grep -v "^\s*$" | wc -l)
  [[ $NOBS -ne 0 ]] || { 1>&2 echo "No observations selected. Exiting."; exit 1; }
  fecho "#    - Number of observations selected: $NOBS"
  fecho "  OBSLIST="`cat $OBSLIST`
  unset NOBS

  # Download Swift observations; Already present datasets are skipped
  #
  fecho "# -> Querying/Downloading observations.."
  ${SCRPT_DIR}/download_queue.sh -n $NPROCS -f $OBSLIST -d $DATA_ARCHIVE \
    2>> $LOGERROR >> $LOGFILE

  fecho "#............................................................."
)

(
  BLOCK='DATA_STACKING'
  fecho "# Block (2) $BLOCK"
  cd $OUTDIR

  source ${SCRPT_DIR}/setup_ximage_files.fsh

  # Create two files with filenames list of event-images and exposure-maps
  #
  fecho "# -> Querying archive for event-files:"
  EVENTSFILE="${TMPDIR}/${RUN_LABEL}_events.txt"
  event_files $DATA_ARCHIVE $OBSLIST > $EVENTSFILE 2> $LOGERROR
  fecho "  EVENTSFILE="`cat $EVENTSFILE`

  fecho "# -> ..and exposure-maps:"
  EXMAPSFILE="${TMPDIR}/${RUN_LABEL}_expos.txt"
  exposure_maps $DATA_ARCHIVE $OBSLIST > $EXMAPSFILE 2> $LOGERROR
  fecho "  EXMAPSFILE="`cat $EXMAPSFILE`

  # Create XSelect and XImage scripts to sum event-files and exposure-maps
  #
  fecho "# -> Generating scripts for stacking data"
  XSELECT_SUM_SCRIPT="${TMPDIR}/events_sum.xcm"
  create_xselect_script $RUN_LABEL $EVENTSFILE $EVENTSSUM_RESULT > $XSELECT_SUM_SCRIPT

  XIMAGE_SUM_SCRIPT="${TMPDIR}/expos_sum.xco"
  create_ximage_script $RUN_LABEL $EXMAPSFILE $EXPOSSUM_RESULT > $XIMAGE_SUM_SCRIPT

  # Run the scripts
  #
  fecho "# -> Running XSelect (events concatenation).."
  xselect < $XSELECT_SUM_SCRIPT &>> $LOGFILE
  fecho "# -> Running XImage (exposure-maps stacking).."
  ximage < $XIMAGE_SUM_SCRIPT &>> $LOGFILE

  [[ -f xselect.log ]] && mv xselect.log $TMPDIR

  fecho "#..............................................................."
)

XSELECT_DET_DEFAULT="${EVENTSSUM_RESULT%.*}.det"
DET_TMPDIR="${TMPDIR}/${XSELECT_DET_DEFAULT##*/}"
XSELECT_DET_FULL="${DET_TMPDIR%.*}.full.det"
XSELECT_DET_SOFT="${DET_TMPDIR%.*}.soft.det"
XSELECT_DET_MEDIUM="${DET_TMPDIR%.*}.medium.det"
XSELECT_DET_HARD="${DET_TMPDIR%.*}.hard.det"
(
  # Here we use ximage to detect bright sources in the field.
  # The "field" now is the result of all observations stacked,
  # event-files and exposure-maps.
  # We want to detect such (bright) sources using every photon
  # available, i.e., using the entire x-ray band (0.3keV to 10keV)
  BLOCK='SOURCES_DETECTION'
  fecho "# Block (3) $BLOCK"
  cd $OUTDIR


  XIMAGE_TMP_SCRIPT="${TMPDIR}/ximage.detect_full.xco"
  fecho "# -> Detecting bright sources in the FULL band (0.3-10keV).."
  cat > $XIMAGE_TMP_SCRIPT << EOF
read/size=1024/ecol=PI/emin=30/emax=1000 $EVENTSSUM_RESULT
read/size=1024/expo $EXPOSSUM_RESULT
det/bright
quit
EOF
  ximage < $XIMAGE_TMP_SCRIPT &>> $LOGFILE
  mv $XSELECT_DET_DEFAULT $XSELECT_DET_FULL

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_soft.xco
  fecho "# -> Detecting bright sources in the SOFT band (0.3-1keV).."
  cat > $XIMAGE_TMP_SCRIPT << EOF
read/size=1024/ecol=PI/emin=30/emax=100 $EVENTSSUM_RESULT
read/size=1024/expo $EXPOSSUM_RESULT
det/bright
quit
EOF
  ximage < $XIMAGE_TMP_SCRIPT &>> $LOGFILE
  mv $XSELECT_DET_DEFAULT $XSELECT_DET_SOFT

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_medium.xco
  fecho "# -> Detecting bright sources in the MEDIUM band(1-2keV).."
  cat > $XIMAGE_TMP_SCRIPT << EOF
read/size=1024/ecol=PI/emin=101/emax=200 $EVENTSSUM_RESULT
read/size=1024/expo $EXPOSSUM_RESULT
det/bright
quit
EOF
  ximage < $XIMAGE_TMP_SCRIPT &>> $LOGFILE
  mv $XSELECT_DET_DEFAULT $XSELECT_DET_MEDIUM

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_hard.xco
  fecho "# -> Detecting bright sources in the HARD band (2-10keV).."
  cat > $XIMAGE_TMP_SCRIPT << EOF
read/size=1024/ecol=PI/emin=201/emax=1000 $EVENTSSUM_RESULT
read/size=1024/expo $EXPOSSUM_RESULT
det/bright
quit
EOF
  ximage < $XIMAGE_TMP_SCRIPT &>> $LOGFILE
  mv $XSELECT_DET_DEFAULT $XSELECT_DET_HARD

  # rm $XIMAGE_TMP_SCRIPT
  fecho "#..............................................................."
)

(
  # And now, for each source detected previously by ximage:detect/bright
  # we estimate the source with ximage/sosta for each x-ray band.
  # Sosta will use the background estimate from the
  BLOCK='COUNTRATES_MEASUREMENT'
  fecho "# Block (4) $BLOCK"
  cd $OUTDIR

  source ${SCRPT_DIR}/det2sosta.fsh

  # To have the countrates as a simple table, in its own file,
  # for future use, we should create it as a sub-products during
  # the following det-2-sosta runs..
  #
  CTS_DET_FULL="${TMPDIR}/countrates_full.detect.txt"

  XIMAGE_TMP_SCRIPT="${TMPDIR}/ximage.sosta_full.xco"
  LOGFILE_FULL="${TMPDIR}/sosta_full.log"
  det2sosta $XSELECT_DET_FULL \
            $XSELECT_DET_FULL 30 1000 \
            $EXPOSSUM_RESULT \
            $LOGFILE_FULL $CTS_DET_FULL \
            $RUN_LABEL \
            > $XIMAGE_TMP_SCRIPT
  ximage < $XIMAGE_TMP_SCRIPT &>> $LOGFILE

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_soft.xco
  LOGFILE_SOFT="${TMPDIR}/sosta_soft.log"
  det2sosta $XSELECT_DET_FULL \
            $XSELECT_DET_SOFT 30 100 \
            $EXPOSSUM_RESULT \
            $LOGFILE_SOFT $CTS_DET_FULL \
            $RUN_LABEL \
            > $XIMAGE_TMP_SCRIPT
  ximage < $XIMAGE_TMP_SCRIPT &>> $LOGFILE

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_medium.xco
  LOGFILE_MEDIUM="${TMPDIR}/sosta_medium.log"
  det2sosta $XSELECT_DET_FULL \
            $XSELECT_DET_MEDIUM 101 200 \
            $EXPOSSUM_RESULT \
            $LOGFILE_MEDIUM $CTS_DET_FULL \
            $RUN_LABEL \
            > $XIMAGE_TMP_SCRIPT
  ximage < $XIMAGE_TMP_SCRIPT &>> $LOGFILE

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_hard.xco
  LOGFILE_HARD="${TMPDIR}/sosta_hard.log"
  det2sosta $XSELECT_DET_FULL \
            $XSELECT_DET_HARD 201 1000 \
            $EXPOSSUM_RESULT \
            $LOGFILE_HARD $CTS_DET_FULL \
            $RUN_LABEL \
            > $XIMAGE_TMP_SCRIPT
  ximage < $XIMAGE_TMP_SCRIPT &>> $LOGFILE

  # rm $XIMAGE_TMP_SCRIPT

  # Countrates measured by Sosta are written in an non-tabular file,
  # we now read from this "logfile" and write to a table..
  #
  CTS_SOST_FULL="${TMPDIR}/countrates_full.sosta.txt"
  python ${SCRPT_DIR}/read_detections.py $LOGFILE_FULL 'FULL' > $CTS_SOST_FULL
  CTS_SOST_SOFT="${TMPDIR}/countrates_soft.sosta.txt"
  python ${SCRPT_DIR}/read_detections.py $LOGFILE_SOFT 'SOFT' > $CTS_SOST_SOFT
  CTS_SOST_MEDIUM="${TMPDIR}/countrates_medium.sosta.txt"
  python ${SCRPT_DIR}/read_detections.py $LOGFILE_MEDIUM 'MEDIUM' > $CTS_SOST_MEDIUM
  CTS_SOST_HARD="${TMPDIR}/countrates_hard.sosta.txt"
  python ${SCRPT_DIR}/read_detections.py $LOGFILE_HARD 'HARD' > $CTS_SOST_HARD
  # ..make it a CSV..
  COUNTRATES_SOSTA_TABLE="${COUNTRATES_TABLE%.*}.sosta.csv"
  COUNTRATES_SOSTA_TABLE="${TMPDIR}/${COUNTRATES_SOSTA_TABLE##*/}"
  paste $CTS_DET_FULL \
        $CTS_SOST_FULL \
        $CTS_SOST_SOFT \
        $CTS_SOST_MEDIUM \
        $CTS_SOST_HARD \
        > $COUNTRATES_SOSTA_TABLE
  sed -i 's/\s\{1,\}/;/g' $COUNTRATES_SOSTA_TABLE

  # And finally adjust the (countrate) fluxes.
  # Such fix seems necessary because sosta returns lower (countrate) numbers
  # which we don't exactly know why. So we weight each band measurement
  # done by Sosta by the measurement done before by Detect/bright.
  #
  grep -v "^#" $COUNTRATES_SOSTA_TABLE \
    | awk -F ';' -f ${SCRPT_DIR}/adjust_fluxes.awk > $COUNTRATES_TABLE 2> $LOGERROR
    fecho "#..............................................................."
)

(
  # Here we take the countrates measurements from the last block,
  # saved in file '$COUNTRATES_TABLE', which are in units of `cts/s`,
  # and transform them to energy flux, in `erg/s/cm2`.
  # We will use Paolo's countrates code, which takes the integrated
  # (photon) flux, energy slope and transform it accordingly.
  #
  BLOCK='COUNTRATES_TO_FLUX'
  fecho "# Block (5) $BLOCK"
  cd $OUTDIR

  source ${SCRPT_DIR}/countrates.fsh

  # For each detected source (each source is read from COUNTRATES_TABLE)
  # get its NH (given RA and DEC read from COUNTRATES_TABLE, use 'nh' tool)
  # define the middle band values (soft:0.5, medium:1.5, hard:5)
  # get the slope from swiftslope.py
  # input them all to 'countrates' to get nuFnu
  fecho "# -> Converting objects' flux.."

  echo -n "#RA;DEC;NH;ENERGY_SLOPE"                                                                     > $FLUX_TABLE
  echo -n ";FULL_5keV:flux[mW/m2];FULL_5keV:flux_error[mW/m2]"                                          >> $FLUX_TABLE
  echo -n ";SOFT_0.5keV:flux[mW/m2];SOFT_0.5keV:flux_error[mW/m2];SOFT_0.5keV:upper_limit[mW/m2]"       >> $FLUX_TABLE
  echo -n ";MEDIUM_1.5keV:flux[mW/m2];MEDIUM_1.5keV:flux_error[mW/m2];MEDIUM_1.5keV:upper_limit[mW/m2]" >> $FLUX_TABLE
  echo    ";HARD_4.5keV:flux[mW/m2];HARD_4.5keV:flux_error[mW/m2];HARD_4.5keV:upper_limit[mW/m2]"       >> $FLUX_TABLE

  for DET in `tail -n +2 $COUNTRATES_TABLE`; do
    IFS=';' read -a FIELDS <<< ${DET}

    # RA and Dec are the first two columns (in COUNTRATES_TABLE);
    # they are colon-separated, which we have to substitute by spaces
    #
    RA=${FIELDS[0]}
    ra=${RA//:/ }
    DEC=${FIELDS[1]}
    dec=${DEC//:/ }

    # NH comes from ftool's `nh` tool
    #
    NH=$(echo -e "2000\n${ra[*]}\n${dec[*]}" | nh | tail -n1 | awk '{print $NF}')
    fecho -n "    RA=$RA DEC=$DEC NH=$NH"

    # Countrates:
    #
    CT_FULL=${FIELDS[2]}
    CT_FULL_ERROR=${FIELDS[3]}
    #
    CT_SOFT=${FIELDS[4]}
    CT_SOFT_ERROR=${FIELDS[5]}
    CT_SOFT_UL=${FIELDS[6]}
    #
    CT_MEDIUM=${FIELDS[7]}
    CT_MEDIUM_ERROR=${FIELDS[8]}
    CT_MEDIUM_UL=${FIELDS[9]}
    #
    CT_HARD=${FIELDS[10]}
    CT_HARD_ERROR=${FIELDS[11]}
    CT_HARD_UL=${FIELDS[12]}

    # The `Swifslope` tool computes the slope of flux between hard(2-10keV)
    # and soft(0.3-2keV) bands. It's soft band definition comprises
    # *our* soft+medium (0.3-1keV + 1-2keV) definition.
    # That's why we are adding the soft+medium fluxes
    ct_softium=$(echo "$CT_SOFT $CT_MEDIUM" | awk '{print $1 + $2}')
    ct_softium_error=$(echo "$CT_SOFT_ERROR $CT_MEDIUM_ERROR" \
      | awk '{s=$1; m=$2; if(s<0){s=0}; if(m<0){m=0}; print( sqrt(s*s + m*m) )}')

    ENERGY_SLOPE=$(${SCRPT_DIR}/swiftslope.py --nh=$NH \
                                        --soft=$ct_softium \
                                        --soft_error=$ct_softium_error \
                                        --hard=$CT_HARD \
                                        --hard_error=$CT_HARD_ERROR \
                                        --oneline)
    ENERGY_SLOPE_minus=$(echo $ENERGY_SLOPE | cut -d' ' -f3)
    ENERGY_SLOPE_plus=$(echo $ENERGY_SLOPE | cut -d' ' -f2)
    ENERGY_SLOPE=$(echo $ENERGY_SLOPE | cut -d' ' -f1)
    SLOPE_OK=$(echo "$ENERGY_SLOPE_plus $ENERGY_SLOPE_minus" | awk '{dif=$1-$2; if(dif<0.8){print "yes"}else{print "no"}}')
    if [[ $SLOPE_OK == 'no' ]];
    then
      ENERGY_SLOPE_minus=${NULL_VALUE}
      ENERGY_SLOPE_plus=${NULL_VALUE}
      ENERGY_SLOPE='0.8'
      # fecho " # ENERGY_SLOPE was changed because estimate error was too big (>0.8)"
    fi
    fecho " ENERGY_SLOPE=$ENERGY_SLOPE"

    for BAND in `energy_bands list`; do
      # echo "#  -> Running band: $BAND"
      NUFNU_FACTOR=$(run_countrates $BAND $ENERGY_SLOPE $NH)
      fecho "      BAND=$BAND NUFNU_FACTOR=$NUFNU_FACTOR"
      case $BAND in
        soft)
          FLUX_SOFT=$(echo "$NUFNU_FACTOR $CT_SOFT" | awk '{print $1*$2}')
          FLUX_SOFT_ERROR=$(echo "$NUFNU_FACTOR $CT_SOFT_ERROR" | awk '{print $1*$2}')
          if [ $(is_null $CT_SOFT_UL) == 'yes' ]; then
            FLUX_SOFT_UL=$CT_SOFT_UL
          else
            FLUX_SOFT_UL=$(echo "$NUFNU_FACTOR $CT_SOFT_UL" | awk '{print $1*$2}')
          fi
          fecho "      FLUX_SOFT=$FLUX_SOFT FLUX_SOFT_ERROR=$FLUX_SOFT_ERROR FLUX_SOFT_UL=$FLUX_SOFT_UL"
          ;;
        medium)
          FLUX_MEDIUM=$(echo "$NUFNU_FACTOR $CT_MEDIUM" | awk '{print $1*$2}')
          FLUX_MEDIUM_ERROR=$(echo "$NUFNU_FACTOR $CT_MEDIUM_ERROR" | awk '{print $1*$2}')
          if [ $(is_null $CT_MEDIUM_UL) == 'yes' ]; then
            FLUX_MEDIUM_UL=$CT_MEDIUM_UL
          else
            FLUX_MEDIUM_UL=$(echo "$NUFNU_FACTOR $CT_MEDIUM_UL" | awk '{print $1*$2}')
          fi
          fecho "      FLUX_MEDIUM=$FLUX_MEDIUM FLUX_MEDIUM_ERROR=$FLUX_MEDIUM_ERROR FLUX_MEDIUM_UL=$FLUX_MEDIUM_UL"
          ;;
        hard)
          FLUX_HARD=$(echo "$NUFNU_FACTOR $CT_HARD" | awk '{print $1*$2}')
          FLUX_HARD_ERROR=$(echo "$NUFNU_FACTOR $CT_HARD_ERROR" | awk '{print $1*$2}')
          if [ $(is_null $CT_HARD_UL) == 'yes' ]; then
            FLUX_HARD_UL=$CT_HARD_UL
          else
            FLUX_HARD_UL=$(echo "$NUFNU_FACTOR $CT_HARD_UL" | awk '{print $1*$2}')
          fi
          fecho "      FLUX_HARD=$FLUX_HARD FLUX_HARD_ERROR=$FLUX_HARD_ERROR FLUX_HARD_UL=$FLUX_HARD_UL"
          ;;
        full)
          FLUX_FULL=$(echo "$NUFNU_FACTOR $CT_FULL" | awk '{print $1*$2}')
          FLUX_FULL_ERROR=$(echo "$NUFNU_FACTOR $CT_FULL_ERROR" | awk '{print $1*$2}')
          # if [ $(is_null $CT_FULL_UL) == 'yes' ]; then
          #   FLUX_FULL_UL=$CT_FULL_UL
          # else
          #   FLUX_FULL_UL=$(echo "$NUFNU_FACTOR $CT_FULL_UL" | awk '{print $1*$2}')
          # fi
          # fecho "      FLUX_FULL=$FLUX_FULL FLUX_FULL_ERROR=$FLUX_FULL_ERROR FLUX_FULL_UL=$FLUX_FULL_UL"
          fecho "      FLUX_FULL=$FLUX_FULL FLUX_FULL_ERROR=$FLUX_FULL_ERROR"
          ;;
      esac
    done
    echo -n "${RA};${DEC};${NH};${ENERGY_SLOPE}"                      >> $FLUX_TABLE
    echo -n ";${FLUX_FULL};${FLUX_FULL_ERROR}"                        >> $FLUX_TABLE
    echo -n ";${FLUX_SOFT};${FLUX_SOFT_ERROR};${FLUX_SOFT_UL}"        >> $FLUX_TABLE
    echo -n ";${FLUX_MEDIUM};${FLUX_MEDIUM_ERROR};${FLUX_MEDIUM_UL}"  >> $FLUX_TABLE
    echo    ";${FLUX_HARD};${FLUX_HARD_ERROR};${FLUX_HARD_UL}"        >> $FLUX_TABLE
  done
  sed -i 's/\s/;/g' $FLUX_TABLE
  fecho "#..............................................................."
)
echo "# ---"
echo "# Pipeline finished. Final table: '$FLUX_TABLE'"
echo "# ---"
