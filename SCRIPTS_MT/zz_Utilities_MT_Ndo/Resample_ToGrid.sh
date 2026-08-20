#!/bin/bash
# +----------------------------------------------------------------------------+
# | Resample_To_Grid.sh                                                        |
# |                                                                            |
# | Resample INPUT on the EXACT grid of REFERENCE (same CRS, same extent,      |
# | same number of pixels) and write the result in ENVI Float32 format.        |
# |                                                                            |
# | Usage: Resample_To_Grid.sh REFERENCE INPUT OUTPUT [-R=method]              |
# |                           [-SRCNODATA=value] [-DSTNODATA=value]            |
# |                                                                            |
# |   REFERENCE : georeferenced raster defining the target grid (ENVI .hdr     |
# |               with map info, GeoTIFF, ...). Only its grid is used.         |
# |   INPUT     : georeferenced raster to resample                             |
# |   OUTPUT    : output ENVI binary. Beware: the GDAL ENVI driver writes the  |
# |               header by REPLACING the extension (out.r4 -> out.hdr), it     |
# |               does not append it. Both conventions are read back correctly  |
# |               by Diff_Envi_DivCos.py.                                       |
# |   -R=       : resampling method, default bilinear (near for masks/labels,  |
# |               bilinear or cubic for smooth fields such as ZTD or angles)   |
# |   -SRCNODATA= : value flagging voids in INPUT, e.g. 0 for GACOS .ztd.      |
# |               MUST be given if the voids are coded with a real number,     |
# |               otherwise interpolation smears them into valid pixels.       |
# |   -DSTNODATA= : value written in the empty parts of OUTPUT, default nan    |
# |                                                                            |
# | The target grid is read with gdalinfo, NOT by parsing the header, because   |
# | ENVI "map info" refers to pixel (1,1) while a GDAL geotransform refers to  |
# | the outer corner: parsing by hand is the classical source of half pixel    |
# | shifts. The grid of the result is verified against REFERENCE at the end.   |
# |                                                                            |
# | Mac OS X and Linux compatible (bash 3.2 safe); needs gdal + python3.       |
# +----------------------------------------------------------------------------+
set -u

PRG=$(basename "$0")

Usage()
	{
	echo "Usage: ${PRG} REFERENCE INPUT OUTPUT [-R=method] [-SRCNODATA=value] [-DSTNODATA=value]"
	exit 1
	}

[ $# -lt 3 ] && Usage

REF="$1"
IN="$2"
OUT="$3"
shift 3

METHOD="bilinear"
SRCNODATA=""
DSTNODATA="nan"

while [ $# -gt 0 ] ; do
	case "$1" in
		-R=*)		METHOD="${1#*=}" ;;
		-SRCNODATA=*)	SRCNODATA="${1#*=}" ;;
		-DSTNODATA=*)	DSTNODATA="${1#*=}" ;;
		*)		echo "ERROR: unknown option \"$1\"" ; Usage ;;
	esac
	shift
done

for FILE in "${REF}" "${IN}" ; do
	[ -f "${FILE}" ] || { echo "ERROR: ${FILE} does not exist" ; exit 1 ; }
done

for TOOL in gdalinfo gdalwarp python3 ; do
	command -v "${TOOL}" > /dev/null 2>&1 || { echo "ERROR: ${TOOL} is required" ; exit 1 ; }
done

TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/Resample_To_Grid.XXXXXX") || exit 1
trap 'rm -rf "${TMPDIR}"' 0 1 2 3 15

# ---- read the target grid from REFERENCE ------------------------------------
# GridOf writes: xmin ymin xmax ymax width height   and the CRS in $1
GridOf()
	{
	gdalinfo -json "$1" > "${TMPDIR}/ref.json" 2> "${TMPDIR}/ref.err" || {
		echo "ERROR: gdalinfo failed on $1" >&2 ; cat "${TMPDIR}/ref.err" >&2 ; return 1 ; }
	python3 - "${TMPDIR}/ref.json" "${TMPDIR}/ref.wkt" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as fh:
	info = json.load(fh)
corners = info.get("cornerCoordinates")
if not corners:
	sys.exit("ERROR: no georeferencing found in the reference (missing map info / CRS ?)")
xs = [corners[k][0] for k in ("upperLeft", "lowerLeft", "upperRight", "lowerRight")]
ys = [corners[k][1] for k in ("upperLeft", "lowerLeft", "upperRight", "lowerRight")]
wkt = info.get("coordinateSystem", {}).get("wkt", "")
if wkt == "":
	sys.exit("ERROR: the reference has no CRS - can not resample on its grid")
with open(sys.argv[2], "w") as fh:
	fh.write(wkt)
print("%.12f %.12f %.12f %.12f %d %d"
      % (min(xs), min(ys), max(xs), max(ys), info["size"][0], info["size"][1]))
PYEOF
	}

GRID=$(GridOf "${REF}") || exit 1
set -- ${GRID}
XMIN="$1" ; YMIN="$2" ; XMAX="$3" ; YMAX="$4" ; WIDTH="$5" ; HEIGHT="$6"

echo "Target grid from ${REF}: ${WIDTH} x ${HEIGHT} pixels"
echo "                extent : ${XMIN} ${YMIN} ${XMAX} ${YMAX}"

# ---- resample ---------------------------------------------------------------
# -te + -ts (rather than -tr) guarantees the very same pixel count as REFERENCE
SRCOPT=""
[ -n "${SRCNODATA}" ] && SRCOPT="-srcnodata ${SRCNODATA}"

# remove both possible header names, a stale one would be read back later
rm -f "${OUT}" "${OUT}.hdr" "${OUT%.*}.hdr"
gdalwarp -overwrite \
	-t_srs "${TMPDIR}/ref.wkt" \
	-te "${XMIN}" "${YMIN}" "${XMAX}" "${YMAX}" \
	-ts "${WIDTH}" "${HEIGHT}" \
	-r "${METHOD}" \
	${SRCOPT} -dstnodata "${DSTNODATA}" \
	-of ENVI -ot Float32 \
	"${IN}" "${OUT}" || { echo "ERROR: gdalwarp failed" ; exit 1 ; }

# ---- verify that the result really shares the grid of REFERENCE -------------
GRIDOUT=$(GridOf "${OUT}") || exit 1
if [ "${GRIDOUT}" != "${GRID}" ] ; then
	echo "ERROR: the grid of ${OUT} does not match ${REF}"
	echo "       reference: ${GRID}"
	echo "       output   : ${GRIDOUT}"
	exit 1
fi

OUTHDR="${OUT}.hdr"
[ -f "${OUTHDR}" ] || OUTHDR="${OUT%.*}.hdr"
echo "${OUT} and ${OUTHDR} written on the grid of ${REF} (${METHOD})"
