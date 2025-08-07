#!/bin/bash
# Script aims at geocoding all and only the products with name starting by the string "REGEOC." 
# that are located in the InSARProducts directory. Files are expected to be of the same size as 
# original products from the InSAR processing. They are supposed to be of the same type and
# size as the amplitude images (.mod) from the original processing. 
#  Remember, the recomputed interf ML will be computed on zommed pixel (if applicable) !  Zoom can not be changed. 
#
# It will read the geoProjectionParameters.txt to get the size etc. as well as the 
# LaunchMTparam.txt provided as a parameter to know the details of the geocoding you want. 
# Note that it only processes UTM geoprojection here, but it easy to convert in Lat Long 
#      e.g. with gdal. 
# 
# The script expects 
#	- in /InSARProducts, the file(s) named "REGEOC.whatever_you_want". 
#	- a LaunchParam file to assess how to re-geocode. 
#     Size of pixel or method can hence be changed or it can be done based on a kml.
#
# Need to be run in dir where SinglePair.sh was run. 
#
# NOTE: if performing several times the same re-geoproj, remember to delete all REGEOC
#			products in GeoProjection (because the hdr might not be overwitten)
#
# Parameters:	- File with the parameters needed for the run (LaunchMTParam.txt)
#
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- FUNCTIONS_FOR_MT.sh
#				- bc
#
# New in Distro V 1.0:	- Based on ReGeocode_ManuallyUnwrapped_SinglePair.sh
# New in Distro V 1.1:	- more robust search for MASNAME
# New in Distro V 1.2:	- replace if -s as -f -s && -f to be compatible with mac os if  
#						- Remind to remove former REGEOCO. products in GeoProjection if run several times the script 
# New in Distro V 1.3:	- read UTM zone for geocoding
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.0 20240123:	- script unchanged but state that the products muste be 
#							 	  named REGEOC.something instead of REGEOC_something to ensure
#								  that they will all be re-geocoded whatever their name. 
# New in Distro V 3.1 20240228:	- Fix rounding pix size when smaller than one by allowing scale 5 before division  
# New in Distro V 3.2 20250227:	- replace cp -n with if [ ! -e DEST ] ; then cp SRC DEST ; fi 
# New in Distro V 3.3 20250521:	- allows re-geocoding of S1 WideSwath zoomed images. 
#								- allows changing pixel shape 
#									It can't change the zoom factor though in case of S1 WS. 
# New in Distro V 3.4 20250627:	- Erroneous ChangeGeocParam instead of ChangeParam in removing kml just in case in Closest and Auto 
# New in Distro V 3.5 20250804:	- Correct checking unchanged zoom factor  

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.5 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 04, 2025"

echo "${PRG} ${VER}, ${AUT}"
echo " "

PARAMFILE=$1	# File with the parameters needed for the run

source ${PATH_SCRIPTS}/SCRIPTS_MT/FUNCTIONS_FOR_MT.sh

# test if REGEOC_ files exist
if [ `find ./i12/InSARProducts -maxdepth 1 -type f -name "REGEOC*" 2>/dev/null | wc -l` -eq 0 ] ; then 
	echo "No REGEOC... files in InSARProducts to regeocode; exit..."
	exit 0
fi

# test if S1 zoomed image files exist
if [ `find ./i12.NoZoom/TextFiles -maxdepth 1 -type f -name "InSARParameters.txt" 2>/dev/null | wc -l` -eq 1 ] ; then 
	echo "Re-geocoding Sentinel 1 wide swath zoomed image; need to get SLC info from ./i12.NoZoom"
	S1WSZOOM="Yes"
fi


# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

FIG=`GetParam "FIG,"`

PIXSHAPE=`GetParam "PIXSHAPE,"`				# PIXSHAPE, pix shape for products : SQUARE or ORIGINALFORM   

ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
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

RADIUSMETHD=`GetParam "RADIUSMETHD,"`		# LetCIS (CIS will compute best radius) or forced to a given radius 
	
FORCEGEOPIXSIZE=`GetParam "FORCEGEOPIXSIZE,"` # Pixel size (in m) wanted for your final products. Required for MSBAS

UTMZONE=`GetParam "UTMZONE,"`				# UTMZONE, letter of row and nr of col of the zone where coordinates below are computed (e.g. U32)

XMIN=`GetParam "XMIN,"`						# XMIN, minimum X UTM coord of final Forced geocoded product
XMAX=`GetParam "XMAX,"`						# XMAX, maximum X UTM coord of final Forced geocoded product
YMIN=`GetParam "YMIN,"`						# YMIN, minimum Y UTM coord of final Forced geocoded product
YMAX=`GetParam "YMAX,"`						# YMAX, maximum Y UTM coord of final Forced geocoded product
GEOCKML=`GetParam "GEOCKML,"`				# GEOCKML, a kml file to define final geocoded product. If not found, it will use the coordinates above

DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 
SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)

RUNDIR="$(pwd)"
BASEDIRNAME=`dirname ${RUNDIR}`
BASEDIRNAME2=`dirname ${BASEDIRNAME}`

MODE="${BASEDIRNAME##*/}"

# Some fcts
############

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
		"InSARParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/InSARParameters.txt;;
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt;;
		"NoZoom_InSARParameters.txt") parameterFilePath=${RUNDIR}/i12.NoZoom/TextFiles/InSARParameters.txt;;
		"NoZoom_geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/i12.NoZoom/TextFiles/geoProjectionParameters.txt;;

	esac

	ORIGINAL=`updateParameterFile ${parameterFilePath} ${KEY} ${NEW}`
	EchoTee "=> Change in ${parameterFilePath}"
	EchoTee "...Key = ${CRITERIA} "
	EchoTee "...Former Value =  ${ORIGINAL}"
	EchoTee "    --> New Value =  ${NEW}  \n"
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
		"SLCImageInfo.txt") parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${MASNAME}.csl/Info/SLCImageInfo.txt ;;				
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt ;;
		"masterSLCImageInfo.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/masterSLCImageInfo.txt;; 

		"NoZoom_masterSLCImageInfo.txt") parameterFilePath=${RUNDIR}/i12.NoZoom/TextFiles/masterSLCImageInfo.txt;; 

	esac
	updateParameterFile ${parameterFilePath} ${KEY}
	}

# Compute Ratio

# get AZSAMP. Attention, needs original az sampling
	#MASDATE=`basename ${RUNDIR} | cut -d _ -f 1`
	#SLVDATE=`basename ${RUNDIR} | cut -d _ -f 2`
	# get it from InSARParameters.txt for more robustness
	MASPATH=`GetParamFromFile "Master image file path" InSARParameters.txt`
	SLVPATH=`GetParamFromFile "Slave image file path" InSARParameters.txt`

	TMPMASNAME=$(basename "$MASPATH")
	MASDATE=$(echo "$TMPMASNAME" | ${PATHGNU}/grep -oE '[0-9]{8}')
	TMPSLVNAME=$(basename "$SLVPATH")
	SLVDATE=$(echo "$TMPSLVNAME" | ${PATHGNU}/grep -oE '[0-9]{8}')
	
	MASNAME=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${MASDATE} | ${PATHGNU}/grep -v ".txt" | cut -d . -f 1` 	

	if [ "${S1WSZOOM}" == "Yes" ]
		then 
			# Get param from NoZoom image
			AZSAMP=`GetParamFromFile "Azimuth sampling [m]" NoZoom_masterSLCImageInfo.txt`
			RGSAMP=`GetParamFromFile "Range sampling [m]" NoZoom_masterSLCImageInfo.txt`
			INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" NoZoom_masterSLCImageInfo.txt` # not rounded

		else 
			#KEY=`echo "Azimuth sampling [m]" | tr ' ' _`
			#parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${MASNAME}.csl/Info/SLCImageInfo.txt
			#AZSAMP=`updateParameterFile ${parameterFilePath} ${KEY}` # not rounded
			AZSAMP=`GetParamFromFile "Azimuth sampling [m]" SLCImageInfo.txt`
			RGSAMP=`GetParamFromFile "Range sampling [m]" SLCImageInfo.txt`
			INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" SLCImageInfo.txt` # not rounded

	fi

	EchoTee "Range sampling : ${RGSAMP}"
	EchoTee "Azimuth sampling : ${AZSAMP}"
	EchoTee "Incidence angle : ${INCIDANGL}"

	RATIO=`echo "scale=2; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l | xargs printf "%.*f\n" 0` # with two digits and rounded to 0th decimal
	RATIOREAL=`echo "scale=5; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l` # with 5 digits 


# Get AZML and RGML 
	RatioPix ${INTERFML}

	# Check which one is the largest
	ROUNDEDAZSAMP=`echo ${AZSAMP} | xargs printf "%.*f\n" 0`  # (AzPixSize) rounded to 0th digits precision
	ROUNDEDRGSAMP=`echo ${RGSAMP} | xargs printf "%.*f\n" 0`  # (RgPixSize) rounded to 0th digits precision
		if [ ${ROUNDEDAZSAMP} -ge ${ROUNDEDRGSAMP} ]
			then 
				PIXSIZEAZ=`echo "scale=5; ( ${AZSAMP}) * ${AZML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
				PIXSIZERG=`echo "scale=5; ( ${RGSAMP} ) * ${RGML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
				eval PIXSIZEAZORIGINAL=${PIXSIZEAZ} # needed in the specific case of asymetric zoom making square pix despite ORIGINALFORM 
	
				# largest is AZ
				EchoTee " Largest PIXSIZE is ${PIXSIZEAZ} from AZSAMP${AZSAMP} * INTERFML${AZML} "
			else 
				PIXSIZEAZ=`echo "scale=5; ( ${AZSAMP}) * ${AZML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
				PIXSIZERG=`echo "scale=5; ( ${RGSAMP} ) * ${RGML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
				
				# largest is RG
				EchoTee " Largest PIXSIZE is ${PIXSIZERG} from RGSAMP${RGSAMP} * INTERFML${RGML} "
				eval PIXSIZEAZORIGINAL=${PIXSIZEAZ}

				EchoTee " PIXSIZEAZ is ${PIXSIZEAZORIGINAL} from AZSAMP${AZSAMP} * INTERFML${AZML} "
				# from now on, the largest pixel is named AZ... even if it is RG - Yes it is uggly but changing the name could have too much impact in other scripts
				if [ "${PIXSHAPE}" != "ORIGINALFORM" ] ; then 
					PIXSIZEAZ=${PIXSIZERG}
				fi
		fi

#####

# set files to geocode - only Master amplitude as files named REGEOC_
   DEFOMAP="NO"
   MASAMPL="YES"
   SLVAMPL="NO"
   COH="NO"
   INTERF="NO"
   FILTINTERF="NO"
   RESINTERF="NO"
   UNWPHASE="NO"
   INCIDENCE="NO"
  
# do not re-geocode incidence angles
if [ -f ${RUNDIR}/i12/InSARProducts/incidence ] ; then 
	mv ${RUNDIR}/i12/InSARProducts/incidence ${RUNDIR}/i12/incidence
fi

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


# Re-geocode (only the REGEOC_ file(s))
	cd  ${RUNDIR}/i12/TextFiles

	# Update geoProjectionParameters.txt TextFile
	#cp -n ${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt ${RUNDIR}/i12/TextFiles/geoProjectionParameters_ORIGINAL.txt
	if [ ! -e "${RUNDIR}/i12/TextFiles/geoProjectionParameters_ORIGINAL.txt" ] ; then cp "${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt" "${RUNDIR}/i12/TextFiles/geoProjectionParameters_ORIGINAL.txt" ; fi 
	
	# Update which products to geocode
####
####	PIXSIZEAZ=`echo "scale=5; ( ${AZSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
####	EchoTee " PIXSIZEAZ is ${PIXSIZEAZ} from ( AZSAMP${AZSAMP} / ZOOM${ZOOM} ) * INTERFML${INTERFML} "
	# Test if Zoom is one value or two
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
	
			#EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
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
			ChangeParam "Path to a kml file defining the geoProjection area" "None" geoProjectionParameters.txt
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
			ChangeParam "Path to a kml file defining the geoProjection area" "None" geoProjectionParameters.txt
			ChangeParam "xMin" 0 geoProjectionParameters.txt
			ChangeParam "xMax" 0 geoProjectionParameters.txt
			ChangeParam "yMin" 0 geoProjectionParameters.txt
			ChangeParam "yMax" 0 geoProjectionParameters.txt
	
			#EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
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
			GEOPIXSIZENAME=${GEOPIXSIZE}x${GEOPIXSIZE}
			EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
			;;
	esac

	# Change default parameters : Geoprojected products generic extension 
	# Set everything to NO except Master amplitude tricked as REGEOC.
	ChangeParam "Geoproject master amplitude" ${MASAMPL} geoProjectionParameters.txt 
	# Need to change amplitude file name
	# In order to geocode all files starting by REGEOCODE, one must at least provide 
	# the path to an existing file starting with REGEOC
	#ONEREGEOCFILE=`ls ${RUNDIR}/i12/InSARProducts/REGEOC* | ${PATHGNU}/grep -v "\.ras$" | grep -v ".hdr" | head -1`	# \.ras$ means .ras at the end... 
	ONEREGEOCFILE=`find "${RUNDIR}/i12/InSARProducts/" -name 'REGEOC*' -type f ! -name '*.ras' ! -name '*.hdr' | head -n 1`


	ChangeParam "Reduced master amplitude image file path" "${ONEREGEOCFILE}"  InSARParameters.txt

	ChangeParam "Geoprojected products generic extension" ".UTM.${GEOPIXSIZENAME}" geoProjectionParameters.txt
	ChangeParam "Easting sampling" ${GEOPIXSIZERG} geoProjectionParameters.txt 
	ChangeParam "Northing sampling" ${GEOPIXSIZEAZ} geoProjectionParameters.txt
	ChangeParam "Geoproject measurement" ${DEFOMAP} geoProjectionParameters.txt
	ChangeParam "Geoproject slave amplitude" ${SLVAMPL} geoProjectionParameters.txt
	ChangeParam "Geoproject coherence" ${COH} geoProjectionParameters.txt 
	ChangeParam "Geoproject interferogram" ${INTERF} geoProjectionParameters.txt 
	ChangeParam "Geoproject filtered interferogram" ${FILTINTERF} geoProjectionParameters.txt 
	ChangeParam "Geoproject residual interferogram" ${RESINTERF} geoProjectionParameters.txt 
	ChangeParam "Geoproject unwrapped phase" ${UNWPHASE} geoProjectionParameters.txt 

	ChangeParam "Resampling method" ${RESAMPMETHD} geoProjectionParameters.txt
	
	ChangeParam "Weighting method" ${WEIGHTMETHD} geoProjectionParameters.txt
	ChangeParam "ID smoothing factor" ${IDSMOOTH} geoProjectionParameters.txt
	ChangeParam "ID weighting exponent" ${IDWEIGHT} geoProjectionParameters.txt
	ChangeParam "FWHM : Lorentzian Full Width at Half Maximum" ${FWHM} geoProjectionParameters.txt
	# Since 2020 01 21 MasTer Engine masking method is defined by either "mask" (all method but CIS) or "zoneMap" (for CIS in topo mode); no more path to mask
	# In cas eof Snaphu or DetPhun, no need to change here below
	# ChangeParam "Mask " ${PATHTOMASK} geoProjectionParameters.txt
	ChangeParam "Zone index" ${ZONEINDEX} geoProjectionParameters.txt

	# Apply mask with AMSTer Engine V > 20241127	
	if [ "${APPLYMASK}" == "APPLYMASKyes" ] && grep -q "Masking: Use of slant range mask or zoneMap for measurement geo-projection" "${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt"
		then 
			ChangeParam "Masking: Use of slant range mask or zoneMap for measurement geo-projection ([mask] or [zoneMap])" mask geoProjectionParameters.txt
	fi 

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
      		 		ChangeParam "Masking: Use of slant range mask or zoneMap for measurement geo-projection ([mask] or [zoneMap])" mask geoProjectionParameters.txt
      		 	else
      		 		ChangeParam "Masking: Use of slant range mask or zoneMap for measurement geo-projection ([mask] or [zoneMap])" zoneMap geoProjectionParameters.txt
			fi
			# ChangeParam "Mask " zoneMap geoProjectionParameters.txt
	fi
		
cd ${RUNDIR}/i12

# All param updated. Run geocoding
	if [ ${RADIUSMETHD} == "LetCIS" ] 
		then
			# Let CIS Choose what is the best radius, that is 2 times the distance to the nearest neighbor
			geoProjection -rk ./TextFiles/geoProjectionParameters.txt	
		else 
			# Force radius: force radius to RADIUSMETHD times the distance to the nearest neighbor. Default value (i.e. LetCIS) is 2)
			geoProjection -rk -f=${RADIUSMETHD} ./TextFiles/geoProjectionParameters.txt	
	fi
 			
# do not re-geocode incidence angles
if [ -f ${RUNDIR}/i12/incidence ] ; then 
	mv ${RUNDIR}/i12/incidence ${RUNDIR}/i12/InSARProducts/incidence
fi 

# Make figs 
cd ${RUNDIR}/i12/GeoProjection

GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`

for REGEOCFILES in `ls REGEOC* | grep -v ".hdr" | grep -v ".ras" | grep -v ".xml"`
do 
	MakeFigNoNorm ${GEOPIXW} normal gray 1/1 r4 ${REGEOCFILES}
done