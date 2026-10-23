#!/bin/bash
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 



TSFILE=$1

while read yyyymmmdd los
do

yyyy=`echo $yyyymmmdd | cut -b 1-4`
mm=`echo $yyyymmmdd | cut -b 5-6`
dd=`echo $yyyymmmdd | cut -b 7-8`

decimadate=`echo $yyyy $mm $dm | awk '{printf("%f",$1+(($2-1)*30.25+$3)/365);}'` 

echo $decimadate $los >> los.txt

done < ${TSFILE}

/opt/local/bin/gnuplot << EOF
	set terminal postscript color eps enhanced  "Helvetica,24"
	set output "point_ts.eps"
#	set output "lcurveNoLog.eps"
	set   autoscale                        # scale axes automatically
    unset label                            # remove any previous labels
    set xtic auto                          # set xtics automatically
    set ytic auto                          # set ytics automatically
    set title "pix 227 120"
    set xlabel "Date" font "Helvetica,24"
    set ylabel "Los" font "Helvetica,24"
	#set ytics font "Helvetica,24" 
	#set xtics font "Helvetica,16" 
	#set size 1.5,1.5
	#set pointsize 1
	#set xtics 0.5	
	set key left top
	
	set timestamp "Created by AMSTer at ECGS on: %d/%m/%y %H:%M " font "Helvetica,8" textcolor rgbcolor "#2a2a2a" 
	
#'plot "lcurve.txt" using 2:3 notitle with linespoints'
plot "los.txt" u 1:2


#pplot 'span.txt' with vectors nohead lt 1 lw 1.5 lc rgb '#4D4D4D' notitle, 'span1.txt' with points pt 7 ps 1.5 lc rgb '#4D4D4D' notitle
#plot "lcurveNoLog.txt" u 2:3:1 w labels offset character 0,character 1 tc rgb "blue" notitle, "lcurveNoLog.txt" u 2:3 with lp notitle



EOF
gmt psconvert -Tj -A -E300 point_ts.eps
