#!/bin/bash
# Transform first column of linux seconds in YYYYMMDD 
#
# Dependencies: - dgate
#
# CSL InSAR Suite utilities. 
# NdO (c) 2019/02/1 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0 Beta CIS script utilities"
AUT="Nicolas d'Oreye, (c)2016-2018, Last modified on Feb 1, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

FILE=$1

rm -f ${FILE}_yyyymmdd.txt

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "working on ${OS}"
# Change tab with "," if needed
${PATHGNU}/gsed -i "s/	/,/g" ${FILE}

for LINES in `cat ${FILE} | tail -n +1`  # all lines but first
do 
	linuxtime=`echo ${LINES} | cut -c 1-10`
	case ${OS} in 
		"Linux") 
			yyyymmdd=`date -d@${linuxtime} +"%Y%m%d"` ;;
		"Darwin")
			yyyymmdd=`${PATHGNU}/gdate -d@${linuxtime} +"%Y%m%d"`	;;
	esac
	echo "${yyyymmdd} ${LINES}" >> ${FILE}_yyyymmdd.txt
done 

${PATHGNU}/gsed -i "s/,/	/g" ${FILE}_yyyymmdd.txt
${PATHGNU}/gsed -i "s/,/	/g" ${FILE}
