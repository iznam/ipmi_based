#!/bin/bash

####################################
#      For Supermicro only         #
# Script do:                       #
# Power consumption                #
# Temperature of CPU and DIMMs     #
# $1 - ip list                     #
# $2 duration of the test, minutes # 
# $3 period for mesure, minutes    #
####################################

if [ -z "$2" ]; then
    echo "Please set duration of test in minutes. Exit."
    exit 1
fi

if [ -z "$3" ]; then
    echo "Please set period of one measurement in minutes. Exit."
    exit 1
fi

if test -d data
  then rm -r data
fi

mkdir data
time=0
duration=$(( $2 * 60 )) #minutes to seconds
period=$(awk "BEGIN{print $3*60}") #minutes to seconds
#dimmCount=$(java -jar SMCIPMITool.jar $1 ADMIN ADMIN nm20 cpumemtemp |  grep P1 -c)

power()
 {
  if test -e $1.txt #$HOME/Documents/Benchmarks/PMBus/$3.txt
    then
    rm $1.txt #$HOME/Documents/Benchmarks/PMBus/$3.txt
  fi
 
  dimmCount=$(java -jar SMCIPMITool.jar $1 ADMIN ADMIN nm20 cpumemtemp |  grep P1 -c)

echo "Time" $'\t\t\t' "   Period"  "  Power"  " CPU,T"  "  DIMM#1,T"   > data/$1.txt

  while [ "$time" -le "$duration" ]; do
   d=$(date) 
    powerCons=$(java -jar SMCIPMITool.jar $1 ADMIN ADMIN nm20 oemGetPower | sed 's/watts//') 
     java -jar SMCIPMITool.jar $1 ADMIN ADMIN nm20 cpumemtemp > data_pmbus_temp.txt
      dimmTempCpu1=$(cat data_pmbus_temp.txt | awk '/P1/{printf $4}' |sed 's/(c)/+/g'|sed 's/+$//')
       dimmTempCpu2=$(cat data_pmbus_temp.txt | awk '/P2/{printf $4}' |sed 's/(c)/+/g'|sed 's/+$//')
        cpuTemp=$(cat data_pmbus_temp.txt | awk '/TJ/{printf $3}' |sed 's/(c)/ /g')   
     dimmTempAvrg1=$(( ($dimmTempCpu1) / $dimmCount ))
      dimmTempAvrg2=$(( ($dimmTempCpu2) / $dimmCount )) 
       #ipmitool -U ADMIN -P ADMIN -H $1 raw 0x30 0xe2 0 0 0 |awk '{s="0x" $2; printf "%d\n", s }' #power consumption via ipmitool, hex 
cat <<EOF >> data/$1.txt
$d	$time	$powerCons	$cpuTemp	$dimmTempAvrg1 $dimmTempAvrg2
EOF
    time=$(( $time + $period))
    sleep $period 
  done
 }


pids=
while read line
 do
  power "$line" "$2" "$3" &
  pids="$pids $!"
done < $1

echo "Waiting for childs.."
wait $pids
