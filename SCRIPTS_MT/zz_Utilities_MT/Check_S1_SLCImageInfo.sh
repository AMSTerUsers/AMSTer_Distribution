#!/bin/bash
# Script to check that there is a SLCImageInfo.txt in each S1.CSL dir and that polarisatin is ok.  
#
# Need to be run in dir where all the S1.csl data from a given mode are stored 
#   (e.g. /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/DRC_Bukavu_A_174/NoCrop).
#
# Parameters : - None but pol is hard coded.   
#
# Dependencies:	- none
#
# New in V1.1 Beta (July 18, 2019):	- check polarisation
# New in Distro V 2.0 20231030:		- Rename MasTer Toolbox as AMSTer Software
#									- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
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

EXPECTEDPOL="VV"  # usually OK for S1
SOURCEDIR=$PWD

rm -f _Missing_SLCImageInfo.txt
rm -f _Missing_Pol_in_SLCImageInfo.txt

i=0
j=0
for S1DIR in `ls -d *.csl`
do 
	if [ ! -f ${SOURCEDIR}/${S1DIR}/Info/SLCImageInfo.txt ] ; then 
			echo " SLCImageInfo.txt is missing in ${S1DIR}"
			echo ${S1DIR} >> _Missing_SLCImageInfo.txt
			j=`echo "$j+1" | bc`
		else 
			# check polarisation 
			POLSLC=`updateParameterFile ${SOURCEDIR}/${S1DIR}/Info/SLCImageInfo.txt "Polarisation mode"`
			echo ${POLSLC}
 			if [ "${POLSLC}" != "${EXPECTEDPOL}" ] ; then 
 				updateParameterFile ${SOURCEDIR}/${S1DIR}/Info/SLCImageInfo.txt "Polarisation mode" ${EXPECTEDPOL}
 				echo "missing pol in ${S1DIR}" >> _Missing_Pol_in_SLCImageInfo.txt
 			fi
			i=`echo "$i+1" | bc`
	fi
done

echo "$i images with SLCImageInfo.txt"
echo "$j images without SLCImageInfo.txt"
