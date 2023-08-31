#!/bin/bash
######################################################################################
# This script lists the size in lines and columns as well as in bytes of all S1 SLC in NoCrop dir
#   and save them into a table .
#
# Parameter: - none
#
# Must be launched in the NoCrop dir
#
# New in V D 1.0.1: - bash for Linux compatibility 
# New in Distro V 1.1: - replace if -s as -f -s && -f to be compatible with mac os if 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# N.d'Oreye, v 1.0 2019/04/25 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.1 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2019, Last modified on Jul 19, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

SOURCEDIR=$PWD

echo "MasterDate	Columns	Lines	Expectedsize	Size 		Diff(bytes)" > ${SOURCEDIR}/List_Master_Sizes.txt
echo "-------------------------------------------------------------------------" >> ${SOURCEDIR}/List_Master_Sizes.txt

for MASDIR in `ls -d *.csl`
do 
	MAS=`echo "${MASDIR}" | cut -d S -f 2 | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select _date_date_ where date is 8 numbers
	# get MASTER info from SAR_CSL
	MASCOL=`grep "Range dimension" ${SOURCEDIR}/${MASDIR}/Info/SLCImageInfo.txt | ${PATHGNU}/grep -Eo "[0-9]*"`
	MASLIN=`grep "Azimuth dimension" ${SOURCEDIR}/${MASDIR}/Info/SLCImageInfo.txt | ${PATHGNU}/grep -Eo "[0-9]*"`
	MASBYTES=`echo "(${MASCOL} * ${MASLIN} * 8) " | bc` 
	if [ -f ${SOURCEDIR}/${MASDIR}/Data/SLCData.* ] && [ -s ${SOURCEDIR}/${MASDIR}/Data/SLCData.* ] ## BEWARE, it only works when only one file is there
		then 
			MASSLC=`ls ${SOURCEDIR}/${MASDIR}/Data/SLCData.*`
			MASSIZE=`wc -c < ${MASSLC}`

			MASDIFF=`echo "(${MASBYTES} - ${MASSIZE}) " | bc` 

			#echo "  // Master (${MAS}) is	${MASSIZE} bytes and ${MASCOL} x ${MASLIN}, which (x8) is supposed to be ${MASBYTES} bytes => diff is ${MASDIFF}	bytes"
			echo "${MAS}	${MASCOL}	${MASLIN}	${MASBYTES}	${MASSIZE}		${MASDIFF}" >> ${SOURCEDIR}/List_Master_Sizes.txt
	fi

done

