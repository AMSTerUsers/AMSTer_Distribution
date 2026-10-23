#!/bin/bash
######################################################################################
# This script aims at checking the name and the size of the slantRangeDEM in each image 
# directory e.g. SAR_CSL/Sat/Region/NoCrop/imgage.csl directories. It also displays the 
# version of AMSTer used to create the slnatRangeDEM
#
# Image name, DEM used and slantRangeDEM size are listed in a file named ___Check_DEMs.txt
# 
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- grep
#
# The script must be launched in the dir containing the images
# 
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


#find . -type f -name externalSlantRangeDEM.txt -exec sh -c 'echo "File: {}"; grep "Georeferenced DEM file path" {} && echo "Size: $(stat -c %s "$(dirname {})/../Data/externalSlantRangeDEM") bytes"' \; > ___Check_DEMs_tmp.txt
#find . -type f -name externalSlantRangeDEM.txt -exec sh -c 'echo "File: {}"; grep "Georeferenced DEM file path" {} && echo "Size: $(stat -c %s "$(dirname {})/../Data/externalSlantRangeDEM") bytes" && if [ -f $(dirname {})/../Projecting_DEM_w_MasTerEngine_V.txt ] ; then echo "		Read with AMSTer version:" && grep "version" $(dirname {})/../Projecting_DEM_w_MasTerEngine_V.txt | ${PATHGNU}/grep -Eo "[0-9]{8}" ; else echo "		No version available\n" ; fi' \; > ___Check_DEMs_tmp.txt
find . -type f -name externalSlantRangeDEM.txt -exec sh -c 'echo "File: {}"; grep "Georeferenced DEM file path" {} && echo "Size: $(stat -c %s "$(dirname {})/../Data/externalSlantRangeDEM") bytes" && if [ "$(grep "version" $(dirname {})/../Projecting_DEM_w_MasTerEngine_V.txt 2>/dev/null | ${PATHGNU}/grep -Eo "[0-9]{8}")" != "" ] ; then echo "		Read with AMSTer version:" && grep "version" $(dirname {})/../Projecting_DEM_w_MasTerEngine_V.txt | ${PATHGNU}/grep -Eo "[0-9]{8}" ; else echo "		No version available\n" ; fi ' \; > ___Check_DEMs_tmp.txt


${PATHGNU}/gsed -i 's%File: \.\/%%g' ___Check_DEMs_tmp.txt								# clean leading File: ./
${PATHGNU}/gsed -i 's%\/Info\/externalSlantRangeDEM.txt% %g' ___Check_DEMs_tmp.txt		# put file name on same line 
${PATHGNU}/gsed -i 's%\/\* Georeferenced DEM file path \*\/% %g' ___Check_DEMs_tmp.txt	# put size on same line 

awk 'ORS=NR%5?" ":"\n"' ___Check_DEMs_tmp.txt > ___Check_DEMs.txt						# group lines by 5
rm -f ___Check_DEMs_tmp.txt

