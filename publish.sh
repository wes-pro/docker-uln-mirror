#!/bin/bash
#
# Author: Michal Wesolowski (http://mwesolowski.com)
#

if [ $# -ne 1 ]; then
  echo Provide name of docker volume.
  exit 1
fi

export VOLNAME="$1"

docker run -d --rm \
  -h "uln-mirror" \
  --name "uln-mirror-nginx" \
  -p 8080:80 \
  -v `pwd`/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v ${VOLNAME}:/usr/share/nginx/html:ro \
  -d nginx
