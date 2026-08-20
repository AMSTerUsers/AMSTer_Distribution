#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at multiply all GeoTIFFs in a dir by -1  (macOS + Linux)
# Inverted files are saved in ./inverted directory.
#
# Must be launched in dir containing all tif files. 
# 
# The outputs are written with the same constraints as Envi2msbastif.sh, i.e.
# Float32, COMPRESS=NONE, TILED=NO, nodata = 0 and no NaN/Inf left, because msbas
# CreateCopy's the first interferogram of the first set as the template for EVERY
# output and then rewrites its outputs by line ranges: a DEFLATE/tiled template
# breaks those writes.
#
# Usage:  ./All_tif_x_-1.sh [indir] [outdir]
#
# bash (>= 3.2, i.e. the macOS system bash); works on macOS and Linux.
#
# Parameters are :
#       - Path to dir containing the tif to invert  (optional, default ".")
#       - Path to dir where to store the inverted tif  (optional, default <indir>/inverted)
##
# Dependencies:	- GDAL python utils gdal_calc.py (in AMSTer venv)
#				- gdalinfo
#				- find, sort
#
# New in Distro V 1.0 20260730:	- set up
# New in Distro V 1.1 20260818:	- bin/sh -> bin/bash
# New in Distro V 1.2 20260818:
#						- outputs are now COMPRESS=NONE / TILED=NO instead of
#						  DEFLATE / tiled, which silently broke msbas when one of
#						  these files happened to be the msbas template
#						- nodata is forced to 0 and NaN/Inf are zeroed, as in
#						  Envi2msbastif.sh; the previous version could propagate
#						  "nan" as nodata value, which msbas cannot detect since
#						  it compares nodata by equality
#						- set -eu and ERR trap: a failing gdal_calc is no longer
#						  reported as a success
#						- same gdal_calc detection as Envi2msbastif.sh, including
#						  the check that osgeo_utils is importable, and the
#						  command is kept in an array
#						- gdalinfo is called once per file and its failure only
#						  skips that file
#						- the file list is built with find -iname, so .tif,
#						  .tiff, .TIF and .TIFF are all covered exactly once
#						- refuses to write into the input dir
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=$(basename "$0")
VER="Distro V1.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 18, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) "
echo " "

set -eu
trap 'echo "ERROR: ${PRG} aborted at line ${LINENO}" >&2' ERR

IN_DIR="${1:-.}"
OUT_DIR="${2:-$IN_DIR/inverted}"

[ -d "$IN_DIR" ] || { echo "ERROR: no such directory: $IN_DIR" >&2; exit 1; }
mkdir -p "$OUT_DIR"

# inputs and outputs share the same names, so the two dirs must differ
if [ "$(cd "$IN_DIR" && pwd -P)" = "$(cd "$OUT_DIR" && pwd -P)" ]; then
    echo "ERROR: output dir is the input dir; refusing to overwrite in place" >&2
    exit 1
fi

# ---- locate gdal_calc.py -----------------------------------------------------
# Same detection as in Envi2msbastif.sh: AMSTer venv first (called as a module so
# that neither PATH nor the shebang length limit matters), then PATH, then the
# module through python3. Kept as an array: it is several words.
AMSTER_PY="/opt/local/amster_python_env/bin/python"

if [ -x "$AMSTER_PY" ] && "$AMSTER_PY" -c "import osgeo_utils" >/dev/null 2>&1; then
    GDAL_CALC=("$AMSTER_PY" -m osgeo_utils.gdal_calc)
elif command -v gdal_calc.py >/dev/null 2>&1; then
    GDAL_CALC=(gdal_calc.py)
elif python3 -c "import osgeo_utils" >/dev/null 2>&1; then
    GDAL_CALC=(python3 -m osgeo_utils.gdal_calc)
else
    echo "ERROR: gdal_calc.py not found (no AMSTer venv, not on PATH," >&2
    echo "       and osgeo_utils not importable by python3)." >&2
    exit 1
fi
echo "Using gdal_calc: ${GDAL_CALC[*]}"

command -v gdalinfo >/dev/null 2>&1 || {
    echo "ERROR: gdalinfo not found on PATH" >&2; exit 1; }

export GDAL_PAM_ENABLED=NO

NTIF=0
NCONV=0
NSKIP=0

while IFS= read -r F; do

    NTIF=$((NTIF + 1))
    B=$(basename "$F")
    OUT="$OUT_DIR/$B"

    # read the metadata once; a file gdalinfo cannot open is skipped, not fatal
    if ! INFO=$(gdalinfo "$F" 2>&1); then
        echo "WARNING: gdalinfo cannot read $B, skipping" >&2
        echo "         $(printf '%s' "$INFO" | head -1)" >&2
        NSKIP=$((NSKIP + 1))
        continue
    fi

    case $INFO in
        *Type=Float32*) ;;
        *) echo "WARNING: $B is not Float32, it will be cast" >&2 ;;
    esac

    # The input nodata declared in the file is honoured by gdal_calc.py and mapped
    # to the output nodata (0). numpy.isfinite() catches the undeclared NaN/Inf.
    "${GDAL_CALC[@]}" \
        -A "$F" --allBands=A \
        --outfile="$OUT" \
        --calc="numpy.where(numpy.isfinite(A),-1*A,0)" \
        --format=GTiff \
        --type=Float32 \
        --NoDataValue=0 \
        --co="COMPRESS=NONE" \
        --co="TILED=NO" \
        --overwrite \
        --quiet

    NCONV=$((NCONV + 1))
    echo "$B -> $OUT"

done < <(find "$IN_DIR" -maxdepth 1 -type f \
              \( -iname '*.tif' -o -iname '*.tiff' \) | LC_ALL=C sort)

echo ""
if [ "$NTIF" -eq 0 ]; then
    echo "ERROR: no GeoTIFF found in $IN_DIR" >&2
    exit 1
fi
echo "$NCONV file(s) inverted, $NSKIP skipped, written in $OUT_DIR"
echo ""