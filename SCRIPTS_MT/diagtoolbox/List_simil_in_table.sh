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
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- gawk 
#               			
# New in Distro V 1.0:  - 
# New in Distro V 1.1 20250207 DS :  - remove header lines
# New in Distro V 1.2 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.2 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on oct 13, 2026"
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo "Processing launched on $(date) " 
echo " "


source $HOME/.bashrc

# Inputs parameters
FILE1=$1
FILE2=$2
RESULTDIR=$3


# Make header 
#echo "   Master	   Slave	 Bperp	 Delay"  > ${RESULTDIR}/pairs_in_file_1_only.txt
#echo ""  >> ${RESULTDIR}/pairs_in_file_1_only.txt

#echo "   Master	   Slave	 Bperp	 Delay"  > ${RESULTDIR}/pairs_in_file_2_only.txt
#echo ""  >> ${RESULTDIR}/pairs_in_file_2_only.txt

#echo "   Master	   Slave	 Bperp	 Delay"  > ${RESULTDIR}/pairs_in_both_tables.txt
#echo ""  >> ${RESULTDIR}/pairs_in_both_tables.txt


# List pairs that are in first table and in not second table
${PATHGNU}/gawk 'NR==FNR { n[$1 $2]=($1 $2);next } !($1 $2 in n) { print $0 }' $FILE2 $FILE1 > ${RESULTDIR}/pairs_in_file_1_only.txt

# List pairs that are in second table and not in first table
${PATHGNU}/gawk 'NR==FNR { n[$1 $2]=($1 $2);next } !($1 $2 in n) { print $0 }' $FILE1 $FILE2 > ${RESULTDIR}/pairs_in_file_2_only.txt

# List pairs that are common to both tables
${PATHGNU}/gawk 'NR==FNR { n[$1 $2]=($1 $2);next } ($1 $2 in n) { print $0 }' $FILE2 $FILE1 > ${RESULTDIR}/pairs_in_both_tables.txt


# correct the 3rd header by removing the 3rd line
#${PATHGNU}/gsed -i '3d' ${RESULTDIR}/pairs_in_both_tables.txt 
