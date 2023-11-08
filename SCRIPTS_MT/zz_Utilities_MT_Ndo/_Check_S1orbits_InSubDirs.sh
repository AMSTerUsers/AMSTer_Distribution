#!/bin/bash
######################################################################################
# This script checks the S1 orbits in all the subdirs from current dir.  
#
# Parameters:	- none
#
# Note: must be launched in SAR_CSL/S1/TRACK/NoCrop dir
#
# Dependencies:	- gsed
# 
# V 1.0 (April 29, 2022)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
# ^^^ ----- Hard coded lines to check -- ^^^ 

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
eval RNDM1=`echo $(( $RANDOM % 10000 ))`


find . -maxdepth 1 -name "*.csl" | while read IMGNAME 
do 
	echo "Check ${IMGNAME}... "
	echo "${IMGNAME}: " | cut -d / -f 2 >> ___List_Orbits_${RUNDATE}_${RNDM1}.txt
	ls ${IMGNAME}/Info/SLCImageInfo.* | grep -v "swath" | cut -d / -f 4  | ${PATHGNU}/gsed "s%SLCImageInfo%		SLCImageInfo%g" >> ___List_Orbits_${RUNDATE}_${RNDM1}.txt
done

echo "-----------------------------------------------------------------"
echo " All done. Check ___List_Orbits_${RUNDATE}_${RNDM1}.txt"
echo "-----------------------------------------------------------------"
