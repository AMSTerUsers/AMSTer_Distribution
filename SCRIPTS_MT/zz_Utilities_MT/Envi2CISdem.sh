#!/bin/bash
# Script aims at making a DEM usable by CIS based on an Envi format DEM computed by CIS (!), 
#   eg from TDX processing 
#
# Parameters : - path to Envi DEM 
#
# Dependencies : - python
#				 - scripts FLIPproducts.py.sh and FLOPproducts.py.sh
#
# New in V1.0.1: -
#
# CSL InSAR Suite utilities. 
# NdO (c) 2018/03/29 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0.0 Beta CIS script utilities"
AUT="Nicolas d'Oreye, (c)2018, Last modified on Apr 28, 2020"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

ENVIDEM=$1

if [ `cat ${ENVIDEM}.hdr | grep Lines | wc -l ` -eq 1 ] 
	then 
		NLINES=`cat ${ENVIDEM}.hdr | grep Lines | cut -d = -f 2`   
	else 
		NLINES=`cat ${ENVIDEM}.hdr | grep lines | cut -d = -f 2`   
fi

FLIPproducts.py.sh ${ENVIDEM} ${NLINES}
FLOPproducts.py.sh ${ENVIDEM}.flip ${NLINES}

mv ${ENVIDEM}.flip.flop ${ENVIDEM}_CIS
cp ${ENVIDEM}.hdr ${ENVIDEM}_CIS.hdr

rm -f ${ENVIDEM}.flip

