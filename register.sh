#!/bin/bash
#
# Author: Michal Wesolowski (http://mwesolowski.com)
#

if [ $# -ne 1 ]; then
  cat <<EOF
  The only input parameter is the name of docker volume where repositories will be kept.
  If volume already exists it will NOT be overwritten. 

  You should also amend repo_list file and put channels you need to download from ULN
  Re-running this script with existing volume - is the way to modify list of downloaded repositories.
EOF
  exit 1
fi

export VOLNAME="$1"

# Pull oracleliunux image from repositories
docker inspect oraclelinux >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
	docker pull oraclelinux:latest || { echo 'Could not find or download oraclelinux docker image'; exit 1; }
fi

# Create docker volume to keep persistent data
docker volume create ${VOLNAME}

# Create docker image to handle repo synchronization
docker build -t uln-mirror:latest .

# Run container to register or setup your ULN mirror 

docker run -it --rm \
  -h "uln-mirror" \
  -v ${VOLNAME}:/uln \
  uln-mirror:latest register

if [ $? -eq 0 ]; then
	cat <<-EOF

  Docker image "uln-mirror" and volume "$VOLNAME" created. 

  If you haven't done so yet, put channel names you want to download into 
  repo_list file and rerun register.sh script with the same volume name. 
  You can find list of all available repositories in repo_available file.
  Re-running register.sh script with existing volume - still asks for username
  and password - these are required by uln-channel to modify channel list.

  Then run below command to start docker and which will download selected repositories: 
  ./download.sh <volume-name>

  To publish downloaded repositories using HTTP server start another docker using:
  ./publish.sh <volume-name>

	EOF

fi
