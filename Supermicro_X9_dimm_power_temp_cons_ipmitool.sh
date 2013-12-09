#!/bin/bash

########################################################
#      For Supermicro only                             #
# Script does:                                         #
# Server & DIMMs Power consumption trough ipmitool raw #
#                                                      #
# $1 - ip                                              #
# $2 - duration for the test, minutes                  # 
# $3 - period for measure, seconds                     #
# $4 - tesname                                         #
########################################################

while getopts "i:d:p:f:h" arg
 do
  case $arg in
   i ) ip=$OPTARG ;;
   d ) duration=$OPTARG ;;
   p ) period=$OPTARG ;;
   f ) name=$OPTARG ;;
   h ) echo "
$0 -i [ipmi address] -d [duration, min] -p [period, sec] -f [filename] 
     -i ipmi ip-address
     -d duration of the test, minutes
     -p period fot one measure, seconds
     -f output filename
     -h this help"
    exit 0 ;;
   ? ) echo "No argument value for option $OPTARG" ;;
  esac
 done
shift $OPTIND

err()
{
   echo "ERROR: $@" 1>&2
   exit 1
}

[ -n "$ip" ] || err "Please set ipmi ip-address: -i [ip...]"

[ -n "$duration" ] || err "Please set duration: -d [minutes]"

[ -n "$period" ] || err "Please set period of one measure: -p [seconds]"

[ -n "$name" ] || err "Please set output filename: -f [name]"

#VARIABLES:
dur=$(( $duration * 60 ))
now=$(date +%s)
tm=0

echo "Unix T	|Period	|Full P,W	|DIMMs P,W	|DIMM T,CPU#1	|DIMM T,CPU#2  " > $name.dat

dimm ()
{
   summ_dimmP=$(cat $name.dat | awk 'NR > 2{print $4}'| xargs|sed 's/ /+/g')
    amount_dimmP=$(( $(cat $name.dat | wc -l) - 1))
     avrg_dimmP=$(( $summ_dimmP / $amount_dimmP))
    oneDimmP=$(( $avrg_dimmP / 16 ))
   echo "Power consumption of one DIMM =" $oneDimmP"W">> $name.dat
}

power()
{
    while [ "$tm" -le "$dur" ]; do
      d=$(date +%s)
       real_sec=$(($d - $now)) 
     hex_dimm_Power=$(ipmitool -H $ip -U ADMIN -P ADMIN -t 0x2c raw 0x2e 0xc8 0x57 0x01 0x00 0x01 0x02 0x00|awk 'NR==1{print "0x" $4}')
       dimm_powerCons=$(echo $(($hex_dimm_Power)))
     hex_server_Power=$(ipmitool -U ADMIN -P ADMIN -H $ip raw 0x30 0x19|awk '{print "0x" $3 $2}')
       server_powerCons=$(echo $(($hex_server_Power)))     
     hex_dimm_Tcpu0=$(ipmitool -U ADMIN -P ADMIN -H $ip raw 0x30 0x94 0x00 0x02 0x00|awk '{print "0x" $1}')
       dimm_Tcpu0=$(echo $(($hex_dimm_Tcpu0)))
     hex_dimm_Tcpu1=$(ipmitool -U ADMIN -P ADMIN -H $ip raw 0x30 0x94 0x01 0x01 0x00|awk '{print "0x" $1}')
       dimm_Tcpu1=$(echo $(( $hex_dimm_Tcpu1)))

cat <<EOF >> $name.dat
$real_sec	 $tm	 $server_powerCons       	 $dimm_powerCons	         $dimm_Tcpu0	         $dimm_Tcpu1
EOF

     tm=$(( $tm + $period))
     sleep $period
   done

#dimm
}


power & 
pid=$!
echo "PID=" $pid

