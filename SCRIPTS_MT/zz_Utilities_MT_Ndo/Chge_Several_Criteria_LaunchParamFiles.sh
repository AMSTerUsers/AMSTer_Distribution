#!/bin/bash
######################################################################################
# This script change several criteria in all Param files in current dir
#
# Better be sure before launching - making backup of dir/subdirs is advised  
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
######################################################################################

CRITERE=$1
NEWCRITERE=$2

${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/_ChgeAll_LaunchParamFiles.sh "# VERSION Nov 30 2018" "# VERSION Apr 18 2019"
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/_ChgeAll_LaunchParamFiles.sh "# CROP, CROPyes or CROPno ?" "# CROP, CROPyes or CROPno, or for S1, path to kml that will be used to define area of interest."
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/_ChgeAll_LaunchParamFiles.sh "# FIRSTP, ok Crop" "# FIRSTP, Crop"
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/_ChgeAll_LaunchParamFiles.sh "# INTERFML, multilook factor for final interferometric products generation" "# INTERFML, multilook factor for final interferometric products generation (to multiply to the LARGEST side of the pixel)"
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/_ChgeAll_LaunchParamFiles.sh "# SKIPUW, SKIPno unwraps and geocode all products, SKIPyes skips unwrapping and geocode only available products, Mask geocode only ampli and coh (for mask geenration)" "# SKIPUW, SKIPno unwraps and geocodes all products, SKIPyes skips unwrapping and geocodes only available products, Mask geocodes only ampli and coh (for mask generation)"
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/_ChgeAll_LaunchParamFiles.sh "# UW_METHOD, Select phase unwrapping method (SNAPHU, CSL or DETPHUN)" "# UW_METHOD, Select phase unwrapping method (SNAPHU, MT or DETPHUN)"
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/_ChgeAll_LaunchParamFiles.sh "# if CSL unwrapping:" "# if CIS unwrapping:"
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/_ChgeAll_LaunchParamFiles.sh "(at FORCEGEOPIXSIZE - convenient" "(at FORCEGEOPIXSIZE - mandatory"

# add the line with param PROCESSMETHOD before INITPOL
for filename in `find . -type f -name "*.txt" | grep LaunchMTparam`
   do
	  ${PATHGNU}/grep INITPOL ${filename} | cut -d , -f 1 > initpol.txt
	  LINETOFIND=`cat initpol.txt`
	   ${PATHGNU}/gsed -i  "/${LINETOFIND}/i DEFO		# PROCESSMODE, DEFO to produce DInSAR or TOPO to produce DEM (used only in SinglePair.sh)" ${filename}
done

rm -f  initpol.txt
