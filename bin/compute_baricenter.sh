#!/usr/bin/env bash
set +ue

read_ra() {
    fkeyprint "$1"+1 RA_PNT exact=yes | grep "^RA" | awk '{printf "%f",$3}'
}

read_dec() {
    fkeyprint "$1"+1 DEC_PNT exact=yes | grep "^DEC" | awk '{printf "%f",$3}'
}

compute_baricenter() {
  local EVENTSFILE=$1
  # Compute RA,Dec center for events/expomaps stacking
  #
  declare -a EXPOSURES=$(cat $EVENTSFILE | xargs -n1 -P1 -I{} fkeyprint {}+1 EXPOSURE exact=yes | grep "^EXPOSURE" | awk '{printf "%d\n",$2}')

  declare -a RAS=$(cat $EVENTSFILE | xargs -n1 -P1 -I{} fkeyprint {}+1 RA_PNT exact=yes | grep "^RA" | awk '{printf "%f\n",$3}')

  declare -a DECS=$(cat $EVENTSFILE | xargs -n1 -P1 -I{} fkeyprint {}+1 DEC_PNT exact=yes | grep "^DEC" | awk '{printf "%f\n",$3}')

  local CENTER=$(python ${SCRPT_DIR}/compute_weight_coordinates.py \
                    --expos ${EXPOSURES[@]} --ras ${RAS[@]} --decs ${DECS[@]})
  echo "$CENTER"
}
