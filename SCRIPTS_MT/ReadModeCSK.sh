#!/bin/bash
# Script to read the orbit mode of the CosmoSkymed Data from the xml file located in the Dir
#  and move the data in appropriate accordingly. 
#
# Need to be run in dir where DATE.csl directories are.
#
# Parameters : - Region: (e.g. Bukavu or VVP) for dir naming.   
#
# Dependencies:	- directories where to put the data must exist: 
#					REGION_Asc and REGION_Desc
#				- gnu sed and awk for more compatibility. 
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.2
# New in Distro V 1.1:	- Keep link in original dir for automation
# New in Distro V 1.2:	- List only new dir using find 
# New in Distro V 1.3:	- Compatible with new data.csl naming, that is SSAR1_yyyymmdd_hl.csl (h is A or D heading; l is R or L looking direction) 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/02/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.3 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Feb 1, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

REGION=$1

if [ $# -lt 1 ] ; then echo “Usage $0 REGION”; exit; fi


if [ -d "../${REGION}_Asc/NoCrop" ] && [ -d "../${REGION}_Desc/NoCrop" ]
then
   echo ""
   echo " OK: directories exist where I guess CSL data will be stored :" 
   echo "  ${REGION}_Asc/NoCrop and ${REGION}_Desc/NoCrop"    
   echo ""
else
   echo ""
   echo " NO directories ${REGION}_Asc/NoCrop and ${REGION}_Desc/NoCrop where I can store data."
   echo " Can't run..." 
   exit 1
fi

for DIR in `find . -maxdepth 1 -type d -name "*.csl"`
do
	cd ${DIR}/Info
	MODE=`grep "Heading direction" SLCImageInfo.txt | cut -d " " -f 1 | ${PATHGNU}/gsed "s/ending//"`
	IMGDATE=`echo "${DIR}" | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select 8 characters string from dir name 

	echo "Image ${DIR} is orbit ${MODE} " 
	echo "Shall move ${DIR} in ../../${REGION}_${MODE}" 
	cd ..
	cd ..
	
	mv ${DIR} ../${REGION}_${MODE}/NoCrop/${IMGDATE}.csl
	# add link ti source dir for automation 
	ln -s ../${REGION}_${MODE}/NoCrop/${IMGDATE}.csl ${DIR}
done

echo "------------------------------------"
echo "All CSK img sorted in Asc and Desc. "
echo "------------------------------------"
