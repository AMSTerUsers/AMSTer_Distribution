#!/bin/bash
######################################################################################
# This script look for directories in current dir that are named with duplicated date.
#
# It can be easily adapted to seach for files and in subdirs... and/or do something with results
#
# Must be launched in dir to search. 
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# V1.0 (June 09, 2020)
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



#for DIRNAME in `find . -maxdepth 1 -mindepth 1 -type d | cut -c 3-` ;  do
#for DIRNAME in `find . -maxdepth 1 -mindepth 1 -type f | cut -c 3-` ;  do
for DIRNAME in `find . -type f | cut -c 3-` ;  do

	MAS=`echo "${DIRNAME}" | ${PATHGNU}/grep -Eo "[0-9]{8}"  | tail -2 | head -1 `  # hence also OK for Ampli images
	SLV=`echo "${DIRNAME}" | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1  `

	if [ "${MAS}" != "" ] && [ ${MAS} == ${SLV} ] 	# avoid prblm if dir name does not contains digits ! 
		then 
			#echo "${DIRNAME} _ ${MAS} _ ${SLV}"
			echo ${DIRNAME} 
			#rm -f ${DIRNAME}
	fi
	
 done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL DIR CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

