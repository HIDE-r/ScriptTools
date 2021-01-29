#!/sbin/bash

# echo "done!!!" | nc 10.118.81.30 8081

while true
do
	nc -lp 8081 | xargs -0 -n 1 notify-send ;
	sleep 1;
done
