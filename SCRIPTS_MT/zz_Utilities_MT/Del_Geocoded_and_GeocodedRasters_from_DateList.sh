#!/bin/bash
######################################################################################
# This script remove all files in Geocoded and GeocodedRasters dir that contains dates 
#   provided by a list of dates  
#
# Must be launched in dir that contains Geocoded and GeocodedRasters
# 
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/06/26 -                         
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


