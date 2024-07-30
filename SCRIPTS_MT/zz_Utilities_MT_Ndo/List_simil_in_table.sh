#!/bin/bash
# Script intends to compare two tables of pair lists
# Ouputs are 2 textfiles containing :
#	- a list of pairs unique to each file and 
#	- a list of pairs common to both tables.
#
# NOTE: - 
#
# WARNING: 	
#
# Parameters: - path to tablefile1
#			  - path to tablefile2 
#			  - path where results will be stored
#
# Hardcoded: names of the outputs
#
# Dependencies:	- gawk 
#               			
# New in Distro V 1.0:  - 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Feb 09, 2024 by DS"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

# Inputs parameters
FILE1=$1
FILE2=$2
RESULTDIR=$3


# Make header 
echo "   Master	   Slave	 Bperp	 Delay"  > ${RESULTDIR}/pairs_in_file_1_only.txt
echo ""  >> ${RESULTDIR}/pairs_in_file_1_only.txt

echo "   Master	   Slave	 Bperp	 Delay"  > ${RESULTDIR}/pairs_in_file_2_only.txt
echo ""  >> ${RESULTDIR}/pairs_in_file_2_only.txt

#echo "   Master	   Slave	 Bperp	 Delay"  > ${RESULTDIR}/pairs_in_both_tables.txt
#echo ""  >> ${RESULTDIR}/pairs_in_both_tables.txt


# List pairs that are in first table and in not second table
${PATHGNU}/gawk 'NR==FNR { n[$1 $2]=($1 $2);next } !($1 $2 in n) { print $0 }' $FILE2 $FILE1 >> ${RESULTDIR}/pairs_in_file_1_only.txt

# List pairs that are in second table and not in first table
${PATHGNU}/gawk 'NR==FNR { n[$1 $2]=($1 $2);next } !($1 $2 in n) { print $0 }' $FILE1 $FILE2 >> ${RESULTDIR}/pairs_in_file_2_only.txt

# List pairs that are common to both tables
${PATHGNU}/gawk 'NR==FNR { n[$1 $2]=($1 $2);next } ($1 $2 in n) { print $0 }' $FILE2 $FILE1 > ${RESULTDIR}/pairs_in_both_tables.txt


# correct the 3rd header by removing the 3rd line
#${PATHGNU}/gsed -i '3d' ${RESULTDIR}/pairs_in_both_tables.txt 

