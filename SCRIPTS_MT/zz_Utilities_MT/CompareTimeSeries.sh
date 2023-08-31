#!/bin/bash
# 
# Compare time series 
#
#

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
