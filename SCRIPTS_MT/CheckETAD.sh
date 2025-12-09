#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at checking if ETAD data are present in each burst dir of each S1 
# images from the pwd. 
#
# Must be launched in dir /.../SAR_CSL/S1/YourRegion_Track/NoCrop
# 
# Parameters : - optional: from=YYYYMMDD to search only from a given date 
#			   - optional: to=YYYYMMDD to search only up to a given date 
# NOTE: If no from date is provided, it would check all images from the CSL directory, which could be time consuming. 
#	  Since so far (as on September 2025) the ETAD products are only provided from end of July 2023, 
# 	  if no date is provided, to be sure not to waste too much time, it will try to read only ETAD data from 20230701.
#	  Change hard coded line in script if you want to bypass that date, or provide the script with any starting date. 
#
# Hard coded: - date of July 1st 2023 as starting point if no starting date is provided, because as from Sept 2025, 
#				ESA hasn't produced ETAD products before that date  
#
# Dependencies:
#	 - grep
#
# New in Distro V 1.1:		- allows searching only from and or uo to specific dates  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2025/08/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1,1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 23, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

RUNDATE=$(date "+%m_%d_%Y_%Hh%Mm" | sed "s/ //g")
RNDM1=$(( RANDOM % 10000 ))
PWD=$(pwd)

# vvvvvvvv hard coded vvvvvvvvvv 
DEFAULTFROM=20230701		# date of frst ETAD available product as on Sept 2025
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


# Optional arguments: from=YYYYMMDD to=YYYYMMDD
FROM_DATE=""
TO_DATE=""

for arg in "$@"; do
    case $arg in
        from=*)
            FROM_DATE="${arg#*=}"
            TAGFROM="_FROM_${FROM_DATE}"	# For file naming
            ;;
        to=*)
            TO_DATE="${arg#*=}"
            TAGTO="_TO_${TO_DATE}"	# For file naming
            ;;
    esac
done

if [ "${FROM_DATE}" == "" ] ; then 
	echo " // Check ETAD layers to all you SLC images in dir... May take a lot of time..."
	echo " // To be sure of not wasting too much time, I will try from 20230701 because ESA hasn't released ETAD data before that date"
	echo " // Change hard coded line in script if you want to bypass that date or provide the script with any starting date. "
	FROM_DATE=${DEFAULTFROM} 
	TAGFROM="_FROM_${FROM_DATE}" 
fi

# Check for S1*.csl directories
if ! ls | ${PATHGNU}/grep -q '^S1.*\.csl$'; then
    echo "No directory named S1*.csl exists; you are not in a SAR_CSL directory."
    exit 1
fi

SOME_MISSING_ETAD="_ETAD_Missing_${RUNDATE}_${RNDM1}${TAGFROM}${TAGTO}.txt"
ALL_ETAD_OK="_ETAD_All_OK_${RUNDATE}_${RNDM1}${TAGFROM}${TAGTO}.txt"
NOBURSTS_FILES="_Images_With_Missing_BURSTS_${RUNDATE}_${RNDM1}${TAGFROM}${TAGTO}.txt"	# this should always be empty... 

# Loop over first-level subdirectories
find "${PWD}" -mindepth 1 -maxdepth 1 -type d -name "S1*.csl" | while read -r DIRIMG; do
    IMG_BASE=$(basename "${DIRIMG}")

    # Extract date from directory name (e.g., S1C_18_20250523_A.csl -> 20250523)
    DATE_PART=$(echo "$IMG_BASE" | grep -oE '[0-9]{8}')

    # Apply optional filters
    if [ -n "$FROM_DATE" ] && [ "$DATE_PART" -lt "$FROM_DATE" ]; then
        continue
    fi
    if [ -n "$TO_DATE" ] && [ "$DATE_PART" -gt "$TO_DATE" ]; then
        continue
    fi

    SW_DIRS=$(find "${DIRIMG}" -mindepth 4 -maxdepth 4 -type d -name 'SW*.csl')
    ALL_OK=true
    SOME_MISSING=false
	
    while read -r SW; do
        [ -z "$SW" ] && continue		# if exist
        if [ ! -d "${SW}/ETADData" ]; then
            ALL_OK=false
            SOME_MISSING=true
            SW_BASE=$(basename "${SW}")
            echo "ETAD data are missing at .../${IMG_BASE}.../${SW_BASE}"
        fi
    done <<< "${SW_DIRS}"

    echo
    if [ $(find "${DIRIMG}" -mindepth 4 -maxdepth 4 -type d -name 'SW*.csl' | wc -l) -eq 0 ]; then
        echo "No bursts dir at .../${IMG_BASE}"
        echo "No bursts dir at .../${IMG_BASE}" >> "${NOBURSTS_FILES}"
    elif $ALL_OK; then
        echo "All ETAD data are present at .../${IMG_BASE}"
        echo "All ETAD data are present at .../${IMG_BASE}" >> "${ALL_ETAD_OK}"
    else
        echo "ETAD data are missing at .../${IMG_BASE}" >> "${SOME_MISSING_ETAD}"
    fi
done

# Cleanup empty files
if [ ! -s "${SOME_MISSING_ETAD}" ]; then
   rm -f ${SOME_MISSING_ETAD}
fi
if [ ! -s "${ALL_ETAD_OK}" ]; then
   rm -f ${ALL_ETAD_OK}
fi
if [ ! -s "${NOBURSTS_FILES}" ]; then
   rm -f ${NOBURSTS_FILES}
fi

