#!/sbin/bash

while true
do
	Message=$(nc -lp 8083);
	if [ "$Message" == "en" ]; then
		fcitx5-remote -c
	fi
	sleep 1;
done
