#!/bin/bash
######################################################################################
# This script check the size of the ellipsoid in all the i12/TextFiles/geoProjectionParameters.txt
#  from the SAR_MASSPROCESS. If zero, update the value and store the pair name in file 
#
# Must be launnched in SAR_MASSPROCESS/sat/trk/crop/ where all pair dirs are
#
# New in Distro V 1.1 (Jul 19 2023): - replace if -s as -f -s && -f to be compatible with mac os if 
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2020/01/27 -                         
######################################################################################

SOURCEDIR=$PWD


rm -f _Updated_GeoProjParamFiles.txt

function ChangeParam()
	{
	unset CRITERIA NEW 
	local CRITERIA
	local NEW	

	CRITERIA=$1
	NEW=$2
	
	unset KEY ORIGINAL
	local KEY
	local ORIGINAL
	
	KEY=`echo ${CRITERIA} | tr ' ' _`

	updateParameterFile ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt ${KEY} ${NEW}
	
	}
	

ls -d S1*_*_*_*_S1*_*_* > All_Pairs.txt

for PAIR in `cat All_Pairs.txt`
do 
	SMAJA=`updateParameterFile ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt "Semi major axis"`
	SMINA=`updateParameterFile ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt "Semi minor axis"`

	SMAJA=`echo ${SMAJA} | cut -c 1-7`  # i.e. also ok when ellispoid was defined as double precision 
	SMINA=`echo ${SMINA} | cut -c 1-17`	

	if [ ${SMAJA} != "6378137" ] || [ ${SMINA} != "6356752.314245179" ] 
		then 
			cp ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters.txt ${SOURCEDIR}/${PAIR}/i12/TextFiles/geoProjectionParameters_beforeUpdateEllips.txt
			
			echo "Axes are : ${SMAJA}  and  ${SMINA}"			
			ChangeParam "Semi major axis" 6378137
			ChangeParam "Semi minor axis" 6356752.314245179
			echo "Updateing geoProjectionParameters in ${PAIR}" 
			echo "${PAIR}: ${SMAJA}  and  ${SMINA} " >> _Updated_GeoProjParamFiles.txt
	fi
done 

rm -f All_Pairs.txt
echo "-----------------------------"
if [ -f _Updated_GeoProjParamFiles.txt ] && [ -s _Updated_GeoProjParamFiles.txt ]
	then 
		echo "At least some ellispoid were wrong."
		echo "Clean _Updated_GeoProjParamFiles.txt by removing everything from :, i.e. everything but the pair names."
		echo "Then run here the following cmd from the same path: " 
		echo
		echo "_ReGeocode_fromList.sh ${SOURCEDIR}/_Updated_GeoProjParamFiles.txt BOTH" 
		echo
fi

echo "All done. "

