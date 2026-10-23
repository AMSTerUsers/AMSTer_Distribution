#!/bin/bash
# Script intends to remove all duplicate defo maps in MSBAS dir, e.g. MSBAS_yyyymmddThhmms_COMP.bin, 
# as well as their .hdr, Except the most recently computed ones.  
#
# NOTE: - must be launched in MSBAS dir that contains the defo maps
#		
# Parameters: - none 
#
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- awk 
#
# New in Distro V 1.0 20260205:	- set up 
# New in Distro V .1 20261013:	- Recommend using Search_Dependencies.sh for 
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


${PATHGNU}/gfind . -maxdepth 1 -type f -name 'MSBAS_*T*.bin' -printf '%T@ %f\n' | ${PATHGNU}/gawk '
$2 ~ /^MSBAS_[0-9]{8}T[0-9]{6}_.+\.bin$/ {
  split($2,a,"_")
  date = substr(a[2],1,8)
  t = $1
  if (!(date in best) || t > best[date]) {
    if (date in best_file) {
      print best_file[date]
      print best_file[date] ".hdr"
    }
    best[date] = t
    best_file[date] = $2
  } else {
    print $2
    print $2 ".hdr"
  }
}'  | xargs -r rm -f