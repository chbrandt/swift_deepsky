#!/usr/bin/env bash
set -u

CURDIR=$(cd `dirname $BASH_SOURCE`; pwd)

VERBOSE="1"

# Number of procs
#
NPROCS=1

# GetOptions..
#
while getopts ":hqn:f:d:" opt
do
case $opt in
  h) echo ""
   echo " Usage: $(basename $0) [-n ] -f "
   echo ""
   echo " Options:"
   echo " -h : this help message"
   echo " -n : number or processors to use [default: 1]"
   echo " -f : observations list file"
   echo " -d : root data archive directory"
   echo " -q : quiet run"
   echo ""
   exit 0;;
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
echo "Error: None Observations-list file given. See '$(basename $0) -h'"
exit 1
fi

if [ ! -f "$OBSLIST" ]
then
echo ""
echo "ERROR: file $OBSLIST does not exist. Finishing."
exit 2
fi

#===========================
# Check PID..
#
check_process(){
kill -0 $1 2>/dev/null
echo $?
}
#===========================

# Read pipeline file names of each selected Halo..
#
fcnt=0
file=()
for fini in `cat $OBSLIST`
do
  fcnt=$((fcnt+1))
  file[$fcnt]=$fini
done

[ "$VERBOSE" = "1" ] && echo "Number of Observations $fcnt"

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
    IFS='/' read -ra FLDS <<< ${file[$ncnt]}
    IFS=$OIFS

    # ${SCRIPT} --file=${file[$ncnt]} &
    sleep 2
    ${CURDIR}/download.sh -d ${FLDS[0]} -o ${FLDS[1]} -a ${DATA_ARCHIVE} &

    PID=$!
    # [ "$VERBOSE" = "1" ] && { echo "Downloading observation '${file[$ncnt]}'"; echo "PID: $PID"; }
    PIDs[$PID]=$PID
    CNTs[$PID]=$ncnt
    cd - &> /dev/null

    echo ""

  else
    sleep 10
  fi


  for PID in ${PIDs[*]};
  do

    if [ "$(check_process $PID)" -ne "0" ]
    then
    unset PIDs[$PID]
    unset CNTs[$PID]
    [ "$VERBOSE" = "1" ] && echo "Process $PID is finished"
    fi
  done

  [ "$ncnt" -eq "$fcnt" -a "${#PIDs[*]}" -eq "0" ] && break

done

# End
