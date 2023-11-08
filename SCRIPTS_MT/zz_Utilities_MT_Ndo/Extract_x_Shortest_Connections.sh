#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at extracting from allPairsListing.txt
#   x (positive integer) shortest connections between all the pairs and plot the baseline plot. 
# It creates :
#		- a file named table_0_0_MaxShortest_x.txt that contains all the list of pairs for the mass processing,
#		- a file named allPairsListing_Max${MAX}.txt that contains all the list of pairs for plotting with baselinePlot
#		- a figure named baselinePlot_table_max_x.txt.png with the baseline plot
#
#
# Parameters : 	- path to allPairsListing.txt table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/allPairsListing.txt)
#				- max number of connection (e.g. 3)
#
#
# Dependencies:	- gnu grep and awk for more compatibility
#
# Hard coded:	- 
#
# V 1.0 (Sept 18, 2020)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

MSBASTABLE=$1			# path to MSBAS table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/allPairsListing.txt)
MAX=$2					# max number of connection (e.g. 3)


PATHTABLEDIR=$(dirname "${MSBASTABLE}")


cd ${PATHTABLEDIR}

tail -n +8  ${MSBASTABLE} > allPairsListing_NoHeader.txt
head -7 ${MSBASTABLE} > Header_tmp.txt

# Just in case.... sort on master, then slave, then Bt then Bp
sort -n -k1,1 -k2,2 -k9,9 -k8,8  allPairsListing_NoHeader.txt > allPairsListing_Sort_1_2_9_8.txt

rm -f ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt
for IMG in `${PATHGNU}/gawk '{print $1}' allPairsListing_NoHeader.txt | sort | uniq`
do 
	${PATHGNU}/grep ^"    ${IMG}" -m ${MAX} allPairsListing_Sort_1_2_9_8.txt >> ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt
done 

rm -f allPairsListing_Sort_1_2_9_8.txt

echo "  Master	   Slave	 Bperp	 Delay" > ${PATHTABLEDIR}/table_max_${MAX}_ForPlot.txt
echo " " >> ${PATHTABLEDIR}/table_max_${MAX}_ForPlot.txt

# new tool requires file with Dummy Bp Mas Slv for plotting
${PATHGNU}/gawk '{print "Dummy \t" $8 "\t" $1 "\t" $2}' ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt > ${PATHTABLEDIR}/table_max_${MAX}_ForPlot.txt

# creates table file with all pairs selected for mass processing 
echo "   Master	   Slave	 Bperp	 Delay" > ${PATHTABLEDIR}/table_0_0_MaxShortest_${MAX}.txt
echo "" >> ${PATHTABLEDIR}/table_0_0_MaxShortest_${MAX}.txt
${PATHGNU}/gawk '{print $1 "\t" $2 "\t" $8 "\t\t" $9}' ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt >> ${PATHTABLEDIR}/table_0_0_MaxShortest_${MAX}.txt

# add headers
cat Header_tmp.txt ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt > ${PATHTABLEDIR}/allPairsListing_Max${MAX}.txt 
rm -f ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt

# make the plot
baselinePlot -r ${PATHTABLEDIR} ${PATHTABLEDIR}/table_max_${MAX}_ForPlot.txt

rm -f allPairsListing_NoHeader.txt Header_tmp.txt

echo "------------------------------------"
echo "All img taken ${MAX} times "
echo "------------------------------------"

