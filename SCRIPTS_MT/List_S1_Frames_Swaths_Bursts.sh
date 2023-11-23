#!/bin/bash
# List S1 Frame/Swath/burst from all image in SAR_CSL. 
#
# Hardcoded: - (Suppose that polarisation is VV) - removed since V 1.1
#
# Mustbe launched in dir S1data.csl. 
#
# New in Distro V 1.0:	- Based on developpement version Beta V1.0.2 
# New in Distro V 1.1:	- Read pol from stitched image instead of hardcoded param
#						- output also the pol in file name 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20231121:	- Search img bursts numbers for old and new DataReaders
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Nov 21, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

#INITPOL=VV

SOURCEDIR=$PWD	# e.g. /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/DRC_VVP_A_174/NoCrop
cd ..
LOGDIR=$PWD
mkdir -p ${LOGDIR}/BurstsLists.txt
cd ${SOURCEDIR}

for MASDIR in `ls -d *.csl`  #  e.g. S1A_174_20150214_A.csl
do 
	cd  ${SOURCEDIR}/${MASDIR}/Data

	MAS=`echo "${MASDIR}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_..csl" | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select _date_date_ where date is 8 numbers

	INITPOL=`ls SLCData.?? | cut -d. -f 2`

	echo "Fr Sw busts in img ${MAS}" > ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt
	echo "---------------------------" >> ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt
	i=0
	#for FRAMESWATHBURSTMODES in `find ./*/* -name "*.${INITPOL}"`	# compatible with only old DataReaders (e.g. V20230420) that is when dir contains e.g. SWx.bx.VV files 
	for FRAMESWATHBURSTMODES in `find ./*/* -name "SW*.*"`	# compatible with new & old DataReaders that is when dir contains either e.g. SWx.bx.VV files or SWx.bx.csl dir
		do 
			i=`echo "$i+1" | bc`
			FRAME=`echo "${FRAMESWATHBURSTMODES}" | cut -d. -f2 | cut -d / -f2`   	# eg Frame0
			NFRAME=`echo "${FRAME}" | ${PATHGNU}/grep -Eo "[0-9]*"`					# eg 0


			FRAMESWATHBURSTMODESEXT="${FRAMESWATHBURSTMODES##*.}"
			if [[ "${FRAMESWATHBURSTMODESEXT}" == "csl" ]]
				then
					# if extension is is csl then name contains no dots (new reader)
					SWATH=`echo "${FRAMESWATHBURSTMODES}" | cut -d . -f3  | cut -d / -f3  | cut -d b -f1`   # eg SW1
					NSWATH=`echo "${SWATH}" | ${PATHGNU}/grep -Eo "[0-9]*"`							# eg 1
					NBURST=`echo "${FRAMESWATHBURSTMODES}" | cut -d . -f3  | cut -d / -f3  | cut -d b -f2`   # eg 0
				else
					# if extension is INITPOL then name contains dots (old reader)
					SWATH=`echo "${FRAMESWATHBURSTMODES}" | cut -d . -f3  | cut -d / -f3`   # eg SW1
					NSWATH=`echo "${SWATH}" | ${PATHGNU}/grep -Eo "[0-9]*"`							# eg 1
					BURST=`echo "${FRAMESWATHBURSTMODES}" | cut -d . -f4`   				# eg b0
					NBURST=`echo "${BURST}" | ${PATHGNU}/grep -Eo "[0-9]*"`							# eg 0
			fi
			EXISTING=`grep "${NFRAME}  ${NSWATH}  " ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt`
			if [ -z "${EXISTING}" ] 
				then 
					# No line exits with that frame and burst => add new line
					echo "${NFRAME}  ${NSWATH}  ${NBURST}"  >> ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt
				else 
					# a line exits with that frame and burst => add burst with comma
					${PATHGNU}/gsed -i "s%${EXISTING}%${EXISTING},${NBURST}%" ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt
			fi
	done
	echo "---------------------------" >> ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt
	echo "Total: $i  bursts" >> ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt
	echo "---------------------------" >> ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt
	mv -f ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${INITPOL}.txt ${LOGDIR}/BurstsLists.txt/FramesSwathBurst_Table_${MAS}_${i}_bursts_${INITPOL}.txt
done
