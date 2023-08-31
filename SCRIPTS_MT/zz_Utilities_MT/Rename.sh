#!/bin/bash
# Script to rename files based on name criteria. 
#
#
# Parameters : - criteria to match 
#			   - new criteria  
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#
# New in V1.0.1 Beta:	- take state variable for PATHGNU etc 
#
# CSL InSAR Suite utilities. 
# NdO (c) 2018/03/29 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0.1 Beta CIS script utilities"
AUT="Nicolas d'Oreye, (c)2018, Last modified on Oct 30, 2018"
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


