#!/bin/bash
######################################################################################
# This script remove all files in Geocoded and GeocodedRasters dir that contains dates 
#   provided by a list of dates  
#
# Must be launched in dir that contains Geocoded and GeocodedRasters
# 
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 



DATELIST=$1  #must be in the form of YYYYMMDD_YYYYMMDD

cd Geocoded
for PAIRDATE in `cat ${DATELIST}` ; do 
	echo "Search for files with ${PAIRDATE} in Geocoded"
	find . -type f -name "*${PAIRDATE}*" -delete
	#find . -type f -name "*${PAIRDATE}*" -exec echo {} \;
done 

cd .. 

cd GeocodedRasters
for PAIRDATE in `cat ${DATELIST}` ; do 
	echo "Search for files with ${PAIRDATE} in GeocodedRasters"
	find . -type f -name "*${PAIRDATE}*" -delete
	#find . -type f -name "*${PAIRDATE}*" -exec echo {} \;
done 



echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CLEANED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


