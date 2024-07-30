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
# The script will first check if a geocoded DEM at the same grid as the deformation maps 
# exists. Then it will detrend and apply a Gaussian spatial filter, 
# then compute the first derivatives along X and Y directions (i.e. EW and NS)
# 
# Parameters are : 
#       - FG: width of the Gaussian kernel filter (in meters - e.g 10000 that is 10km) 
#		- optional : if "Force", it will recompute the filtering of the DEM and then the 
#			NS and EW gradients. Useful when testing several filtering 
#		- xx: for specific case where a water body located to the North of the image 
#			  induced a strong NS trend: remove xx first lines and replace with NaN 
#			  (need to be 3rd param, hence Force is mandatory as param 2) 
#
# ex: in /$PATH_3602/MSBAS/_Funu_S1_Auto_Max3Shortests, run
#		Add_NS_comp_msbas.sh 10000 Force 
#       
# Dependencies:	- (GMT and gdal if works with geotif files like Sergey Samsonov - NOT HERE)
#				- python 3.10 with scipy and numpy modules
#				- Filter_and_Gradient.py script
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
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Mar 05, 2024"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# vvv ----- Hard coded lines to check --- vvv 
source $HOME/.bashrc 
# ^^^ ----- Hard coded lines to check -- ^^^ 

FG=$1	# size of the filtering window in km (e.g. 10)
FORCE=$2
#FIRSTLINESTOREMOVE=$3

PWDDIR=$(pwd)

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
# Create the dir where the DEM and its derivatives will be stored
mkdir -p DEM

GEOCDEMDIR="${PWDDIR}/DEM"

cd DEM
echo 

if test -e ${GEOCDEMDIR}/externalSlantRangeDEM.UTM*.hdr
	then
		echo "  // External slant range DEM already computed at deformations' grid in msbas dir. No need to recompute it."
#		# Need below to check size of the pixel
#		FIRSTLINK=$(ls ../DefoInterpolx2Detrend1/*deg | head -1)
#		PAIR=$(echo ${FIRSTLINK} | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}")
#		MAS=$(echo ${PAIR} | cut -d_ -f1)
#		SLV=$(echo ${PAIR} | cut -d_ -f2)
#		PATHTOGEOCODEDDATA=$(readlink -f ${FIRSTLINK} | ${PATHGNU}/gawk -F"Geocoded" '{print $1}' 2>/dev/null)  	# read target of link and get everything before Geocoded 
#		PAIRDIRPATH=$(ls -d ${PATHTOGEOCODEDDATA}/*${MAS}*${SLV}*)													# get full path to pair dir using MAS and SLV 
#		PAIRDIR=$(basename ${PAIRDIRPATH})

	else
		echo "  // No DEM sampled at deformations' grid yet in msbas dir. Let's compute it."
		# Get the first deformation map from the first DefoInterpolx2Detrendi because this must always exist and 
		# track where the pair was computed in order to recompute it and geocode the externalSlantrangeDEM thanks 
		# to the -e option
		FIRSTLINK=$(find ${PWDDIR}/DefoInterpolx2Detrend1/ -maxdepth 1 -name "*deg" 2>/dev/null | head -1)
		if [ "${FIRSTLINK}" == "" ] 
			then 
				# There is no file in DefoInterpolx2Detrend1, search in DefoInterpolDetrend1
				FIRSTLINK=$(find ${PWDDIR}/DefoInterpolDetrend1/ -maxdepth 1 -name "*deg" 2>/dev/null | head -1) 
				if [ "${FIRSTLINK}" == "" ] 
					then 
						# There is no file in DefoInterpolDetrend1, search in DefoInterpol1
						FIRSTLINK=$(find ${PWDDIR}/DefoInterpol1/ -maxdepth 1 -name "*deg" 2>/dev/null | head -1) 
						if [ "${FIRSTLINK}" == "" ] 
							then 
								# There is no file in DefoInterpol1, search in Defo1
								FIRSTLINK=$(find ${PWDDIR}/Defo1/ -maxdepth 1 -name "*deg" 2>/dev/null | head -1) 
								if [ "${FIRSTLINK}" == "" ] 
									then 
										# There is no file at all - can't make the fig with amplitude background
										echo "  // I can't find a deformation file in ../Defo[Interpol][x2][Detrend]1. "
										echo "  // Hence I can't figure out where the pair was computed and will not be able to recompute it to geocode the DEM " 
								fi
						fi
				fi
		fi

		PAIR=$(echo ${FIRSTLINK} | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}")
		MAS=$(echo ${PAIR} | cut -d_ -f1)
		SLV=$(echo ${PAIR} | cut -d_ -f2)
		PATHTOGEOCODEDDATA=$(readlink -f ${FIRSTLINK} | ${PATHGNU}/gawk -F"Geocoded" '{print $1}' 2>/dev/null)  	# read target of link and get everything before Geocoded 
		PAIRDIRPATH=$(ls -d ${PATHTOGEOCODEDDATA}/*${MAS}*${SLV}*)													# get full path to pair dir using MAS and SLV 
		PAIRDIR=$(basename ${PAIRDIRPATH})
		
		mkdir -p ${PAIRDIR}/i12/GeoProjection
		mkdir -p ${PAIRDIR}/i12/InSARProducts
		mkdir -p ${PAIRDIR}/i12/TextFiles
		
		cp ${PAIRDIRPATH}/i12/InSARProducts/externalSlantRangeDEM ./${PAIRDIR}/i12/InSARProducts/ 
		cp -R ${PAIRDIRPATH}/i12/InSARProducts/*${SLV}*.interpolated.csl ./${PAIRDIR}/i12/InSARProducts/
		cp -R ${PAIRDIRPATH}/i12/TextFiles/* ./${PAIRDIR}/i12/TextFiles/ 

		cd ./${PAIRDIR}/i12/TextFiles
	
		# Update path in param files
		cp -n InSARParameters.txt InSARParameters_original.txt 					# do not copy if exist already
		cp -n geoProjectionParameters.txt geoProjectionParameters_original.txt 	# do not copy if exist already
		
		
		MASPATH=`GetParamFromFile "Master image file path" InSARParameters.txt`
	
		if [[ ! -d "${MASPATH}" ]] 
			then 
				echo "No Primary image found in ${MASPATH}." 
				echo "Updating path to the Primary image in ${GEOCDEMDIR}/${PAIRDIR}/i12/TextFiles/InSARParameters.txt" 

				source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
				cp -n InSARParameters.txt InSARParameters_original.txt # do not copy if exist already
				RenameVolNameToVariable InSARParameters_original.txt InSARParameters.txt

				eval MASPATH=`GetParamFromFile "Master image file path" InSARParameters.txt`
				if [[ ! -d "${MASPATH}" ]] 
					then 
						echo "Still no primary image found in ${MASPATH}. Check you files. Exiting..."
				fi				
		fi
		
		${PATHGNU}/gsed "s%^.*${PAIRDIR}%${GEOCDEMDIR}\/${PAIRDIR}%g" InSARParameters_original.txt > InSARParameters.txt
		${PATHGNU}/gsed "s%^.*${PAIRDIR}%${GEOCDEMDIR}\/${PAIRDIR}%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt
		
		# change which products to geocode 
		ChangeGeocParam "Geoproject measurement (slant range topography or deformation map)" "NO" 
		ChangeGeocParam "Geoproject master amplitude" "NO" 
		ChangeGeocParam "Geoproject slave amplitude" "NO" 
		ChangeGeocParam "Geoproject coherence" "NO" 	
		ChangeGeocParam "Geoproject interferogram" "NO" 
		ChangeGeocParam "Geoproject filtered interferogram" "NO" 
		ChangeGeocParam "Geoproject residual interferogram" "NO" 
		ChangeGeocParam "Geoproject unwrapped phase" "NO" 
	
		# Because of a bug in geoProjection, one must ensure that there is a non-empty Data and Headers dir in InSARProducts
			RESAMPSLVPATH=$(find ${GEOCDEMDIR}/${PAIRDIR}/i12/InSARProducts/ -maxdepth 1 -type d -name "*${SLV}*.interpolated.csl" )
			if [ ! -d "${RESAMPSLVPATH}/Data" ]
				then 
					mkdir -p ${RESAMPSLVPATH}/Data
					touch ${RESAMPSLVPATH}/Data/Dummy.txt
			fi 
			if [ ! -d "${RESAMPSLVPATH}/Headers" ]
				then 
					mkdir -p ${RESAMPSLVPATH}/Headers
					touch ${RESAMPSLVPATH}/Headers/Dummy.txt
			fi 
		
		cd ..
		geoProjection -e -r # -r is to get Envi format and -e aims at geocoding the slantRangeDEM 
		
		# mv dem and header in GEOCDEMDIR
		mv ./GeoProjection/externalSlantRangeDEM.UTM* ${GEOCDEMDIR}/
		
		cd ${GEOCDEMDIR}
fi

## get the size of the pixel 
#PIXSIZEX=`GetParamFromFile "Easting sampling" geoProjectionParameters.txt`
#PIXSIZEY=`GetParamFromFile "Northing sampling" geoProjectionParameters.txt`
#if [ ${PIXSIZEX} -ne ${PIXSIZEY} ] ; then echo "DEM with not square pixels ? CScript not designed for filtering that kind of DEM; exit" ; exit ; fi

ENVIDEMHDR=$(find ${GEOCDEMDIR}/ -maxdepth 1 -type f -name "externalSlantRangeDEM.UTM*.hdr")
ENVIDEM=$(find ${GEOCDEMDIR}/ -maxdepth 1 -type f -name "externalSlantRangeDEM.UTM*.bil")


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
Filter_and_Gradient.py ${ENVIDEM} ${FG} #${FIRSTLINESTOREMOVE}

# Keep track of half windows filter size used
cp -f DEM_grad_north.bin DEM_grad_north_${FG}.bin
cp -f DEM_grad_east.bin DEM_grad_east_${FG}.bin
# Create header 
cp -f ${ENVIDEMHDR} DEM_grad_north_${FG}.hdr
cp -f ${ENVIDEMHDR} DEM_grad_east_${FG}.hdr


# mv the gradient files where they will be needed for msbas inversion
mv -f DEM_grad_north.bin ../DEM_grad_north.bin 
mv -f DEM_grad_east.bin ../DEM_grad_east.bin
cp -f DEM_grad_east_${FG}.hdr ../DEM_grad_north.hdr
cp -f DEM_grad_north_${FG}.hdr ../DEM_grad_east.hdr


# Add DD_NSEW_FILES=topo_grad_north.tif,topo_grad_east.tif flag in header.txt below line V_FLAG=0
cd ${PWDDIR}

cp -n header.txt header_original_no_TopoDeriv.txt

#${PATHGNU}/gsed -i '/V_FLAG=0/a\DD_NSEW_FILES=topo_grad_north.tif,topo_grad_east.tif' header.txt
# not sure it works with path 
AddFlag "DD_NSEW_FILES" "DD_NSEW_FILES = DEM_grad_north.bin,DEM_grad_east.bin" 

# Add D_FLAG: 0=3D, 1=4D - use only 3D 
AddFlag "D_FLAFG" "D_FLAFG = 0"

# Ensure C_FLAG = 10 
ChgeFlag "C_FLAFG" "C_FLAFG = 10"


echo 
echo "  // Now your header.txt looks like:"
cat header.txt
echo
echo
echo "  // ==> your files should be ready for a 3D msbas processing. Execute the following command:"
echo "         MSBAS.sh ...."
echo "  // All done. Hope it works "
echo 

