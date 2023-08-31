#!/bin/bash
# Script to re-run the geocoding of files from a given list of PAIR DIRS in SAR_MASSPROCESS. 
# It then moves the results in /Geocoded and rasters in /Geocodedrasters
# Note that it skips the geocoding of amplitude if it exists in Geocded dir. 
#      See script lines 177-186 below if you want to force it. 
# Note Incidence is geocoded by default if present in InSARProducts. 
#    If you do not want to re-geoc it, it will be renamed temporarily. For this let the 
#    script know by adding an additional NO at the hardcoded list of geocoded files. 
#
# Note : only verified for interpolation BOTH and with detrend !
#
# Note that this request to run first RenamePathAfterMove_in_SAR_MASSPROC.sh in SAR_MASSPROCESS/../../..
#   to ensure proper path to files. It might be advised also to run
#   RenamePath_Volumes.sh in .../SAR_CSL/... and .../RESAMPLED/...
# 
#  !!!!! WARNING: only tested for S1 so far and not in STRIPMAP !!!!!
#
# Need to be run in dir where all PAIR DIRS in SAR_MASSPROCESS are, 
#   e.g. /.../SAR_MASSPROCESS/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310_Zoom1_ML8
#
# Parameters:	- a list of dir where to re-run the geocoding either in the form of S1A_174_20141017_A_S1A_174_20141110_A or 20141017_20141110
#               - interpolation of the defo maps: "BEFORE", "AFTER", "BOTH" or "NONE"
#				- if a third parameter is provide as a LauchParameters.txt file, it can perform the re-geocoding with new parameters. 
#
# HARD CODED: 	- list of products to gecode
#				- FIG=FIGyes or FIGno if one wants to recompute the rasters
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- FUNCTIONS_FOR_MT.sh
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.1.0
# New in Distro V 1.1:	- also re-create the scripts to make the rasters 
# New in Distro V 1.2: 	- ask if one wants to move results in Geocoded and GeocodedRasters
#						- ok for Envisat
# New in Distro V 1.3: 	- allows interpolation also AFTER and BOTH when it is not from a mass processing
#						- do not restrict coherence to VV-VV
# New in Distro V 2.0: 	- Reads a parameters file to be able to perform the Re-Geocoding with new parameters.
# New in Distro V 2.1: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.2: - read UTM zone for geocoding
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2018/03/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

LISTTOGEOC=$1		# a list of dir where to re-run the geocoding either in the form of S1A_174_20141017_A_S1A_174_20141110_A or 20141017_20141110
INTERPOL=$2 		# Must be AFTER, BEFORE, BOTH or NONE to let the script know what type of inyterpolation you want (before/after geocoding)
PARAMFILE=$3	# File with the parameters needed for the run

if [ $# -lt 2 ] ; then 
		echo "Please provided a list of pairs and INTERPOLATION option."
		exit 0
fi

source ${PATH_SCRIPTS}/SCRIPTS_MT/FUNCTIONS_FOR_MT.sh

# vvv ----- Hard coded lines to check --- vvv 
FIG=FIGyes  # or FIGno
# only the deformation maps
#  		DEFOMAP	MASAMPL	SLVAMPL	COH	INTERF	FILTINTERF	RESINTERF	UNWPHASE INCIDENCE 
#FILESTOGEOC="YES NO NO NO NO NO NO NO NO"
# All
FILESTOGEOC="YES YES NO YES NO YES YES YES YES"
# All but ampl
#FILESTOGEOC="YES NO NO YES NO YES YES YES YES"
#FILESTOGEOC="NO NO NO YES NO NO NO NO NO"
# ^^^ ----- Hard coded lines to check -- ^^^ 

MASSPROCDIR="$(pwd)"
SAT=`echo ${MASSPROCDIR} | ${PATHGNU}/gsed 's/.*SAR_MASSPROCESS\///' | cut -d / -f1`
MODE=`echo ${MASSPROCDIR} | ${PATHGNU}/gsed 's/.*SAR_MASSPROCESS\///' | cut -d / -f2`

if [ $# -eq 3 ] ; then 
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

	SKIPUW=`GetParam "SKIPUW,"`					# SKIPUW, SKIPyes skips unwrapping and geocode all available products
	#INTERPOL=`GetParam "INTERPOL,"`				# INTERPOL, interpolate the unwrapped interfero BEFORE or AFTER geocoding or BOTH. 	
	REMOVEPLANE=`GetParam "REMOVEPLANE,"`		# REMOVEPLANE, if DETREND it will remove a best plane after unwrapping. Anything else will ignore the detrending. 	

	DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					
fi


# if [ "${SAT}" != "S1" ] 
# 	then 
# 		echo "Script not designd for non-S1 yet."
# 		exit 0
# 	else 
# 		echo "WARNING : script not designd for S1 in STRIPMAP."
# fi

				SpeakOut "Do you want to move results in Geocoded and rasters in GeocodedRasters ?" 
				while true; do
					read -p "Do you want to move results in Geocoded and rasters in GeocodedRasters ?"  yn
					case $yn in
						[Yy]* ) 
							echo "OK, you are probably re-running mass processing..."
							MVRES="YES"
							break ;;
						[Nn]* ) 
							echo "OK, you are probably re-running pairs other than for mass processing..."
							MVRES="NO"
							break ;;
						* ) echo "Please answer yes or no.";;
					esac
				done


# Change LISTTOGEOC type if not in the form of S1A_174_20141017_A_S1A_174_20141110_A
if [ `head -1 ${LISTTOGEOC} | awk -F\_ '{print NF-1}'` == "1" ]    # count the nr of underscore. If only one, one must change format
	then 
		# var to remind the script to change format 	
		CHANGEDIRNAME="YES"
	else 
		CHANGEDIRNAME="NO"
fi

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
echo "If needed, run RenamePathAfterMove_in_SAR_MASSPROC.sh to get the right path and RenamePath_Volumes.sh or similar to get it in the right format."
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

function ChangeGeocParam()
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
	parameterFilePath=./geoProjectionParameters.txt

	ORIGINAL=`updateParameterFile ${parameterFilePath} ${KEY} ${NEW}`
	echo "  // update  ${CRITERIA} in ${parameterFilePath}"
# 	echo "=> Change in ${parameterFilePath}"
# 	echo "...Key = ${CRITERIA} "
# 	echo "...Former Value =  ${ORIGINAL}"
# 	echo "    --> New Value =  ${NEW}"
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
		"InSARParameters.txt") parameterFilePath=${MASSPROCDIR}/${DIR}/i12/TextFiles/InSARParameters.txt ;;
		"SLCImageInfo.txt") parameterFilePath=${MASTERPATH}/Info/SLCImageInfo.txt ;;
		"geoProjectionParameters.txt") parameterFilePath=${MASSPROCDIR}/${DIR}/i12/TextFiles/geoProjectionParameters.txt ;;
	esac
	updateParameterFile ${parameterFilePath} ${KEY}
	}

for DIR in `cat -s ${LISTTOGEOC}` 
do 
	if [ ${CHANGEDIRNAME} == "YES" ] ; then 
			MAS=`echo "${DIR}" | cut -d "_" -f1  ` # select master date
			SLV=`echo "${DIR}" | cut -d "_" -f2  ` # select slave date
			DIR=`ls -d *${MAS}*${SLV}*`
		else 
			MAS=`echo "${DIR}" | cut -d "_" -f3  ` # select master date
			SLV=`echo "${DIR}" | cut -d "_" -f7  ` # select slave date
	fi
	if [ "${INCIDENCE}" == "YES" ] 
		then 
			echo "Will geocode incidence again"
		else 
			echo "Temporarily rename indidence to avoid automatic geocoding" 
			if [ -f ${MASSPROCDIR}/${DIR}/i12/InSARProducts/incidence ] ; then mv ${MASSPROCDIR}/${DIR}/i12/InSARProducts/incidence ${MASSPROCDIR}/${DIR}/i12/InSARProducts/BAK_incidence  ; fi
	fi
	echo ""
	echo "***** Process ${DIR}"
	# remove possible existing old Projection Map
	rm -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/projMat.UTM.*

	cd  ${MASSPROCDIR}/${DIR}/i12/TextFiles

	# Update which products to geocode
	ChangeGeocParam "Geoproject measurement" ${DEFOMAP} geoProjectionParameters.txt

	if [ "${MVRES}" == "YES" ]
		then
			# check if mas and slave are already geocoded. If yes, e.g. in a mass processing, then do not re-geocode it after first geocoding
			if [ `find ${MASSPROCDIR}/Geocoded/Ampli/ -name "*${MAS}*mod*" -type f 2>/dev/null | wc -l` -ge 1 ] 
				then  # exists already hence skip even if default was YES 
					MASAMPL=NO
			fi

			if [ `find ${MASSPROCDIR}/Geocoded/Ampli/ -name "*${SLV}*mod*" -type f 2>/dev/null | wc -l` -ge 1 ] 
				then # exists already hence skip even if default was YES 
					SLVAMPL=NO
			fi
	fi
	ChangeGeocParam "Geoproject master amplitude" ${MASAMPL} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject slave amplitude" ${SLVAMPL} geoProjectionParameters.txt

	ChangeGeocParam "Geoproject coherence" ${COH} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject interferogram" ${INTERF} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject filtered interferogram" ${FILTINTERF} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject residual interferogram" ${RESINTERF} geoProjectionParameters.txt 
	ChangeGeocParam "Geoproject unwrapped phase" ${UNWPHASE} geoProjectionParameters.txt 

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
	NEWNAME=${SAT}_${MODE}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
	NAMING=`GetParamFromFile "Geoprojected products generic extension" geoProjectionParameters.txt ` # e.g. .UTM.100x100 (beware of starting dot !)

	if [ $# -eq 3 ] ; then 
			RUNDIR=${MASSPROCDIR}/${DIR}
			
			# get AZSAMP. Attention, needs original az sampling
			MASDATE=`basename ${RUNDIR} | cut -d _ -f 1`
			SLVDATE=`basename ${RUNDIR} | cut -d _ -f 2`
			MASNAME=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${MASDATE} | cut -d . -f 1` 	
			KEY=`echo "Azimuth sampling [m]" | tr ' ' _`
			parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${MASNAME}.csl/Info/SLCImageInfo.txt
			AZSAMP=`updateParameterFile ${parameterFilePath} ${KEY}` # not rounded
		
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

				if [ "${UTMZONE}" == "" ]
					then 
						EchoTeeYellow "No UTM zone defined (empty or not in LaunchParam.txt file). Will compute it from the center of the image."
						EchoTeeYellow "  It may not be a problem unless the center of the AoI is in another zone and you need to compare different modes which can have different central UTM zone."
					else
						EchoTeeYellow "Shall use UTM zone defined in LaunchParam.txt, that is: ${UTMZONE}"
						ChangeGeocParam "UTM zone " ${UTMZONE} geoProjectionParameters.txt
				fi

				ChangeGeocParam "xMin" ${XMIN} geoProjectionParameters.txt
				ChangeGeocParam "xMax" ${XMAX} geoProjectionParameters.txt
				ChangeGeocParam "yMin" ${YMIN} geoProjectionParameters.txt
				ChangeGeocParam "yMax" ${YMAX} geoProjectionParameters.txt
				;;
				*) 
				EchoTeeYellow "Not sure what you wanted => used Closest..." 
				GEOPIXSIZE=`echo ${PIXSIZEAZ} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
				EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
				;;
			esac
		
			# Change default parameters : Geoprojected products generic extension 
			ChangeGeocParam "Geoprojected products generic extension" ".UTM.${GEOPIXSIZE}x${GEOPIXSIZE}" geoProjectionParameters.txt
			ChangeGeocParam "Easting sampling" ${GEOPIXSIZE} geoProjectionParameters.txt 
			ChangeGeocParam "Northing sampling" ${GEOPIXSIZE} geoProjectionParameters.txt
		
		
		
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
	fi

	cd ${MASSPROCDIR}/${DIR}/i12

	# ensure that products are not renamed such as after a SinglePair processing. If so, cp it as default coh file name 
 	POLM=`GetParamFromFile "Master polarization channel" InSARParameters.txt `
 	POLS=`GetParamFromFile "Slave polarization channel" InSARParameters.txt `
 	COHFILE=`find ./InSARProducts -type f -name "coherence.${POLM}-${POLS}*" | ${PATHGNU}/grep "day" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" `
 	if [ -f "${COHFILE}" ] && [ -s "${COHFILE}" ]
 		then 
 			echo "Your files were renamed, probably because of a SinglePair processing. Need to recreate original naming befor coregistration"
 			RENAMING="YES"
 			mv -f ${COHFILE} ./InSARProducts/coherence.${POLM}-${POLS} 
 			# may need to rename the others if want to re-geoc more than coh... Feel free to do it here after 
 	fi

	geoProjection -rk ./TextFiles/geoProjectionParameters.txt


	if [ "${MVRES}" == "YES" ]
		then

			# create figures
				# force no fig pop up
				POP=POPno
				cd ${MASSPROCDIR}/${DIR}/i12/GeoProjection
				GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
				if [ "${DEFOMAP}" == "YES" ]
					then
						# plot geocoded unwrapped defo 
						MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap${NAMING}.bil
						if [ -e deformationMap.flatttened${NAMING}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.flatttened${NAMING}.bil ; fi
						if [ -e deformationMap.interpolated${NAMING}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated${NAMING}.bil ; fi
						if [ -e deformationMap.interpolated.flattened${NAMING}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened${NAMING}.bil ; fi
						if [ -e deformationMap.interpolated${NAMING}.bil.interpolated ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated${NAMING}.bil.interpolated ; fi
		#				if [ -e deformationMap.interpolated.flattened${NAMING}.bil.interpolated ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened${NAMING}.bil.interpolated ; fi
				fi
				if [ "${MASAMPL}" == "YES" ]
					then
					# plot geocoded master
					PATHGEOMAS=`basename *${MASNAME}*.*.mod${NAMING}.bil`
					if [ -f "${PATHGEOMAS}" ] && [ -s "${PATHGEOMAS}" ] ; then MakeFigR ${GEOPIXW} 0,100 0.8 1.0 normal gray 1/1 r4 ${PATHGEOMAS} ; fi
				fi
				if [ "${SLVAMPL}" == "YES" ]
					then
					# plot geocoded slave
					PATHGEOSLV=`basename *${SLVNAME}*.*.mod${NAMING}.bil`
					if [ -f "${PATHGEOSLV}" ] && [ -s "${PATHGEOSLV}" ] ; then MakeFigR ${GEOPIXW} 0,100 0.8 1.0 normal gray 1/1 r4 ${PATHGEOSLV} ; fi
				fi
				if [ "${COH}" == "YES" ]
					then
					# plot geocoded coherence
					PATHGEOCOH=`basename coherence.*${NAMING}.bil`
					MakeFigR ${GEOPIXW} 0,1 1.5 1.5 normal gray 1/1 r4 ${PATHGEOCOH} v			
				fi
				if [ "${INTERF}" == "YES" ]
					then
					# plot interferogram
					PATHGEOINTERF=`basename interfero.*${NAMING}.bil`
					MakeFigR ${GEOPIXW} 0,3.15 1.1 1.1 normal jet 4/4 r4 ${PATHGEOINTERF} 
				fi
				if [ "${FILTINTERF}" == "YES" ]
					then
					# plot filtered interferogram
					# for interfero.f.${POL} or residualInterferogram.${POL}.f
					PATHGEOFILTINTERF1=`GetParamFromFile "Filtered interferogram file path" InSARParameters.txt | ${PATHGNU}/gawk -F '/' '{print $NF}' `
					PATHGEOFILTINTERF=`echo ${PATHGEOFILTINTERF1}${NAMING}.bil`
					# On linux computer, for unknown reason it denies renaming geocoded resid interfero with .bil.. 
					if [ ! -s ${PATHGEOFILTINTERF} ] ; then PATHGEOFILTINTERFNOBIL=`echo ${PATHGEOFILTINTERF1}${NAMING}` ; mv ${PATHGEOFILTINTERFNOBIL} ${PATHGEOFILTINTERF} ; fi 
					#MakeFigR ${GEOPIXW} 0,3.1415926535897 1 0.85 normal jet 1/1 r4 ${PATHGEOFILTINTERF} 
					MakeFig ${GEOPIXW} 1 1.2 normal jet 1/1 r4 ${PATHGEOFILTINTERF} 
				fi
				if [ "${RESINTERF}" == "YES" ]
					then
					# plot residual interferogram
					# PATHGEORESINTERF=`basename residualInterferogram.*${NAMING}.bil`
					PATHGEORESINTERF1=`GetParamFromFile "Residual interferogram file path" InSARParameters.txt | ${PATHGNU}/gawk -F '/' '{print $NF}' `
					PATHGEORESINTERF=`echo ${PATHGEORESINTERF1}${NAMING}.bil`
					# On linux computer, for unknown reason it denies renaming geocoded filt resid interfero with .bil.. 
					if [ ! -s ${PATHGEORESINTERF} ] ; then PATHGEORESINTERFNOBIL=`echo ${PATHGEORESINTERF1}${NAMING}` ; mv ${PATHGEORESINTERFNOBIL} ${PATHGEORESINTERF} ; fi 
					#MakeFigR ${GEOPIXW} 0,3.15 1.0 1.0 normal jet 1/1 r4 ${PATHGEORESINTERF} 	
					MakeFig ${GEOPIXW} 1.0 1.2 normal jet 1/1 r4 ${PATHGEORESINTERF} 
				fi
				if [ "${UNWPHASE}" == "YES" ]
					then
					# plot unwrapped phase
					PATHGEOUNWRAPINTERF=`basename unwrappedPhase.*${NAMING}.bil`
					MakeFigNoNorm ${GEOPIXW} normal jet 4/4 r4 ${PATHGEOUNWRAPINTERF} 
				fi
			# end of figures

			cd ${MASSPROCDIR}/${DIR}/i12/GeoProjection
			# rename and move results
			if [ "${DEFOMAP}" == "YES" ] 
				then 
					DEFOGEOCFILE=`ls -f deformationMap.UTM*.bil` 
					DEFOGEOCHDRFILE=`echo ${DEFOGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`
					# Make fig
					deformationMap${NAMING}.bil.ras.sh
					cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/Defo/${DEFOGEOCFILE}_${NEWNAME}.ras
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}.ras
		
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE} ${MASSPROCDIR}/Geocoded/Defo/${DEFOGEOCFILE}_${NEWNAME}
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/Defo/${DEFOGEOCFILE}_${NEWNAME}.hdr

					#ln -sf ${MASSPROCDIR}/Geocoded/Defo/${DEFOGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}
					#ln -sf ${MASSPROCDIR}/Geocoded/Defo/${DEFOGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}.hdr
					# if interpolated exists
					if [ `find . -name "deformationMap.interpolated.UTM*.bil" -type f 2>/dev/null | wc -l` -ge 1 ] 
						then 
							DEFOGEOCFILE=`ls -f deformationMap.interpolated.UTM*.bil` 
							DEFOGEOCHDRFILE=`echo ${DEFOGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`

							# Make fig
							deformationMap.interpolated${NAMING}.bil.ras.sh
							cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/DefoInterpol/${DEFOGEOCFILE}_${NEWNAME}.ras
							mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}.ras

							mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE} ${MASSPROCDIR}/Geocoded/DefoInterpol/${DEFOGEOCFILE}_${NEWNAME}
							mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/DefoInterpol/${DEFOGEOCFILE}_${NEWNAME}.hdr
							#ln -sf ${MASSPROCDIR}/Geocoded/DefoInterpol/${DEFOGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}
							#ln -sf ${MASSPROCDIR}/Geocoded/DefoInterpol/${DEFOGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}.hdr
					fi	
					# if interpolated.flatten exists
					if [ `find . -name "deformationMap.interpolated.flattened.UTM*.bil" -type f 2>/dev/null | wc -l` -ge 1 ] 
						then 
							DEFOGEOCFILE=`ls -f deformationMap.interpolated.flattened.UTM*.bil` 
							DEFOGEOCHDRFILE=`echo ${DEFOGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`

							# Make fig
							deformationMap.interpolated.flattened${NAMING}.bil.ras.sh
							cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/DefoInterpolDetrend/${DEFOGEOCFILE}_${NEWNAME}.ras
							mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}.ras

							mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE} ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/${DEFOGEOCFILE}_${NEWNAME}
							mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/${DEFOGEOCFILE}_${NEWNAME}.hdr
							#ln -sf ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/${DEFOGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}
							#ln -sf ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/${DEFOGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${DEFOGEOCFILE}_${NEWNAME}.hdr
					fi
	
					case ${INTERPOL} in 
						"AFTER")  
							echo "Not tested ; review script on test data set first" ; exit 0
							GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
							GEOPIXL=`GetParamFromFile "Y size of geoprojected products" geoProjectionParameters.txt`

							if [ `find . -name "deformationMap.flattened.UTM*" -type f 2>/dev/null | wc -l` -ge 1 ]  # if a file exists, one must interpolate it. No chance to get it as a link and in /GeoProjection because option AFTER is not planned for mass proc and hence no files are moved in Geocoded
								then 
									# i.e. need interpolation only after unwrapping while a detrending was requested before
									PATHDEFOGEOMAP=`ls -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/deformationMap.flattened.UTM*.bil` # usually this does not exist in Geocoded
									fillGapsInImage ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
								else 
									# i.e. need interpolation only after unwrapping and no detrending was requested 
									PATHDEFOGEOMAP=`ls -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/deformationMap.UTM*.bil`  								# usually this does not exist in Geocoded
									fillGapsInImage ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
							fi 
							if [ -e deformationMap.flattened${NAMING}.bil.interpolated ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.flattened${NAMING}.bil.interpolated ; fi

							 ;;
						"BOTH")  
							GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
							GEOPIXL=`GetParamFromFile "Y size of geoprojected products" geoProjectionParameters.txt`

							#if [ `/usr/bin/find ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/ -name "deformationMap.interpolated.flattened.UTM*${MAS}_${SLV}*deg" -type f 2>/dev/null | wc -l` -ge 1 ] # if a link exists in /GeoProjection, one must interpolate the file which is already in /Geocoded
							if [  -f ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/deformationMap.interpolated.flattened${NAMING}.bil_${NEWNAME} ] 
								then 
									# i.e. did interpolation before unwrapping and a detrending; will now make another interpol
									#PATHDEFOGEOMAP=`find ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/ -name "deformationMap.interpolated.flattened.UTM*${MAS}_${SLV}*deg" | ${PATHGNU}/gsed "s%\/\/%/%g"  | ${PATHGNU}/grep -v bil.interpolated` 
									PATHDEFOGEOMAP=`echo "${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/deformationMap.interpolated.flattened${NAMING}.bil_${NEWNAME}" | ${PATHGNU}/gsed "s%\/\/%/%g"  `
							 
									NAMEDEFOGEOMAP=`basename ${PATHDEFOGEOMAP}`
									fillGapsInImage ${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}  # attention, interpolated file is locate where input file is and ended with .interpolated
									NEWNAMEINTERP=`echo "${NAMEDEFOGEOMAP}.interpolated" | ${PATHGNU}/gsed "s/.bil\_/.bil.interpolated\_/" | ${PATHGNU}/gsed "s/deg.interpolated/deg/"`  # eg deformationMap.interpolated.flattened.UTM.100x100.bil.interpolated_S1_DRC_VVP_A_174-37.0deg_20190313_20191220_Bp-18.9m_HA749.0m_BT282days_Head102.1deg
									mv -f ${PATHDEFOGEOMAP}.interpolated ${NEWNAMEINTERP} # ie mv to GeoProjection with final naming 

									# Make fig
									MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}
									mv -f ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras.sh ${MASSPROCDIR}/${DIR}/i12/GeoProjection/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras.sh
									cp -f ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras ${MASSPROCDIR}/GeocodedRasters/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras
									mv -f ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras
			
									#cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NEWNAMEINTERP}.ras ${MASSPROCDIR}/GeocodedRasters/DefoInterpolx2Detrend/${NEWNAMEINTERP}.ras

									mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NEWNAMEINTERP} ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP}
									#ln -sf ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NEWNAMEINTERP}
									cp -f ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/${NAMEDEFOGEOMAP}.hdr ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP}.hdr
									${PATHGNU}/gsed -i "/Description =/s/$/.interpolated/" ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP}.hdr  #add .interpolated at the end of Description =  line
									#ln -sf ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NEWNAMEINTERP}.hdr
								else 
									# i.e. did interpolation before unwrapping but no detrending; will now make another interpol
									echo "Can't find ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/deformationMap.interpolated.flattened${NAMING}.bil_${NEWNAME}"
									echo "Not tested ; review script on test data set first" ; exit 0
									NAMEDEFOGEOMAP=`find . -name "deformationMap.interpolated.UTM*deg" | ${PATHGNU}/gsed "s/\.\///"`
									fillGapsInImage ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NAMEDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}						
							fi
							 ;;		
						"BEFORE") 
							echo "Do not request interpolation after geocoding" 
							;;		
						"NONE") 
							echo "Do not request interpolation after geocoding" 
							;;		
					esac					
			fi
			if [ "${MASAMPL}" == "YES" ]
				then 
					AMPLGEOCFILE=`ls -f *_${MAS}_*.mod*.bil` 
					AMPLGEOCHDRFILE=`echo ${AMPLGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`

					# Make fig
					${AMPLGEOCFILE}.ras.sh
					cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/Ampli/${AMPLGEOCFILE}_${NEWNAME}.ras
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}_${NEWNAME}.ras

					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE} ${MASSPROCDIR}/Geocoded/Ampli/${AMPLGEOCFILE}_${NEWNAME}
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/Ampli/${AMPLGEOCFILE}_${NEWNAME}.hdr
					#ln -sf ${MASSPROCDIR}/Geocoded/Ampli/${AMPLGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}_${NEWNAME}
					#ln -sf ${MASSPROCDIR}/Geocoded/Ampli/${AMPLGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}_${NEWNAME}.hdr
			fi	
			if [ "${SLVAMPL}" == "YES" ]
				then 
					AMPLGEOCFILE=`ls -f *_${SLV}_*.mod*.bil` 
					AMPLGEOCHDRFILE=`echo ${AMPLGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`

					# Make fig
					${AMPLGEOCFILE}.ras.sh
					cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/Ampli/${AMPLGEOCFILE}_${NEWNAME}.ras
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}_${NEWNAME}.ras

					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE} ${MASSPROCDIR}/Geocoded/Ampli/${AMPLGEOCFILE}_${NEWNAME}
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/Ampli/${AMPLGEOCFILE}_${NEWNAME}.hdr
					#ln -sf ${MASSPROCDIR}/Geocoded/Ampli/${AMPLGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}_${NEWNAME}
					#ln -sf ${MASSPROCDIR}/Geocoded/Ampli/${AMPLGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${AMPLGEOCFILE}_${NEWNAME}.hdr
			fi	
			if [ "${COH}" == "YES" ] 
				then 
					COHGEOCFILE=`ls -f coherence*.bil` 
					COHGEOCHDRFILE=`echo ${COHGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`

					# Make fig
					${COHGEOCFILE}.ras.sh
					cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${COHGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/Coh/${COHGEOCFILE}_${NEWNAME}.ras
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${COHGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${COHGEOCFILE}_${NEWNAME}.ras

					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${COHGEOCFILE} ${MASSPROCDIR}/Geocoded/Coh/${COHGEOCFILE}_${NEWNAME}
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${COHGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/Coh/${COHGEOCFILE}_${NEWNAME}.hdr
					#ln -sf ${MASSPROCDIR}/Geocoded/Coh/${COHGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${COHGEOCFILE}_${NEWNAME}
					#ln -sf ${MASSPROCDIR}/Geocoded/Coh/${COHGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${COHGEOCFILE}_${NEWNAME}.hdr
			fi
			#if [ "${INTERF}" == "YES" ] ; then   ; fi
			if [ "${FILTINTERF}" == "YES" ] 
				then 
					INTERFGEOCFILE=`ls -f residualInterferogram.??-??.UTM*.bil` 
					INTERFGEOCHDRFILE=`echo ${INTERFGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`

					# Make fig
					${INTERFGEOCFILE}.ras.sh
					cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${INTERFGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/InterfFilt/${INTERFGEOCFILE}_${NEWNAME}.ras
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${INTERFGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${INTERFGEOCFILE}_${NEWNAME}.ras

					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${INTERFGEOCFILE} ${MASSPROCDIR}/Geocoded/InterfFilt/${INTERFGEOCFILE}_${NEWNAME}
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${INTERFGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/InterfFilt/${INTERFGEOCFILE}_${NEWNAME}.hdr
					#ln -sf ${MASSPROCDIR}/Geocoded/InterfFilt/${INTERFGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${INTERFGEOCFILE}_${NEWNAME}
					#ln -sf ${MASSPROCDIR}/Geocoded/InterfFilt/${INTERFGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${INTERFGEOCFILE}_${NEWNAME}.hdr
			fi
			if [ "${RESINTERF}" == "YES" ] 
				then 
					RESINTERFGEOCFILE=`ls -f residualInterferogram.??-??.f.UTM*.bil` 
					RESINTERFGEOCHDRFILE=`echo ${RESINTERFGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`

					# Make fig
					${RESINTERFGEOCFILE}.ras.sh
					cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${RESINTERFGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/InterfResid/${RESINTERFGEOCFILE}_${NEWNAME}.ras
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${RESINTERFGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${RESINTERFGEOCFILE}_${NEWNAME}.ras

					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${RESINTERFGEOCFILE} ${MASSPROCDIR}/Geocoded/InterfResid/${RESINTERFGEOCFILE}_${NEWNAME}
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${RESINTERFGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/InterfResid/${RESINTERFGEOCFILE}_${NEWNAME}.hdr
					#ln -sf ${MASSPROCDIR}/Geocoded/InterfResid/${RESINTERFGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${RESINTERFGEOCFILE}_${NEWNAME}
					#ln -sf ${MASSPROCDIR}/Geocoded/InterfResid/${RESINTERFGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${RESINTERFGEOCFILE}_${NEWNAME}.hdr
			fi
			if [ "${UNWPHASE}" == "YES" ] 
				then 
					UFGEOCFILE=`ls -f unwrappedPhase.*.bil` 
					UFGEOCHDRFILE=`echo ${UFGEOCFILE} | ${PATHGNU}/gsed s/.bil/.hdr/`

					# Make fig
					${UFGEOCFILE}.ras.sh
					cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${UFGEOCFILE}.ras ${MASSPROCDIR}/GeocodedRasters/UnwrapPhase/${UFGEOCFILE}_${NEWNAME}.ras
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${UFGEOCFILE}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${UFGEOCFILE}_${NEWNAME}.ras

					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${UFGEOCFILE} ${MASSPROCDIR}/Geocoded/UnwrapPhase/${UFGEOCFILE}_${NEWNAME}
					mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${UFGEOCHDRFILE} ${MASSPROCDIR}/Geocoded/UnwrapPhase/${UFGEOCFILE}_${NEWNAME}.hdr
					#ln -sf ${MASSPROCDIR}/Geocoded/UnwrapPhase/${UFGEOCFILE}_${NEWNAME} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${UFGEOCFILE}_${NEWNAME}
					#ln -sf ${MASSPROCDIR}/Geocoded/UnwrapPhase/${UFGEOCFILE}_${NEWNAME}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${UFGEOCFILE}_${NEWNAME}.hdr
			fi
	
			if [ "${INCIDENCE}" == "YES" ] 
				then 
					echo ""
				else 
					echo "Indidence file restaured" 
					mv ${MASSPROCDIR}/${DIR}/i12/InSARProducts/BAK_incidence ${MASSPROCDIR}/${DIR}/i12/InSARProducts/incidence 
			fi
		else  # MVRES=no
			# ensure that products are renamed as before 
			NRGEOC=`find ./GeoProjection -type f -name "coherence.${POLM}-${POLS}*" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | wc -l` 
			if [ ${NRGEOC} -gt 1 ] 
				then 
					# get the oldest (do not rename it as _original because it would cause prblms if used for MultiLuanchForMask.sh)
					OLDESTCOHFILE=`ls -lt ./GeoProjection/coherence.${POLM}-${POLS}* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | tail -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
					# mv -n ${OLDESTCOHFILE} ${OLDESTCOHFILE}_original
					
					# get the youngest and rename it as the oldest
					NEWESTCOHFILE=`ls -lt ./GeoProjection/coherence.${POLM}-${POLS}* | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".hdr" | head -1 | cut -d / -f 2-`  #i.e. name preceded by GeoProjection/
					mv ${NEWESTCOHFILE} ${OLDESTCOHFILE}
					
					rm ${OLDESTCOHFILE}.ras
			fi
# try below
 			case ${INTERPOL} in 
 				"AFTER")  
 					echo "Not tested ; review script on test data set first" ; exit 0
 					GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
 					GEOPIXL=`GetParamFromFile "Y size of geoprojected products" geoProjectionParameters.txt`
 
 					if [ `find ./GeoProjection -name "deformationMap.flattened.UTM*" -type f 2>/dev/null | wc -l` -ge 1 ]  # if a file exists, one must interpolate it. No chance to get it as a link and in /GeoProjection because option AFTER is not planned for mass proc and hence no files are moved in Geocoded
 						then 
 							# i.e. need interpolation only after unwrapping while a detrending was requested before
 							PATHDEFOGEOMAP=`ls -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/deformationMap.flattened.UTM*.bil` # usually this does not exist in Geocoded
 							fillGapsInImage ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
 						else 
 							# i.e. need interpolation only after unwrapping and no detrending was requested 
 							PATHDEFOGEOMAP=`ls -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/deformationMap.UTM*.bil`  								# usually this does not exist in Geocoded
 							fillGapsInImage ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
 					fi 
 					if [ -e deformationMap.flattened${NAMING}.bil.interpolated ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.flattened${NAMING}.bil.interpolated ; fi
 
 					 ;;
 				"BOTH")  
 					GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
 					GEOPIXL=`GetParamFromFile "Y size of geoprojected products" geoProjectionParameters.txt`
 
 					#if [ `/usr/bin/find ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/ -name "deformationMap.interpolated.flattened.UTM*${MAS}_${SLV}*deg" -type f 2>/dev/null | wc -l` -ge 1 ] # if a link exists in /GeoProjection, one must interpolate the file which is already in /Geocoded
 					if [  -f ./GeoProjection/deformationMap.interpolated.flattened${NAMING}.bil ] 
 						then 
 							# i.e. did interpolation before unwrapping and a detrending; will now make another interpol
 							#PATHDEFOGEOMAP=`find ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/ -name "deformationMap.interpolated.flattened.UTM*${MAS}_${SLV}*deg" | ${PATHGNU}/gsed "s%\/\/%/%g"  | ${PATHGNU}/grep -v bil.interpolated` 
 							PATHDEFOGEOMAP=`echo "./GeoProjection/deformationMap.interpolated.flattened${NAMING}.bil" | ${PATHGNU}/gsed "s%\/\/%/%g"  `
 					 
 							NAMEDEFOGEOMAP=`basename ${PATHDEFOGEOMAP}`
 							fillGapsInImage ${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}  # attention, interpolated file is locate where input file is and ended with .interpolated
 							NEWNAMEINTERP=`echo "${NAMEDEFOGEOMAP}.interpolated" | ${PATHGNU}/gsed "s/.bil\_/.bil.interpolated\_/" | ${PATHGNU}/gsed "s/deg.interpolated/deg/"`  # eg deformationMap.interpolated.flattened.UTM.100x100.bil.interpolated_S1_DRC_VVP_A_174-37.0deg_20190313_20191220_Bp-18.9m_HA749.0m_BT282days_Head102.1deg
 							mv -f ${PATHDEFOGEOMAP}.interpolated ./GeoProjection/${NEWNAMEINTERP} # ie mv to GeoProjection with final naming 
 
 							# Make fig
 							MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 ./GeoProjection/deformationMap.interpolated.flattened${NAMING}.bil.interpolated
 							#mv -f ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras.sh ${MASSPROCDIR}/${DIR}/i12/GeoProjection/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras.sh
 							#cp -f ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras ${MASSPROCDIR}/GeocodedRasters/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras
 							#mv -f ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras ${MASSPROCDIR}/${DIR}/i12/GeoProjection/deformationMap.interpolated.flattened${NAMING}.bil.interpolated_${NEWNAME}.ras
 			
 							#cp -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NEWNAMEINTERP}.ras ${MASSPROCDIR}/GeocodedRasters/DefoInterpolx2Detrend/${NEWNAMEINTERP}.ras
 
 							#mv -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NEWNAMEINTERP} ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP}
 							#ln -sf ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP} ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NEWNAMEINTERP}
 							#cp -f ${MASSPROCDIR}/Geocoded/DefoInterpolDetrend/${NAMEDEFOGEOMAP}.hdr ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP}.hdr
 							#${PATHGNU}/gsed -i "/Description =/s/$/.interpolated/" ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP}.hdr  #add .interpolated at the end of Description =  line
 							#ln -sf ${MASSPROCDIR}/Geocoded/DefoInterpolx2Detrend/${NEWNAMEINTERP}.hdr ${MASSPROCDIR}/${DIR}/i12/GeoProjection/${NEWNAMEINTERP}.hdr
 						else 
 							# i.e. did interpolation before unwrapping but no detrending; will now make another interpol
 							echo "Can't find ./GeoProjection/deformationMap.interpolated.flattened${NAMING}.bil"
 							echo "Not tested ; review script on test data set first" ; exit 0
 							NAMEDEFOGEOMAP=`find ./GeoProjection -name "deformationMap.interpolated.UTM*deg" | ${PATHGNU}/gsed "s/\.\///"`
 							fillGapsInImage ./GeoProjection/${NAMEDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}						
 					fi
 					 ;;		
 				"BEFORE") 
 					echo "Do not request interpolation after geocoding" 
 					;;		
 				"NONE") 
 					echo "Do not request interpolation after geocoding" 
 					;;		
 			esac	
 


			
	fi # end of move to Geocoded and GeocodedRaster
	cd  ${MASSPROCDIR}
done 
