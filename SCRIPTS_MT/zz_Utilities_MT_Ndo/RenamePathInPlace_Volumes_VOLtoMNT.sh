#!/bin/bash
# Script to rename IN PLACE (in various parameters text files) external HD path such as Volumes/hp-1650-Data_Share1 (from OSX) in mnt/1650 (from Linux)  
#
# This may have an interest whe processing data prepared on a computer using another OS
#
# Need to be run in dir where all files are stored in /SUBDIRS/Info/*.txt, 
#   e.g. /.../SAR_CSL/S1/DRC_NyigoVolcField_A_174/NoCrop/S1A_174_20141017_A.csl/Info
#
# Parameters : - none  
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- __HardCodedLines.sh
#
# Hard coded:	- Type of text files
#				- Path to subdirs
#
# New in Distro V 2.0: - Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2017/12/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below: 
	# - RenameInPlaceVotToMnt to rename in palce Mac volume name by Linux volume mounting name
# ^^^ ----- Hard coded lines to check --- ^^^ 


for TXTFILES in `find ./*/info -maxdepth 1 \( -name  "externalSlantRangeDEM.txt" -or -name "slantRangeMask*.txt" \)` 
do
	RenameInPlaceVotToMnt ${TXTFILES}
# 	${PATHGNU}/gsed -i -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/mnt\/1650%g  
# 							s%\/Volumes\/hp-D3600-Data_Share1%\/mnt\/3600%g 
# 						 	s%\/Volumes\/hp-D3601-Data_RAID6%\/mnt\/3601%g  
# 						 	s%\/Volumes\/hp-D3602-Data_RAID5%\/mnt\/3602%g" ${TXTFILES}
done 
