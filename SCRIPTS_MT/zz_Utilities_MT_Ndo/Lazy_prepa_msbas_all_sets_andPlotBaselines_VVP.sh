#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at preparing the MSBAS data sets for each set of a given region
#   then plotting a baseline plot with all sets in the same plot Region is here VVP.
# 
# It is quick when one must replay things but also usefull as it  keeps track of which set is which sat/mode
#
# Parameters : - Max Bp and Bt
# 
# Dependencies:	- Prepa_MSBAS.sh
#				- Some hard coded info :
#					+ GlobalPrimary (SuperMaster) date of each data set
#					+ Min Bp and Bt for all data sets
#				- plot_Multi_span.sh
# 				- color table (depends on the nr of sets); eg: 
#						+ for 2 sets : ColorTable_AD.txt
#						+ for 4 sets : ColorTable_ADDA.txt
#						+ for 6 sets : ColorTable_DADDAD.txt
#   			  Color range depends on Asc or Desc (see alternance in naming)
#				- SetList_xxx.txt taht is the list of modes wanted for the plot
#
# New in V1.0 beta: - Based on developpement version
#                   - cosmetic cleaning and commenting for distribution purpose. 
# New in Distro V 1.1 20230626:	- Color tables are now in TemplatesForPlots
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

MAXBP=$1
MAXBT=$2

# vvv ----- Hard coded lines to check --- vvv 
SM1=20120514
SM2=20120702
SM3=20100328
SM4=20121223
SM5=20151201
SM6=20120803

BPMIN=0				# Min Bperp set 1 and 2
BTMIN=0				# Min Btemp set 1 and 2
# ^^^ ----- Hard coded lines to check -- ^^^ 

if [ $# -lt 2 ] ; then echo “Usage $0 MaxBp MaxBt”; exit; fi

PDir="$(pwd)"

# CSK DESC
cd /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set1
/Users/doris/PROCESS/SCRIPTS_MT/Prepa_MSBAS.sh /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set1 ${MAXBP} ${MAXBT} ${BPMIN} ${BTMIN} ${SM1}

# CSK ASC
cd /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set2
/Users/doris/PROCESS/SCRIPTS_MT/Prepa_MSBAS.sh /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set2 ${MAXBP} ${MAXBT} ${BPMIN} ${BTMIN} ${SM2}

# RS F2F
cd /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set3
/Users/doris/PROCESS/SCRIPTS_MT/Prepa_MSBAS.sh /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set3 ${MAXBP} ${MAXBT} ${BPMIN} ${BTMIN} ${SM3}

# RS F21N
cd /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set4
/Users/doris/PROCESS/SCRIPTS_MT/Prepa_MSBAS.sh /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set4 ${MAXBP} ${MAXBT} ${BPMIN} ${BTMIN} ${SM4}

# RS UH
cd /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set5
/Users/doris/PROCESS/SCRIPTS_MT/Prepa_MSBAS.sh /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set5 ${MAXBP} ${MAXBT} ${BPMIN} ${BTMIN} ${SM5}

# TSX SM D92
cd /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set7
/Users/doris/PROCESS/SCRIPTS_MT/Prepa_MSBAS.sh /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set7 ${MAXBP} ${MAXBT} ${BPMIN} ${BTMIN} ${SM6}

cd "${PDir}"
/Users/doris/PROCESS/SCRIPTS_MT/plot_Multi_span.sh /Users/doris/PROCESS/SCRIPTS_MT/SetList_123457.sh  ${BPMIN} ${MAXBP} ${BTMIN} ${MAXBT}  /Users/doris/PROCESS/SCRIPTS_MT/TemplatesForPlots/ColorTable_DADDAD.txt
# Without set 1 and 6
#/Users/doris/PROCESS/SCRIPTS_MT/plot_Multi_span.sh /Users/doris/PROCESS/SCRIPTS_MT/SetList_1345.sh  ${BPMIN} ${MAXBP} ${BTMIN} ${MAXBT}  /Users/doris/PROCESS/SCRIPTS_MT/TemplatesForPlots/ColorTable_ADDA.txt
