#!/bin/bash
######################################################################################
# This script geocodes snaphuZoneMap, unwrappedPhase.cor, deformationMap.cor and deformationMap.cor.detrended 
#
# Must be launnched in i12 where of pair under concern
#
# Dependencies: - byte2float.py
#				- Python
#
# New in Distro V 1.1 ( Jul 19, 2023): - replace if -s as -f -s && -f to be compatible with mac os if 
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

PROCESSDIR="$(pwd)"


DIREND=`echo -n ${PROCESSDIR} | tail -c 4`
if [ "${DIREND}" != "/i12" ]  ; then echo "Check your current dir. You must be in /i12" ; exit 0 ; fi

if [ `ls ./InSARProducts/*.cor.* 2> /dev/null | wc -l` -lt 1 ] ; then echo "No corrected files (*.cor*) found. Can't run. If you need to geocode only the snaphuZoneMap, use GeocSnaphuZoneMap.sh instead." ; exit 0 ; fi


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

# get polarisation scheme
POL=`updateParameterFile ${PROCESSDIR}/TextFiles/InSARParameters.txt "Master polarization channel"`
POLNAME=${POL}-${POL}

cd InSARProducts

# Transform snaphuZoneMask in float using Python
echo "Transform snaphuZoneMap in Float using Python"
ZMAP=`ls snaphuZoneMap.cor.* | ${PATHGNU}/grep -v Float`
byte2float.py ${ZMAP}  
# Rename snaphuZoneMap in float as a file CIS can geocode
mv ${ZMAP}Float ./coherence.${POLNAME}

echo "Tricking Primary to avoid duplicate geocoding..."
# trick for geocoding only unwrappedPhase and deformationMap in their .cor version
ls unwrappedPhase.${POLNAME}*days | ${PATHGNU}/grep -v ".cor." > ListTMP.tmp
ls deformationMap.*days | ${PATHGNU}/grep -v ".cor." >> ListTMP.tmp
ls coherence.*days | ${PATHGNU}/grep -v ".cor." >> ListTMP.tmp
ls incidence >> ListTMP.tmp

i=1
for FILESTMP in `cat  ListTMP.tmp`
	do 
		mv ${FILESTMP} ${i}.tmp
		echo "${i}.tmp  ${FILESTMP}" >> ListToRename.tmp
		i=`echo "$i + 1" | bc -l`
done 
rm -f ListTMP.tmp

echo "Prepare files to geocode..."
# rename files to geocode 
DEFOCOR=`ls deformationMap.cor*days | ${PATHGNU}/grep -v "detrended"` # renames only one and both (if detrend exists) will beprepared
mv -f ${DEFOCOR} deformationMap
UWCOR=`ls unwrappedPhase.${POLNAME}.cor*days | ${PATHGNU}/grep -v "detrended"`
mv -f ${UWCOR} unwrappedPhase.${POLNAME}

cd .. 
# backup original /TextFiles/geoProjectionParameters.txt
cp ./TextFiles/geoProjectionParameters.txt ./TextFiles/geoProjectionParameters.original.txt
# update list of files to geocode: discard all products but (fake) coherence to geocode
	ChangeParam "Geoproject measurement" YES 
	ChangeParam "Geoproject master amplitude" NO 
	ChangeParam "Geoproject slave amplitude" NO  
	ChangeParam "Geoproject coherence" YES 
	ChangeParam "Geoproject interferogram" NO 
	ChangeParam "Geoproject filtered interferogram" NO  
	ChangeParam "Geoproject residual interferogram" NO 
	ChangeParam "Geoproject unwrapped phase" YES

# geocode 
geoProjection -rk ./TextFiles/geoProjectionParameters.txt

echo "Rebuild original naming of InSARProducts..."
cd InSARProducts

# rebuild original naming
rm -f coherence.${POLNAME}
mv -f deformationMap ${DEFOCOR}
mv -f unwrappedPhase.${POLNAME} ${UWCOR}

while read -r TMP NME
do	
	mv ${TMP} ${NME}
done < ListToRename.tmp
rm -f ListToRename.tmp

cd ..

echo "Rebuild naming of Geocoded Products..."
cd GeoProjection
	
# snaphuZoneMap
	# Rename fake geocoded coh as snaphuZoneMap
	FAKECOHGEOC=`ls coherence.${POLNAME}.UTM* | ${PATHGNU}/grep -v deg | ${PATHGNU}/grep -v hdr  | ${PATHGNU}/grep -v ras`
	PIXSIZE=`echo "${FAKECOHGEOC}" | ${PATHGNU}/grep -Eo "[0-9]{2}x[0-9]{2}" ` 

	# get long naming
	LONGNAME=`ls residualInterferogram.${POLNAME}.UTM.${PIXSIZE}.bil_* | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".ras" | cut -d_ -f2-`  # search for e.g. ENVISAT_ASARNyiragongo_A314-43.9deg_20061031_20061205_Bp-191.m_HA106.0m_BT35days_Head102.6deg

	mv ./${FAKECOHGEOC} ./snaphuZoneMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}

	# Create header for snaphuZoneMap.UTM
	COHGEOCHDR=coherence.${POLNAME}.UTM.${PIXSIZE}.bil_${LONGNAME}.hdr
	cp ${COHGEOCHDR} snaphuZoneMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.hdr
	${PATHGNU}/gsed -i "/Description/c\Description = {${ZMAP}.UTM.${PIXSIZE}.bil" snaphuZoneMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.hdr

	# Create raster of geocded snaphuZoneMap
	cp  coherence.${POLNAME}.UTM.${PIXSIZE}.bil.ras.sh snaphuZoneMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh
	${PATHGNU}/gsed -i "s/coherence.${POLNAME}.UTM.${PIXSIZE}.bil/snaphuZoneMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}/g" snaphuZoneMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh
	${PATHGNU}/gsed -i "s/-r 0,1 -e 1.5 -s 1.5//" snaphuZoneMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh

	snaphuZoneMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh 

# unwrapped phase is 
	# Rename unwrapped phase as .cor
	mv unwrappedPhase.${POLNAME}.UTM.${PIXSIZE}.bil ./unwrappedPhase.${POLNAME}.cor.UTM.${PIXSIZE}.bil_${LONGNAME}

	# Create header 
	UWHDR=unwrappedPhase.${POLNAME}.UTM.${PIXSIZE}.bil_${LONGNAME}.hdr
	cp ${UWHDR} unwrappedPhase.${POLNAME}.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.hdr
	${PATHGNU}/gsed -i "/Description/c\Description = {unwrappedPhase.${POLNAME}.cor.UTM.${PIXSIZE}.bil_${LONGNAME}" unwrappedPhase.${POLNAME}.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.hdr

	# Create raster 
	cp  unwrappedPhase.${POLNAME}.UTM.${PIXSIZE}.bil.ras.sh unwrappedPhase.${POLNAME}.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh
	${PATHGNU}/gsed -i "s/unwrappedPhase.${POLNAME}.UTM.${PIXSIZE}.bil/unwrappedPhase.${POLNAME}.cor.UTM.${PIXSIZE}.bil_${LONGNAME}/g" unwrappedPhase.${POLNAME}.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh 

	unwrappedPhase.${POLNAME}.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh 

# deformation map
	# Rename deformationMap as .cor
	mv ./deformationMap.UTM.${PIXSIZE}.bil ./deformationMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}

	# Create header 
	cp ${UWHDR} deformationMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.hdr
	${PATHGNU}/gsed -i "/Description/c\Description = {deformationMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}" deformationMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.hdr

	# Create raster 
	cp  deformationMap.UTM.${PIXSIZE}.bil.ras.sh deformationMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh
	${PATHGNU}/gsed -i "s/deformationMap.UTM.${PIXSIZE}.bil/deformationMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}/g" deformationMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh 

	deformationMap.cor.UTM.${PIXSIZE}.bil_${LONGNAME}.ras.sh 

# detrended
	# Rename detrended
 	ls *detrended*.bil > ListDetrended.tmp
	if [ -f ListDetrended.tmp ] && [ -s ListDetrended.tmp ] ; then 
		for DETRENDED in `cat ListDetrended.tmp`
			do
				ROOTNAME=`echo ${DETRENDED} | ${PATHGNU}/gsed 's/detrended.*/detrended/'`
				mv ./${DETRENDED} ./${ROOTNAME}.UTM.${PIXSIZE}_${LONGNAME}
 
				# Create header 
				cp ${UWHDR} ${ROOTNAME}.UTM.${PIXSIZE}_${LONGNAME}.hdr
				${PATHGNU}/gsed -i "/Description/c\Description = {${ROOTNAME}.UTM.${PIXSIZE}_${LONGNAME}" ${ROOTNAME}.UTM.${PIXSIZE}_${LONGNAME}.hdr
 
				# Create raster 
				cp  deformationMap.UTM.${PIXSIZE}.bil.ras.sh ${ROOTNAME}.UTM.${PIXSIZE}_${LONGNAME}.ras.sh
				${PATHGNU}/gsed -i "s/deformationMap.UTM.${PIXSIZE}.bil/${ROOTNAME}.UTM.${PIXSIZE}_${LONGNAME}/g" ${ROOTNAME}.UTM.${PIXSIZE}_${LONGNAME}.ras.sh 
 
				${ROOTNAME}.UTM.${PIXSIZE}_${LONGNAME}.ras.sh 
		done
	fi
 	rm -f ListDetrended.tmp
cd ..

# Recover original geoProjectionParameters.txt
mv ./TextFiles/geoProjectionParameters.original.txt ./TextFiles/geoProjectionParameters.txt 
