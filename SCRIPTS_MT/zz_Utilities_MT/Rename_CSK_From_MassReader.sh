#!/bin/bash
######################################################################################
# This script renames the CSK dir obtained from CSK mass reading by only keeping DATE.csl
#      instead of CSKx_DATE_TIME.csl
#
# Must be launched in the dir that contaons all the data dir
#
# New in V1.1: - 
######################################################################################
PRG=`basename "$0"`
VER="v1.0 CIS script utilities"
AUT="Nicolas d'Oreye, (c)2017; last update May 19, 2017"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

for DIR in `ls CSK*.csl | ${PATHGNU}/grep -v Headers | ${PATHGNU}/grep -v Data | ${PATHGNU}/grep -v Info`
do
	DIR=`echo ${DIR} | cut -d : -f 1`
	NEWNAME=`echo ${DIR} | cut -d _ -f 2`
	mv ${DIR} ${NEWNAME}.csl
done



