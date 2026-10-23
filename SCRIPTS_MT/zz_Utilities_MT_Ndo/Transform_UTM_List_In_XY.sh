#!/bin/bash
# The present script transforms a list of geographical coordinates into a list of Col(X) and Lines(Y) positions 
# with respect to a geographic zone define in an Envi hdr file. 
# Coordinates can be -LATLONG, -UTM or -PSEUDO_UTM
# Output file name = input name of list of coordinates with trailing _XY.txt 
#
# The data in XY are stored in the same directory as the input list of data and is named as 
# the list of data with a trailing _XY.txt 
#
# Parameters: 	- path to the hdr file 
#				- the list of coordinates to search for position in file (in the form of e.g. Name Lat Long or Name Xutm Yutm)
#				- format descriptor of provided input coordinates: either -LATLONG, -UTM or -PSEUDO_UTM
#				- 
# 
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies : -  UTM2EnviPosition.py
#
# New in Distro V 1.0 20250507:	- 
# New in Distro V 1.1 20260323:	- cosmetic + add _XY.txt as output file name 
# New in Distro V 1.2 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


PATHTOHDR=$1      		# path to the hdr file 
PATHTOGEOCDATA=$2		# path to the list of points in geographic coordinates
FORMATGEOC=$3			# type of input geoc coordinates, i.e. -LATLONG, -UTM or -PSEUDO_UTM

RUNDIR=`dirname ${PATHTOGEOCDATA}`
GEOCDATA=`basename ${PATHTOGEOCDATA}` 
XYDATA="${GEOCDATA}_XY.txt"

PATHTOXYCDATA="${PATHTOGEOCDATA}_XY.txt" 


rm -f ${PATHTOXYCDATA} 

cd ${RUNDIR}

while read -r STA LONG LAT
do	
	echo "Longitude of point is ${LONG} and Latitude of point is ${LAT} in ${FORMATGEOC} format"
	UTM2EnviPosition.py ${PATHTOHDR} ${LONG} ${LAT} ${FORMATGEOC} >> ${PATHTOXYCDATA} 

done < ${PATHTOGEOCDATA}

#remove all strings "Pixel Position (Option ${FORMATGEOC}): " in ${PATHTOXYCDATA}  and other stuffs
${PATHGNU}/gsed -i "s/Pixel Position (Option "${FORMATGEOC}"): //" ${PATHTOXYCDATA} 
${PATHGNU}/gsed -i "s/X=//" ${PATHTOXYCDATA} 
${PATHGNU}/gsed -i "s/Y=//" ${PATHTOXYCDATA} 
${PATHGNU}/gsed -i "s/,//" ${PATHTOXYCDATA} 

echo "All done. Hope it worked. "
echo 