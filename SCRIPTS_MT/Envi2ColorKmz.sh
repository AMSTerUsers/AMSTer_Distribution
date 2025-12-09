#!/bin/bash
######################################################################################
# This script transforms a ENVI files in color kmz to be open in GoogleEarh for instance 
#
# Parameters: 	- Envi file with path
#				- optional param 2: -l to add legend
#				- optional param 3 (or 2 if there is no -l): % of clipping Min Max color range to make it more dynamic (default = 0.05, that is 5%)
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
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Dec 2, 2025"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

INPUTFILE=$1
ADDLEGEND=$2
CLIP=$3

if [ "${ADDLEGEND}" != "-l" ]
	then 
		CLIP="${ADDLEGEND}"
fi

if [ "${CLIP}" == "" ] 
	then 
		CLIP=0.05		# clipping Min Max range to make it more dynamic
fi
CLIPPC=$(echo "${CLIP} * 100" | bc -l | cut -d . -f 1)


INFILE=$(basename $INPUTFILE)
INDIR=$(dirname $INPUTFILE)

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
CLIPMIN=$(echo "$MIN + ($RANGE * ${CLIP})" | bc -l)
CLIPMAX=$(echo "$MAX - ($RANGE * ${CLIP})" | bc -l)

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
# 3. Apply color + alpha
# --------------------------
# set zero as no data
gdal_translate "$INFILE" step1.tif -a_nodata 0
gdaldem color-relief step1.tif ${COLORTABLE} color.tif -alpha

# --------------------------
# 4. Export KMZ WITH TRANSPARENCY (PNG!)
# --------------------------
gdal_translate -of KMLSUPEROVERLAY color.tif ${INFILE}Color_ClipRg${CLIPPC}pc.kmz -co FORMAT=PNG
   
# --------------------------
# 5. Cleanup
# --------------------------
rm -f step1.tif color.tif ${COLORTABLE}

# --------------------------
# 6. Optional: Add legend
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
    mkdir -p $WORKDIR
    unzip -q ${INFILE}Color_ClipRg${CLIPPC}pc.kmz -d $WORKDIR
    cp $LEGEND $WORKDIR/legend.png

    # Inject ScreenOverlay
    KML="$WORKDIR/doc.kml"
    sed -i '/<\/Document>/i \
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
    #zip -qr ../${INFILE}Color_ClipRg${CLIPPC}pc_withLegend.kmz *
    zip -r9 -q "../${INFILE}Color_ClipRg${CLIPPC}pc_withLegend.kmz" *
    cd ..
    	
    rm -rf $WORKDIR 
    rm -f legend.png
    
fi
