#!/bin/bash
# Transform first column of decimal year into YYYYMMDD
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# V1.0: Aug 16, 2018
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
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

