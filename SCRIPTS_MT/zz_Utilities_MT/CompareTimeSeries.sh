#!/bin/bash
# 
# Compare time series 
#
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
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



# pixel to compare
XLIN=$1
YLIN=$2

# dir where the 2 MSBAS sol are stored
SOL1=/Volumes/hp-D3602-Data_RAID5/MSBAS_testoptim/_VVP_S1_Auto_20m_400days/zz_LOS_Asc_Auto_2_0.04_VVP
SOL2=/Volumes/hp-D3602-Data_RAID5/MSBAS_testoptim/_VVP_S1_Auto_20m_400days/zz_LOS_set1_opt3
# dir where diff will be stored 
DIFF=/Volumes/hp-D3602-Data_RAID5/MSBAS_testoptim/_VVP_S1_Auto_20m_400days

# compute time series for pix for the two sets
cd ${SOL1}
PlotTS.sh ${XLIN} ${YLIN} -f

cd ${SOL2}
PlotTS.sh ${XLIN} ${YLIN} -f

# compute the diff
cd ${DIFF}
Plot_Diff_TS.sh ${SOL1}/timeLine${XLIN}_${YLIN}.txt ${SOL2}/timeLine${XLIN}_${YLIN}.txt
