#!/bin/bash
# Script aims at geocoding all and only the products with name starting by the string "REGEOC" 
# that are located in the InSARProducts directory. Files are expected to be of the same size as 
# original products from the InSAR processing. They are supposed to be of the same type and
# size as the amplitude images (.mod) from the original processing. 
#
# It will read the geoProjectionParameters.txt to get the size etc. as well as the 
# LaunchMTparam.txt provided as a parameter to know the details of the geocoding you want. 
# Note that it only processes UTM geoprojection here, but it easy to convert in Lat Long 
#      e.g. with gdal. 
# 
# The script expects 
#	- in /InSARProducts, the file(s) named "REGEOC_whatever_you_want". 
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
#						- Remind to remove former REGEOCO_ products in GeoProjection if run several times the script 
# New in Distro V 1.3:	- read UTM zone for geocoding
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
echo " "

PARAMFILE=$1	# File with the parameters needed for the run

source ${PATH_SCRIPTS}/SCRIPTS_MT/FUNCTIONS_FOR_MT.sh

# test if REGEOC_ files exist
if [ `find ./i12/InSARProducts -maxdepth 1 -type f -name "REGEOC*" | wc -l` -eq 0 ] ; then 
	echo "No REGEOC_... files in InSARProducts to regeocode; exit..."
	exit 0
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

# get AZSAMP. Attention, needs original az sampling
	MASDATE=`basename ${RUNDIR} | cut -d _ -f 1`
	SLVDATE=`basename ${RUNDIR} | cut -d _ -f 2`
	MASNAME=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${MASDATE} | ${PATHGNU}/grep -v ".txt" | cut -d . -f 1` 	
	KEY=`echo "Azimuth sampling [m]" | tr ' ' _`
	parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${MASNAME}.csl/Info/SLCImageInfo.txt
	AZSAMP=`updateParameterFile ${parameterFilePath} ${KEY}` # not rounded

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

# Some fcts
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
		"SLCImageInfo.txt") parameterFilePath=${MASTERPATH}/Info/SLCImageInfo.txt ;;
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt ;;
		"masterSLCImageInfo.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/masterSLCImageInfo.txt;; 
	esac
	updateParameterFile ${parameterFilePath} ${KEY}
	}

# Re-geocode (only the REGEOC_ file(s))
	cd  ${RUNDIR}/i12/TextFiles

	# Update geoProjectionParameters.txt TextFile
	cp -n ${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt ${RUNDIR}/i12/TextFiles/geoProjectionParameters_ORIGINAL.txt

	# Update which products to geocode

	PIXSIZEAZ=`echo " ( ${AZSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
	EchoTee " PIXSIZEAZ is ${PIXSIZEAZ} from ( AZSAMP${AZSAMP} / ZOOM${ZOOM} ) * INTERFML${INTERFML} "
	
	GEOPIXSIZERND=`echo ${PIXSIZEAZ} | cut -d . -f1`		
	EchoTee "Rounded PIXSIZEAZ is ${GEOPIXSIZERND}"

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
		EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
		;;
		"Auto") 
		EchoTeeYellow "Automatic geocoded pixel size determination."
		EchoTeeYellow "          Will get the closest (upper) multiple of 10 of multilooked original pixel size. " 
		EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 	
		GEOPIXSIZE=${GEOPIXSIZE10}
		EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
		;;
		"Forced") 
		# Possibly force UTM coordinates of geocoded products (convenient for further MSBAS)
		GEOPIXSIZE=${FORCEGEOPIXSIZE}    					# Give the sampling rate here of what you want for your final MSBAS database
		EchoTeeYellow "Forced geocoded pixel size determination. " 
		EchoTeeYellow "Assigned ${GEOPIXSIZE} m. Will also force the limits of the geocoded files."
		EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 	
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
		;;
		*) 
		EchoTeeYellow "Not sure what you wanted => used Closest..." 
		GEOPIXSIZE=`echo ${PIXSIZEAZ} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
		EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
		;;
	esac

	# Change default parameters : Geoprojected products generic extension 
	# Set everything to NO except Master amplitude tricked as REGEOC_
	ChangeParam "Geoproject master amplitude" ${MASAMPL} geoProjectionParameters.txt 
	# Need to change amplitude file name
	# In order to geocode all files starting by REGEOCODE, one must at least provide 
	# the path to an existing file starting with REGEOC
	ONEREGEOCFILE=`ls ${RUNDIR}/i12/InSARProducts/REGEOC* | grep -v ".ras" | grep -v ".hdr" | head -1`
	ChangeParam "Reduced master amplitude image file path" "${ONEREGEOCFILE}"  InSARParameters.txt

	ChangeParam "Geoprojected products generic extension" ".UTM.${GEOPIXSIZE}x${GEOPIXSIZE}" geoProjectionParameters.txt
	ChangeParam "Easting sampling" ${GEOPIXSIZE} geoProjectionParameters.txt 
	ChangeParam "Northing sampling" ${GEOPIXSIZE} geoProjectionParameters.txt
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