#!/bin/bash
# Script to rename path of files in InSARParameters.txt that were computed with CSL images stored in 
#    dir named by SM instead of normal name, e.g
# /Volumes/hp-1650-Data_Share1/SAR_CSL/CSK/Virunga_Desc/SMCrop_SM_20160105_NyigoCrater_-1.510--1.560_29.280-29.330_Zoom1_ML8
#    instead of 
# /Volumes/hp-1650-Data_Share1/SAR_CSL/CSK/Virunga_Desc/Crop_NyigoCrater_-1.510--1.560_29.280-29.330_Zoom1_ML8. 
#
# ATTENTION : input must contains enough info (SAT/TRK) to avoid confusion
#
# Need to be run in dir where all /MAS_SLV/i12/TextFiles/InSARParameters.txt were moved, 
#   e.g. /.../SAR_SM/RESAMPLED/SAT/TRK/CROPDIR/
#
# Parameters : - beginning of existing dir name
#              - beginning of wished dir name   
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#
# New in V1.0.1 Beta:	- take state variable for PATHGNU etc
#
# CSL InSAR Suite utilities. 
# NdO (c) 2018/03/29 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0.1 Beta CIS script utilities"
AUT="Nicolas d'Oreye, (c)2018, Last modified on Oct 30, 2018"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

EXISTING=$1 # eg CS\/Virunga_Asc\/SMCrop_SM_20160627_Nyigo_
NEW=$2		# eg CS\/Virunga_Asc\/Crop_Nyigo_

NEWDIR="$(pwd)"

for DIR in `ls -d ????????_????????` 
do 
	cd ${DIR}/i12/TextFiles
	cp -n InSARParameters.txt InSARParameters_original3.txt # do not copy if exist already
	${PATHGNU}/gsed "s%Volumes\/hp-1650-Data_Share1\/SAR_CSL\/\/${EXISTING}%Volumes\/hp-1650-Data_Share1\/SAR_CSL\/\/${NEW}%g" InSARParameters_original3.txt > InSARParameters.txt
	cd ${NEWDIR}
done 


