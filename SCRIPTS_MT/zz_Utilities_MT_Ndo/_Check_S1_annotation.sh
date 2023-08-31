#!/bin/bash
######################################################################################
# This script checks the S1 annotation dir in all the subdirs from current dir.  
#
# Parameters:	- none
#
# Note: must be launched in SAR_DATA/S1/REGION/ dir
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

rm -f ___S1_Empty_annotation_*.txt

find . -type d -name "*.SAFE" | while read IMGNAME 
do 
	echo "Check ${IMGNAME}... "
	if [ `ls ${IMGNAME}/annotation 2>/dev/null | wc -l` -eq 0 ] 
		then 
			 echo ${IMGNAME} >> ___S1_Empty_annotation_${RUNDATE}_${RNDM1}.txt
			 echo "    => EMPTY"
		else 
			 echo "    OK"
	fi
done

echo "-----------------------------------------------------------------"
echo " All done. Check ___List_Orbits_${RUNDATE}_${RNDM1}.txt"
echo "-----------------------------------------------------------------"
