#!/bin/bash


if $1 -eq "-help" 
  then 
   echo "
##########################################
# $1 - ip ipmi;                          #
# $2 - duration of test;                 # 
# $3 - name of test.                     #
##########################################
"
fi

if test -e $3.txt 
  then 
  rm $3.txt
fi

time=0

dimmCount=$(java -jar SMCIPMITool.jar $1 ADMIN ADMIN nm20 cpumemtemp |  grep P1 -c)

while [ "$time" -le "$2" ]; do

 echo $(date +%H:%M:%S) $time  

 java -jar SMCIPMITool.jar $1 ADMIN ADMIN nm20 cpumemtemp > data_pmbus_temp.txt
 dimmTempCpu1=$(cat data_pmbus_temp.txt | awk '/P1/{printf $4}' |sed 's/(c)/+/g'|sed 's/+$//')
 dimmTempCpu2=$(cat data_pmbus_temp.txt | awk '/P2/{printf $4}' |sed 's/(c)/+/g'|sed 's/+$//')
 cpuTemp=$(cat data_pmbus_temp.txt | awk '/TJ/{printf $3}' |sed 's/(c)/ /g')
 pcons=$(java -jar SMCIPMITool.jar $1 ADMIN ADMIN nm20 oemGetPower | sed 's/watts//')

 dimmTempAvrg1=$(( ($dimmTempCpu1) / $dimmCount ))
 dimmTempAvrg2=$(( ($dimmTempCpu2) / $dimmCount ))

cat <<EOF >> $3.txt
$time $pcons $cpuTemp $dimmTempAvrg1 $dimmTempAvrg2 
EOF
time=$(( $time + 20 ))
sleep 15
done
rm data_pmbus_temp.txt



#cat <<EOF > plot_file.graph
#!/usr/bin/gnuplot -persist
#set terminal postscript eps enhanced
#set output "$HOME/Documents/Benchmarks/PMBus/$3.png"
#set terminal png size 1200,768
#set title "DIMM temperature and Power consumption. Model:$3 " font "Helvetica,20" 
#set yrange [0:350]
#set ytics 25
#set y2range [0:100]
#set ytics nomirror
#set a light green(#ccffcc) background color
#set object 1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb"#ccffcc" behind
#set y2tics 10
#set xdata time
#set timefmt "%S"
#set grid xtics ytics mxtics mytics
#set ylabel "Power consumption, W" font "Helvetica,18"
#set xlabel "Time, s" font "Helvetica,18"
#set y2label "DIMM Temperature, C" font "Helvetica,18"
#set style line 1 lt 1 pt 7
#plot "$HOME/Documents/Benchmarks/PMBus/$3.txt" using 1:3 title "DIMM_CPU#1 Temperature" with linespoints linestyle 5 lt rgb "green" axis x1y2,\
#     "$HOME/Documents/Benchmarks/PMBus/$3.txt" using 1:4 title "DIMM_CPU#2 Temperature" with linespoints linestyle 5 lt rgb "blue" axis x1y2,\
#     "$HOME/Documents/Benchmarks/PMBus/$3.txt" using 1:2 title "Power consumption" with linespoints linestyle 5 lt rgb "red" 
#EOF

#cat plot_file.graph | gnuplot #gnuplot running
