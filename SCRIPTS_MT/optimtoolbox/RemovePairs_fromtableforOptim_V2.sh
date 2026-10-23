#!/bin/bash
######################################################################################
# This script aims at removing from the table_minBP_maxBPminBT_maxBT.txt prepared with 
# PrepaMSBAS.sh all the pairs listed in file  table_minBP_maxBPminBT_maxBT_Pairs2remove.txt
#
# 
# Parameters:	- List of pairs (with path) from Prepa_MSBAS.sh, that is with a 2 lines 
#			  	  header and 4 columns format: yyyymmdd yyyymmdd (-)val (-)val
# 	     		- List of Pairs 2 remove that is a 2 colummns format yyyymmdd yyyymmdd
#	     		- Remark for outputname
#
# Output:	-  *_orig.txt : save of input table (read in priority if already exist)
# 	     	-  *_optimized.txt : table with pairs removed
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies: gsed, gawk
#
# Hard coded:	-
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on oct 13, 2026"
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo "Processing launched on $(date) " 
echo " "


TABLEFILE=$1
PAIRS2RM=$2


TABLEFILEORIG=`echo ${TABLEFILE} | ${PATHGNU}/gsed 's/.*txt\///' | cut -d . -f1`
TABLEOUPUT=`echo ${PAIRS2RM} | rev | cut -d . -f2- | rev`
TABLEOUPUT=${TABLEOUPUT}_optimized.txt
TABLEFILEORIG=${TABLEFILEORIG}_orig.txt

if [ -e "${TABLEFILEORIG}" ]
then 
	cp ${TABLEFILEORIG} ${TABLEFILE}
	echo "File ${TABLEFILEORIG} exist, copy to ${TABLEFILE}"
else
	cp ${TABLEFILE} ${TABLEFILEORIG}
	echo "File ${TABLEFILE} saved as  ${TABLEFILEORIG}" 
fi
${PATHGNU}/gawk '{print $1}' ${PAIRS2RM}> tmp0
${PATHGNU}/gawk 'NR>2{print $1"_"$2" "$0}' ${TABLEFILEORIG}> tmp1
${PATHGNU}/gawk 'NR==FNR {A[$1]; next } !($1 in A) {print $0}' tmp0 tmp1 > tmp2

${PATHGNU}/gawk 'NR<3{print $0}' ${TABLEFILEORIG} > tmp
cut -d " " -f2- tmp2 >> tmp


mv tmp ${TABLEOUPUT}
rm tmp*

#cp ${TABLEOUPUT} ${TABLEFILE}
echo "Pairs listed in"
echo "${PAIRS2RM}"
echo "were removed from table" 
echo "${TABLEFILE}"
echo ""
echo "Table optimized is  "
echo "${TABLEOUPUT}"

#echo "A copy of the new file "
#echo "${TABLEFILE}" 
#echo "was saved as" 
#echo "${TABLEOUPUT}" 


