#!/bin/bash
# Script to move each of the raw envi files (named *.N1) from the current dir into subdirs named 
#  by their orbit number.
# 
# MUST BE LAUNCHED IN DIR CONTAINING ALL ENVISAT FILES
#
# Parameters : - none  
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#
# V1.0.0  (Oct 13, 2022)
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

for FILES in `ls *.N1` 
do 
	echo "Processing file ${FILES}"
	ORBNR=`echo ${FILES}  | rev | cut -d _ -f2 | rev ` # read the name backward and take the second scting between _ and rev again
	echo "Store it in ${ORBNR}"
	mkdir -p ${ORBNR}
	mv -f ${FILES} ${ORBNR}/
done 


