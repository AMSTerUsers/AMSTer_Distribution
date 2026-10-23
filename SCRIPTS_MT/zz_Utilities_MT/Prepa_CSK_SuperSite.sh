#!/bin/bash
# This script prepares the CSK images downloaded from SuperSite. 
# In the running dir, it will list the images (fom ASI)
#   => for each one, it will : 	extract the date  
#								create a dir at that date 
#
# Parameters: - none
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies: - gnu awk for more compatibility. Check hard coded PATHGNU to gawk
#
# New in Distro V 1.0 (Jul 15, 2019):	- Based on developpement version 2.0 and Beta V1.1 of Prepa_CSK.sh
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


for FILES in `ls -d *-* | ${PATHGNU}/grep -v .txt | ${PATHGNU}/grep -v .sh`
do
	cd ${FILES}
	echo ${FILES} > ${FILES}.txt
		
	echo " Process image ${FILES}"
	#ACCOMPSHEET=`ls ${FILES}/DFAS_*_AccompanyingSheet.xml`
	#IMAGEDATE=`${PATHGNU}/gawk -F'ProductFileName' '{print $2}' ${ACCOMPSHEET}  | cut -d ">" -f2 | cut -d _ -f9 | cut -c 1-8 `
	IMAGEDATE=`ls DFDN*.pdf | cut -d _ -f 10 | cut -c 1-8`
	cd ..	
	mv ${FILES} ${IMAGEDATE}
done

rm temp_zip_files.txt
