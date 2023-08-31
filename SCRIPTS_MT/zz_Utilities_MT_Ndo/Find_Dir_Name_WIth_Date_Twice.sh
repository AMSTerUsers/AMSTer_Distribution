#!/bin/bash
######################################################################################
# This script look for directories in current dir that are named with duplicated date.
#
# It can be easily adapted to seach for files and in subdirs... and/or do something with results
#
# Must be launched in dir to search. 
#
# 
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on June 09, 2020"
echo " "
echo "${PRG} ${VER}, ${AUT}"
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

