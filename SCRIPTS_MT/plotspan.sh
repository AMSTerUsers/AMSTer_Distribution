#!/bin/bash
# This script makes a Baseline plot for given data set.
#
# Parameters are 
# 			- Bperp_file.txt
#			- MinBp MaxBp MinBt MaxBt for naming fig and span(1).txt files
#
# Dependencies:	- gnu sed, awk and date for more compatibility. 
#				- gnuplot
#				- gmt for format convertion
#
# Hard coded:	- Some hard coded info about plot style : title, range, font, color...
#
# New in Distro V 1.0:	 - Based on developpement version 1.0 and Beta V2.0
# New in Distro V 1.0.1: - use gdate
# New in Distro V 1.0.2: - use gdate in path
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/04/28 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0.2 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on May 4, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

BPERPFILE=$1
MinBp=$2 
MaxBp=$3
MinBt=$4 
MaxBt=$5

i=1

#while read n m s bp t t1 t2 b1 b2
while read n m s t bp t1 t2 b1 b2
do

	yyyy=`echo $m | cut -b 1-4`
	mm=`echo $m | cut -b 5-6`
	dd=`echo $m | cut -b 7-8`

	# date in decimal year : depends on leap year or not. DOY is decreased by 0.5 to mimick noon and avoid prblm at first or last day
	leapm=`${PATHGNU}/gdate --date="${yyyy}1231" +%j`
	mastertemp=`${PATHGNU}/gdate --date="${yyyy}${mm}${dd}" +%j`
	master=`echo ${mastertemp} ${leapm} ${yyyy} | ${PATHGNU}/gawk '{printf("%f",(($1-0.5)/$2) + $3);}'` 
	#master=`echo $yyyy $mm $dm | ${PATHGNU}/gawk '{printf("%.17g\n",$1+(($2-1)*30.25+$3)/365);}'` 

	yyyy=`echo $s | cut -b 1-4`
	mm=`echo $s | cut -b 5-6`
	dd=`echo $s | cut -b 7-8`

	leaps=`${PATHGNU}/gdate --date="${yyyy}1231" +%j`
	slavetemp=`${PATHGNU}/gdate --date="${yyyy}${mm}${dd}" +%j`
	slave=`echo ${slavetemp} ${leaps} ${yyyy} | ${PATHGNU}/gawk '{printf("%f",(($1-0.5)/$2) + $3);}'` 
	#slave=`echo $yyyy $mm $dm | ${PATHGNU}/gawk '{printf("%.17g\n",$1+(($2-1)*30.25+$3)/365);}'` 

	delta=`echo $master, $slave | ${PATHGNU}/gawk '{printf("%f",$2-$1)}'` 

	bpdelta=`echo $b1, $b2 | ${PATHGNU}/gawk '{printf("%f",$2-$1)}'`

	echo $master $b1 $delta $bpdelta >> span.txt

	md=`echo $master $delta | ${PATHGNU}/gawk '{printf("%f",$1+$2)}'`
	bpd=`echo $b1 $bpdelta | ${PATHGNU}/gawk '{printf("%f",$1+$2)}'`

	echo $master $b1 >> span1.txt
	echo $md $bpd >> span1.txt

	let "i=i+1"

done < ${BPERPFILE}

${PATHGNU}/gnuplot << EOF
#set title "" 

set title "Max ${MaxBp} m ${MaxBt} days" 
set xlabel "Time, year" font "Helvetica,24"
set ylabel "Perpendicular baseline, m" font "Helvetica,24"
set autoscale
#set xrange [2011.0:2011.5]
#set yrange [-2000:3000] 

set ytics font "Helvetica,24" 
set xtics font "Helvetica,24" 
set size 1.5,1.5
set pointsize 1
#set xtics 0.5  
set xtics 0.5 font "Helvetica,20" rotate by 45 right 
set mxtics 5 

# To plot vetors and points verus dates
set output "span.eps" 
set terminal postscript color eps enhanced  "Helvetica,24"
plot 'span.txt' with vectors nohead lt 1 lw 1.5 lc rgb '#4D4D4D' notitle, 'span1.txt' with points pt 7 ps 1.5 lc rgb '#4D4D4D' notitle

# To plot only points and dates
#set offset 1,1,1,1
#plot 'span1.txt' using 1:2:1 with labels point  pt 7 offset char 1,1 notitle

EOF
gmt psconvert -Tj -A -E300 span.eps

mv span.txt span_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt 
mv span1.txt span1_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt 
mv span.jpg span_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.jpg

rm span.eps

