#!/bin/bash
######################################################################################
# This script delete all lines in MSBAS/region/DefoInterpolDetrendi.txt or in table_0_Bp_0_Bt.txt  
# that contain pairs computed from baseline plot optimisation (provided as list of MASdate_SLVdate).  
# It keeps the links in MSBAS/region/DefoInterpolDetrendi
#
# It saves uncleaned DefoInterpolDetrendi.txt as DefoInterpolDetrendi.txt_NotOptimized.txt
#
# Parameters:	- path to Mode to clean, i.e. path to MSBAS/.../DefoInterpolDetrend1 (WITHOUT .txt)
#				  or path to file table_minBp_maxBp_minBt_maxBt.txt
#				- List of pairs to remove in the form of MasDate_SlvDate (with path)
#
# Depedencies: 	- gnu find
#
# New in V1.1: 	- debug quotes in gsed and change name of cleaned file
# New in V1.2: 	- can also clean table from Prepa_MSBAS.sh
# New in V1.3 (May 16, 2023): 	- test file with -f 
#				- backup table before optim
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

MODETOCLN=$1	# Mode to clean (e.g. path to MSBAS/.../DefoInterpolDetrend1 or path to file table_0_Bp_0_Bt.txt)
PAIRLIST=$2		# list if pairs to remove from MSBAS/region/MODETOCLN(.txt) e.g. MSBAS/region/DefoInterpolDetrend1(.txt)

if [ -f "${MODETOCLN}" ]
	then
		echo "Cleaning table prepared with Prepa_MSBAS.sh, table_0_Bp_0_Bt.txt I guess, in the form of list of: MAS SLV BP BT"
		TABLETOCLEANNOEXT="${MODETOCLN%.*}"  # path and file name without extension 
		cp ${MODETOCLN} ${MODETOCLN}_NotOptimized.txt
	else 
		echo "Cleaning table prepared with build_header_msbas_criteria.sh, mode ${MODETOCLN}.txt I guess, in the form of: name BP MAS SLV"	
		TABLETOCLEANNOEXT=${MODETOCLN}
		cp ${MODETOCLN}.txt ${MODETOCLN}.txt_NotOptimized.txt
fi
echo

PAIRLISTNAME=$(basename ${PAIRLIST})

if [ $# -lt 2 ] ; then echo “\n Usage $0 ModeToClean ListOfPairs”; exit; fi

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
#eval RNDM=`echo $(( $RANDOM % 10000 ))`

# backup mode
# When used in routine, should merge ${MODETOCLN}.txt and last ${MODETOCLN}_NotOptimized.txt 
# before making backup in order to be sure to always sort the most complete and recent list of pairs
cp ${TABLETOCLEANNOEXT}.txt ${TABLETOCLEANNOEXT}_Optimized_${PAIRLISTNAME}_${RUNDATE}.txt 

while read -r PAIRTOCLN
do	
	if [ -f "${MODETOCLN}" ]
		then
			STRINGTOCLN=`echo ${PAIRTOCLN} | tr _ "\t" ` 
		else 
			STRINGTOCLN=${PAIRTOCLN}
	fi
	
	echo "Search and remove lines with ${STRINGTOCLN} in ${MODETOCLN}.txt"
	${PATHGNU}/gsed -i "/${STRINGTOCLN}/d" ${TABLETOCLEANNOEXT}_Optimized_${PAIRLISTNAME}_${RUNDATE}.txt 
done < ${PAIRLIST}


echo "Cleaned file in ${MODETOCLN}_Optimized_${PAIRLISTNAME}_${RUNDATE}.txt "

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "MODE FILE CLEANED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

