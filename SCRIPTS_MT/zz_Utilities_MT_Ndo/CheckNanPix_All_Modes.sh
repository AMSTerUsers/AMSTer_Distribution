#!/bin/bash
######################################################################################
# This script checks that there is no NaN at a specific pixel COL LIN  in each maps for all modes
# in SAR_MASSPROCESS/SAT/REGION_TRK/SM_ZOOM_ML/Geocoded/DefoInterpolx2Detrend
# when provided with a path SAR_MASSPROCESS/SAT/ as input. 
#
# This script launch Check_NaN_Pix_In_All_Maps.sh 
# Coordinates of the pix to check are given as X Y. All defo maps must have a hdr file. 
# The script will run a getLineThroughStack and output the pairs for which there are NaNs. 
#
# Must be launnched in where all envi files are, e.g.: 
#			- SAR_MASSPROCESS/SAT/REGION_TRK/SM_ZOOM_ML/Geocoded/Ampli, or 
#			- SAR_MASSPROCESS/SAT/REGION_TRK/SM_ZOOM_ML/Geocoded/DefoInterpolx2Detrend, or
#			- MSBAS/REGION/DefoInterpolx2Detrend
#
# Parameters:	- fullpath to dir SAR_MASSPROCESS/SAT/
# 				- REGION name 
# 				- X coordinate of pixel to test
#				- Y coordinate of pixel to test
#
# Dependencies:	- getLineThroughStack
# 				- Check_NaN_Pix_In_All_Maps.sh 
# 
#
# New in Distro V 1.0 20250114:	- set up
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Jan 14, 2025"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# Check if 3 arguments are given
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <directory> <region> <columns> <lines>"
    exit 1
fi

CURRENT_DIR=$(pwd)

INPUT_DIR=$1
REGION=$2
COL=$3
LIN=$4

# Ckeck if INPUT_DIR exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Erreur : Le répertoire $INPUT_DIR n'existe pas."
    exit 1
fi

echo "I will check for NaN in all modes in : $INPUT_DIR"
echo " at pixel : Col : $COL ; Lin : $LIN"

# find all modes in  */SMNoCrop*
DIRECTORIES=$(find "$INPUT_DIR" -maxdepth 2 -type d -path "*/${REGION}*/SMNoCrop*")

# test if modes exist
if [ -z "$DIRECTORIES" ]; then
    echo "No mode found, check the path and region name to test."
    exit 0
fi

# launch Check_NaN_Pix_In_All_Maps.sh for each mode
while IFS= read -r DIR; do
    DIRGEOC="$DIR/Geocoded/DefoInterpolx2Detrend"
    
    #  check if /Geocoded/DefoInterpolx2Detrend exists
    if [ -d "$DIRGEOC" ]; then
        cd "$DIRGEOC" || { echo "Impossible d'accéder à $DIRGEOC"; continue; }
        echo "Test for mode : $DIRGEOC"
        Check_NaN_Pix_In_All_Maps.sh "$COL" "$LIN"
    else
        echo "No Geocoded/DefoInterpolx2Detrend in $DIR"
    fi
done <<< "$DIRECTORIES"

# go back to launchdir
cd "$CURRENT_DIR"

echo "All modes done."
