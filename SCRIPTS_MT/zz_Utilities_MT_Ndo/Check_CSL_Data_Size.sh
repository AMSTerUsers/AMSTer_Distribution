#!/bin/bash
# The script list all csl images from the pwd where the size of the ./Data/SLCData.?? 
# file is not between two sizes provided as parameters
#
# Parameters:	- Min expected size of ./Data/SLCDara.?? in MB (SI units)
#				- Max expected size of ./Data/SLCDara.?? in MB (SI units) 
#
# Dependencies: 	- gstat
# 
# New in Distro V... 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 23, 2025"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

MINSIZE=$1		# in MB (SI units)
MAXSIZE=$2		# in MB (SI units)

MINSIZE=$((MINSIZE * 1000000))		# in bytes
MAXSIZE=$((MAXSIZE * 1000000))		# in bytes

if [ $# -lt 2 ] 
	then 
		echo "Usage $0 MINSIZE MAXSIZE" 
		exit
fi

if [ ${MINSIZE} -gt ${MAXSIZE}  ] 
	then 
		echo "MINSIZE (parm 1) must be smaller or equal to MAXSIZE (param 2)" 
		exit
fi

# Loop over all items in the current directory
for dir in */ ; do
    [ -d "$dir" ] || continue  # Skip if not a directory

    missing_subdirs=0
    if [ ! -d "$dir/Data" ]; then
        missing_subdirs=1
        break
    fi

    # If any required subdirectory is missing
    if [ "$missing_subdirs" -eq 1 ]; then
        echo "missing ./Data in $dir"
        continue
    fi

    # If SLCData.* exists but does not have the right size
    DataFile=$(find "$dir/Data" -maxdepth 1 -type f -name "SLCData.*" )
    
    DataFileSize=$(${PATHGNU}/gstat -c%s "${DataFile}")
    #echo "${MINSIZE} < ${DataFileSize} > ${MAXSIZE}"
    if [ "${DataFileSize}" -lt "${MINSIZE}" ] || [ "${DataFileSize}" -gt "${MAXSIZE}" ]
    	then
        	echo "Wrong image $dir: min=${MINSIZE} < size=${DataFileSize} >  max=${MAXSIZE} "
    fi
done
