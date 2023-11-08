#!/bin/bash
######################################################################################
# This script transforms a ENVI in Black and White kmz to be open in GoogleEarh for instance
#
# Parameters: 	- Envi file with path
#
# Dependencies: - gdal
#
# New in Distro V 1.0:	- Based on Beta V1.0
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

INPUTFILE=$1

# Black and white - OK
gdal_translate -scale -of ENVI ${INPUTFILE} ${INPUTFILE}Flat
gdal_translate -of KMLSUPEROVERLAY ${INPUTFILE}Flat ${INPUTFILE}Flat.kmz -co FORMAT=JPEG

rm -f  ${INPUTFILE}Flat.aux.xml

