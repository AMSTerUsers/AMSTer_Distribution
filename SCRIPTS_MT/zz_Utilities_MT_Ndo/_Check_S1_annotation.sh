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
