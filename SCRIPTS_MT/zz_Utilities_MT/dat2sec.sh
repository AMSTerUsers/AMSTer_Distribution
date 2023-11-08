#!/bin/bash
# Transform first column of YYYYMMDD in linux seconds 
#
# Dependencies: - dgate
#
# New in V1.0 (Feb 1, 2019)
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

rm -f ${FILE}_linuxsec.txt

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "working on ${OS}"
# Change tab with "," if needed
${PATHGNU}/gsed -i "s/	/,/g" ${FILE}

for LINES in `cat ${FILE} | tail -n +1`  # all lines but first
do 
	yyyymmdd=`echo ${LINES} | cut -c 1-8`
	case ${OS} in 
		"Linux") 
			linuxsec=`date -d ${yyyymmdd} +"%s"` ;;
		"Darwin")
			linuxsec=`${PATHGNU}/gdate -d ${yyyymmdd} +"%s"`	;;
	esac
	echo "${linuxsec} ${LINES}" >> ${FILE}_linuxsec.txt
done 

${PATHGNU}/gsed -i "s/,/	/g" ${FILE}_linuxsec.txt
${PATHGNU}/gsed -i "s/,/	/g" ${FILE}
