#!/bin/bash
######################################################################################
# This script delete all files (deg, deg.hdr and ras) in MSBAS/region/DefoInterpolDetrendi(_Full) and its texts 
# and in /Geocoded/Mode and /GeocodedRasters/Mode 
# for given pairs of date and Bp.
#
# DO NOT USE IT ON GEOCODED AMPLITUDE IMAGES because mas and slv can be geocoded within the same pair 
#
# Parameters:	- Primary image date
#				- Secondary image date 
#				- Bt
#				- region/crop dir in SAR_MASSPROCESS where region and crop are specific to where files are
#				- region/mode in MSBAS where region and i are specific to where files are
#				- optional: CHECK (to perform check but remove nothing)
#				
#
# Depedencies: 	- gnu find !! (Macport findutils)
#
# V1.0 (Oct 08, 2020)
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

MAS=$1
SLV=$2
BP=$3
MASSPROCREGCROP=$4	# e.g. ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_20180512_Zoom1_ML4
MSBASREGMODE=$5		# e.g. _Domuyo_S1_Auto_20m_450days/DefoInterpolx2Detrend1
CHECKMODE=$6

# vvv ----- Hard coded lines to check --- vvv 
MASSPROCESSDIRHERE=$PATH_3601/SAR_MASSPROCESS
# ^^^ ----- Hard coded lines to check -- ^^^ 


if [ $# -lt 5 ] ; then echo “\n Usage $0 PRIMARY SECONDARY BP MASSPROCREGION/CROP MSBASREGION/MODE [CHECK]”; exit; fi

function SpeakOut()
	{
	unset MESSAGE 
	local MESSAGE
	MESSAGE=$1
	case ${OS} in 
		"Linux") 
			espeak "${MESSAGE}" ;;
		"Darwin")
			say "${MESSAGE}" 	;;
		*)
			echo "${MESSAGE}" 	;;
	esac			
	}

if [ $# -eq 5 ] ; then 
	SpeakOut "You request to delete bad infos without check; are you sure ?" 
	while true; do
		read -p "You request to delete bad infos without check; are you sure ?"  yn
		case $yn in
			[Yy]* ) 
				echo "OK, you know..."
				break ;;
			[Nn]* ) 
				echo "OK, will only check then "
				CHECKMODE="CHECK"
				break ;;
			* ) echo "Please answer yes or no.";;
		esac
	done

fi
# where to move all dir 
TARGETDIR=${MASSPROCESSDIRHERE}/S1/${MASSPROCREGCROP}/DuplicateToKill
mkdir -p ${TARGETDIR}
echo ""
echo "Dealing with deg and deg.hdr files" 
echo "  => move the bad ones in ${TARGETDIR}"
echo "--------------------------------------"

# move all file from Geocode to place to kill
if [ "${CHECKMODE}" == "CHECK" ] ; then 
		find ${MASSPROCESSDIRHERE}/S1/${MASSPROCREGCROP}/Geocoded -type f -name "*${MAS}_${SLV}*Bp${BP}*"
		echo
	else 
		find ${MASSPROCESSDIRHERE}/S1/${MASSPROCREGCROP}/Geocoded -type f -name "*${MAS}_${SLV}*Bp${BP}*" -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +
		echo
fi
echo ""
echo "Dealing with ras files" 
echo "  => move the bad ones in ${TARGETDIR}"
echo "--------------------------------------"
# move all file from GeocodeRasters to place to kill
if [ "${CHECKMODE}" == "CHECK" ] ; then 
		find ${MASSPROCESSDIRHERE}/S1/${MASSPROCREGCROP}/GeocodedRasters -type f -name "*${MAS}_${SLV}*Bp${BP}*"
		echo
	else 
		find ${MASSPROCESSDIRHERE}/S1/${MASSPROCREGCROP}/GeocodedRasters -type f -name "*${MAS}_${SLV}*Bp${BP}*" -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +
		echo
fi

# 
echo ""
echo "Dealing with ${MAS}_${SLV} PAIR directory" 
echo "  => move the bad one in ${TARGETDIR}"
echo "-----------------------------------------"
# where to move all dir 
TARGETDIR=$PATH_3602/MSBAS/DuplicateToKill
mkdir -p ${TARGETDIR}
mkdir -p ${TARGETDIR}/Files
# move all file from DefoInterpolx2Detrendi(_Full) to place to kill
if [ "${CHECKMODE}" == "CHECK" ] ; then 
		find $PATH_3602/MSBAS/${MSBASREGMODE} -type f -name "*${MAS}_${SLV}*Bp${BP}*" 
		find $PATH_3602/MSBAS/${MSBASREGMODE}_Full -type f -name "*${MAS}_${SLV}*Bp${BP}*" 
	else 
		find $PATH_3602/MSBAS/${MSBASREGMODE} -type f -name "*${MAS}_${SLV}*Bp${BP}*" -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +
		find $PATH_3602/MSBAS/${MSBASREGMODE}_Full -type f -name "*${MAS}_${SLV}*Bp${BP}*" -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +
fi
echo
echo ""
echo "Dealing with text files" 
echo "  => erase bad lines"
echo "-----------------------"
# remove from within text files in 
REGION=`basename ${MSBASREGMODE}`
MODE=`dirname ${MSBASREGMODE}`
cd $PATH_3602/MSBAS/

# list with path from MSBAS (no leading ./)
find ${MSBASREGMODE} -type f -name "${MODE}*.txt" > FilesToCheck_For_Wrong_date_bp.txt
ls ${MSBASREGMODE}/Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt >> FilesToCheck_For_Wrong_date_bp.txt
ls ${MSBASREGMODE}/List*.txt >> FilesToCheck_For_Wrong_date_bp.txt
ls ${MSBASREGMODE}/Out_Of_Range*.txt >> FilesToCheck_For_Wrong_date_bp.txt
ls ${MSBASREGMODE}_Full/Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt >> FilesToCheck_For_Wrong_date_bp.txt
ls ${MSBASREGMODE}_Full/List*.txt >> FilesToCheck_For_Wrong_date_bp.txt
while read -r FILEANDPATH
do	
	echo "Search and delete lines with ${MAS}_${SLV}_Bp${Bp} in ${FILEANDPATH}"

	if [ "${CHECKMODE}" == "CHECK" ] 
		then
			${PATHGNU}/grep "${MAS}_${SLV}_Bp${Bp}" ./${FILEANDPATH} 
		else 
			${PATHGNU}/gsed -i "/${MAS}_${SLV}_Bp${Bp}/d" ./${FILEANDPATH} 
	fi
done < FilesToCheck_For_Wrong_date_bp.txt
echo 


echo ""
echo "Check coherence tables " 
echo "  => manaully remove lines that looks suspicious"
echo "------------------------------------------------"
# list coh table to search for errors 
ls ${MSBASREGMODE}/Coh_Table*.txt > FilesToCheck_For_Wrong_date_bp_CohTables.txt
ls ${MSBASREGMODE}_Full/Coh_Table*.txt >> FilesToCheck_For_Wrong_date_bp_CohTables.txt
while read -r FILEANDPATH
do	
	echo "Search for PRM_SCD in ${FILEANDPATH} and display 2 lines before and after to check if everything is ok"
	${PATHGNU}/grep -B 2 -A 2 "${MAS}_${SLV}" ${FILEANDPATH} 
	echo
done < FilesToCheck_For_Wrong_date_bp_CohTables.txt

#rm -f FilesToCheck_For_Wrong_date_bp.txt FilesToCheck_For_Wrong_date_bp_CohTables.txt

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CLEANED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

