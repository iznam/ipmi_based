#!/bin/bash


####################################
#   For Supermicro Fat Twin only   #
# Script do:                       #
# Power consumption                #
# Temperature of CPU and DIMMs     #
####################################

#---------------------SET parameters----------------------------
while getopts "l:d:p:h" arg
 do
  case $arg in
   d ) dr=$OPTARG ;;
   p ) pr=$OPTARG ;;
   l ) list=$OPTARG ;;
   h ) echo "
$0 -l [ipmi ip list] -d [duration, min] -p [period, min]" 
    exit 0 ;;
   ? ) echo "No argument value for option $OPTARG" ;;
  esac
 done
shift $OPTIND
#---------------------------------------------------------------

#----------------------ERRORS-----------------------------------
err()
{
   echo "ERROR: $@" 1>&2
   exit 1
}

[ -n "$list" ] || err "Please set file with ipmi ip-addresses: -l filename.dat"

[ -n "$dr" ] || err "Please set duration: -d [minutes]"

[ -n "$pr" ] || err "Please set period of one measure: -p [seconds]"
#---------------------------------------------------------------

#----------------------SET vars---------------------------------
time=0
duration=$(( $dr * 60 ))
period=$(awk "BEGIN{print $pr*60}") 

if test -d data ; then
  rm -rf data
  echo " "
  echo "Previous data directory has been deleted"
   mkdir data
 else
   mkdir data
fi

# d - unix date
# time - period for one mesure
# powerCons - server power consumption value 
# tempCpu1 - CPU#1 temperature
# tempCpu2 - CPU#2 temperature
#---------------------------------------------------------------

#---------------------MAIN Function-----------------------------
power()
 {
  while [ "$time" -le "$duration" ]; do
      d=$(date) 
     hexPower=$(ipmitool -U ADMIN -P ADMIN -H $1 raw 0x30 0xe2|awk '{print "0x" $3 $2}')
      powerCons=$(echo $(($hexPower)))
     hexTempCpu1=$(ipmitool -U ADMIN -P ADMIN -H $1 raw 0x30 0x93 0x00|awk '{print "0x" $1}')
      tempCpu1=$(echo $(($hexTempCpu1)))
     hexTempCpu2=$(ipmitool -U ADMIN -P ADMIN -H $1 raw 0x30 0x93 0x01|awk '{print "0x" $1}')
      tempCpu2=$(echo $(($hexTempCpu2)))
cat <<EOF >> data/$1.dat
$d 	$time $powerCons $tempCpu1 $tempCpu2
EOF
    time=$(($time + $period))
    sleep $period 
  done
 }
#--------------------------------------------------------------

#--------------------------RUN Collecting----------------------
pids=
while read line
 do
  power "$line" "$dr" "$pr" &
   pids="$pids $!"
done < $list

echo "Script PID =" $$
#echo "Waiting for childs.."
wait $pids 
#---------------------------END--------------------------------
