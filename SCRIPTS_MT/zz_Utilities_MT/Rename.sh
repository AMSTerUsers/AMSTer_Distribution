#!/bin/bash
# Script to rename files based on name criteria. 
#
#
# Parameters : - criteria to match 
#			   - new criteria  
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#
# New in V1.0.1 Beta (Oct 30, 2018):	- take state variable for PATHGNU etc 
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

for FILES in `ls *.deg*` 
do 
	FILENODOT=`echo ${FILES} | gsed 's/\.deg/deg/'`
	echo "FILE is		${FILES} "
	echo "FILENODOT is	${FILENODOT} "
	if [ ! -f ${FILENODOT} ]
		then 
			echo "rename"
			mv ${FILES} ${FILENODOT} 
		else 
			echo "clean and rename"
			rm ${FILENODOT} 
			mv ${FILES} ${FILENODOT} 
	fi
done 


