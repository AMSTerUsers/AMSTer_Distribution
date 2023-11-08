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
# New in Distro V 1.0 (Jul 15, 2019):	- Based on Beta V1.0
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

GEOTIFF=$1

# to 
gdal_translate -of KMLSUPEROVERLAY ${GEOTIFF} ${GEOTIFF}.kmz -co FORMAT=JPEG
