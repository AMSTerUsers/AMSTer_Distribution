#!/bin/bash
######################################################################################
# This script move all dirs in pwd that are smaller than a certain amount (in Mb) in provided path.
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in V1.1 (Aug 08, 2022): 	- seems that former version was not compliant with some OS 
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


MAXSIZE=$1 			# Max dir size in Mb
WHERETOMOVE=$2 		# path where to move dirs

#find . -mindepth 1 -maxdepth 1 -type d -exec du -ms {} +  | ${PATHGNU}/gawk '$1 <= '${MAXSIZE}'' | cut -f 2- | xargs -I ARG mv ARG ${WHERETOMOVE}/

find . -maxdepth 1 -type d | grep -v ^\\.$ | xargs -n 1 du -ms | while read size name ; do if [ $size -lt ${MAXSIZE} ] ; then mv $name ${WHERETOMOVE}/ ; echo "$name ($size Mb) moved to ${WHERETOMOVE}"; else echo "$name : $size Mb" ; fi done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL DIR MOVED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

