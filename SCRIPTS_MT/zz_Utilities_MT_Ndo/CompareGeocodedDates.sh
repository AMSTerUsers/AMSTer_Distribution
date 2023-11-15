#!/bin/bash
######################################################################################
# This script comapres the dates of pairs in each Geocoded and GeocodedRasters directories.
# It does not look in the Ampli dir.  
#
# Must be launched in SAR_MASSPROCESS where /Geocoded and /GeocodedRasters. 
#
# New in Distro V 1.1 (Sept 21, 2022): - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
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

