#!/bin/bash
# Script aims at making a DEM usable by CIS based on an Envi format DEM computed by CIS (!), 
#   eg from TDX processing 
#
# Parameters : - path to Envi DEM 
#
# Dependencies : - python
#				 - scripts FLIPproducts.py.sh and FLOPproducts.py.sh
#
# New in V1.0.1 Apr 28, 2020
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

