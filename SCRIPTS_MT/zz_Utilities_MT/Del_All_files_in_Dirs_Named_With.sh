#!/bin/bash
######################################################################################
# This script remove/move all files in dir and subdirs that contains a certain string 
# in their name. Comment/uncomment in script following your needs. 
# 
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
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


