#!/bin/bash
######################################################################################
# This script remove all files in Geocoded and GeocodedRasters dir that contains dates 
#   provided by a list of dates  
#
# Must be launched in dir that contains Geocoded and GeocodedRasters
# 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
######################################################################################

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


