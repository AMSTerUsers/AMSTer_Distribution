#!/bin/bash
# This script deletes all the *bil* files that are named with twice the same date 
# in the current directory and subdirectories.
#
# New in Distro V 1.1 :	- 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2024, Last modified on Jul 01, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "


# Define the base directory
base_dir="."

# Find and delete files where the dates are the same
find "$base_dir" -type f -name "*.bil*" | grep -E '_(20[0-9]{6})_\1_' | while read -r file; do
    echo "Deleting $file"
    rm "$file"
done
