#!/bin/bash
######################################################################################
# This script aims at filterfing/filling gaps in defo map. It must be run in the dir 
#    where defo map is stored. 
#
# Input image is expected to be envi like, that is with .dhr header. 
# Output file created will be envi format and hdr will be included with output. 
#
# Parameters :	- file to filter (its .hdr counterpart must be in the dir)
#
# Hard coded:	- width of the median filter, i.e. 11 here (cfr line 29)
#
# Dependencies:
#	 - gmt
# 
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# N.d'Oreye, v 1.0 2016/04/07 -                         
######################################################################################
echo
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 15, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

FILETOINTERP=$1

FILTVAL=11   # width of median filter

FILETOINTERP=`basename ${FILETOINTERP}`
FILENAME=`echo ${FILETOINTERP%.*}`

if [ `ls ${FILENAME}.* 2> /dev/null| wc -l` ] # check if file has an extension
	then
		FILEXT=`echo ${FILETOINTERP##*.}`
		fout=${FILENAME}_filt${FILTVAL}_interpolated.${FILEXT}
	else
		fout=${FILENAME}_filt${FILTVAL}_interpolated
fi

gmt grdfilter ${FILETOINTERP} -Dp -Fm${FILTVAL} -G${fout}=gd:ENVI

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL DONE- HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

