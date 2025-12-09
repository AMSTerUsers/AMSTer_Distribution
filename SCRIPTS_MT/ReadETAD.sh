#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at reading ETAD products and add them in corresponding CSL S1  
# images from the pwd. 
# The script must be provided with 
#	- the path where the S1 images are stored in CSL format. That is where the ETAD layers
#     will be added in the sub directories, e.g. 
#	  .../SAR_CSL/S1/YourRegion_Track/NoCrop/S1sat_Orbit_YYYYMMDD_A/D.csl/Data/Framex.csl/Data/SWibj.csl/ETADData   
#	  (where sat is A, B, C... and Orbit, x and i and j are integers, and YYYYMMDD is the date of the img)
# 	- the path where the UNZIPPED ETAD products are stored 
#	- the date from which to add the ETAD prtoducts to CSL images. If a date is provided, it will check all images from that date .
#	  If no date is provided, it would check all images from the CSL directory, which could be time consuming. 
#	  Since so far (as on September 2025) the ETAD products are only provided from end of July 2023, 
# 	  if no date is provided, to be sure not to waste too much time, it will try to read only ETAD data from 20230701.
#	  Change hard coded line in script if you want to bypass that date, or provide the script with any starting date. "
#		
#
#		Note that so far (on September 2025) the ETAD products are only provided from end of 
# 	  July 2023. 
#
# 
# Parameters :  - path to dir where the CSL images are stored
#				- path to dir where the UNZIPPED ETAD products are stored
#				- Date from which to start the reading 
#
# e.g. ReadETAD.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/ARG_DOMU_LAGUNA_DEMGeoid_A_18/NoCrop_TMP/ /Volumes/hp-1650-Data_Share1/SAR_ETAD.UNZIP/ARG_DOMU_LAGUNA_DEMGeoid_A_18  20230701
#
# Hard coded: - date of July 1st 2023 as starting point if no starting date is provided, because as from Sept 2025, 
#				ESA hasn't produced ETAD products before that date  
#
# Dependencies:
#	 - 
#
# New in Distro V 1.0:		- 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2025/08/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1,0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 23, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

DIRCSL=$1
ETADDIR=$2
FROMDATE=$3



# Check for S1*.csl directories
if ! ( find "${DIRCSL}" -maxdepth 1 -type d -name "S1*.csl" | grep -q . ) ; then
    echo "No directory named S1*.csl exists in ${DIRCSL}; you may have provided with a wrong SAR_CSL directory."
    exit 1
fi

# Check for ETAD directories
if ! ( find "${ETADDIR}" -maxdepth 1 -type d -name "S1*.SAFE" | grep -q . ) ; then
    echo "No directory named S1*.SAFE exists in ${ETADDIR}; you may have provided with a wrong UNZIPPED ETAD data directory"
    exit 1
fi

if [ "${FROMDATE}" == "" ]
	then 
		echo " // Search to add ETAD layers to all you SLC images in dir... May take a lot of time..."
		echo " // To be sure of not wasting too much time, I will try from 20230701 because ESA hasn't released ETAD data before that date"
		echo " // Change hard coded line in script if you want to bypass that date or provide the script with any starting date. "
		
		ETADDataReader "${DIRCSL}" "${ETADDIR}" from=20230701	# Beware of quotes in dir names if they have special characters 
	else 
		ETADDataReader "${DIRCSL}" "${ETADDIR}" from=${FROMDATE} 
fi

echo 
echo "All done; Hope it worked"

