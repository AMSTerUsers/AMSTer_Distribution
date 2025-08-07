#!/bin/bash
# Script to rename (in parameters text files) path of files in TextFiles in PAIR DIRS in SAR_MASSPROCESS after having 
#    moved them fdrom where they were computed. 
#
# This may have an interest in case of replaying some steps in SAR_MASSPROCESS directories 
#
# Need to be run in dir where all SAR_MASSPROCESS/.../i12/TextFiles/InSARParameters.txt were moved, 
#   e.g. /.../SAR_MASSPROCESS/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310_Zoom1_ML8
#
# Parameters : - Sat   
#
# Hard coded:	- Path to disks and volumes to rename
#				- __HardCodedLines.sh
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.1.0
# New in Distro V 2.0: 	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20250227:	- replace cp -n with if [ ! -e DEST ] ; then cp SRC DEST ; fi 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Feb 27, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

SATDIR=$1

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below: 
	# - RenameVolNameToVariable to rename all path in param files just in case DIR were moved
# ^^^ ----- Hard coded lines to check --- ^^^ 


if [ $# -lt 1 ] ; then 
		echo "No sat provided."
		exit 0
fi

NEWDIR="$(pwd)"

case ${SATDIR} in 
		"S1")
			ls -d S1?_*_????????_?_S1?_*_????????_? > Files_To_Rename.txt ;;
		#"S1STRIPMAP")
		# NOT TESTED YET
		#	ls -d ????????_?1?_* > Files_To_Rename.txt ;;
		*)
			#echo "Not tested ; review script on test data set first" ; exit 0
			ls -d ????????_????????* > Files_To_Rename.txt ;;
esac	


for DIR in `cat -s Files_To_Rename.txt` 
do 
	cd ${DIR}/i12/TextFiles
	#cp -n InSARParameters.txt InSARParameters_original.txt # do not copy if exist already
	#cp -n geoProjectionParameters.txt geoProjectionParameters_original.txt # do not copy if exist already
	if [ ! -e InSARParameters_original.txt ] ; then cp InSARParameters.txt InSARParameters_original.txt ; fi 
	if [ ! -e geoProjectionParameters_original.txt ] ; then cp geoProjectionParameters.txt geoProjectionParameters_original.txt ; fi 

	if [ "${SATDIR}" == "S1STRIPMAP" ] ; then
			# NOT TESTED YET
			echo "Not tested ; review script on test data set first" ; exit 0
			# MASIMGPATH=`updateParameterFile ${NEWDIR}/${DIR}/i12/TextFiles/InSARParameters_original.txt "Master image file path [CSL image format]"`
	# 		MASIMG=`basename ${MASIMGPATH} | cut -d. -f1`
	# 		MASIMGDATE=`echo ${MASIMG} | cut -d_ -f3`
	# 		SLVIMG=`echo ${DIR} | cut -d_ -f 2-5` 
	# 		
	# 		${PATHGNU}/gsed "s%^.*${MASIMG}_${SLVIMG}%${NEWDIR}\/${MASIMGDATE}_${SLVIMG}%g" InSARParameters_original.txt > InSARParameters.txt
	# 		${PATHGNU}/gsed "s%^.*${MASIMG}_${SLVIMG}%${NEWDIR}\/${MASIMGDATE}_${SLVIMG}%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt
	# 		
		else 
			${PATHGNU}/gsed "s%^.*${DIR}%${NEWDIR}\/${DIR}%g" InSARParameters_original.txt > InSARParameters.txt
			${PATHGNU}/gsed "s%^.*${DIR}%${NEWDIR}\/${DIR}%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt
			
			#cp -n InSARParameters.txt InSARParameters_original_ExtHDpath.txt # do not copy if exist already
			if [ ! -e InSARParameters_original_ExtHDpath.txt ] ; then cp InSARParameters.txt InSARParameters_original_ExtHDpath.txt ; fi 
			
			RenameVolNameToVariable InSARParameters_original_ExtHDpath.txt InSARParameters.txt
# 			${PATHGNU}/gsed -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/\$PATH_1650%g 
# 								 s%\/Volumes\/hp-D3600-Data_Share1%\/\$PATH_3600%g 
# 								 s%\/Volumes\/hp-D3601-Data_RAID6%\/\$PATH_3601%g 
# 								 s%\/Volumes\/hp-D3602-Data_RAID5%\/\$PATH_3602%g
# 								 s%\/mnt\/1650%\/\$PATH_1650%g 
# 								 s%\/mnt\/3600%\/\$PATH_3600%g 
# 								 s%\/mnt\/3601%\/\$PATH_3601%g 
# 								 s%\/mnt\/3602%\/\$PATH_3602%g" InSARParameters_original_ExtHDpath.txt > InSARParameters.txt
								 
			#cp -n geoProjectionParameters.txt geoProjectionParameters_original_ExtHDpath.txt # do not copy if exist already
			if [ ! -e geoProjectionParameters_original_ExtHDpath.txt ] ; then cp geoProjectionParameters.txt geoProjectionParameters_original_ExtHDpath.txt ; fi 
			
			RenameVolNameToVariable geoProjectionParameters_original_ExtHDpath.txt geoProjectionParameters.txt
# 				${PATHGNU}/gsed -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/\$PATH_1650%g 
# 									 s%\/Volumes\/hp-D3600-Data_Share1%\/\$PATH_3600%g 
# 									 s%\/Volumes\/hp-D3601-Data_RAID6%\/\$PATH_3601%g 
# 									 s%\/Volumes\/hp-D3602-Data_RAID5%\/\$PATH_3602%g
# 									 s%\/mnt\/1650%\/\$PATH_1650%g 
# 									 s%\/mnt\/3600%\/\$PATH_3600%g 
# 									 s%\/mnt\/3601%\/\$PATH_3601%g 
# 									 s%\/mnt\/3602%\/\$PATH_3602%g" geoProjectionParameters_original_ExtHDpath.txt > geoProjectionParameters.txt
	fi
	cd ${NEWDIR}
done 

# NOT TESTED YET
# if [ "${SATDIR}" == "S1STRIPMAP" ] ; then
# 	cd _${MASIMG}_Ampli_Img_Reduc/i12/TextFiles
# 	cp -n InSARParameters.txt InSARParameters_original.txt # do not copy if exist already
# 	${PATHGNU}/gsed "s%^.*${MASIMG}%${NEWDIR}\/${MASIMGDATE}%g" InSARParameters_original.txt > InSARParameters.txt
# fi
rm -f Files_To_Rename.txt

