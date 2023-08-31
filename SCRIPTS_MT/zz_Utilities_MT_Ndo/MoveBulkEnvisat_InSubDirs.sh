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
# New in V1.0.0 :	- take state variable for PATHGNU etc 
#
# CSL InSAR Suite utilities. 
# NdO (c) 2018/03/29 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0.0  MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2022, Last modified on Oct 13, 2022"
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


