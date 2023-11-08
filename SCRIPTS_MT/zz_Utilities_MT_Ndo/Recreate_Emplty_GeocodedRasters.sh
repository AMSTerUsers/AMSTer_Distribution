#!/bin/bash
# This script aims at recreating all empty raster files from  /GeocodedRasters/DefoInterpolx2Detrend
#
# Must be launched in SAR_MASSPROCESS/region where /Geocoded and /GeocodedRasters are.
# 
# Dependencioes: - gsed
#
# V1.0 (Oct 08, 2020)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

MAINDIR=$PWD

RASDIR=${MAINDIR}/GeocodedRasters/DefoInterpolx2Detrend
FILEDIR=${MAINDIR}/Geocoded/DefoInterpolx2Detrend

ReDoRaster()
{
	unset NAMETOPLOT
	local NAMETOPLOT=$1
	cpxfiddle -w 5361 -q normal -o sunraster -c jet -M 1/1 -f r4 -l1 ${FILEDIR}/${NAMETOPLOT} > ${RASDIR}/${NAMETOPLOT}.ras
}

# search for all empty rasters
cd ${RASDIR}
find . -maxdepth 1 -type f -name "*.ras" -size 0 -print | while read filename
do
	NAMETOPLOT=`echo ${filename} | cut -d / -f 2 |  ${PATHGNU}/gsed 's/.ras//'`
	ReDoRaster "${NAMETOPLOT}"
done
