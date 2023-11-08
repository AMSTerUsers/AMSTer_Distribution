#!/bin/bash
# Script to rename path of files in InSARParameters.txt that were computed with CSL images stored in 
#    dir named by SM instead of normal name, e.g
# /Volumes/hp-1650-Data_Share1/SAR_CSL/CSK/Virunga_Desc/SMCrop_SM_20160105_NyigoCrater_-1.510--1.560_29.280-29.330_Zoom1_ML8
#    instead of 
# /Volumes/hp-1650-Data_Share1/SAR_CSL/CSK/Virunga_Desc/Crop_NyigoCrater_-1.510--1.560_29.280-29.330_Zoom1_ML8. 
#
# ATTENTION : input must contains enough info (SAT/TRK) to avoid confusion
#
# Need to be run in dir where all /PRM_SCD/i12/TextFiles/InSARParameters.txt were moved, 
#   e.g. /.../SAR_SM/RESAMPLED/SAT/TRK/CROPDIR/
#
# Parameters : - beginning of existing dir name
#              - beginning of wished dir name   
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#
# New in V1.0.1 Beta (Oct 30, 2018):	- take state variable for PATHGNU etc
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


