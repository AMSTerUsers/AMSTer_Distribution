#!/bin/bash
######################################################################################
# This script look for duplicated products in all Mode dir based on pair of dates that is in the name. 
# Duplicate products may happen in /Geocoded/Mode and /GeocodedRasters/Mode (where Mode is e.g. DefoInterpolx2Detrend)
# when a pair is reprocessed with updated orbit with resulting slightly different Bp.
# It then move them in each Mode/___Duplicated_ToKill.
#
# It DOES NOT PROCESS GEOCODED AMPLITUDE IMAGES because mas and slv can be geocoded within the same pair 
#
# Must be launched in SAR_MASSPROCESS dir where /Geocoded/Mode and /GeocodedRasters/Mode are present. 
#
# Depedencies: 	- gnu find !! (Macport findutils)
#				- Remove_Duplicate_Pairs_File.sh
#
# New in V1.1:	- improve mode listing to avoid selecting txt or tif files... 
# New in V1.2:	- more robust by searching only dirs in Geocoded
# New in V1.3 (Feb 15, 2023):	- search dirs with find instead of ls 
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


rm -f MODES_CKECK_DUPLIC.TXT 
# Check available modes
#ls -d Geocoded | ${PATHGNU}/grep -v .txt | ${PATHGNU}/grep -v .tif | ${PATHGNU}/grep -v Ampli | ${PATHGNU}/grep -v "test" > MODES_CKECK_DUPLIC.TXT # List all modes 
find ./Geocoded -maxdepth 1 -mindepth 1 -type d  | ${PATHGNU}/grep -v .txt | ${PATHGNU}/grep -v .tif | ${PATHGNU}/grep -v Ampli | ${PATHGNU}/grep -v "test" | ${PATHGNU}/gsed 's/.*\///' > MODES_CKECK_DUPLIC.TXT # List all modes 
# ${PATHGNU}/grep -v .txt MODES_CKECK_DUPLIC.TXT > MODES_CKECK_DUPLIC_TMP.TXT
# ${PATHGNU}/grep -v Ampli MODES_CKECK_DUPLIC_TMP.TXT > MODES_CKECK_DUPLIC.TXT
# rm -f MODES_CKECK_DUPLIC_TMP.TXT

for MODE in `cat MODES_CKECK_DUPLIC.TXT` ;  do
	cd Geocoded/${MODE}
	echo "  // Shall move duplicated ${MODE} files..."
	Remove_Duplicate_Pairs_File.sh
	cd ../..
	cd GeocodedRasters/${MODE}
	echo "  // Shall move duplicated ${MODE} rasters files..."
	Remove_Duplicate_Pairs_File_ras.sh
	cd ../..	
done 

#echo +++++++++++++++++++++++++++++++++++++++++++++++
#echo "ALL ${MODE} FILES CHECKED - HOPE IT WORKED"  
#echo +++++++++++++++++++++++++++++++++++++++++++++++

