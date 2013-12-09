#!/bin/bash

# $1 - ip
# $2 - filename
# $3 - period, seconds

if test -e $2.txt
  then
  rm $2.txt
fi

echo Test begins at $(date +%H:%M:%S)
data()
{
tm=0
while :; do
 time=$(date +%H:%M:%S)
 dimm_power="$(java -jar SMCIPMITool.jar $1 ADMIN ADMIN nm20 statistics 1 2 0 | grep Current)"
# echo $(date +%H:%M:%S) $tm $dimm_power
cat <<EOF >> $2.txt
$time $tm $dimm_power   
EOF
tm=$(( $tm + $3))
sleep $3
done
}

data $1 $2 $3 &
pid=$!

echo "Press Enter to stop script. PID=$pid"

read Enter

kill $pid
