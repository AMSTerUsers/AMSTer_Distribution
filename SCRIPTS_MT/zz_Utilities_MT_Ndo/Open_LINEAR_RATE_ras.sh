#!/bin/bash
######################################################################################
# This script search for last date in MSBAS component directory and open the LINEAR_RATE ras
#
# Parameters: 	- path to dir to search
# 
# Dependencies:	- 
# 
# New in V 1.0 20260409:	- setup
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Apr 09, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

DIR=$1

cd $DIR

LASTDATE=$(
  ${PATHGNU}/find . -maxdepth 1 -type f -name 'MSBAS_*_*.bin' -printf '%f\n' |
  ${PATHGNU}/gawk 'match($0,/^MSBAS_([0-9]{8}).*_(LOS|EW|UD)\.bin$/,a){ if(a[1]>max) max=a[1] } END{print max}'
)
echo "Last img is ${LASTDATE}"

open MSBAS_LINEAR_RATE_*.ras