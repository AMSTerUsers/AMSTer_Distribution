#!/bin/bash
######################################################################################
# This script remove/move all files in dir and subdirs that contains a certain string 
# in their name. Comment/uncomment in script following your needs. 
# 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

#STRINGTOKILL=20210730
#TARGETDIR="$PATH_3601/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_20180222_Zoom1_ML4/GeocodedRasters"
STRINGTOKILL=$1
TARGETDIR=$2

# mv to TARGETDIR
#################
find . -maxdepth 2 -type f -name "*${STRINGTOKILL}*" -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +

# delete from TARGETDIR
#######################
#cd ${TARGETDIR}
#find . -maxdepth 2 -type f -name "*${STRINGTOKILL}*" -delete

echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES "*${STRINGTOKILL}*" (RE)MOVED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


