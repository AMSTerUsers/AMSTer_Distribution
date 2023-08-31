#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at extracting from a graph = MSBAS table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/table_0_50_0_400.txt)
#   the list of all the triangles. 
#
# Parameters : - path to MSBAS table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/table_0_50_0_400.txt)
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

MSBASTABLE=$1			# path to MSBAS table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/table_0_50_0_400.txt)

PATHTABLEDIR=$(dirname "${MSBASTABLE}")
NAMETABLE=$(basename "${MSBASTABLE}")

cd ${PATHTABLEDIR}
mkdir -p _Triangles
cd _Triangles

# sort on master, then slave, then Bt then Bp
sort -n -k1,1 -k2,2 -k4,4 -k 3,3 ${MSBASTABLE} > ${NAMETABLE}_Sort_1_2_4_3.tmp.txt

# get rid of 2 line header 
tail -n +3 ${NAMETABLE}_Sort_1_2_4_3.tmp.txt > ${NAMETABLE}_Sort_1_2_4_3.txt 
rm -f ${NAMETABLE}_Sort_1_2_4_3.tmp.txt List_No_Triangels.txt List_Triangels.txt


# get number of pairs (edges)
N=`cat ${NAMETABLE}_Sort_1_2_4_3.txt | wc -l `
M=`echo "$N - 1" | bc -l`

# brute force triangle with loop. Gain some time to braek when mas 2 > mas1. Still slow. May prefer using python
for i in $(seq 1 ${M})
	do 
		mas1=`${PATHGNU}/gawk 'NR=='${i}' {print $1}' ${NAMETABLE}_Sort_1_2_4_3.txt`
		slv1=`${PATHGNU}/gawk 'NR=='${i}' {print $2}' ${NAMETABLE}_Sort_1_2_4_3.txt`
		k=`echo "${i} + 1" | bc -l`
		for j in  $(seq ${k} ${N})
			do
				mas2=`${PATHGNU}/gawk 'NR=='${j}' {print $1}' ${NAMETABLE}_Sort_1_2_4_3.txt`
				slv2=`${PATHGNU}/gawk 'NR=='${j}' {print $2}' ${NAMETABLE}_Sort_1_2_4_3.txt`
				if [ ${mas1} == ${mas2} ] 
					then 
						tri=`grep ${slv1}  ${NAMETABLE}_Sort_1_2_4_3.txt | ${PATHGNU}/grep ${slv2} | wc -l`
						if [ ${tri} -eq 1 ]
							then
								echo "Triangle : ${mas1}_${slv1} : ${mas2}_${slv2} : ${slv1}_${slv2} " >> List_Triangels.txt
						fi
					else 
						tst1=`grep ${mas1}  ${NAMETABLE}_Sort_1_2_4_3.txt | wc -l`
						tst2=`grep ${slv1}  ${NAMETABLE}_Sort_1_2_4_3.txt | wc -l`
						if [ ${tst1} -eq 1 ] || [ ${tst2} -eq 1 ]  # master or slave of that pair used nowhere, hence no triangle possible 
							then 
								echo "No Triangle : ${mas1}_${slv1} " >> List_No_Triangels.txt
								break 1
							else 
								echo "${mas2} > ${mas1}: exit ${mas1}"
								break 1
						fi
				fi
		done
done

echo "------------------------------------"
echo "All triangle listed"
echo "------------------------------------"

