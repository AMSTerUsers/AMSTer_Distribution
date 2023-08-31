#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at re-creating the link of S1 images in REGION after reading in csl 
#      format and stored in REGION_MODE where they will be used by the cis automated scripts. 
# The script will do this from S1 images in Asc and Desc specific dir. This script is based on 
# Read_All_Img.sh, which can explain some useless stuffs here and there...
#
#
# Parameters : - path to dir where images in csl format are stored  (in SAR_CSL/../REGION_MODE/NoCrop)  
#              - path to dir where images should be stored as links (in SAR_CSL/../REGION/NoCrop)
#  
# Dependencies:	-
#
# Hard coded:	- 
#
# New in Distro V 1.1:	- Mute error while atemmpting to delete old links 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/02/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 1, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

CSL_MODE=$1				# path to dir where images in csl format are stored  (in SAR_CSL/../REGION_MODE/NoCrop)
CSL=$2					# path to dir where images should be stored as links (in SAR_CSL/../REGION/NoCrop)

SAT=S1					# satellite can only be S1

# vvv ----- Hard coded lines to check --- vvv 
#source /$HOME/.bashrc 
# ^^^ ----- Hard coded lines to check -- ^^^ 

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

CSLEND=`echo -n ${CSL_MODE} | tail -c 7`
if [ "${CSLEND}" != "/NoCrop" ] ; then echo "Check your CSL_MODE dir. It must end with NoCrop instead of ${CSLEND}" ; exit 0 ; fi
CSLEND=`echo -n ${CSL} | tail -c 7`
if [ "${CSLEND}" != "/NoCrop" ] ; then echo "Check your CSL dir. It must end with NoCrop instead of ${CSLEND}" ; exit 0 ; fi

if [ $# -lt 2 ] ; then echo "Usage $0 PATH_TO_REGION_MODE PATH_TO_REGION"; exit; fi

echo ""
# Check required dir:
#####################

# Path where to store data in csl format 
if [ -d "${CSL_MODE}" ] && [ -d "${CSL}" ] 
then
   echo "" 
   echo " OK: a directories exist from/to where I can re-create the links." 
   echo "     Data are stored in ${CSL_MODE}. " 
   echo "	 Links will be in ${CSL}. "
else
   echo " "
   echo " NO expected ${CSL} or ${CSL_MODE} directory."
   echo " I can't work; please check." 
   echo ""
   exit 0 
fi

echo "  // Command line used and parameters:"
echo "  // $(dirname $0)/${PRG} $1 $2 "
echo "  // ${VER}"
echo ""

	
# Let's Go:
###########	
cd ${CSL_MODE}

for FILES in `find ${CSL_MODE} -maxdepth 1 -type d -name "*.csl"  | sed "s%\.\/%%g"`
do 
	FILES=`basename ${FILES}`
	echo "Re-create link ${CSL}/${FILES}"
	rm -r ${CSL}/${FILES} 2>/dev/null
	ln -s ${CSL_MODE}/${FILES} ${CSL}

done 





echo "------------------------------------"
echo "All links re-created; hope it worked"
echo "------------------------------------"

