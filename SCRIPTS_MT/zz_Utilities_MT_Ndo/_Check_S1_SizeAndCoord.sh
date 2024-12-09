#!/bin/bash
######################################################################################
# This script checks the size (in bursts) and coorrdinates of corners of S1 images.
#   If you only want to read the nr of bursts and coordinates of an image, provide PATH and string Dummy
#
# Parameters:	- PATH to image in CSL format (e.g. /${PATH_1650}/SAR_CSL/S1/TRK/NoCrop/S1i_ORB_DATE_x.csl)
#				- either expected nr of bursts OR "Dummy" to simply read the nr of bursts and coordinates of an image
#				And if test against expected kml footprint (within hardcoded TOLERANCE):
#					- expected (0;0) longitude 
#					- expected (0;0) latitude 
#					- expected (maxRange;0) longitude 
#					- expected (maxRange;0) latitude 
#					- expected (0;maxAzimuth) longitude 
#					- expected (0;maxAzimuth) latitude 
#					- expected (maxRange;maxAzimuth) longitude 
#					- expected (maxRange;maxAzimuth) latitude 
#				Or if test against expected area of interest (no TOLERANCE needed): image must at least contains the coordinates below
#					- expected min long
#					- expected max long 
#					- expected min lat 
#					- expected max lat

#
# Note: expected lat or long are approximative coordinates. Corner of images will be searched for being max TOLERANCE deg from these coordinates, 
#       where TOLERANCE is a hard coded param
#
# Dependencies:	- bc
#
#
# Example of cmd line for VVP S1 Asc: 
#	_Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/DRC_VVP_A_174/NoCrop/S1B_174_20211209_A.csl 16 28.7532 -2.4225 30.2811 -2.0896 28.4441 -0.9607 29.9705 -0.6309 
# Example to run it for all images in dir (to be run in dir where images are stored):
#	find . -maxdepth 1 -type d -name "*.csl" | while read IMGNAME ; do _Check_S1_SizeAndCoord.sh ${IMGNAME} 16 28.7532 -2.4225 30.2811 -2.0896 28.4441 -0.9607 29.9705 -0.6309 ; done
# 
# New in V 1.1:	- ok if number of burst is not the same but at least greater
# New in V 2.0 (Sept 01, 2023):	- if 6 parameters are provided, then coordinates are supposed to be of Area Of Interest. Check that they are inside coordinates of bursts, whatever the TOLERANCE is. 
#				  if 10 parameters are provided, then coordinates are supposed to be of expected kml footprint. Check that they are inside coordinates of bursts within the TOLERANCE. 
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
TOLERANCE=0.05	# in decimal degrees
# ^^^ ----- Hard coded lines to check -- ^^^ 

# Check parameters
	case $# in
		6) 
			echo " Probably searching image footprint against AOI coordinates; no TOLERANCE needed"	
			;;
		10)
			echo " Probably searching image footprint against expected bursts, within TOLERANCE of ${TOLERANCE}"
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


IMGPATH=${1}	   # PATH to image in CSL format (e.g. /${PATH_1650}/SAR_CSL/S1/TRK/NoCrop/S1i_ORB_DATE_x.csl)
EXPECTEDNRBURSTS=${2}	   # expected nr of bursts (OR Dummy to simply read the coordinates of the corners)
if [ $# = 10 ] ; then 
	EXPECTEDMINRGMINAZLONG=${3}	# expected (0;0) longitude 
	EXPECTEDMINRGMINAZLAT=${4}	# expected (0;0) latitude 
	EXPECTEDMAXRGMINAZLONG=${5}	# expected (maxRange;0) longitude 
	EXPECTEDMAXRGMINAZLAT=${6}	# expected (maxRange;0) latitude 
	EXPECTEDMINRGMAXAZLONG=${7}	# expected (0;maxAzimuth) longitude 
	EXPECTEDMINRGMAXAZLAT=${8}	# expected (0;maxAzimuth) latitude 
	EXPECTEDMAXRGMAXAZLONG=${9}	# expected (maxRange;maxAzimuth) longitude 
	EXPECTEDMAXRGMAXAZLAT=${10}	# expected (maxRange;maxAzimuth) latitude 
fi
if [ $# = 6 ] ; then 
	EXPECTEDMINLONG=${3}	# expected min long
	EXPECTEDMAXLONG=${4}	# expected max long 
	EXPECTEDMINLAT=${5}		# expected min lat 
	EXPECTEDMAXLAT=${6}		# expected max lat
fi


IMGNAME=`basename ${IMGPATH}`


# Check Info files
if [ ! -s ${IMGPATH}/Info/burstSelection.txt ] ; then echo "${IMGPATH}/Info/burstSelection.txt is missing. Please check (may be error in reading S1 image or read with old version of AMSTerEngine.)" ; STATUS="UNKNOWN" ; echo "Status is : ${STATUS}"; exit ; else STATUS="OK" ; fi
if [ ! -s ${IMGPATH}/Info/SLCImageInfo.txt ] ; then echo "${IMGPATH}/Info/SLCImageInfo.txt is missing. Please check." ; STATUS="FAIL" ; echo "Status is : ${STATUS}" ; exit ; else STATUS="OK" ; fi
echo

# function
	function CheckProxymityKML()
		{
		unset EXPECTED
		unset IMGCOORD
		unset MSG
		unset MIN 
		unset MAX
		local EXPECTED=$1
		local IMGCOORD=$2
		local MSG=$3
		
		#if [ ${IMGCOORD} -gt `echo "${EXPECTED} - ${TOLERANCE}" | bc -l` ] && [ ${IMGCOORD} -st `echo "${EXPECTED} + ${TOLERANCE}" | bc -l` ] 
		MIN=`echo "${EXPECTED} - ${TOLERANCE}" | bc -l`
		MAX=`echo "${EXPECTED} + ${TOLERANCE}" | bc -l`

		if (( $(echo "${IMGCOORD} > ${MIN}" | bc -l) ))  && (( $(echo "${IMGCOORD} < ${MAX}" | bc -l) ))  
			then 
				if [ "${STATUS}" == "FAIL" ] ; then  STATUS="FAIL" ; else STATUS="OK" ; fi 	# needed to stay FAIL if at least one of the corner is bad
				echo -n "  OK   ; ${MSG} is in range: "				# -n = no carriage return to write next line on the same line 
			else 
				echo -n "  FAIL ; ${MSG} is out of range: "	# -n = no carriage return to write next line on the same line 
				STATUS="FAIL"	
		fi
		echo "${MIN} < ${IMGCOORD} < ${MAX}"		
		}
		
	function CheckProxymityAOI()
		{
		unset MINLAT
		unset MAXLAT
		unset MINLONG
		unset MAXLONG
		# Compare ${EXPECTEDMINLONG} ${EXPECTEDMAXLONG} ${EXPECTEDMINLAT} ${EXPECTEDMAXLAT} 
		# with min lat and long

		MINLONGTMP1=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]<ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MINRGMINAZLONG}" "${MINRGMAXAZLONG}")
		MINLONGTMP2=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]<ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MAXRGMINAZLONG}" "${MAXRGMAXAZLONG}")

		MAXLONGTMP1=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]>ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MINRGMINAZLONG}" "${MINRGMAXAZLONG}")
		MAXLONGTMP2=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]>ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MAXRGMINAZLONG}" "${MAXRGMAXAZLONG}")

		MINLATTMP1=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]<ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MINRGMINAZLAT}" "${MAXRGMINAZLAT}")
		MINLATTMP2=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]<ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MINRGMAXAZLAT}" "${MAXRGMAXAZLAT}")

		MAXLATTMP1=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]>ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MINRGMINAZLAT}" "${MAXRGMINAZLAT}")
		MAXLATTMP2=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]>ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MINRGMAXAZLAT}" "${MAXRGMAXAZLAT}")

		MINLONG=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]<ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MINLONGTMP1}" "${MINLONGTMP2}")
		MAXLONG=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]>ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MAXLONGTMP1}" "${MAXLONGTMP2}")
		MINLAT=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]<ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MINLATTMP1}" "${MINLATTMP2}")
		MAXLAT=$(${PATHGNU}/gawk 'BEGIN{if(ARGV[1]>ARGV[2]) print ARGV[1]; else print ARGV[2]}' "${MAXLATTMP1}" "${MAXLATTMP2}")

		echo ${MINLONG}
		echo ${MAXLONG}
		echo ${MINLAT}
		echo ${MAXLAT}

		# test Min Long
		if (( $(echo "${EXPECTEDMINLONG} > ${MINLONG}" | bc -l) ))  && (( $(echo "${EXPECTEDMINLONG} < ${MAXLONG}" | bc -l) ))  
			then 
				echo "  OK   ; Min Long is in range: "				# -n = no carriage return to write next line on the same line 
				STATUS="OK" 
			else 
				echo "  FAIL ; Min Long is out of range: "	# -n = no carriage return to write next line on the same line 
				STATUS="FAIL"	
		fi
		# test Max Long
		if (( $(echo "${EXPECTEDMAXLONG} < ${MAXLONG}" | bc -l) ))  && (( $(echo "${EXPECTEDMAXLONG} > ${MINLONG}" | bc -l) ))  
			then 
				if [ "${STATUS}" == "FAIL" ] ; then  STATUS="FAIL" ; else STATUS="OK" ; fi 	# needed to stay FAIL if at least one of the corner is bad
				echo "  OK   ; Max Long is in range: "				# -n = no carriage return to write next line on the same line 
			else 
				echo  "  FAIL ; Max Long is out of range: "	# -n = no carriage return to write next line on the same line 
				STATUS="FAIL"	
		fi
		# test Min Lat
		if (( $(echo "${EXPECTEDMINLAT} > ${MINLAT}" | bc -l) ))  && (( $(echo "${EXPECTEDMINLAT} < ${MAXLAT}" | bc -l) ))  
			then 
				if [ "${STATUS}" == "FAIL" ] ; then  STATUS="FAIL" ; else STATUS="OK" ; fi 	# needed to stay FAIL if at least one of the corner is bad
				echo  "  OK   ; Min Lat is in range: "				# -n = no carriage return to write next line on the same line 
			else 
				echo  "  FAIL ; Min Lat is out of range: "	# -n = no carriage return to write next line on the same line 
				STATUS="FAIL"	
		fi
		# test Max Lat
		if (( $(echo "${EXPECTEDMAXLAT} < ${MAXLAT}" | bc -l) ))  && (( $(echo "${EXPECTEDMAXLAT} > ${MINLAT}" | bc -l) ))  
			then 
				if [ "${STATUS}" == "FAIL" ] ; then  STATUS="FAIL" ; else STATUS="OK" ; fi 	# needed to stay FAIL if at least one of the corner is bad
				echo  "  OK   ; Max Lat is in range: "				# -n = no carriage return to write next line on the same line 
			else 
				echo   "  FAIL ; Max Lat is out of range: "	# -n = no carriage return to write next line on the same line 
				STATUS="FAIL"	
		fi
		}		
		
# Get the nr of swath 
	NRSWATH=`grep Swath ${IMGPATH}/Info/burstSelection.txt 2>/dev/null | wc -l`
	echo -n "Image ${IMGNAME} has ${NRSWATH} swath(s) "

# Check the total nr of bursts 
	TOTALBURSTS=0
	for i in $(seq 1 ${NRSWATH})			
	do 
		BURSTS=`grep Swath ${IMGPATH}/Info/burstSelection.txt 2>/dev/null | head -${i} | tail -1 | cut -d / -f 1`
		#echo "Bursts of Swath ${i} are: ${BURSTS}"
		NRBURSTS=`echo "${BURSTS}" | tr -cd ',' | wc -c` # nr of bursts = nr of coma +1
		NRBURSTS=`echo "${NRBURSTS} + 1" | bc -l`
		TOTALBURSTS=`echo "${TOTALBURSTS} + ${NRBURSTS}" | bc -l`
	done
	if [ "${EXPECTEDNRBURSTS}" == "Dummy" ]
		then 
			echo "and total nr of bursts is ${TOTALBURSTS}"
		else 
			if [ ${TOTALBURSTS} -ge ${EXPECTEDNRBURSTS} ]
				then 
					echo "and total nr of bursts is ${TOTALBURSTS}, that is greater or equal to expected (${EXPECTEDNRBURSTS})"	
					STATUS="OK"
				else 
					echo "and total nr of bursts is ${TOTALBURSTS} instead of ${EXPECTEDNRBURSTS} expected."
					echo "  Coordinates of corners are not checked. May be read by launching the following command though:"
					echo "  $0 ${IMGPATH} Dummy"
					STATUS="FAIL"	
					echo "Status is : ${STATUS}"
					exit 	
			fi
	fi

echo
# Get the coordinates of image 
MINRGMINAZLONG=`updateParameterFile ${IMGPATH}/Info/SLCImageInfo.txt "(0;0) longitude "` 
MINRGMINAZLAT=`updateParameterFile ${IMGPATH}/Info/SLCImageInfo.txt "(0;0) latitude "`
MAXRGMINAZLONG=`updateParameterFile ${IMGPATH}/Info/SLCImageInfo.txt "(maxRange;0) longitude"`
MAXRGMINAZLAT=`updateParameterFile ${IMGPATH}/Info/SLCImageInfo.txt "(maxRange;0) latitude"`
MINRGMAXAZLONG=`updateParameterFile ${IMGPATH}/Info/SLCImageInfo.txt "(0;maxAzimuth) longitude"`
MINRGMAXAZLAT=`updateParameterFile ${IMGPATH}/Info/SLCImageInfo.txt "(0;maxAzimuth) latitude"`
MAXRGMAXAZLONG=`updateParameterFile ${IMGPATH}/Info/SLCImageInfo.txt "(maxRange;maxAzimuth) longitude"`
MAXRGMAXAZLAT=`updateParameterFile ${IMGPATH}/Info/SLCImageInfo.txt "(maxRange;maxAzimuth) latitude"`

if [ "${EXPECTEDNRBURSTS}" == "Dummy" ]
	then 
		echo "Image corners are : "
		echo "	MINRG MINAZ : ${MINRGMINAZLONG} / ${MINRGMINAZLAT}"
		echo "	MAXRG MINAZ : ${MAXRGMINAZLONG} / ${MAXRGMINAZLAT}"
		echo "	MINRG MAXAZ : ${MINRGMAXAZLONG} / ${MINRGMAXAZLAT}"
		echo "	MAXRG MAXAZ : ${MAXRGMAXAZLONG} / ${MAXRGMAXAZLAT}"
		exit
	else 
		case $# in
			6) 
				# Searching image footprint against AOI coordinates; no TOLERANCE needed 
				CheckProxymityAOI ${EXPECTEDMINLONG} ${EXPECTEDMAXLONG} ${EXPECTEDMINLAT} ${EXPECTEDMAXLAT} 
				;;
			10)
				# Searching image footprint against expected bursts, within TOLERANCE of ${TOLERANCE} 
				CheckProxymityKML ${EXPECTEDMINRGMINAZLONG} ${MINRGMINAZLONG} "MinRG MinAZ LONG"
				CheckProxymityKML ${EXPECTEDMINRGMINAZLAT} ${MINRGMINAZLAT} "MinRG MinAZ LAT"
				CheckProxymityKML ${EXPECTEDMAXRGMINAZLONG} ${MAXRGMINAZLONG} "MinRG MinAZ LONG"
				CheckProxymityKML ${EXPECTEDMAXRGMINAZLAT} ${MAXRGMINAZLAT} "MaxRG MinAZ LAT"
				CheckProxymityKML ${EXPECTEDMINRGMAXAZLONG} ${MINRGMAXAZLONG} "MinRG MaxAZ LONG"
				CheckProxymityKML ${EXPECTEDMINRGMAXAZLAT} ${MINRGMAXAZLAT} "MinRG MaxAZ LAT"
				CheckProxymityKML ${EXPECTEDMAXRGMAXAZLONG} ${MAXRGMAXAZLONG} "MaxRG MaxAZ LONG"
				CheckProxymityKML ${EXPECTEDMAXRGMAXAZLAT} ${MAXRGMAXAZLAT} "MaxRG MaxAZ LAT"
				;;
			*) 
				echo "Unknown number of agrguments: 10 must be to check against kml footprint, 6 must be against min max Lat Long of AoI.  "
				echo "Exiting"
				exit 
				;;
	
		esac
fi		

echo "Status is : ${STATUS}"
