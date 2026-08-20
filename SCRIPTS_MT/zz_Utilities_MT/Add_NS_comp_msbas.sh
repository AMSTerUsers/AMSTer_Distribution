#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at computing the additional required files for a 3D msbas inversion.
# Note that the inversion of the this third NS component only makes sense if/where the 
# displacement is expected to occur along the steepest slope of the topography (e.g. in 
# case of land slide). That is why it is sometimes referred as 3D SPF (Surface Parallel Flow)
#
# The scripts is supposed to be run after the preparation of the "normal" files for the 2D 
# inversion, that is either build_header_msbas_criteria.sh or build_header_msbas_Tables.sh
#
# Like these two scripts, the present script MUST BE LAUNCHED in the dir where 
# msbas will be run. 
#
# The script will first get the DEM (from the image.csl if S1 IW, or from the global_master.csl)
# and crop it at the same grid as the deformation maps.  
# Then it will detrend and apply a Gaussian spatial filter, 
# then compute the first derivatives along X and Y directions (i.e. EW and NS)
#
# The script deals with the path to the data, whatever the mounting pt (Linux or Mac) thanks 
# to the use of __HardcodedLines.sh and its function RenameVolNameToVariable.
# 
# Parameters are : 
#       - FG: width of the Gaussian kernel filter (in meters - e.g 10000 that is 10km) 
#		- optional : if "Force", it will recompute the DEM cropping, the filtering of the DEM 
#			and then the NS and EW gradients. Useful when testing several filtering 
#		- xx: for specific case where a water body located to the North of the image 
#			  induced a strong NS trend: remove xx first lines and replace with NaN 
#			  (need to be 3rd param, hence Force is mandatory as param 2) - option currently disabled 
#
# Optional flags (can be provided in any order, before or after the positional parameters): 
#		- -DEM=Path/to/DEM : path to the DEM to use, instead of searching it from the info 
#			  of the deformation maps. The DEM can be in tif, Envi (i.e. binary + .hdr) or 
#			  AMSTer (i.e. binary + .txt) format. If in tif format, it will be translated in 
#			  Envi format (Float32) with gdal_translate. 
#		- -DEFOMODE=string : name of the dir containing the deformation maps of the first mode 
#			  to invert, i.e. Defo1, DefoInterpol1, DefoInterpolDetrend1, DefoInterpolx2Detrend1 
#			  or any other name that would have been given to that dir. 
#			  If not provided, the script searches successively in DefoInterpolx2Detrend1, 
#			  DefoInterpolDetrend1, DefoInterpol1 and Defo1. 
#		Using these optional parameters, the DEM is cropped at the size and grid of the first deformation map (in Envi or 
#			  tif format) found in that dir. 
#		- -THRESHOLD=value : gradient clipping threshold in m/m passed to Filter_and_Gradient.py. 
#			  Pixels where the (filtered) local slope |gradient| > value are set to NaN in the 
#			  gradient files. If not provided, Filter_and_Gradient.py uses its own default (0.6, 
#			  i.e. ~31 deg slope). Use a large value, or 0, to keep (almost) all pixels. 
#
# ex: in /$PATH_3602/MSBAS/_Funu_S1_Auto_Max3Shortests, run e.g. either
#		Add_NS_comp_msbas.sh 10000 Force 
#		Add_NS_comp_msbas.sh 10000 Force -DEM=/$PATH_DataSAR/SAR_AUX_FILES/DEM/COPERNICUS/Funu.bil -DEFOMODE=DefoInterpolx2Detrend1
#		Add_NS_comp_msbas.sh 10000 Force -THRESHOLD=0.8
#       
# Dependencies:	- (GMT and gdal if works with geotif files like Sergey Samsonov - NOT HERE)
#				- python 3.10 with scipy and numpy modules
#				- Filter_and_Gradient.py script
#				- __HardcodedLines.sh for function RenameVolNameToVariable
#				- DEM_AMSTer_txt2Envi_hdr.sh if DEM is in CSL format, i.e. with a .txt file 
#				- CropDEM2targetHDR.sh
#
# New in Distro V 1.1 20240123:	- Rename rep DefoDEM as DEM to avoid clash with some scripts 
#								  searching for comp dir with similar name 
# New in Distro V 1.2 20240125:	- undocumented option: if third param is provided, it will
#								  remove that amount of first lines before computing the 
#								  NS and EW gradients, then replace them as NaN in gradient 
#								  files. This option was required for specific case South of 
#								  Lake Kivu where the wate body induced tred in NS grad. 
#								- When computing 3D, calibrating the msbas with C_FLAG = 10
#								  is recommended.  
# New in Distro V 1.3 20240305:	- Works for other defo mode than only DefoInterpolx2Detrend
#								- update path in image before re-geocode DEM
# New in Distro V 1.4 20240924:	- more robust to change all path in Parameters.txt files with 
#								  global variables for disk names
# New in Distro V 1.5 20250227:	- replace cp -n with if [ ! -e DEST ] ; then cp SRC DEST ; fi 
# New in Distro V 1.6 20251104:	- because of an old bug in geoProjection which does not follow 
#									links for AoI kml's, change path in geoProjectionParameters.txt
# New in Distro V 2.0 20251223:	- use original DEM instead of slantRangeDEM
#								- do not use -f option for readlink, because it is not supported by Mac computers
# New in Distro V 2.1 20260219:	- change cslDEM2envi.sh into DEM_AMSTer_txt2Envi_hdr.sh (same script, just name change)
# New in Distro V 3.0 20260729:	- parse parameters to accept the optional flags -DEM=Path/to/DEM 
#								  (DEM in tif, Envi or AMSTer format) and -DEFOMODE=string (name of  
#								  the dir with the deformation maps of the first mode to invert) 
#								- crop the DEM at the size and grid of the first deformation map 
#								  (Envi or tif) found in the dir of the first mode to invert 
#								- re-cropping of the DEM is now skipped only if a *_cropped.hdr 
#								  exists and Force is not requested 
# New in Distro V 3.1 20260730:	- accept the optional flag -THRESHOLD=value and forward it to 
#								  Filter_and_Gradient.py as threshold=value (gradient clipping in m/m) 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 29, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# vvv ----- Hard coded lines to check --- vvv 
source $HOME/.bashrc 
# need  RenameVolNameToVariable
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
# ^^^ ----- Hard coded lines to check -- ^^^ 

PWDDIR=$(pwd)

function ResolveDEMPath()
	{
	# Echoes the path to the DEM binary file corresponding to the path provided as $1, which may be 
	# the binary file itself or its .hdr (Envi) or .txt (AMSTer) descriptor. 
	# Echoes nothing if it can not be resolved. 
	unset DEMPATH DEMEXTi
	local DEMPATH
	local DEMEXTi
	DEMPATH="$1"

	case "${DEMPATH}" in 
		*.hdr|*.txt)	
			if [ -f "${DEMPATH%.*}" ] 
				then 
					# e.g. DEM and DEM.hdr, as in AMSTer 
					DEMPATH="${DEMPATH%.*}"
				else 
					# the binary file may have its own extension, e.g. DEM.bin with DEM.hdr, as created by gdal 
					for DEMEXTi in bin bil img dat raw flt tif tiff
						do
							if [ -f "${DEMPATH%.*}.${DEMEXTi}" ] ; then DEMPATH="${DEMPATH%.*}.${DEMEXTi}" ; break ; fi
						done
			fi ;;
	esac

	case "${DEMPATH}" in 
		*.hdr|*.txt)	echo "" ; return ;;			# no binary file found for that descriptor 
	esac

	if [ ! -f "${DEMPATH}" ] ; then echo "" ; return ; fi
	echo "${DEMPATH}"
	}

# Parse the parameters: FG, Force and the nr of first lines to remove are positional (in that order), 
# while -DEM= and -DEFOMODE= are optional flags that can be provided anywhere in the command line 
unset FG FORCE FIRSTLINESTOREMOVE DEMPROVIDED DEFOMODE THRESHOLD
FG=""					# size of the filtering window in m (e.g. 10000)
FORCE=""
FIRSTLINESTOREMOVE=""
DEMPROVIDED=""			# path to the DEM provided with -DEM=  
DEFOMODE=""				# name of the dir with the defo maps of the first mode to invert, provided with -DEFOMODE= 
THRESHOLD=""			# gradient clipping threshold in m/m, provided with -THRESHOLD= (forwarded to Filter_and_Gradient.py) 

for ARG in "$@"
	do
		case "${ARG}" in
			-DEM=*)			DEMPROVIDED="${ARG#-DEM=}" ;;
			-DEFOMODE=*)	DEFOMODE="${ARG#-DEFOMODE=}" ;;
			-THRESHOLD=*)	THRESHOLD="${ARG#-THRESHOLD=}" ;;
			-*)				echo "  // Unknown option ${ARG}; ignored." ;;
			*)				
				if [ "${FG}" = "" ] 
					then 
						FG="${ARG}" 
					elif [ "${FORCE}" = "" ] 
						then 
							FORCE="${ARG}" 
						else 
							FIRSTLINESTOREMOVE="${ARG}" 
				fi ;;
		esac
	done

if [ "${FG}" = "" ] 
	then 
		echo "Usage: ${PRG} FG [Force] [nrOfFirstLinesToRemove] [-DEM=Path/to/DEM] [-DEFOMODE=NameOfFirstDefoModeDir] [-THRESHOLD=value]"
		echo "   e.g. ${PRG} 10000 Force -DEM=/\$PATH_DataSAR/SAR_AUX_FILES/DEM/Funu.bil -DEFOMODE=DefoInterpolx2Detrend1 -THRESHOLD=0.8"
		echo "Exiting..."
		exit 1
fi

# Check the DEM provided with -DEM= (if any) 
if [ "${DEMPROVIDED}" != "" ] 
	then 
		# expand ~ if provided because it is not expanded after the = sign 
		case "${DEMPROVIDED}" in 
			"~/"*)	DEMPROVIDED="${HOME}/${DEMPROVIDED#\~/}" ;;
			"~")	DEMPROVIDED="${HOME}" ;;
		esac
		# if the .hdr or .txt descriptor was provided instead of the binary file, take the binary file 
		DEMRESOLVED=$(ResolveDEMPath "${DEMPROVIDED}")
		if [ "${DEMRESOLVED}" = "" ] 
			then 
				echo "  // ${DEMPROVIDED} provided with -DEM= is not a valid DEM file (nor a descriptor of a DEM file I could find). "
				echo "  // Please provide the path to a DEM in tif, Envi or AMSTer format. Exiting..."
				exit 1
		fi
		DEMPROVIDED="${DEMRESOLVED}"
		# make the path absolute because the script changes dir while running 
		case "${DEMPROVIDED}" in 
			/*)	;;
			*)	DEMPROVIDED="$(cd "$(dirname "${DEMPROVIDED}")" && pwd)/$(basename "${DEMPROVIDED}")" ;;
		esac
		echo "  // DEM provided as parameter: ${DEMPROVIDED}"
fi

# Check the defo mode provided with -DEFOMODE= (if any) 
if [ "${DEFOMODE}" != "" ] 
	then 
		DEFOMODE=$(basename "${DEFOMODE%/}")			# just in case a path or a trailing / would have been provided 
		if [ ! -d "${PWDDIR}/${DEFOMODE}" ] 
			then 
				echo "  // ${PWDDIR}/${DEFOMODE} provided with -DEFOMODE= is not a valid dir. Exiting..."
				exit 1
		fi
		echo "  // First mode to invert provided as parameter: ${DEFOMODE}"
fi

# Check the gradient clipping threshold provided with -THRESHOLD= (if any) 
if [ "${THRESHOLD}" != "" ] 
	then 
		if ! echo "${THRESHOLD}" | "${PATHGNU}"/grep -qE '^-?[0-9]+([.][0-9]+)?$' 
			then 
				echo "  // -THRESHOLD=${THRESHOLD} is not a valid number (expected e.g. 0.6). Exiting..."
				exit 1
		fi
		echo "  // Gradient clipping threshold provided as parameter: ${THRESHOLD} m/m"
fi

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
		"OriginalInSARParameters.txt") parameterFilePath=${INSARTXTDIR}/InSARParameters.txt;;	# i.e. ${PAIRDIRPATH}/i12/TextFiles/InSARParameters.txt
		"masterSLCImageInfo.txt") parameterFilePath=${INSARTXTDIR}/masterSLCImageInfo.txt;;	# i.e. ${PAIRDIRPATH}/i12/TextFiles/InSARParameters.txt
		"externalSlantRangeDEM_IW.txt") parameterFilePath=${PATHMASCSLVAR}/Info/externalSlantRangeDEM.txt;;	# i.e. ${PAIRDIRPATH}/i12/TextFiles/InSARParameters.txt
		"externalSlantRangeDEM_SM.txt") parameterFilePath=${PATHSM}/Info/externalSlantRangeDEM.txt;;	# i.e. ${PAIRDIRPATH}/i12/TextFiles/InSARParameters.txt
		
		"InSARParameters.txt") parameterFilePath=${GEOCDEMDIR}/${PAIRDIR}/i12/TextFiles/InSARParameters.txt;;
		"geoProjectionParameters.txt") parameterFilePath=${GEOCDEMDIR}/${PAIRDIR}/i12/TextFiles/geoProjectionParameters.txt;;
	esac
	updateParameterFile ${parameterFilePath} ${KEY}
	}

function AddFlag() {
    unset FLAG FLAGANDVAL
    local FLAG
    local FLAGANDVAL
    FLAG="$1"
    FLAGANDVAL="$2"

    if "${PATHGNU}"/grep -q "^${FLAG}" header.txt 2>/dev/null ; then
        echo "  // Header.txt contains a line starting with ${FLAG}"
        # Check if the entire line matches
        if "${PATHGNU}"/grep -q "${FLAGANDVAL}" header.txt 2>/dev/null ; then
            echo "  // and the right value: ${FLAGANDVAL}"
        else
            echo "  // though with a different value. Replace the line with ${FLAGANDVAL}."
            "${PATHGNU}"/gsed -i "s/^${FLAG}.*/${FLAGANDVAL}/" header.txt
        fi
    else
        echo "  // Header.txt does not contain a line starting with ${FLAG}. Add it here "
        # hence add it with provided values
        "${PATHGNU}"/gsed -i "/^I_FLAG/a\\${FLAGANDVAL}" header.txt
    fi
}
function ChgeFlag() {
    unset FLAG FLAGANDVAL
    local FLAG
    local FLAGANDVAL
    FLAG="$1"
    FLAGANDVAL="$2"	# Full flag e.g. C_FLAG = 10

   # Check if the entire line matches
   if "${PATHGNU}"/grep -q "${FLAGANDVAL}" header.txt 2>/dev/null ; then
       echo "  // header.txt has the right flag: ${FLAGANDVAL}"
   else
       echo "  // header.txt has  a different value for ${FLAG}. Change it to ${FLAGANDVAL}."
       "${PATHGNU}"/gsed -i "s/^${FLAG}.*/${FLAGANDVAL}/" header.txt
   fi
}
function GetFirstDefoMap()
	{
	# Search in the dir provided as $1 for the first deformation map, either in Envi 
	# (i.e. a binary file with a companion .hdr) or in tif format. 
	# Echoes the path to that file (possibly a link), or nothing if none is found. 
	unset DEFODIR MAP
	local DEFODIR
	local MAP
	DEFODIR="$1"

	if [ ! -d "${DEFODIR}" ] ; then echo "" ; return ; fi

	# 1) usual AMSTer geocoded Envi products, i.e. files named *deg (or *m if geocoded in UTM)
	MAP=$(find "${DEFODIR}" -mindepth 1 -maxdepth 1 -name "*deg" 2>/dev/null | sort | head -1)
	# 2) products in tif format 
	if [ "${MAP}" = "" ] 
		then 
			MAP=$(find "${DEFODIR}" -mindepth 1 -maxdepth 1 \( -name "*.tif" -o -name "*.tiff" -o -name "*.TIF" -o -name "*.TIFF" \) 2>/dev/null | sort | head -1)
	fi
	# 3) any other Envi product, i.e. any file with a companion .hdr file 
	if [ "${MAP}" = "" ] 
		then 
			MAP=$(find "${DEFODIR}" -mindepth 1 -maxdepth 1 ! -name "*.hdr" ! -name "*.txt" ! -name "*.kml" 2>/dev/null | sort | while read -r FILE
				do
					TGT=$(readlink "${FILE}" 2>/dev/null)			# do not use -f option for readlink because not supported on Mac
					if [ "${TGT}" = "" ] ; then TGT="${FILE}" ; fi
					if [ -f "${TGT}.hdr" ] || [ -f "${TGT%.*}.hdr" ] ; then echo "${FILE}" ; break ; fi
				done | head -1)
	fi
	echo "${MAP}"
	}

function PrepareDEM()
	{
	# Copy the DEM provided as $1 in ${GEOCDEMDIR} and ensure it is there in Envi format with a 
	# header named ${DEMBIN}.hdr, as expected by CropDEM2targetHDR.sh.
	# The DEM can be provided in tif, Envi (binary + .hdr) or AMSTer (binary + .txt) format. 
	# Sets the global variable DEMBIN, i.e. the name of the DEM binary file in ${GEOCDEMDIR}. 
	unset DEMIN DEMEXT
	local DEMIN
	local DEMEXT
	DEMIN="$1"

	# if the .hdr or .txt descriptor was provided instead of the binary file, take the binary file 
	DEMIN=$(ResolveDEMPath "${DEMIN}")

	if [ "${DEMIN}" = "" ] ; then echo "  // $1 is not a valid DEM file. Exiting..." ; exit 1 ; fi

	DEMBIN=$(basename "${DEMIN}")
	DEMEXT=$(echo "${DEMBIN##*.}" | tr '[:upper:]' '[:lower:]')

	echo "  // Get the DEM ${DEMIN} in ${GEOCDEMDIR}"

	if [ -f "${DEMIN}.txt" ] 
		then 
			# AMSTer format DEM, i.e. binary file with a companion .txt descriptor 
			echo "  // AMSTer format DEM - must translate its .txt descriptor into an Envi .hdr"
			if [ ! -e "${GEOCDEMDIR}/${DEMBIN}" ] ; then cp -f "${DEMIN}" "${GEOCDEMDIR}/${DEMBIN}" ; fi
			cp -f "${DEMIN}.txt" "${GEOCDEMDIR}/${DEMBIN}.txt"
			echo "DEM_AMSTer_txt2Envi_hdr.sh ${GEOCDEMDIR}/${DEMBIN}.txt"
			DEM_AMSTer_txt2Envi_hdr.sh "${GEOCDEMDIR}/${DEMBIN}.txt"
		elif [ -f "${DEMIN}.hdr" ] 
			then 
				# Envi format DEM with a header named as the binary file + .hdr 
				echo "  // Envi format DEM - no need to translate "
				if [ ! -e "${GEOCDEMDIR}/${DEMBIN}" ] ; then cp -f "${DEMIN}" "${GEOCDEMDIR}/${DEMBIN}" ; fi
				cp -f "${DEMIN}.hdr" "${GEOCDEMDIR}/${DEMBIN}.hdr"
			elif [ "${DEMEXT}" = "tif" ] || [ "${DEMEXT}" = "tiff" ] 
				then 
					# tif format DEM - translate it in Envi format; note that the output file name is  
					# without extension, hence gdal_translate will name the header ${DEMBIN}.hdr 
					echo "  // tif format DEM - must translate it in Envi format with gdal_translate"
					DEMBIN="${DEMBIN%.*}_Envi"
					rm -f "${GEOCDEMDIR}/${DEMBIN}" "${GEOCDEMDIR}/${DEMBIN}.hdr"
					gdal_translate -q -of ENVI -ot Float32 "${DEMIN}" "${GEOCDEMDIR}/${DEMBIN}"
					if [ ! -f "${GEOCDEMDIR}/${DEMBIN}.hdr" ] 
						then 
							echo "  // gdal_translate failed to create ${GEOCDEMDIR}/${DEMBIN}.hdr. Exiting..."
							exit 1
					fi
				elif [ "${DEMIN%.*}" != "${DEMIN}" ] && [ -f "${DEMIN%.*}.hdr" ] 
					then 
						# Envi format DEM though with a header named with the extension of the binary 
						# file replaced by .hdr (e.g. DEM.bin and DEM.hdr, as created by gdal) 
						echo "  // Envi format DEM with header ${DEMIN%.*}.hdr - copy it as ${DEMBIN}.hdr"
						if [ ! -e "${GEOCDEMDIR}/${DEMBIN}" ] ; then cp -f "${DEMIN}" "${GEOCDEMDIR}/${DEMBIN}" ; fi
						cp -f "${DEMIN%.*}.hdr" "${GEOCDEMDIR}/${DEMBIN}.hdr"
					else 
						echo "  // No .txt nor .hdr file associated to ${DEMIN}, and not a tif file either; can't work. Exiting..."
						exit 1
	fi
	}

# Create the dir where the DEM and its derivatives will be stored
mkdir -p DEM

GEOCDEMDIR="${PWDDIR}/DEM"

cd DEM
echo 

# Check if a DEM cropped at the deformation maps' grid already exists in the msbas dir 
EXISTINGCROPPEDDEMHDR=$(find "${GEOCDEMDIR}" -mindepth 1 -maxdepth 1 -type f -name "*_cropped.hdr" 2>/dev/null | sort | head -1)

if [ "${EXISTINGCROPPEDDEMHDR}" != "" ] && [ "${FORCE}" != "Force" ]
	then
		DEMBIN=$(basename "${EXISTINGCROPPEDDEMHDR}" _cropped.hdr)
		echo "  // A DEM cropped at deformations' grid already exists in msbas dir, i.e. ${DEMBIN}_cropped.bin."
		echo "  // No need to recompute it. Use Force as second parameter if you want to recompute it."
#		# Need below to check size of the pixel
#		FIRSTLINK=$(ls ../DefoInterpolx2Detrend1/*deg | head -1)
#		PAIR=$(echo ${FIRSTLINK} | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}")
#		MAS=$(echo ${PAIR} | cut -d_ -f1)
#		SLV=$(echo ${PAIR} | cut -d_ -f2)
#		PATHTOGEOCODEDDATA=$(readlink -f ${FIRSTLINK} | ${PATHGNU}/gawk -F"Geocoded" '{print $1}' 2>/dev/null)  	# read target of link and get everything before Geocoded 
#		PAIRDIRPATH=$(ls -d ${PATHTOGEOCODEDDATA}/*${MAS}*${SLV}*)													# get full path to pair dir using MAS and SLV 
#		PAIRDIR=$(basename ${PAIRDIRPATH})

	else
		echo "  // No DEM sampled at deformations' grid yet in msbas dir (or Force is requested). Let's compute it."

		# Get the first deformation map of the first mode to invert: it provides the target grid at which 
		# the DEM must be cropped and, if no DEM is provided with -DEM=, it allows tracking where the pair 
		# was computed in order to get the DEM used at the time of the processing. 
		if [ "${DEFOMODE}" != "" ] 
			then 
				# mode provided with -DEFOMODE= 
				DEFOMODELIST="${DEFOMODE}"
			else 
				# no mode provided: search in the usual ones, from the most to the least processed 
				DEFOMODELIST="DefoInterpolx2Detrend1 DefoInterpolDetrend1 DefoInterpol1 Defo1"
		fi

		FIRSTLINK=""
		for DEFOMODEi in ${DEFOMODELIST}
			do
				FIRSTLINK=$(GetFirstDefoMap "${PWDDIR}/${DEFOMODEi}")
				if [ "${FIRSTLINK}" != "" ] ; then DEFOMODE="${DEFOMODEi}" ; break ; fi
			done

		if [ "${FIRSTLINK}" = "" ] 
			then 
				echo "  // I can't find any deformation map (in Envi or tif format) in ${PWDDIR}/{$(echo ${DEFOMODELIST} | tr ' ' ',')}. "
				echo "  // Hence I can't get the grid at which the DEM must be cropped. Exiting..."
				exit 1
		fi
		echo "  // Deformation maps of the first mode to invert are taken from ${DEFOMODE}"
		echo "  // Target grid is taken from $(basename ${FIRSTLINK})"

	if [ "${DEMPROVIDED}" != "" ] 
		then 
			# DEM provided with -DEM= ; no need to search it from the info of the deformation maps 
			PATHDEMVAR="${DEMPROVIDED}"
		else 
		# Track where the pair was computed in order to get the DEM used at the time of the processing 
		PAIR=$(echo ${FIRSTLINK} | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}")
		MAS=$(echo ${PAIR} | cut -d_ -f1)
		SLV=$(echo ${PAIR} | cut -d_ -f2)
		PATHTOGEOCODEDDATA=$(readlink "${FIRSTLINK}" | ${PATHGNU}/gawk -F"Geocoded" '{print $1}' 2>/dev/null)  	# read target of link and get everything before Geocoded ; Do not use -f option for readlink because not supported on Mac

		# trick to apply function to string instead of file
		PATHTOGEOCODEDDATAVAR=$(RenameVolNameToVariable <(printf '%s\n' "${PATHTOGEOCODEDDATA}") /dev/stdout) 		# ie. name of dir with variable instead of /Volumes/ or /mnt/ 
		eval "PATHTOGEOCODEDDATAVAR=\"$PATHTOGEOCODEDDATAVAR\""

		PAIRDIRPATH=$(find "${PATHTOGEOCODEDDATAVAR}" -maxdepth 1 -type d -name "*${MAS}*${SLV}*")													# get full path to pair dir using MAS and SLV 
		INSARTXTDIR="${PAIRDIRPATH}/i12/TextFiles"									# path to InSARParameters.txt where one can get the path to the img in SAR_CSL (with variable in name instead of mounting point name)
		
		SATID=$(GetParamFromFile "Scene ID" "masterSLCImageInfo.txt")		# e.g S1B_IW_SLC__1SDV_20211221T162011_20211221T162039_030125_0398E7_E162, Fast-24h
			SAT=$(echo "${SATID}" | cut -c 1-2)								# e.g. S1
			MODE=$(echo "${SATID}" | cut -d _ -f 2)							# e.g. IW
			if [ "${SAT}" == "S1" ] 
				then 
					if [ "${MODE}" == "IW" ] || [ "${MODE}" == "EW" ]
						then 
							S1MODE="WIDESWATH"
							#CROPDIR=/NoCrop
						else 
							S1MODE="STRIPMAP"
					fi
				else
					S1MODE="NOTS1"
			fi


		if [ "${S1MODE}" == "WIDESWATH" ] 
			then 
				# get the DEM from the master
				PATHMASCSL=$(GetParamFromFile "Master image file path [CSL image format]" "OriginalInSARParameters.txt")	# e.g. /Volumes/hp1660/SAR_CSL/S1/DRC_Funu_A_174/NoCrop/S1B_174_20211221_A.csl	
				# trick to apply function to string instead of file
				PATHMASCSLVAR=$(RenameVolNameToVariable <(printf '%s\n' "${PATHMASCSL}") /dev/stdout) 						# e.g. /$PATH_1660/SAR_CSL/S1/DRC_Funu_A_174/NoCrop/S1B_174_20211221_A.csl	
				eval "PATHMASCSLVAR=\"$PATHMASCSLVAR\""
				
				PATHDEM=$(GetParamFromFile "Georeferenced DEM file path" "externalSlantRangeDEM_IW.txt")						# e.g. //Volumes/DataSAR/SAR_AUX_FILES/DEM/COPERNICUS/ALL/Copernicus_DSM_E27-31_S00-04.tif_flip0.bil_CorrGeoid	
				# trick to apply function to string instead of file
				PATHDEMVAR=$(RenameVolNameToVariable <(printf '%s\n' "${PATHDEM}") /dev/stdout) 				# e.g. /$PATH_DataSAR/SAR_AUX_FILES/DEM/COPERNICUS/ALL/Copernicus_DSM_E27-31_S00-04.tif_flip0.bil_CorrGeoid	
				eval "PATHDEMVAR=\"$PATHDEMVAR\""

				# For debug
				echo "Path to DEM is ${PATHDEMVAR}"
			else
				# get the DEM from the super master
				PATHRESAMPLED=$(GetParamFromFile "Global master to master InSAR directory path" "OriginalInSARParameters.txt")	# e.g. //mnt/1650//SAR_SM/RESAMPLED/S1/KARTHALA_SM_A_86/SMCrop_SM_20220713_ComoresIsland_-11.94--11.34_43.22-43.53/20220713_S1A_86_20170516_A/i12/
				PATHRESAMPLED=$(dirname "${PATHRESAMPLED}") 																	# e.g. //mnt/1650//SAR_SM/RESAMPLED/S1/KARTHALA_SM_A_86/SMCrop_SM_20220713_ComoresIsland_-11.94--11.34_43.22-43.53/20220713_S1A_86_20170516_A
				PAIRRESAMPLED=$(basename "${PATHRESAMPLED}") 					# e.g. 20220713_S1A_86_20170516_A
				SUPERMASDATE=$(echo "${PAIRRESAMPLED}" | cut -d _ -f 1)			# e.g. 20220713
				
				PATHCSL=$(GetParamFromFile "Master image file path [CSL image format]" "OriginalInSARParameters.txt")		# e.g. /mnt/1650/SAR_CSL/S1/KARTHALA_SM_A_86/Crop_ComoresIsland_-11.94--11.34_43.22-43.53/S1A_86_20170516_A.csl
				PATHCSL=$(dirname "${PATHCSL}") 																# e.g. /mnt/1650/SAR_CSL/S1/KARTHALA_SM_A_86/Crop_ComoresIsland_-11.94--11.34_43.22-43.53
				# trick to apply function to string instead of file
				PATHCSLVAR=$(RenameVolNameToVariable <(printf '%s\n' "${PATHCSL}") /dev/stdout) 				# e.g. /$PATH_1650/SAR_CSL/S1/KARTHALA_SM_A_86/Crop_ComoresIsland_-11.94--11.34_43.22-43.53
				eval "PATHCSLVAR=\"$PATHCSLVAR\""
				
				PATHSM=$(find "${PATHCSLVAR}" -type d -name "*${SUPERMASDATE}*")		# path to Super Master CSL img

				PATHDEM=$(GetParamFromFile "Georeferenced DEM file path" "externalSlantRangeDEM_SM.txt")						# e.g. //Volumes/DataSAR/SAR_AUX_FILES/DEM/COPERNICUS/ALL/Copernicus_DSM_E27-31_S00-04.tif_flip0.bil_CorrGeoid	
				# trick to apply function to string instead of file
				PATHDEMVAR=$(RenameVolNameToVariable <(printf '%s\n' "${PATHDEM}") /dev/stdout) 				# e.g. /$PATH_DataSAR/SAR_AUX_FILES/DEM/COPERNICUS/ALL/Copernicus_DSM_E27-31_S00-04.tif_flip0.bil_CorrGeoid	
				eval "PATHDEMVAR=\"$PATHDEMVAR\""

				# For debug
				echo "Path to DEM is ${PATHDEMVAR}"
		fi
	fi		# end of test on DEM provided with -DEM= 
		
		# cp DEM in ${GEOCDEMDIR} and ensure it is in Envi format there (i.e. ${GEOCDEMDIR}/${DEMBIN} 
		# and ${GEOCDEMDIR}/${DEMBIN}.hdr); this sets DEMBIN 
		PrepareDEM "${PATHDEMVAR}"
	
		# Crop DEM to the size and grid of the first deformation map of the first mode to invert 
		TARGET=$(readlink "${FIRSTLINK}" 2>/dev/null)  												# read target of link, e.g. /mnt/3611/SAR_MASSPROCESS/S1/Nepal_D_19/SMNoCrop_SM_20180928_Zoom1_ML2/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened.blablabal.7deg
		if [ "${TARGET}" = "" ] ; then TARGET="${FIRSTLINK}" ; fi									# it was not a link but a file 

		# trick to apply function to string instead of file
		TARGETVAR=$(RenameVolNameToVariable <(printf '%s\n' "${TARGET}") /dev/stdout) 	# ie. name of dir with variable instead of /Volumes/ or /mnt/, e.g. /$PATH_3611/SAR_MASSPROCESS/S1/Nepal_D_19/SMNoCrop_SM_20180928_Zoom1_ML2/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened.blablabal.7deg
		eval "TARGETVAR=\"$TARGETVAR\""

		# CropDEM2targetHDR.sh expects the target to be an Envi file with a header named target.hdr; 
		# if the deformation map is in tif format, or if its header is named with the extension of the 
		# binary file replaced by .hdr, create in ${GEOCDEMDIR} what is needed to describe the target grid 
		case "${TARGETVAR}" in 
			*.tif|*.tiff|*.TIF|*.TIFF)
				echo "  // First deformation map is in tif format; translate it in Envi format to get the target grid"
				TARGETGRID="${GEOCDEMDIR}/TargetGrid_$(basename "${TARGETVAR}" | ${PATHGNU}/gsed 's/\.[Tt][Ii][Ff][Ff]*$//')"
				rm -f "${TARGETGRID}" "${TARGETGRID}.hdr"
				gdal_translate -q -of ENVI "${TARGETVAR}" "${TARGETGRID}"
				if [ ! -f "${TARGETGRID}.hdr" ] 
					then 
						echo "  // gdal_translate failed to create ${TARGETGRID}.hdr. Exiting..."
						exit 1
				fi
				TARGETVAR="${TARGETGRID}" ;;
			*)	
				if [ ! -f "${TARGETVAR}.hdr" ] 
					then 
						if [ "${TARGETVAR%.*}" != "${TARGETVAR}" ] && [ -f "${TARGETVAR%.*}.hdr" ] 
							then 
								echo "  // Header of the first deformation map is named ${TARGETVAR%.*}.hdr; make a copy named as expected by CropDEM2targetHDR.sh"
								TARGETGRID="${GEOCDEMDIR}/TargetGrid_$(basename "${TARGETVAR}")"
								rm -f "${TARGETGRID}" "${TARGETGRID}.hdr"
								ln -s "${TARGETVAR}" "${TARGETGRID}" 						# link only, to avoid duplicating the data 
								cp -f "${TARGETVAR%.*}.hdr" "${TARGETGRID}.hdr"
								TARGETVAR="${TARGETGRID}"
							else 
								echo "  // Can't find the header of the first deformation map ${TARGETVAR}, hence I can't get the target grid. Exiting..."
								exit 1
						fi
				fi ;;
		esac

		# crop DEM, which is then ${GEOCDEMDIR}/${DEMBIN}_cropped.bin
		echo "CropDEM2targetHDR.sh ${GEOCDEMDIR}/${DEMBIN} ${TARGETVAR}"
		CropDEM2targetHDR.sh "${GEOCDEMDIR}/${DEMBIN}" "${TARGETVAR}"
		
		
		####PAIRDIR=$(basename ${PAIRDIRPATH})
		####
		####mkdir -p ${PAIRDIR}/i12/GeoProjection
		####mkdir -p ${PAIRDIR}/i12/InSARProducts
		####mkdir -p ${PAIRDIR}/i12/TextFiles
		####
		####cp ${PAIRDIRPATH}/i12/InSARProducts/externalSlantRangeDEM ./${PAIRDIR}/i12/InSARProducts/ 
		####cp -R ${PAIRDIRPATH}/i12/InSARProducts/*${SLV}*.interpolated.csl ./${PAIRDIR}/i12/InSARProducts/
		####cp -R ${PAIRDIRPATH}/i12/TextFiles/* ./${PAIRDIR}/i12/TextFiles/ 
		####
		####cd ./${PAIRDIR}/i12/TextFiles
		####
		##### Update path in param files
		#####cp -n InSARParameters.txt InSARParameters_original.txt 					# do not copy if exist already
		#####cp -n geoProjectionParameters.txt geoProjectionParameters_original.txt 	# do not copy if exist already
		####if [ ! -e InSARParameters_original.txt ] ; then cp InSARParameters.txt InSARParameters_original.txt ; fi 
		####if [ ! -e geoProjectionParameters_original.txt ] ; then cp geoProjectionParameters.txt geoProjectionParameters_original.txt ; fi
		####
		####MASPATH=`GetParamFromFile "Master image file path" InSARParameters.txt`
		####
		####if [[ ! -d "${MASPATH}" ]] 
		####	then 
		####		echo "No Primary image found in ${MASPATH}." 
		####		echo "Updating path to the Primary image in ${GEOCDEMDIR}/${PAIRDIR}/i12/TextFiles/InSARParameters.txt" 
		####
		####		source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
		####		#cp -n InSARParameters.txt InSARParameters_original.txt # do not copy if exist already
		####		if [ ! -e InSARParameters_original.txt ] ; then cp InSARParameters.txt InSARParameters_original.txt ; fi 
		####		RenameVolNameToVariable InSARParameters_original.txt InSARParameters.txt
		####
		####		eval MASPATH=`GetParamFromFile "Master image file path" InSARParameters.txt`
		####		if [[ ! -d "${MASPATH}" ]] 
		####			then 
		####				echo "Still no primary image found in ${MASPATH}. Check you files. Exiting..."
		####		fi				
		####fi
		####
		####${PATHGNU}/gsed "s%^.*${PAIRDIR}%${GEOCDEMDIR}\/${PAIRDIR}%g" InSARParameters_original.txt > InSARParameters.txt
		####${PATHGNU}/gsed "s%^.*${PAIRDIR}%${GEOCDEMDIR}\/${PAIRDIR}%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt
		####
		##### change which products to geocode 
		####ChangeGeocParam "Geoproject measurement (slant range topography or deformation map)" "NO" 
		####ChangeGeocParam "Geoproject master amplitude" "NO" 
		####ChangeGeocParam "Geoproject slave amplitude" "NO" 
		####ChangeGeocParam "Geoproject coherence" "NO" 	
		####ChangeGeocParam "Geoproject interferogram" "NO" 
		####ChangeGeocParam "Geoproject filtered interferogram" "NO" 
		####ChangeGeocParam "Geoproject residual interferogram" "NO" 
		####ChangeGeocParam "Geoproject unwrapped phase" "NO" 
		####
		##### change path with state variables 
		####RenamePath_Volumes.sh ${GEOCDEMDIR}/${PAIRDIR}/
		####
		##### Because of a bug in geoProjection, one must ensure that there is a non-empty Data and Headers dir in InSARProducts
		####	RESAMPSLVPATH=$(find ${GEOCDEMDIR}/${PAIRDIR}/i12/InSARProducts/ -maxdepth 1 -type d -name "*${SLV}*.interpolated.csl" )
		####	if [ ! -d "${RESAMPSLVPATH}/Data" ]
		####		then 
		####			mkdir -p ${RESAMPSLVPATH}/Data
		####			touch ${RESAMPSLVPATH}/Data/Dummy.txt
		####	fi 
		####	if [ ! -d "${RESAMPSLVPATH}/Headers" ]
		####		then 
		####			mkdir -p ${RESAMPSLVPATH}/Headers
		####			touch ${RESAMPSLVPATH}/Headers/Dummy.txt
		####	fi 
		####
		####cd ..	# now in /${PAIRDIR}/i12/				
		##### old bug  in geoProjection prevents following links 
		####	cd .. # now in /${PAIRDIR}
		####	cd .. 
		####	# Check OS
		####	OS=`uname -a | cut -d " " -f 1 `
		####
		####	case ${OS} in 
		####		"Linux") 
		####			RenamePath_Volumes_VARtoMNT.sh ;;
		####		"Darwin")
		####			RenamePath_Volumes_VARtoVol.sh 	;;
		####		*)
		####			echo "Can't figure out you OS, hence I can't change paths in text files'" 	;;
		####	esac
		####	cd ${PAIRDIR}/i12		# back in /${PAIRDIR}/i12/			
		####geoProjection -e -r # -r is to get Envi format and -e aims at geocoding the slantRangeDEM 
		####
		##### mv dem and header in GEOCDEMDIR
		####mv ./GeoProjection/externalSlantRangeDEM.UTM* ${GEOCDEMDIR}/
		####
		####cd ${GEOCDEMDIR}
fi



## get the size of the pixel 
#PIXSIZEX=`GetParamFromFile "Easting sampling" geoProjectionParameters.txt`
#PIXSIZEY=`GetParamFromFile "Northing sampling" geoProjectionParameters.txt`
#if [ ${PIXSIZEX} -ne ${PIXSIZEY} ] ; then echo "DEM with not square pixels ? CScript not designed for filtering that kind of DEM; exit" ; exit ; fi

####ENVIDEMHDR=$(find ${GEOCDEMDIR}/ -maxdepth 1 -type f -name "externalSlantRangeDEM.UTM*.hdr")
####ENVIDEM=$(find ${GEOCDEMDIR}/ -maxdepth 1 -type f -name "externalSlantRangeDEM.UTM*.bil")
cd ${GEOCDEMDIR}
ENVIDEMHDR="${DEMBIN}_cropped.hdr"
ENVIDEM="${DEMBIN}_cropped.bin"

if [ ! -f "${GEOCDEMDIR}/${ENVIDEM}" ] || [ ! -f "${GEOCDEMDIR}/${ENVIDEMHDR}" ] 
	then 
		echo "  // ${GEOCDEMDIR}/${ENVIDEM} and/or its header do not exist; the cropping of the DEM at the deformations' grid probably failed. Exiting..."
		exit 1
fi


#UTMZONE=$(gmt grdinfo -M "${ENVIDEM}" | grep -oP '(?<=\+zone=)\d+')
#ZONEDEF=$(gmt grdinfo -M "${ENVIDEM}" | grep "proj")


# Computation using transformation in LatLong and geotif using commands described by Sergey Samsonov. 
# However, it introduces distortions and the resulting number of lines and pixels differs. 

# echo
# # Transform in geotiff if needed
# if test -e ${GEOCDEMDIR}/DEM.tif && [ "${FORCE}" != "Force" ]
# 	then
# 		echo "  // DEM already in geotiff format."
# 	else
# 		echo "  // Need to transform DEM in geotiff."
# 		gdal_translate -of GTiff ${ENVIDEM} DEM.tif
# fi
# echo
# # Transform in latLong if needed
# if test -e ${GEOCDEMDIR}/DEM_LL.tif && [ "${FORCE}" != "Force" ]
# 	then
# 		echo "  // DEM already in LatLong format."
# 	else
# 		echo "  // Need to transform DEM in LatLong format."
# 		gdalwarp -t_srs EPSG:4326 DEM.tif DEM_LL.tif		# may need option -tr TARGET_XRES TARGET_YRES to keep same nr of lines and pix, but it may introduce distortions
# fi
# 
# echo 
# # Filter if needed
# if test -e ${GEOCDEMDIR}/DEM_LL_flt.tif && [ "${FORCE}" != "Force" ]
# 	then
# 		echo "  // DEM already filtered."
# 	else
# 		echo "  // Need to filter the DEM."
# 		#gmt grdfilter dem.tif -D2 -Fg${FG} -fg -Gdem_flt.tif=gd+n0:Gtiff 	# if DEM is in geographic distance - FG muste be even
# 		gmt grdfilter DEM_LL.tif -D2 -Fg${FG} -fg -GDEM_LL_flt.tif=gd+n0:Gtiff 	# if DEM is in cartesian coord - FG muste be odd !!
# fi
# echo 
# # Compute second derivative in NS if needed
# if test -e ${GEOCDEMDIR}/DEM_grad_north.tif && [ "${FORCE}" != "Force" ]
# 	then
# 		echo "  // Seconde derivative of DEM in NS already computed."
# 	else
# 		echo "  // Need to compute the second derivative of DEM in NS."
# 		gmt grdmath DEM_LL_flt.tif DDY 0 DENAN -M -fg = DEM_grad_north.tif=gd+n0:Gtiff	# old dem_flt_ns.tif
# 		cp DEM_grad_north.tif DEM_grad_north_FG${FG}.tif
# fi
# echo 
# # Compute second derivative in EW if needed
# if test -e ${GEOCDEMDIR}/DEM_grad_east.tif && [ "${FORCE}" != "Force" ]
# 	then
# 		echo "  // Seconde derivative of DEM in EW already computed."
# 	else
# 		echo "  // Need to compute the second derivative of DEM in EW."
# 		gmt grdmath DEM_LL_flt.tif DDX 0 DENAN -M -fg = DEM_grad_east.tif=gd+n0:Gtiff # old dem_flt_ew.tif
# 		cp DEM_grad_east.tif DEM_grad_east_FG${FG}.tif
# fi
# echo 
# 
# # need to get back to the UTM 
# echo "gdalwarp -t_srs ${ZONEDEF} DEM_grad_north.tif DEM_grad_north_UTM.tif"
# gdalwarp -t_srs "${ZONEDEF}" DEM_grad_north.tif DEM_grad_north_UTM.tif
# gdalwarp -t_srs "${ZONEDEF}" DEM_grad_east.tif DEM_grad_east_UTM.tif
# # then back in Envi Harris format and mv grad files in PWDDIR
# gdal_translate -of ENVI DEM_grad_north_UTM.tif ../DEM_grad_north_UTM.bil
# gdal_translate -of ENVI DEM_grad_east_UTM.tif ../DEM_grad_east_UTM.bil

# Do the same directly in UTM and ENVI Harris format using python, in DEM dir
# Forward the clipping threshold to Filter_and_Gradient.py only if provided (else it uses its own default) 
if [ "${THRESHOLD}" != "" ] ; then THRESHOLDPARAM="threshold=${THRESHOLD}" ; else THRESHOLDPARAM="" ; fi

echo "DEBUG: Filter_and_Gradient.py ${ENVIDEM} ${FG} ${THRESHOLDPARAM}"
Filter_and_Gradient.py "${ENVIDEM}" ${FG} ${THRESHOLDPARAM} #${FIRSTLINESTOREMOVE}

# Keep track of half windows filter size used
cp -f DEM_grad_north.bin DEM_grad_north_${FG}.bin
cp -f DEM_grad_east.bin DEM_grad_east_${FG}.bin
# Create header 
#cp -f ${ENVIDEMHDR} DEM_grad_north_${FG}.hdr
#cp -f ${ENVIDEMHDR} DEM_grad_east_${FG}.hdr
cp -f DEM_grad_north.hdr DEM_grad_north_${FG}.hdr
cp -f DEM_grad_east.hdr  DEM_grad_east_${FG}.hdr

# mv the gradient files where they will be needed for msbas inversion
mv -f DEM_grad_north.bin ../DEM_grad_north.bin 
mv -f DEM_grad_east.bin ../DEM_grad_east.bin
#cp -f DEM_grad_east_${FG}.hdr ../DEM_grad_north.hdr
#cp -f DEM_grad_north_${FG}.hdr ../DEM_grad_east.hdr
cp -f DEM_grad_north.hdr ../DEM_grad_north.hdr
cp -f DEM_grad_east.hdr  ../DEM_grad_east.hdr

# Add DD_NSEW_FILES=topo_grad_north.tif,topo_grad_east.tif flag in header.txt below line V_FLAG=0
cd ${PWDDIR}

#cp -n header.txt header_original_no_TopoDeriv.txt
if [ ! -e header_original_no_TopoDeriv.txt ] ; then cp header.txt header_original_no_TopoDeriv.txt ; fi 

#${PATHGNU}/gsed -i '/V_FLAG=0/a\DD_NSEW_FILES=topo_grad_north.tif,topo_grad_east.tif' header.txt
# not sure it works with path 
AddFlag "DD_NSEW_FILES" "DD_NSEW_FILES = DEM_grad_north.bin,DEM_grad_east.bin" 

# Add D_FLAG: 0=3D, 1=4D - use only 3D 
AddFlag "D_FLAFG" "D_FLAFG = 0"

# Ensure C_FLAG = 10 
ChgeFlag "C_FLAFG" "C_FLAFG = 10"

# Some cleaning in ${GEOCDEMDIR}
#cd ${GEOCDEMDIR}
	


echo 
echo "  // Now your header.txt looks like:"
cat header.txt 
echo
echo
echo "  // ==> your files should be ready for a 3D msbas processing. Execute the following command:"
echo "         MSBAS.sh ...."
echo ""
echo "  // IF YOU SEE TOO MUCH GAPS IN YOUR GRADIENT FILES, EITHER "
echo "      - RERUN WITH A LARGER -THRESHOLD=value (in m/m; e.g. -THRESHOLD=0.8) TO CLIP FEWER PIXELS, OR "
echo "      - INCREASE THE SIZE OF THE FILTERING WINDOW "
echo ""
echo "  // All done. Hope it works "
echo 

