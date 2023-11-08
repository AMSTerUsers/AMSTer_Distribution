#!/bin/bash
# Script aims at geocoding the unwrapped phase of a SinglePair processing and where  
# the Unwrapped phase was manually recomputed e.g. by itterative procedure as proposed by 
# J-L Froger.  
# The script expects 
#	- in /InSARProducts, the Unwrapped phase (from Matlab code) names as unwrappedPhase 
#	  (without polarisations). InSARParameters.txt must be updated accordingly.
#	- the number of lines and columns of Unwrapped file issued by the Matlab code IS ALWAYS even.
#     If these numbers in the orgininal file were not the even, InSARParameters.txt 
#	  must be updated accordingly.
#	- the script reads the LaunchParam file to see if it must Detrend and/or Interpolate 
#	  the deformation map.
# Note that before reprocessing the phase-to-height convertion and geocoding, the former
#	results are moved in a directory one level ABOVE InSARProducts and GeoProjection named 
#	ORIGINAL.  
# The script reads again the LaunchParam file to assess how to re-geocode. 
# Size of pixel or method can hence be changed or it can be done based on a kml.
#
# Note : only verified for interpolation BOTH and with detrend !
#
#  !!!!! WARNING: only tested for S1 so far and not in STRIPMAP !!!!!
#
# Need to be run in dir where SinglePair.sh was run
#
# Parameters:	- File with the parameters needed for the run (LaunchMTparam.txt)
#
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- FUNCTIONS_FOR_MT.sh
#				- bc
#				- byte2Float.py
#
# New in Distro V 1.0:	- Based on ReGeocode_FromSinglePair.sh and ReUnwrap_SingelPair.sh
# New in Distro V 1.1:	- get proper hdr for re geocoded defo interpx2 flatten in case of re-geocoding with different options
# New in Distro V 1.2: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 1.3: - uncomment accidentally commented lines about cropping mask
# New in Distro V 1.4: 	- read UTM zone for geocoding
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 2.1 20231002:	- compatible with new multi-mevel masks where 0 = non masked and 1 or 2 = masked  
#								- add fig snaphuMask and keep copy of unmasked defo map fig
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

POP=`GetParam "POP,"`						# POP, option to pop up figs or not (POPno or POPyes)

PROCESSMODE=`GetParam "PROCESSMODE,"`		# PROCESSMODE, DEFO to produce DInSAR or TOPO to produce DEM

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
 else 
  PATHTOMASK=`echo "NoMask"`
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


# Will geocode only the deformation maps and unwrapped phase
#  		DEFOMAP	MASAMPL	SLVAMPL	COH	INTERF	FILTINTERF	RESINTERF	UNWPHASE INCIDENCE 
FILESTOGEOC="YES NO NO NO NO NO NO YES NO"


RUNDIR="$(pwd)"
BASEDIRNAME=`dirname ${RUNDIR}`
BASEDIRNAME2=`dirname ${BASEDIRNAME}`

MODE="${BASEDIRNAME##*/}"
SAT=DRC_"${BASEDIRNAME2##*/}"

# get AZSAMP. Attention, needs original az sampling
	MASDATE=`basename ${RUNDIR} | cut -d _ -f 1`
	SLVDATE=`basename ${RUNDIR} | cut -d _ -f 2`
	MASNAME=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${MASDATE} | cut -d . -f 1` 	
	KEY=`echo "Azimuth sampling [m]" | tr ' ' _`
	parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${MASNAME}.csl/Info/SLCImageInfo.txt
	AZSAMP=`updateParameterFile ${parameterFilePath} ${KEY}` # not rounded

# set files to geocode
   DEFOMAP=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $1}'`
   MASAMPL=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $2}'`
   SLVAMPL=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $3}'`
   COH=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $4}'`
   INTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $5}'`
   FILTINTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $6}'`
   RESINTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $7}'`
   UNWPHASE=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $8}'`
   INCIDENCE=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $9}'`

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

function RenameAllProducts()
	{
	unset FILE 
	local FILE
	#for FILE in `ls | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".rev" | ${PATHGNU}/grep -v "xRef" | ${PATHGNU}/grep -v "yRef" | ${PATHGNU}/grep -v "xRadius" | ${PATHGNU}/grep -v "yRadius" | ${PATHGNU}/grep -v "projMat"`
	#for FILE in `ls | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".rev" | ${PATHGNU}/grep -v "xRef" | ${PATHGNU}/grep -v "yRef" | ${PATHGNU}/grep -v "xRadius" | ${PATHGNU}/grep -v "yRadius" | ${PATHGNU}/grep -v "projMat"`
	for FILE in `ls | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".rev" | ${PATHGNU}/grep -v "xRef" | ${PATHGNU}/grep -v "yRef" | ${PATHGNU}/grep -v "xRadius" | ${PATHGNU}/grep -v "yRadius" | ${PATHGNU}/grep -v "projMat" | ${PATHGNU}/grep -v "deg"` # ${PATHGNU}/grep -v deg avoid files aleady renamed
	do
		FILENOEXT=`echo "${FILE}" |  ${PATHGNU}/gawk '{gsub(/.*[/]|[.]{1}[^.]+$/, "", $0)} 1'`
		FILEEXT=`echo "${FILE}" |  ${PATHGNU}/gawk -F'[.]' '{print $NF}'`
		case ${FILEEXT} in 
			"bil")
				mv ${FILE} ${FILENOEXT}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg ;;
			"ras")
				mv ${FILE} ${FILENOEXT}_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.ras ;;
			"hdr")
				mv ${FILE} ${FILENOEXT}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr ;;
			"interpolated")
				mv ${FILE} ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
				# get any existing hdr and adapt it 
				FORMERHDR=`ls *.hdr | head -1`
				cp ${FORMERHDR} ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
				${PATHGNU}/gsed -i "/Description/c\Description = {${FILENOEXT}.interpolated" ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr ;;
			"flattened")
				mv ${FILE} ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
				# get any existing hdr and adapt it 
				FORMERHDR=`ls *.hdr | head -1`
				cp ${FORMERHDR} ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
				${PATHGNU}/gsed -i "/Description/c\Description = {${FILENOEXT}.flattened" ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr ;;

		esac		
	done 
	}

# First move former results in ../ORIGINAL
	mkdir -p ${RUNDIR}/i12/ORIGINAL
	mkdir -p ${RUNDIR}/i12/ORIGINAL/InSARProducts
	mkdir -p ${RUNDIR}/i12/ORIGINAL/GeoProjection
			
	echo "Move former results in /i12/ORIGINAL:" 
	echo "  InSARProducts..."
		mv -f ${RUNDIR}/i12/InSARProducts/incidence* ${RUNDIR}/i12/ORIGINAL/InSARProducts/ 2>/dev/null
		mv -f ${RUNDIR}/i12/InSARProducts/deformationMap* ${RUNDIR}/i12/ORIGINAL/InSARProducts/ 2>/dev/null
		mv -f ${RUNDIR}/i12/InSARProducts/unwrappedPhase.??-??* ${RUNDIR}/i12/ORIGINAL/InSARProducts/ 2>/dev/null
	echo "  GeoProjection..."		
		mv -f ${RUNDIR}/i12/GeoProjection/deformationMap* ${RUNDIR}/i12/ORIGINAL/GeoProjection/ 2>/dev/null
		mv -f ${RUNDIR}/i12/GeoProjection/unwrappedPhase* ${RUNDIR}/i12/ORIGINAL/GeoProjection/ 2>/dev/null
		# remove possible existing old Projection Map
		rm -f ${RUNDIR}/i12/GeoProjection/projMat.UTM.* 2>/dev/null
echo ""

# Update InSARParameters.txt TextFile
	cp -n ${RUNDIR}/i12/TextFiles/InSARParameters.txt ${RUNDIR}/i12/TextFiles/InSARParameters_ORIGINAL.txt
	ChangeParam "Unwrapped phase file path" ${RUNDIR}/i12/InSARProducts/unwrappedPhase InSARParameters.txt
	# check even lines and columns
	NLINES=`GetParamFromFile "Unwrapped phase range dimension [pix]" InSARParameters.txt`
	NCOL=`GetParamFromFile "Unwrapped phase azimuth dimension [pix]" InSARParameters.txt`

	if [ $((NLINES%2)) -eq 0 ]
	then
	  echo "Number of lines is even => OK"
	else
	  echo "Number of lines is odd => Number of lines -1"
	  mv ${RUNDIR}/i12/InSARProducts/slantRangeMask ${RUNDIR}/i12/InSARProducts/slantRangeMask.NoCropLine
	  CropLastLine.py ${RUNDIR}/i12/InSARProducts/slantRangeMask ${NLINES} ${NCOL}
	  mv ${RUNDIR}/i12/InSARProducts/slantRangeMask.CropLastLine ${RUNDIR}/i12/InSARProducts/slantRangeMask
	  NLINES=`echo "( ${NLINES} - 1) " | bc ` 
	  ChangeParam "Unwrapped phase range dimension [pix]" ${NLINES} InSARParameters.txt
	fi

	if [ $((NCOL%2)) -eq 0 ]
	then
	  echo "Number of col is even => OK"
	else
	  echo "Number of col is odd => Number of col -1"
 	  mv ${RUNDIR}/i12/InSARProducts/slantRangeMask ${RUNDIR}/i12/InSARProducts/slantRangeMask.NoCropCol
	  CropLastCol.py ${RUNDIR}/i12/InSARProducts/slantRangeMask ${NLINES} ${NCOL}
	  mv ${RUNDIR}/i12/InSARProducts/slantRangeMask.CropLastCol ${RUNDIR}/i12/InSARProducts/slantRangeMask
	  NCOL=`echo "( ${NCOL} - 1) " | bc ` 
	  ChangeParam "Unwrapped phase azimuth dimension [pix]" ${NCOL} InSARParameters.txt
	fi


# Convert unwrapped phase (from Matlab) to heigt to create a new file named deformationMap
	cd  ${RUNDIR}/i12/InSARProducts
	phaseUnwrapping ${RUNDIR}/i12/TextFiles/InSARParameters.txt -r --convertOnly
	
# Detrend and interpolate if needed
	# Interpolation of small gaps - gaps are from holes in DEM and/or mask
	if [ ${INTERPOL} == "BEFORE" ] || [ ${INTERPOL} == "BOTH" ]
		then
			EchoTee "You requested an interpolation before geocoding. "
			DEFORG=`GetParamFromFile "Deformation measurement range dimension" InSARParameters.txt`
			DEFOAZ=`GetParamFromFile "Deformation measurement azimuth dimension" InSARParameters.txt`

			if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
				then 
					EchoTee "First multiply deformation map with NaN mask."
					if [ -f "${RUNDIR}/i12/InSARProducts/binarySlantRangeMask" ]
						then 
							EchoTee "Suppose multilevel masking where 1 and/or 2 = to be masked and 0 = non masked."
							# i.e. use new masking method with multilevel masks where 0 = non masked and 1 or 2 = masked
							byte2Float.py ${RUNDIR}/i12/InSARProducts/snaphuMask
							ffa ${RUNDIR}/i12/InSARProducts/deformationMap N ${RUNDIR}/i12/InSARProducts/snaphuMaskFloat -i
							convert -depth 8 -equalize -size ${DEFORG}x${DEFOAZ} gray:${RUNDIR}/i12/InSARProducts/snaphuMask ${RUNDIR}/i12/InSARProducts/snaphuMask.gif
						else 
							if [ ${UW_METHOD} == "CIS" ]
								then 
									EchoTee "CIS unwrapping performed with mask. However, deformation maps are not shown with masked area because there is no product with teh same size. "
									EchoTee "However, you can easily do it manually with any GIS software. "
								else 
									EchoTee "Suppose mask where 0 = to be masked and 1 = non masked."
									# i.e. use old masking method with single level masks where 0 = masked
									ffa ${RUNDIR}/i12/InSARProducts/deformationMap N ${RUNDIR}/i12/InSARProducts/slantRangeMask -i
							fi
					fi
			fi
			fillGapsInImage ${RUNDIR}/i12/InSARProducts/deformationMap ${DEFORG} ${DEFOAZ} 
			# make raster
			MakeFig ${DEFORG} 1.0 1.2 normal jet 1/1 r4 ${RUNDIR}/i12/InSARProducts/deformationMap.interpolated 
		else
			EchoTee "You did not request an interpolation before geocoding."
	fi				

	# Remove best plane 
	if [ ${REMOVEPLANE} == "DETREND" ] 
		then 
			EchoTee "You request detrending. \n" 
			RemovePlane 
		else 
			EchoTee "You did not request detrending. \n" 
	fi


# Re-geocode (only the deformationMap)
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
	ChangeParam "Geoprojected products generic extension" ".UTM.${GEOPIXSIZE}x${GEOPIXSIZE}" geoProjectionParameters.txt
	ChangeParam "Easting sampling" ${GEOPIXSIZE} geoProjectionParameters.txt 
	ChangeParam "Northing sampling" ${GEOPIXSIZE} geoProjectionParameters.txt


	ChangeParam "Geoproject measurement" ${DEFOMAP} geoProjectionParameters.txt

	ChangeParam "Geoproject master amplitude" ${MASAMPL} geoProjectionParameters.txt 
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

# Get infos for naming
	MASTERPATH=`GetParamFromFile "Master image file path" InSARParameters.txt `

	LOOKFULL=`GetParamFromFile "Incidence angle at median slant range" SLCImageInfo.txt ` # must cut to 2 decimal
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
# NOT NEEDED HERE BECAUSE ONLY REGEOC THE DEFO MAP AND ITS NAME AS ALREADY BE UPDATED IN PARAM FILE 
# 	if [ ${COH} == "YES" ] ; then 
# 		 COHFILE=`find ./InSARProducts -type f -name "coherence.??-??*" ! -name "*.ras*"` # search coh file but not raster nor sh
# 		 if [ -s ${COHFILE} ] 
# 			then 
# 				if [ ${COHFILE} != "./InSARProducts/coherence.VV-VV" ] 
# 					then 
# 						echo "Your files were renamed, probably because of a SinglePair processing. Need to recreate original naming befor coregistration"
# 						mv -f ${COHFILE} ./InSARProducts/coherence.${POL}-${POL} 
# 				fi
# 		 fi
# 	fi
# 		# same for interf
# 	if [ ${RESINTERF} == "YES" ] ; then 
# 		  RESIDFILE=`find ./InSARProducts -type f -name "residualInterferogram.??-??*" ! -name "*.ras*" ! -name "*.f*"` # search coh file but not raster nor sh
# 		 if [ -s ${RESIDFILE} ] 
# 			then 
# 				if [ ${RESIDFILE} != "./InSARProducts/residualInterferogram.VV-VV" ] 
# 					then 
# 						mv -f ${RESIDFILE} ./InSARProducts/residualInterferogram.${POL}-${POL} 
# 				fi
# 		 fi	
# 	fi			
# 		# interf.f
# 	if [ ${FILTINTERF} == "YES" ] ; then 
# 		 RESIDFILEFILT=`find ./InSARProducts -type f -name "residualInterferogram.??-??.f*" ! -name "*.ras*"` # search coh file but not raster nor sh
# 		 if [ -s ${RESIDFILEFILT} ] 
# 			then 
# 				if [ ${RESIDFILEFILT} != "./InSARProducts/residualInterferogram.VV-VV.f" ] 
# 					then 
# 						mv -f ${RESIDFILEFILT} ./InSARProducts/residualInterferogram.${POL}-${POL}.f 
# 				fi
# 		 fi	
# 	fi
# 		# unwrappedPhase.VV-VV
# 	if [ ${UNWPHASE} == "YES" ] ; then 
# 		 UNWRFILE=`find ./InSARProducts -type f -name "unwrappedPhase.??-??.*" ! -name "*.ras*" ! -name "*.zoneMap*"` # search coh file but not raster nor sh
# 		 if [ -s ${UNWRFILE} ] 
# 			then 
# 				if [ ${UNWRFILE} != "./InSARProducts/unwrappedPhase.VV-VV" ] 
# 					then 
# 						mv -f ${UNWRFILE} ./InSARProducts/unwrappedPhase.${POL}-${POL}
# 				fi
# 		 fi	
# 	fi
# 		# deformationMap.interpolated.flattened
# 	if [ ${DEFOMAP} == "YES" ] ; then 
# 		 DEFOINTFLATFILE=`find ./InSARProducts -type f -name "deformationMap.interpolated.flattened.*" ! -name "*.ras*"` # search coh file but not raster nor sh
# 		 if [ -s ${DEFOINTFLATFILE} ] 
# 			then 
# 				if [ ${DEFOINTFLATFILE} != "./InSARProducts/deformationMap.interpolated.flattened" ] 
# 					then 
# 						mv -f ${DEFOINTFLATFILE} ./InSARProducts/deformationMap.interpolated.flattened
# 				fi
# 		 fi
# 		# deformationMap.interpolated 
# 		 DEFOINTFILE=`find ./InSARProducts -type f -name "deformationMap.interpolated.*" ! -name "*.ras*" ! -name "*.flattened.*"` # search coh file but not raster nor sh
# 		 if [ -s ${DEFOINTFILE} ] 
# 			then 
# 				if [ ${DEFOINTFILE} != "./InSARProducts/deformationMap.interpolated" ] 
# 					then 
# 						mv -f ${DEFOINTFILE} ./InSARProducts/deformationMap.interpolated
# 				fi
# 		 fi	
# 		# deformationMap
# 		 DEFOFILE=`find ./InSARProducts -type f -name "deformationMap.*" ! -name "*.ras*" ! -name "*.flattened.*" ! -name "*.interpolated.*"` # search coh file but not raster nor sh
# 		 if [ -s ${DEFOFILE} ] 
# 			then 
# 				if [ ${DEFOFILE} != "./InSARProducts/deformationMap" ] 
# 					then 
# 						mv -f ${DEFOFILE} ./InSARProducts/deformationMap
# 				fi
# 		 fi	
# 		# may need to rename the others ? Renaming to be added here if needed
# 	fi


# All param updated. Run geocoding
	if [ ${RADIUSMETHD} == "LetCIS" ] 
		then
			# Let CIS Choose what is the best radius, that is 2 times the distance to the nearest neighbor
			geoProjection -rk ./TextFiles/geoProjectionParameters.txt	| tee -a ${LOGFILE}
		else 
			# Force radius: force radius to RADIUSMETHD times the distance to the nearest neighbor. Default value (i.e. LetCIS) is 2)
			geoProjection -rk -f=${RADIUSMETHD} ./TextFiles/geoProjectionParameters.txt	| tee -a ${LOGFILE}
	fi

cd ${RUNDIR}/i12/GeoProjection

# 			
# if [ -s ${RUNDIR}/i12/InSARProducts/BAK_incidence ] 
# 	then 
# 		EchoTee "Will get back incidence file with original name"
# 		EchoTee ""
# 		mv ${RUNDIR}/i12/InSARProducts/BAK_incidence ${RUNDIR}/i12/InSARProducts/incidence 
# fi
# 

# INterpolate if needed
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

	# Interpolation
	case ${INTERPOL} in 
		"AFTER")  
# 			EchoTee "Request interpolation after geocoding."
# 			PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil
# 			fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
# 			PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated	;;
			if [ ${REMOVEPLANE} == "DETREND" ] 
					then 
						EchoTee "Request interpolation after geocoding."
						PATHDEFOGEOMAP=deformationMap.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil
						fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
						#PATHDEFOGEOMAP=deformationMap.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated	
					else 
						EchoTee "Request interpolation after geocoding."
						PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil
						fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
						#PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated	
			fi ;;
		"BOTH")  
# 			EchoTee "Request interpolation before and after geocoding."
# 			PATHDEFOGEOMAP=deformationMap.interpolated.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil
# 			fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
# 			PATHDEFOGEOMAP=deformationMap.interpolated.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated   ;;
			if [ ${REMOVEPLANE} == "DETREND" ] 
					then 
						EchoTee "Request interpolation before and after geocoding."
						PATHDEFOGEOMAP=deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil
						fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
						#PATHDEFOGEOMAP=deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated   
					else 
						EchoTee "Request interpolation before and after geocoding."
						PATHDEFOGEOMAP=deformationMap.interpolated.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil
						fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
						#PATHDEFOGEOMAP=deformationMap.interpolated.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated   
			fi ;;
		"BEFORE") 
			EchoTee "Do not request interpolation after geocoding" 
			PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil	;;		
	esac


# Make figs 

	MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil
	if [ -e deformationMap.flatttened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.flatttened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil ; fi
	if [ -e deformationMap.interpolated.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil ; fi
	if [ -e deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil ; fi
	if [ -e deformationMap.interpolated.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated ; fi
	if [ -e deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated ; fi


# DO THE RENAMING FILES HERE BELOW
# still in /i12 :
# Renaming
	 EchoTee "Updating  files if it were re-geocoded..."
	 EchoTee ""

	GetSatOrbDetails
	
 	RenameAllProducts 
	
	EchoTee "Updating defo interpx2 flatten hdr in case of re-geocoding with different options"
	EchoTee ""
	if [ -e deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr ] 
		then 
			FLATTENHDR=deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
			FLATTENINTERPHDR=deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
			cp -f ${FLATTENHDR} ${FLATTENINTERPHDR} 
			${PATHGNU}/gsed -i "/Description/c\Description = {deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZE}x${GEOPIXSIZE}.bil.interpolated" ${FLATTENINTERPHDR}
	fi
	
	
	
	
	
	
	
	
	
	
