#!/bin/bash
######################################################################################
# This script transforms a ENVI or a GeoTIFF file in color kmz to be open in GoogleEarh for instance 
#
# Parameters: 	- Raster file with path. Can be:
#						- an ENVI binary file (with its .hdr beside it)
#						- an ENVI .hdr file (the associated binary will be used)
#						- a GeoTIFF file (.tif or .tiff)
#						- in fact any single band raster readable by gdal 
#				- optional parameter to add legend : -l 
#				- optional parameter(s) to clip the range:
#						- if only one value = % of clipping Min Max color range to make it more dynamic (default = 0.05, that is 5%)
#							Note that it can't be more than 0.5 because remaining range would be 0. 
#							If provided values is above 0.45, it is clipped to max 0.45
#						- if two values = % of clipping Min and clipping Max color range to make it more dynamic (default = 0.05, that is 5% for both)
#							Note that clip min + clip max can't be more than 0.9 to keep at least 10% of range. 
#							If clip min + clip max are too big, they are downscaled proportionally to keep 10% of the range
#						- if you do not want to clip, then enter 0 
#
# Dependencies: - gdal
#				- imagemagick or graphicsmagick
#				- python script CreateColorTable.py if use graphicsmagick
#
# Hard coded:	-
#
# New in Distro V 1.0:	- Based on Beta V1.0
#				V 1.0.1: - fix prblm of path to ColorTableKMZ.txt
#				V 1.0.2: - fix bug in naming hdr (dot was missing before binFlatColor.hdr)
# New in Distro V 1.1.0: - Color tables are now in TemplatesForPlots
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.0 20250903:	- create a dynamic color table
#								- option: if -l , it add a legend in the kmz 
# New in Distro V 4.1 20250904:	- imporve search of min and max with gdalinfo and now takes real min and max rather than those in metadata.
# New in Distro V 4.2 20250917:	- debug color scale and legend for use with graphicsmagick
# New in Distro V 4.3 20250930:	- debug WORKDIR which was given a file name instead of TMP
# New in Distro V 5.0 20251202:	- maked Zero transparent 
#								- add dynamic color clilpping
# New in Distro V 5.1 20260121:	- prevent clipping more than 0.4 (i.e 45% ) because at 50% MAX=Min 
#								- allows asymetric clipping
# New in Distro V 5.2 20260127:	- allows option -l wherever you want after INPUT file 
#								- do not check if min and max clip % must be swapped !
# New in Distro V 5.3 20260730:	- accept ENVI or GeoTIFF (or any other gdal readable raster) as input
#								- if an ENVI .hdr is provided, use the associated binary file instead
#								- if the input has more than one band, only the first one is used
#								- get rid of the raster extension (.tif, .tiff...) in the name of the output kmz
#								- min and max are now computed after having masked the NoData (zeros and, 
#									if any, the NoData value declared in the input file, e.g. -9999 in some tif)
#								- unique names for the temporary files to avoid overwriting an input 
#									file that would be named step1.tif or color.tif
#								- GDAL_PAM_ENABLED=NO to avoid creation of .aux.xml beside the input file
#								- use ${PATHGNU}/sed for in place edition because BSD sed -i requires a suffix
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 30, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

export GDAL_PAM_ENABLED=NO		# do not pollute the data dir with .aux.xml files
LC_NUMERIC=C					# needed to avoid wrong handling of float numbers depending on OS 

if [ $# -lt 1 ] ; then
	echo "Usage: $PRG  ENVI_or_TIF_FILE  [-l]  [CLIP_MIN_PC]  [CLIP_MAX_PC]"
	echo "   e.g. $PRG  deformationMap.interpolated.flattened  -l  0.02  0.1"
	echo "   e.g. $PRG  /my/path/velocity.tif  0"
	exit 1
fi

INPUTFILE=$1
shift

# Defaults
ADDLEGEND=""
CLIPMINPC=0.05
CLIPMAXPC=0.05

# Optional legend: -l (can be anywhere after filename)
	# Collect non-flag arguments
	ARGS=()
	
	for arg in "$@"; do
	    if [ "$arg" = "-l" ]; then
	        ADDLEGEND="-l"
	    else
	        ARGS+=("$arg")
	    fi
	done

# Clip values: remaining 0, 1 or 2 clip values
	# Now process clip values from ARGS
	if [ ${#ARGS[@]} -eq 1 ]; then
	    CLIPMINPC=${ARGS[0]}
	    CLIPMAXPC=${ARGS[0]}

	elif [ ${#ARGS[@]} -ge 2 ]; then
	    CLIPMINPC=${ARGS[0]}
	    CLIPMAXPC=${ARGS[1]}
	fi

# Clipping sanity checks
if (( $(echo "$CLIPMINPC == $CLIPMAXPC" | bc -l) ))
	then
		# Symmetric clipping: Do not allow clipping more than 50% (because range would be 0). 
    	if (( $(echo "$CLIPMINPC >= 0.45" | bc -l) )); then
    	    echo "Clipping more than 45% has no meaning since range would be too small; downscale CLIP to 45%"
    	    CLIPMINPC=0.45
    	    CLIPMAXPC=0.45
    	fi

	else
	    # Asymmetric clipping: Ensure at least 10% of the range remains
	    if (( $(echo "($CLIPMINPC + $CLIPMAXPC) > 0.9" | bc -l) )); then
	        echo "Asymmetric clipping too strong: must leave at least 10% of range."
	        echo "Downscaling proportionally to fit constraint."
	
	        SCALE=$(echo "0.9 / ($CLIPMINPC + $CLIPMAXPC)" | bc -l)
	        CLIPMINPC=$(echo "$CLIPMINPC * $SCALE" | bc -l)
	        CLIPMAXPC=$(echo "$CLIPMAXPC * $SCALE" | bc -l)
	    fi
fi


CLIPPCMIN=$(echo "$CLIPMINPC * 100" | bc -l | cut -d. -f1)
CLIPPCMAX=$(echo "$CLIPMAXPC * 100" | bc -l | cut -d. -f1)

echo "Clipping the lower part of the color range by ${CLIPPCMIN}% and its upper part by ${CLIPPCMAX}%."

# Input file handling
INFILE=$(basename "$INPUTFILE")
INDIR=$(dirname "$INPUTFILE")

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

# Detect ImageMagick / GraphicsMagick
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
# 1. Identify the input: ENVI, GeoTIFF or anything else gdal can read
# --------------------------
# If an ENVI header file was provided, search for the associated binary file
case "${INFILE}" in
    *.hdr|*.HDR )
		INHDR="${INFILE}"
		INFILE="${INFILE%.*}"			# e.g. myFile.bil.hdr --> myFile.bil  ;  myFile.hdr --> myFile
		if [ ! -f "${INFILE}" ] 
			then 
				# maybe the binary got an extension while the hdr had none, e.g. myFile.hdr + myFile.img
				for EXTENSION in img bil bsq bip dat bin raw r4 ; do
					if [ -f "${INFILE}.${EXTENSION}" ] ; then INFILE="${INFILE}.${EXTENSION}" ; break ; fi
				done
		fi
		if [ ! -f "${INFILE}" ] 
			then 
				echo "${INHDR} provided but no associated binary file found; exit."
				exit 1
		fi
		echo " // ENVI header provided; will use the binary file ${INFILE}"
		;;
esac

if [ ! -f "${INFILE}" ] ; then echo "${INFILE} does not exist; exit." ; exit 1 ; fi

# Ask gdal what it is  (line looks like: Driver: ENVI/ENVI .hdr Labelled  or  Driver: GTiff/GeoTIFF)
DRIVER=$(gdalinfo "${INFILE}" 2>/dev/null | ${PATHGNU}/sed -n 's|^Driver: \([^/]*\)/.*|\1|p')

case "${DRIVER}" in
	"" )	echo "${INFILE} is not readable by gdal (neither ENVI nor tif ?); exit."
			exit 1 ;;
	ENVI )	echo " // Input recognised as an ENVI file" ;;
	GTiff )	echo " // Input recognised as a GeoTIFF file" ;;
	* )		echo " // Input recognised as a ${DRIVER} file; will try anyway" ;;
esac

# Nr of bands and possible NoData value declared in the input 
NRBANDS=$(gdalinfo "${INFILE}" 2>/dev/null | grep -c "^Band ")
NODATAIN=$(gdalinfo "${INFILE}" 2>/dev/null | ${PATHGNU}/sed -n 's|^ *NoData Value=||p' | head -1)

# --------------------------
# 2. Output name: get rid of the raster extension, if any
# --------------------------
case "${INFILE}" in
    *.tif|*.tiff|*.TIF|*.TIFF|*.gtif|*.GTIF )	OUTROOT="${INFILE%.*}" ;;
    * )											OUTROOT="${INFILE}" ;;		# ENVI binaries have no extension or a meaningful one (.bil, .interpolated...)
esac

if [ "$CLIPPCMIN" = "$CLIPPCMAX" ]; then
    OUTBASE="${OUTROOT}Color_ClipRg${CLIPPCMIN}pc"
else
    OUTBASE="${OUTROOT}Color_ClipRgMin${CLIPPCMIN}pcMax${CLIPPCMAX}pc"
fi

# --------------------------
# 3. Convert the input (whatever the format) in a single band tif with the NoData masked, i.e. transparent
# --------------------------
# unique tmp names to avoid clobbering an input that would be named step1.tif or color.tif
STEP0="_tmpBand1_$$.tif"
STEP1="_tmpStep1_$$.tif"
COLORTIF="_tmpColor_$$.tif"

if [ "${NRBANDS}" -gt 1 ] 
	then 
		echo " // ${NRBANDS} bands in ${INFILE}; only the first one is used"
		gdal_translate -q -b 1 "${INFILE}" "${STEP0}" 2>/dev/null
	else 
		STEP0="${INFILE}"
fi

# set zero as no data ; if the input declares its own NoData (e.g. -9999 or nan in some tif), merge it with the zeros 
if [ -z "${NODATAIN}" ] || [ "${NODATAIN}" == "0" ] 
	then 
		gdal_translate -q "${STEP0}" "${STEP1}" -a_nodata 0 2>/dev/null
	else 
		echo " // Input declares NoData = ${NODATAIN}; it will be masked together with the zeros"
		gdalwarp -q -srcnodata "${NODATAIN} 0" -dstnodata 0 "${STEP0}" "${STEP1}" 2>/dev/null
fi

if [ ! -f "${STEP1}" ] ; then echo "Fail converting ${INFILE} with gdal; exit." ; rm -f "${STEP0}" ; exit 1 ; fi

# --------------------------
# 4. Compute dynamic clipped min/max (robust contrast) - NoData excluded
# --------------------------
read MIN MAX < <(gdalinfo -stats "${STEP1}" 2>/dev/null | ${PATHGNU}/gawk -F= '/STATISTICS_MINIMUM/{min=$2} /STATISTICS_MAXIMUM/{max=$2} END{print min, max}')

if [ -z "${MIN}" ] || [ -z "${MAX}" ] ; then echo "Can't get statistics from ${INFILE}; exit." ; rm -f "${STEP1}" ; exit 1 ; fi

RANGE=$(echo "$MAX - $MIN" | bc -l)
echo ""
echo " // Unclipped range (max - min): $MAX - $MIN"

CLIPMIN=$(echo "$MIN + ($RANGE * $CLIPMINPC)" | bc -l)
CLIPMAX=$(echo "$MAX - ($RANGE * $CLIPMAXPC)" | bc -l)

# Ensure numeric order - how could it happend ? 
if (( $(echo "$CLIPMIN > $CLIPMAX" | bc -l) )); then
    echo "Warning: CLIPMIN > CLIPMAX after clipping, swapping values."
    TMP=$CLIPMIN
    CLIPMIN=$CLIPMAX
    CLIPMAX=$TMP
fi

if (( $(echo "$CLIPMINPC == 0 && $CLIPMAXPC == 0" | bc -l) ))
	then 
		echo " // No clipped range applied"
	else 
		echo " // Clipped range (max - min): $CLIPMAX - $CLIPMIN"
fi
echo ""

# Ensure CLIPMAX > CLIPMIN and avoid collapse to zero
EPS=1e-12
if (( $(echo "$CLIPMAX <= $CLIPMIN" | bc -l) )); then
    CLIPMAX=$(echo "$CLIPMIN + $EPS" | bc -l)
fi

# --------------------------
# 5. Build dynamic diverging color table
# --------------------------
COLORTABLE=$(mktemp)
if [ "${TOOL}" == "imagemagick" ] 
	then 
		printf "%f 255 0 0\n" "$CLIPMIN"   >> ${COLORTABLE}   # red
		printf "0 0 255 0\n"           >> ${COLORTABLE}   # green
		printf "%f 0 0 255\n" "$CLIPMAX"   >> ${COLORTABLE}   # blue
		printf "nv 0 0 0 0\n"             >> ${COLORTABLE}   # transparent NoData
	else 
		CreateColorTable.py "$COLORTABLE" "$CLIPMIN" "$CLIPMAX" 256
fi

# --------------------------
# 6. Apply color + alpha
# --------------------------
#echo "Debug: CLIPMIN=$CLIPMIN, CLIPMAX=$CLIPMAX"
gdaldem color-relief "${STEP1}" ${COLORTABLE} "${COLORTIF}" -alpha

# --------------------------
# 7. Export KMZ WITH TRANSPARENCY (PNG!)
# --------------------------
gdal_translate "${COLORTIF}" "${OUTBASE}.kmz" -of KMLSUPEROVERLAY -co FORMAT=PNG   

# --------------------------
# 8. Cleanup
# --------------------------
if [ "${STEP0}" != "${INFILE}" ] ; then rm -f "${STEP0}" ; fi
rm -f "${STEP1}" "${STEP1}.aux.xml" "${COLORTIF}" ${COLORTABLE}

# --------------------------
# 9. Optional: Add legend
# --------------------------
if [ "$ADDLEGEND" == "-l" ]; then
    LEGEND=legend.png
    WIDTH=60
    HEIGHT=400

    echo "[+] Creating legend..."

	if [ "${TOOL}" == "imagemagick" ] 
		then 
			convert -size ${WIDTH}x${HEIGHT} gradient: -rotate 90 \
				\( -size 3x1 xc:red xc:green xc:blue +append -filter Cubic -resize ${WIDTH}x1! \) \
				-clut "$LEGEND"
			
			convert "$LEGEND" \
				-pointsize 20 -fill black \
				-gravity west -annotate +0+0 "$CLIPMIN" \
				-gravity center -annotate +0+0 "0" \
				-gravity east -annotate +0+0 "$CLIPMAX" \
				"$LEGEND"
		else 
			CreateColorTable.py --legend "$LEGEND" "$CLIPMIN" "$CLIPMAX" "$WIDTH" "$HEIGHT"
	fi		
      
    echo "[+] Injecting legend into KMZ..."
    WORKDIR="TMP"
    mkdir -p "$WORKDIR"
    unzip -q "${OUTBASE}.kmz" -d "$WORKDIR"
    cp "$LEGEND" "$WORKDIR"

    # Inject ScreenOverlay
    KML="$WORKDIR/doc.kml"
    ${PATHGNU}/sed -i '/<\/Document>/i \
<ScreenOverlay>\n\
  <name>Legend</name>\n\
  <Icon>\n\
    <href>legend.png</href>\n\
  </Icon>\n\
  <overlayXY x="0" y="0" xunits="fraction" yunits="fraction"/>\n\
  <screenXY x="0.05" y="0.05" xunits="fraction" yunits="fraction"/>\n\
  <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>\n\
  <size x="0" y="0" xunits="pixels" yunits="pixels"/>\n\
</ScreenOverlay>' "$KML"

    echo "[+] Repackaging KMZ..."
	# Zip preserving folder structure
    cd $WORKDIR
    zip -r9 -q "../${OUTBASE}_withLegend.kmz" *
    cd ..
    	
    rm -rf $WORKDIR 
    rm -f legend.png
    
fi
