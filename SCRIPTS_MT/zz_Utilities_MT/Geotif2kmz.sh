#!/bin/bash
######################################################################################
# This script transforms a geotiff in kmz
# Geotiff is created eg using envi 
# Note : you may want to improve by adapting the color table. See for instance Envi2ColorKmz.sh
#
# Parameters: geotiff file with path
#
# Dependencies: - gdal
#
# New in Distro V 1.0:	- Based on Beta V1.0
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
#####################################################################################
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 15, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

GEOTIFF=$1

# to 
gdal_translate -of KMLSUPEROVERLAY ${GEOTIFF} ${GEOTIFF}.kmz -co FORMAT=JPEG
