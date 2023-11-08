#!/bin/bash
# Transform first column of decimal year into YYYYMMDD
#
# V1.0: Aug 16, 2018
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

FILE=$1

#PATHGNU1=/usr/local/bin
#PATHGNU2=/opt/local/bin

rm -f ${FILE}_date.txt

#${PATHGNU2}/gsed -i "s/ /,/g" ${FILE}
${PATHGNU}/gsed -i "s/ /,/g" ${FILE}

for LINES in `cat ${FILE}`
do 
	decimalyyyy=`echo "${LINES}" | cut -d , -f 1`
	yyyy=`echo ${decimalyyyy} | cut -c 1-4`
	#leapm=`${PATHGNU1}/gdate --date="${yyyy}1231" +%j` # 365 or 366
	#doy=`echo ${decimalyyyy} ${yyyy} ${leapm} | ${PATHGNU2}/gawk '{printf("%f",($1-$2) * $3);}' | cut -d . -f 1` 
	leapm=`${PATHGNU}/gdate --date="${yyyy}1231" +%j` # 365 or 366
	doy=`echo ${decimalyyyy} ${yyyy} ${leapm} | ${PATHGNU}/gawk '{printf("%f",($1-$2) * $3);}' | cut -d . -f 1` 
	yyyymmdd=` gdate -d "${doy} days ${yyyy}-01-01" +"%Y%m%d"`
	echo "${yyyymmdd} ${LINES}" >> ${FILE}_date.txt

#${PATHGNU2}/gsed -i "s/,/ /g" ${FILE}_date.txt
${PATHGNU}/gsed -i "s/,/ /g" ${FILE}_date.txt

done 

