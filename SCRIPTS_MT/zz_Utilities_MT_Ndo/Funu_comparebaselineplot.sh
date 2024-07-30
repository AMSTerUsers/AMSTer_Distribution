#!/bin/bash
# Script intends to run a comparison of baseline plots built with different criteria
# 
# NOTE: - 
#
# WARNING: 	
#
# Parameters: - none 
#
# Hardcoded: - A lot !
#
# Dependencies:	- 
#
# New in Distro V 1.1:  - arrange path
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 MasTer script utilities"
AUT="Delphine Smittarello, (c)2024 DS, Last modified on Feb 13, 2024 by NdO"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

LAUNCHDIR=`pwd`

# SERVER HP
WORKDIR="${PATH_1660}/SAR_SM/MSBAS/Funu/set1"
RESULTDIR="${PATH_1660}SAR_SM/MSBAS/Funu/BaselinePlots_test_set1_Shortest3_Delaunay30"

# Local Imac 27
#WORKDIR="/Users/delphine/SAR/AMSTerLocalProcessings/RESULTS/SAR_SM/MSBAS/S1/Funu/set1"
#RESULTDIR="/Users/delphine/SAR/AMSTerLocalProcessings/RESULTS/SAR_SM/MSBAS/S1/Funu/BaselinePlots_test_Shortest3_Delaunay30"

# Local Macbook
#WORKDIR="/Users/delphine/SAR/AMSTerLocalProcessings/RESULTS/SAR_SM/MSBAS/S1/Funu/set1"
#RESULTDIR="/Users/delphine/SAR/AMSTerLocalProcessings/RESULTS/SAR_SM/MSBAS/S1/Funu/BaselinePlots_test"

# TableFile 1
strtitle1="Shortest3"
PAIRSFILE1=${WORKDIR}/table_0_0_MaxShortest_3.txt

# TableFile 2
strtitle2="Delaunay30"
PAIRSFILE2=${WORKDIR}/table_0_0_DelaunayRatio30.0_0.txt

# TableFile 3
MaxBp1=50
MaxBt1=30
strtitle3="BpMax="${MaxBp1}"BtMax="${MaxBt1}
PAIRSFILE3=${WORKDIR}/table_0_${MaxBp1}_0_${MaxBt1}.txt


Compare_BSplot.sh ${PAIRSFILE1} ${strtitle1} ${PAIRSFILE2} ${strtitle2} ${RESULTDIR}

RESULTDIR="${PATH_1660}/SAR_SM/MSBAS/Funu/BaselinePlots_test_set1_Shortest3_BP50_BT30"
Compare_BSplot.sh ${PAIRSFILE1} ${strtitle1} ${PAIRSFILE3} ${strtitle3} ${RESULTDIR}

RESULTDIR="${PATH_1660}/SAR_SM/MSBAS/Funu/BaselinePlots_test_set1_Delaunay30_BP50_BT30"
Compare_BSplot.sh ${PAIRSFILE2} ${strtitle2} ${PAIRSFILE3} ${strtitle3} ${RESULTDIR}
#ls -lt

#cd $LAUNCHDIR

# All done...

