#!/bin/bash
######################################################################################
# This script lists the size in lines and columns as well as in bytes of all S1 SLC in NoCrop dir
#   and save them into a table .
#
# Parameter: - none
#
# Must be launched in the NoCrop dir
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in V D 1.0.1: - bash for Linux compatibility 
# New in Distro V 1.1: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.2 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
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

