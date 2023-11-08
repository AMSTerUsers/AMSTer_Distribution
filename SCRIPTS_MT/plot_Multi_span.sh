#!/bin/bash
# This script makes a common Baseline plot for multiple data sets.
# Data are supposed to be in the current dir in subdir named DefoI
#
# It supposes that a first plot was already computed (see plotspan.sh) for each mode in order to generate 
#     the span(1).txt files with the same MaxBp and MaxBt
#
# Parameters = 
#		- file with the list of sets used in the order of Defo dir  (SETLIST)
#		- MinBp MaxBp MinBt MaxBt
#       - file with color table in hex (COLORTABLE). 
#           Try to keep eg. blueish for asc and reddish for desc. (must be of same length as SETLIST
#			Blue like colors e.g. : #0000ff, #8a2be2, #6495ed,#00008b, #00ffff, #7fffd4
#      		Red like colors e.g. : #dc143c, #a52a2a, #d2691e, #ff7f50, #ff1493, #ff00ff
#           see for instance http://cloford.com/resources/colours/500col.htm
#
#  eg of content of file of sets : 
#	/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set1
#	/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set2
#	/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set5
#
#  eg of color table in hex : 
#	#0000ff
#	#8a2be2
#	#6495ed
#
# Dependencies:	- gnuplot
#				- gmt for format convertion
#
# Hard coded:	- Some hard coded info about plot style : title, range, font, color...
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

SETLIST=$1
MinBp=$2 
MaxBp=$3
MinBt=$4 
MaxBt=$5
COLORTABLE=$6

# Dump Command line used in CommandLine.txt
echo "$(dirname $0)/${PRG} run with following arguments : \n" > CommandLine_${PRG}.txt
index=1 
for arg in $*
do
  echo "$arg" >> CommandLine_${PRG}.txt
  let "index+=1"
done 


i=1
for LINE in `cat -s ${SETLIST}`
do
	cp ${LINE}/span_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt ./Defo${i}_span_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt
	cp ${LINE}/span1_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt ./Defo${i}_span1_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt
	i=`expr ${i} + 1`
done
Nsets=`expr ${i} - 1`

for i in `seq 1 ${Nsets}`
do
	if [ ${i} != ${Nsets} ]
		then
			COLOR=`sed "${i}q;d" ${COLORTABLE}`
			echo " 'Defo${i}_span_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt' with vectors nohead lt 1 lw 1.5 lc rgb '${COLOR}' notitle, 'Defo${i}_span1_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt' with points pt 7 ps 1.5 lc rgb '${COLOR}' , \\" >> ToPlot.txt
		else 
			COLOR=`sed "${i}q;d" ${COLORTABLE}`
			echo " 'Defo${i}_span_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt' with vectors nohead lt 1 lw 1.5 lc rgb '${COLOR}' notitle, 'Defo${i}_span1_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt' with points pt 7 ps 1.5 lc rgb '${COLOR}'" >> ToPlot.txt			
	fi
done

${PATHGNU}/gnuplot << EOF

#set title "" 
set title "Max ${MaxBp} m ${MaxBt} days" 
set xlabel "Time, year" font "Helvetica,24"
set ylabel "Perpendicular baseline, m" font "Helvetica,24"

#set autoscale
#set xrange [2002.9:2011.1]
#set yrange [-2000:2500] 

set ytics font "Helvetica,24" 
set xtics font "Helvetica,20" rotate by 45 right
set size 1.5,1.5
set pointsize 1
set xtics 0.5

set output "span.eps" 
set terminal postscript color eps enhanced  "Helvetica,12"
# plot asc in Blue like colors e.g. : #0000ff, #8a2be2, #6495ed,#00008b, #00ffff, #7fffd4
#      desc in red like colors e.g. : #dc143c, #a52a2a, #d2691e, #ff7f50, #ff1493, 	#ff00ff


plot `cat ToPlot.txt`
EOF

gmt psconvert -Tj -A -E300 span.eps

mv span.jpg span_${Nsets}sets_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.jpg
rm span.eps ToPlot.txt #Defo*.txt

