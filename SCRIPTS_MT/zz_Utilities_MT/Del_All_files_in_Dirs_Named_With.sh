#!/bin/bash
######################################################################################
# This script remove all files in dir and subdirs that contains a certain string in their name 
# 
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/06/26 -                         
######################################################################################

#STRINGTOKILL=$1
STRINGTOKILL=20210730
TARGETDIR="$PATH_3601/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_20180222_Zoom1_ML4/GeocodedRasters"

cd ${TARGETDIR}

find . -maxdepth 2 -type f -name "*${STRINGTOKILL}*" -delete
#find . -maxdepth 2 -type f -name "*${STRINGTOKILL}*" -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES COPIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


