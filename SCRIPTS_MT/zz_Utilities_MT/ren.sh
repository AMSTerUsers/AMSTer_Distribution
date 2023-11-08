#!/bin/bash
######################################################################################
# This script change hdr file name as the base one 
#
# Parameters : - none
#
# Dependencies:	- none
#
# New in V1.0 beta: 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, S. Samsonov v 1.0 2018/11/15 -                         
######################################################################################
echo
PRG=`basename "$0"`
VER="v1.0 Beta CIS script utilities"
AUT="Nicolas d'Oreye, (c)2016-18, Last modified on Nov 15, 2018"
echo " "
echo "${PRG} ${VER}, ${AUT}"
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


