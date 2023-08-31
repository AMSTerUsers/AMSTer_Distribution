#!/bin/bash
######################################################################################
# This script aims at removing line in DefoInterpolx2Detrendi.txt contains at least one image before 
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
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/03 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.0.1 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on May 15, 2020"
echo ""
echo "${PRG} ${VER}, ${AUT}"
echo " "

PAIRFILE=$1
MAXDATE=$2

RNDM=`date "+ %m_%d_%Y" | ${PATHGNU}/gsed "s/ //g"`

# remove lines where 
${PATHGNU}/gawk '( ( $3 > '${MAXDATE}') && ( $4 > '${MAXDATE}' ) ) ' ${PAIRFILE}  > ${PAIRFILE}_After${MAXDATE}_${RNDM}.txt 


