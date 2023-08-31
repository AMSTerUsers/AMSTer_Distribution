#!/bin/bash
# This script makes a common Baseline plot for 2 data sets OF DIFFERENT BASELINES.
# Data are supposed to be in the current dir in subdir named DefoI
#
# it supposes that a first plot was already computed (see plotspan.sh) for each mode in order to generate 
#     the span(1).txt files with the same MaxBp and MaxBt
#
# Parameters : 
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
#  eg of color table in hex : (see in line 
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
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/04/28 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 15, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

SETLIST=$1
MinBp1=$2 
MaxBp1=$3
MinBt1=$4 
MaxBt1=$5
COLORTABLE=$6
MinBp2=$7 
MaxBp2=$8
MinBt2=$9 
MaxBt2=${10}

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
	case "${i}" in 
		"1")  
			cp ${LINE}/span_${MinBp1}_${MaxBp1}_${MinBt1}_${MaxBt1}.txt ./Defo${i}_span.txt
			cp ${LINE}/span1_${MinBp1}_${MaxBp1}_${MinBt1}_${MaxBt1}.txt ./Defo${i}_span1.txt
				;;
		"2")	
			cp ${LINE}/span_${MinBp2}_${MaxBp2}_${MinBt2}_${MaxBt2}.txt ./Defo${i}_span.txt
			cp ${LINE}/span1_${MinBp2}_${MaxBp2}_${MinBt2}_${MaxBt2}.txt ./Defo${i}_span1.txt
				;;
	esac
i=`expr ${i} + 1`
done
Nsets=`expr ${i} - 1`

for i in `seq 1 ${Nsets}`
do
	if [ ${i} != ${Nsets} ]
		then
			COLOR=`sed "${i}q;d" ${COLORTABLE}`
			echo " 'Defo${i}_span.txt' with vectors nohead lt 1 lw 1.5 lc rgb '${COLOR}' notitle, 'Defo${i}_span1.txt' with points pt 7 ps 1.5 lc rgb '${COLOR}' , \\" >> ToPlot.txt
		else 
			COLOR=`sed "${i}q;d" ${COLORTABLE}`
			echo " 'Defo${i}_span.txt' with vectors nohead lt 1 lw 1.5 lc rgb '${COLOR}' notitle, 'Defo${i}_span1.txt' with points pt 7 ps 1.5 lc rgb '${COLOR}'" >> ToPlot.txt			
	fi
done

${PATHGNU}/gnuplot << EOF
#set title "" 
set title "Max ${MaxBp1}/${MaxBp2} m ${MaxBt1}/${MaxBt2} days for set 1/2" 
set xlabel "Time, year" font "Helvetica,24"
set ylabel "Perpendicular baseline, m" font "Helvetica,24"

set autoscale
#set xrange [2002.9:2011.1]
#set yrange [-2000:2000] 

set ytics font "Helvetica,24" 
set xtics font "Helvetica,16" 
set size 1.5,1.5
set pointsize 1
set xtics 0.5

set output "span.eps" 
set terminal postscript color eps enhanced  "Helvetica,24"
# plot asc in Blue like colors e.g. : #0000ff, #8a2be2, #6495ed,#00008b, #00ffff, #7fffd4
#      desc in red like colors e.g. : #dc143c, #a52a2a, #d2691e, #ff7f50, #ff1493, 	#ff00ff


plot `cat ToPlot.txt` 


EOF
gmt psconvert -Tj -A -E300 span.eps

mv span.jpg span_${Nsets}sets_${MinBp1}_${MaxBp1}-${MaxBp2}_${MinBt1}_${MaxBt1}-${MaxBt2}.jpg
rm span.eps ToPlot.txt Defo*.txt

