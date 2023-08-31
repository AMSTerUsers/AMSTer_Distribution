#!/bin/bash
# This script aims at recreating all empty raster files from  /GeocodedRasters/DefoInterpolx2Detrend
#
# Must be launched in SAR_MASSPROCESS/region where /Geocoded and /GeocodedRasters are.
# 
# Dependencioes: - gsed
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2020/10/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2020, Last modified on Oct 08, 2020"
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
