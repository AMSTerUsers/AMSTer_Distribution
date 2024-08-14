#!/bin/bash
######################################################################################
# This script check that there is no NaN at a specific pixel in each maps in pwd. 
# Coordinates of the pix to check are given as X Y. All defo maps must have a hdr file. 
# The script will run a getLineThroughStack and output the pairs for which there are NaNs. 
#
# Must be launnched in where all envi files are, e.g.: 
#			- SAR_MASSPROCESS/SAT/REGION_TRK/SM_ZOOM_ML/Geocoded/Ampli, or 
#			- SAR_MASSPROCESS/SAT/REGION_TRK/SM_ZOOM_ML/Geocoded/DefoInterpolx2Detrend, or
#			- MSBAS/REGION/DefoInterpolx2Detrend
#
# Parameters:	- X coordinate of pixel to test
#				- Y coordinate of pixel to test
#
# Dependencies:	- getLineThroughStack
# 
#
# New in Distro V 1.0 20240806:	- set up
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 6, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

COLX=$1
COLY=$2

PWDIR=$(pwd)

getLineThroughStack ${PWDIR} ${COLX} ${LINY} > /dev/null 2>&1	# mute output
if [ `${PATHGNU}/grep "nan" timeLine${COLX}_${LINY}.txt | wc -l ` -gt 0 ]
	then 
		echo "Nan detected at pixel {COLX} ${LINY} in the following maps:"
		${PATHGNU}/grep "nan" timeLine${COLX}_${LINY}.txt 
		echo "See timeLine${COLX}_${LINY}.txt for values in each maps at that pixel "
		echo "   and timeLine${COLX}_${LINY}_NaNs.txt for list of maps with NaNs"
		${PATHGNU}/grep "nan" timeLine${COLX}_${LINY}.txt > timeLine${COLX}_${LINY}_NaNs.txt
	else
		echo "No NaNs detected"
fi
 