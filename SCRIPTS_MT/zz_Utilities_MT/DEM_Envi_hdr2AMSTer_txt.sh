#!/bin/bash
# This script transform
# - a Geotif DEM (for which the coordinates of the UL reference pixel are the coordinates of its center), or 
# - an Envi ESRI/ArcGis DEM and its .hdr file (for which the coordinates of the UL reference pixel are the coordinates of its center), or 
# - an Envi Harris DEM and its .hdr file (for which the coordinates of the UL reference pixel are the coordinates of its upper left corner)
# (in GIS order) into a flipped DEM with its corresponding .txt file (in math order).
# Input DEM is supposed to be in Lat Long.
#
# REMEMBER that AMSTerEngine takes in priority the txt header file if both txt and hdr are present. 
#
# If DEM is referred to Geoid, it computes directly the height correction 
#
# Note: The script can't check if the DEM is referred to the Geoid or the Ellispoid. 
#		You must tell him...
#
#
# Parameter: - path to Envi DEM 
#
# Dependencies: - $PATHGNU/ggrep
#				- dgalinfo
#				- python3.10 flip_raster.py script
#				- agregateSRTMTiles or getSRTMDEM for correcting geoidal height
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
# New in Distro V 5.0 20231030: - Cope with new fct getSRTMDEM instead of agregateSRTMTiles since AMSTerEngine V Oct 2024 
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 09, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# Parameters
DEM=$1 # path to dem (without .hdr)

if [ $# -lt 1 ] ; then echo " Usage $0 Path_to_DEM_LatLong_ENVI "; exit; fi

if [ ! -f ${DEM} ] ; then echo "DEM does not exist. Please check"; echo ; exit ; fi 

if [ -f ${DEM}.txt ] ; then echo "DEM.txt already exist. Please check"; echo ; exit ; fi 

EXT=${DEM##*.}
if [ "${EXT}" == "hdr" ] ; then echo "Provide the script with the DEM rather than the DEM.hdr" ; echo ; exit ; fi

if [ -f ${DEM}.hdr ] 
	then 
		# must be envi... 
		DEMbaseName=${DEM%.*}
	else
		# must be tif or ? 
		DEMbaseName=${DEM}
fi

# check version of AMSTer Engine. From October 2024, agregateSRTMTiles is replaced by getSRTMDEM
if [ -f ${PATH_SCRIPTS}/AMSTerEngine/getSRTMDEM ]
	then 
		CORRFCT=getSRTMDEM
	else 
		CORRFCT=agregateSRTMTiles
	
fi 
# first flip the raster file (Works with envi files but should also be OK for TIF and maybe other recognized formats)
${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/flip_raster.py ${DEM} -o ${DEMbaseName}_flip.bil -of ENVI

# get it in float32, just in case... 
gdal_translate -of ENVI -ot Float32 ${DEMbaseName}_flip.bil ${DEMbaseName}_flip0.bil

rm -f ${DEMbaseName}_flip0.bil.aux.xml ${DEMbaseName}_flip.bil ${DEMbaseName}_flip.hdr

# get nr of pixels from hdr
PIXELS=`gdalinfo ${DEMbaseName} | $PATHGNU/ggrep "Size is" | $PATHGNU/gawk '{ print $3 }' | cut -d , -f1` 
# get nt of lines from hdr
LINES=`gdalinfo ${DEMbaseName} | $PATHGNU/ggrep "Size is" | $PATHGNU/gawk '{ print $4 }'`

# get LL LONG sampling from hdr
#LLLONGSAMPL=`$PATHGNU/ggrep "map info" ${DEMbaseName}_flip0.hdr | cut -d, -f 6`
LLLONGSAMPL=`gdalinfo ${DEMbaseName} | $PATHGNU/ggrep "Pixel Size =" | cut -d "(" -f2 | cut -d , -f1 | cut -d - -f 2 `	# ensure that sampling is positive... 
# get LL LAT sampling from hdr
#LLLATSAMPL=`$PATHGNU/ggrep "map info" ${DEMbaseName}_flip0.hdr | cut -d, -f 7`
LLLATSAMPL=`gdalinfo ${DEMbaseName} | $PATHGNU/ggrep "Pixel Size =" | cut -d "(" -f2 | cut -d , -f2 | cut -d ")" -f1 | cut -d - -f 2`	# ensure that sampling is positive... 

# get REF LONG corner : Envi uses UL (NW) corner of UL pixel. TXT requires LL corner of LL pixel (SW), which we get from gdalinfo
# LLLONG=`$PATHGNU/ggrep "map info" ${DEMbaseName}_flip0.hdr | cut -d, -f 4`
LLLONG=`gdalinfo ${DEMbaseName} | $PATHGNU/ggrep "Lower Left" | $PATHGNU/gawk '{ print $4 }' | cut -d , -f1`
#### However, AMSTerEngine consider the middle of the pixel as the reference instead of the corner of the pixel, hence we must remove half of pix resolution
####LLLONG=`echo "( ${LLLONG} - ( ${LLLONGSAMPL}/2 ) )" | bc -l`
# get REF LAT corner 
#LLLAT=`$PATHGNU/ggrep "map info" ${DEMbaseName}_flip0.hdr | cut -d, -f 5`
LLLAT=`gdalinfo ${DEMbaseName} | $PATHGNU/ggrep "Lower Left" | $PATHGNU/gawk '{ print $5 }' | cut -d ")" -f1`
####LLLAT=`echo "( ${LLLAT} - ( ${LLLATSAMPL}/2) )" | bc -l`


echo "/* SRTM DEM characteristics */" > ${DEMbaseName}_flip0.bil.txt
echo "/* ************************ */" >> ${DEMbaseName}_flip0.bil.txt
echo "${DEMbaseName}_flip0.bil		/* Georeferenced DEM file path */" >> ${DEMbaseName}_flip0.bil.txt
echo "${PIXELS}		/* X (longitude) dimension [pixels] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LINES}		/* Y (latitude) dimension [pixels] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LLLONG}		/* Lower left corner longitude [dd] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LLLAT}		/* Lower left corner latitude [dd] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LLLONGSAMPL}		/* Longitude sampling [dd] */" >> ${DEMbaseName}_flip0.bil.txt
echo "${LLLATSAMPL}		/* Latitude sampling [dd] */" >> ${DEMbaseName}_flip0.bil.txt
echo "NaN                                     		/* Excluding value */" >> ${DEMbaseName}_flip0.bil.txt

while true; do
	read -p "Is your DEM referred to Ellipsoid (E), Geoid (G) or you do not know (Q) ? Please specify by typing E, G or Q:  " EGQ
	case $EGQ in
		"E")
			echo ""
			echo "OK, you confirm that your DEM is already referred to ellipsoidal height, which is what AMSTerEngin expects. I set it in the .txt file..."
			echo "Ellipsoidal - EGM96 geoidal height added		/* Height type */" >> ${DEMbaseName}_flip0.bil.txt		
			rm -f ${DEMbaseName}_flip0.hdr
			break ;;
		"G")
			echo ""
			echo "OK, you confirm that your DEM is referred to Geoidal height while you will need it referred to Ellipsoid. "
			echo "I will run ${CORRFCT} to correct it from the geoidal height. It will be renamed _CorrGeoid "
 			cp ${DEMbaseName}_flip0.bil.txt ${DEMbaseName}_flip0.bil.txt.NoCorr
 			cp ${DEMbaseName}_flip0.bil ${DEMbaseName}_flip0.bil.NoCorr
 			echo "${CORRFCT} ${DEMbaseName}_flip0.bil"
 			${CORRFCT} ${DEMbaseName}_flip0.bil
 			mv -f ${DEMbaseName}_flip0.bil.txt ${DEMbaseName}_flip0.bil_CorrGeoid.txt
 			mv -f ${DEMbaseName}_flip0.bil ${DEMbaseName}_flip0.bil_CorrGeoid
 			mv -f ${DEMbaseName}_flip0.bil.txt.NoCorr ${DEMbaseName}_flip0.bil.txt 
 			mv -f ${DEMbaseName}_flip0.bil.NoCorr ${DEMbaseName}_flip0.bil
			rm -f ${DEMbaseName}_flip0.hdr
			# need update path in ${DEMbaseName}_flip0.bil_CorrGeoid.txt
			${PATHGNU}/gsed -i "s%${DEMbaseName}_flip0.bil%${DEMbaseName}_flip0.bil_CorrGeoid%" ${DEMbaseName}_flip0.bil_CorrGeoid.txt
			break ;;
		"Q")
			echo ""
			echo "OK, you do not know if your DEM is referred to ellipsoidal or geoidal height. "
			echo "I add nothing about that in the .txt file, which means that AMSTerEngine will consider "
			echo "  that it is NOT corrected from geoidal height yet. In any case AMSTer Engine will work but you might have"
			echo "  small errors (manly geocoding errors) if referrence is not appropirate. Contact your DEM provider to check."
			echo "If it turns out that your DEM is referred to Geoid, YOU MUST RUN ${CORRFCT} to correct it from the geoidal height."
			rm -f ${DEMbaseName}_flip0.hdr
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
   		
