#!/bin/bash


while getopts "i:d:n:h" arg
 do
  case $arg in
   i ) ip=$OPTARG ;;
   n ) name=$OPTARG ;;
   d ) dur=$OPTARG ;;
   h ) echo "
Usage: $0 -i [ipmi ip] -d [duration of test in minutes] -n [test name]"
    exit 0 ;;
   ? ) echo "No argument value for option $OPTARG" ;;
  esac
 done
shift $OPTIND


if [ -e cpu_p_cons/$name.dat ]; then
   echo -e "
   Result file exists. Do you want to rewrite it?
   Press Y[y]/N[n]" 
while :; do
   read -s -n 1 answ
   case "$answ" in
   [yY]) rm cpu_p_cons/$name.dat
   echo " "
   echo "
   Test has been started. Duration = $dur min."
   break
   ;;
   [nN]) exit 0
   ;;
   *) echo "
   Wrong answer! Just say \"yes [yY]\" or \"no [nN]\" "
   esac
 done  
fi  



message()
{
echo " "
echo "Usage: $0 -i [ipmi ip] -d [duration of test in minutes] -n [test name]"
echo " " 
echo $1
echo " " 
exit 1
}    

[ -n "$ip" ] || message "Please set ipmi ip, -i "
[ -n "$dur" ] || message "Please set test duration, in minutes, -d"
[ -n "$name" ] || message "Please set name of the test, -n "



time=0

duration=$(( $dur * 60 ))

#power()
while :; do #[ "$time" -le "$duration" ]; do
      d=$(date +%H:%M:%S)
     hexPower=$(ipmitool -U ADMIN -P ADMIN -H $ip -t 0x2c raw 0x2e 0xc8 0x57 0x01 0x00 0x01 0x01 0x00 | awk 'NR == 1{print "0x" $4}')
      powerCons=$(echo $(($hexPower)))
cat <<EOF >> cpu_p_cons/$name.dat
$d	$time	| Power= $powerCons  W
EOF
    time=$(awk "BEGIN{print $time+0.1}") #$(( $time + 0.1 ))
    sleep 0.1
done


