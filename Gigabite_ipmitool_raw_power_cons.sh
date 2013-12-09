#!/bin/bash

# $1 - ip list
# $2 - duration in minutes
# $3 - period in seconds

if [ -z "$2" ]; then
    echo "Please set duration of test in minutes. Exit."
    exit 1
fi

if [ -z "$3" ]; then
    echo "Please set period of one measurement in seconds. Exit."
    exit 1
fi

if [ -d data ];then
   rm -r data
fi

time=0

duration=$(( $2 * 60 ))
#period=$(awk "BEGIN{print $3*60}") 

mkdir data

power()
 {
  while [ "$time" -le "$duration" ]; do
      d=$(date +%H:%M:%S)
     hexPower=$(ipmitool -U admin -P password -H $1 raw 0x04 0x2d 0x66|awk '{print "0x" $1}')
      powerCons=$((2 * $(echo $(($hexPower)))))
     hexTempCpu1=$(ipmitool -U admin -P password -H $1 raw 0x04 0x2d 0x70|awk '{print "0x" $1}')
      tempCpu1=$(echo $(($hexTempCpu1)))
     hexTempCpu2=$(ipmitool -U admin -P password -H $1 raw 0x04 0x2d 0x71|awk '{print "0x" $1}')
      tempCpu2=$(echo $(($hexTempCpu2)))
cat <<EOF >> data/$1.txt
$d $time | Power= $powerCons W | CPU1_T= $tempCpu1 °C | CPU2_T=  $tempCpu2 °C |
EOF
    time=$(( $time + $3 ))
    sleep $3
  done
 }


pids=
while read line
 do
  power "$line" "$2" "$3" &
  pids="$pids $!"
done < $1

echo "Waiting for childs.."
echo "Parent PID=" $$
wait $pids

