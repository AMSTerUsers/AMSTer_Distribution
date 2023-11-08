#!/bin/bash
# Plot the diff between 2 time series provided as PATH/timeLineXXXX_YYYY.txt (from PlotTS.sh for instance)  
#  This is useful to compare the time series of the same pixels processed with different MSBAS parameters.
# 
# Script must be launched in dir where results will be stored. Name your dir smartly to remmeber what 
#     were the time series that were compared... 
#
# Parameters :	- PATH/timeLineXXXX_YYYY.txt of pixel 1
# 				- PATH/timeLineXXXX_YYYY.txt of pixel 2
#
# Hard coded:	- Path to figure template: plotTS_template.gnu (Obsolate since V 3.0)
#				- Some hard coded info about plot style : title, range, font, color...
#
# Dependencies : - gnuplot
#                - gnu plot template plotTS_template.gnu 
#				 - gnu sed and awk for more compatibility. 
#				 - convert
#				 - __HardCodedLines.sh
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
#		 Distro V 1.1:	- remove transparency option "-alpha remove" from convert (because may crash on linux; maybe must be "-alapha off" on recent convert versions)
#		 Distro V 2.0:	- change path to GNUTEMPLATE the same way for Mac and Linux
# New in Distro V 3.0:	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Get name of the institue $INSTITUTE where computation is performed (defined as a function in __HardCodedLines.sh)
	Institue
	# Get the templates for plotting with or without fit
	TemplatesGnuForPlotWOfit
# ^^^ ----- Hard coded lines to check --- ^^^ 


#GNUTEMPLATE="/${PATH_SCRIPTS}/SCRIPTS_MT/plotTS_template.gnu"
GNUTEMPLATE="${GNUTEMPLATENOFIT}"

RUNDIR=`pwd`

# Filst pixel time series
PATHFILE1=$1
FILE1EXT=`basename ${PATHFILE1}`
FILE1=${FILE1EXT%.*}

# second pixel time series (same pixel from two different processings or different pixel from same processing. This last case could be done directely using PlotTS.sh with two pixels as input)
PATHFILE2=$2
FILE2EXT=`basename ${PATHFILE2}`
FILE2=${FILE2EXT%.*}

if [ $# -lt 2 ] ; then echo "Usage $0 PATH_TO_MSBAS_DEFO_MAPS PATH_PIX1_TIME_SERIES PATH_PIX2_TIME_SERIES"; exit; fi

# PLOT
cp ${GNUTEMPLATE} plotTS_${FILE1}_${FILE2}.gnu


# and get the double difference
#merge line by lines the two txt files
paste ${PATHFILE1} ${PATHFILE2} > timeLine_${FILE1}_${FILE2}.txt

# Change input time series txt name
${PATHGNU}/gsed -i "s%PATH_TO_EPS%${RUNDIR}\/timeLine_${FILE1}_${FILE2}%" plotTS_${FILE1}_${FILE2}.gnu

# Change title
TITLE="Ground displacement; ${FILE1} - ${FILE2} "
${PATHGNU}/gsed -i "s%TITLE%${TITLE}%" plotTS_${FILE1}_${FILE2}.gnu

# Change INSTITUTE name 
${PATHGNU}/gsed -i "s%INSTITUTE%${INSTITUTE}%" plotTS_${LIN1}_${PIX1}.gnu

# select the columns
${PATHGNU}/gsed -i "s%u 1: 3%u 1: (\$3 - \$6)%g" plotTS_${FILE1}_${FILE2}.gnu

gnuplot plotTS_${FILE1}_${FILE2}.gnu

for EPSFILE in `ls *.eps`
do 
	#convert -density 150 -rotate 90 -background white -alpha remove ${EPSFILE} ${EPSFILE}.png
	convert -density 150 -rotate 90 -trim -background white ${EPSFILE} ${EPSFILE}.png
done

