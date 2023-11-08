#!/bin/bash
# Exclude pairs from DefoInterpolx2Detrendi.txt that are located in 
#     DefoInterpolx2Detrendi/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
# That file contains pair list as DATE_DATE
#
# Pairs in that list may satisfy Bt and Bp criteria as well as Coh threshold criteria (if filtered on Coh) 
# but are considered to be rejected for whatever reason.. 
# One could have reject images forming that pair by setting them in Quarantained dir but that would prevent 
# usage of all the pairs involving these images, wich is more restrictive. 
#
# Rejecting only selected pairs was required for automated mass processing of Domuyo where 
# only one pair accidentally satisfied the Coh Threshold criteria during the Austral Winter.
# That pair was taken into account in msbas processing and resulted in erroneous results.
#
# This script must be launched after build_header_msbas_criteria.sh and before MSBAS.sh
#
# Parameters:	- Path to .../MSBAS/REGION/MODEi where file _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt is loacted
#
# Dependencies: 	- gnu grep
# 
# V1.0: 20200804
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

PATHMODE=$1

cd ${PATHMODE}

MODE=`basename ${PATHMODE}`

# force discarding pairs that are satisfying Bt and Bp and Coh criteria - may be needed if some pairs are known to be erroneous for whatever reason
if [ -f _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt ] 
	then 
		echo "// Exclude pairs that are in _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt even if they satisfy the Bt, Bp and Coh criteria "
		mv ../${MODE}.txt ${MODE}_WithoutForceExclude.txt
		${PATHGNU}/grep  -Fv -f _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt ${MODE}_WithoutForceExclude.txt > ../${MODE}.txt 
fi
