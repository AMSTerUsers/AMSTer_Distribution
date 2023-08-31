#!/bin/bash
# The script plots or re-plots the L-curve prepared with test_lcurve.sh. 
#
# Parameters are : 
#			- regularisation order you want to (re-)plot (1-3)
#
# Dependencies:	- gnuplot
#				- gmt
#				- __HardCodedLines.sh
# 
# Hard coded:	- Some hard coded info about plot style : title, range, font, color...
#
# New in Distro V 1.0:	- Based on developpement version 1.0 and Beta V1.1
# New in Distro V 1.1:	- add creation date label
# New in Distro V 2.0:	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Get name of the institue $INSTITUTE where computation is performed (defined as a function in __HardCodedLines.sh)
	Institue
# ^^^ ----- Hard coded lines to check --- ^^^ 
     
ORDER=$1 

# Gnuplot script file for plotting data in file "lcurve.txt"
${PATHGNU}/gnuplot << EOF
		set terminal postscript color eps enhanced  "Helvetica,24"
		set output "Lcurve_${ORDER}.eps"
		set   autoscale                        # scale axes automatically
		unset label                            # remove any previous labels
		set xtic auto                          # set xtics automatically
		set ytic auto                          # set ytics automatically
		set title "Best Lambda is at deflection point - regularisation order : ${ORDER}"
		set xlabel "log ||Ax - Y||" font "Helvetica,24"
		set ylabel "log ||X|| up and ew" font "Helvetica,24"
	
		set timestamp "Created by MasTer at ${INSTITUTE} on: %d/%m/%y %H:%M " font "Helvetica,8" textcolor rgbcolor "#2a2a2a" 

		#'plot "lcurve.txt" using 2:3 notitle with linespoints'
		plot "lcurve_${ORDER}.txt" u 2:3:1 w labels offset character 0,character 1 tc rgb "blue" notitle, "lcurve_${ORDER}.txt" u 2:3 with lp notitle
EOF

gmt psconvert -Tj -A -E300 Lcurve_${ORDER}.eps 
