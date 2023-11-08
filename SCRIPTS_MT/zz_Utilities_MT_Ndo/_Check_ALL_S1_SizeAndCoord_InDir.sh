#!/bin/bash
######################################################################################
# This script checks the size (in bursts) and coorrdinates of corners of all S1 images in dir.
#   Images that are not compliant are moved in temporary quaratine dir. All results are stored in 
#   temp log files removed after 15 days: 
#		__Unverifiable_Images_*.txt"
#		___Wrong_Images_Images_*.txt
#		__Good_Images_Images_*.txt" 
#
# Parameters:	- PATH to DIR where image in CSL format are stored (e.g. /${PATH_1650}/SAR_CSL/S1/TRK/NoCrop/)
#				- either expected nr of bursts OR "Dummy" to simply read the nr of bursts and coordinates of an image
#				- expected (0;0) longitude 
#				- expected (0;0) latitude 
#				- expected (maxRange;0) longitude 
#				- expected (maxRange;0) latitude 
#				- expected (0;maxAzimuth) longitude 
#				- expected (0;maxAzimuth) latitude 
#				- expected (maxRange;maxAzimuth) longitude 
#				- expected (maxRange;maxAzimuth) latitude 

#
# Note: expected lat or long are approximative coordinates. Corner of images will be searched for being max TOLERANCE deg from these coordinates, 
#       where TOLERANCE is a hard coded param in _Check_S1_SizeAndCoord.sh
#
# Dependencies:	- bc
#				- gsed
# 
# New in V 1.1:	- typo in __Good and __Wrong images files to remove when older than 15 days
# New in V 1.2:	- yet another typo in __Wrong images files to remove when older than 15 days
# New in V 1.3:	- do not need TOLERANCE and may work with coordinates from AoI 
# New in V 1.4 (Sept 01, 2023):	- get TOLERANCE from  _Check_S1_SizeAndCoord.sh for display at the beginning of the script
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

TOLERANCEDISPLAY=`${PATHGNU}/ggrep "TOLERANCE=" ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT_Ndo/_Check_S1_SizeAndCoord.sh`

# Check parameters
	case $# in
		6) 
			echo " // Probably searching image footprint against AOI coordinates; no TOLERANCE needed"	
			;;
		10)
			echo " // Probably searching image footprint against expected bursts, within TORELANCE from _Check_S1_SizeAndCoord.sh, that is ${TOLERANCEDISPLAY}"
			;;
		*) 
			if [ "$2" != "Dummy" ] ; then 
				echo "Usage $0 PATH N MinRgMinAzLong MinRgMinAzLat MaxRgMinAzLong MaxRgMinAzLat MinRgMaxAzLong MinRgMaxAzLat MaxRgMaxAzLong MaxRgMaxAzLat (coordinates from kml) " 
				echo " or $0 PATH N ExpectedMinLong ExpectedMaxLong ExpectedMinLat ExpectedMaxLat (coordinates of Area Of Interest) "
				echo " Where:"
				echo "	N = expected number of bursts "
				echo "	PATH = Path to image in CSL format (e.g. /${PATH_1650}/SAR_CSL/S1/TRK/NoCrop/S1i_ORB_DATE_x.csl)"	
				echo ""
				exit
			fi
				;;
	
	esac


IMGPATH=${1}	   # PATH to image in CSL format (e.g. /${PATH_1650}/SAR_CSL/S1/TRK/NoCrop/)
EXPECTEDNRBURSTS=${2}	   # expected nr of bursts (OR Dummy to simply read the coordinates of the corners)
EXPECTEDMINRGMINAZLONG=${3}	# expected (0;0) longitude 
EXPECTEDMINRGMINAZLAT=${4}	# expected (0;0) latitude 
EXPECTEDMAXRGMINAZLONG=${5}	# expected (maxRange;0) longitude 
EXPECTEDMAXRGMINAZLAT=${6}	# expected (maxRange;0) latitude 
EXPECTEDMINRGMAXAZLONG=${7}	# expected (0;maxAzimuth) longitude 
EXPECTEDMINRGMAXAZLAT=${8}	# expected (0;maxAzimuth) latitude 
EXPECTEDMAXRGMAXAZLONG=${9}	# expected (maxRange;maxAzimuth) longitude 
EXPECTEDMAXRGMAXAZLAT=${10}	# expected (maxRange;maxAzimuth) latitude 


eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
eval RNDM1=`echo $(( $RANDOM % 10000 ))`

# Go to appropriate dir
cd ${IMGPATH}

# make log files
echo "Images with UNKNOWN status (see _Check_S1_SizeAndCoord.sh), i.e. read with old version of AMSTerEngine (or wrong image?)" > __Unverifiable_Images_${RUNDATE}_${RNDM1}.txt
echo "Images with FAIL status (see _Check_S1_SizeAndCoord.sh), i.e. wrong nr of bursts and/or corner coordinates" > __Wrong_Images_${RUNDATE}_${RNDM1}.txt
echo "Images with OK status (see _Check_S1_SizeAndCoord.sh), i.e. good nr of bursts and corner coordinates" > __Good_Images_${RUNDATE}_${RNDM1}.txt

find ${IMGPATH} -maxdepth 1 -type d -name "*.csl" | while read IMGNAME 
do 
	# get status
	STATUS=`_Check_S1_SizeAndCoord.sh ${IMGNAME} ${EXPECTEDNRBURSTS} ${EXPECTEDMINRGMINAZLONG} ${EXPECTEDMINRGMINAZLAT} ${EXPECTEDMAXRGMINAZLONG} ${EXPECTEDMAXRGMINAZLAT} ${EXPECTEDMINRGMAXAZLONG} ${EXPECTEDMINRGMAXAZLAT} ${EXPECTEDMAXRGMAXAZLONG} ${EXPECTEDMAXRGMAXAZLAT} | tail -1 | cut -d : -f 2  | ${PATHGNU}/gsed "s/ //g" `
	case ${STATUS} in 
		"UNKNOWN") 
			echo "Can't check image because  ${IMGNAME}/Info/burstSelection.txt is missing (may be read with old version of AMSTerEngine and fine, or be wrong image...)" 
			echo "${IMGNAME} status is UNKNOWN" >> __Unverifiable_Images_${RUNDATE}_${RNDM1}.txt
			;;
		"FAIL") 
			echo "${IMGNAME} has wrong nr of bursts or corners are not in expected range. Image is moved in __TMP_QUARANTINE and logged in __Wrong_Images.txt; please check if persist after few days" 
			echo "${IMGNAME} status is FAIL" >> __Wrong_Images_${RUNDATE}_${RNDM1}.txt
			_Check_S1_SizeAndCoord.sh ${IMGNAME} ${EXPECTEDNRBURSTS} ${EXPECTEDMINRGMINAZLONG} ${EXPECTEDMINRGMINAZLAT} ${EXPECTEDMAXRGMINAZLONG} ${EXPECTEDMAXRGMINAZLAT} ${EXPECTEDMINRGMAXAZLONG} ${EXPECTEDMINRGMAXAZLAT} ${EXPECTEDMAXRGMAXAZLONG} ${EXPECTEDMAXRGMAXAZLAT} >> __Wrong_Images_${RUNDATE}_${RNDM1}.txt
			IMG=`basename ${IMGNAME}`
			mkdir -p __TMP_QUARANTINE
			mv -f ${IMGNAME} __TMP_QUARANTINE/${IMG}
			 ;;
		"OK")
			echo "${IMGNAME} has good nr of bursts and corners are in expected range. Image is logged in __Good_Images.txt" 
			echo "${IMGNAME} status is OK" >> __Good_Images_${RUNDATE}_${RNDM1}.txt
			;;
		*)
			echo "Can't check image because  ${STATUS} is none of the expedted form. Please check " 
			echo "${IMGNAME} status is none of the expedted form. Please check" >> __Unverifiable_Images.txt
			;;
	esac			
done

# delete emplty lof files, i.e. that contains only one header file
if [ `cat __Unverifiable_Images_${RUNDATE}_${RNDM1}.txt | wc -l` -eq 1 ] ; then rm -f __Unverifiable_Images_${RUNDATE}_${RNDM1}.txt ; fi
if [ `cat __Wrong_Images_${RUNDATE}_${RNDM1}.txt | wc -l` -eq 1 ] ; then rm -f __Wrong_Images_${RUNDATE}_${RNDM1}.txt ; fi
if [ `cat __Good_Images_${RUNDATE}_${RNDM1}.txt | wc -l` -eq 1 ] ; then rm -f __Good_Images_${RUNDATE}_${RNDM1}.txt ; fi

# delete log files older than 15 days
find . -maxdepth 1 -name "__Unverifiable_Images_*.txt" -type f -mtime +15 -exec rm -f {} \;
find . -maxdepth 1 -name "__Wrong_Images_*.txt" -type f -mtime +15 -exec rm -f {} \;
find . -maxdepth 1 -name "__Good_Images_*.txt" -type f -mtime +15 -exec rm -f {} \;
