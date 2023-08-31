#!/bin/bash
######################################################################################
# This script comapres the dates of pairs in each Geocoded and GeocodedRasters directories.
# It does not look in the Ampli dir.  
#
# Must be launched in SAR_MASSPROCESS where /Geocoded and /GeocodedRasters. 
#
# New in Distro V 1.1: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 21, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

rm -f MODES.TXT 
# Check available modes but Ampli
ls Geocoded | ${PATHGNU}/grep -v Ampli > MODES.TXT # List all modes 

for MODE in `cat MODES.TXT` ;  do
  echo "****** Check Geocoded/${MODE}"
	cd Geocoded/${MODE}
	find . -maxdepth 1 -name "*deg" -type f > FilesToCheck.txt
	
	# cut around pair date, sort and uniq then search in FilesToCheck.txt the possible reminaing pairs
	for lines in `cat FilesToCheck.txt` ; do
		echo "${lines}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" >> DatesDeg.txt
	done

	if [ -f DatesDeg.txt ] ; then sort DatesDeg.txt > ../__DatesDeg_${MODE}.txt ; fi
	rm -f FilesToCheck.txt DatesDeg.txt
	
	cd ../..	
	
	echo "****** Check GeocodedRasters/${MODE}"
	cd GeocodedRasters/${MODE}
	find . -maxdepth 1 -name "*.ras" -type f > FilesToCheck.txt
	
	# cut around pair date, sort and uniq then search in FilesToCheck.txt the possible reminaing pairs
	for lines in `cat FilesToCheck.txt` ; do
		echo "${lines}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" >> DatesDeg.txt
	done

	if [ -f DatesDeg.txt ] ; then sort DatesDeg.txt > ../__DatesDeg_${MODE}_ras.txt ; fi
	rm -f FilesToCheck.txt DatesDeg.txt
	
	cd ../..	
	
done

rm MODES.TXT

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

