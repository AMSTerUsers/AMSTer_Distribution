#!/bin/bash
######################################################################################
# This script delete all lines in MSBAS/region/DefoInterpolDetrendi.txt  
# that are not in table obtained from running Extract_Baseline_3.sh
#  
# It keeps the links in MSBAS/region/DefoInterpolDetrendi
#
# It saves uncleaned DefoInterpolDetrendi.txt as DefoInterpolDetrendi.txt_Without_Extract3.txt
# and cleaned table in DefoInterpolDetrendi.txt_With_Extract3.txt
#
# Parameters:	- path to Mode to clean, i.e. path to MSBAS/.../DefoInterpolDetrend1 (WITHOUT .txt)
#				- List of pairs to remove in the form of table_0_Bp_0_Bt.txt as obtained 
#					from Extract_Baseline_3.sh (with path), that is 
#					table_0_Bp_0_Bt.txt_Sort_1_2_4_3_Max3.txt
#
# Depedencies: 	- gnu find
#
# New in V1.0 (May 11, 2023): 	- based on Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh
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
PAIRLIST=$2		# path to list if pairs to keep in the form of table_0_Bp_0_Bt.txt_Sort_1_2_4_3_Max3.txt

PAIRLISTNAME=$(basename ${PAIRLIST})

if [ $# -lt 2 ] ; then echo “\n Usage $0 ModeToClean ListOfPairs”; exit; fi

TABLETOCLEAN="${MODETOCLN}.txt"
TABLETOCLEANNAME=$(basename ${TABLETOCLEAN})

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
#eval RNDM=`echo $(( $RANDOM % 10000 ))`

# backup mode
# When used in routine, should merge ${MODETOCLN}.txt and last ${MODETOCLN}_NotOptimized.txt 
# before making backup in order to be sure to always sort the most complete and recent list of pairs
cp ${TABLETOCLEAN} ${TABLETOCLEAN}_Without_Extract3.txt 

rm -f ${TABLETOCLEAN}_With_Extract3.txt

while read -r MAS SLV DUMMY DUMMY
do	
	STRINGTOKEEP="${MAS}_${SLV}"
	
	echo "Keep lines with ${STRINGTOKEEP} in ${TABLETOCLEAN}"
	${PATHGNU}/ggrep ${STRINGTOKEEP} ${TABLETOCLEAN} >> ${TABLETOCLEAN}_With_Extract3.txt

done < ${PAIRLIST}

echo
echo "${TABLETOCLEAN}_With_Extract3.txt computed "

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "MODE FILE CLEANED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

