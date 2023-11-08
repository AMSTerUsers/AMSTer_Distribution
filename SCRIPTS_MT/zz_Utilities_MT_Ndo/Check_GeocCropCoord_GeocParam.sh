#!/bin/bash
######################################################################################
# This script check the coordinates corners of geocoded products in all the i12/TextFiles/geoProjectionParameters.txt
#  from the SAR_MASSPROCESS. Coordinates are logged into _GeoProjCoord.txt
#
# It may be compared to expected values (hard coded); if not as expected, it will list the pairs name in 
# _GeoProjCoord_WrongaPairs.txt where it will also log the creation date 
#
# Must be launnched in SAR_MASSPROCESS/sat/trk/crop/ where all pair dirs are
#
# New in Distro V 1.1 20230719: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


SOURCEDIR=$PWD

# Domuyo
#EXPECTEDXMIN=245000	
#EXPECTEDXMAX=513000	
#EXPECTEDYMIN=5840000
#EXPECTEDYMAX=6080000

# VVP
#EXPECTEDXMIN=673000	
#EXPECTEDXMAX=866000	
#EXPECTEDYMIN=9750000
#EXPECTEDYMAX=9920000

# PF
EXPECTEDXMIN=312000	
EXPECTEDXMAX=380000	
EXPECTEDYMIN=7632500
EXPECTEDYMAX=7692000


echo "Xmin Xmax Ymin Ymax Pair Computed_on " |  ${PATHGNU}/gawk '//{printf "%10s %10s %10s %10s %10s %15s\n",$1,$2,$3,$4,$5,$6 }' > _GeoProjCoord.txt

echo "WrongPair Xmin Xmax Ymin Ymax Computed_on" |  ${PATHGNU}/gawk '//{printf "%10s %10s %10s %10s %10s %15s\n",$1,$2,$3,$4,$5,$6 }' >_GeoProjCoord_WrongaPairs.txt

find . -maxdepth 1 -type d -name "S1*_*_*_*_S1*_*_*" > All_Pairs.txt

for PAIR in `cat All_Pairs.txt`
do 
	if [ -f "${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt" ] && [ -s "${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt" ]
		then 
			XMIN=`updateParameterFile ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt "xMin"`
			XMAX=`updateParameterFile ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt "xMax"`
			YMIN=`updateParameterFile ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt "yMin"`
			YMAX=`updateParameterFile ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt "yMax"`

			XMIN=`echo ${XMIN} | ${PATHGNU}/gawk '{print $1;}'`  # i.e. get 1st word
			XMAX=`echo ${XMAX} | ${PATHGNU}/gawk '{print $1;}'`	
			YMIN=`echo ${YMIN} | ${PATHGNU}/gawk '{print $1;}'`  
			YMAX=`echo ${YMAX} | ${PATHGNU}/gawk '{print $1;}'`	

			DATECREATION=`stat -c '%w' ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt` 

			if [ ${XMIN} != ${EXPECTEDXMIN} ] || [ ${XMAX} != ${EXPECTEDXMAX} ] || [ ${YMIN} != ${EXPECTEDYMIN} ] || [ ${YMAX} != ${EXPECTEDYMAX} ]
				then 
					echo "${PAIR} ${XMIN} ${XMAX} ${YMIN} ${YMAX} ${DATECREATION}" |  ${PATHGNU}/gawk '//{printf "%10s %10s %10s %10s %10s %15s\n",$1,$2,$3,$4,$5,$6 }' >> _GeoProjCoord_WrongaPairs.txt
			fi 
			echo "${PAIR} ${XMIN} ${XMAX} ${YMIN} ${YMAX} ${DATECREATION}" |  ${PATHGNU}/gawk '//{printf "%10s %10s %10s %10s %10s %15s\n",$1,$2,$3,$4,$5,$6 }'
			echo "${PAIR} ${XMIN} ${XMAX} ${YMIN} ${YMAX} ${DATECREATION}" |  ${PATHGNU}/gawk '//{printf "%10s %10s %10s %10s %10s %15s\n",$1,$2,$3,$4,$5,$6 }' >> _GeoProjCoord.txt
		else 
			echo "${PAIR} has no geoProjectionParameters.txt file" >> _GeoProjCoord_WrongaPairs.txt
			echo "${PAIR} has no geoProjectionParameters.txt file" >> _GeoProjCoord.txt
	fi
done 

rm -f All_Pairs.txt
