#!/usr/bin/env bash

help(){
  echo ""
  echo "Usage:"
  echo "  basename $BASH_SOURCE [--with-docker]"
  echo ""
  echo " Option 'with-docker' will setup the 'docker-heasoft' cli."
  echo ""
  echo " If you don't have HEASoft installed, but do have Docker,"
  echo " this option is for you."
  echo " In such case, before running the pipeline, make sure you"
  echo " have the docker 'chbrandt/heasoft' image:"
  echo ""
  echo " # docker pull chbrandt/heasoft"
  echo ""
}

WITH_DOCKER='no'

while [[ $# -gt 0 ]]
do
  case $1 in
    -h|--help)
      help; exit 0;;
    --with-docker)
      WITH_DOCKER='yes';;
    --*)
      1>&2 echo "Error: Unrecognized option. Try '--help'."
      exit 1;;
    *)
      break;;
  esac
  shift
done

# Compile countrates
source bin/countrates/compile.sh &> bin/countrates/compile.log
[[ $? -eq 0 ]] || exit 1;

# Set docker-heasoft cli
[[ $WITH_DOCKER == 'yes' ]] && bash docker/install.sh


echo "#================================================================="
echo "# Run the following line to make swift-deepsky pipeline available"
echo "# on your environment:"
echo "#----------"
echo "export PATH=\"${PWD}/bin:\$PATH\""
echo "#----------"
echo "#================================================================="
