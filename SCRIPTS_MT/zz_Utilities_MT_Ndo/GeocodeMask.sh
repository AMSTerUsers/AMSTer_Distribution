#!/bin/bash
######################################################################################
# This script aims at geocoding the slantRangeMask 
#
# Parameter: - path to i12 dir of pair to geocode its mask
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

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
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/TextFiles/geoProjectionParameters.txt;;
	esac

	ORIGINAL=`updateParameterFile ${parameterFilePath} ${KEY} ${NEW}`
	echo "=> Change in ${parameterFilePath}"
	echo "...Key = ${CRITERIA} "
	echo "...Former Value =  ${ORIGINAL}"
	echo "    --> New Value =  ${NEW}  \n"
	}
	
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
		# Checked
		"InSARParameters.txt") parameterFilePath=${RUNDIR}/TextFiles/InSARParameters.txt;;
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/TextFiles/geoProjectionParameters.txt;;
	esac
	updateParameterFile ${parameterFilePath} ${KEY}
	}


cd 

RUNDIR=$1
# check that path ends with /i12

if [ "${RUNDIR##*/}" != "i12" ] ; then echo "Path must end with /i12; check you parameters" exit ; fi 

mv ${RUNDIR}/InSARProducts ${RUNDIR}/InSARProducts.back

mkdir -p ${RUNDIR}/InSARProducts

cp ${RUNDIR}/InSARProducts.back/slantRangeMask ${RUNDIR}/InSARProducts/slantRangeMask

sleep 1
echo "Convert bytes to float"
$PATH_SCRIPTS/SCRIPTS_MT/zz_Utilities_MT_Ndo/byte2float.py ${RUNDIR}/InSARProducts/slantRangeMask
echo "Converted... "
echo 

sleep 1

cd ${RUNDIR}/InSARProducts

mv -f ${RUNDIR}/InSARProducts/slantRangeMaskfloat.npy ${RUNDIR}/InSARProducts/residualInterferogram.VV-VV
echo "Geocode mask as fake residualInterferogram.VV-VV"
cd ${RUNDIR}

cp ${RUNDIR}/TextFiles/geoProjectionParameters.txt ${RUNDIR}/TextFiles/geoProjectionParameters.back.txt

ChangeParam "Geoproject measurement" NO geoProjectionParameters.txt
ChangeParam "Geoproject master amplitude" NO geoProjectionParameters.txt 
ChangeParam "Geoproject slave amplitude" NO geoProjectionParameters.txt 
ChangeParam "Geoproject coherence" NO geoProjectionParameters.txt 
ChangeParam "Geoproject interferogram" NO geoProjectionParameters.txt 
ChangeParam "Geoproject filtered interferogram" NO geoProjectionParameters.txt 
ChangeParam "Geoproject residual interferogram" YES geoProjectionParameters.txt 
ChangeParam "Geoproject unwrapped phase" NO} geoProjectionParameters.txt 

geoProjection

cd ${RUNDIR}/GeoProjection
PIXSIZE=`ls residualInterferogram.VV-VV.UTM.* | head -1 | cut -d x -f 2`

MASK=`ls residualInterferogram.VV-VV.UTM.${PIXSIZE}x${PIXSIZE}`

mv ${MASK} mask

mv -f ${RUNDIR}/TextFiles/geoProjectionParameters.back.txt ${RUNDIR}/TextFiles/geoProjectionParameters.txt

INCID=`ls incidence.*.hdr | head -1`
cp ${INCID} mask.hdr
${PATHGNU}/gsed -i "s%incidence%mask%" mask.hdr

# Need to flip to get back to GIS convention
NLINES=`GetParamFromFile "Y size of geoprojected products [pix]" geoProjectionParameters.txt`
echo "Flip mask ${NLINES} long" 
FLIPproducts.py.sh ${RUNDIR}/GeoProjection/mask ${NLINES}
echo "Flipped..." 
echo

mv -f mask.flip mask

WIDTH=`GetParamFromFile "X size of geoprojected products [pix]" geoProjectionParameters.txt`
echo "cpxfiddle -w ${WIDTH} -q normal -o sunraster -c gray -M 1/1 -f r4 -l1 mask > mask.ras" > mask.sh 
chmod +x mask.sh

./mask.sh

cd ${RUNDIR}/
rm -Rf ${RUNDIR}/InSARProducts 
mv ${RUNDIR}/InSARProducts.back ${RUNDIR}/InSARProducts 
