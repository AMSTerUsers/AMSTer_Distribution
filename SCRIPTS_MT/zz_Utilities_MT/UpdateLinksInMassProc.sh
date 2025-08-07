#!/bin/bash
# Script to InSARParameters.txt in pair dir in SAR_MASSPROCESS/SAT/TRK/SM_Crop_Zoom_ML 
#  in the hope of reprocessing. 
#
# Need to be run in dir PRM_SCD where i12/InSARProducts are stored 
#
# Parameters : - None
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- __HardCodedLines.sh
#
# New in V2.0:	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 2.1: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20250227:	- replace cp -n with if [ ! -e DEST ] ; then cp SRC DEST ; fi 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Feb 27, 2025"

echo "not finished - do not use..."
exit 0

PRG=`basename "$0"`
VER="v3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2018, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below: 
	# - RenameVolNameToVariable to rename all path in param files just in case DIR were moved
# ^^^ ----- Hard coded lines to check --- ^^^ 


SOURCEDIR=$PWD

# Change parameters in Parameters txt files
function ChangeParam()
	{
	unset CRITERIA NEW FILETOCHANGE
	local CRITERIA
	local NEW	
	local FILETOCHANGE
	CRITERIA=$1
	NEW=$2
	FILETOCHANGE=$3
	
	unset KEY parameterFilePath ORIGINAL
	local KEY
	local parameterFilePath 
	local ORIGINAL
	
	KEY=`echo ${CRITERIA} | tr ' ' _`
	case ${FILETOCHANGE} in
		"InSARParameters.txt") parameterFilePath=${SOURCEDIR}/i12/TextFiles/InSARParameters.txt;;
		"geoProjectionParameters.txt") parameterFilePath=${SOURCEDIR}/i12/TextFiles/geoProjectionParameters.txt;;
		"bestPlaneRemoval.txt") parameterFilePath=${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval.txt;;
	esac

	ORIGINAL=`updateParameterFile ${parameterFilePath} ${KEY} ${NEW}`
	}


# Get parameters 
function GetParamFromFile()
	{
	unset CRITERIA FILETYPE
	local CRITERIA
	local FILETYPE
	CRITERIA=$1
	FILETYPE=$2

	unset parameterFilePath KEY

	local KEY
	local parameterFilePath 

	KEY=`echo ${CRITERIA} | tr ' ' _`
	case ${FILETYPE} in
		"InSARParameters.txt") parameterFilePath=${SOURCEDIR}/i12/TextFiles/InSARParameters.txt;;
		"geoProjectionParameters.txt") parameterFilePath=${SOURCEDIR}/i12/TextFiles/geoProjectionParameters.txt;;
		"bestPlaneRemoval.txt") parameterFilePath=${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval.txt;;
	esac

	updateParameterFile ${parameterFilePath} ${KEY}
	}

# #Change HD names
# function ChangeHDnames()
# 	{
# 		unset FILETOCHANGE
# 		local FILETOCHANGE
# 		FILETOCHANGE=$1  # incl path
# 	
# 		${PATHGNU}/gsed -i 's%Volumes\/hp-1650-Data_Share1%$PATH_1650%g' ${FILETOCHANGE}
# 		${PATHGNU}/gsed -i 's%Volumes\/hp-D3600-Data_Share1%$PATH_3600%g' ${FILETOCHANGE}
# 		${PATHGNU}/gsed -i 's%Volumes\/hp-D3601-Data_RAID6%$PATH_3601%g' ${FILETOCHANGE}
# 		${PATHGNU}/gsed -i 's%Volumes\/hp-D3602-Data_RAID5%$PATH_3602%g' ${FILETOCHANGE}
# 
# 		${PATHGNU}/gsed -i 's%mnt\/1650%$PATH_1650%g' ${FILETOCHANGE}
# 		${PATHGNU}/gsed -i 's%mnt\/3600%$PATH_3600%g' ${FILETOCHANGE}
# 		${PATHGNU}/gsed -i 's%mnt\/3601%$PATH_3601%g' ${FILETOCHANGE}
# 		${PATHGNU}/gsed -i 's%mnt\/3602%$PATH_3602%g' ${FILETOCHANGE}
# 	}
	
	
#cp -n ${SOURCEDIR}/i12/TextFiles/InSARParameters.txt ${SOURCEDIR}/i12/TextFiles/InSARParameters_original.txt
#cp -n ${SOURCEDIR}/i12/TextFiles/geoProjectionParameters.txt ${SOURCEDIR}/i12/TextFiles/geoProjectionParameters_original.txt
#cp -n ${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval.txt ${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval_original.txt
if [ ! -e "${SOURCEDIR}/i12/TextFiles/InSARParameters_original.txt" ] ; then cp "${SOURCEDIR}/i12/TextFiles/InSARParameters.txt" "${SOURCEDIR}/i12/TextFiles/InSARParameters_original.txt" ; fi 
if [ ! -e "${SOURCEDIR}/i12/TextFiles/geoProjectionParameters_original.txt" ] ; then cp "${SOURCEDIR}/i12/TextFiles/geoProjectionParameters.txt" "${SOURCEDIR}/i12/TextFiles/geoProjectionParameters_original.txt" ; fi 
if [ ! -e "${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval_original.txt" ] ; then cp "${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval.txt" "${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval_original.txt" ; fi 


# get MAS and SLV
PATHMAS=`GetParamFromFile "Master image file path [CSL image format]" InSARParameters.txt`	# should be in SAR_CSL dir, which has not been moved
PATHRESAMPLEDSLV=`ls -d ${SOURCEDIR}/i12/InSARProducts/*.interpolated.csl`					# in pair dir, which has been moved
echo ${PATHRESAMPLEDSLV}
MASNAME=`basename ${PATHMAS}`
SLVRESNAME=`basename ${PATHRESAMPLEDSLV}`
SLVNAMENOEXT=`echo ${SLVRESNAME} | cut -d . -f1 `
MASNAMENOEXT=`echo ${MASNAME} | cut -d . -f1 `

POL=`GetParamFromFile "Master polarization channel" InSARParameters.txt`


# update InSARParameters.txt
############################
# update resampled slave and interpolated resampled, which should be the same because already interpolated
ChangeParam "Slave image file path [CSL image format]" ${PATHRESAMPLEDSLV} InSARParameters.txt
ChangeParam "Interpolated slave image file path" ${PATHRESAMPLEDSLV} InSARParameters.txt

# update amplitude file path - maybe not needed 
PATHMASMOD=${SOURCEDIR}/i12/InSARProducts/${MASNAMENOEXT}.${POL}.mod
PATHSLVMOD=${SOURCEDIR}/i12/InSARProducts/${SLVNAMENOEXT}.${POL}.mod
ChangeParam "Reduced master amplitude image file path" ${PATHMASMOD} InSARParameters.txt
ChangeParam "Reduced slave amplitude image file path" ${PATHSLVMOD} InSARParameters.txt

# update insar products path incl usused ones - just in case... 
ChangeParam "Interferogram file path" ${SOURCEDIR}/i12/InSARProducts/interfero.${POL}-${POL} InSARParameters.txt
ChangeParam "Filtered interferogram file path " ${SOURCEDIR}/i12/InSARProducts/residualInterferogram.${POL}-${POL}.f InSARParameters.txt
ChangeParam "Coherence file path" ${SOURCEDIR}/i12/InSARProducts/coherence.${POL}-${POL} InSARParameters.txt
ChangeParam "First phase component file path" ${SOURCEDIR}/i12/InSARProducts/firstPhaseComponent.${POL}-${POL} InSARParameters.txt
ChangeParam "Residual interferogram file path" ${SOURCEDIR}/i12/InSARProducts/residualInterferogram.${POL}-${POL} InSARParameters.txt
ChangeParam "Biased coherence file path" ${SOURCEDIR}/i12/InSARProducts/biasedCoherence.${POL}-${POL} InSARParameters.txt
ChangeParam "Residus image file path" ${SOURCEDIR}/i12/InSARProducts/residus.${POL}-${POL} InSARParameters.txt
ChangeParam "Connexions image file path" ${SOURCEDIR}/i12/InSARProducts/connexions.${POL}-${POL} InSARParameters.txt
ChangeParam "Unwrapped phase file path" ${SOURCEDIR}/i12/InSARProducts/unwrappedPhase.${POL}-${POL}	InSARParameters.txt
ChangeParam "External slant range DEM file path" ${SOURCEDIR}/i12/InSARProducts/externalSlantRangeDEM InSARParameters.txt
ChangeParam "Deformation measurement file path" ${SOURCEDIR}/i12/InSARProducts/deformationMap InSARParameters.txt

# update bestPlaneRemoval.txt
#############################
if [ -f "${SOURCEDIR}/i12/InSARProducts/deformationMap.interpolated" ] && [ -s "${SOURCEDIR}/i12/InSARProducts/deformationMap.interpolated" ]
	then 
		ChangeParam "File to be corrected" ${SOURCEDIR}/i12/InSARProducts/deformationMap.interpolated bestPlaneRemoval.txt
	else 
		ChangeParam "File to be corrected" ${SOURCEDIR}/i12/InSARProducts/deformationMap bestPlaneRemoval.txt
fi
 
# update geoProjectionParameters.txt
####################################
ChangeParam " InSAR parameters file" ${SOURCEDIR}/i12/InSARProducts/deformationMap geoProjectionParameters.txt


# change hd names
RenameVolNameToVariable ${SOURCEDIR}/i12/TextFiles/InSARParameters.txt ${SOURCEDIR}/i12/TextFiles/InSARParameters_tmp.txt
mv -f ${SOURCEDIR}/i12/TextFiles/InSARParameters_tmp.txt ${SOURCEDIR}/i12/TextFiles/InSARParameters.txt

RenameVolNameToVariable ${SOURCEDIR}/i12/TextFiles/geoProjectionParameters.txt ${SOURCEDIR}/i12/TextFiles/geoProjectionParameters_tmp.txt
mv -f ${SOURCEDIR}/i12/TextFiles/geoProjectionParameters_tmp.txt ${SOURCEDIR}/i12/TextFiles/geoProjectionParameters.txt

RenameVolNameToVariable ${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval.txt ${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval_tmp.txt
mv -f ${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval_tmp.txt ${SOURCEDIR}/i12/InSARProducts/bestPlaneRemoval.txt


# 	LINKTOCHANGE=`ls *.interpolated`
# 	SUPERMASTER=`echo ${DIR} | cut -d _ -f 1`
# 	SLVNAME=`echo ${DIR} | cut -d _ -f 2-5`
# 	POLSLV=`echo ${LINKTOCHANGE} | cut -d . -f 2`
# 	rm ${LINKTOCHANGE}
# 	ln -s ${OUTPUTDATA}/${SUPERMASTER}_${SLVNAME}/i12/InSARProducts/${SLVNAME}.interpolated.csl/Data/SLCData.${POLSLV} ${OUTPUTDATA}/${SUPERMASTER}_${SLVNAME}/i12/InSARProducts/${SLVNAME}.${POLSLV}.interpolated
# 	cd ${OUTPUTDATA}


# OUTPUTDATA="$(pwd)"
# 
# for DIR in `ls -d ????????_?1?_*` 
# do 
# 	cd ${DIR}/i12/InSARProducts
# 	LINKTOCHANGE=`ls *.interpolated`
# 	SUPERMASTER=`echo ${DIR} | cut -d _ -f 1`
# 	SLVNAME=`echo ${DIR} | cut -d _ -f 2-5`
# 	POLSLV=`echo ${LINKTOCHANGE} | cut -d . -f 2`
# 	rm ${LINKTOCHANGE}
# 	ln -s ${OUTPUTDATA}/${SUPERMASTER}_${SLVNAME}/i12/InSARProducts/${SLVNAME}.interpolated.csl/Data/SLCData.${POLSLV} ${OUTPUTDATA}/${SUPERMASTER}_${SLVNAME}/i12/InSARProducts/${SLVNAME}.${POLSLV}.interpolated
# 	cd ${OUTPUTDATA}
# done 



