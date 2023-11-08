#!/bin/bash
# Script to rename (in parameters text files) external HD path such as /$PATH_1650 into hp-1650-Data_Share1 (from OSX) 
#    in order to be readable for MT when MT does not interprete links in parameters files. 
#
# This may have an interest in case of replaying some steps in MASS_PROCESS directories 
#
# Need to be run in dir where all files are stored in /SUBDIRS/i12/TextFiles/InSARParameters.txt, 
#   e.g. /.../SAR_SM/RESAMPLED/SAT/TRK/CROPDIR/
#
# Parameters : - none  
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- __HardCodedLines.sh for Path to disks and volumes to rename
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0.0
#               V1.0.1: - also for usage in SAR_MASSPROCESS (avoid dir with Geocoded etc..)
# New in Distro V 2.0: - Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 2.1: - replace if -s as -f -s && -f to be compatible with mac os if 
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
	# - RenamePathToVol to rename Linux mounting point by Mac volume name 
# ^^^ ----- Hard coded lines to check --- ^^^ 

NEWDIR="$(pwd)"

ls -d */ | ${PATHGNU}/grep -v ModulesForCoreg  | ${PATHGNU}/grep -v _Check  | ${PATHGNU}/grep -v Geocoded  | ${PATHGNU}/grep -v __Back    > Files_To_Rename.txt

# Test if process CSL images (for DEM infos) or RESAMPLED images
TSTDIR=`tail -1 Files_To_Rename.txt`

if [ -d ${TSTDIR}/i12/TextFiles ] 
	then  
		echo "I guess we are renaming path in RESAMPLED directories..."
		for DIR in `cat -s Files_To_Rename.txt` 
		do 
			cd ${DIR}/i12/TextFiles
			cp -n InSARParameters.txt InSARParameters_original_ExtHDpath.txt # do not copy if exist already
			RenamePathToVol InSARParameters_original_ExtHDpath.txt InSARParameters.txt
# 			${PATHGNU}/gsed -e 	"s%\/\$PATH_1650%\/Volumes\/hp-1650-Data_Share1%g 
# 								 s%\/\$PATH_3600%\/Volumes\/hp-D3600-Data_Share1%g 
# 								 s%\/\$PATH_3601%\/Volumes\/hp-D3601-Data_RAID6%g 
# 								 s%\/\$PATH_3602%\/Volumes\/hp-D3602-Data_RAID5%g" InSARParameters_original_ExtHDpath.txt > InSARParameters.txt
			if [ -f geoProjectionParameters.txt ] && [ -s geoProjectionParameters.txt ] ; then
				cp -n geoProjectionParameters.txt geoProjectionParameters_original_ExtHDpath.txt # do not copy if exist already
				RenamePathToVol geoProjectionParameters_original_ExtHDpath.txt geoProjectionParameters.txt
# 				${PATHGNU}/gsed -e 	"s%\/\$PATH_1650%\/Volumes\/hp-1650-Data_Share1%g 
# 									 s%\/\$PATH_3600%\/Volumes\/hp-D3600-Data_Share1%g 
# 									 s%\/\$PATH_3601%\/Volumes\/hp-D3601-Data_RAID6%g 
# 									 s%\/\$PATH_3602%\/Volumes\/hp-D3602-Data_RAID5%g" geoProjectionParameters_original_ExtHDpath.txt > geoProjectionParameters.txt
			fi
			echo "Files in ${DIR}/i12/TextFiles renamed."
			cd ${NEWDIR}
		done 
	else   
		if [ -d ${TSTDIR}/Info ] 
			then 
				echo "I guess we are renaming path in CSL images directories..."
				for DIR in `cat -s Files_To_Rename.txt` 
					do 
						cd ${DIR}/Info
						for MASKSANDDEM in `ls *.txt | ${PATHGNU}/grep -v readme | ${PATHGNU}/grep -v SLC | ${PATHGNU}/grep -v Pattern | ${PATHGNU}/grep -v original` 
							do
								cp -n ${MASKSANDDEM} ${MASKSANDDEM}_original_ExtHDpath.txt # do not copy if exist already
								RenamePathToVol ${MASKSANDDEM}_original_ExtHDpath.txt ${MASKSANDDEM}
# 								${PATHGNU}/gsed -e 	"s%\/\$PATH_1650%\/Volumes\/hp-1650-Data_Share1%g 
# 													 s%\/\$PATH_3600%\/Volumes\/hp-D3600-Data_Share1%g 
# 													 s%\/\$PATH_3601%\/Volumes\/hp-D3601-Data_RAID6%g 
# 													 s%\/\$PATH_3602%\/Volumes\/hp-D3602-Data_RAID5%g" ${MASKSANDDEM}_original_ExtHDpath.txt > ${MASKSANDDEM}
							done
						echo "Files in ${DIR}/Info renamed."
						cd ${NEWDIR}
				done 		
			else 
				echo "Not sure what kind of files you want to modify. Please revise path and adapt script"
		fi
	fi
		
rm -f Files_To_Rename.txt

