#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at making a table MAS SLV Bp Bt Coh from all the files that are in 
# SAR_MASSPROCESS/../Geocoded/Coh named Baseline_Coh_Table_${KMLNAME}.txt. 
# The Coh in table is the average coherence on a selected zone provided by a kml.
#
#
#  Script must be launched in the SAR_MASSPROCESS/../Geocoded/Coh. 
#
# Parameters are : 
#		- path to kml of zone where to test the coh
#
# Dependencies:	- function getStatForZoneInFile from CIS
#
# New in Distro V 1.0:	- restrict_msbas_to_Coh.sh V1.5
# New in Distro V 1.1: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V 1.2: - replace if -s as -f -s && -f to be compatible with mac os if 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 19, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


KML=$1				# Zone where to test if Coherence threshold is satisfied (path and file name)

KMLNAME=`basename ${KML}`

echo ""

RNDM1=`echo $(( $RANDOM % 10000 ))`
RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
# Dump Command line used in CommandLine.txt
echo "$(dirname $0)/${PRG} run with following arguments : " > CommandLine_${PRG}_${RUNDATE}_${RNDM1}.txt
echo $@ >> CommandLine_${PRG}_${RUNDATE}_${RNDM1}.txt

RUNDIR=$(pwd)

if [ `basename ${RUNDIR}` != "Coh" ] ; then echo " You seems to be in the wrong dir; must be something like SAR_MASSPROCESS/../Geocoded/Coh" ; exit ; fi
if [ $# -lt 1 ] ; then echo “Usage $0 PathToKml ”; exit; fi

# list of files to check - take it from ${MODETOCLEAN}.txt to avoid checking unnecessary files
find . -maxdepth 1 -name "*deg" > List_All_img_${RUNDATE}_${RNDM1}_tmp.txt
# get rid of leading path and tailing infos 
${PATHGNU}/gawk -F'/' '{print $2}' List_All_img_${RUNDATE}_${RNDM1}_tmp.txt > List_All_img_${RUNDATE}_${RNDM1}.txt
rm List_All_img_${RUNDATE}_${RNDM1}_tmp.txt


echo "// prepare table (ignoring already checked ones)"
# do only those that are not checked yet
if [ -f "${RUNDIR}/Baseline_Coh_Table_${KMLNAME}.txt" ] && [ -s "${RUNDIR}/Baseline_Coh_Table_${KMLNAME}.txt" ]
	then 
		# ignore in List_All_img_${RUNDATE}_${RNDM1}.txt all pairs that are already in Baseline_Coh_Table_${KMLNAME}.txt
		# and save it in a new List_All_img_${RUNDATE}_${RNDM1}.txt
		while read MAS SLV BP BT COH
			do	
				${PATHGNU}/gsed -i.trash "/${MAS}_${SLV}/d" List_All_img_${RUNDATE}_${RNDM1}.txt 
		done < ${RUNDIR}/Baseline_Coh_Table_${KMLNAME}.txt
fi
#rm -f List_All_img_${RUNDATE}_${RNDM1}.txt.trash

for IMGTOTEST in `cat List_All_img_${RUNDATE}_${RNDM1}.txt`
do 
	PAIR=`echo "${IMGTOTEST}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" ` # select _date_date_ where date is 8 numbers
	MAS=`echo "${PAIR}" | cut -d _ -f 2 ` 
	SLV=`echo "${PAIR}" | cut -d _ -f 3 `
	BP=`echo "${IMGTOTEST}" | ${PATHGNU}/gawk -F 'Bp' '{print $NF}' | cut -d _ -f1 | cut -d m -f1`  
	BT=`echo "${IMGTOTEST}" | ${PATHGNU}/gawk -F 'BT' '{print $NF}' | cut -d d -f1` 
	COH=`getStatForZoneInFile ${RUNDIR}/${IMGTOTEST} ${KML}` # gives the mean coh in zone 

	echo "${MAS}	${SLV}	${BP}	${BT}	${COH}" >> ${RUNDIR}/Baseline_Coh_Table_${KMLNAME}.txt
done 

# just to be sure...
sort  ${RUNDIR}/Baseline_Coh_Table_${KMLNAME}.txt | uniq > ${RUNDIR}/Baseline_Coh_Table_${KMLNAME}_tmp.txt
mv ${RUNDIR}/Baseline_Coh_Table_${KMLNAME}_tmp.txt ${RUNDIR}/Baseline_Coh_Table_${KMLNAME}.txt

# Remove old cmd line files 
find ${RUNDIR} -maxdepth 1 -name "CommandLine_*.txt" -type f -mtime +15 -exec rm -f {} \;

#clean 
rm -f List_All_img_${RUNDATE}_${RNDM1}.txt

echo "-----------------------------------------------------------------"
echo " Table built - hope it worked"
echo "-----------------------------------------------------------------"


