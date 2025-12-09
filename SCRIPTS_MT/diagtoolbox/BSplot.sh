#!/bin/bash
# Script intends to make the baselineplot using gnuplot using as input the file dataBaselinesPlot.txt 
# containing a subselection of lines from allPairsListing
#
# NOTE: - 
#
# WARNING: 	
#
# Parameters: - path to the dir where inputfile is and where the results will be stored 
#			  - name of the inputfile produced with computeBaselinesPlotFile 
#			  - string to name the file and custmize the title
#			  - name of the output gnuplot file
#
# Hardcoded: 
#
# Dependencies:	- 
#
# New in Distro V 1.0.1:  - Cosmetic
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0.1 MasTer script utilities"
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Feb 13, 2024 by NdO"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

WORKINGDIR=$1
Inputfile=$2
strtitle=$3
GNUPLOTfile=$4
date_min=$5
date_max=$6
bs_min=$7
bs_max=$8

if [ -f "${WORKINGDIR}/${GNUPLOTfile}" ]; then
		rm ${WORKINGDIR}/${GNUPLOTfile}
fi

echo "# Spatial baseline plot"  > ${WORKINGDIR}/${GNUPLOTfile}
echo "#"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "# WorkingDirectory:"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "workingDir = sprintf(\""${WORKINGDIR}"\")"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "filenameSuffix = sprintf(\""${strtitle}"\")"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "inputfilename = sprintf(\""${Inputfile}"\")" >> ${WORKINGDIR}/${GNUPLOTfile}
echo "xminval = sprintf(\"%d\",${date_min})" >> ${WORKINGDIR}/${GNUPLOTfile}
echo "xmaxval = sprintf(\"%d\",${date_max})" >> ${WORKINGDIR}/${GNUPLOTfile}
echo "yminval = sprintf(\"%d\",${bs_min})" >> ${WORKINGDIR}/${GNUPLOTfile}
echo "ymaxval = sprintf(\"%d\",${bs_max})" >> ${WORKINGDIR}/${GNUPLOTfile}
echo ""  >> ${WORKINGDIR}/${GNUPLOTfile}

echo "# Input files:"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "inputfile = sprintf(\"%s/%s\", workingDir, inputfilename)"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo ""  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set terminal png size 1280, 720 #transparent truecolor"  >> ${WORKINGDIR}/${GNUPLOTfile}

echo "# Set output file:"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "outputFile = sprintf(\"%s/BPLOT_%s.png\", workingDir, filenameSuffix)"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set output outputFile"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo ""  >> ${WORKINGDIR}/${GNUPLOTfile}

#echo "superMasterDate = 20190622"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "# Settings:"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set style line 1 pointsize 2 pointtype 7"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set xzeroaxis linetype 4 linewidth 2"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set yzeroaxis linetype 4 linewidth 2"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set style circle radius screen 0.004"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set style fill transparent solid 0.5 noborder"  >> ${WORKINGDIR}/${GNUPLOTfile}
#echo "set autoscale xfix"  >> ${WORKINGDIR}/${GNUPLOTfile}
#echo "set offsets graph 0.05, graph 0.05"  >> ${WORKINGDIR }/${GNUPLOTfile}
echo ""  >> ${WORKINGDIR}/${GNUPLOTfile}

echo "#set term postscript color enhanced \"Helvetica,20\""  >> ${WORKINGDIR}/${GNUPLOTfile}
echo ""  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "# Defining title"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo ""  >> ${WORKINGDIR}/${GNUPLOTfile}
#echo "theTitle = sprintf(\"Baseline plot of selected data\n %s        \nSuper Master date: %d\", filenameSuffix, superMasterDate)"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "theTitle = sprintf(\"Baseline plot of selected data\n %s        \n\", filenameSuffix)"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set key left tmargin  box title theTitle"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "timeFormat = \"%Y%m%d\""  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "timeString(n) = sprintf(\"%d\", n)"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set xdata time"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set timefmt timeFormat"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set xrange [xminval:xmaxval] " >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set yrange [yminval:ymaxval] " >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set format x \"%d/%m\n%Y\" "  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set grid"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set style fill transparent solid 0.4 noborder"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set key left"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo #"set arrow 1 from strptime(timeFormat, timeString(superMasterDate)), graph 0 to strptime(timeFormat, timeString(superMasterDate)), graph 1 lt 4 lw 2 nohead"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set xlabel \"Time [dd/mm/yyyy]" >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set ylabel \"Position [m]\"		"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "set timestamp \"Created by AMSTer at ECGS on: %d/%m/%y %H:%M \" font \"Helvetica,8\" textcolor rgbcolor \"#2a2a2a\" "  >> ${WORKINGDIR}/${GNUPLOTfile}
echo ""  >> ${WORKINGDIR}/${GNUPLOTfile}

echo "plot \\"  >> ${WORKINGDIR}/${GNUPLOTfile}
#echo "inputfile using 1:2 with circles fillcolor \"red\" notitle, \\"  >> ${WORKINGDIR}/${GNUPLOTfile}
#echo "inputfile using (strptime(timeFormat, timeString(\$1))+\$3 ):(\$4+\$2) with circles fillcolor \"red\" notitle , \\"  >> ${WORKINGDIR}/${GNUPLOTfile}
#echo "inputfile using 1:2:3:4 with vectors linewidth 1 linecolor rgb \"#3050A0\" notitle"  >> ${WORKINGDIR}/${GNUPLOTfile}

echo "inputfile using 1:7 with circles fillcolor \"red\" notitle, \\"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "inputfile using 2:(\$7 + \$8) with circles fillcolor \"red\" notitle, \\"  >> ${WORKINGDIR}/${GNUPLOTfile}
echo "inputfile using 1:7:(strptime(timeFormat, timeString(\$2)) - strptime(timeFormat, timeString(\$1))):8 with vectors linewidth 1 linecolor rgb \"#3050A0\" notitle"  >> ${WORKINGDIR}/${GNUPLOTfile} 


gnuplot ${WORKINGDIR}/${GNUPLOTfile}

# end