#!/bin/bash
# Script to re-run the geocoding of files from a SinglePair.sh processing.
#
# It also detect if interpolation is required for existing files defo..bil  
#
# Note that it skips the geocoding of amplitude if it exists. 
#      See script lines 177-186 below if you want to force it. 
# Note Incidence is geocoded by default if present in InSARProducts. 
#    If you do not want to re-geoc it, it will be renamed temporarily. For this let the 
#    script know by adding an additional NO at the hardcoded list of geocoded files. 
#
# Note : only verified for interpolation BOTH and with detrend !
#
# Need to be run in dir where SinglePair.sh was run
#
# Parameters:	- Parameters file 
#
# HARD CODED: 	- list of products to gecode
#				- FIG=FIGyes or FIGno if one wants to recompute the rasters
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- FUNCTIONS_FOR_MT.sh
#
# New in Distro V 1.0:	- Based on ReGeocode_FromList.sh
# New in Distro V 2.0:	- Read Param File to get ML, ZOOM etc
#						- now allows to change pixel size etc during re-geocoding
# New in Distro V 2.1:	- rename files
# New in Distro V 2.2:	- bug in SAT maning (remove DRC_)
#						- remove trailing dot before star in search of existing defo maps to cope with format from recursive unwrapping
#						- definition of GEOPIXW and  GEOPIXL were missing because commented !
# New in Distro V 2.3:	- better cope with renaming deformation files when no detrend is chosen
#						- offer the option to create fake detrended file. This may be useful when a pair is manually recomputed with recursive snpahu
#						  because defo is too big for classical unwrapping, then re-injected in classical mass processing results directories for time series
#						- recreate some of the rasters  (not tested for all products)
# New in Distro V 2.4: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.5: 	- read UTM zone for geocoding
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20240228:	- Fix rounding pix size when smaller than one by allowing scale 5 before division  
# New in Distro V 5.0 20241015:	- multi level mask 
# New in Distro V 5.1 20241202:	- debug PATHTOMASK
# New in Distro V 5.2 20241203:	- debug possible crash to fin MASNAME
# 								- also OK with polarisation other than VV
# New in Distro V 5.3 20250604:	- allows regeoc on kml 
#								- adapt to asymetric zoom 
#								- test if RUNDIR contains a dir named i12. If not, you are most probably not in the right dir and exit
#								- test if requested ge-geocoding defo map before atempting detrend to avoid possible error msg
# New in Distro V 5.4 20250804:	- Correct checking unchanged zoom factor  

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.4 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 04, 2025"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

PARAMFILE=$1	# File with the parameters needed for the run

source ${PATH_SCRIPTS}/SCRIPTS_MT/FUNCTIONS_FOR_MT.sh


# vvv ----- Hard coded lines to check --- vvv 
# only the deformation maps
#  		DEFOMAP	MASAMPL	SLVAMPL	COH	INTERF	FILTINTERF	RESINTERF	UNWPHASE INCIDENCE 
#FILESTOGEOC="YES NO NO NO NO NO NO NO NO"
# All
#FILESTOGEOC="YES YES YES YES NO YES YES YES YES"
# All but ampl
#FILESTOGEOC="YES NO NO YES NO YES YES YES YES"
FILESTOGEOC="YES YES YES YES YES YES YES YES YES"
#FILESTOGEOC="NO NO NO YES NO NO NO NO NO"
# ^^^ ----- Hard coded lines to check --- ^^^ 

# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

FIG=`GetParam "FIG,"`

ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping (either a single real value or NAzMRg, where N and M are reals values if want an asymmetric zoom)
PIXSHAPE=`GetParam "PIXSHAPE,"`				# PIXSHAPE, pix shape for products : SQUARE or ORIGINALFORM   
INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products

PROJ=`GetParam "PROJ,"`						# PROJ, Chosen projection (UTM or GEOC)
GEOCMETHD=`GetParam "GEOCMETHD,"`			# GEOCMETHD, Resampling Size of Geocoded product: Forced (at FORCEGEOPIXSIZE - convenient for further MSBAS), Auto (closest multiple of 10), Closest (closest to ML az sampling)
RADIUSMETHD=`GetParam "RADIUSMETHD,"`		# LetCIS (CIS will compute best radius) or forced to a given radius 
RESAMPMETHD=`GetParam "RESAMPMETHD,"`		# TRI = Triangulation; AV = weighted average; NN = nearest neighbour 
WEIGHTMETHD=`GetParam "WEIGHTMETHD,"`		# Weighting method : ID = inverse distance; LORENTZ = lorentzian 
IDSMOOTH=`GetParam "IDSMOOTH,"`				# ID smoothing factor  
IDWEIGHT=`GetParam "IDWEIGHT,"`				# ID weighting exponent 
FWHM=`GetParam "FWHM,"`						# Lorentzian Full Width at Half Maximum
ZONEINDEX=`GetParam "ZONEINDEX,"`			# Zone index  
UW_METHOD=`GetParam "UW_METHOD,"`			# UW_METHOD, Select phase unwrapping method (SNAPHU, CIS or DETPHUN)

APPLYMASK=`GetParam "APPLYMASK,"`			# APPLYMASK, Apply mask before unwrapping (APPLYMASKyes or APPLYMASKno)
if [ ${APPLYMASK} == "APPLYMASKyes" ] 
 then 
	PATHTOMASK=`GetParam "PATHTOMASK,"`			# PATHTOMASK, geocoded mask file name and path
	if [ "${PATHTOMASK}" != "" ]
		then 
			# old Version of LaunchParamFiles.txt, i.e. =< 20231026
			MASKBASENAME=`basename ${PATHTOMASK##*/}`  
		else 
			# Version of LaunchParamFiles.txt, i.e. >= 202341015
			PATHTOMASKGEOC=`GetParam "PATHTOMASKGEOC,"`			# PATHTOMASKGEOC, geocoded "Geographical mask" file name and path (water body etc..)
			DATAMASKGEOC=`GetParam "DATAMASKGEOC,"`				# DATAMASKGEOC, value for masking in PATHTOMASKGEOC

			PATHTOMASKCOH=`GetParam "PATHTOMASKCOH,"`			# PATHTOMASKCOH, geocoded "Thresholded coherence mask" file name and path (mask at unwrapping below threshold)
			DATAMASKCOH=`GetParam "DATAMASKCOH,"`				# DATAMASKCOH, value for masking in PATHTOMASKCOH

			PATHTODIREVENTSMASKS=`GetParam "PATHTODIREVENTSMASKS,"` # PATHTODIREVENTSMASKS, path to dir that contains event mask(s) named eventMaskYYYYMMDDThhmmss_YYYYMMDDThhmmss(.hdr) for masking at Detrend with all masks having dates in Primary-Secondary range of dates
			DATAMASKEVENTS=`GetParam "DATAMASKEVENTS,"`			# DATAMASKEVENTS, value for masking in PATHTODIREVENTSMASKS 

			if [ "${PATHTOMASKGEOC}" != "" ] ; then MASKBASENAMEGEOC=`basename ${PATHTOMASKGEOC##*/}` ; else MASKBASENAMEGEOC=NoGeogMask  ; fi
			if [ "${PATHTOMASKCOH}" != "" ] ; then MASKBASENAMECOH=`basename ${PATHTOMASKCOH##*/}` ; else MASKBASENAMECOH=NoCohMask  ; fi
			if [ "${PATHTODIREVENTSMASKS}" != "" ] 
				then 
				    if [ "$(find "${PATHTODIREVENTSMASKS}" -type f | head -n 1)" ]
				    	then 
				    		MASKBASENAMEDETREND=`basename ${PATHTODIREVENTSMASKS}` 
				    		MASKBASENAMEDETREND=Detrend${MASKBASENAMEDETREND}
				    	else 
				    		echo "${PATHTODIREVENTSMASKS} exist though is empty, hence apply no Detrend mask " 
				    		MASKBASENAMEDETREND=NoAllDetrend
				    fi
				else 
					MASKBASENAMEDETREND=NoAllDetrend
			fi

			MASKBASENAME=${MASKBASENAMEGEOC}_${MASKBASENAMECOH}_${MASKBASENAMEDETREND}

	fi
 else 
  PATHTOMASK=`echo "NoMask"`
  MASKBASENAME=`echo "NoMask"` 
fi


RADIUSMETHD=`GetParam "RADIUSMETHD,"`		# LetCIS (CIS will compute best radius) or forced to a given radius 
	
FORCEGEOPIXSIZE=`GetParam "FORCEGEOPIXSIZE,"` # Pixel size (in m) wanted for your final products. Required for MSBAS

UTMZONE=`GetParam "UTMZONE,"`				# UTMZONE, letter of row and nr of col of the zone where coordinates below are computed (e.g. U32)

XMIN=`GetParam "XMIN,"`						# XMIN, minimum X UTM coord of final Forced geocoded product
XMAX=`GetParam "XMAX,"`						# XMAX, maximum X UTM coord of final Forced geocoded product
YMIN=`GetParam "YMIN,"`						# YMIN, minimum Y UTM coord of final Forced geocoded product
YMAX=`GetParam "YMAX,"`						# YMAX, maximum Y UTM coord of final Forced geocoded product

GEOCKML=`GetParam "GEOCKML,"`				# GEOCKML, a kml file to define final geocoded product. If not found, it will use the coordinates above

SKIPUW=`GetParam "SKIPUW,"`					# SKIPUW, SKIPyes skips unwrapping and geocode all available products
INTERPOL=`GetParam "INTERPOL,"`				# INTERPOL, interpolate the unwrapped interfero BEFORE or AFTER geocoding or BOTH. 	
REMOVEPLANE=`GetParam "REMOVEPLANE,"`		# REMOVEPLANE, if DETREND it will remove a best plane after unwrapping. Anything else will ignore the detrending. 	

DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 
SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)

RUNDIR="$(pwd)"
BASEDIRNAME=`dirname ${RUNDIR}`
BASEDIRNAME2=`dirname ${BASEDIRNAME}`

MODE="${BASEDIRNAME##*/}"
#SAT=DRC_"${BASEDIRNAME2##*/}"
SAT="${BASEDIRNAME2##*/}"


echo "List of products that will be geocoded : "
echo "DEFOMAP	MASAMPL	SLVAMPL	COH	INTERF	FILTINTERF	RESINTERF	UNWPHASE INCIDENCE" 
echo "${FILESTOGEOC}"

while true; do
    read -p "Do you agree with that list ? [y/n] "  yn
    case $yn in
        [Yy]* ) 
        		echo "OK, let's go."
        		DEFOMAP=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $1}'`
        		MASAMPL=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $2}'`
        		SLVAMPL=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $3}'`
        		COH=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $4}'`
        		INTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $5}'`
        		FILTINTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $6}'`
        		RESINTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $7}'`
        		UNWPHASE=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $8}'`
        		INCIDENCE=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $9}'`
        break ;;
        [Nn]* ) 
        echo "Then change the hard coded list in script and relaunch"
        exit 0
        break ;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo ""
echo "Attention : need the Parameters files in TextFiles with the right path and in the format of your mounted disks depending on the OS. "
while true; do
    read -p "Are you sure that all the TextFiles/ have the correct path and format ? [y/n] "  yn
    case $yn in
        [Yy]* ) 
        	echo "OK, let's go again."
		    break ;;
        [Nn]* ) 
        	echo "Please do... "
        	exit 0
        	break ;;
        * ) echo "Please answer yes or no.";;
    esac
done 
echo ""

#  Check that you are in the right dir - hopefuly 
if [ -d "./i12" ]; then
    echo "The current directory contains a subdirectory 'i12'; I guess you are in the directrory where the images to re-geocode were computed."
else
    echo "The current directory DOES NOT contain a subdirectory 'i12'; I guess you are NOT in the directrory where the images to re-geocode were computed."
    echo "I can't work; exiting..."
	exit
fi
# Some fcts
###########

function ChangeGeocParam()
	{
	unset CRITERIA NEW 
	local CRITERIA
	local NEW	
	CRITERIA=$1
	NEW=$2
	FILETOCHANGE=$3
	
	unset KEY parameterFilePath ORIGINAL
	local KEY
	local parameterFilePath 
	local ORIGINAL
	
	KEY=`echo ${CRITERIA} | tr ' ' _`
	case ${FILETOCHANGE} in
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt ;;
		"geoProjectionParameters_NoZoom.txt") parameterFilePath=${RUNDIR}/i12.NoZoom/TextFiles/geoProjectionParameters.txt ;;
	esac

	ORIGINAL=`updateParameterFile ${parameterFilePath} ${KEY} ${NEW}`
	echo "  // update  ${CRITERIA} in ${parameterFilePath}"
 	echo "=> Change in ${parameterFilePath}"
 	echo "...Key = ${CRITERIA} "
 	echo "...Former Value =  ${ORIGINAL}"
 	echo "    --> New Value =  ${NEW}"
	}

function MakeFig()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local E=$2
		local S=$3
		local TYPE=$4
		local COLOR=$5
		local ML=$6
		local FORMAT=$7
		local FILE=$8
		cd GeoProjection
		eval FILE=${FILE}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
		cd ..
	fi
	}
	
function MakeFigR()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local R=$2
		local E=$3
		local S=$4
		local TYPE=$5
		local COLOR=$6
		local ML=$7
		local FORMAT=$8
		local FILE=$9
		cd GeoProjection
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
		cd ..
	fi
	}
function MakeFigNoNorm()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local TYPE=$2
		local COLOR=$3
		local ML=$4
		local FORMAT=$5
		local FILE=$6
		cd GeoProjection
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
		cd ..
	fi
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
		"InSARParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/InSARParameters.txt ;;
		"SLCImageInfo.txt") parameterFilePath=${MASNAME}.csl/Info/SLCImageInfo.txt ;;				
		"masterSLCImageInfo.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/masterSLCImageInfo.txt ;;
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt ;;

		"NoZoom_masterSLCImageInfo.txt") parameterFilePath=${RUNDIR}/i12.NoZoom/TextFiles/masterSLCImageInfo.txt;; 
	esac
	updateParameterFile ${parameterFilePath} ${KEY}
	}
	


########
# test if S1 zoomed image files exist
if [ `find ./i12.NoZoom/TextFiles -maxdepth 1 -type f -name "InSARParameters.txt" 2>/dev/null | wc -l` -eq 1 ] ; then 
	echo "Re-geocoding Sentinel 1 wide swath zoomed image; need to get SLC info from ./i12.NoZoom"
	S1WSZOOM="Yes"
fi

# get AZSAMP. Attention, needs original az sampling
	MASDATE=`basename ${RUNDIR} | cut -d _ -f 1`
	SLVDATE=`basename ${RUNDIR} | cut -d _ -f 2`
	MASNAME=`ls -d ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/*/ | ${PATHGNU}/grep ${MASDATE} | cut -d . -f 1` 	

###	if [ "${S1WSZOOM}" == "Yes" ]
###		then 
###			# Get param from NoZoom image
###			AZSAMP=`GetParamFromFile "Azimuth sampling [m]" Zoom_masterSLCImageInfo.txt`
###			RGSAMP=`GetParamFromFile "Range sampling [m]" Zoom_masterSLCImageInfo.txt`
###			INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" Zoom_masterSLCImageInfo.txt` # not rounded
###		else 
###			#	KEY=`echo "Azimuth sampling [m]" | tr ' ' _`
###			#	parameterFilePath="${MASNAME}.csl/Info/SLCImageInfo.txt"
###			#	AZSAMP=`updateParameterFile ${parameterFilePath} ${KEY}` # not rounded
###			AZSAMP=`GetParamFromFile "Azimuth sampling [m]" SLCImageInfo.txt`
###			RGSAMP=`GetParamFromFile "Range sampling [m]" SLCImageInfo.txt`
###			INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" masterSLCImageInfo.txt` # not rounded
###	fi

	# need to read from masterSLCImageInfo.txt to get the info for zoomed pix if any
	# Remember that zoom factor can't be changed anyway 
	AZSAMP=`GetParamFromFile "Azimuth sampling [m]" masterSLCImageInfo.txt`
	RGSAMP=`GetParamFromFile "Range sampling [m]" masterSLCImageInfo.txt`
	INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" masterSLCImageInfo.txt` # not rounded


if [ "${INCIDENCE}" == "YES" ] 
	then 
		echo "Will geocode incidence again"
	else 
		echo "Temporarily rename indidence to avoid automatic geocoding" 
		if [ -f ${RUNDIR}/i12/InSARProducts/incidence ] ; then mv ${RUNDIR}/i12/InSARProducts/incidence ${RUNDIR}/i12/InSARProducts/BAK_incidence  ; fi
fi
echo ""

# remove possible existing old Projection Map
rm -f ${RUNDIR}/i12/GeoProjection/projMat.UTM.* 2>/dev/null

cd  ${RUNDIR}/i12/TextFiles

# Update which products to geocode

####
####	PIXSIZEAZ=`echo "scale=5; ( ${AZSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
####	EchoTee " PIXSIZEAZ is ${PIXSIZEAZ} from ( AZSAMP${AZSAMP} / ZOOM${ZOOM} ) * INTERFML${INTERFML} "
	# Test if Zoom is one value or two - Define ZOOMONEVAL and ZOOMRG and ZOOMAZ if needed. Needed for fct Crop
	CheckZOOMasymetry

	# May want to check that zoom factor has not changed in Param file and former processing: 
		ZOOMEDAZSAMP=`GetParamFromFile "Azimuth sampling [m]" InSARParameters.txt`
		ZOOMEDRGSAMP=`GetParamFromFile "Range sampling [m]" InSARParameters.txt`

		if [ "${S1WSZOOM}" == "Yes" ]
			then 
				# Get param from NoZoom image
				UNZOOMEDAZSAMP=`GetParamFromFile "Azimuth sampling [m]" NoZoom_masterSLCImageInfo.txt`
				UNZOOMEDRGSAMP=`GetParamFromFile "Range sampling [m]" NoZoom_masterSLCImageInfo.txt`
			else 
				UNZOOMEDAZSAMP=`GetParamFromFile "Azimuth sampling [m]" SLCImageInfo.txt`
				UNZOOMEDRGSAMP=`GetParamFromFile "Range sampling [m]" SLCImageInfo.txt`
		fi
	
		# AZSAMP must be = to UNZOOMEDAZSAMP/ZOOMAZ
		REZOOMEDAZSAMP=`echo "scale=15; ( ${UNZOOMEDAZSAMP} / ${ZOOMAZ} ) " | bc` 
		# RGSAMP must be = to UNZOOMEDRGSAMP/ZOOMRG
		REZOOMEDRGSAMP=`echo "scale=15; ( ${UNZOOMEDRGSAMP} / ${ZOOMRG} ) " | bc` 
	
		# Because of possible problem of floating-point precision (e.g., 3.1400000001 vs 3.14), direct comparison may fail. Hence check if they're close enough (within a small EPSILON):

		EPSILON=0.0001
		
		diff=$(echo " ${REZOOMEDAZSAMP} - ${ZOOMEDAZSAMP}" | bc -l)
		abs_diff=$(echo "$diff" | awk '{print ($1 >= 0) ? $1 : -$1}')
		AZ_is_close=$(echo "$abs_diff < ${EPSILON}" | bc -l)

		diff=$(echo " ${REZOOMEDRGSAMP} - ${ZOOMEDRGSAMP}" | bc -l)
		abs_diff=$(echo "$diff" | awk '{print ($1 >= 0) ? $1 : -$1}')
		RG_is_close=$(echo "$abs_diff < ${EPSILON}" | bc -l)
		
		if [ "${AZ_is_close}" -eq 1 ] && [ "${RG_is_close}" -eq 1 ]
			then
				EchoTee "OK: Former zoomed pixel size matches zoomed pixel size computed with zoom factor from your parameter file."
			else
				EchoTee "Former zoomed pixel size do not match zoomed pixel size computed with zoom factor from your parameter file."
				EchoTee " Rezoomed sampling are ${REZOOMEDAZSAMP} from (${UNZOOMEDAZSAMP} / ${ZOOMAZ} ) in azimuth, compared to ${ZOOMEDAZSAMP} from InSARParameters.txt"
				EchoTee "                   and ${REZOOMEDRGSAMP} from (${UNZOOMEDRGSAMP} / ${ZOOMRG} ) in range, compared to ${ZOOMEDRGSAMP} from InSARParameters.txt"
				EchoTee "Zoom factor can't be changed for geocoding. Pixel size can be changed though...."
				exit 	
		fi

	# Need this for ManageDEM ?? 
	
		####if [ "${ZOOM}" == "1"  ] || [ "${ZOOM}" == "1Az1Rg"  ] || [ "${ZOOM}" == "1Rg1Az"  ] 
		####	then
		####		PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
		####		PIXSIZERG=`echo "${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 
		####	else
		####		if [ "${ZOOMONEVAL}" == "One" ]
		####			then
		####				PIXSIZEAZ=`echo "scale=2; ( ${AZSAMP} * ${INTERFML} ) / ${ZOOM} " | bc`  # size of ML pixel in az (in m) 
		####				PIXSIZERG=`echo "scale=2; ( ${RGSAMP} * ${INTERFML} ) / ${ZOOM} " | bc`  # size of ML pixel in range (in m) 
		####
		####				EchoTee " PIXSIZEAZ is ${PIXSIZEAZ} from ( AZSAMP${AZSAMP} / ZOOM${ZOOM} ) * INTERFML${INTERFML} "
		####				EchoTee " PIXSIZERG is ${PIXSIZERG} from ( RGSAMP${RGSAMP} / ZOOM${ZOOM} ) * INTERFML${INTERFML} "
		####			else 
		####				PIXSIZEAZ=`echo "scale=2; ( ${AZSAMP} * ${INTERFML} ) / ${ZOOMAZ} " | bc`  # size of ML pixel in az (in m) 
		####				PIXSIZERG=`echo "scale=2; ( ${RGSAMP} * ${INTERFML} ) / ${ZOOMRG} " | bc`  # size of ML pixel in range (in m) 
		####
		####				EchoTee " PIXSIZEAZ is ${PIXSIZEAZ} from ( AZSAMP${AZSAMP} / ZOOMAZ${ZOOMAZ} ) * INTERFML${INTERFML} "
		####				EchoTee " PIXSIZERG is ${PIXSIZERG} from ( RGSAMP${RGSAMP} / ZOOMRG${ZOOMRG} ) * INTERFML${INTERFML} "
		####		fi
		####
		####fi

	# In every case, AZSAMP and RGSAMP are already zoomed (for S1 IW or other, zoomed asymetric or not or unzoomed) 
	# Ratio is however computed on UNZOOMED pixels  
	UNZOOMEDRATIO=`echo "scale=2; ( s((${INCIDANGL} * 3.1415927) / 180) * ${UNZOOMEDAZSAMP} ) / ${UNZOOMEDRGSAMP}" | bc -l | xargs printf "%.*f\n" 0` # with two digits and rounded to 0th decimal
	UNZOOMEDRATIOREAL=`echo "scale=5; ( s((${INCIDANGL} * 3.1415927) / 180) * ${UNZOOMEDAZSAMP} ) / ${UNZOOMEDRGSAMP}" | bc -l` # with 5 digits 
	
	RatioPixUnzoomed ${INTERFML}  # Define ${UNZOOMEDRGML} and ${UNZOOMEDAZML}
	INTERFMLAZ=${UNZOOMEDAZML}
	INTERFMLRG=${UNZOOMEDRGML}
	unset UNZOOMEDRGML 
	unset UNZOOMEDAZML
	
	PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFMLAZ}" | bc`  # size of ML pixel in az (in m) 
	PIXSIZERG=`echo "${RGSAMP} * ${INTERFMLRG}" | bc`  # size of ML pixel in range (in m) 

	# To be certain, re-check wich one is the largest
	ROUNDEDAZSAMP=`echo ${AZSAMP} | xargs printf "%.*f\n" 0`  # (AzPixSize) rounded to 0th digits precision
	ROUNDEDRGSAMP=`echo ${RGSAMP} | xargs printf "%.*f\n" 0`  # (RgPixSize) rounded to 0th digits precision
	
		if [ ${ROUNDEDAZSAMP} -ge ${ROUNDEDRGSAMP} ]
			then 
				# Beware: PIXSIZE already computed - do not ML again
				eval PIXSIZEAZORIGINAL=${PIXSIZEAZ} # needed in the specific case of asymetric zoom making square pix despite ORIGINALFORM 
				EchoTee " PIXSIZEAZ is ${PIXSIZEAZ} "
			else 
				# Beware: PIXSIZE already computed - do not ML again
				EchoTee " PIXSIZERG is ${PIXSIZERG} "
				eval PIXSIZEAZORIGINAL=${PIXSIZEAZ}
				EchoTee " PIXSIZEAZ is ${PIXSIZEAZORIGINAL} "
				# from now on, the largest pixel is named AZ... even if it is RG - Yes it is uggly but changing the name could have too much impact in other scripts
				if [ "${PIXSHAPE}" != "ORIGINALFORM" ] ; then 
					PIXSIZEAZ=${PIXSIZERG}
				fi
		fi

	# Unless PIXSHAPE=ORIGINALFORM, PIXSIZEAZ below is the pixel with respect to the largest side (i.e. AZ or RG) - Yes it is uggly but changing the name could have too much impact in other scripts
	
	GEOPIXSIZERND=`echo ${PIXSIZEAZ} | cut -d . -f1`	
	if [ ${GEOPIXSIZERND} -eq "0" ] 
		then 
			GEOPIXSIZERND="1" 
			EchoTee "Truncated PIXSIZE is 0, hence increased to ${GEOPIXSIZERND}"
		else
			EchoTee "Truncated PIXSIZE is ${GEOPIXSIZERND}"
	fi 	
	
	# Size of the geocoded pixel rounded to the nearest (up) multiple of 10
	if [ -z ${GEOPIXSIZERND#?} ]   # test if all but the first digit is null
		then
		 GEOPIXSIZE10=`echo "10"`	 # if only 1 digit, uper round is 10
		else
		 unset x
		 x=$((${GEOPIXSIZERND}-${GEOPIXSIZERND: -1})) # Rounded - last digit
		 GEOPIXSIZE10=`echo "$x" +10 | bc`            # +10
	fi

	case ${GEOCMETHD} in
		"Closest") 
			EchoTeeYellow "Automatic geocoded pixel size determination."
			EchoTeeYellow "          Will get the closest multilooked original pixel size." 
			EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 		

			GEOPIXSIZE=`echo ${PIXSIZEAZ} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
			if [ ${GEOPIXSIZE} -eq "0" ] ; then GEOPIXSIZE="1" ; fi 	# just in case...
	
			if [ "${PIXSHAPE}" == "ORIGINALFORM" ]
				then 
					GEOPIXSIZEAZ=`echo ${PIXSIZEAZORIGINAL} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
					if [ ${GEOPIXSIZEAZ} -eq "0" ] ; then GEOPIXSIZEAZ="1" ; fi 	# just in case...
					GEOPIXSIZERG=`echo ${PIXSIZERG} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
					if [ ${GEOPIXSIZERG} -eq "0" ] ; then GEOPIXSIZERG="1" ; fi 	# just in case...
					ChangeParam "Easting sampling" ${GEOPIXSIZERG} geoProjectionParameters.txt 
					ChangeParam "Northing sampling" ${GEOPIXSIZEAZ} geoProjectionParameters.txt
					GEOPIXSIZENAME=${GEOPIXSIZERG}x${GEOPIXSIZEAZ}
	
					EchoTeeYellow "Using ${GEOPIXSIZENAME} meters geocoded Rg x Az pixel size."
				else 
					ChangeParam "Easting sampling" ${GEOPIXSIZE} geoProjectionParameters.txt 
					ChangeParam "Northing sampling" ${GEOPIXSIZE} geoProjectionParameters.txt
					GEOPIXSIZENAME=${GEOPIXSIZE}x${GEOPIXSIZE}
	
					EchoTeeYellow "Using ${GEOPIXSIZENAME} meters geocoded pixel size."
					
					# Dummy; Needed for naming 
					GEOPIXSIZEAZ=${GEOPIXSIZE}
					GEOPIXSIZERG=${GEOPIXSIZE}
			fi

			# just in case 
			ChangeGeocParam "Path to a kml file defining the geoProjection area" "None" geoProjectionParameters.txt
			ChangeParam "xMin" 0 geoProjectionParameters.txt
			ChangeParam "xMax" 0 geoProjectionParameters.txt
			ChangeParam "yMin" 0 geoProjectionParameters.txt
			ChangeParam "yMax" 0 geoProjectionParameters.txt

			;;
		"Auto") 
			EchoTeeYellow "Automatic geocoded (squared) pixel size determination."
			EchoTeeYellow "          Will get the closest (upper) multiple of 10 of multilooked original pixel size. " 
			EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 	
			GEOPIXSIZE=${GEOPIXSIZE10}
	
			# just in case 
			ChangeGeocParam "Path to a kml file defining the geoProjection area" "None" geoProjectionParameters.txt
			ChangeParam "xMin" 0 geoProjectionParameters.txt
			ChangeParam "xMax" 0 geoProjectionParameters.txt
			ChangeParam "yMin" 0 geoProjectionParameters.txt
			ChangeParam "yMax" 0 geoProjectionParameters.txt
	
			ChangeParam "Easting sampling" ${GEOPIXSIZE} geoProjectionParameters.txt 
			ChangeParam "Northing sampling" ${GEOPIXSIZE} geoProjectionParameters.txt
			GEOPIXSIZENAME=${GEOPIXSIZE}x${GEOPIXSIZE}
	
			EchoTeeYellow "Using ${GEOPIXSIZENAME} meters geocoded pixel size."
			
			# Dummy; Needed for naming 
			GEOPIXSIZEAZ=${GEOPIXSIZE}
			GEOPIXSIZERG=${GEOPIXSIZE}

			;;
		"Forced") 
			# Possibly force UTM coordinates of geocoded products (convenient for further MSBAS)

			CheckFORCEGEOPIXSIZEasymetry		# this fct also define GEOPIXSIZE, GEOPIXSIZERG and GEOPIXSIZEAZ based on FORCEGEOPIXSIZE, FORCEGEOPIXSIZEAZ and FORCEGEOPIXSIZERG

			#GEOPIXSIZE=${FORCEGEOPIXSIZE}    					# Give the sampling rate here of what you want for your final MSBAS database
			#EchoTeeYellow "Forced geocoded (squared) pixel size determination. " 
			#EchoTeeYellow "Assigned ${GEOPIXSIZE} m. Will also force the limits of the geocoded files."
			#EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 	

			# Check if GEOCKML param is defined
			CHECKGEOCKML=`echo "${GEOCKML}" | wc -c`
			if [ ${CHECKGEOCKML} -gt 1 ] 
				then
					# Seems you want to define the geocoded zone using a kml file
					if [ -f "${GEOCKML}" ] && [ -s "${GEOCKML}" ]
						then 
							# OK file exists 
							ChangeParam "Path to a kml file defining the geoProjection area" ${GEOCKML} geoProjectionParameters.txt	
						else 
							EchoTeeYellow "Can't find the kml for defining geocoding area in ${GEOCKML} " 
							EchoTeeYellow "Try using xMin, xMax, yMin and yMax instead..." 
	
							if [ "${UTMZONE}" == "" ]
								then 
									EchoTeeYellow "No UTM zone defined (empty or not in LaunchParam.txt file). Will compute it from the center of the image."
									EchoTeeYellow "  It may not be a problem unless the center of the AoI is in another zone and you need to compare different modes which can have different central UTM zone."
								else
									EchoTeeYellow "Shall use UTM zone defined in LaunchParam.txt, that is: ${UTMZONE}"
									ChangeParam "UTM zone " ${UTMZONE} geoProjectionParameters.txt
							fi
								
							ChangeParam "xMin" ${XMIN} geoProjectionParameters.txt
							ChangeParam "xMax" ${XMAX} geoProjectionParameters.txt
							ChangeParam "yMin" ${YMIN} geoProjectionParameters.txt
							ChangeParam "yMax" ${YMAX} geoProjectionParameters.txt
					fi
				else 
					if [ "${UTMZONE}" == "" ]
						then 
							EchoTeeYellow "No UTM zone defined (empty or not in LaunchParam.txt file). Will compute it from the center of the image."
							EchoTeeYellow "  It may not be a problem unless the center of the AoI is in another zone and you need to compare different modes which can have different central UTM zone."
						else
							EchoTeeYellow "Shall use UTM zone defined in LaunchParam.txt, that is: ${UTMZONE}"
							ChangeParam "UTM zone " ${UTMZONE} geoProjectionParameters.txt
					fi
	
					ChangeParam "xMin" ${XMIN} geoProjectionParameters.txt
					ChangeParam "xMax" ${XMAX} geoProjectionParameters.txt
					ChangeParam "yMin" ${YMIN} geoProjectionParameters.txt
					ChangeParam "yMax" ${YMAX} geoProjectionParameters.txt
			fi

			ChangeParam "Easting sampling" ${GEOPIXSIZERG} geoProjectionParameters.txt 
			ChangeParam "Northing sampling" ${GEOPIXSIZEAZ} geoProjectionParameters.txt		
			GEOPIXSIZENAME=${GEOPIXSIZERG}x${GEOPIXSIZEAZ}

			;;
			*) 
			EchoTeeYellow "Not sure what you wanted => used Closest..." 
			GEOPIXSIZE=`echo ${PIXSIZEAZ} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
			if [ ${GEOPIXSIZE} -eq "0" ] ; then GEOPIXSIZE="1" ; fi 	# just in case...
	
			EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
		;;
	esac

	# Change default parameters : Geoprojected products generic extension (OK also if only one value of FORCEDGEOPIXSIZE ; see fct CheckFORCEGEOPIXSIZEasymetry)
	ChangeParam "Geoprojected products generic extension" ".UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}" geoProjectionParameters.txt

	ChangeGeocParam "Geoproject measurement" ${DEFOMAP} geoProjectionParameters.txt

	ChangeGeocParam "Geoproject master amplitude" ${MASAMPL} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject slave amplitude" ${SLVAMPL} geoProjectionParameters.txt

	ChangeGeocParam "Geoproject coherence" ${COH} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject interferogram" ${INTERF} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject filtered interferogram" ${FILTINTERF} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject residual interferogram" ${RESINTERF} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject unwrapped phase" ${UNWPHASE} geoProjectionParameters.txt 

	ChangeGeocParam "Resampling method" ${RESAMPMETHD} geoProjectionParameters.txt
	
	ChangeGeocParam "Weighting method" ${WEIGHTMETHD} geoProjectionParameters.txt
	ChangeGeocParam "ID smoothing factor" ${IDSMOOTH} geoProjectionParameters.txt
	ChangeGeocParam "ID weighting exponent" ${IDWEIGHT} geoProjectionParameters.txt
	ChangeGeocParam "FWHM : Lorentzian Full Width at Half Maximum" ${FWHM} geoProjectionParameters.txt
	# Since 2020 01 21 MasTer Engine masking method is defined by either "mask" (all method but CIS) or "zoneMap" (for CIS in topo mode); no more path to mask
	# In cas eof Snaphu or DetPhun, no need to change here below
	# ChangeParam "Mask " ${PATHTOMASK} geoProjectionParameters.txt
	ChangeGeocParam "Zone index" ${ZONEINDEX} geoProjectionParameters.txt

   if [ "${UW_METHOD}" == "CIS" ]
        then
			# can make use of the mask generated for the borders at the unwrapping step:
			EchoTeeYellow "Geocoding using mask generated by CIS unwrapping method. "
			EchoTeeYellow "    It is built based on coh cleaning threshold (chose wizely) and is only usable "
			EchoTeeYellow "    by CIS unwrapping method to mask low coh pixels in contact with the borders of the image. "
			# Since 2020 01 21 CIS masking method is defined by either "mask" (all method but CIS) or "zoneMap" (for CIS in topo mode); no more path to mask
			# For CIS unwrapping and topo mode, it is advised to change mask as zoneMap here below
  			 if [ "${APPLYMASK}" == "APPLYMASKyes" ]
      		 	then
      		 		ChangeGeocParam "Masking: Use of slant range mask or zoneMap for measurement geo-projection ([mask] or [zoneMap])" mask geoProjectionParameters.txt
      		 	else
      		 		ChangeGeocParam "Masking: Use of slant range mask or zoneMap for measurement geo-projection ([mask] or [zoneMap])" zoneMap geoProjectionParameters.txt
			fi
			# ChangeParam "Mask " zoneMap geoProjectionParameters.txt
	fi

# Get infos for naming
	MASTERPATH=`GetParamFromFile "Master image file path" InSARParameters.txt `

	LOOKFULL=`GetParamFromFile "Incidence angle at median slant range" masterSLCImageInfo.txt ` # must cut to 2 decimal - do not put here InSARParameters.txt becasue it might be wrong in case of re-geoc
	LOOK=`echo "${LOOKFULL}" | cut -c 1-4`
	BpFULL=`GetParamFromFile "Perpendicular baseline component at image centre" InSARParameters.txt` 
	Bp=`echo "${BpFULL}" | cut -c 1-5`
	HAFULL=`GetParamFromFile "Ambiguity altitude at scene centre" InSARParameters.txt` 
	HA=`echo "${HAFULL}" | cut -c 1-5`
	BTFULL=`GetParamFromFile "Temporal baseline" InSARParameters.txt` 

	if [ ${BTFULL} == "(null)" ] ; then 
			BT=0
		else  
			BT=`echo "${BTFULL}" | cut -c 1-5 | ${PATHGNU}/gsed "s/ //g"`
	fi

	HEADINGFULL=`GetParamFromFile "Azimuth heading" SLCImageInfo.txt ` # must cut to 2 decimal
	HEADING=`echo "${HEADINGFULL}" | cut -c 1-5`
	NEWNAME=${SAT}_${MODE}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
	NAMING=`GetParamFromFile "Geoprojected products generic extension" geoProjectionParameters.txt ` # e.g. .UTM.100x100 (beware of starting dot !)
	
	POL=`GetParamFromFile "Master polarization channel" InSARParameters.txt `
	POLSLV=`GetParamFromFile "Slave polarization channel" InSARParameters.txt `
	
cd ${RUNDIR}/i12

# ensure that products are not renamed such as after a SinglePair processing. If so, cp it as default coh file name 
	if [ ${COH} == "YES" ] ; then 
		 COHFILE=`find ./InSARProducts -type f -name "coherence.??-??*" ! -name "*.ras*"` # search coh file but not raster nor sh
		 if [ -f "${COHFILE}" ] && [ -s "${COHFILE}" ] 
			then 
				if [ ${COHFILE} != "./InSARProducts/coherence.${POL}-${POLSLV}" ] 
					then 
						echo "Your files were renamed, probably because of a SinglePair processing. Need to recreate original naming befor coregistration"
						mv -f ${COHFILE} ./InSARProducts/coherence.${POL}-${POLSLV} 
				fi
		 fi
	fi
		# same for interf
	if [ ${RESINTERF} == "YES" ] ; then 
		  RESIDFILE=`find ./InSARProducts -type f -name "residualInterferogram.??-??*" ! -name "*.ras*" ! -name "*.f*"` # search coh file but not raster nor sh
		 if [ -f "${RESIDFILE}" ] && [ -s "${RESIDFILE}" ] 
			then 
				if [ ${RESIDFILE} != "./InSARProducts/residualInterferogram.${POL}-${POLSLV}" ] 
					then 
						mv -f ${RESIDFILE} ./InSARProducts/residualInterferogram.${POL}-${POLSLV} 
				fi
		 fi	
	fi			
		# interf.f
	if [ ${FILTINTERF} == "YES" ] ; then 
		 RESIDFILEFILT=`find ./InSARProducts -type f -name "residualInterferogram.??-??.f*" ! -name "*.ras*"` # search coh file but not raster nor sh
		 if [ -f "${RESIDFILEFILT}" ] && [ -s "${RESIDFILEFILT}" ]
			then 
				if [ ${RESIDFILEFILT} != "./InSARProducts/residualInterferogram.${POL}-${POLSLV}.f" ] 
					then 
						mv -f ${RESIDFILEFILT} ./InSARProducts/residualInterferogram.${POL}-${POLSLV}.f 
				fi
		 fi	
	fi
		# unwrappedPhase.VV-VV
	if [ ${UNWPHASE} == "YES" ] ; then 
		 UNWRFILE=`find ./InSARProducts -type f -name "unwrappedPhase.??-??.*" ! -name "*.ras*" ! -name "*.zoneMap*"` # search coh file but not raster nor sh
		 if [ -f "${UNWRFILE}" ] && [ -s "${UNWRFILE}" ] 
			then 
				if [ ${UNWRFILE} != "./InSARProducts/unwrappedPhase.${POL}-${POLSLV}" ] 
					then 
						mv -f ${UNWRFILE} ./InSARProducts/unwrappedPhase.${POL}-${POLSLV}
				fi
		 fi	
	fi
		# deformationMap.interpolated.flattened
	if [ ${DEFOMAP} == "YES" ] ; then 
		 DEFOINTFLATFILE=`find ./InSARProducts -type f -name "deformationMap.interpolated.flattened*" ! -name "*.ras*"` # search defo file but not raster nor sh
		 if [ -f "${DEFOINTFLATFILE}" ] && [ -s "${DEFOINTFLATFILE}" ] 
			then 
				if [ ${DEFOINTFLATFILE} != "./InSARProducts/deformationMap.interpolated.flattened" ] 
					then 
						mv -f ${DEFOINTFLATFILE} ./InSARProducts/deformationMap.interpolated.flattened
				fi
		 fi
		# deformationMap.interpolated 
		 DEFOINTFILE=`find ./InSARProducts -type f -name "deformationMap.interpolated*" ! -name "*.ras*" ! -name "*.flattened*"` # search defo file but not raster nor sh
		 if [ -f "${DEFOINTFILE}" ] && [ -s "${DEFOINTFILE}" ] 
			then 
				if [ ${DEFOINTFILE} != "./InSARProducts/deformationMap.interpolated" ] 
					then 
						mv -f ${DEFOINTFILE} ./InSARProducts/deformationMap.interpolated
				fi
		 fi	
		# deformationMap
		 DEFOFILE=`find ./InSARProducts -type f -name "deformationMap*" ! -name "*.ras*" ! -name "*.flattened*" ! -name "*.interpolated*"` # search defo file but not raster nor sh
		 if [ -f "${DEFOFILE}" ] && [ -s "${DEFOFILE}" ] 
			then 
				if [ ${DEFOFILE} != "./InSARProducts/deformationMap" ] 
					then 
						mv -f ${DEFOFILE} ./InSARProducts/deformationMap
				fi
		 fi	
		# may need to rename the others ? Renaming to be added here if needed
	fi


# All param updated. Run geocoding
	if [ ${RADIUSMETHD} == "LetCIS" ] 
		then
			# Let CIS Choose what is the best radius, that is 2 times the distance to the nearest neighbor
			geoProjection -rk ./TextFiles/geoProjectionParameters.txt	| tee -a ${LOGFILE}
		else 
			# Force radius: force radius to RADIUSMETHD times the distance to the nearest neighbor. Default value (i.e. LetCIS) is 2)
			geoProjection -rk -f=${RADIUSMETHD} ./TextFiles/geoProjectionParameters.txt	| tee -a ${LOGFILE}
	fi

			
if [ -f "${RUNDIR}/i12/InSARProducts/BAK_incidence" ] && [ -s "${RUNDIR}/i12/InSARProducts/BAK_incidence" ] 
	then 
		EchoTee "Will get back incidence file with original name"
		EchoTee ""
		mv ${RUNDIR}/i12/InSARProducts/BAK_incidence ${RUNDIR}/i12/InSARProducts/incidence 
fi


# Interpolate if needed
	# old rough method: interpolate all even if not requested
	# EchoTee "Interpolating all new deformationMap.*.bil files just in case you need it..."
	# EchoTee ""
	# # INTERPOLATE NEW FILES 
	# GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
	# GEOPIXL=`GetParamFromFile "Y size of geoprojected products" geoProjectionParameters.txt`
	# 
	# echo " GEOPIXW and GEOPIXL : ${GEOPIXW} ${GEOPIXL} "
	# 
	# 
	# for DEFOFILESTOINTERPOL in `ls ./GeoProjection/deformationMap.*.bil 2> /dev/null`
	# 	do
	# 		EchoTee "Interpolating ${DEFOFILESTOINTERPOL}..."
	# 		fillGapsInImage ${DEFOFILESTOINTERPOL} ${GEOPIXW} ${GEOPIXL}   
	# done

	GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
	GEOPIXL=`GetParamFromFile "Y size of geoprojected products" geoProjectionParameters.txt`

	if [ ${SKIPUW} == "SKIPyes" ] 
		then
			EchoTeeYellow "  // Skip interpolation AFTER geocoding..."
		else 
			if [ ${DEFOMAP} == "YES" ]
				then
					# Interpolation
					case ${INTERPOL} in 
						"AFTER")  
							if [ ${REMOVEPLANE} == "DETREND" ] 
									then 
										EchoTee "Request interpolation after geocoding."
										PATHDEFOGEOMAP=deformationMap.flattened.${PROJ}.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil
										fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
									else 
										EchoTee "Request interpolation after geocoding (no detrend)."
										PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil
										fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
							fi ;;
						"BOTH")  
							if [ ${REMOVEPLANE} == "DETREND" ] 
									then 
										EchoTee "Request interpolation before and after geocoding."
										PATHDEFOGEOMAP=deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil
										fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
									else 
										EchoTee "Request interpolation before and after geocoding (no detrend)."
										PATHDEFOGEOMAP=deformationMap.interpolated.${PROJ}.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil
										fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
							fi ;;
						"BEFORE") 
							EchoTee "Do not request interpolation after geocoding" 
							PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil	
							;;		
					esac
			fi
	fi


# DO THE RENAMING FILES HERE BELOW
# still in /i12 :
# Renaming
	 EchoTee "Updating  files if it were re-geocoded..."
	 EchoTee ""
	# # ensure that products are renamed as before 
	if [ ${COH} == "YES" ] ; then 
	 NRGEOC=`find ./GeoProjection -type f -name "coherence.${POL}-${POLSLV}*" ! -name "*.ras*" | wc -l` 
		 if [ ${NRGEOC} -gt 1 ] 
			then 
				# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
				OLDESTCOHFILE=`ls -lt ./GeoProjection/coherence.${POL}-${POLSLV}* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
				# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
		
				# get the youngest and rename it as the oldest
				NEWESTCOHFILE=`ls -lt ./GeoProjection/coherence.${POL}-${POLSLV}* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/

				if [ ${NEWESTCOHFILE} != ${OLDESTCOHFILE} ] 
					then 
						EchoTee "Regeocoded Coh with new parameters - name new file and keep original geocoded file. No raster prepared yet"
						mv ./${NEWESTCOHFILE} ./GeoProjection/coherence.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
						mv ./${NEWESTCOHFILE%.bil}.hdr ./GeoProjection/coherence.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
						# plot geocoded coherence
						MakeFigR ${GEOPIXW} 0,1 1.5 1.5 normal gray 1/1 r4 coherence.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME} 
					else 
						EchoTee "Regeocoded Coh with same parameters - remove older file and replace with new one. Keep header but not raster"
						mv -f ./${NEWESTCOHFILE} ./${OLDESTCOHFILE} 
						mv -f ./${OLDESTCOHFILE}.ras ./${OLDESTCOHFILE}_old.ras
						# plot geocoded coherence
				fi
		 fi
	fi

	if [ ${RESINTERF} == "YES" ] ; then 
	 NRGEOC=`find ./GeoProjection -type f -name "residualInterferogram.??-??*" ! -name "*.ras*" ! -name "*.f.*" | wc -l` 
		 if [ ${NRGEOC} -gt 1 ] 
			then 
				# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
				OLDEST=`ls -lt ./GeoProjection/residualInterferogram.??-??* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v "\.f\." | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
				# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
		
				# get the youngest and rename it as the oldest
				NEWEST=`ls -lt ./GeoProjection/residualInterferogram.??-??* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v "\.f\." | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
				if [ ${NEWEST} != ${OLDEST} ] 
					then 
						EchoTee "Regeocoded  Residual Interf withnew parameters - name new file and keep original geocoded file. No raster prepared yet"
						mv ./${NEWEST} ./GeoProjection/residualInterferogram.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
						#mv ./GeoProjection/residualInterferogram.${POL}-${POLSLV}.UTM.{GEOPIXSIZE}x${GEOPIXSIZE}.hdr ./GeoProjection/residualInterferogram.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
						mv ./${NEWEST%.bil}.hdr ./GeoProjection/residualInterferogram.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
						MakeFig ${GEOPIXW} 1.0 1.2 normal jet 1/1 r4 residualInterferogram.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
					else 
						EchoTee "Regeocoded  Residual Interf with same parameters - remove older file and replace with new one. Keep header but not raster"
						mv -f ./${NEWEST} ./${OLDEST} 
						mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
				fi	
		 fi
	fi
	
	if [ ${FILTINTERF} == "YES" ] ; then 
	 NRGEOC=`find ./GeoProjection -type f -name "residualInterferogram.??-??.f.*" ! -name "*.ras*" | wc -l` 
		 if [ ${NRGEOC} -gt 1 ] 
			then 
				# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
				OLDEST=`ls -lt ./GeoProjection/residualInterferogram.??-??.f.* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
				# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
		
				# get the youngest and rename it as the oldest
				NEWEST=`ls -lt ./GeoProjection/residualInterferogram.??-??.f.* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
				if [ ${NEWEST} != ${OLDEST} ] 
					then 
						EchoTee "Regeocoded  Residual Interf.f withnew parameters - name new file and keep original geocoded file. No raster prepared yet"
						mv ./${NEWEST} ./GeoProjection/residualInterferogram.${POL}-${POLSLV}.f.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
						#mv ./GeoProjection/residualInterferogram.${POL}-${POLSLV}.f.UTM.{GEOPIXSIZE}x${GEOPIXSIZE}.hdr ./GeoProjection/residualInterferogram.${POL}-${POLSLV}.f.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
						mv ./${NEWEST%.bil}.hdr ./GeoProjection/residualInterferogram.${POL}-${POLSLV}.f.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
						MakeFig ${GEOPIXW} 1.0 1.2 normal jet 1/1 r4 residualInterferogram.${POL}-${POLSLV}.f.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
					else 
						EchoTee "Regeocoded  Residual Interf.f with same parameters - remove older file and replace with new one. Keep header but not raster"
						mv -f ./${NEWEST} ./${OLDEST} 
						mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
				fi	
		 fi
	fi
		
	if [ ${UNWPHASE} == "YES" ] ; then 
	 NRGEOC=`find ./GeoProjection -type f -name "unwrappedPhase.??-??*" ! -name "*.ras*" ! -name "*.zoneMap*" | wc -l` 
		 if [ ${NRGEOC} -gt 1 ] 
			then 
				# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
				OLDEST=`ls -lt ./GeoProjection/unwrappedPhase.??-??* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".zoneMap" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
				# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
		
				# get the youngest and rename it as the oldest
				NEWEST=`ls -lt ./GeoProjection/unwrappedPhase.??-??* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".zoneMap" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
				if [ ${NEWEST} != ${OLDEST} ] 
					then 
						EchoTee "Regeocoded  unwrapped Phase withnew parameters - name new file and keep original geocoded file. No raster prepared yet"
						mv ./${NEWEST} ./GeoProjection/unwrappedPhase.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
						mv ./${NEWEST%.bil}.hdr ./GeoProjection/unwrappedPhase.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
						MakeFigNoNorm ${GEOPIXW} normal jet 4/4 r4 unwrappedPhase.${POL}-${POLSLV}.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
					else 
						EchoTee "Regeocoded  unwrapped Phase with same parameters - remove older file and replace with new one. Keep header but not raster"
						mv -f ./${NEWEST} ./${OLDEST} 
						mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
				fi	
		 fi
	fi
	
	if [ ${DEFOMAP} == "YES" ] ; then 
	 NRGEOC=`find ./GeoProjection -type f  -name "deformationMap*" ! -name "*.ras*" | wc -l` 

		if [ ${NRGEOC} -gt 1 ] 
			then 
				if [ ${REMOVEPLANE} == "DETREND" ] 
					then
							# deformationMap.interpolated.flattened
								# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
								OLDEST=`ls -lt ./GeoProjection/deformationMap.interpolated.flattened* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
						
								# get the youngest and rename it as the oldest
								NEWEST=`ls -lt ./GeoProjection/deformationMap.interpolated.flattened* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								if [ ${NEWEST} != ${OLDEST} ] 
									then 
										EchoTee "Regeocoded deformationMap.interpolated.flattened withnew parameters - name new file and keep original geocoded file. No raster prepared yet"
										mv ./${NEWEST} ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
										mv ./${NEWEST%.bil}.hdr ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
										MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
									else 
										EchoTee "Regeocoded deformationMap.interpolated.flattened with same parameters - remove older file and replace with new one. Keep header but not raster"
										mv -f ./${NEWEST} ./${OLDEST} 
										mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
								fi
							# deformationMap.interpolated	
								# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
								OLDEST=`ls -lt ./GeoProjection/deformationMap.interpolated* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".flattened" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
						
								# get the youngest and rename it as the oldest
								NEWEST=`ls -lt ./GeoProjection/deformationMap.interpolated* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".flattened" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								if [ ${NEWEST} != ${OLDEST} ] 
									then 
										EchoTee "Regeocoded deformationMap.interpolated withnew parameters - name new file and keep original geocoded file. No raster prepared yet"
										mv ./${NEWEST} ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
										mv ./${NEWEST%.bil}.hdr ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
										MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
									else 
										EchoTee "Regeocoded deformationMap.interpolated with same parameters - remove older file and replace with new one. Keep header but not raster"
										mv -f ./${NEWEST} ./${OLDEST} 
										mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
								fi
							# deformationMap			
								# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
								OLDEST=`ls -lt ./GeoProjection/deformationMap* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".interpolated" | ${PATHGNU}/grep -v ".flattened" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
						
								# get the youngest and rename it as the oldest
								NEWEST=`ls -lt ./GeoProjection/deformationMap* | ${PATHGNU}/grep -v ".interpolated" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".flattened" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								if [ ${NEWEST} != ${OLDEST} ] 
									then 
										EchoTee "Regeocoded deformationMap withnew parameters - name new file and keep original geocoded file. No raster prepared yet"
										mv ./${NEWEST} ./GeoProjection/deformationMap.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
										mv ./${NEWEST%.bil}.hdr ./GeoProjection/deformationMap.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
										MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
									else 
										EchoTee "Regeocoded deformationMap with same parameters - remove older file and replace with new one. Keep header but not raster"
										mv -f ./${NEWEST} ./${OLDEST} 
										mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
								fi
					else 						
 							# deformationMap.interpolated.*interpolated
 								# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
 								OLDEST=`ls -lt ./GeoProjection/deformationMap.interpolated.*.interpolated* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".flattened" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
 								# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
 						
 								# get the youngest and rename it as the oldest
 								NEWEST=`ls -lt ./GeoProjection/deformationMap.interpolated.*.interpolated* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".flattened" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
 								if [ ${NEWEST} != ${OLDEST} ] 
 									then 
 										EchoTee "Regeocoded deformationMap.interpolated.*.interpolated with new parameters - name new file and keep original geocoded file. No raster prepared yet"
 										mv ./${NEWEST} ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}
 										#mv ./${NEWEST%.bil}.hdr ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}.hdr
										# hdr does not exist. Get the one from deformationMap
										NEWDEFOMAPHDR=`ls -lt ./GeoProjection/deformationMap* | ${PATHGNU}/grep -v ".interpolated" | ${PATHGNU}/grep -v ".flattened" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
 										cp ${NEWDEFOMAPHDR} ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}.hdr
 										MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}
 									else 
 										EchoTee "Regeocoded deformationMap.interpolated.*.interpolated with same parameters - remove older file and replace with new one. Keep header but not raster"
 										mv -f ./${NEWEST} ./${OLDEST} 
 										mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
 								fi
							# deformationMap.interpolated	
								# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
								OLDEST=`ls -lt ./GeoProjection/deformationMap.interpolated* | ${PATHGNU}/grep -v "bil.interpolated" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".flattened" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
						
								# get the youngest and rename it as the oldest
								NEWEST=`ls -lt ./GeoProjection/deformationMap.interpolated* | ${PATHGNU}/grep -v "bil.interpolated" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".flattened" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								if [ ${NEWEST} != ${OLDEST} ] 
									then 
										EchoTee "Regeocoded deformationMap.interpolated withnew parameters - name new file and keep original geocoded file. No raster prepared yet"
										mv ./${NEWEST} ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
										mv ./${NEWEST%.bil}.hdr ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
										MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
									else 
										EchoTee "Regeocoded deformationMap.interpolated with same parameters - remove older file and replace with new one. Keep header but not raster"
										mv -f ./${NEWEST} ./${OLDEST} 
										mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
								fi
							# deformationMap			
								# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
								OLDEST=`ls -lt ./GeoProjection/deformationMap* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".interpolated" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".flattened" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
						
								# get the youngest and rename it as the oldest
								NEWEST=`ls -lt ./GeoProjection/deformationMap* | ${PATHGNU}/grep -v ".interpolated" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".flattened" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
								if [ ${NEWEST} != ${OLDEST} ] 
									then 
										EchoTee "Regeocoded deformationMap withnew parameters - name new file and keep original geocoded file. No raster prepared yet"
										mv ./${NEWEST} ./GeoProjection/deformationMap.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
										mv ./${NEWEST%.bil}.hdr ./GeoProjection/deformationMap.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
										MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
									else 
										EchoTee "Regeocoded deformationMap with same parameters - remove older file and replace with new one. Keep header but not raster"
										mv -f ./${NEWEST} ./${OLDEST} 
										mv -f ./${OLDEST}.ras ./${OLDEST}_old.ras
								fi	
								
							while true; do
							    read -p "Do you want to create fake detrended (.flattened) files (use with caution !) ? [y/n] "  yn
							    case $yn in
							        [Yy]* ) 
							        	echo "OK, let's go."
							        	cp ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME} ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME} 
							        	cp ./GeoProjection/deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME} ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME} 
							        	
							        	# hdr does not exist. Get the one from deformationMap
										NEWDEFOMAPHDR=`ls -lt ./GeoProjection/deformationMap* | ${PATHGNU}/grep -v ".interpolated" | ${PATHGNU}/grep -v ".flattened" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
 										cp ${NEWDEFOMAPHDR} ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}.hdr
 										cp ${NEWDEFOMAPHDR} ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}.hdr
										MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}
							     	    MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}
							     	    echo "BEWARE: the file deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME} is a fake. " > ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}_ReadMe.txt
							     	    echo "        It is only a copy of deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME} " >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}_ReadMe.txt
							     	    echo "        created to be added e.g. in the DefoInterpolx2Detrend mode of for time series" >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}_ReadMe.txt
							     	    echo "        " >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}_ReadMe.txt
							     	    echo "        This may be useful when a pair is manually recomputed with recursive snpahu " >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}_ReadMe.txt
							     	    echo "        because defo is too big for classical unwrapping, then re-injected in classical mass processing results directories for time series " >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME}_ReadMe.txt

							     	    echo "BEWARE: the file deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME} is a fake. " > ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}_ReadMe.txt
							     	    echo "        It is only a copy of deformationMap.interpolated.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil.interpolated_${NEWNAME} " >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}_ReadMe.txt
							     	    echo "        created to be added e.g. in the DefoInterpolx2Detrend mode of for time series" >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}_ReadMe.txt
							     	    echo "        " >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}_ReadMe.txt
							     	    echo "        This may be useful when a pair is manually recomputed with recursive snpahu " >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}_ReadMe.txt
							     	    echo "        because defo is too big for classical unwrapping, then re-injected in classical mass processing results directories for time series " >> ./GeoProjection/deformationMap.interpolated.flattened.UTM.${GEOPIXSIZERG}x${GEOPIXSIZEAZ}.bil_${NEWNAME}_ReadMe.txt
							     	    break ;;
							        [Nn]* ) 
							       		echo "OK... I was just asking."
								        break ;;
							        * ) 
							        	echo "Please answer yes or no.";;
							    esac
							done
				fi
		fi
	fi	
	
	
	
	
	
	
	
	
	
	
	
	
	
