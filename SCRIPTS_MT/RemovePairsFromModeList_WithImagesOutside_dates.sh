#!/bin/bash
######################################################################################
# This script aims at removing line in DefoInterpolx2Detrendi.txt contains at least one image before 
#   the MIN date provided as parameter 2 and/or one image after the MAX date provided as parameter 3 
#
# Parameters - Modei.txt such as DefoInterpolx2Detrendi.txt prepared for MSBAS, that is with no header and 4 columns format: 
#			   Modei/PairName.xdeg Bp yyyymmdd yyyymmdd
# 			 - Min and Max date of interval
#
# Dependencies:	- gsed
#
# Hard coded:	-
#
# New in V D 1.0.1: - bash for Linux compatibility 
# New in Distro V 1.0 20250424:	- based one RemovePairsFromModeList_WithImagesAfter.sh and RemovePairsFromModeList_WithImagesBefore.sh
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Apr 240, 2025"

echo ""
echo "${PRG} ${VER}, ${AUT}"
echo " "

PAIRFILE=$1
MINDATE=$2
MAXDATE=$3

RNDM=`date "+ %m_%d_%Y" | ${PATHGNU}/gsed "s/ //g"`

# remove pairs with at least one image before MINDATE
${PATHGNU}/gawk '( ( $3 > '${MINDATE}') && ( $4 > '${MINDATE}' ) ) ' ${PAIRFILE}  > ${PAIRFILE}_After${MAXDATE}_${RNDM}.txt 
# remove pairs with at least one image after MAXDATE
${PATHGNU}/gawk '( ( $3 < '${MAXDATE}') && ( $4 < '${MAXDATE}' ) ) ' ${PAIRFILE}_After${MAXDATE}_${RNDM}.txt   > ${PAIRFILE}_Between${MINDATE}_${MAXDATE}_${RNDM}.txt 

rm -f ${PAIRFILE}_After${MAXDATE}_${RNDM}.txt 



