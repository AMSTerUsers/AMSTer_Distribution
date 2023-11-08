#!/bin/bash
######################################################################################
# This script renames the CSK dir obtained from CSK mass reading by only keeping DATE.csl
#      instead of CSKx_DATE_TIME.csl
#
# Must be launched in the dir that contaons all the data dir
#
# V1.0 (May 19, 2017) 
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

for DIR in `ls CSK*.csl | ${PATHGNU}/grep -v Headers | ${PATHGNU}/grep -v Data | ${PATHGNU}/grep -v Info`
do
	DIR=`echo ${DIR} | cut -d : -f 1`
	NEWNAME=`echo ${DIR} | cut -d _ -f 2`
	mv ${DIR} ${NEWNAME}.csl
done



