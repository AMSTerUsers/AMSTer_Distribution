#!/bin/bash
######################################################################################
# This script compare the area of interest in the AMPLITUDES/SAT/TRK... to ensure that the 
#       stack of .mod can be compared without shift. If residual shift persists increase the 
#       LLRGCO and LLAZCO in ParametersFile and re-run whole process
#
# Parameters : 	none 
#
# Dependencies:	none 
# 
# New in Distro V 1.0:	- Based on developpement version 1.0 and Beta V1.0
# 
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# N.d'Oreye, v 1.0 2017/05/22 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 15, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

echo "List of Upper right range and azimuth coordinates:" > _List_Az_Rg_UpperLeft_coord.txt
for DIR in `ls | ${PATHGNU}/grep -v _AMPLI | ${PATHGNU}/grep -v .txt`
do
	RCOORD=`grep "Upper right range coordinate" ${DIR}/i12/TextFiles/InSARParameters.txt | cut -c 1-10`
	ACOORD=`grep "Upper right azimuth coordinate" ${DIR}/i12/TextFiles/InSARParameters.txt | cut -c 1-10`
	echo "${DIR}:     ${RCOORD} ${ACOORD}" >> _List_Az_Rg_UpperLeft_coord.txt
done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


