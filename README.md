# docker-uln-mirror
#### Oracle ULN mirror inside docker - works on Redhat/CentOS/Oracle Linux 7

Officially you need Oracle Linux to create your [local ULN YUM mirror](https://www.oracle.com/technetwork/articles/servers-storage-admin/yum-repo-setup-1659167.html). 
This is sometimes not possible or unconvenient, for example if you are Oracle Exadata customer, so you have Oracle Linux only on Exadata and your other linux systems are Redhat.

Luckily Oracle created [official docker image for Oracle Linux 7](https://hub.docker.com/_/oraclelinux/) which can be used on non-Oracle Linux like RHEL or CentOS.
I'm using this image to download repositories from https://linux.oracle.com (ULN).

### Requirements
1. Linux system with docker service installed and running
1. Some space on your host to hold the mirror
1. Valid support contract with Oracle (CSI) and an Oracle account associated with it

### How to use this docker
Just clone repository to temporary folder and run:
```
./register.sh <yum_mirror_root>
```
You will be asked for your Oracle credentials and CSI. Command will create and start docker - just to register it in ULN. 
Registration data (your systemid file) will be kept in <yum_mirror_root>/conf directory.

Edit <yum_mirror_root>/conf/repo_list file by writing repositories you need to download. You can find all of them in repo_available 
file created in the same directory.

Re-run ./register.sh <yum_mirror_root> again. This is necessery to add repositories (i.e. channels) to your ULN host.
This would not be necessery if you created <yum_mirror_root>/conf/repo_list before first step (i.e. executing register.sh)

Run this command to start download:
```
./download.sh <yum_mirror_root>
```

You should be able to interrupt (stop) the container and re-run download.sh or register.sh scripts as many times as you like - as long as you don't remove <yum_mirror_root>/conf/systemid.
Re-runninig register.sh script is only necessery if you change list of mirrored repositories or if you decide to start from scratch.
In second case - remember that if you delete systemid file your deleted docker will remain registered in Oracle ULN portal but you will no longer be able to use it.
You can always remove this artefact by navigating to https://linux.oracle.com
