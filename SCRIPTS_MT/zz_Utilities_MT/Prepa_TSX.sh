#!/bin/bash
######################################################################################
# This script aims at renaming the directories containing TSX data by their date in 
# a new dir named by happening _RENAMED in pwd. 
# It suppose that only one image is stored in each directory. 
# It will read all the sub dir until finding a dir named with something like 
# T?X1_SAR__SSC_*_SRA_yyyymmddThhmmss_yyyymmddThhmmss, e.g. 
#   TSX1_SAR__SSC______SL_S_SRA_yyyymmddThhmmss_yyyymmddThhmmss or 
#   TDX1_SAR__SSC______SL_S_SRA_yyyymmddThhmmss_yyyymmddThhmmss
# and get the date out of that name. 
#
# NOTES: - if a directory with the same date exists but with a different content, 
#          it will name the new one with an index _i
#        - former directory name will be stored as text file in the image directory 
#
# It must be launched in the dir that contains all the subdirs where TDX or TSX data are.
#
# Parameters: - none
#
# Dependencies: - none
#
#
# New in V D 1.1:	- 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# N.d'Oreye, v 1.2 2023/01/23 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jan 23, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

eval CURRENTDIR=$(pwd)
RNDM=`echo $(( $RANDOM % 10000 ))`

mkdir -p ${CURRENTDIR}_RENAMED

function GetDateYyyyMmDdT()
	{
	unset DIRNAME
	local DIRNAME=$1
	echo "${DIRNAME}" | ${PATHGNU}/grep -Eo "[0-9]{8}T"  | cut -d T -f1 | head -1
	}

function TestIfTheSame()
	{
	local DIR1=$1
	local DIR2=$2

	if ! diff -qr ${DIR1} ${DIR2} > /dev/null 		# Mute output when no need to debug
		then 
			# Dirs are not the same. If all no different, then mv
			echo "		Dirs ${DIR1} and ${DIR2}	are not the same"
		else
			# Dirs are the same; keep trying. 
			echo "		Dirs ${DIR1} and ${DIR2}	are the same ; skip reading this image " 
			mv ${CURRENTDIR}_RENAMED/${DATEIMG}_0 ${CURRENTDIR}_RENAMED/${DATEIMG}
			BRK="YES"	# To tell the while loop to skip this image
			break 		# Escape the for loop 
	fi
	}

for DIRS in `find . -maxdepth 1 -mindepth 1 -type d ! -regex '.*/[0-9_]+$'`  # Search for all dirs except those named by digits and underscore 
   do
	echo "Test ${DIRS}: "
	DIRWITHDATE=`find ${DIRS}/ -type d -name "T*X*_SAR__SSC*_SRA_*T*_*T*"`
	DATEIMG=`GetDateYyyyMmDdT ${DIRWITHDATE}`

	if [ ! -d ${CURRENTDIR}_RENAMED/${DATEIMG} ]
		then 
			# No dir with that date exist yet; move it
			
			# Keep track of old name
			echo "Originam name of ${DATEIMG} was  ${DIRS}" > ${DIRS}.txt 
			cp -r ${DIRS} ${CURRENTDIR}_RENAMED/${DATEIMG}
			mv ${DIRS}.txt  ${CURRENTDIR}_RENAMED/
			echo "	Rename it with ${DATEIMG}"	

		else
			# A dir with that date exists. Move it with index 0 for check
			mv ${CURRENTDIR}_RENAMED/${DATEIMG} ${CURRENTDIR}_RENAMED/${DATEIMG}_0
			# Check if it is the same of any dir that would have an index 
	
			index=0
	
			while [ -d "${CURRENTDIR}_RENAMED/${DATEIMG}_$index" ]; do
		
				TestIfTheSame ${CURRENTDIR}/${DIRS} ${CURRENTDIR}_RENAMED/${DATEIMG}_$index
				((index++))			
			done

			if [ "${BRK}" == "YES" ] ; then BRK="NO" ; continue ; fi 	# Reset flag escaping the while loop then go to next step in for loop

			# If no break encountered, it means that all ${DATEIMG}_$index are different, hence it is a new image to be moved
			# add one to index
			NexIndex=$((index++))
			
			echo "Original name of ${DATEIMG}_$NexIndex was ${DIRS} " > ${DIRS}.txt 
			cp -r ${DIRS} ${CURRENTDIR}_RENAMED/${DATEIMG}_$NexIndex
			mv ${DIRS}.txt  ${CURRENTDIR}_RENAMED/
			echo "	Rename ${DIRS} with ${DATEIMG}_$NexIndex with new index"	
			# Get original name 
			mv ${CURRENTDIR}_RENAMED/${DATEIMG}_0 ${CURRENTDIR}_RENAMED/${DATEIMG}
	fi
	echo

done

