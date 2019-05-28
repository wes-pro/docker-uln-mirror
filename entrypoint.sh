#!/bin/bash
#
# Author: Michal Wesolowski (http://mwesolowski.com)
#

voldir=/uln

function initialize_dirs {
	for dir in conf persist cache repos; do
		[[ -d $voldir/$dir ]] || mkdir -p $voldir/$dir
	done
        [[ -f /repo_list ]] && mv /repo_list $voldir/conf/
	[[ -f $voldir/conf/yum.conf ]] || {
		cat > $voldir/conf/yum.conf <<-EOF
		[main]
		logfile=/var/log/yum.log
		gpgcheck=1
		plugins=1
		pluginconfpath=$voldir/conf
		persistdir=$voldir/persist
		cachedir=$voldir/cache
		EOF
	}
	for file in rhnplugin.conf ulninfo.conf ovl.conf; do
		[[ -f $voldir/conf/$file ]] || {
			cat > $voldir/conf/$file <<-EOF
			[main]
			enabled=1
			gpgcheck=1
			EOF
		}
	done
}

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
				echo "Successfully registered your system. File: $voldir/conf/systemid has been created."
				uln-channel --enable-yum-server
				uln-channel -u "${uln_user}" -p "${uln_password}" -L >$voldir/conf/repo_available
				echo "List of available repositories has been written to $voldir/conf/repo_available"
				break
			fi
		else
			break
		fi
	done
	if [[ -f $voldir/conf/repo_list ]]; then
		for channel in $(uln-channel -l | fgrep -vf $voldir/conf/repo_list); do
			rem_channel_args="$rem_channel_args -c $channel"
		done
		[[ -n $rem_channel_args ]] && uln-channel -r -u $"${uln_user}" -p "${uln_password}" $rem_channel_args
		while read channel; do
				add_channel_args="$add_channel_args -c $channel"
		done <$voldir/conf/repo_list
		uln-channel -a -u $"${uln_user}" -p "${uln_password}" $add_channel_args
		echo
		echo Subscribed to repositories:
		uln-channel -l
	fi
}

function download {
	rhn_check >/dev/null
	if [ $? -ne 0 ]; then
		echo "You need to register the system first. Run docker with 'register' argument first."
		exit 1
	fi 
	if [[ -f $voldir/conf/repo_list ]]; then
		while read channel; do
			sync_channel_args="$sync_channel_args -r $channel"
		done <$voldir/conf/repo_list
		reposync -c $voldir/conf/yum.conf -l -m --download-metadata -p $voldir/repos $sync_channel_args
	fi
	for repo in $(cat $voldir/conf/repo_list); do
		if [[ -f $voldir/repos/$repo/comps.xml ]]; then
			createrepo -v -g comps.xml $voldir/repos/$repo
		else
			createrepo -v $voldir/repos/$repo
		fi	
	done
}

# MAIN

sed -i 's|^systemIdPath=.*$|systemIdPath='$voldir'/conf/systemid|g' /etc/sysconfig/rhn/up2date

if [ "$1" = 'register' ]; then
	initialize_dirs
	register
elif [ "$1" = 'download' ]; then
	download
else
	exec "$@"
fi
