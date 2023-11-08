#!/bin/bash
######################################################################################
# This script aims at removing pairs of images that contains at least one image before 
#   the date provided as parameter
#
# Parameters - List of pairs (with path) from Prepa_MSBAS.sh, that is with a 2 lines 
#			   header and 4 columns format: yyyymmdd yyyymmdd (-)val (-)val
# 			 - Max date  
#
# Dependencies:	- gsed
#
# Hard coded:	-
#
# New in Distro V 1.1:	- 
#
# New in V D 1.0.1: - bash for Linux compatibility 
# New in V D 1.1.0: - change outputname that was miss leading
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo ""
echo "${PRG} ${VER}, ${AUT}"
echo " "

PAIRFILE=$1
MAXDATE=$2

RNDM=`date "+ %m_%d_%Y" | ${PATHGNU}/gsed "s/ //g"`


# remove header
cat ${PAIRFILE} | tail -n+3 | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${PAIRFILE}_After${MAXDATE}_${RNDM}_tmp.txt 

# remove lines where 
${PATHGNU}/gawk '( ( $1 > '${MAXDATE}') || ( $2 > '${MAXDATE}' ) ) ' ${PAIRFILE}_After${MAXDATE}_${RNDM}_tmp.txt  > ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt 

rm -f ${PAIRFILE}_After${MAXDATE}_${RNDM}_tmp.txt 
