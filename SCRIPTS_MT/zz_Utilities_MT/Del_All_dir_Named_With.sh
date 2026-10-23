#!/bin/bash
######################################################################################
# This script remove all dirs that contains a certain string in their name 
#    and that correspond to a string of format hard coded (for security).
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in V1.1:	- change with a oneliner version...
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



STRINGTOKILL=$1

# for stringname in `ls -d *${STRINGTOKILL}*`
#    do
#  		echo ${stringname}
#  		MAS=`echo ${stringname} | cut -d _ -f3`
#  		SLV=`echo ${stringname} | cut -d _ -f7`
#  		echo "Kill S1?_88_${MAS}_A_S1?_88_${SLV}_A"
#  		rm -Rf S1?_88_${MAS}_A_S1?_88_${SLV}_A
# done
find . -maxdepth 1 -type d -name "*${STRINGTOKILL}*"
find . -maxdepth 1 -type d -name "*${STRINGTOKILL}*" -exec rm -Rf {} \;


# echo +++++++++++++++++++++++++++++++++++++++++++++++
# echo "ALL FILES COPIED - HOPE IT WORKED"
# echo +++++++++++++++++++++++++++++++++++++++++++++++
# 
# 
# Version from a file with list of string for dir to kill
# 
# DIRTOKILL=$1
# 
# while read -r MASDATE SLVDATE
# do	
# 	DIRTOREMOVE=`ls -d S1*${MASDATE}*${SLVDATE}*A`
# 	echo "rm -Rf ${DIRTOREMOVE}"
# 	rm -Rf ${DIRTOREMOVE}
# done < ${DIRTOKILL} 
# 


echo ++++++++++++++++++++++++++++++++++
echo "ALL DIR CLEANED - HOPE IT WORKED"
echo ++++++++++++++++++++++++++++++++++
