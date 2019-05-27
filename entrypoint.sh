#!/bin/bash
#
# Author: Michal Wesolowski (http://mwesolowski.com)
#

export YUMDIR=${YUM_DIRECTORY:-/yum}

function register {
  while true; do
    echo -n "Your ULN username: "
    read uln_user
    echo -n "Your ULN password: "
    read -s uln_password
    echo
    rhn_check >/dev/null
    if [ $? -ne 0 ]; then
      echo -n "Your CSI: "
      read uln_csi
      echo "Registering your system... Please wait..."
      ulnreg_ks --username "${uln_user}" --password "${uln_password}" --csi "${uln_csi}" --nohardware --nopackages --norhnsd --novirtinfo 
      if [ $? -eq 0 ]; then
        echo "Successfully registered your system. File: ${YUMDIR}/conf/systemid has been created."
        uln-channel --enable-yum-server
        uln-channel -u "${uln_user}" -p "${uln_password}" -L >${YUMDIR}/conf/repo_available
        echo "List of available repositories has been written to ${YUMDIR}/conf/repo_available"
        break
      fi
    else
      break
    fi
  done
  if [[ -f ${YUMDIR}/conf/repo_list ]]; then
    for channel in $(uln-channel -l | fgrep -vf /yum/conf/repo_list); do
      rem_channel_args="$rem_channel_args -c $channel"
    done
    uln-channel -r -u $"${uln_user}" -p "${uln_password}" $rem_channel_args
    while read channel; do
      add_channel_args="$add_channel_args -c $channel"
    done <${YUMDIR}/conf/repo_list
    uln-channel -a -u $"${uln_user}" -p "${uln_password}" $add_channel_args
    echo "Subscribed to repositories:"
    uln-channel -l
  fi
}

function download {
  rhn_check >/dev/null
  if [ $? -ne 0 ]; then
    echo "You need to register the system first. Run docker with 'register' argument first."
    exit 1
  fi 
  if [[ -f ${YUMDIR}/conf/repo_list ]]; then
    while read channel; do
      sync_channel_args="$sync_channel_args -r $channel"
    done <${YUMDIR}/conf/repo_list
    reposync -c ${YUMDIR}/conf/yum.conf -l -m --download-metadata -p ${YUMDIR}/repos $sync_channel_args
  fi
}

# MAIN

sed -i 's|^systemIdPath=.*$|systemIdPath='${YUMDIR}'/conf/systemid|g' /etc/sysconfig/rhn/up2date

if [ "$1" = 'register' ]; then
  register
elif [ "$1" = 'download' ]; then
  download
else
  exec "$@"
fi
