#!/bin/bash
######################################################################################
# This script aims at cropping a DEM to the size of another DEM based on its HDR file. 
# The created cropped DEM will be stored at the same place as the initial DEM. 
# It has the same name as the initial DEM, with an additional "_cropped.nvi" trailing string.  
# The cropped DEM is always in the CRS of the target DEM. 
#
# Parameters: 	- path to DEM to crop 
#				- path to target region in the form of Envi file (path to binary file)
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- gdal
#
#
# New in Distro V 1.0 20251223: - creation
# New in Distro V 1.1 20251224: - use gawk and for LC_NUMERIC-C to avoid problem with dot or coma etc
# New in Distro V 1.2 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


set -euo pipefail

DEMTOCROP="$1"      # ENVI DEM to crop
TARGET="$2"         # ENVI target region
OUT="${DEMTOCROP}_cropped.bin"

# -----------------------------
# 1. Extract TARGET bounding box
# -----------------------------
eval $(gdalinfo "${TARGET}" | ${PATHGNU}/gawk '
/Upper Left/  {gsub("[(),]",""); print "ULX="$3"; ULY="$4}
/Lower Right/ {gsub("[(),]",""); print "LRX="$3"; LRY="$4}
')

# -----------------------------
# 2. Extract TARGET pixel size
# -----------------------------
read PX PY <<< $(gdalinfo "${TARGET}" | \
  ${PATHGNU}/gawk -F'[(),]' '/Pixel Size/ {print $2, $3}')

export LC_NUMERIC=C
PX=$(printf "%.10f" "${PX}")
PY=$(printf "%.10f" "${PY}")


# -----------------------------
# 3. Extract TARGET CRS (EPSG or WKT)
# -----------------------------
TARGET_SRS=$(gdalinfo "${TARGET}" | \
  ${PATHGNU}/gawk '/AUTHORITY\["EPSG"/ {gsub(/.*EPSG","|".*/, "", $0); print "EPSG:"$0; exit}')

# Fallback to full WKT if EPSG not found
if [[ -z "${TARGET_SRS}" ]]; then
  TARGET_SRS=$(gdalinfo "${TARGET}" | \
    ${PATHGNU}/gawk '/Coordinate System is:/ {flag=1; next} flag {print} /^$/ {exit}')
fi

# -----------------------------
# 4. Crop + reproject DEM safely
# -----------------------------
gdalwarp \
  -of ENVI \
  -t_srs "${TARGET_SRS}" \
  -te ${ULX} ${LRY} ${LRX} ${ULY} \
  -tr ${PX} ${PY} \
  -tap \
  -r bilinear \
  -co INTERLEAVE=BSQ \
  "${DEMTOCROP}" "${OUT}"

echo "✔ Cropped DEM written to:"
echo "  ${OUT}"
