#!/bin/bash
######################################################################################
# This script transforms a ENVI files in color Cloud optimized Geotiffe 
#
# Parameters: 	- Envi file with path
#				- optional: % of clipping Min Max color range to make it more dynamic (default = 0.05, that is 5%)
#
# Dependencies: - gdal
#				- imagemagick or graphicsmagick
#				- python script CreateColorTable.py if use graphicsmagick
#
# Hard coded:	- Default clipping Min Max range to make it more dynamic 0.05, that is 5%
#
# New in Distro V 1.0:	-  based on Envi2ColorKmz.sh
# New in Distro V 1.1:	-  optional clipping of min max range color table 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Dec 1, 2025"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

INPUTFILE=$1
CLIP=$2			# clipping min max color table 

INFILE=$(basename $INPUTFILE)
INDIR=$(dirname $INPUTFILE)

if [ "${CLIP}" == "" ] 
	then 
		CLIP=0.05		# clipping Min Max range to make it more dynamic
fi
CLIPPC=$(echo "${CLIP} * 100" | bc -l | cut -d . -f 1)

if [ "${INDIR}" == "." ] 
	then 
		# No path provided
		if [ -f "$PWD/$INFILE" ]; then
			echo "File $INFILE exists in current directory."
			INDIR=$(pwd)
		else
			echo "File $INFILE not found in current directory and no path provided; exit."
			exit
		fi
	else 
		cd ${INDIR}
fi 

case "$(convert -version 2>&1)" in 
    *ImageMagick* )   
    	# just in case, check graphicsmagick again
		if command -v gm >/dev/null 2>&1; then
     		echo " // Use graphicsmagick"   
			TOOL="graphicsmagick" 
		else
    	echo " // Use imagemagick"
			TOOL="imagemagick"
		fi
		;;
    *GraphicsMagick* ) 
     	echo " // Use graphicsmagick"   
    	TOOL="graphicsmagick" ;;
    * ) echo 
    	"Unknown convert - quit here !!"
    	exit 1 ;;
esac

# --------------------------
# 1. Compute dynamic clipped min/max (robust contrast)
# --------------------------
#read MIN MAX < <(gdalinfo -stats "$INFILE" | \
#   grep STATISTICS_MINIMUM | sed 's/STATISTICS_MINIMUM=//' | tr '\n' ' ')
read MIN MAX < <(gdalinfo -stats "$INFILE" | ${PATHGNU}/gawk -F= '/STATISTICS_MINIMUM/{min=$2} /STATISTICS_MAXIMUM/{max=$2} END{print min, max}')


RANGE=$(echo "$MAX - $MIN" | bc -l)
CLIPMIN=$(echo "$MIN + ($RANGE * $CLIP)" | bc -l)
CLIPMAX=$(echo "$MAX - ($RANGE * $CLIP)" | bc -l)

# Ensure CLIPMAX > CLIPMIN and avoid collapse to zero
EPS=1e-12
if (( $(echo "$CLIPMAX <= $CLIPMIN" | bc -l) )); then
    CLIPMAX=$(echo "$CLIPMIN + $EPS" | bc -l)
fi


# --------------------------
# 2. Build dynamic diverging color table
# --------------------------
COLORTABLE=$(mktemp)
if [ "${TOOL}" == "imagemagick" ] 
	then 
		LC_NUMERIC=C		# needed to avoid wrong handling of float numbers depending on OS 
		printf "%f 255 0 0\n" "$CLIPMIN"   >> ${COLORTABLE}   # red
		printf "0 0 255 0\n"           >> ${COLORTABLE}   # green
		printf "%f 0 0 255\n" "$CLIPMAX"   >> ${COLORTABLE}   # blue
		printf "nv 0 0 0 0\n"             >> ${COLORTABLE}   # transparent NoData
	else 
		CreateColorTable.py "$COLORTABLE" "$CLIPMIN" "$CLIPMAX" 256
fi

# --------------------------
# 3. Make ZERO transparent
# --------------------------
gdal_translate "${INFILE}" step1.tif -a_nodata 0


# --------------------------
# 4. Generate colored COG with 0 Transparent
# --------------------------
# Create a temporary colorized GeoTIFF
TEMP_COLOR=$(mktemp /tmp/color_XXXXXX.tif)

gdaldem color-relief step1.tif ${COLORTABLE} ${TEMP_COLOR} -alpha

# Convert to fully optimized COG
gdal_translate ${TEMP_COLOR} ${INFILE}_ClipRg${CLIPPC}pc_cog.tif \
    -of COG \
    -co COMPRESS=DEFLATE \
    -co PREDICTOR=2 \
    -co BLOCKSIZE=512 \
    -co OVERVIEWS=AUTO \
    -co RESAMPLING=AVERAGE

# Clean up temporary files
rm -f step1.tif ${TEMP_COLOR} 