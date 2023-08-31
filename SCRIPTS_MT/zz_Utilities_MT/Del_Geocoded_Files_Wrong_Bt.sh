#!/bin/bash
######################################################################################
# This script remove all files in Geocoded and GeocodedRasters that have a Bt larger than $1.
#
# Must be launched in SAR_MASSPROCESS dir where Geocoded and GeocodedRasters are. 
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2018/11/05 -                         
######################################################################################

MAXBT=$1

rm -f MODES.TXT
# Check available modes
ls Geocoded > MODES.TXT # List all modes 
NROFALLMODE=`wc -l < MODES.TXT`

for MODE in `cat MODES.TXT`
   do
	cd Geocoded/${MODE}
	for FILETOCHECK in `ls *`
		do
			BT=`echo ${FILETOCHECK} | ${PATHGNU}/gawk -F 'BT' '{print $NF}' | cut -d d -f1 | ${PATHGNU}/gsed "s/-//"` 
			if [ ${BT} -ge ${MAXBT} ] ; then 
				echo "Remove ${FILETOCHECK}"
				rm -f ${FILETOCHECK}
			fi
	done
	cd ../..	
	
	cd GeocodedRasters/${MODE}
	for FILETOCHECK in `ls *`
		do
			BT=`echo ${FILETOCHECK} | ${PATHGNU}/gawk -F 'BT' '{print $NF}' | cut -d d -f1 | ${PATHGNU}/gsed "s/-//"` 
			if [ ${BT} -ge ${MAXBT} ] ; then 
				echo "Remove ${FILETOCHECK}"
				rm -f ${FILETOCHECK}
			fi
	done	
	cd ../..
done

rm MODES.TXT

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

