#!/bin/bash
######################################################################################
# This script aims at moving the geocoded results from a SuperMaster_MassProc.sh  
# and that would be still located in a pair directory, that is 
# SAR_MASSPROCESS/SAT/TRK/SMCrop.../MAS_SLV/i12/GeoProjection 
# to where it was supposed to be, that is SAR_MASSPROCESS/SAT/TRK/SMCrop.../Geocoded/... directories
# It also copy the corresponding rasters in GeocodedRasters
#
# WARNING: do not use it for the results of a SinglePiar.sh processing asd the naming of the 
#          geocoded products might differ. In that case, use the script 
#          Move_SinglePair_Results_To_MASSPROCESS.sh instead
# 
# Parameters : 	- full path to Pair Directory. MUST BE WITH IN SAR_MASSPROCESS/SAT/TRK/SMCrop.../
#				- full path to SAR_MASSPROCESS/SAT/TRK/SMCrop.../
#
# Hard coded: 	- none
#
# Dependencies:
#	 - 
# 
# New in Distro V 1.0.:	-
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Feb 03, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

SNGLPAIRDIRPATH=$1				# directory (with path) where the Pair was processed, i.e. in SAR_MASSPROCESS/SAT/TRK/SMCrop.../MAS_SLV
MASSPROCDIRPATH=$2				# Dir (with path) where mass process Geocoded results are expected, i.e. SAR_MASSPROCESS/SAT/TRK/SMCrop.../

SNGLPAIRDIR=`basename ${SNGLPAIRDIRPATH}`
MASSPROCDIR=`basename ${MASSPROCDIRPATH}`
MASSPROCPATH=`dirname ${MASSPROCDIRPATH}`

if [ $# -lt 2 ] ; then echo " Usage $0 PAIR_GEOPROJ_DIR MASS_PROCESS_GEOCODED_DIR "; exit 0 ; fi

if [ ! -d "${MASSPROCDIRPATH}" ] ; then echo "  //  Sorry, destination ${MASSPROCDIRPATH} dir does not exist. Please check." ; exit 0 ; fi

# Define fcts
function MvIfString()
	{
	unset DESTINATION 
	unset PARTNAME
	local DESTINATION
	local PARTNAME
	PARTNAME=$1
	DESTINATION=$2
   
   	if [[ ${GEOCODEDFILE} == *${PARTNAME}* ]] 
   		then 
   			mv -f ${SNGLPAIRDIRPATH}/i12/GeoProjection/${GEOCODEDFILE} ${MASSPROCDIRPATH}/Geocoded/${DESTINATION}/ 
   			mv -f ${SNGLPAIRDIRPATH}/i12/GeoProjection/${GEOCODEDFILE}.hdr ${MASSPROCDIRPATH}/Geocoded/${DESTINATION}/ 
   	fi  
	}

function CpIfString()
	{
	unset DESTINATION 
	unset PARTNAME
	local DESTINATION
	local PARTNAME
	PARTNAME=$1
	DESTINATION=$2
   
   	if [[ ${GEOCODEDFILE} == *${PARTNAME}* ]] 
   		then 
   			cp -f ${SNGLPAIRDIRPATH}/i12/GeoProjection/${GEOCODEDFILE}.ras ${MASSPROCDIRPATH}/GeocodedRasters/${DESTINATION}/
   	fi  
	}

# move ${SNGLPAIRDIR}/i12/GeoProjection/*deg and *.hdr geocoded products to ${MASSPROCDIRPATH}/Geocoded
# and cp geocoded rasters 
cd ${SNGLPAIRDIRPATH}/i12/GeoProjection
for GEOCODEDFILE in *deg
do
	MvIfString ".mod.UTM." Ampli # it avoids possible flip or flop images
	CpIfString ".mod.UTM." Ampli # it avoids possible flip or flop images
		
	MvIfString "coherence." Coh
	CpIfString "coherence." Coh
	
	MvIfString "deformationMap.UTM." Defo
	CpIfString "deformationMap.UTM." Defo
	
	MvIfString "deformationMap.interpolated.UTM." DefoInterpol
	CpIfString "deformationMap.interpolated.UTM." DefoInterpol
	
	MvIfString "unwrappedPhase." UnwrapPhase
	CpIfString "unwrappedPhase." UnwrapPhase
	
	if [[ ${GEOCODEDFILE} == *"deformationMap.interpolated.flattened."* ]] 
   		then 
   			if [[ ${GEOCODEDFILE} == *".interpolated_"* ]] 
   				then 
   		   			mv -f ${GEOCODEDFILE} ${MASSPROCDIRPATH}/Geocoded/DefoInterpolx2Detrend/ 
		   			mv -f ${GEOCODEDFILE}.hdr ${MASSPROCDIRPATH}/Geocoded/DefoInterpolx2Detrend/ 
		   			cp -f ${GEOCODEDFILE}.ras ${MASSPROCDIRPATH}/GeocodedRasters/DefoInterpolx2Detrend/
   				else 
   		   			mv -f ${GEOCODEDFILE} ${MASSPROCDIRPATH}/Geocoded/DefoInterpolDetrend/ 
		   			mv -f ${GEOCODEDFILE}.hdr ${MASSPROCDIRPATH}/Geocoded/DefoInterpolDetrend/ 
		   			cp -f ${GEOCODEDFILE}.ras ${MASSPROCDIRPATH}/GeocodedRasters/DefoInterpolDetrend/
   			fi
   	fi
	if [[ ${GEOCODEDFILE} == *"residualInterferogram."* ]] 
   		then 
   			if [[ ${GEOCODEDFILE} == *".f.UTM."* ]] 
   				then 
  		   			mv -f ${GEOCODEDFILE} ${MASSPROCDIRPATH}/Geocoded/InterfFilt/
		   			mv -f ${GEOCODEDFILE}.hdr ${MASSPROCDIRPATH}/Geocoded/InterfFilt/ 
		   			cp -f ${GEOCODEDFILE}.ras ${MASSPROCDIRPATH}/GeocodedRasters/InterfFilt/
   				else 
  		   			mv -f ${GEOCODEDFILE} ${MASSPROCDIRPATH}/Geocoded/InterfResid/ 
		   			mv -f ${GEOCODEDFILE}.hdr ${MASSPROCDIRPATH}/Geocoded/InterfResid/ 
		   			cp -f ${GEOCODEDFILE}.ras ${MASSPROCDIRPATH}/GeocodedRasters/InterfResid/
   			fi
   	fi
done 

#no need to update text files	

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES MOVED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

