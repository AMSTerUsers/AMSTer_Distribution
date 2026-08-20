#!/bin/bash
######################################################################################
# This script aims at converting ROI_PAC/ISCE-style .rsc files to ENVI Harris .hdr files
# The script is made with AI assistant. 
#
# Parameters : 	- rsc to reprocess (can be more than one). If none is provided, it does all in dir.  
#
# Usage:
#   ./rsc2hdr.sh [file1.rsc file2.rsc ...]   # process listed files
#   ./rsc2hdr.sh                              # process all *.rsc in current dir
#
# Output: one <basename>.hdr per .rsc, written alongside the source file.
#
#
# New in Distro V 1.1 :	- 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/10 -						 
######################################################################################
set -euo pipefail

# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #

usage() {
    echo "Usage: $0 [file1.rsc ...]"
    echo "  Converts ROI_PAC/ISCE .rsc sidecar files to ENVI Harris .hdr files."
    echo "  With no arguments, processes all *.rsc in the current directory."
    exit 1
}

rsc_value() {
    # Extract the value for a given keyword from the .rsc file (case-insensitive key).
    # Usage: rsc_value <file> <KEYWORD>
    local file="$1" key="$2"
    grep -i "^[[:space:]]*${key}[[:space:]]" "$file" \
        | head -1 \
        | awk '{print $2}'
}

# --------------------------------------------------------------------------- #
# ENVI data-type mapping
# The .rsc format doesn't carry a data type, so we default to float32 (type=4)
# and allow the user to override via RSC_ENVI_DATA_TYPE env var.
# Common ENVI types:
#   1=uint8  2=int16  3=int32  4=float32  5=float64
#   6=complex float32  9=complex float64  12=uint16
# --------------------------------------------------------------------------- #
ENVI_DATA_TYPE="${RSC_ENVI_DATA_TYPE:-4}"

# --------------------------------------------------------------------------- #
# ENVI interleave — default BIL (band-interleaved-by-line).
# Override via RSC_ENVI_INTERLEAVE=bsq|bil|bip
# --------------------------------------------------------------------------- #
ENVI_INTERLEAVE="${RSC_ENVI_INTERLEAVE:-bil}"

# --------------------------------------------------------------------------- #
# Number of bands — default 1.  Override via RSC_ENVI_BANDS.
# --------------------------------------------------------------------------- #
ENVI_BANDS="${RSC_ENVI_BANDS:-1}"

# --------------------------------------------------------------------------- #
# Byte order: 0=little-endian (default), 1=big-endian
# Override via RSC_ENVI_BYTE_ORDER
# --------------------------------------------------------------------------- #
ENVI_BYTE_ORDER="${RSC_ENVI_BYTE_ORDER:-0}"

# --------------------------------------------------------------------------- #
# collect input files
# --------------------------------------------------------------------------- #

if [ "$#" -gt 0 ]; then
    files=("$@")
else
    # Collect *.rsc in current directory (POSIX-safe, no bash 4 mapfile)
    set +f
    files=()
    for f in *.rsc; do
        [ -e "$f" ] && files+=("$f")
    done
    set -f
    if [ "${#files[@]}" -eq 0 ]; then
        echo "No .rsc files found in current directory." >&2
        usage
    fi
fi

# --------------------------------------------------------------------------- #
# process each file
# --------------------------------------------------------------------------- #

for rsc in "${files[@]}"; do

    if [ ! -f "$rsc" ]; then
        echo "WARNING: '$rsc' not found, skipping." >&2
        continue
    fi

    # Derive output path: same directory, .hdr extension
    dir=$(dirname "$rsc")
    base=$(basename "$rsc" .rsc)
    hdr="${dir}/${base}.hdr"

    echo "Processing: $rsc  →  $hdr"

    # ------------------------------------------------------------------- #
    # Read mandatory fields
    # ------------------------------------------------------------------- #
    WIDTH=$(rsc_value "$rsc" "WIDTH")
    FILE_LENGTH=$(rsc_value "$rsc" "FILE_LENGTH")
    X_FIRST=$(rsc_value "$rsc" "X_FIRST")
    Y_FIRST=$(rsc_value "$rsc" "Y_FIRST")
    X_STEP=$(rsc_value "$rsc" "X_STEP")
    Y_STEP=$(rsc_value "$rsc" "Y_STEP")
    PROJECTION=$(rsc_value "$rsc" "PROJECTION")
    DATUM=$(rsc_value "$rsc" "DATUM")
    X_UNIT=$(rsc_value "$rsc" "X_UNIT")

    # Optional / defaulted fields
    Z_OFFSET=$(rsc_value "$rsc" "Z_OFFSET");  Z_OFFSET="${Z_OFFSET:-0}"
    Z_SCALE=$(rsc_value "$rsc" "Z_SCALE");    Z_SCALE="${Z_SCALE:-1}"

    # ------------------------------------------------------------------- #
    # Validate mandatory fields
    # ------------------------------------------------------------------- #
    for var in WIDTH FILE_LENGTH X_FIRST Y_FIRST X_STEP Y_STEP; do
        eval val="\$$var"
        if [ -z "$val" ]; then
            echo "ERROR: '$rsc' is missing mandatory field $var, skipping." >&2
            continue 2   # skip to next rsc file
        fi
    done

    # ------------------------------------------------------------------- #
    # Derive ENVI coordinate system string
    # ENVI expects: map info = {proj, x_pixel_origin, y_pixel_origin,
    #                           easting, northing, x_pixel_size, y_pixel_size,
    #                           datum, units}
    # For LATLON: upper-left centre of pixel 1,1 is (X_FIRST, Y_FIRST)
    # Note: Y_STEP is typically negative (northing decreasing southward)
    # ------------------------------------------------------------------- #

    # Absolute pixel size (ENVI always wants positive values in map info)
    abs_x_step=$(echo "$X_STEP" | awk '{printf "%.15g", ($1<0?-$1:$1)}')
    abs_y_step=$(echo "$Y_STEP" | awk '{printf "%.15g", ($1<0?-$1:$1)}')

    # Resolve ENVI projection label and map_info units
    case "$(echo "$PROJECTION" | tr '[:lower:]' '[:upper:]')" in
        LATLON|GEOGRAPHIC)
            envi_proj="Geographic Lat/Lon"
            envi_units="Degrees"
            ;;
        UTM)
            envi_proj="UTM"
            envi_units="Meters"
            ;;
        *)
            envi_proj="${PROJECTION:-Unknown}"
            envi_units="${X_UNIT:-Degrees}"
            ;;
    esac

    # Resolve ENVI datum/ellipsoid label
    case "$(echo "$DATUM" | tr '[:lower:]' '[:upper:]')" in
        WGS84|WGS-84)   envi_datum="WGS-84" ;;
        WGS72|WGS-72)   envi_datum="WGS-72" ;;
        NAD27)           envi_datum="North America 1927" ;;
        NAD83)           envi_datum="North America 1983" ;;
        *)               envi_datum="${DATUM:-WGS-84}" ;;
    esac

    # ------------------------------------------------------------------- #
    # Write the ENVI .hdr
    # ------------------------------------------------------------------- #
    cat > "$hdr" <<ENVI_HDR
ENVI
description = {${base} - converted from ${rsc}}
samples     = ${WIDTH}
lines       = ${FILE_LENGTH}
bands       = ${ENVI_BANDS}
header offset = 0
file type   = ENVI Standard
data type   = ${ENVI_DATA_TYPE}
interleave  = ${ENVI_INTERLEAVE}
byte order  = ${ENVI_BYTE_ORDER}
map info    = {${envi_proj}, 1, 1, ${X_FIRST}, ${Y_FIRST}, ${abs_x_step}, ${abs_y_step}, ${envi_datum}, units=${envi_units}}
coordinate system string = {GEOGCS["GCS_${envi_datum}",DATUM["D_${envi_datum}",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]]}
data ignore value = 0
z plot range = {${Z_OFFSET}, ${Z_SCALE}}
ENVI_HDR

    echo "  → Written: $hdr"

done

echo "Done."