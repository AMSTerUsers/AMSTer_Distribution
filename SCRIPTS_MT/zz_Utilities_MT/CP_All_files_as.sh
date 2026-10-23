#!/bin/bash
######################################################################################
# This script copy all files in sub dirs that contains a certain string in their name into a given dir.
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


CRITERE=$1
PATHDIR=$2

echo "Cp files with ${CRITERE} to ${PATHDIR} from prensent dir/subdirs: "

for filename in `find * -type f | ${PATHGNU}/grep ${CRITERE}`
   do
 		cp ${filename} ${PATHDIR}
done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES COPIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


