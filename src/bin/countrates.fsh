energy_bands() {
  # Arguments:
  # $1) BAND is one of 'soft','medium','hard'
  # $2) OPTE is 'min','max' or 'eff'
  #     If "$2" is not given, return all values associated with 'BAND'
  #
  # Particularly, if "$1" is "list", list the energy bands
  [[ ${#@} -eq 0 ]] && return 1

  local -a ENERGY_BANDS
  ENERGY_BANDS[0]='0.3 5.0 10.0'
  ENERGY_BANDS[1]='0.3 0.5 1.0'
  ENERGY_BANDS[2]='1.0 1.5 2.0'
  ENERGY_BANDS[3]='2.0 4.5 10.0'

  local BAND=$1
  # BAND=${BAND,,}

  # [[ $BAND == list ]] && { echo "${!ENERGY_BANDS[@]}"; return 0; }
  [[ $BAND == list ]] && { echo "full soft medium hard"; return 0; }
  [[ ${#@} -lt 2 ]] && { 1>2 echo "Wrong number of arguments"; return 0; }
  case $BAND in
    full)
      iBAND=0;;
    soft)
      iBAND=1;;
    medium)
      iBAND=2;;
    hard)
      iBAND=3;;
    *)
      1>2 echo "Worng option for band: $BAND"
      return 0;;
  esac


  local OPTE=$2

  read -a VALS <<< "${ENERGY_BANDS[$iBAND]}"
  local VAL
  case $OPTE in
    min) VAL=${VALS[0]};;
    eff) VAL=${VALS[1]};;
    max) VAL=${VALS[2]};;
  esac
  unset VALS
  echo $VAL
}

run_countrates() {
  local BAND=$1
  local SLOPE=$2
  local NH=$3
  local SAT
  case $BAND in
    full)   SAT=25;;
    soft)   SAT=26;;
    medium) SAT=27;;
    hard)   SAT=28;;
  esac
  local EFFE=$(energy_bands $BAND eff)
  local EMIN=$(energy_bands $BAND min)
  local EMAX=$(energy_bands $BAND max)
  (
    cd "${SCRPT_DIR}/countrates"
    CTS_IN=${TMPDIR}/countrates.in
    CTS_OUT="${CTS_IN%.in}.out"
    echo -e "$SAT\n$EMIN $EMAX\n$EFFE\n1\n1\n$SLOPE\n$NH\nemitted\n0" > $CTS_IN
    # ./countrates < $CTS_IN > $CTS_OUT
    # local NUFNU=$(grep "nuFnu" $CTS_OUT | tail -n1 | awk '{print $(NF-1)}')
    local NUFNU=$(./countrates < $CTS_IN | grep "nuFnu" | tail -n1 | awk '{print $(NF-1)}')
    echo $NUFNU
  )
}
is_null() {
  local VAL=$1
  local NULL=-999
  echo "$VAL $NULL" | awk '{if($1==$2){print "yes"}else{print "no"}}'
}
