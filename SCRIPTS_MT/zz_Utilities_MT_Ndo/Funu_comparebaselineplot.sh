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
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- 
#
# New in Distro V 1.1:  - arrange path
# New in Distro V 1.2 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
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

