#!/bin/bash
# Script intends to run a comparison of baseline plots used for different MSBAS
# 
# NOTE: - 
#
# WARNING: 	can only compare table from a single set and both table are supposed to be stored in the same dir
#
# Parameters: - Pathto/Table File 1
#			  - StringCommentforNaming 1 
# 			  - Pathto/Table File 2 
#			  - StringCommentforNaming 2
#			  - PathtoDir where the results will be stored 
# Hardcoded: 
#
# Dependencies:	- gawk, cat, cut, gsed, bc
#				- Find_minmaxforBSplots.py
#				- Find_minmaxBSforBSplots.py
#				- BSplot.sh
#				- List_simil_in_table.sh 
#
# New in Distro V 1.0.1:  - cosmetic
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0.1 MasTer script utilities"
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Feb 7, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc


PAIRSFILE1=$1
strtitle1=$2
PAIRSFILE2=$3
strtitle2=$4
AllPairsListing=$5
RESULTDIR=$6

WORKDIR=`dirname ${PAIRSFILE1}`

# initialise
mkdir -p ${RESULTDIR}
#cp ${WORKDIR}/initBaselines.txt ${RESULTDIR}/initBaselines.txt
#cp ${WORKDIR}/allPairsListing.txt ${RESULTDIR}/allPairsListing.txt


echo "ComputeBaselinesPlotFile for file 1: ${PAIRSFILE1}"
${PATHGNU}/gawk '!/^#/ && NR==FNR { n[$1 $2]=($1 $2); next } !/^#/ && ($1 $2 in n) { print $0 }' ${PAIRSFILE1} ${AllPairsListing} > ${RESULTDIR}/dataBaselinesPlot1.txt
#${PATHGNU}/gawk 'NR==FNR { n[$1 $2]=($1 $2);next } ($1 $2 in n) { print $0 }' ${PAIRSFILE1} ${AllPairsListing} > ${RESULTDIR}/dataBaselinesPlot1.txt

echo "ComputeBaselinesPlotFile for file 2: ${PAIRSFILE2}"			
${PATHGNU}/gawk '!/^#/ && NR==FNR { n[$1 $2]=($1 $2); next } !/^#/ && ($1 $2 in n) { print $0 }' ${PAIRSFILE2} ${AllPairsListing} > ${RESULTDIR}/dataBaselinesPlot2.txt


## FIND Min and Max values
echo " "
echo "Find common Min max values for all plots"
Find_minmaxforBSplots.py ${RESULTDIR}/dataBaselinesPlot1.txt ${RESULTDIR}/dataBaselinesPlot2.txt > ${RESULTDIR}/range_date.txt
Find_minmaxBSforBSplots.py ${RESULTDIR}/dataBaselinesPlot1.txt ${RESULTDIR}/dataBaselinesPlot2.txt > ${RESULTDIR}/range_bs.txt

date_min=`cat ${RESULTDIR}/range_date.txt | cut -d' ' -f1`
date_max=`cat ${RESULTDIR}/range_date.txt | cut -d' ' -f2`

bs_min=`cat ${RESULTDIR}/range_bs.txt | cut -d' ' -f1`
bs_max=`cat ${RESULTDIR}/range_bs.txt | cut -d' ' -f2`

echo "Common time span : ["${date_min} " : " ${date_max}"]"
echo "Common baseline span : ["${bs_min} " : " ${bs_max}"]"

echo " "
echo "Make bsplot for file :${PAIRSFILE1}"
BSplot.sh ${RESULTDIR}  dataBaselinesPlot1.txt  ${strtitle1} File1.gnuplot ${date_min} ${date_max} ${bs_min} ${bs_max}

echo "Make bsplot for file :${PAIRSFILE2}"
BSplot.sh ${RESULTDIR}  dataBaselinesPlot2.txt  ${strtitle2} File2.gnuplot ${date_min} ${date_max} ${bs_min} ${bs_max}

echo "Compute Tables containing common pairs and solo pairs:"			
List_simil_in_table.sh ${PAIRSFILE1} ${PAIRSFILE2} ${RESULTDIR}

echo "Make baseline plot of pairs only in file ${PAIRSFILE1}"
#cd ${RESULTDIR}
${PATHGNU}/gawk '!/^#/ && NR==FNR { n[$1 $2]=($1 $2); next } !/^#/ && ($1 $2 in n) { print $0 }' ${RESULTDIR}/pairs_in_file_1_only.txt ${AllPairsListing} > ${RESULTDIR}/dataBaselinesPlot_file1only.txt
BSplot.sh ${RESULTDIR}  dataBaselinesPlot_file1only.txt  ${strtitle1}"only" PairsinFile1only.gnuplot ${date_min} ${date_max} ${bs_min} ${bs_max}

echo "Make baseline plot of pairs only in file ${PAIRSFILE2}"
${PATHGNU}/gawk '!/^#/ && NR==FNR { n[$1 $2]=($1 $2); next } !/^#/ && ($1 $2 in n) { print $0 }' ${RESULTDIR}/pairs_in_file_2_only.txt ${AllPairsListing} > ${RESULTDIR}/dataBaselinesPlot_file2only.txt
BSplot.sh ${RESULTDIR}  dataBaselinesPlot_file2only.txt ${strtitle2}"only" PairsinFile2only.gnuplot ${date_min} ${date_max} ${bs_min} ${bs_max}

echo "Make Baseline plot showing pairs that are common to both files"
${PATHGNU}/gawk '!/^#/ && NR==FNR { n[$1 $2]=($1 $2); next } !/^#/ && ($1 $2 in n) { print $0 }' ${RESULTDIR}/pairs_in_both_tables.txt ${AllPairsListing}  > ${RESULTDIR}/dataBaselinesPlot_commun.txt
BSplot.sh ${RESULTDIR}  dataBaselinesPlot_commun.txt  "both"${strtitle1}"and"${strtitle2} Pairsincommon.gnuplot ${date_min} ${date_max} ${bs_min} ${bs_max}

echo ""
echo "Some info about your files : "
num1=`${PATHGNU}/gsed -n '/^[^#]/p' ${PAIRSFILE1} | wc -l`
NBPAIRS1=`echo ${num1} | bc`
echo ${NBPAIRS1} " pairs found in File " ${PAIRSFILE1}

num1=`${PATHGNU}/gsed -n '/^[^#]/p' ${PAIRSFILE2} | wc -l`
NBPAIRS2=`echo ${num1} | bc`
echo ${NBPAIRS2} " pairs found in File " ${PAIRSFILE2}

num1=`${PATHGNU}/gsed -n '/^[^#]/p' ${RESULTDIR}/pairs_in_file_1_only.txt | wc -l`
NBPAIRSonly1=`echo ${num1} | bc`
echo ${NBPAIRSonly1} " pairs are only in File " ${PAIRSFILE1}

num1=`${PATHGNU}/gsed -n '/^[^#]/p' ${RESULTDIR}/pairs_in_file_2_only.txt | wc -l`
NBPAIRSonly2=`echo ${num1} | bc`
echo ${NBPAIRSonly2} " pairs are only in File " ${PAIRSFILE2}

num1=`${PATHGNU}/gsed -n '/^[^#]/p' ${RESULTDIR}/pairs_in_both_tables.txt | wc -l`
NBPAIRScom=`echo ${num1} | bc`
echo ${NBPAIRScom} " pairs are both in files "  ${PAIRSFILE1} " and "  ${PAIRSFILE2}

echo ""
echo "End of script Compare_BSplt.sh"