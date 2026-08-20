#!/bin/bash
# This script transform
# - a Geotif DEM (for which the coordinates of the UL reference pixel are the coordinates of its center), or 
# - an Envi Harris DEM and its .hdr file (for which the coordinates of the UL reference pixel are the coordinates of its upper left corner)
# (in GIS order) into a flipped DEM with its corresponding .txt file (in math order).
#
# Not sure about the validity of transforming Envi ESRI/ArcGis DEM and its .hdr file 
# because the coordinates of the UL reference pixel are the coordinates of its center... 
#
#
# Input DEM is supposed to be in Lat Long.
#
# NOTE: Envi DEM must be named e.g. 
#		your_name.bin and your_name.bin.hdr or  
#		your_name.nvi and your_name.nvi.hdr or  
#		your_name and your_name.hdr   
#
# It will apply the geoidal height correction if possible: 
#	- For SRTM or COPERNICUS DEM, it will use resp. EGM96 and EGM2008 
#	- for OTHER type of DEM, you must tell the script which EGM to use
# providing that the EGM are in the appropriate directory, that is e.g. 
#   $PATH_DataSAR/SAR_AUX_FILES/EGM/EGM96 or 
#	$PATH_DataSAR/SAR_AUX_FILES/EGM/EGM2008 ..
#   
#
# REMEMBER that AMSTerEngine takes in priority the txt header file if both txt and hdr are present. 
#
# If DEM is referred to Geoid, it computes directly the height correction.
#
# Note: The script can't check if the DEM is referred to the Geoid or the Ellispoid. 
#		You must tell him...
#
#
# Parameter: - path to Envi DEM 
#			 - type of DEM: SRTM, COPERNICUS or OTHER
#			 - type of EGM (if not SRTM nor COPERNICUS)	
#
# Dependencies: - $PATHGNU/ggrep
#				- dgalinfo
#				- python3.10 flip_raster.py script
#				- agregateSRTMTiles or getSRTMDEM for correcting geoidal height
#				- EGM in appropriate directory
#
# New in V1.1:	- if DEM is referred to Geoid, it computes directly the height correction
# New in V1.2:	- force output DEM in env i format as float32
# New in V2.0:	- correct bug ref pixel in .txt 
#				- used awk to get coordinates instead of cut
# New in V2.1:	- correct bug ref pixel in .txt when tif format 
# New in V2.2:	- remove call python to launch python script to keep that info from script itself 
# New in V2.3:	- ensure that sampling are positive values 
#				- no need to offset by half LLLONGSAMPL or LLLATGSAMPL because dgal takes into account
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh 
# New in Distro V 4.0 20231030: - Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.0 20231030: - Add line in .txt with Excluding values 
# New in Distro V 5.0 20241009: - Cope with new fct getSRTMDEM instead of agregateSRTMTiles since AMSTerEngine V Oct 2024 
# New in Distro V 6.0 20260213: - Cope with new fct geoidal2EllipsoidalDEM instead of agregateSRTMTiles or getSRTMDEM since AMSTerEngine V Jan 2026 
# New in Distro V 7.0 20260216: - If not Lat Long (dd), convert UTM to WGS84 Lat/Long (EPSG:4326)
# New in Distro V 7.1 20260312: - do not use flip_raster.py because it requires osgeo, which might be 
#								  a problem with some OS
#
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V7.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Mar 12, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# Parameters
DEM=$1 	# path to dem (envi without .hdr, or .tif)
TYPE=$2	# SRTM, COPERNICUS or OTHER
TYPE=$(printf '%s' "${TYPE}" | tr '[:lower:]' '[:upper:]')   # convert to uppercase

# because it relies on gdalinfo... 
command -v gdalinfo >/dev/null 2>&1 || { echo "gdalinfo not found"; exit 1; }
 
case ${TYPE} in 
	SRTM)
		echo "Converting SRTM DEM; will use EGM96 geoidal height correction if required"
		# needed for later
		HEIGHT="Ellipsoidal - EGM96 geoidal height added		/* Height type */"
		;;
	COPERNICUS)
		echo "Converting COPERNICUS DEM; will use EGM2008 geoidal height correction if required"
		# needed for later
		HEIGHT="Ellipsoidal - EGM2008 geoidal height added		/* Height type */"
		;;
	OTHER)
		echo "Converting DEM from unknown format."
		EGM=$3
		if [ "${EGM}" == "" ]
			then 
				echo "However, you haven't provided me whith the EGM corresponding to your DEM (EGM96 or EGM2008...) as 3rd parameter. "
				echo " I can't work... exiting"
				exit
			else

				if [[ "${EGM}" =~ ^EGM[0-9]+$ ]]; then
				    echo "Using EGM ${EGM}"
				else
				    echo "You provided an EGM with invaliud format though. It must be EGMxx where xx is the date of your EGM, eg EGM96 or EGM2008"
				    exit
				fi
				# needed for later
				HEIGHT="Ellipsoidal - ${EGM} geoidal height added		/* Height type */"
		fi
		;;
	*)
		echo "Please specify as 2nd parameter which type of DEM you want to convert: SRTM, COPERNICUS or OTHER "
		exit
		;;
esac

echo ""

if [ $# -lt 2 ] ; then echo " Usage $0 Path_to_DEM_LatLong_ENVI Type_Of_DEM [EGM] "; exit; fi

if [ ! -f "${DEM}" ] ; then echo "DEM does not exist. Please check"; echo ; exit ; fi 

if [ -f "${DEM}.txt" ] ; then echo "DEM.txt already exist. Please check"; echo ; exit ; fi 

############################################################
#  Normalize input DEM and detect format
############################################################
EXT="${DEM##*.}"		# give the extension 

if [[ "$EXT" == "hdr" ]]; then
    echo "Provide the DEM data file, not the .hdr file."
    exit
fi

# ENVI case: if .hdr exists, treat as ENVI
if [[ -f "${DEM}.hdr" ]]; then
    FORMATDEM="ENVI"
    DEM_DATA="${DEM}"            # may or may not contain .bin
elif [[ "$EXT" == "bin" && -f "${DEM%.*}.hdr" ]]; then
    FORMATDEM="ENVI"
    DEM_DATA="${DEM}"
elif [[ "$EXT" == "nvi" && -f "${DEM%.*}.hdr" ]]; then
    FORMATDEM="ENVI"
    DEM_DATA="${DEM}"
elif [[ "$EXT" == "tif" || "$EXT" == "tiff" ]]; then
    FORMATDEM="TIF"
    DEM_DATA="${DEM}"
else
    echo "Unsupported DEM format."
    echo
    echo "Envi DEM must be named e.g. "
    echo "	your_name.bin and your_name.bin.hdr or  "
    echo "	your_name.nvi and your_name.nvi.hdr or  "
    echo "	your_name and your_name.hdr   "
    echo
    echo "Geotif DEM must be named e.g. "
    echo "	your_name.tif "

    exit
fi

# Clean base name (remove extension if present)
case "$FORMATDEM" in
    ENVI)
        DEMbaseName="${DEM_DATA%.bin}"	# i.e. DEM name without .bin (if any)
        ;;
    TIF)
        DEMbaseName="${DEM_DATA%.*}"	# i.e. DEM name without .tif
        ;;
esac

############################################################
# check version of AMSTer Engine. 
# From October 2024, agregateSRTMTiles is replaced by getSRTMDEM. 
# From Jan 2026, it is replaced by geoidal2EllipsoidalDEM
############################################################
if [[ -f ${PATH_SCRIPTS}/AMSTerEngine/geoidal2EllipsoidalDEM ]] ; then 
		CORRFCT=geoidal2EllipsoidalDEM
	elif [[ -f ${PATH_SCRIPTS}/AMSTerEngine/getSRTMDEM ]] ; then
		CORRFCT=getSRTMDEM
	else 
		CORRFCT=agregateSRTMTiles
fi 


############################################################
#  Projection check and reprojection (if needed)
############################################################

echo "Checking projection..."
INFO=$(gdalinfo "${DEM_DATA}")

if echo "$INFO" | grep -q "PROJCRS\|PROJCS"
	then
    	echo "	Projected coordinate (UTM) system detected."
    	echo "	Converting to WGS84 Lat/Long (EPSG:4326)..."
	
		# Detect source CRS
		############################################################
		
		#SRC_SRS=$(gdalsrsinfo -o epsg "${DEM_DATA}")		# e.g. EPSG:32735 with several empty lines 
		SRC_SRS=$(gdalsrsinfo -o epsg "${DEM_DATA}" | grep -o 'EPSG:[0-9]\+')
		
		if [ -z "${SRC_SRS}" ]
			then
		    	echo "Could not detect source CRS automatically."
		    	echo "Please specify EPSG code manually."
		    	exit
		fi
		
		echo "	Detected source CRS: ${SRC_SRS}"
		echo "	Target CRS: EPSG:4326 (WGS84 geographic)"
		echo ""
		# High-accuracy reprojection
		############################################################
		
		case "$FORMATDEM" in
		
		    ENVI)
		        NEW_DEM="${DEMbaseName}_LL.bin"
		
		        gdalwarp \
		            --config PROJ_NETWORK ON \
		            -s_srs "${SRC_SRS}" \
		            -t_srs EPSG:4326 \
		            -of ENVI \
		            -r cubicspline \
		            -et 0.0 \
		            -multi \
		            -wo NUM_THREADS=ALL_CPUS \
		            -overwrite \
		            "${DEM_DATA}" \
		            "${NEW_DEM}"
		        ;;
		
		    TIF)
		        NEW_DEM="${DEMbaseName}_LL.tif"
		
		        gdalwarp \
		            --config PROJ_NETWORK ON \
		            -s_srs "${SRC_SRS}" \
		            -t_srs EPSG:4326 \
		            -r cubicspline \
		            -et 0.0 \
		            -multi \
		            -wo NUM_THREADS=ALL_CPUS \
		            -overwrite \
		            "${DEM_DATA}" \
		            "${NEW_DEM}"
		        ;;
		esac
		
		DEM_DATA="${NEW_DEM}"
		DEMbaseName="${DEM_DATA%.*}"

fi

############################################################
# Now flip and convert
############################################################

# first flip the raster file (Works with envi and tif files and maybe other recognized formats)
#${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/flip_raster.py ${DEM_DATA} -o ${DEMbaseName}_flip.bil -of ENVI
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/flip_raster_rasterio.py ${DEM_DATA} 

# get it in float32, just in case... 
gdal_translate -of ENVI -ot Float32 ${DEMbaseName}_flip.bil ${DEMbaseName}_flip0.bil

rm -f "${DEMbaseName}_flip0.bil.aux.xml" "${DEMbaseName}_flip.bil" "${DEMbaseName}_flip.hdr" "${DEMbaseName}.bin.aux.xml"

# get nr of pixels from hdr
PIXELS=`gdalinfo "${DEM_DATA}" | $PATHGNU/ggrep "Size is" | $PATHGNU/gawk '{ print $3 }' | cut -d , -f1` 
# get nt of lines from hdr
LINES=`gdalinfo "${DEM_DATA}" | $PATHGNU/ggrep "Size is" | $PATHGNU/gawk '{ print $4 }'`

# get LL LONG sampling from hdr
#LLLONGSAMPL=`$PATHGNU/ggrep "map info" ${DEMbaseName}_flip0.hdr | cut -d, -f 6`
LLLONGSAMPL=`gdalinfo "${DEM_DATA}" | $PATHGNU/ggrep "Pixel Size =" | cut -d "(" -f2 | cut -d , -f1 | cut -d - -f 2 `	# ensure that sampling is positive... 
# get LL LAT sampling from hdr
#LLLATSAMPL=`$PATHGNU/ggrep "map info" ${DEMbaseName}_flip0.hdr | cut -d, -f 7`
LLLATSAMPL=`gdalinfo "${DEM_DATA}" | $PATHGNU/ggrep "Pixel Size =" | cut -d "(" -f2 | cut -d , -f2 | cut -d ")" -f1 | cut -d - -f 2`	# ensure that sampling is positive... 

# get REF LONG corner : Envi uses UL (NW) corner of UL pixel. TXT requires LL corner of LL pixel (SW), which we get from gdalinfo
# LLLONG=`$PATHGNU/ggrep "map info" ${DEMbaseName}_flip0.hdr | cut -d, -f 4`
LLLONG=`gdalinfo "${DEM_DATA}" | $PATHGNU/ggrep "Lower Left" | $PATHGNU/gawk '{ print $4 }' | cut -d , -f1`
#### However, AMSTerEngine consider the middle of the pixel as the reference instead of the corner of the pixel, hence we must remove half of pix resolution
####LLLONG=`echo "( ${LLLONG} - ( ${LLLONGSAMPL}/2 ) )" | bc -l`
# get REF LAT corner 
#LLLAT=`$PATHGNU/ggrep "map info" ${DEMbaseName}_flip0.hdr | cut -d, -f 5`
LLLAT=`gdalinfo "${DEM_DATA}" | $PATHGNU/ggrep "Lower Left" | $PATHGNU/gawk '{ print $5 }' | cut -d ")" -f1`
####LLLAT=`echo "( ${LLLAT} - ( ${LLLATSAMPL}/2) )" | bc -l`


echo "/* ${TYPE} DEM characteristics */" > ${DEMbaseName}_flip0.bil.txt
echo "/* ************************ */" >> ${DEMbaseName}_flip0.bil.txt
echo "${DEMbaseName}_flip0.bil		/* Georeferenced DEM file path */" >> ${DEMbaseName}_flip0.bil.txt
echo "${PIXELS}		/* X (longitude) dimension [pixels] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LINES}		/* Y (latitude) dimension [pixels] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LLLONG}		/* Lower left corner longitude [dd] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LLLAT}		/* Lower left corner latitude [dd] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LLLONGSAMPL}		/* Longitude sampling [dd] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LLLATSAMPL}		/* Latitude sampling [dd] */" >> ${DEMbaseName}_flip0.bil.txt
echo "NaN                                     		/* Excluding value */" >> ${DEMbaseName}_flip0.bil.txt

echo ""
echo "Is your DEM referred to "
echo "  - the Ellipsoid (E) and hence no additional correction is needed but .txt will be updated, or "
echo "  - the Geoid (G) and hence correction needs to be applied and .txt will be updated, or "
echo "  - you do not know (Q) and hence no correction will be applied and .txt will not be updated, which allows you to decide later ? "

while true; do
	read -p "Please specify by typing E, G or Q:  " EGQ
	case $EGQ in
		"E")
			echo ""
			echo "OK, you confirm that your DEM is already referred to ellipsoidal height, which is what AMSTerEngine expects. I set it in the .txt file..."

			echo "${HEIGHT}" >> ${DEMbaseName}_flip0.bil.txt		
			rm -f "${DEMbaseName}_flip0.hdr"
			break ;;
		"G")
			echo ""
			echo "OK, you confirm that your DEM is referred to Geoidal height while you will need it referred to Ellipsoid. "
			echo "I will run ${CORRFCT} to correct it from the geoidal height using ${EGM}. It will be renamed _CorrGeoid "
 			cp ${DEMbaseName}_flip0.bil.txt ${DEMbaseName}_flip0.bil.txt.NoCorr
 			cp ${DEMbaseName}_flip0.bil ${DEMbaseName}_flip0.bil.NoCorr

 			#echo "${CORRFCT} ${DEMbaseName}_flip0.bil"
 			#${CORRFCT} ${DEMbaseName}_flip0.bil

			case ${TYPE} in 
				SRTM)
					# Check that EGM96 exist and contains at least a file with .DAC or .pgm extension 
					DIR="${EARTH_GRAVITATIONAL_MODELS_DIR}/EGM96"
					#if [[ -d "$DIR" ]] && compgen -G "$DIR"/*.DAC > /dev/null || compgen -G "$DIR"/*.pgm > /dev/null; then
					if [[ -d "$DIR" ]] && ( compgen -G "$DIR"/*.DAC > /dev/null || compgen -G "$DIR"/*.pgm > /dev/null ); then

					    echo "EGM Directory exists and contains at least one .DAC or .pgm file. "
						echo "${CORRFCT} ${DEMbaseName}_flip0.bil"
						"${CORRFCT}" "${DEMbaseName}_flip0.bil"
					else
					    echo "No EGM Directory exists or it does not contain at least one .DAC or .pgm file. "
					    echo " I can't make the correction - exiting"
						exit 
					fi
					;;
				COPERNICUS)
					# Check that EGM2008 exist and contains at least a file with .pgm extension 
					DIR="${EARTH_GRAVITATIONAL_MODELS_DIR}/EGM2008"
					if [[ -d "$DIR" ]] && compgen -G "$DIR"/*.pgm > /dev/null; then
					    echo "EGM Directory exists and contains at least one .pgm file. "
						echo "${CORRFCT} ${DEMbaseName}_flip0.bil"
						"${CORRFCT}" "${DEMbaseName}_flip0.bil"
					else
					    echo "No EGM Directory exists or it does not contain at least one .pgm file. "
					    echo " I can't make the correction - exiting"
						exit 
					fi
					;;
				OTHER)
					# Check that an EGM exist and contains at least a file with .DAC or .pgm extension  
					DIR="${EARTH_GRAVITATIONAL_MODELS_DIR}/${EGM}"
					#if [[ -d "$DIR" ]] && compgen -G "$DIR"/*.DAC > /dev/null || compgen -G "$DIR"/*.pgm > /dev/null; then
					if [[ -d "$DIR" ]] && ( compgen -G "$DIR"/*.DAC > /dev/null || compgen -G "$DIR"/*.pgm > /dev/null ); then

					    echo "EGM Directory exists and contains at least one .DAC or .pgm file. "
						
						echo "${CORRFCT} ${DEMbaseName}_flip0.bil ${EGM}"
						"${CORRFCT}" "${DEMbaseName}_flip0.bil" "${EGM}"
					else
					    echo "No EGM Directory exists or it does not contain at least one .DAC or .pgm file. "
					    echo " I can't make the correction - exiting"
						exit 
					fi
					;;
			esac

 			mv -f "${DEMbaseName}_flip0.bil.txt" "${DEMbaseName}_flip0.bil_CorrGeoid.txt"
 			mv -f "${DEMbaseName}_flip0.bil" "${DEMbaseName}_flip0.bil_CorrGeoid"
 			mv -f "${DEMbaseName}_flip0.bil.txt.NoCorr" "${DEMbaseName}_flip0.bil.txt" 
 			mv -f "${DEMbaseName}_flip0.bil.NoCorr" "${DEMbaseName}_flip0.bil"
			rm -f "${DEMbaseName}_flip0.hdr"
			# need update path in ${DEMbaseName}_flip0.bil_CorrGeoid.txt
			${PATHGNU}/gsed -i "s%${DEMbaseName}_flip0.bil%${DEMbaseName}_flip0.bil_CorrGeoid%" ${DEMbaseName}_flip0.bil_CorrGeoid.txt
			break ;;
		"Q")
			echo ""
			echo "OK, you do not know if your DEM is referred to ellipsoidal or geoidal height. "
			echo "I add nothing about that in the .txt file, which means that AMSTerEngine will consider "
			echo "  that it is NOT corrected from geoidal height yet. In any case AMSTer Engine will work but you might have"
			echo "  small errors (mainly geocoding errors) if referrence is not appropirate. Contact your DEM provider to check."
			echo "If it turns out that your DEM is referred to Geoid, YOU MUST RUN ${CORRFCT} to correct it from the geoidal height."
			rm -f "${DEMbaseName}_flip0.hdr"
			break ;;			
		*)
			echo ""
			echo "I can't understand your answer. Please answer E, G or Q"
			break ;;
	esac
done

# To avoid confusion, rename .hdr as .bak_hdr
#mv -f ${DEM}_flip0.bil.hdr ${DEM}_flip0.bil.bak_hdr

echo "All done, hope it worked"
   		
