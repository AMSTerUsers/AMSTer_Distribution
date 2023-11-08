#!/bin/bash
######################################################################################
# This script check the size in lines and columns of all S1 SLC in NoCrop dir
#   and compare them with their respective file size in bytes. If not good, re-read it.
#
# Parameter: - INITPOL: polarisation to stitch (eg VV or HH). If not INITPOL provided, it will stitch all modes
#
# Must be launched in the NoCrop dir
#
# New in V D 1.0.1: - bash for Linux compatibility 
#		 V D 1.0.2:	- Use S1DateReader with new option -p to prevent reading S1 images without restituted or precise orbits. This is recommended since March 2021 when S1 images started to be distributed with orginal orbits of poor quality.  
#		 V D 1.1.0:	- Set S1DateReader option -p after path to image 
# New in V D 1.2.0: - replace if -s as -f -s && -f to be compatible with mac os if 
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

INITPOL=$1

SOURCEDIR=$PWD

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

			echo "Primary (${MAS}) is	${MASSIZE} bytes and ${MASCOL} x ${MASLIN}, which (x8) is supposed to be ${MASBYTES} bytes => diff is ${MASDIFF}	bytes"
			if [ ${MASDIFF} -ge 1 ]
				then 
					echo "Not expected size => re-read it"
					S1DataReader ${SOURCEDIR}/${MASDIR} P=${INITPOL} -p	# Do not use option -t here because it deletes the separate bursts after stitching but we need them for coreg
			fi			
		else
			echo "Primary (${MAS}) not read yet ; read it now "
			S1DataReader ${SOURCEDIR}/${MASDIR} P=${INITPOL} -p	# Do not use option -t here because it deletes the separate bursts after stitching but we need them for coreg
		
	fi

done

