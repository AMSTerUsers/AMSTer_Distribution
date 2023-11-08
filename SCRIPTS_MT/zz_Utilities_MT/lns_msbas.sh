#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at creating a symbolic link from envi geocoded files 
#      to where they will be used by MSBAS. 
#
# Parameters : - path to dir with the csl archives are stored.   
#              - path to dir where link will be copied 
#
# V1.0 (April 06, 2016)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"


ARCHIVES=$1					# path to dir with the raw archives to read
LINKTOCSL=$2				# path to dir where images in csl format will be stored

if [ $# -lt 2 ] ; then echo “Usage $0 PATH_TO_ARCHIVES PATH_TO_LINK”; exit; fi

echo ""
# Check required dir:
#####################
# Path to original raw data 
if [ -d "${ARCHIVES}/" ]
then
   echo " OK: a directory exist where I guess csl archives are stored." 
   echo "      I guess images are in ${ARCHIVES}."    
else
   echo " "
   echo " NO directory ${ARCHIVES}/ where I can find raw data. Can't run..." 
   exit 1
fi
# Path where to store data in csl format 
if [ -d "${LINKTOCSL}" ]
then
   echo " OK: a directory exist where I can make a link to data in csl format." 
   echo "     They will be strored in ${LINKTOCSL}"
else
   echo " "
   echo " NO expected ${LINKTOCSL} directory."
   echo " I will create a new one. I guess it is the first run for that mode." 
   mkdir -p ${LINKTOCSL}
fi

# Let's Go:
###########	

# read existing csl archives (usually in /Volumes/hp-1650-Data_Share1/SAR_CSL/SAT/TRKDIR/NoCrop)
cd ${ARCHIVES}				
ls -d *.rev  > List_ready.txt

for LINE in `cat -s List_ready.txt`
	do	
		#ln -s ${ARCHIVES}/${LINE} ${LINKTOCSL}/${LINE}
		cp ${ARCHIVES}/${LINE} ${LINKTOCSL}/${LINE}
		Echo "Link ${LINE} created"
done

rm ${ARCHIVES}/List_ready.txt 
Echo "Done." 
