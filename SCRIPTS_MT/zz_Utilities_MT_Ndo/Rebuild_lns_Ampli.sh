#!/bin/bash
# This script aims at rebuilding links to amplitude files in all pairs directories
#     in current directory (usually SAR_SM/AMPLITUDES/SAT/TRK/REGION/)
# after the original file were moved to _AMPLI.
# It also remove possible wrong .ras and .sh links resulting from usage of wrong Cp_Ampli.sh V2.0 
#
# Parameters are:
#		- Path to _AMPLI dir
#
# Dependencies:	- readlink
#
# New in V1.1 :	- 
# CSL InSAR Suite utilities. 
# NdO (c) 2017/12/29 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

PRG=`basename "$0"`
VER="v1.0  CIS script utilities"
AUT="Nicolas d'Oreye, (c)2016-2018, Last modified on March 07, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

TARGETDIR=$1  # e.g. /$PATH_1650/SAR_SM/AMPLITUDES/S1/DRC_NyamCrater_A_174/Nyam_crater_originalForm/_AMPLI

SOURCEDIR=$PWD

RebulidLink()
	{
	unset TYPELINK
	local TYPELINK
	TYPELINK=$1
	for LKS in `find * -maxdepth 1 -type l -name "*.${TYPELINK}"`
	do
		ORIGINALTARGET=`readlink ${LKS}`
	
		if [ ! -s ${ORIGINALTARGET} ] 
			then 

				SAT=`grep "Sensor ID" ../TextFiles/slaveSLCImageInfo.txt | cut -c 1-2`
				#echo " SAT is ${SAT}"
				
				if [ "${SAT}" == "S1" ] && [ "${TYPELINK}" == "jpg" ]
					then 
						SATAB=`grep "Sensor ID" ../TextFiles/slaveSLCImageInfo.txt | cut -c 1-3`
						# heading S1A or S1B was remove from name. 
						FULLORIGINALTARGETFILE=`basename ${ORIGINALTARGET}` # need to remove 4 first char i.e. e.g. S1A_
						ORIGINALTARGETFILE=${FULLORIGINALTARGETFILE: 4}
					else 
						ORIGINALTARGETFILE=`basename ${ORIGINALTARGET}`
				fi
				
				echo "Link broken : ${LKS}" 
				echo "	Will rebuild it supposing that file is in ${TARGETDIR}"
				if [ ! -s ${TARGETDIR}/${ORIGINALTARGETFILE} ] 
					then 
						echo "	File does not exist: ${TARGETDIR}/${ORIGINALTARGETFILE}"
						echo "	Please check expected path"
					else 
						# remove echo below when you are sure... 
						#echo "ln -s ${TARGETDIR}/${ORIGINALTARGETFILE} ${ORIGINALTARGETFILE}"
						rm ${LKS}
						if [ "${SAT}" == "S1" ] && [ "${TYPELINK}" == "jpg" ]
							then 
								echo "	File does exist at origin: ${TARGETDIR}/${ORIGINALTARGETFILE}"
								echo "	Hence link it to here (incl. getting satellite name back): ${SATAB}_${ORIGINALTARGETFILE} "
								ln -s ${TARGETDIR}/${ORIGINALTARGETFILE} ${SATAB}_${ORIGINALTARGETFILE}
							else 
								echo "	File does exist at origin: ${TARGETDIR}/${ORIGINALTARGETFILE}"
								echo "	Hence link it to here: ${ORIGINALTARGETFILE} "
								ln -s ${TARGETDIR}/${ORIGINALTARGETFILE} ${ORIGINALTARGETFILE}
						fi
				fi			
			else 
				echo "Link ${LKS} is ok: " 
				ls -l ${LKS}
		fi 
	done
	}



# Check if all links in dir points toward existing files  
for PAIRDIRS in `ls | ${PATHGNU}/grep -v txt | ${PATHGNU}/grep -v _AMPLI`
do
	echo " // Check ${PAIRDIRS}"
	cd ${PAIRDIRS}/i12/InSARProducts
	# rebuild links
	RebulidLink "jpg"
	RebulidLink "hdr"
	RebulidLink "flip"
	RebulidLink "flop"
	# remove wrong ras links	
	for LKS in `find * -maxdepth 1 -type l -name "*.ras"`
		do	
			ORIGINALTARGET=`readlink ${LKS}`
			if [ ! -s ${ORIGINALTARGET} ] 
				then 
					rm -f ${LKS}
			fi
	done
	# remove wrong sh links	
	for LKS in `find * -maxdepth 1 -type l -name "*.sh"`
		do	
			ORIGINALTARGET=`readlink ${LKS}`
			if [ ! -s ${ORIGINALTARGET} ] 
				then 
					rm -f ${LKS}
			fi
	done
	cd ${SOURCEDIR} 
	echo
done 

