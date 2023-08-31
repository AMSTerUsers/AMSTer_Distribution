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
# New in V 1.1:	- 
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2021, Last modified on April 29, 2022"
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
