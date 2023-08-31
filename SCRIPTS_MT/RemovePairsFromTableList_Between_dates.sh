#!/bin/bash
######################################################################################
# This script aims at removing all pairs of images that contains at least 
# one image between two dates provided as parameters.
# It will then store the results in 
# a file named ${PAIRFILE}_Without_${MINDATE}_${MAXDATE}.txt that contains all pairs 
# from the input file except those with at least one images in ]${MINDATE},${MAXDATE}[.
#  This file is a 4 columns file with header, as the input file. 
#
# Parameters - List of pairs (with path) from Prepa_MSBAS.sh, that is with a 2 lines 
#			   header and 4 columns format: yyyymmdd yyyymmdd (-)val (-)val
# 			 - Min date
#			 - Max date  
#
# Dependencies:	- gawk
#
# Hard coded:	-
#
# New in Distro V 1.1:	- 
#
# New in V D 1.0.1: - bash for Linux compatibility 
# New in V D 1.0.2: - also save a version without header
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/03 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.0.2 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on March 27, 2023"
echo ""
echo "${PRG} ${VER}, ${AUT}"
echo " "

PAIRFILE=$1
MINDATE=$2
MAXDATE=$3

RNDM=`date "+ %m_%d_%Y" | ${PATHGNU}/gsed "s/ //g"`

# remove header
cat ${PAIRFILE} | tail -n+3 > ${PAIRFILE}_NoHeader_${RNDM}_tmp.txt 

# remove pairs with at least one image after MINDATE
${PATHGNU}/gawk '( ( $1 < '${MINDATE}') && ( $2 < '${MINDATE}' ) ) ' ${PAIRFILE}_NoHeader_${RNDM}_tmp.txt > ${PAIRFILE}_Before${MINDATE}_NoBaselines_${RNDM}.txt 
# remove pairs with at least one image before MAXDATE
${PATHGNU}/gawk '( ( $1 > '${MAXDATE}') && ( $2 > '${MAXDATE}' ) ) ' ${PAIRFILE}_NoHeader_${RNDM}_tmp.txt  > ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt 

echo "  Master	   Slave	 Bperp	 Delay" > table_Header.txt
echo "" >> table_Header.txt
cat table_Header.txt ${PAIRFILE}_Before${MINDATE}_NoBaselines_${RNDM}.txt ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt > ${PAIRFILE}_Without_${MINDATE}_${MAXDATE}.txt
cat ${PAIRFILE}_Before${MINDATE}_NoBaselines_${RNDM}.txt ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt > ${PAIRFILE}_Without_${MINDATE}_${MAXDATE}_NoHeader.txt


rm -f table_Header.txt
rm -f ${PAIRFILE}_NoHeader_${RNDM}_tmp.txt 
rm -f ${PAIRFILE}_Before${MINDATE}_NoBaselines_${RNDM}.txt ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt
