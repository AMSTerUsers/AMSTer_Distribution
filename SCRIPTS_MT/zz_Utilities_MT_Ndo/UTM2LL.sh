#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script changes an UTM map in ENVI format into a Lat Long map considereing EPSG 4326  
#
#
# Parameters :  - path to map to change
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	 
#    	- gdal
#
# New in Distro V 1.1 (Oct 10, 2023): - secure handling of possible extensions
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

INPUTMAP=$1

PATHMAP=`dirname ${INPUTMAP}`
MAPNAME=`basename ${INPUTMAP}`

# test if there is an extention
if [[ ${MAPNAME} == *.* ]]
	then 
		MAPEXT=".${MAPNAME##*.}"
		MAPONLYNAME="${MAPNAME%.*}"
	else 
		MAPEXT=""
		MAPONLYNAME="${MAPNAME}"
fi


# just in case of prblm with or without extensions...
mkdir -p ${PATHMAP}/UTM_MAPS
cp "${INPUTMAP}" ${PATHMAP}/UTM_MAPS/ 
cp "${PATHMAP}/${MAPONLYNAME}.hdr"  ${PATHMAP}/UTM_MAPS/ 

gdalwarp -of ENVI -t_srs EPSG:4326 "${INPUTMAP}" "${PATHMAP}/${MAPONLYNAME}_LL${MAPEXT}"


