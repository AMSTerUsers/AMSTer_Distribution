#!/bin/bash
# Script to read the date of the CosmoSkymed Data from the xml file located in the Dir
#  and rename the dir accordingly. 
# All files must have to be first unzipped to be transformed in Dir. 
# 
# Parameters: - none
#
# Dependencies: - none
#
# New in Distro V 1.0:	- Based on developpement version and beta version 1.0
# New in Distro V 1.1 (Jan 31, 2023):	- More robust date search in h5 naming
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
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
echo " "

ls | ${PATHGNU}/grep -v ".tmp" | ${PATHGNU}/grep -v "ID_" | ${PATHGNU}/grep -v ".eml" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".gz" > listDIR.tmp

for DIR in `cat -s listDIR.tmp`
do
	if [ $(echo ${DIR} | ${PATHGNU}/grep -c -) == 1 ] 
		then 
			cd ${DIR}
			#DATE=`echo *.h5 | cut -d _ -f 9 | cut -c 1-8`
			DATE=`echo *.h5 | ${PATHGNU}/grep -Eo "[0-9]{14}"  | cut -c 1-8 | head -1`
			echo "Dir ${DIR} has been renamed ${DATE}" > ${DIR}.txt
			cd ..
			mv ${DIR} ${DATE}
		else 
			echo "Dir ${DIR} does not contains a dash ; probably already renamed. Hence skip this dir"
	fi
done

rm listDIR.tmp
