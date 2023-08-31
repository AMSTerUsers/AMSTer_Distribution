#!/bin/bash
######################################################################################
# This script checks that S1 data are OK (4 col and consistent regarding possible orbit update).  
#
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Dec 05, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

MASSPROCESS1=$1	# SAR_MASSPROCESS/Region dir where /Geocoded and /GeocodedRasters. 
MASSPROCESS2=$2	# SAR_MASSPROCESS/Region dir where /Geocoded and /GeocodedRasters. 

MASSPROCESS=`dirname ${MASSPROCESS1}`

PATHMODE1=$3		# MSBAS/region/MODESi dir where data from mode and MODESi.txt to check are. 
PATHMODE2=$4		# MSBAS/region/MODESi dir where data from mode and MODESi.txt to check are. 

MODE1=`basename ${PATHMODE1}`
MODE2=`basename ${PATHMODE2}`

# Check defo maps in SAR_MASSPROCESS
####################################
# Remove possible duplicate geocoded products in SAR_MASSPROCESS/.../Geocoded/... 
# i.e. remove in each MODE (but Ampl) possible products from same pair of dates but with different Bp, Ha etc.. that would results from 
# reprocessing with updated orbits. If duplicated product detected, it keeps only the most recent product.  
	echo "Remove possible duplicate pair files in all geocoded modes but Ampl"
	cd ${MASSPROCESS1}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${MASSPROCESS2}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	wait
	echo "Possible duplicate files cleaned"
	echo ""	

if [ -d ${PATHMODE1} ] && [ -d ${PATHMODE2} ] ; then 
	
	# Remove possible broken links in MSBAS/.../MODEi and clean corresponding files 
	################################################################################
	# (clean if required MODEi.txt and Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt if any)
		echo "Remove Broken Links and Clean txt file in existing SAR_MASSPROCESS/MODEi (e.g. DefoInterpolx2Detrend) dirs"
		Remove_BrokenLinks_and_Clean_txt_file.sh ${PATHMODE1} &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${PATHMODE2} &
		wait
		echo "Possible broken links in former existing MODEi dir are cleaned"
		echo ""

	# Remove possible lines with less that 4 columns
		mv ${PATHMODE1}.txt ${PATHMODE1}_all4col.txt
		mv ${PATHMODE2}.txt ${PATHMODE2}_all4col.txt
		${PATHGNU}/gawk 'NF>=4' ${PATHMODE1}_all4col.txt > ${PATHMODE1}.txt 
		${PATHGNU}/gawk 'NF>=4' ${PATHMODE2}_all4col.txt > ${PATHMODE2}.txt
		rm -f ${PATHMODE1}.txt ${PATHMODE1}_all4col.txt ${PATHMODE1}.txt ${PATHMODE2}_all4col.txt
		echo "All lines in MODEi.txt have 4 columns"
		echo ""

	# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
		cd ${PATHMODE1}
		cd .. 
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		_Check_bad_DefoInterpolx2Detrend.sh ${MODE1} ${MASSPROCESS} &
		_Check_bad_DefoInterpolx2Detrend.sh ${MODE2} ${MASSPROCESS} &
		wait
		echo "All lines in former existing MODEi.txt are ok"
		echo ""

fi

echo ++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES/MODES CHECKED - HOPE IT WORKED"
echo ++++++++++++++++++++++++++++++++++++++++++

