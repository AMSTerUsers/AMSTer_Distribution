#!/bin/bash
######################################################################################
# This script geocodes snaphuZoneMap 
#
# Must be launnched in i12 where of pair under concern
#
# Dependencies: - byte2float.py
#				- Python
#
# V1.0 (Aug 03, 2020)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20260902:	- Cope with name changed of incidence => localIncidenceAngle and geoidalIncidenceAngle.

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 02, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

function ChangeParam()
	{
	unset CRITERIA NEW 
	local CRITERIA
	local NEW	
	CRITERIA=$1
	NEW=$2
	
	unset KEY parameterFilePath ORIGINAL
	local KEY
	local parameterFilePath 
	local ORIGINAL
	KEY=`echo ${CRITERIA} | tr ' ' _`
	ORIGINAL=`updateParameterFile ./TextFiles/geoProjectionParameters.txt ${KEY} ${NEW}`
	}

cd InSARProducts

# Rename former coherence 
ORIGINALCOH=`ls coherence.*days`
mv ${ORIGINALCOH} ${ORIGINALCOH}.original

# Transform snaphuZoneMask in float using Python
echo "Transform snaphuZoneMap in Float using Python"
byte2float.py snaphuZoneMap  
# Rename snaphuZoneMap in float as a file CIS can geocode
mv snaphuZoneMapFloat coherence.VV-VV

# Avoid re-geocoding incidence ; note 1 instead of i
if [ -f incidence ] ; then mv incidence inc1dence ; fi
if [ -f localIncidenceAngle ] ; then mv localIncidenceAngle localInc1denceAngle ; fi
if [ -f geoidalIncidenceAngle ] ; then mv geoidalIncidenceAngle geoidalInc1denceAngle ; fi

cd .. 
# backup original /TextFiles/geoProjectionParameters.txt
cp ./TextFiles/geoProjectionParameters.txt ./TextFiles/geoProjectionParameters.original.txt
# update list of files to geocode: discard all products but (fake) coherence to geocode
	ChangeParam "Geoproject measurement" NO 
	ChangeParam "Geoproject master amplitude" NO 
	ChangeParam "Geoproject slave amplitude" NO  
	ChangeParam "Geoproject coherence" YES 
	ChangeParam "Geoproject interferogram" NO 
	ChangeParam "Geoproject filtered interferogram" NO  
	ChangeParam "Geoproject residual interferogram" NO 
	ChangeParam "Geoproject unwrapped phase" NO 



# geocode (without -r ?) 
geoProjection -rk ./TextFiles/geoProjectionParameters.txt

cd GeoProjection
# Rename fake geocoded coh as snaphuZoneMap
FAKECOHGEOC=`ls coherence.VV-VV.UTM* | ${PATHGNU}/grep -v deg | ${PATHGNU}/grep -v hdr  | ${PATHGNU}/grep -v ras`
PIXSIZE=`echo "${FAKECOHGEOC}" | ${PATHGNU}/grep -Eo "[0-9]{2}x[0-9]{2}" ` 
mv ./${FAKECOHGEOC} ./snaphuZoneMap.UTM.${PIXSIZE}.bil

# Create header for snaphuZoneMap.UTM
COHGEOCHDR=`ls coherence.VV-VV.UTM* | ${PATHGNU}/grep deg | ${PATHGNU}/grep hdr`
cp ${COHGEOCHDR} snaphuZoneMap.UTM.${PIXSIZE}.bil.hdr
${PATHGNU}/gsed -i "/Description/c\Description = {snaphuZoneMap.UTM.${PIXSIZE}.bil" snaphuZoneMap.UTM.${PIXSIZE}.bil.hdr

# Create raster of geocded snaphuZoneMap
cp  coherence.VV-VV.UTM.${PIXSIZE}.bil.ras.sh snaphuZoneMap.UTM.${PIXSIZE}.bil.sh
${PATHGNU}/gsed -i "s/coherence.VV-VV.UTM.${PIXSIZE}.bil/snaphuZoneMap.UTM.${PIXSIZE}.bil/g" snaphuZoneMap.UTM.${PIXSIZE}.bil.sh 
${PATHGNU}/gsed -i "s/-r 0,1 -e 1.5 -s 1.5//" snaphuZoneMap.UTM.${PIXSIZE}.bil.sh 

snaphuZoneMap.UTM.${PIXSIZE}.bil.sh 

cd ..
# Recover original coherence, incidence and geoProjectionParameters.txt
mv ./InSARProducts/${ORIGINALCOH}.original ./InSARProducts/${ORIGINALCOH} 
#mv ./InSARProducts/1cidence ./InSARProducts/incidence 
if [ -f inc1dence ] ; then mv inc1dence incidence ; fi
if [ -f localInc1denceAngle ] ; then mv localInc1denceAngle localIncidenceAngle ; fi
if [ -f geoidalInc1denceAngle ] ; then mv geoidalInc1denceAngle geoidalIncidenceAngle ; fi
mv ./TextFiles/geoProjectionParameters.original.txt ./TextFiles/geoProjectionParameters.txt 
  
