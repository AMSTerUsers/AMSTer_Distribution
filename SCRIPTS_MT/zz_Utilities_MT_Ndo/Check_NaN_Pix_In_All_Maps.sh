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
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- getLineThroughStack
# 
#
# New in Distro V 1.0 20240806:	- set up
# New in Distro V 1.1 20250114:	- test if timeLine_COL_LIN.txt exist + cosmetic by DS
# New in Distro V 1.2 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

COLX=$1
LINY=$2

PWDIR=$(pwd)


# Vérifie que deux arguments sont fournis
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <COLX> <LINY>"
    exit 1
fi

TIMELINE_FILE="timeLine${COLX}_${LINY}.txt"

getLineThroughStack "${PWDIR}" "${COLX}" "${LINY}" > /dev/null 2>&1

#Check if TIMELINE_FILE exist
if [ ! -f "${TIMELINE_FILE}" ]; then
    echo "Erreur : Le fichier ${TIMELINE_FILE} n'existe pas."
    exit 1
fi

# Check for nan in TIMELINE_FILE
if [ `${PATHGNU}/grep "nan" timeLine${COLX}_${LINY}.txt | wc -l ` -gt 0 ];then
#if [ "$(${PATHGNU}/grep -c "nan" "${TIMELINE_FILE}")" -gt 0 ]; then
    echo "Nan detected at pixel ${COLX} ${LINY} in the following maps:"
    ${PATHGNU}/grep "nan" "${TIMELINE_FILE}"
    echo "See ${TIMELINE_FILE} for values in each map at that pixel"
    echo "   and timeLine${COLX}_${LINY}_NaNs.txt for list of maps with NaNs"    
    ${PATHGNU}/grep "nan" "${TIMELINE_FILE}" > "timeLine${COLX}_${LINY}_NaNs.txt"
else
    echo "No NaNs detected"
fi
