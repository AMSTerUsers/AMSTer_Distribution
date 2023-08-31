#!/bin/bash
######################################################################################
# This script aims at removing all pairs of images that does not contains at least 
# one image between two dates provided as parameters. It will then store the results in 
# a file named ${PAIRFILE}_Between_${MINDATE}_${MAXDATE}.txt that contains all pairs 
# with at least one images in [${MINDATE},${MAXDATE}].
#  This file is a 4 columns file with header, as the input file. 
# It also a-output the results in a file named 
#  _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt that contains only one column without header
#  in the form of dateMAS_dateSLV 
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
# New in V D 1.2.0: - also create a table _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt as DATEMAS_DATESLV
# New in V D 1.3.0: - do not add header in _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt 
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/03 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.32 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on March 30, 2023"
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
${PATHGNU}/gawk '( ( $1 >= '${MINDATE}') || ( $2 >= '${MINDATE}' ) ) ' ${PAIRFILE}_NoHeader_${RNDM}_tmp.txt > ${PAIRFILE}_Before${MINDATE}_NoBaselines_${RNDM}.txt 
# remove pairs with at least one image before MAXDATE
${PATHGNU}/gawk '( ( $1 <= '${MAXDATE}') || ( $2 <= '${MAXDATE}' ) ) ' ${PAIRFILE}_Before${MINDATE}_NoBaselines_${RNDM}.txt  > ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt 

# create _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt as DATEMAS_DATESLV
${PATHGNU}/gawk ' {print $1"_"$2 } ' ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt | sort | uniq > _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt

echo "  Master	   Slave	 Bperp	 Delay" > table_Header.txt
echo "" >> table_Header.txt
cat table_Header.txt ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt > ${PAIRFILE}_Between_${MINDATE}_${MAXDATE}.txt

rm -f table_Header.txt
rm -f ${PAIRFILE}_NoHeader_${RNDM}_tmp.txt 
rm -f ${PAIRFILE}_Before${MINDATE}_NoBaselines_${RNDM}.txt ${PAIRFILE}_After${MAXDATE}_NoBaselines_${RNDM}.txt 



