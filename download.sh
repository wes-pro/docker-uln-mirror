#!/bin/bash
#
# Author: Michal Wesolowski (http://mwesolowski.com)
#

if [ $# -ne 1 ]; then
  echo Provide directory path where YUM repositories will be kept
  exit 1
fi

export YUM_DIRECTORY="$1"

selinuxenabled
if [ $? -eq 0 ]; then
  chcon -Rt svirt_sandbox_file_t ${YUM_DIRECTORY}
fi

docker run -d --rm  \
  -h "uln-mirror" \
  -e YUM_DIRECTORY="${YUM_DIRECTORY}" \
  -v "${YUM_DIRECTORY}":"${YUM_DIRECTORY}" \
  uln-mirror:latest 
