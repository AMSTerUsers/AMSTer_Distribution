#!/bin/bash
######################################################################################
# This script remove all files in dir and subdirs that contains a certain string in their name 
# 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

#STRINGTOKILL=$1
STRINGTOKILL=20210730
TARGETDIR="$PATH_3601/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_20180222_Zoom1_ML4/GeocodedRasters"

cd ${TARGETDIR}

find . -maxdepth 2 -type f -name "*${STRINGTOKILL}*" -delete
#find . -maxdepth 2 -type f -name "*${STRINGTOKILL}*" -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES COPIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


