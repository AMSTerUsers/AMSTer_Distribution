#!/bin/bash
# This script prepares the CSK images. 
# In the running dir, it will list the tar.gz images (fom ASI)
#   => for each one, it will : 	extract the date from the tar.gz name, 
#								create a dir at that date 
#								unzip the file 
#
# Parameters: - none
#
# Dependencies: - gunzip
#				- gnu awk for more compatibility. Check hard coded PATHGNU to gawk
#
# New in Distro V 1.0 (Jul 15, 2019):	- Based on developpement version 2.0 and Beta V1.1
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

ls *.gz > temp_zip_files.txt

for FILES in `cat -s temp_zip_files.txt`
do
	mkdir TMP
	mv ${FILES} TMP
	cd  TMP
	echo " File ${FILES} will be unzipped"
	gunzip -c ${FILES} | tar xopf -
	echo ${FILES} > ${FILES}.txt
		
	echo " Get the date of image from ${FILES} : "
	IMAGEDATE=`${PATHGNU}/gawk -F'ProductFileName' '{print $2}' DFAS_AccompanyingSheet.xml  | cut -d ">" -f2 | cut -d _ -f9 | cut -c 1-8 `
	echo "                                       ${IMAGEDATE}"
	rm -f ${FILES}
	cd ..	
	mv TMP ${IMAGEDATE}


done

rm temp_zip_files.txt
