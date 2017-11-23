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

is_null() {
  local VAL=$1
  echo "$VAL $NULL_VALUE" | awk '{if($1==$2){print "yes"}else{print "no"}}'
}

function print() {
  [ $VERBOSE -eq 1 ] || return
  echo "$@" | tee -a $LOGFILE
}

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
  echo "  -l|--label LABEL  : Label output files. Otherwise object NAME or ra,dec VALUEs will be used."
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
LABEL=''

while [[ $# -gt 0 ]]
do
  case $1 in
    -h|--help)
      help; exit 0;;
    -q|--quiet)
      VERBOSE=0;;
    -l|--label)
      LABEL=$2; shift;;
    -f|--master_table)
      TABLE_MASTER=$2; shift;;
    -d|--data_archive)
      DATA_ARCHIVE=$2; shift;;
    -o|--outdir)
      OUTDIR=$2; shift;;
    --object)
      OBJECT=$2; shift;;
    --ra)
      POS_RA=$2; shift;;
    --dec)
      POS_DEC=$2; shift;;
    --radius)
      RADIUS=$2; shift;;
    --)
      shift; break;;
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

[[ -n $LABEL ]] && RUN_LABEL="$LABEL"

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

# Summary
# -------
print "#==============================================================="
print "# Swift (XRT) deep-sky pipeline"
print "# -----------------------------"
print "# Pipeline arguments:"
print "#  * Swift master table: ${TABLE_MASTER}"
print "#  * Swift archive:      ${DATA_ARCHIVE}"
print "#  * Field:              ${OBJECT}"
print "#    * RA:               ${POS_RA}"
print "#    * Dec:              ${POS_DEC}"
print "#    * Radius:           ${RADIUS}"
print "#  * Run-label:          ${RUN_LABEL}"
print "#  * Output directory:   ${OUTDIR}"
print "#    * Temporary files:  ${TMPDIR}"
print "#  * Logfile:            ${LOGFILE}"
print "#    * Error log:        ${LOGERROR}"
print "#..............................................................."

print "# Workflow:"
print "# 1.1) Identify all XRT observations inside the requested field;"
print "#      Field size is $RADIUS arcmin around given object/position."
print "# 1.2) Check data archive, download necessary files if missing;"
print "#      A maximum of $NPROCS downloads will run concurrently."
print "#..............................................................."

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

print "# Pipeline outputs:"
print "# * Filtered entries from Master table:"
print "    TABLE_SELECT=$TABLE_SELECT"
print "# * Stacked events file:"
print "    EVENTSSUM_RESULT=$EVENTSSUM_RESULT"
print "# * Stacked exposure-maps file:"
print "    EXPOSSUM_RESULT=$EXPOSSUM_RESULT"
print "# * Detected objects photon-flux table:"
print "    COUNTRATES_TABLE=$COUNTRATES_TABLE"
print "# * Detected objects final flux table:"
print "    FLUX_TABLE=$FLUX_TABLE"
print "#..............................................................."

DATA_ARCHIVE="${DATA_ARCHIVE}/obs"

# List of Swift archive observation addresses
#
OBSLIST="${TMPDIR}/${RUN_LABEL}.archive_addr.txt"
(
  # This first block reads the (internal) database
  BLOCK='DATA_SELECTION'
  print "# Block (1) $BLOCK"
  cd $OUTDIR

  # Select rows/obserations from master table in the field
  #
  print "# -> Selecting observations.."
  python ${SCRPT_DIR}/select_observations.py $TABLE_MASTER \
                                            $TABLE_SELECT \
                                            --position "${POS_RA},${POS_DEC}" \
                                            --radius $RADIUS \
                                            --archive_addr_list $OBSLIST \
                                            #2>> $LOGFILE #>> $LOGFILE

  [[ $? -eq 0 ]] || { 1>&2 echo "Observations selection failed. Exiting."; exit 1; }

  NOBS=$(grep -v "^#" $OBSLIST | grep -v "^\s*$" | wc -l)
  [[ $NOBS -ne 0 ]] || { 1>&2 echo "No observations selected. Exiting."; exit 1; }
  print "#    - Number of observations selected: $NOBS"
  print "  OBSLIST="`cat $OBSLIST`
  unset NOBS

  # Download Swift observations; Already present datasets are skipped
  #
  print "# -> Querying/Downloading observations.."
  ${SCRPT_DIR}/download_queue.sh -n $NPROCS -f $OBSLIST -d $DATA_ARCHIVE \
    #2>> $LOGFILE #>> $LOGFILE

  print "#............................................................."
)

(
  # Here we sum (or stack) the event-files as well as the exposure-maps.
  # This block works in three steps:
  # 1st) we select event-files and exposure-maps from each observation
  #      directory listed in '$OBSLIST'
  # 2nd) we generate the scripts for 'xselect' and 'ximage';
  #      xselect is used for event-files, while ximage for exposure-maps
  # 3rd) we run the scripts with the data files
  #
  BLOCK='DATA_STACKING'
  print "# Block (2) $BLOCK"
  cd $OUTDIR

  source ${SCRPT_DIR}/module_Sum_events_maps.sh

  # Create two files with filenames list of event-images and exposure-maps
  #
  print "# -> Querying archive for event-files:"
  EVENTSFILE="${TMPDIR}/${RUN_LABEL}_events.txt"
  select_event_files $DATA_ARCHIVE $OBSLIST $EVENTSFILE 2> FILES_not_FOUND.events.txt #2> $LOGFILE
  print "  EVENTSFILE="`cat $EVENTSFILE`

  print "# -> ..and exposure-maps:"
  EXMAPSFILE="${TMPDIR}/${RUN_LABEL}_expos.txt"
  select_exposure_maps $DATA_ARCHIVE $OBSLIST $EXMAPSFILE 2> FILES_not_FOUND.expomaps.txt #2> $LOGFILE
  print "  EXMAPSFILE="`cat $EXMAPSFILE`

  # Create XSelect and XImage scripts to sum event-files and exposure-maps
  #
  print "# -> Generating scripts for stacking data"
  XSELECT_SUM_SCRIPT="${TMPDIR}/events_sum.xcm"
  create_xselect_sum_script $RUN_LABEL $EVENTSFILE "./${EVENTSSUM_RESULT#$PWD}" $XSELECT_SUM_SCRIPT

  XIMAGE_SUM_SCRIPT="${TMPDIR}/expos_sum.xco"
  create_ximage_sum_script $RUN_LABEL $EXMAPSFILE "./${EXPOSSUM_RESULT#$PWD}" $XIMAGE_SUM_SCRIPT

  # Run the scripts
  #
  print "# -> Running XSelect (events concatenation).."
  xselect @"./${XSELECT_SUM_SCRIPT#$PWD}" #>> $LOGFILE
  print "# -> Running XImage (exposure-maps stacking).."
  ximage @"./${XIMAGE_SUM_SCRIPT#$PWD}" #>> $LOGFILE

  [[ -f xselect.log ]] && mv xselect.log $TMPDIR

  print "#..............................................................."
)

create_ximage_detbright_script(){
  EMIN="$1"
  EMAX="$2"
  EVENTS="$3"
  EXPMAP="$4"
  OUTFILE="$5"

  cat > $OUTFILE << EOF
read/size=1024/ecol=PI/emin=$EMIN/emax=$EMAX $EVENTS
read/size=1024/expo $EXPMAP
det/bright
quit
EOF
}

XSELECT_DET_DEFAULT="${EVENTSSUM_RESULT%.*}.det"
DET_TMPDIR="${TMPDIR}/${XSELECT_DET_DEFAULT##*/}"
XSELECT_DET_FULL="${DET_TMPDIR%.*}.full.det"
XSELECT_DET_SOFT="${DET_TMPDIR%.*}.soft.det"
XSELECT_DET_MEDIUM="${DET_TMPDIR%.*}.medium.det"
XSELECT_DET_HARD="${DET_TMPDIR%.*}.hard.det"
(
  # Here we use ximage to detect bright sources in the field;
  # "field" now is the result of all observations stacked,
  # event-files and exposure-maps.
  # We want to detect such (bright) sources using every photon
  # available, i.e., using the entire x-ray band (0.3keV to 10keV)
  #
  # The detections done using the *entire* energy, from 0.3keV to 10keV,
  # will be effectively used as "the objects" detected, and so listed
  # in the results. Nevertheless we run 'detect' for each band (keV 0.3-1, 1-2, 2-10)
  # because we want an estimate of the background on each corresponding band.
  # Such background level estimate will be used in the next step to adjust
  # the measurements in each band.
  #
  BLOCK='SOURCES_DETECTION'
  print "# Block (3) $BLOCK"
  cd $OUTDIR


  print "# -> Detecting bright sources in the FULL band (0.3-10keV).."
  XIMAGE_TMP_SCRIPT="${TMPDIR}/ximage.detect_full.xco"
  create_ximage_detbright_script 30 1000 \
                                "./${EVENTSSUM_RESULT#$PWD}" \
                                "./${EXPOSSUM_RESULT#$PWD}" \
                                "$XIMAGE_TMP_SCRIPT"
  ximage @"./${XIMAGE_TMP_SCRIPT#$PWD}" #>> $LOGFILE
  mv $XSELECT_DET_DEFAULT $XSELECT_DET_FULL

  print "# -> Detecting bright sources in the SOFT band (0.3-1keV).."
  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_soft.xco
  create_ximage_detbright_script 30 100 \
                                "./${EVENTSSUM_RESULT#$PWD}" \
                                "./${EXPOSSUM_RESULT#$PWD}" \
                                "$XIMAGE_TMP_SCRIPT"
  ximage @"./${XIMAGE_TMP_SCRIPT#$PWD}" #>> $LOGFILE
  mv $XSELECT_DET_DEFAULT $XSELECT_DET_SOFT

  print "# -> Detecting bright sources in the MEDIUM band(1-2keV).."
  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_medium.xco
  create_ximage_detbright_script 101 200 \
                                "./${EVENTSSUM_RESULT#$PWD}" \
                                "./${EXPOSSUM_RESULT#$PWD}" \
                                "$XIMAGE_TMP_SCRIPT"
  ximage @"./${XIMAGE_TMP_SCRIPT#$PWD}" #>> $LOGFILE
  mv $XSELECT_DET_DEFAULT $XSELECT_DET_MEDIUM

  print "# -> Detecting bright sources in the HARD band (2-10keV).."
  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_hard.xco
  create_ximage_detbright_script 201 1000 \
                                "./${EVENTSSUM_RESULT#$PWD}" \
                                "./${EXPOSSUM_RESULT#$PWD}" \
                                "$XIMAGE_TMP_SCRIPT"
  ximage @"./${XIMAGE_TMP_SCRIPT#$PWD}" #>> $LOGFILE
  mv $XSELECT_DET_DEFAULT $XSELECT_DET_HARD

  # rm $XIMAGE_TMP_SCRIPT
  print "#..............................................................."
)

(
  # And now, for each source detected previously by ximage:detect/bright
  # we estimate the source with ximage/sosta for each x-ray band.
  # Sosta will use the background estimate from the
  BLOCK='COUNTRATES_MEASUREMENT'
  print "# Block (4) $BLOCK"
  cd $OUTDIR

  source ${SCRPT_DIR}/module_Sosta_det2sosta.sh

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
            $XIMAGE_TMP_SCRIPT \
            'yes'
  ximage @"./${XIMAGE_TMP_SCRIPT#$PWD}" #>> $LOGFILE

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_soft.xco
  LOGFILE_SOFT="${TMPDIR}/sosta_soft.log"
  det2sosta $XSELECT_DET_FULL \
            $XSELECT_DET_SOFT 30 100 \
            $EXPOSSUM_RESULT \
            $LOGFILE_SOFT $CTS_DET_FULL \
            $RUN_LABEL \
            $XIMAGE_TMP_SCRIPT \
            'no'
  ximage @"./${XIMAGE_TMP_SCRIPT#$PWD}" #>> $LOGFILE

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_medium.xco
  LOGFILE_MEDIUM="${TMPDIR}/sosta_medium.log"
  det2sosta $XSELECT_DET_FULL \
            $XSELECT_DET_MEDIUM 101 200 \
            $EXPOSSUM_RESULT \
            $LOGFILE_MEDIUM $CTS_DET_FULL \
            $RUN_LABEL \
            $XIMAGE_TMP_SCRIPT \
            'no'
  ximage @"./${XIMAGE_TMP_SCRIPT#$PWD}" #>> $LOGFILE

  XIMAGE_TMP_SCRIPT=${XIMAGE_TMP_SCRIPT%_*.xco}_hard.xco
  LOGFILE_HARD="${TMPDIR}/sosta_hard.log"
  det2sosta $XSELECT_DET_FULL \
            $XSELECT_DET_HARD 201 1000 \
            $EXPOSSUM_RESULT \
            $LOGFILE_HARD $CTS_DET_FULL \
            $RUN_LABEL \
            $XIMAGE_TMP_SCRIPT \
            'no'
  ximage @"./${XIMAGE_TMP_SCRIPT#$PWD}" #>> $LOGFILE

  # rm $XIMAGE_TMP_SCRIPT

  # Countrates measured by Sosta are written in an non-tabular file,
  # we now read from this "logfile" and write to a table..
  #
  CTS_SOST_FULL="${TMPDIR}/countrates_full.sosta.txt"
  python ${SCRPT_DIR}/module_Sosta_log_to_table.py $LOGFILE_FULL '0.3-10keV' > $CTS_SOST_FULL

  CTS_SOST_SOFT="${TMPDIR}/countrates_soft.sosta.txt"
  python ${SCRPT_DIR}/module_Sosta_log_to_table.py $LOGFILE_SOFT '0.3-1keV' > $CTS_SOST_SOFT

  CTS_SOST_MEDIUM="${TMPDIR}/countrates_medium.sosta.txt"
  python ${SCRPT_DIR}/module_Sosta_log_to_table.py $LOGFILE_MEDIUM '1-2keV' > $CTS_SOST_MEDIUM

  CTS_SOST_HARD="${TMPDIR}/countrates_hard.sosta.txt"
  python ${SCRPT_DIR}/module_Sosta_log_to_table.py $LOGFILE_HARD '2-10keV' > $CTS_SOST_HARD

  # ..make it a CSV..
  COUNTRATES_SOSTA_TABLE="${COUNTRATES_TABLE%.*}.sosta.csv"
  COUNTRATES_SOSTA_TABLE="${TMPDIR}/${COUNTRATES_SOSTA_TABLE##*/}"
  paste $CTS_DET_FULL \
        $CTS_SOST_FULL \
        $CTS_SOST_SOFT \
        $CTS_SOST_MEDIUM \
        $CTS_SOST_HARD \
        > $COUNTRATES_SOSTA_TABLE
  # sed -i.bak 's/[[:space:]]/;/g' $COUNTRATES_SOSTA_TABLE

  # And finally adjust the (countrate) fluxes.
  # Such fix seems necessary because sosta returns lower (countrate) numbers
  # which we don't exactly know why. So we weight each band measurement
  # done by Sosta by the measurement done before by Detect/bright.
  #
  tail -n +2 $COUNTRATES_SOSTA_TABLE \
    | awk -f ${SCRPT_DIR}/module_Sosta_adjust_countrates.awk > $COUNTRATES_TABLE #2> $LOGFILE
  print "#..............................................................."
)

(
  # Here we take the countrates measurements from the last block,
  # saved in file '$COUNTRATES_TABLE', which are in units of `cts/s`,
  # and transform them to energy flux, in `erg/s/cm2`.
  # We will use Paolo's countrates code, which takes the integrated
  # (photon) flux, energy slope and transform it accordingly.
  #
  BLOCK='COUNTRATES_TO_FLUX'
  print "# Block (5) $BLOCK"
  cd $OUTDIR

  source ${SCRPT_DIR}/countrates.sh

  # For each detected source (each source is read from COUNTRATES_TABLE)
  # get its NH (given RA and DEC read from COUNTRATES_TABLE, use 'nh' tool)
  # define the middle band values (soft:0.5, medium:1.5, hard:5)
  # get the slope from swiftslope.py
  # input them all to 'countrates' to get nuFnu
  print "# -> Converting objects' flux.."

  echo -n "#RA;DEC;NH;ENERGY_SLOPE;ENERGY_SLOPE_ERROR"                                                                     > $FLUX_TABLE
  echo -n ";nufnu_5keV(erg.s-1.cm-2);nufnu_error_5keV(erg.s-1.cm-2)"                                          >> $FLUX_TABLE
  echo -n ";nufnu_0.5keV(erg.s-1.cm-2);nufnu_error_0.5keV(erg.s-1.cm-2);upper_limit_0.5keV(erg.s-1.cm-2)"       >> $FLUX_TABLE
  echo -n ";nufnu_1.5keV(erg.s-1.cm-2);nufnu_error_1.5keV(erg.s-1.cm-2);upper_limit_1.5keV(erg.s-1.cm-2)" >> $FLUX_TABLE
  echo    ";nufnu_4.5keV(erg.s-1.cm-2);nufnu_error_4.5keV(erg.s-1.cm-2);upper_limit_4.5keV(erg.s-1.cm-2)"       >> $FLUX_TABLE

  for DET in `tail -n +2 $COUNTRATES_TABLE`; do
    IFS=';' read -a FIELDS <<< "${DET}"

    # RA and Dec are the first two columns (in COUNTRATES_TABLE);
    # they are colon-separated, which we have to substitute by spaces
    #
    RA=${FIELDS[0]}
    DEC=${FIELDS[1]}
    coords=$(bash ${SCRPT_DIR}/sex2deg.sh "$RA" "$DEC" | tail -n1)
    ra=$(echo $coords | cut -d' ' -f1)
    dec=$(echo $coords | cut -d' ' -f2)

    # NH comes from ftool's `nh` tool
    #
    NH=$(nh 2000 $ra $dec | tail -n1 | awk '{print $NF}')
    print -n "    RA=$RA DEC=$DEC NH=$NH"

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
      # print " # ENERGY_SLOPE was changed because estimate error was too big (>0.8)"
    fi
    print " ENERGY_SLOPE=$ENERGY_SLOPE"

    for BAND in `energy_bands list`; do
      # echo "#  -> Running band: $BAND"
      NUFNU_FACTOR=$(run_countrates $BAND $ENERGY_SLOPE $NH)
      print "      BAND=$BAND NUFNU_FACTOR=$NUFNU_FACTOR"
      case $BAND in
        soft)
          FLUX_SOFT=$(echo "$NUFNU_FACTOR $CT_SOFT" | awk '{print $1*$2}')
          FLUX_SOFT_ERROR=$(echo "$NUFNU_FACTOR $CT_SOFT_ERROR" | awk '{print $1*$2}')
          if [ $(is_null $CT_SOFT_UL) == 'yes' ]; then
            FLUX_SOFT_UL=$CT_SOFT_UL
          else
            FLUX_SOFT_UL=$(echo "$NUFNU_FACTOR $CT_SOFT_UL" | awk '{print $1*$2}')
          fi
          print "      FLUX_SOFT=$FLUX_SOFT FLUX_SOFT_ERROR=$FLUX_SOFT_ERROR FLUX_SOFT_UL=$FLUX_SOFT_UL"
          ;;
        medium)
          FLUX_MEDIUM=$(echo "$NUFNU_FACTOR $CT_MEDIUM" | awk '{print $1*$2}')
          FLUX_MEDIUM_ERROR=$(echo "$NUFNU_FACTOR $CT_MEDIUM_ERROR" | awk '{print $1*$2}')
          if [ $(is_null $CT_MEDIUM_UL) == 'yes' ]; then
            FLUX_MEDIUM_UL=$CT_MEDIUM_UL
          else
            FLUX_MEDIUM_UL=$(echo "$NUFNU_FACTOR $CT_MEDIUM_UL" | awk '{print $1*$2}')
          fi
          print "      FLUX_MEDIUM=$FLUX_MEDIUM FLUX_MEDIUM_ERROR=$FLUX_MEDIUM_ERROR FLUX_MEDIUM_UL=$FLUX_MEDIUM_UL"
          ;;
        hard)
          FLUX_HARD=$(echo "$NUFNU_FACTOR $CT_HARD" | awk '{print $1*$2}')
          FLUX_HARD_ERROR=$(echo "$NUFNU_FACTOR $CT_HARD_ERROR" | awk '{print $1*$2}')
          if [ $(is_null $CT_HARD_UL) == 'yes' ]; then
            FLUX_HARD_UL=$CT_HARD_UL
          else
            FLUX_HARD_UL=$(echo "$NUFNU_FACTOR $CT_HARD_UL" | awk '{print $1*$2}')
          fi
          print "      FLUX_HARD=$FLUX_HARD FLUX_HARD_ERROR=$FLUX_HARD_ERROR FLUX_HARD_UL=$FLUX_HARD_UL"
          ;;
        full)
          FLUX_FULL=$(echo "$NUFNU_FACTOR $CT_FULL" | awk '{print $1*$2}')
          FLUX_FULL_ERROR=$(echo "$NUFNU_FACTOR $CT_FULL_ERROR" | awk '{print $1*$2}')
          print "      FLUX_FULL=$FLUX_FULL FLUX_FULL_ERROR=$FLUX_FULL_ERROR"
          ;;
      esac
    done
    ENERGY_SLOPE_ERROR="${ENERGY_SLOPE_plus}/${ENERGY_SLOPE_minus}"
    echo -n "${RA};${DEC};${NH};${ENERGY_SLOPE};${ENERGY_SLOPE_ERROR}">> $FLUX_TABLE
    echo -n ";${FLUX_FULL};${FLUX_FULL_ERROR}"                        >> $FLUX_TABLE
    echo -n ";${FLUX_SOFT};${FLUX_SOFT_ERROR};${FLUX_SOFT_UL}"        >> $FLUX_TABLE
    echo -n ";${FLUX_MEDIUM};${FLUX_MEDIUM_ERROR};${FLUX_MEDIUM_UL}"  >> $FLUX_TABLE
    echo    ";${FLUX_HARD};${FLUX_HARD_ERROR};${FLUX_HARD_UL}"        >> $FLUX_TABLE
  done
  sed -i.bak 's/[[:space:]]/;/g' $FLUX_TABLE
  print "#..............................................................."
)

# Finally, let's zip some files..
gzip $EVENTSSUM_RESULT
gzip $EXPOSSUM_RESULT
(
  cd ${TMPDIR}/..
  TMPDIR=$(basename ${TMPDIR})
  tar -czf ${TMPDIR}.tgz ${TMPDIR} && rm -rf $TMPDIR
)

echo "# ---"
echo "# Pipeline finished. Final table: '$FLUX_TABLE'"
echo "# ---"
