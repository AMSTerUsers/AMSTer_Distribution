#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at removing from a restrictedPairSelection(_DefoInterpolx2Detrend1).txt 
# file all the lines for which the temporal baseline in col 9 (Dt) is above a given threshold. 
#
# Parameters : - path to restrictedPairSelection_DefoInterpolx2Detrend1.txt 
#              - max Bt
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- none
#
# New in Distro V 1.0 20241031:	- setup
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

RESTRICTPAIRFILE=$1			# path to restrictedPairSelection(_DefoInterpolx2Detrend1).txt 
MAXBT=$2 					# lines with Bt above that value will be removed 

cat ${RESTRICTPAIRFILE} | wc -l


# Filter lines by extracting BT values and checking if they're within the specified range
${PATHGNU}/gawk -v maxbt="${MAXBT}" '
{
    if (NR <= 9) { 
        print; 
        next; 
    }
    if ($9 <= maxbt) {
        print;
    }
}' "${RESTRICTPAIRFILE}" > "${RESTRICTPAIRFILE}_Below_${MAXBT}days.txt"

cat ${RESTRICTPAIRFILE}_Below_${MAXBT}days.txt | wc -l