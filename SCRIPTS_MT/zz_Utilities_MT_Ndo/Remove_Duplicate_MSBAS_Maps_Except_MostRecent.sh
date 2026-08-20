#!/bin/bash
# Script intends to remove all duplicate defo maps in MSBAS dir, e.g. MSBAS_yyyymmddThhmms_COMP.bin, 
# as well as their .hdr, Except the most recently computed ones.  
#
# NOTE: - must be launched in MSBAS dir that contains the defo maps
#		
# Parameters: - none 
#
#
# Dependencies:	- awk 
#
# New in Distro V 1.0 20260205:	- st up 
									
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Feb 05, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
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