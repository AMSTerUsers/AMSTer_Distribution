#!/bin/bash
######################################################################################
# This script transforms a ENVI in Black and White kmz to be open in GoogleEarh for instance
#
# Parameters: 	- Envi file with path
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

INPUTFILE=$1

# Black and white - OK
gdal_translate -scale -of ENVI ${INPUTFILE} ${INPUTFILE}Flat
gdal_translate -of KMLSUPEROVERLAY ${INPUTFILE}Flat ${INPUTFILE}Flat.kmz -co FORMAT=JPEG

rm -f  ${INPUTFILE}Flat.aux.xml

