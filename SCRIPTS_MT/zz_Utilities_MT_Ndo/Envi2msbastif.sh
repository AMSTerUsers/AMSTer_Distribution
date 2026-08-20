#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at converting ENVI float32 (+ .hdr) rasters into GeoTIFFs
# ingestible by MSBAS v10 (FORMAT=2).
#
# Usage:  ./Envi2msbastif.sh <indir> <outdir>
#
# Requirements enforced here, all imposed by the msbas v10 source:
#   * single band, Float32          -> first input file is CreateCopy'd as the
#                                      template for every output (Param.cpp:52)
#   * COMPRESS=NONE, TILED=NO       -> outputs are reopened GA_Update and written
#                                      by line ranges (Buffer.cpp:64,80); random
#                                      writes into compressed TIFF fail
#   * NaN / Inf replaced by 0       -> msbas encodes nodata as 0 (NAN_VAL) and has
#                                      no isnan() test in its GeoTIFF path
#   * nodata declared as 0, NEVER   -> Param.cpp:449 remaps nodata by equality;
#     as "nan"                        NaN == NaN is false, so NaN nodata survives
#
#
# POSIX sh; works on macOS and Linux. 
#
# Parameters are : 
#       - Path to dir containing the original Envi data
#		- Path to dir where to store the tif data
#
# Dependencies:	- GDAL python utils gdal_calc.py (in AMSTer venv)
#				- gdalinfo
#				- find, sort
#
# New in Distro V 1.1 20260730:
#						- gdal_calc.py is searched in the AMSTer venv first
#						  (/opt/local/amster_python_env), then on PATH, then as
#						  the osgeo_utils.gdal_calc module; called as a module to
#						  avoid PATH and shebang-length problems
#						- warn if the python bindings and gdalinfo report
#						  different GDAL versions
# New in Distro V 1.2 20260818:	- bin/sh -> bin/bash
# New in Distro V 1.3 20260818:
#						- ERR trap, so that an unexpected failure says where it
#						  happened instead of exiting silently
#						- gdalinfo is called ONCE per file and its failure is
#						  reported instead of killing the script. The former
#						  NB=`gdalinfo ... | grep -c '^Band '` aborted the whole
#						  run silently under set -e, because grep -c exits 1 when
#						  the count is 0 - i.e. exactly when gdalinfo could not
#						  read the file
#						- expr replaced by POSIX arithmetic $((...)): expr too
#						  exits 1 when the result is 0
#						- the gdal_calc command is held in an array, so it no
#						  longer relies on word splitting of an unquoted variable
#						- the file list is built with find + sort, so the
#						  template file (first one converted) is deterministic
#						  and names with spaces are safe
#						- the FORMAT/FILE_SIZE footer is printed only when at
#						  least one file was converted
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=$(basename "$0")
VER="Distro V1.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 18, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) "
echo " "

set -eu
trap 'echo "ERROR: ${PRG} aborted at line ${LINENO}" >&2' ERR

if [ $# -ne 2 ]; then
    echo "usage: $0 <input_dir_with_ENVI_files> <output_dir>" >&2
    exit 1
fi

INDIR=$1
OUTDIR=$2

[ -d "$INDIR" ] || { echo "ERROR: no such directory: $INDIR" >&2; exit 1; }
mkdir -p "$OUTDIR"

# ---- locate gdal_calc.py -----------------------------------------------------
# Preference order:
#   1. AMSTer venv (MacPorts install here), called as a module so that neither
#      PATH nor the shebang length limit matters
#   2. gdal_calc.py on PATH (usual Linux packaging: python3-gdal / gdal-python-tools)
#   3. python3 -m osgeo_utils.gdal_calc as last resort
# The command is kept as an array: it is several words, and an array carries them
# without depending on IFS splitting of an unquoted variable.
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

# ---- warn if the python bindings do not match the libgdal behind gdalinfo ----
# A mismatch here shows up much later as import or symbol errors.
GDALVER_CLI=$(gdalinfo --version | sed -n 's/^GDAL \([0-9.]*\).*/\1/p')
GDALVER_PY=$("${GDAL_CALC[@]}" --version 2>/dev/null \
             | sed -n 's/^.*[^0-9]\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' \
             | head -1)
if [ -n "$GDALVER_PY" ] && [ -n "$GDALVER_CLI" ] && [ "$GDALVER_PY" != "$GDALVER_CLI" ]; then
    echo "WARNING: gdalinfo is GDAL $GDALVER_CLI but the python bindings report $GDALVER_PY" >&2
fi

# keep GDAL from littering *.aux.xml next to the ENVI files
GDAL_PAM_ENABLED=NO
export GDAL_PAM_ENABLED

SIZEREF=""
SIZEREF_FROM=""
NHDR=0
NCONV=0
NSKIP=0

# Sorted list, so that the file which ends up being the msbas template (the first
# one converted) does not depend on the directory order of the file system.
while IFS= read -r HDR; do

    NHDR=$((NHDR + 1))

    # ENVI data file: strip the .hdr suffix. Covers both AMSTer conventions,
    # i.e. "deformationMap" + "deformationMap.hdr" and "x.r4" + "x.r4.hdr".
    DAT=${HDR%.hdr}

    if [ ! -f "$DAT" ]; then
        echo "WARNING: header without data file, skipping: $HDR" >&2
        NSKIP=$((NSKIP + 1))
        continue
    fi

    BASE=$(basename "$DAT")
    OUT="$OUTDIR/$BASE.tif"

    # ---- sanity: read the raster metadata once -------------------------------
    # A file that gdalinfo cannot open is skipped with a message; it must not
    # bring the whole run down, and it must not go unnoticed either.
    if ! INFO=$(gdalinfo "$DAT" 2>&1); then
        echo "WARNING: gdalinfo cannot read $BASE, skipping" >&2
        echo "         $(printf '%s' "$INFO" | head -1)" >&2
        NSKIP=$((NSKIP + 1))
        continue
    fi

    NB=$(printf '%s\n' "$INFO" | grep -c '^Band ' || true)
    if [ "$NB" -ne 1 ]; then
        echo "WARNING: $BASE has $NB bands, msbas reads band 1 only" >&2
    fi

    case $INFO in
        *Type=Float32*) ;;
        *) echo "WARNING: $BASE is not Float32, it will be cast" >&2 ;;
    esac

    # ---- convert -------------------------------------------------------------
    # numpy.isfinite() keeps finite values and zeroes NaN and +/-Inf in one pass.
    # gdal_calc.py honours the input nodata by default and maps it to the output
    # nodata, so any "data ignore value" from the .hdr also lands on 0.
    "${GDAL_CALC[@]}" \
        -A "$DAT" \
        --outfile="$OUT" \
        --calc="numpy.where(numpy.isfinite(A),A,0)" \
        --format=GTiff \
        --type=Float32 \
        --NoDataValue=0 \
        --co="COMPRESS=NONE" \
        --co="TILED=NO" \
        --overwrite \
        --quiet

    # ---- verify all rasters share one geometry (msbas FILE_SIZE is global) ----
    SIZE=$(gdalinfo "$OUT" | sed -n 's/^Size is \([0-9]*\), \([0-9]*\)$/\1,\2/p')
    if [ -z "$SIZEREF" ]; then
        SIZEREF=$SIZE
        SIZEREF_FROM=$BASE
    elif [ "$SIZE" != "$SIZEREF" ]; then
        echo "ERROR: $BASE is ${SIZE} but $SIZEREF_FROM is ${SIZEREF}." >&2
        echo "       msbas needs one common grid; crop/resample first." >&2
        exit 1
    fi

    NCONV=$((NCONV + 1))
    echo "converted  $BASE  ->  $OUT"

done < <(find "$INDIR" -maxdepth 1 -type f -name '*.hdr' | LC_ALL=C sort)

if [ "$NHDR" -eq 0 ]; then
    echo "ERROR: no *.hdr found in $INDIR" >&2
    exit 1
fi

echo ""
echo "$NCONV file(s) converted, $NSKIP skipped."
echo ""

if [ "$NCONV" -eq 0 ]; then
    echo "Nothing was converted, no msbas parameter to report."
    echo ""
    exit 1
fi

echo "Put these lines in msbas_par.txt:"
echo "  FORMAT=2"
echo "  FILE_SIZE=$SIZEREF"
echo ""
echo "Reminder: list the inputs in the set files WITH the .tif extension,"
echo "and make sure the first interferogram of the first set is one of these"
echo "files - it becomes the template for every msbas output."