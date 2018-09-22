#!/usr/bin/env bash
set -ue

CURDIR=$(cd `dirname $BASH_SOURCE`; pwd)

# Directory of Swift data archive; where swift 'data' directory tree is.
# For example, "/.../path/.../swift"
#
DATA_ARCHIVE="${PWD}"

DATA_SERVER='UK'

# By default, be verbose
#
VERBOSE="1"

# Number of CPUs
#
NPROCS=1

# List of Observations (init null)
#
OBSLIST=''

TMPDIR="${PWD}"

# GetOptions..
#
while getopts ":hqn:f:d:s:" opt
do
  case $opt in
    h) echo ""
     echo " Usage: $(basename $0) [-n ] -f <OBS_LIST>"
     echo ""
     echo " Options:"
     echo " -h : this help message"
     echo " -d : data archive directory, where 'swift' directory is seated"
     echo " -f : file with observations list in the format 'OBSID/DATE';"
     echo "     E.g,"
     echo "$ cat > OBS_LIST << EOF"
     echo "2006_03/00035393001"
     echo "2006_03/00035063020"
     echo "EOF"
     echo " -n : number or processors to use (default=1)"
     echo " -q : quiet run"
     echo " -s : archive server, where options are 'UK', 'US'"
     echo ""
     exit 0;;
    s) DATA_SERVER=$OPTARG;;
    q) VERBOSE="0";;
    n) NPROCS="$OPTARG";;
    f) OBSLIST="$OPTARG";;
    d) DATA_ARCHIVE="$OPTARG";;
    \?) echo "ERROR: Wrong option $OPTARG ";;
    :) echo "ERROR: Missing value for $OPTARG ";;
  esac
done

if [ -z "$OBSLIST" ]
then
echo "ERROR: None Observations-list file given. See '$(basename $0) -h'"
exit 1
fi

if [ ! -f "$OBSLIST" ]
then
echo ""
echo "ERROR: file $OBSLIST does not exist. Finishing."
exit 2
fi


SWIFT_ARCHIVE="${DATA_ARCHIVE}"


#===========================
# Check PID..
#
check_process(){
kill -0 $1 2>/dev/null
echo $?
}
#===========================

# =====================================================================
# Read pipeline file names of each selected Halo..
#
fcnt=0
file=()
for fini in `cat $OBSLIST`
do
  fcnt=$((fcnt+1))
  file[$fcnt]=$fini
done

[ "$VERBOSE" = "1" ] && echo "# Number of Observations $fcnt"

# Check if any halo was found. If not, finish the run..
#
[ "$fcnt" -eq "0" ] && { echo "Empty list of observation?"; exit; }

# Start the distribution of jobs..
#
PIDs=()
ncnt=0

while [ "$ncnt" -le "$fcnt" ]
do

  if [ ${#PIDs[*]} -lt $NPROCS -a "$ncnt" -lt "$fcnt" ]
  then

    ncnt=$((ncnt+1))
    # mkdir $ncnt
    # cd $ncnt

    # ln -s ../${file[$ncnt]} ${file[$ncnt]}
    OIFS=$IFS
    IFS='/' read -ra FLDS <<< "${file[$ncnt]}"
    IFS=$OIFS

    DATE=${FLDS[0]}
    OBSID=${FLDS[1]}

    # # ${SCRIPT} --file=${file[$ncnt]} &
    # # ${CURDIR}/download.sh -d ${DATE} -o ${OBSID} -a ${DATA_ARCHIVE} &
    # DESTDIR="${SWIFT_ARCHIVE}"
    #
    # [[ -d ${DESTDIR}/${OBSID} ]] && continue
    #
    # [[ -d $DESTDIR ]] || mkdir -p $DESTDIR

    # TARBALL="${TMPDIR}/${OBSID}.tar"

    #${CURDIR}/download_swift_asdc.pl ${OBSID} \
    #                                 ${DATE} \
    #                                 ${TARBALL} \
    #                                 ${DESTDIR} &

    if [[ "$DATA_SERVER" == 'UK' ]]; then
      ${CURDIR}/download_swift_leicester.sh -o ${OBSID} \
                                            -d ${DATE} \
                                            -a ${SWIFT_ARCHIVE} &
    else
      # assert [ $DATA_SERVER == 'US' ]
      ${CURDIR}/download_swift_nasa.sh -o ${OBSID} \
                                       -d ${DATE} \
                                       -a ${SWIFT_ARCHIVE} &
    fi

    PID=$!
    PIDs[$PID]=$PID
    CNTs[$PID]=$ncnt
    # Since we gave $DESTDIR above, we may now delete the tarball
    # [ -f $TARBALL ] && rm $TARBALL

    echo ""

  else
    sleep 1
  fi

  [ "$ncnt" -eq "$fcnt" -a "${#PIDs[@]}" -eq "0" ] && break

  for PID in ${PIDs[*]};
  do
    if [ "$(check_process $PID)" -ne "0" ]; then
      _cnt=${CNTs[$PID]}
      _file=${file[$_cnt]}

      wait $PID
      PSTS=$?
      if [[ $PSTS -eq 0 ]]; then
        # [ "$VERBOSE" = "1" ] && \
        echo "Processing of '$_file' was successfully finished"
      else
        # [ "$VERBOSE" = "1" ] && \
        1>&2 echo "Processing of '$_file' failed"
      fi
      unset PIDs[$PID]
      unset CNTs[$PID]
    fi
  done

done
