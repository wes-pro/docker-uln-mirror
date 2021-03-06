#!/bin/bash
#
# Author: Michal Wesolowski (http://mwesolowski.com)
#

if [ $# -ne 1 ]; then
  echo Provide name of docker volume.
  exit 1
fi

export VOLNAME="$1"

docker run -d \
  -h "uln-mirror" \
  --name "uln-mirror" \
  -v ${VOLNAME}:/uln \
  uln-mirror:latest 
