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
# New in Distro V 1.0:	- Based on developpement version 2.0 and Beta V1.1
#
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2015/08/24 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2015-2019, Last modified on Jul 15, 2019"
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
