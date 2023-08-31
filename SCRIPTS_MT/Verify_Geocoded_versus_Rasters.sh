#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at verifying that the results from the mass processing are successfully 
#     stored the same way as Geocoded and GeocodedRasters. 
# It will output a series of text files with the list of images that are not in both type of dir.
#  
# Parameters : - dir where Geocoded results are stored 
#                (eg. /.../SAR_MASSPROCESS/SAT/TRACK/CROP_SM_DATE_ZOOM_ML/Geocoded)
#
# Dependencies:
#    - gnu sed and awk for more compatibility. 
#
# New in Distro V 1.0:	- Based on developpement version and Beta V10
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2015/08/24 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 15, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


MASSPROCESSGEOCPATH=$1		# dir where Geocoded results are stored (eg. /.../SAR_MASSPROCESS/SAT/TRACK/CROP_SM_DATE_ZOOM_ML/Geocoded)

MASSPROCESSPATH=`echo ${MASSPROCESSGEOCPATH} | ${PATHGNU}/gsed "s%\/Geocoded%%" `

mkdir -p ${MASSPROCESSPATH}/_CheckGeoc_vs_Ras
cd ${MASSPROCESSPATH}/_CheckGeoc_vs_Ras

# some stuff for later
ls ${MASSPROCESSGEOCPATH}/Geocoded > MODES.TXT # List all modes 
NROFALLMODE=`wc -l < MODES.TXT`

if [ $# -lt 1 ] ; then echo “Usage $0 DIR_TO_GEOCODED”; exit; fi

for MODE in `cat -s MODES.TXT`
do   
	echo "List ${MODE} Geocoded"
	cd ${MASSPROCESSGEOCPATH}/Geocoded/${MODE}
	ls *deg > ${MASSPROCESSPATH}/_CheckGeoc_vs_Ras/${MODE}_In_Geoc_tmp.txt
	echo "List ${MODE} GeocodedRasters"
	cd ${MASSPROCESSGEOCPATH}/GeocodedRasters/${MODE}
	ls *.ras > ${MASSPROCESSPATH}/_CheckGeoc_vs_Ras/${MODE}_In_GeocRas_tmp.txt	
done 

cd ${MASSPROCESSPATH}/_CheckGeoc_vs_Ras

# Remove .ras for comparison
for MODE in `cat -s MODES.TXT`
do   
	for LINE in `cat -s ${MASSPROCESSPATH}/_CheckGeoc_vs_Ras/${MODE}_In_GeocRas_tmp.txt`
		do 
			LINE=${LINE%".ras"} 
			echo ${LINE} >> ${MODE}_In_GeocRas_tmp2.txt
	done
	echo "Sort ${MODE} GeocodedRasters"
	sort ${MODE}_In_GeocRas_tmp2.txt > ${MODE}_In_GeocRas.txt
	rm -f ${MODE}_In_GeocRas_tmp.txt ${MODE}_In_GeocRas_tmp2.txt
	echo "Sort ${MODE} Geocoded"
	sort ${MODE}_In_Geoc_tmp.txt > ${MODE}_In_Geoc.txt
	rm -f ${MODE}_In_Geoc_tmp.txt
	echo "Check difference in ${MODE} Geocoded versus GeocodedRasters"
	diff ${MODE}_In_GeocRas.txt ${MODE}_In_Geoc.txt > ${MODE}_diff.txt
	
	rm ${MODE}_In_GeocRas.txt ${MODE}_In_Geoc.txt
done 
echo "Clean files..."
find . -size 0 -delete
rm ${MASSPROCESSPATH}/_CheckGeoc_vs_Ras/MODES.TXT
