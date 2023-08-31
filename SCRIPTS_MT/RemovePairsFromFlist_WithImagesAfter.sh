#!/bin/bash
######################################################################################
# This script aims at removing pairs of images that contains at least one image after 
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
# New in V D 1.0.1: - bash for Linux compatibility 
# New in V D 1.1.0: - change outputname that was miss leading
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/03 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on march 22, 2023"
echo ""
echo "${PRG} ${VER}, ${AUT}"
echo " "

PAIRFILE=$1
MAXDATE=$2

RNDM=`date "+ %m_%d_%Y" | ${PATHGNU}/gsed "s/ //g"`


# remove header
cat ${PAIRFILE} | tail -n+3 | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${PAIRFILE}_Before${MAXDATE}_${RNDM}_tmp.txt 

# remove lines where 
${PATHGNU}/gawk '( ( $1 < '${MAXDATE}') || ( $2 < '${MAXDATE}' ) ) ' ${PAIRFILE}_Before${MAXDATE}_${RNDM}_tmp.txt  > ${PAIRFILE}_Before${MAXDATE}_NoBaselines_${RNDM}.txt 

rm -f ${PAIRFILE}_Before${MAXDATE}_${RNDM}_tmp.txt 
