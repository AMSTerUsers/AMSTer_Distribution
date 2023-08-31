#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at extracting frolm a MSBAS table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/table_0_50_0_400.txt)
#   the pairs such as each image is used MAXIMUM 3 times as master and slave
#
#
# Parameters : - path to dir with the CSL images are stored (e.g. /Volumes/hp-1650-Data_Share1/SAR_CSL/sat/NoCrop)   
#              - path to MSBAS table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/table_0_50_0_400.txt)
#
#
# Dependencies:	- gnu sed and awk for more compatibility
#
# Hard coded:	- 
#
# New in Distro V 1.0:	- 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/02/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jan 13, 2020"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

CSL=$1					# path to dir where images in csl format are stored (usually must end with /NoCrop; e.g. /Volumes/hp-1650-Data_Share1/SAR_CSL/sat/NoCrop)   
MSBASTABLE=$2			# path to MSBAS table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/table_0_50_0_400.txt)

PATHTABLEDIR=$(dirname "${MSBASTABLE}")
NAMETABLE=$(basename "${MSBASTABLE}")

cd ${PATHTABLEDIR}
mkdir -p _Check_Stat_Mas_Slv_Max3
cd _Check_Stat_Mas_Slv_Max3

rm -f ${NAMETABLE}_Sort_1_2_4_3_Max3.txt

# sort on master, then slave, then Bt then Bp
sort -n -k1,1 -k2,2 -k4,4 -k 3,3 ${MSBASTABLE} > ${NAMETABLE}_Sort_1_2_4_3.txt

# Check if S1
if [ `echo ${CSL} | ${PATHGNU}/grep "SAR_CSL/S1/" | wc -l` -eq 1 ] ; then TESTS1=YES ; else TESTS1=NO ; fi 

for IMG in `ls -A ${CSL} | ${PATHGNU}/grep -v ".txt" | ${PATHGNU}/grep -v ".DS_Store"`
do 
	# if S1 imges are in the form of S1A_174_20141017_A.csl, else 20120303.csl
	if [ ${TESTS1} == "YES" ] 
		then 
			DATEIMG=`echo ${IMG} | cut -d _ -f 3`
		else 
			DATEIMG=`echo ${IMG} | cut -d . -f 1`
	fi 
	grep ^${DATEIMG} -m 3 ${NAMETABLE}_Sort_1_2_4_3.txt >>  ${NAMETABLE}_Sort_1_2_4_3_Max3.txt
done 

for IMG in `ls -A ${CSL} | ${PATHGNU}/grep -v ".txt" | ${PATHGNU}/grep -v ".DS_Store"`
do 
	# if S1 imges are in the form of S1A_174_20141017_A.csl, else 20120303.csl
	if [ ${TESTS1} == "YES" ] 
		then 
			DATEIMG=`echo ${IMG} | cut -d _ -f 3`
		else 
			DATEIMG=`echo ${IMG} | cut -d . -f 1`
	fi 
	NMAS=`${PATHGNU}/gawk '{count[$1]++} END {print count ["'"${DATEIMG}"'"]}' ${NAMETABLE}_Sort_1_2_4_3_Max3.txt`
	NSLV=`${PATHGNU}/gawk '{count[$2]++} END {print count ["'"${DATEIMG}"'"]}' ${NAMETABLE}_Sort_1_2_4_3_Max3.txt` 
	cat ${NAMETABLE}_Sort_1_2_4_3_Max3.txt | ${PATHGNU}/grep ${DATEIMG} > Stat_img_${DATEIMG}_Mas${NMAS}_Slv${NSLV}.txt
	echo "${DATEIMG} used as master: ${NMAS}	and Slv: ${NSLV}"
done



echo "------------------------------------"
echo "All img stat revised"
echo "------------------------------------"

