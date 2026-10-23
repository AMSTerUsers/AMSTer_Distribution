#!/bin/bash
# Script to check the size of the UNZIP S1 image files; that is the size of dir is at least 6 Gb (must be integer) and contains 57 files & subdir.  
#
# Need to be run in dir where all the UNZIP images data are stored (e.g. /Volumes/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC.UNZIP_FORMER/_2020).
#
# Parameters : - None but nr of files and min size are hard coded .   
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- enable color text at terminal though this is not mandatory. Ony used to write message in red in case of wrong size.  
#
# V1: 2021
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
