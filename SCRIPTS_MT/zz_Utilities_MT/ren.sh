#!/bin/bash
######################################################################################
# This script change hdr file name as the base one 
#
# Parameters : - none
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- none
#
# New in V1.0 beta: 
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


ls *.hdr > List_bin.txt 

for BIN in `cat List_bin.txt `
do 
	BINBASE=`basename ${BIN} .hdr`
	mv ${BIN} ${BINBASE}.bin.hdr
done 

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL HDR ADDED AND FILES MOVED- HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


