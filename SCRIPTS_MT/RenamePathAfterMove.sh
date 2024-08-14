#!/bin/bash
# Script to rename path of files in InSARParameters.txt after moving them from 
#     where they were computed to where the mass processing wants them to be stored. 
#
# This may have an interest in case of replaying some steps in MASS_PROCESS directories 
#
# Need to be run in dir where all /PRM_SCD/i12/TextFiles/InSARParameters.txt were moved, 
#   e.g. /.../SAR_SM/RESAMPLED/SAT/TRK/CROPDIR/
#
# Parameters : - Sat   
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.1.0
# New in Distro V 1.1:	- search for dir of any name after ????????_????????
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.0 20240812:	- Do not need anymore renaming path when {SATDIR} is S1STRIPMAP
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 12, 2024"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

SATDIR=$1

NEWDIR="$(pwd)"

case ${SATDIR} in 
		"S1")
			ls -d ????????_?1?_* > Files_To_Rename.txt ;;
		"S1STRIPMAP")
			ls -d ????????_?1?_* > Files_To_Rename.txt ;;
		*)
			ls -d ????????_????????* > Files_To_Rename.txt ;;
esac	


for DIR in `cat -s Files_To_Rename.txt` 
do 
	cd ${DIR}/i12/TextFiles
	cp -n InSARParameters.txt InSARParameters_original.txt # do not copy if exist already
	cp -n geoProjectionParameters.txt geoProjectionParameters_original.txt # do not copy if exist already

	if [ "${SATDIR}" == "S1STRIPMAP" ] ; then
			MASIMGPATH=`updateParameterFile ${NEWDIR}/${DIR}/i12/TextFiles/InSARParameters_original.txt "Master image file path [CSL image format]"`
			MASIMG=`basename ${MASIMGPATH} | cut -d. -f1`
			MASIMGDATE=`echo ${MASIMG} | cut -d_ -f3`
			SLVIMG=`echo ${DIR} | cut -d_ -f 2-5` 
			
			${PATHGNU}/gsed "s%^.*${MASIMG}_${SLVIMG}%${NEWDIR}\/${MASIMGDATE}_${SLVIMG}%g" InSARParameters_original.txt > InSARParameters.txt
			${PATHGNU}/gsed "s%^.*${MASIMG}_${SLVIMG}%${NEWDIR}\/${MASIMGDATE}_${SLVIMG}%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt
			
			
		else 
			${PATHGNU}/gsed "s%^.*${DIR}%${NEWDIR}\/${DIR}%g" InSARParameters_original.txt > InSARParameters.txt
			${PATHGNU}/gsed "s%^.*${DIR}%${NEWDIR}\/${DIR}%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt
	fi
	cd ${NEWDIR}
done 

#if [ "${SATDIR}" == "S1STRIPMAP" ] ; then
#	cd _${MASIMG}_Ampli_Img_Reduc/i12/TextFiles
#	cp -n InSARParameters.txt InSARParameters_original.txt # do not copy if exist already
#	${PATHGNU}/gsed "s%^.*${MASIMG}%${NEWDIR}\/${MASIMGDATE}%g" InSARParameters_original.txt > InSARParameters.txt
#fi
rm -f Files_To_Rename.txt

