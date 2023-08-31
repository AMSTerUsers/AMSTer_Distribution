#!/bin/bash
######################################################################################
# This script aims at moveing the results of a SinglePair.sh processing into the SAR_MASSPROCESS
# dir as if it was computed by a normal SuperMaster_MassProcess.sh 
#
# Parameters : 	- Single Pair Dir. MUST BE WITH THE SAME NAMING CONVENTION THAN THE MASS PROCESSED ONES
#				- SAR_MASSPROCESS Dir
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
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Nov 18, 2020"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

SNGLPAIRDIRPATH=$1				# directory (with path) where the SinglePair.sh was processed
MASSPROCDIRPATH=$2					# Dir (with path) where mass process results are expected

SNGLPAIRDIR=`basename ${SNGLPAIRDIRPATH}`
MASSPROCDIR=`basename ${MASSPROCDIRPATH}`
MASSPROCPATH=`dirname ${MASSPROCDIRPATH}`

if [ $# -lt 2 ] ; then echo " Usage $0 SINGLE_PAIR_DIR FILE MASS_PROCESS_DIR "; exit 0 ; fi

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
# Get name of a data dir in MASSPROCDIR for comparison with SNGLPAIRDIR
LASTDATADIR=`$PATHGNU/find ${MASSPROCDIRPATH} -maxdepth 1 -type d -name '*[[:digit:]]*' | tail -1 `  # get the last dir of all dir which contain digits

# Single pair dir name msut at least have the same number of characters and underscore as the data dir in MASSPROCDIR 
NRCHARMASSPROC=`basename ${LASTDATADIR} | wc -c `
NRCHARSNGLPAIR=`echo ${SNGLPAIRDIR} | wc -c `

NRUNDERSCMASSPROC=`basename ${LASTDATADIR} | tr -cd "_" | wc -c `
NRUNDERSCSNGLPAIR=`echo ${SNGLPAIRDIR} | tr -cd "_" | wc -c `

if [ ${NRCHARMASSPROC} -ne ${NRCHARSNGLPAIR} ] || [ ${NRUNDERSCMASSPROC} -ne ${NRUNDERSCSNGLPAIR} ]
	then 
		echo " Single Pair Dir has not the same number of characters an/or underscore."
		echo " It must have a different naming as the pair files in SAR_MASSPROCESS, which is not wanted. Please check"
		exit 0 
fi 

# Check that dir does not exist yet in SAR_MASSPROCESS
if [ -d ${MASSPROCDIRPATH}/${SNGLPAIRDIR} ] ; then echo " Single Pair dir already exists in SAR_MASSPROCESS dir. Please check " ; exit 0 ; fi

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

# move pair dir
cd ${SNGLPAIRDIRPATH}
cd ..
mv -f ${SNGLPAIRDIR} ${MASSPROCDIRPATH}/

#no need to update text files	

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES MOVED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

