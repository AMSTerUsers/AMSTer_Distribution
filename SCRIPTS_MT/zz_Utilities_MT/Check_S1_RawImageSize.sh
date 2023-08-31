#!/bin/bash
# Script to check the size of the UNZIP S1 image files; that is the size of dir is at least 6 Gb (must be integer) and contains 57 files & subdir.  
#
# Need to be run in dir where all the UNZIP images data are stored (e.g. /Volumes/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC.UNZIP_FORMER/_2020).
#
# Parameters : - None but nr of files and min size are hard coded .   
#
# Dependencies:	- enable color text at terminal though this is not mandatory. Ony used to write message in red in case of wrong size.  
#
# New in V1.1 :	- 
#
# CSL InSAR Suite utilities. 
# NdO (c) 2016/02/29 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0 CIS script utilities"
AUT="Nicolas d'Oreye, (c)2016-2021, Last modified on Sept 21, 2021"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

EXPECTEDSIZE="6"  		# Integer (in Gb)
EXPECTEDNROFFILES="57" 	# counted with ls -R | wc -l; i.e. count  files and sub dirs

SOURCEDIR=$PWD

echo "Size	Dir                                                                    Nr_of_files" >  _ImageSizeWrong.txt
echo "__________________________________________________________________________________________" >>  _ImageSizeWrong.txt
cp -f _ImageSizeWrong.txt _ImageSizeOK.txt

for S1DIR in `ls -d *.SAFE`
do 
	SIZEANDNAME=`du -sh ${S1DIR}`
	SIZE=`echo ${SIZEANDNAME} | cut -d G -f1 | cut -d . -f1`
	NROFFILES=`ls -R ${S1DIR} | wc -l`
		
	if [ ${NROFFILES} != ${EXPECTEDNROFFILES} ] ; then 
		echo -e "$(tput setaf 1)$(tput setab 7)Abnormal: ${SIZEANDNAME}	${NROFFILES} files$(tput sgr 0)"
		echo "${SIZEANDNAME}	${NROFFILES}" >>   _ImageSizeWrong.txt
	elif [ ${SIZE} -le ${EXPECTEDSIZE} ] ; then 
		echo -e "$(tput setaf 1)$(tput setab 7)Abnormal: ${SIZEANDNAME}	${NROFFILES} files$(tput sgr 0)"
		echo "${SIZEANDNAME}	${NROFFILES}" >>   _ImageSizeWrong.txt
	else 
		echo "OK: ${SIZEANDNAME}	${NROFFILES} files"
		echo "${SIZEANDNAME}	${NROFFILES}" >>   _ImageSizeOK.txt
	fi
done