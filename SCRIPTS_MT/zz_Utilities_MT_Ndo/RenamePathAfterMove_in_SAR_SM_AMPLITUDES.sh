#!/bin/bash
# Script to rename (in parameters text files) path of files in TextFiles in PAIR DIRS in SAR_SM.AMPLITUDES after having 
#    moved them from where they were computed. 
#
# This may have an interest in case of geocoding in SAR_SM/AMPLITUDES directories 
#
# Need to be run in dir where all SAR_SM/AMPLITUDES/.../i12/TextFiles/InSARParameters.txt were moved, 
#   e.g. /.../SAR_SM/AMPLITUDES/CSK/Virunga_Asc/NyigoCrater
#
# Parameters : -    
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- __HardCodedLines.sh
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.1.0
# New in Distro V 2.0: - Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below: 
	# - RenameVolNameToVariable to rename all path in param files just in case DIR were moved
# ^^^ ----- Hard coded lines to check --- ^^^ 


NEWDIR="$(pwd)"

ls -d ????????_????????* | ${PATHGNU}/grep -v ".txt" > Files_To_Rename.txt 

for DIR in `cat -s Files_To_Rename.txt` 
do 
	DIRSHORT=`echo ${DIR} | cut -d_ -f1-2`
	
	cd ${DIR}/i12/TextFiles
	cp -n InSARParameters.txt InSARParameters_original.txt # do not copy if exist already
	cp -n geoProjectionParameters.txt geoProjectionParameters_original.txt # do not copy if exist already

	${PATHGNU}/gsed "s%^.*i12%${NEWDIR}\/${DIR}\/i12%g" InSARParameters_original.txt > InSARParameters.txt
	${PATHGNU}/gsed "s%^.*i12%${NEWDIR}\/${DIR}\/i12%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt
	cp InSARParameters.txt InSARParameters_original_ExtHDpath.txt # do not copy if exist already
	RenameVolNameToVariable InSARParameters_original_ExtHDpath.txt InSARParameters.txt
# 	${PATHGNU}/gsed -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/\$PATH_1650%g 
# 						 s%\/Volumes\/hp-D3600-Data_Share1%\/\$PATH_3600%g 
# 						 s%\/Volumes\/hp-D3601-Data_RAID6%\/\$PATH_3601%g 
# 						 s%\/Volumes\/hp-D3602-Data_RAID5%\/\$PATH_3602%g
# 						 s%\/mnt\/1650%\/\$PATH_1650%g 
# 						 s%\/mnt\/3600%\/\$PATH_3600%g 
# 						 s%\/mnt\/3601%\/\$PATH_3601%g 
# 						 s%\/mnt\/3602%\/\$PATH_3602%g" InSARParameters_original_ExtHDpath.txt > InSARParameters.txt
						 
	cp geoProjectionParameters.txt geoProjectionParameters_original_ExtHDpath.txt # do not copy if exist already
	RenameVolNameToVariable geoProjectionParameters_original_ExtHDpath.txt geoProjectionParameters.txt
# 		${PATHGNU}/gsed -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/\$PATH_1650%g 
# 							 s%\/Volumes\/hp-D3600-Data_Share1%\/\$PATH_3600%g 
# 							 s%\/Volumes\/hp-D3601-Data_RAID6%\/\$PATH_3601%g 
# 							 s%\/Volumes\/hp-D3602-Data_RAID5%\/\$PATH_3602%g
# 							 s%\/mnt\/1650%\/\$PATH_1650%g 
# 							 s%\/mnt\/3600%\/\$PATH_3600%g 
# 							 s%\/mnt\/3601%\/\$PATH_3601%g 
# 							 s%\/mnt\/3602%\/\$PATH_3602%g" geoProjectionParameters_original_ExtHDpath.txt > geoProjectionParameters.txt


	cd ${NEWDIR}
done 

#rm -f Files_To_Rename.txt

