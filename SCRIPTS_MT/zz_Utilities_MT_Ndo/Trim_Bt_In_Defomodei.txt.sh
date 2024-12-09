#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at removing from a DefoModei.txt file all the lines for which the 
# temporal baseline is above a given threshold. 
#
# Parameters : - path to DefoModei.txt    
#              - max Bt
#
# Dependencies:	- none
#
# New in Distro V 1.0 20241031:	- setup
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 31, 2024"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

DEFOMODE=$1			# path to DefoModei.txt   
MAXBT=$2 			# lines with Bt above that value will be removed from DefoModei.txt   

cat ${DEFOMODE} | wc -l


# Filter lines by extracting BT values and checking if they're within the specified range
${PATHGNU}/gawk -v maxbt="${MAXBT}" '
{
    if (match($0, /BT-?[0-9]+\.?[0-9]*/)) {       # Find "BT<num>" pattern
        bt_value = substr($0, RSTART+2, RLENGTH-2);   # Extract numeric part
        bt_value += 0;                               # Convert to numeric

        # Check if the absolute value of bt_value is below the maxbt threshold
        if (bt_value <= maxbt && bt_value >= -maxbt) {
            print $0                                # Print the line if within range
        }
    }
}' "${DEFOMODE}" > "${DEFOMODE}_Below_${MAXBT}days.txt"

cat ${DEFOMODE}_Below_${MAXBT}days.txt | wc -l