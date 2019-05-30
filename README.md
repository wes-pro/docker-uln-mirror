# docker-uln-mirror
#### Oracle ULN mirror inside docker - works on Redhat/CentOS/Oracle Linux 7

Officially you need Oracle Linux to create your [local ULN YUM mirror](https://www.oracle.com/technetwork/articles/servers-storage-admin/yum-repo-setup-1659167.html). 
This is sometimes not possible or unconvenient, for example if you are Oracle Exadata customer, so you have Oracle Linux only on Exadata and your other linux systems are Redhat, SuSE or Debian.

Luckily Oracle created [official docker image for Oracle Linux 7](https://hub.docker.com/_/oraclelinux/) which can be used on any non-Oracle Linux which have docker installed.
I'm using this image to setup local mirror for ULN repositories available on https://linux.oracle.com.

### Requirements
1. Linux system with docker service installed and running. 
1. Internet access - from the same host - to download docker images from registry.
1. Some space on your host to hold downloaded repositories
1. Valid support contract with Oracle (CSI) and an Oracle account associated with it

### How to use this docker

#### Step 1 - register your docker as host/system known to ULN:
First clone repository to temporary folder:
```
git clone https://github.com/wes-pro/docker-uln-mirror.git
cd docker-uln-mirrors
```
and modify repo_list file where you need to put all repositories you need to download from ULN. You can check out content of list_available file where I put all repos available when I created this README. 

Then execute register.sh script providing name of new (or existing, see later comments) docker volume as parameter:
```
./register.sh <volume_name>
```
You will be asked for your Oracle credentials and CSI. Script will create docker volume (a) docker image (b) and start docker container (c) out of it - just to register it in ULN. Docker container will be removed after registration (i.e. after register.sh script finishes) but generated host identity data (systemid file) will be kept in docker volume in the ./conf directory. In the same directory you will find updated repo_avaiable with full list of currently available ULN channels (i.e. repositories).

You can always re-run register.sh script if you wish. One reason is when you need to modify repo_list file. If you provide the same docker volume name - you will only be asked for credentials (required to change channel list in ULN) but not for CSI. You modify repo_list on host (not inside the volume) - it will be copied into volume by the script.

#### Step 2 - download repositories/channels listed in repo_list file.
Run this command to start download (provide the same docker volume as parameter):
```
./download.sh <volume_name>
```
This will start container out of the same docker image and will start download repositories to your docker volume. The container is started in the background and will not be removed after finishes. This is to allow checking docker logs (docker logs <container_id>) where you will see output from reposync and other commands.

#### Step 3 - publish downloaded repositories using NGINX (http server):
Third script is using nginx docker image to create container which will mount (as read-only) the same docker volume and will start publishing content of repositories on http/8080 port. Just run:
```
./publish <volume_name>
```
You can execute this script even while download is still in progress and check using browser what has been downloaded so far. But repositories will not be usable until download finishes entirely.

There is no script to stop NGINX container. Just use docker commands:
```
docker stop <containerid>
```

#### Remarks:
You should be able to interrupt (stop) the container and re-run download.sh or register.sh scripts as many times as you like - as long as you use the same docker volume which holds registration data. Re-runninig register.sh script is only necessery if you change list of mirrored repositories (repo_list file) or if you decide to start from scratch.

In second case - remember that if you use different docker volume - it will create new registration and new systemid file will be generated. If you login into ULN - you will see another system under the same name (I hard-coded 'uln-mirror' hostname in the scripts - but you can easily change it).
You can always remove these duplicated systems by navigating to https://linux.oracle.com.
