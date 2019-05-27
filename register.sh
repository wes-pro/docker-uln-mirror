#!/bin/bash
#
# Author: Michal Wesolowski (http://mwesolowski.com)
#

if [ $# -ne 1 ]; then
  echo Provide directory path where YUM repositories will be kept
  exit 1
fi

export YUM_DIRECTORY="$1"

mkdir -p /${YUM_DIRECTORY}/conf
mkdir -p /${YUM_DIRECTORY}/repos
mkdir -p /${YUM_DIRECTORY}/persist
mkdir -p /${YUM_DIRECTORY}/cache

cat >/${YUM_DIRECTORY}/conf/yum.conf <<EOF
[main]
logfile=/var/log/yum.log
gpgcheck=1
plugins=1
pluginconfpath=${YUM_DIRECTORY}/conf
persistdir=${YUM_DIRECTORY}/persist
cachedir=${YUM_DIRECTORY}/cache
EOF

cat >${YUM_DIRECTORY}/conf/rhnplugin.conf <<EOF
[main]
enabled=1
gpgcheck=1
EOF

cat >${YUM_DIRECTORY}/conf/ulninfo.conf <<EOF
[main]
enabled=1
gpgcheck=1
EOF

cat >${YUM_DIRECTORY}/conf/ovl.conf <<EOF
[main]
enabled=1
EOF

docker build -t uln-mirror:latest .

selinuxenabled
if [ $? -eq 0 ]; then
  chcon -Rt svirt_sandbox_file_t ${YUM_DIRECTORY}
fi

docker run -it --rm  \
  -h "uln-mirror" \
  -e YUM_DIRECTORY="${YUM_DIRECTORY}" \
  -v ${YUM_DIRECTORY}:/${YUM_DIRECTORY} \
  uln-mirror:latest register

if [ $? -eq 0 ]; then

cat <<EOF

Docker image "uln-mirror" created. 

If you haven't done so yet, put repo names you want to download into 
${YUM_DIRECTORY}/conf/repo_list file and rerun register.sh script.
You can find list of all available repositories in this file: ${YUM_DIRECTORY}/conf/repo_available

Then run below command to start docker and which will download selected repositories: 
./download.sh ${YUM_DIRECTORY}

EOF

fi
