#!/bin/bash
######################################################################################
# This script aims at punching out a series of ENVI Harris file in current dir into a  
# given crop. 
# The footprint and resolution of the existing envi files is read from the first hdr file
# in dir.  
# Those for the crop are entered as parameters as follow:
# 		<UL_LON> <UL_LAT> <LR_LON> <LR_LAT> <RES_DEG>
# e.g.	55.567199775 -21.110980076 55.8759 -21.3685 0.000277507079136694
#
# Parameters : 	- <UL_LON> <UL_LAT> <LR_LON> <LR_LAT> <RES_DEG>
#
# Hard coded:	- file format (r4): see BYTES_PER_PIXEL=4
#
# Dependencies:	- gawk, ggsed and ggrep
#
# WARNING: run a test before operate on full scale to bee sure that the naming and renaming fits your needs. 
#
#
# New in Distro V 1.0 20260611:	- setup
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/10 -	#  
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on June 11, 2026"

# ── Usage ──────────────────────────────────────────────────────────────────────
if [[ $# -ne 5 ]]; then
    echo "Usage: $0 <UL_LON> <UL_LAT> <LR_LON> <LR_LAT> <RES_DEG>"
    echo "  e.g: $0 55.567199775 -21.110980076 55.8759 -21.3685 0.000277507079136694"
    exit 1
fi

CROP_UL_LON=$1
CROP_UL_LAT=$2
CROP_LR_LON=$3
CROP_LR_LAT=$4
CROP_RES=$5

# ── Read source parameters from first .hdr file in current directory ───────────
SRC_HDR=$(ls *.hdr 2>/dev/null | head -1)
if [[ -z "$SRC_HDR" ]]; then
    echo "Error: no .hdr file found in current directory"
    exit 1
fi
echo "Reading source header: $SRC_HDR"

# Parse map info line: {Geographic Lat/Lon, 1, 1, lon, lat, xres, yres, ...}
MAP_INFO=$(${PATHGNU}/grep -m1 "^map info" "$SRC_HDR" | sed 's/.*{\(.*\)}/\1/')
SRC_UL_LON=$(echo "$MAP_INFO" | ${PATHGNU}/awk -F',' '{gsub(/ /,"",$4); print $4}')
SRC_UL_LAT=$(echo "$MAP_INFO" | ${PATHGNU}/awk -F',' '{gsub(/ /,"",$5); print $5}')
SRC_XRES=$(echo  "$MAP_INFO" | ${PATHGNU}/awk -F',' '{gsub(/ /,"",$6); print $6}')
SRC_YRES=$(echo  "$MAP_INFO" | ${PATHGNU}/awk -F',' '{gsub(/ /,"",$7); print $7}')
SRC_SAMPLES=$(${PATHGNU}/grep -m1 "^samples" "$SRC_HDR" | ${PATHGNU}/awk -F'=' '{gsub(/ /,"",$2); print $2}')
SRC_LINES=$(${PATHGNU}/grep   -m1 "^lines"   "$SRC_HDR" | ${PATHGNU}/awk -F'=' '{gsub(/ /,"",$2); print $2}')

echo "Source: samples=$SRC_SAMPLES lines=$SRC_LINES"
echo "Source: UL=($SRC_UL_LON, $SRC_UL_LAT)  res=($SRC_XRES, $SRC_YRES)"

# ── Compute crop size and pixel offsets from coordinates ───────────────────────
read COL_OFF ROW_OFF CROP_SAMPLES CROP_LINES < <(${PATHGNU}/awk \
    -v src_lon="$SRC_UL_LON" -v src_lat="$SRC_UL_LAT" \
    -v xres="$SRC_XRES"      -v yres="$SRC_YRES" \
    -v crop_ul_lon="$CROP_UL_LON" -v crop_ul_lat="$CROP_UL_LAT" \
    -v crop_lr_lon="$CROP_LR_LON" -v crop_lr_lat="$CROP_LR_LAT" \
    -v crop_res="$CROP_RES" \
    'BEGIN {
        col     = int((crop_ul_lon - src_lon) / xres + 0.5)
        row     = int((src_lat - crop_ul_lat) / yres + 0.5)
        samples = int((crop_lr_lon - crop_ul_lon) / crop_res + 0.5)
        lines   = int((crop_ul_lat - crop_lr_lat) / crop_res + 0.5)
        print col, row, samples, lines
    }')

echo "Pixel offset:  col=$COL_OFF  row=$ROW_OFF"
echo "Crop size:     ${CROP_SAMPLES} samples x ${CROP_LINES} lines"

# Sanity check
if [[ $COL_OFF -lt 0 || $ROW_OFF -lt 0 || \
      $(( COL_OFF + CROP_SAMPLES )) -gt $SRC_SAMPLES || \
      $(( ROW_OFF + CROP_LINES   )) -gt $SRC_LINES ]]; then
    echo "Error: crop window extends outside source image bounds"
    exit 1
fi

# ── Data type = 4 → float32 = 4 bytes ─────────────────────────────────────────
BYTES_PER_PIXEL=4

# ── Read coordinate system string from source hdr for output hdr ──────────────
COORD_SYS=$(${PATHGNU}/grep -m1 "^coordinate system string" "$SRC_HDR" | ${PATHGNU}/sed 's/coordinate system string = //')

# ── Loop over all .r4 files ────────────────────────────────────────────────────
for SRC_FILE in *.r4; do
    [[ -f "$SRC_FILE" ]] || continue

    OUT_FILE="${SRC_FILE%.r4}.crop.r4"
    echo "Cropping $SRC_FILE → $OUT_FILE"

    > "$OUT_FILE"
    for ((i=0; i<CROP_LINES; i++)); do
        LINE=$(( ROW_OFF + i ))
        SKIP=$(( LINE * SRC_SAMPLES + COL_OFF ))
        dd if="$SRC_FILE" bs=$BYTES_PER_PIXEL \
           skip=$SKIP count=$CROP_SAMPLES \
           >> "$OUT_FILE" 2>/dev/null
    done

    # ── Write companion .hdr ──────────────────────────────────────────────────
    cat > "${OUT_FILE}.hdr" <<HDR
ENVI
description = {${OUT_FILE}}
samples = ${CROP_SAMPLES}
lines   = ${CROP_LINES}
bands   = 1
header offset = 0
file type = ENVI Standard
data type = 4
interleave = bsq
byte order = 0
map info = {Geographic Lat/Lon, 1, 1, ${CROP_UL_LON}, ${CROP_UL_LAT}, ${CROP_RES}, ${CROP_RES},WGS-84}
coordinate system string = ${COORD_SYS}
band names = {
Band 1}
HDR

done

echo "All done."