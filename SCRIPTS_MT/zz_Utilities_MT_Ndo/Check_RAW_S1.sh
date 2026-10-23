#!/bin/bash
# The script list all directories from the pwd that do not contain at least the following sub-directories:
# - annotation 
# - measurement
# - preview
# - support
# and/or where measurement directory does not contains x tiff files 
# (where x is an integer provided as parameter)
# in order to detect possible bad Sentinel 1 raw unzipped data 
#
# Parameters:	- Nr of files expected in measurement sub dir
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies: 	- none
# 
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


NRMEASUREMENT=$1

if [ $# -lt 1 ] 
	then 
		echo "Usage $0 Nr_Of_Expected_Measurement_Files" 
		exit
fi


# List of required subdirectories
required_subdirs=("annotation" "measurement" "preview" "support")

# Loop over all items in the current directory
for dir in */ ; do
    [ -d "$dir" ] || continue  # Skip if not a directory

    missing_subdirs=0
    for sub in "${required_subdirs[@]}"; do
        if [ ! -d "$dir$sub" ]; then
            missing_subdirs=1
            break
        fi
    done

    # If any required subdirectory is missing
    if [ "$missing_subdirs" -eq 1 ]; then
        echo "$dir"
        continue
    fi

    # If measurement exists but does not have exactly 6 TIFF files
    tiff_count=$(find "$dir/measurement" -maxdepth 1 -type f \( -iname "*.tif" -o -iname "*.tiff" \) | wc -l)
    if [ "$tiff_count" -ne ${NRMEASUREMENT} ]; then
        echo "$dir"
    fi
done
