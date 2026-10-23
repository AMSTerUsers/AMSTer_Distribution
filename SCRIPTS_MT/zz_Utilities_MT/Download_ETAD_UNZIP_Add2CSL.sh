#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at downloading ETAD data from ESA Dataspace server. It must be provided 
# with a dates dates for search (from/to dates), an AoI (as kml), a dir where zipped ETAD data 
# will be stored (destination dir) and the orbit number. Note that the destination dir must be
# in the form of /Your/Path/SAR_ETAD.ZIP/Your_Region_ORB/ 
#
# Then DETAD data will be unzip in /Your/Path/SAR_ETAD.UNZIP/Your_Region_ORB/ 
#
# Then the ETAD data are added to the CSL images if a CSL directroy is provided as 6th parameter
#
# Parameters:	- date from which to search ETAD data as YYYYMMDD (so for, there are no ETAD data before 20230701)
#				- date up to which to search ETAD data as YYYYMMDD 
#				- a kml with the AOI (full path)
#				- a path where to store the ETAD data (full path)
#				- the orbit number
#				- [optional]: full path to directory where the CSL images are read to add there the ETAD products 
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- SentinelDataDownloader from AMSTer Engine 
#				- have a login and pwd stored in .netrc in your home directory 
#				  (see manual, chapter 0.8) with the login and password to ESA dataspace server. 
#
# Hard coded:	- 
#
#
# New in Distro V 1.0:	- create 
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



START=$1				# date from which to search ETAD data 
STOP=$2					# date up to which to search ETAD data
KML=$3					# full path to a kml with the AOI  (e.g. /Volumes/hp-1650-Data_Share1/kml/ARGENTINA/Argentina_download_Polygon.kml)
ETADDIRZIP=$4			# full path to where to store the ETAD data (e.g./Volumes/hp-1650-Data_Share1/SAR_ETAD.ZIP/ARG_DOMU_LAGUNA_DEMGeoid_D_19)
ORBIT=$5				# the Sentinel1 orbit nr
DIRCSL=$6				# full path to directory where the CSL images are read (e.g./Volumes/D3611/SAR_CSL/S1/MUSTANG_D_19/NoCrop)

RUNDATE=$(date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g")
RNDM1=$(( $RANDOM % 10000 ))

mkdir -p "${ETADDIRZIP}"

# Download data
###############
echo ""
echo " // Download ETAD products in ${ETADDIRZIP} from ${START} to ${STOP}"
SentinelDataDownloader from=${START} to=${STOP} kml="${KML}" destDir="${ETADDIRZIP}" orbit=${ORBIT} -ETAD 

# store info of last download
KMLFILE=$(basename ${KML})
echo " // and store info in "${ETADDIRZIP}"/_Last_ETAD_Download_orb"${ORBIT}"_"${KMLFILE}"_"${RUNDATE}"_"${RNDM1}".txt"
echo "from=${START} to=${STOP}" > "${ETADDIRZIP}"/_Last_ETAD_Download_orb"${ORBIT}"_"${KMLFILE}"_"${RUNDATE}"_"${RNDM1}".txt

# Unzip data
############
ETADDIRUNZIP="${ETADDIRZIP/SAR_ETAD.ZIP/SAR_ETAD.UNZIP}"
mkdir -p "${ETADDIRUNZIP}"

echo ""
echo " // Uzip ETAD products in ${ETADDIRUNZIP} "

find "${ETADDIRZIP}" -type f -name "*.zip" | while read -r zip_file; do
    # Get relative path from base ZIP dir
    rel_path="${zip_file#${ETADDIRZIP}/}"

    # Get base name (without .zip)
    base_name="$(basename "$zip_file" .zip)"

    # We'll check if this ZIP file was already unzipped
    if [ -d "${ETADDIRUNZIP}/$base_name.SAFE" ] || [ -f "${ETADDIRUNZIP}/$base_name" ]; then
        echo "Already unzipped: $base_name"
    else
        echo "Unzipping: $base_name ..."
        unzip -uq "$zip_file" -d "${ETADDIRUNZIP}" # repalce niewer files 
    fi
done

#  Add to CDSL images
#####################
if [ $# -eq 6 ] ; then
	echo ""
	if [ -d "${DIRCSL}" ] 
		then 
			echo ""
			echo " // Add ETAD products to images in ${DIRCSL} from ${START} to ${STOP} "
			ETADDataReader "${DIRCSL}"  "${ETADDIRUNZIP}"  from=${START} to=${STOP}
			echo ""
		else 
			echo " // Can't add ETAD products to images from ${START} to ${STOP}: missing destination dir ${DIRCSL} "
	fi 
fi
echo ""
echo " // All done, hope it worked..."
echo ""
