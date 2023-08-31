#!/bin/bash
######################################################################################
# This script check that there is no data at a specific point in each burst. These points
# are manually set in a file named BurstMap_REGION_TRK.txt (e.g. by looking in QGIS with 
# module "Value Tool" at the coordinate of a point known to be always coherent in a defo
# map of that region, for each of the bursts. Remember that burst KMLs can be found in 
# each SAR_CSL/SAT/TRK/NoCrop/Img.csl/Info/PerBurstInfo). 
# The script will run a getLineThroughStack for each point and output the dates at which 
# there is no data for some of these bursts. 
#
# List BurstMap_REGION_TRK.txt MUST end with one and only one carriage return
#
# Note: 
#	If script is used for MSBAS results, files to check are named MSBAS_YYYYMMDDThhmmss...
#		and timeLine${COLX}_${LINY}.txt will contain "dates times values" in columns. 
#	If script is used for checking other type of date '(such as amplitudes..), files may
#		be of other type and naming. It will then get through all the envi files (supposed  
#		all of the same size in the dir) and store results in timeLine${COLX}_${LINY}.txt 
#		that will contain "name_of_the_files values" in columns. 
# 
# Must be launnched in where all envi files are, e.g.: 
#			- SAR_MASSPROCESS/SAT/REGION_TRK/SM_ZOOM_ML/Geocoded/Ampli, or 
#			- SAR_MASSPROCESS/SAT/REGION_TRK/SM_ZOOM_ML/Geocoded/DefoInterpolx2Detrend, or
#			- MSBAS/REGION/DefoInterpolx2Detrend
#
# Parameters: - path to BurstMap_REGION_TRK.txt (i.e. an ascii file containing a header 
#						"Lin(Y) Col(X) Swath,Burst" then the list of points as lines and columns 
#						separated by a space and followed by BurstPosition as Swath,Burst. 
#						Notes:
#							+ regions that are overlapped by two bursts can be tested as 
#							  well and can be noted by their Swath,Burst+Burst numbers
#							+ if some regions are depicted by the same burst but holding 
#							  two different names, it can be noted as Swath,Burst-SwathBurst 
#			  - Path to dir with envi files to check
#			  - KEEPFILES if you want to keep the timeLine${COLX}_${LINY}.txt files
#
# Dependencies:	- getLineThroughStack
# 
#
# New in V 1.1:	- 
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2020/01/27 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Nov 10, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

BURSTMAP=$1
PATHTODIR=$2
KEEP=$3

cd ${PATHTODIR}

i=0
while read LINY COLX SWBST
do	
	if [ "${LINY}" == "Lin(Y)" ]	# check that it contains only digits, i.e. skip header
		then
    		echo "Skip header"
    		i=`echo "${i}+1 " | bc `
    		NBURSTS=`cat ${BURSTMAP} | wc -l`
    		NBURSTS=`echo "(${NBURSTS} -1 ) " | bc `
    		echo
		else
   			 echo "Check ${i}th/${NBURSTS} burst mapped at pixel ${COLX} ${LINY} (X,Y):"
   			 getLineThroughStack ${PATHTODIR} ${COLX} ${LINY} > /dev/null 2>&1	# mute output
   			 if [ `${PATHGNU}/grep "nan" timeLine${COLX}_${LINY}.txt | wc -l ` -gt 0 ]
   			 	then 
   			 		${PATHGNU}/grep "nan" timeLine${COLX}_${LINY}.txt > _MissingBursts_${SWBST}.txt
   			 		echo "	=> ${i}th burst, named \"${SWBST}\" (Swath,Burst), contains a NaN (and hence is porbably missing) at the following date(s): "
   			 		cat _MissingBursts_${SWBST}.txt
   			 		echo "	  (See ${PATHTODIR}/_MissingBursts_${SWBST}.txt)"
   			 	else
   			 		#Get min max of values in col3
					MINPIX=`${PATHGNU}/gawk '{print $3}' timeLine${COLX}_${LINY}.txt | tail -1`
					MAXPIX=`${PATHGNU}/gawk '{print $3}' timeLine${COLX}_${LINY}.txt | head -1`
   			 		echo "	Min value = ${MINPIX}"
   			 		echo "	Max value = ${MAXPIX}"
   			 		if [ "${MINPIX}" == "${MAXPIX}" ] && [ "${MINPIX}" == "0.000000" ]
   			 			then 
   			 				echo "	=> ${i}th burst, named \"${SWBST}\" (Swath,Burst), all null ? Please check burst or pixel coordinates."
   			 				echo "Swath,Burst ${SWBST} all null at pixel \"${COLX} ${LINY}\" (ColX,LinY)" > _NullBursts_${SWBST}.txt
   			 				echo "	  (See ${PATHTODIR}/_NullBursts_${SWBST}.txt)"
   			 			else 
   			 				echo "	=> ${i}th burst, named \"${SWBST}\" (Swath,Burst), seems OK "
   			 		fi
   			 fi
   			 if [ "${KEEP}" != "KEEPFILES" ] 
   			 	then 
   			 		rm timeLine${COLX}_${LINY}.txt
   			 fi
   			 i=`echo "${i}+1 " | bc `
   			 echo 
	fi


done < ${BURSTMAP}

echo "All done. "

