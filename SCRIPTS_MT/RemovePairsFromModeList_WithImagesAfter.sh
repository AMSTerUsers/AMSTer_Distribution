#!/bin/bash
######################################################################################
# This script aims at removing line in DefoInterpolx2Detrendi.txt contains at least one image after 
#   the MAX date provided as parameter
#
# Parameters - Modei.txt such as DefoInterpolx2Detrendi.txt prepared for MSBAS, that is with no header and 4 columns format: 
#			   Modei/PairName.xdeg Bp yyyymmdd yyyymmdd
# 			 - Max date  
#
# Dependencies:	- gsed
#
# Hard coded:	-
#
# New in V D 1.0.1: - bash for Linux compatibility 
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

# remove lines where 
${PATHGNU}/gawk '( ( $3 < '${MAXDATE}') && ( $4 < '${MAXDATE}' ) ) ' ${PAIRFILE}  > ${PAIRFILE}_Below${MAXDATE}_${RNDM}.txt 
