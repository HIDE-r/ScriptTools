#!/usr/bin/bash

# server
server_ip=
port=
password=

#local
local_ip=127.0.0.1
local_port=1080

# 检测参数
if [[ $# != 1 ]] || [[ -z $1 ]]
then
	echo './brook.sh <on/off>';
fi


case $1 in
	"on" )
		echo "brook on...";
		brook client -s $server_ip:$port -p $password --socks5 $local_ip:$local_port > /dev/null 2>&1 &
        export proxy="socks5://$local_ip:$local_port";
		export http_proxy=$proxy;
		export https_proxy=$proxy;
		export ftp_proxy=$proxy;
		export ALL_PROXY=$proxy;
		export no_proxy="localhost, 127.0.0.1, ::1";
		;;
	"off" )
		echo "brook off...";
		killall -9 brook
		unset http_proxy;
		unset https_proxy;
		unset ftp_proxy;
		unset ALL_PROXY;
		unset no_proxy;
		;;
esac
