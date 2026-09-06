#!/bin/bash
# Build_WaterMask_forAMSTer_Auto.sh aims at creating a water bodies mask, by
# fetching the water data bases from the web (coastlines and inland water bodies).
#
# Mask characteristics:
#   - extent      : bounding box of a provided kml (or kmz), optionally buffered
#   - format      : ENVI (Harris) binary + .hdr, BSQ, single band
#   - data type   : Byte (ENVI data type 1) -> no NaN possible
#   - projection  : geographic lat/long, WGS84 (EPSG:4326)
#   - values      : 1 = water (masked), 0 = land (not masked). No nodata value.
#
# Usage: Build_WaterMask_forAMSTer_Auto.sh  -k FOOTPRINT.kml [options]
#
# Parameters :  -   -k FILE     kml (or kmz) defining the area of interest. Its bounding box
# 				                defines the extent of the mask.
# 				-   -o NAME     output basename (default: ./WaterMask). Creates NAME and NAME.hdr
# 				-   -p SIZE     pixel size in metres (default: 30). Suffix d for degrees,
# 				                e.g. -p 0.00027d for a grid square in degrees instead.
# 				-   -b SIZE     buffer added around the kml bounding box, same convention
# 				                as -p (default: 0 m)
# 				-   -s LIST     comma separated data bases (default: ocean,gsw)
# 				                   ocean : OSM coastline water polygons (seas and oceans)
# 				                   gsw   : JRC Global Surface Water (lakes, reservoirs, rivers)
# 				                   osm   : live Overpass query (small areas, most recent)
# 				-   -t PERCENT  water occurrence threshold for gsw, 1-100 (default: 50)
# 				-   -c DIR      cache directory for the downloaded data
# 				                (default: ${CACHE}, or \$AMSTER_WATERDATA)
# 				-   -w FILE     extra local polygon file to burn as water. Can be repeated.
# 				-   -h          Help
#
# Dependencies:	 
#    	- GDAL/OGR tools (ogrinfo, ogr2ogr, gdalwarp, gdalbuildvrt, gdal_rasterize),
#		- curl or wget, 
#		- unzip, 
#		- python of the AMSTer virtual environment.
#
# Hard coded:	- Path to databases, see below
#
# ---------------------------------------------------------------------------
# DATA BASES (only what covers the kml is downloaded, then cached for reuse)
#
#   ocean : OSM water polygons, WGS84 shapefile
#           https://osmdata.openstreetmap.de/data/water-polygons.html
#           Oceans and seas only (polygons closed on natural=coastline).
#           One global file, ~800 MB, downloaded once.
#
#   gsw   : JRC Global Surface Water, occurrence layer v1.5 (1984-2024), 30 m
#           https://global-surface-water.appspot.com/download
#           Inland water: lakes, reservoirs, wide rivers. 10x10 deg tiles,
#           only the tiles covering the kml are fetched.
#           A pixel is water where occurrence >= threshold (default 50 %).
#
#   osm   : live OpenStreetMap query through the Overpass API
#           natural=water, landuse=reservoir, waterway=riverbank
#           Small, always up to date, but limited to modest areas. Off by
#           default; useful for recent reservoirs or narrow rivers that
#           Landsat misses.
#
# The two families are complementary: 'ocean' is exact on the coastline but
# has no inland water, 'gsw' has all inland water but is unreliable offshore.
# Default is therefore "ocean,gsw".
# ---------------------------------------------------------------------------
#
#
# N. d'Oreye / AMSTer - v2.0
#
# New in Distro V 1.0 20260901 NdO:	- made with the help of Claude AI
# New in Distro V 1.1 20260902 NdO:	- ok for Monterey 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 02, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 
set -e

# --- GNU tools on Mac are prefixed by ${PATHGNU} in AMSTer -------------------
if [ -n "${PATHGNU}" ] && [ -x "${PATHGNU}/gawk" ]; then
	AWK="${PATHGNU}/gawk"
else
	AWK="awk"
fi

# --- where the data bases live ----------------------------------------------
OCEAN_URL="https://osmdata.openstreetmap.de/download/water-polygons-split-4326.zip"
GSW_BASE="https://s3.waw4-1.cloudferro.com/swift/v1/global-surface-water/download2024/Aggregated/VER1-5/occurrence"
GSW_SUFFIX="_v1_5_2024.tif"
OVERPASS_URL="https://overpass-api.de/api/interpreter"

# --- python from the AMSTer virtual environment ------------------------------
# Override with AMSTER_PYTHON if the venv sits elsewhere on this machine.
PYTHON="${AMSTER_PYTHON:-/opt/local/amster_python_env/bin/python}"

# --- defaults ---------------------------------------------------------------
KML=""
OUTPUT="WaterMask"
PIXSIZE="30"				# metres; add a "d" suffix to give it in degrees
BUFFER="0"					# same convention as PIXSIZE (metres, or "d" degrees)
SOURCES="ocean,gsw"
OCCTHRESH="50"				# % of water occurrence to call a pixel water
CACHE="${AMSTER_WATERDATA:-${HOME}/.AMSTer/WaterData}"
EXTRAFILES=()

usage()
{
	cat << EOF

Usage: $(basename "$0") -k FOOTPRINT.kml [options]

  -k FILE     kml (or kmz) defining the area of interest. Its bounding box
              defines the extent of the mask.
  -o NAME     output basename (default: ${OUTPUT}). Creates NAME and NAME.hdr
  -p SIZE     pixel size in metres (default: ${PIXSIZE}). Suffix d for degrees,
              e.g. -p 0.00027d for a grid square in degrees instead.
  -b SIZE     buffer added around the kml bounding box, same convention
              as -p (default: ${BUFFER} m)
  -s LIST     comma separated data bases (default: ${SOURCES})
                 ocean : OSM coastline water polygons (seas and oceans)
                 gsw   : JRC Global Surface Water (lakes, reservoirs, rivers)
                 osm   : live Overpass query (small areas, most recent)
  -t PERCENT  water occurrence threshold for gsw, 1-100 (default: ${OCCTHRESH})
  -c DIR      cache directory for the downloaded data
              (default: ${CACHE}, or \$AMSTER_WATERDATA)
  -w FILE     extra local polygon file to burn as water. Can be repeated.
  -h          this help

Examples:
  # coastal volcano: ocean + inland lakes
  $(basename "$0") -k Fogo.kml -o Fogo_WaterMask -b 0.02

  # inland area: skip the 800 MB ocean download
  $(basename "$0") -k Domuyo.kml -s gsw -o Domuyo_WaterMask

  # add the most recent OSM reservoirs and your own shapefile
  $(basename "$0") -k Site.kml -s gsw,osm -w MyPonds.shp

EOF
}

while getopts "k:o:p:b:s:t:c:w:h" OPT ; do
	case ${OPT} in
		k) KML="${OPTARG}" ;;
		o) OUTPUT="${OPTARG}" ;;
		p) PIXSIZE="${OPTARG}" ;;
		b) BUFFER="${OPTARG}" ;;
		s) SOURCES="${OPTARG}" ;;
		t) OCCTHRESH="${OPTARG}" ;;
		c) CACHE="${OPTARG}" ;;
		w) EXTRAFILES+=("${OPTARG}") ;;
		h) usage ; exit 0 ;;
		*) usage ; exit 1 ;;
	esac
done

# --- checks -----------------------------------------------------------------
for TOOL in ogrinfo ogr2ogr gdal_rasterize gdalwarp gdalbuildvrt ; do
	command -v ${TOOL} > /dev/null 2>&1 || { echo "ERROR: ${TOOL} not found." ; exit 1 ; }
done

[ -x "${PYTHON}" ] || { echo "ERROR: AMSTer python not found at ${PYTHON}" ; \
	echo "       set AMSTER_PYTHON to the python of your AMSTer venv." ; exit 1 ; }

if command -v curl > /dev/null 2>&1 ; then
	GETTER="curl"
elif command -v wget > /dev/null 2>&1 ; then
	GETTER="wget"
else
	echo "ERROR: neither curl nor wget found." ; exit 1
fi

[ -z "${KML}" ] && { echo "ERROR: no kml provided." ; usage ; exit 1 ; }
[ -f "${KML}" ] || { echo "ERROR: kml not found: ${KML}" ; exit 1 ; }

WantSource()	# name -> true if listed in ${SOURCES}
{
	echo ",${SOURCES}," | grep -q ",$1," 
}

mkdir -p "${CACHE}"

WRKDIR=$(mktemp -d "${TMPDIR:-/tmp}/watermask.XXXXXX")
trap 'rm -rf "${WRKDIR}"' EXIT INT TERM

# --- download helper --------------------------------------------------------
# Downloads to a .part file and renames only on success, so an interrupted
# transfer can never be mistaken for a valid cached file.
Download()	# url  destination  -> 1 if the file could not be fetched
{
	URL="$1" ; DST="$2"
	[ -s "${DST}" ] && return 0
	echo "  fetching $(basename "${DST}") ..."
	if [ "${GETTER}" = "curl" ] ; then
		# resume an interrupted transfer; if the server refuses the range
		# (or the leftover .part is already complete), restart from scratch
		if ! curl -f -L -C - -# -o "${DST}.part" "${URL}" ; then
			rm -f "${DST}.part"
			curl -f -L -# -o "${DST}.part" "${URL}" || { rm -f "${DST}.part" ; return 1 ; }
		fi
	else
		wget -q -O "${DST}.part" "${URL}" || { rm -f "${DST}.part" ; return 1 ; }
	fi
	mv "${DST}.part" "${DST}"
}

# --- 1. bounding box of the area of interest ---------------------------------
# A kml is parsed straight from its xml: every <coordinates> block is read and
# reduced to a bounding box. This deliberately does NOT go through OGR. Both
# kml drivers are optional in a GDAL build (KML needs expat, LIBKML needs
# libkml), so an installation without them cannot open a kml at all, whatever
# the file contains. Kml is WGS84 by specification, so nothing is reprojected.
# Any other vector format (shp, gpkg, geojson...) still goes through ogrinfo.
echo "Reading extent of ${KML}..."

case "${KML}" in
	*.kmz|*.KMZ)
		command -v unzip > /dev/null 2>&1 || { echo "ERROR: unzip is needed to read a kmz." ; exit 1 ; }
		unzip -p "${KML}" "*.kml" > "${WRKDIR}/aoi.kml" 2>/dev/null
		AOIXML="${WRKDIR}/aoi.kml" ;;
	*.kml|*.KML)
		AOIXML="${KML}" ;;
	*)
		AOIXML="" ;;
esac

if [ -n "${AOIXML}" ] ; then
	# <coordinates> holds whitespace separated lon,lat[,alt] tuples, possibly
	# spread over several lines. Anything that is not a lon,lat pair (a LookAt,
	# a style, an altitude alone) is ignored.
	BBOX=$(${AWK} '
	function keep(lo, la) {
		if (lo < -180 || lo > 180 || la < -90 || la > 90) return
		if (n == 0) { xmin = lo ; xmax = lo ; ymin = la ; ymax = la ; n = 1 ; return }
		if (lo < xmin) xmin = lo ; if (lo > xmax) xmax = lo
		if (la < ymin) ymin = la ; if (la > ymax) ymax = la
	}
	function scan(chunk,   nt, i, t, nc, c) {
		nt = split(chunk, t, /[ \t\r\n]+/)
		for (i = 1 ; i <= nt ; i++) {
			if (t[i] == "") continue
			nc = split(t[i], c, ",")
			if (nc < 2) continue
			if (c[1] !~ /^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?$/) continue
			if (c[2] !~ /^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?$/) continue
			keep(c[1] + 0, c[2] + 0)
		}
	}
	{
		line = $0
		while (line != "") {
			if (inside == 0) {
				p = index(line, "<coordinates>")
				if (p == 0) break
				line = substr(line, p + 13)
				inside = 1
			}
			q = index(line, "</coordinates>")
			if (q > 0) { scan(substr(line, 1, q - 1)) ; line = substr(line, q + 14) ; inside = 0 }
			else       { scan(line) ; line = "" }
		}
	}
	END { if (n == 1) printf "%.10f %.10f %.10f %.10f\n", xmin, ymin, xmax, ymax }' "${AOIXML}")
else
	# ogrinfo reports one "Extent: (xmin, ymin) - (xmax, ymax)" line per layer.
	# All layers are combined to get the true footprint. Its stderr is kept so
	# that a missing driver is reported instead of being silently swallowed.
	BBOX=$(ogrinfo -ro -al -so "${KML}" 2> "${WRKDIR}/ogr.err" | ${AWK} -F'[(),]' '
		/Extent:/ {
			if (n == 0) { xmin = $2 ; ymin = $3 ; xmax = $5 ; ymax = $6 ; n = 1 }
			else {
				if ($2 + 0 < xmin + 0) xmin = $2
				if ($3 + 0 < ymin + 0) ymin = $3
				if ($5 + 0 > xmax + 0) xmax = $5
				if ($6 + 0 > ymax + 0) ymax = $6
			}
		}
		END { if (n == 1) printf "%.10f %.10f %.10f %.10f\n", xmin, ymin, xmax, ymax }')
fi

if [ -z "${BBOX}" ] ; then
	echo "ERROR: no usable coordinates found in ${KML}"
	if [ -s "${WRKDIR}/ogr.err" ] ; then
		echo "       OGR reported:"
		${AWK} '{ print "       " $0 }' "${WRKDIR}/ogr.err"
	fi
	exit 1
fi

# --- 2. pixel size in degrees, then snap the box on a global grid ------------
# The requested size is metric by default (suffix d = already in degrees).
# A degree of longitude shrinks with latitude while a degree of latitude does
# not, so the two axes get different steps: the pixels are then square on the
# ground, which is what matters, not square in the header. The conversion uses
# the highest latitude of the box, so the mask is never coarser than asked for
# anywhere inside it. Steps are rounded to 1e-7 deg (~1 cm) to keep the header
# readable and identical for neighbouring frames.
REFLAT=$(echo "${BBOX}" | ${AWK} '{ a = ($2 < 0) ? -$2 : $2 ; b = ($4 < 0) ? -$4 : $4 ; print (a > b) ? a : b }')

STEPS=$(${AWK} -v pix="${PIXSIZE}" -v buf="${BUFFER}" -v lat="${REFLAT}" '
	function round7(v) { return int(v * 10000000 + 0.5) / 10000000 }
	BEGIN {
		r = lat * atan2(0, -1) / 180
		mlat = 111132.92 - 559.82 * cos(2*r) + 1.175 * cos(4*r) - 0.0023 * cos(6*r)
		mlon = 111412.84 * cos(r) -  93.50 * cos(3*r) + 0.118 * cos(5*r)
		if (mlon < 1) { print "ERROR" ; exit }
		if (pix ~ /[dD]$/) { pixx = pix + 0             ; pixy = pix + 0             }
		else               { pixx = round7((pix+0)/mlon) ; pixy = round7((pix+0)/mlat) }
		if (buf ~ /[dD]$/) { bufx = buf + 0             ; bufy = buf + 0             }
		else               { bufx = (buf+0)/mlon        ; bufy = (buf+0)/mlat        }
		if (pixx <= 0 || pixy <= 0) { print "ERROR" ; exit }
		printf "%.10f %.10f %.10f %.10f %.1f %.1f\n", pixx, pixy, bufx, bufy, pixx*mlon, pixy*mlat
	}')

[ "${STEPS}" = "ERROR" ] && { echo "ERROR: cannot convert ${PIXSIZE} into degrees at latitude ${REFLAT}." ; exit 1 ; }
set -- ${STEPS}
PIXX=$1 ; PIXY=$2 ; BUFX=$3 ; BUFY=$4 ; MX=$5 ; MY=$6

# Snapping on floor(coord/pix)*pix (and not on the kml corner) makes the grid
# reproducible: two masks built with the same pixel size are always aligned,
# and the pixel size divides the extent exactly (no rounding by gdal).
# eps (in pixel unit) avoids adding a spurious pixel when a corner already
# falls exactly on a grid line but is stored as e.g. 186099.9999999998
GRID=$(echo "${BBOX}" | ${AWK} -v pixx="${PIXX}" -v pixy="${PIXY}" -v bufx="${BUFX}" -v bufy="${BUFY}" '
	function floor(x) { return (x == int(x)) ? x : (x < 0 ? int(x) - 1 : int(x)) }
	function ceil(x)  { return (x == int(x)) ? x : (x < 0 ? int(x) : int(x) + 1) }
	BEGIN { eps = 0.000001 }
	{
		xmin = floor(($1 - bufx) / pixx + eps) * pixx
		ymin = floor(($2 - bufy) / pixy + eps) * pixy
		xmax = ceil(($3 + bufx) / pixx - eps) * pixx
		ymax = ceil(($4 + bufy) / pixy - eps) * pixy
		if (xmin < -180) xmin = -180 ; if (xmax >  180) xmax =  180
		if (ymin <  -90) ymin =  -90 ; if (ymax >   90) ymax =   90
		nx = int((xmax - xmin) / pixx + 0.5)
		ny = int((ymax - ymin) / pixy + 0.5)
		printf "%.10f %.10f %.10f %.10f %d %d\n", xmin, ymin, xmax, ymax, nx, ny
	}')

set -- ${GRID}
XMIN=$1 ; YMIN=$2 ; XMAX=$3 ; YMAX=$4 ; NX=$5 ; NY=$6

[ "${NX}" -gt 0 ] && [ "${NY}" -gt 0 ] || { echo "ERROR: empty extent. Pixel size too large ?" ; exit 1 ; }

echo "  extent : ${XMIN} ${YMIN} -> ${XMAX} ${YMAX} (deg, WGS84)"
echo "  pixel  : ${PIXX} x ${PIXY} deg  ( ${MX} x ${MY} m at latitude ${REFLAT} )"
echo "  size   : ${NX} x ${NY} pixels"
echo "  cache  : ${CACHE}"

echo "${XMIN} ${XMAX}" | ${AWK} '{ if ($1 <= -179.999 || $2 >= 179.999) \
	print "  WARNING: extent touches the antimeridian; check the result." }'

rm -f "${OUTPUT}" "${OUTPUT}.hdr" "${OUTPUT}.aux.xml"

# --- 3. raster source: JRC Global Surface Water ------------------------------
# The occurrence tiles are named after their upper left corner, in 10 deg
# steps: longitude 180W..170E, latitude 80N..50S. Only the tiles overlapping
# the area of interest are fetched.
if WantSource gsw ; then
	echo "JRC Global Surface Water (occurrence >= ${OCCTHRESH} %)..."
	mkdir -p "${CACHE}/gsw"

	TILES=$(echo "${XMIN} ${YMIN} ${XMAX} ${YMAX}" | ${AWK} '
		function floor(x) { return (x == int(x)) ? x : (x < 0 ? int(x) - 1 : int(x)) }
		function ceil(x)  { return (x == int(x)) ? x : (x < 0 ? int(x) : int(x) + 1) }
		function lonname(v) { return (v < 0) ? -v "W" : v "E" }
		function latname(v) { return (v < 0) ? -v "S" : v "N" }
		BEGIN { eps = 0.000001 }
		{
			lon0 = floor($1 / 10) * 10
			lon1 = floor(($3 - eps) / 10) * 10
			lat0 = ceil(($2 + eps) / 10) * 10
			lat1 = ceil($4 / 10) * 10
			for (x = lon0 ; x <= lon1 ; x += 10) {
				if (x < -180 || x > 170) continue
				for (y = lat0 ; y <= lat1 ; y += 10) {
					if (y < -50 || y > 80) continue
					print lonname(x) "_" latname(y)
				}
			}
		}')

	GOTTILE=0
	for TILE in ${TILES} ; do
		TIF="${CACHE}/gsw/occurrence_${TILE}${GSW_SUFFIX}"
		if Download "${GSW_BASE}/occurrence_${TILE}${GSW_SUFFIX}" "${TIF}" ; then
			echo "${TIF}" >> "${WRKDIR}/gsw_list.txt"
			GOTTILE=$((GOTTILE + 1))
		else
			echo "  no tile ${TILE} (outside the GSW coverage), skipped."
		fi
	done

	if [ ${GOTTILE} -gt 0 ] ; then
		gdalbuildvrt -q -input_file_list "${WRKDIR}/gsw_list.txt" "${WRKDIR}/gsw.vrt"
		# -r average: works both when the target grid is finer than the 30 m
		# source (average of one pixel = that pixel) and when it is coarser
		# (fraction weighted occurrence). 255 is the GSW no-data code.
		echo "  resampling ${GOTTILE} tile(s) onto the mask grid..."
		gdalwarp -q -overwrite \
			-t_srs EPSG:4326 -r average \
			-te "${XMIN}" "${YMIN}" "${XMAX}" "${YMAX}" -ts "${NX}" "${NY}" \
			-srcnodata 255 -dstnodata 0 \
			-ot Byte -of ENVI -co INTERLEAVE=BSQ \
			"${WRKDIR}/gsw.vrt" "${OUTPUT}"

		# occurrence (0-100, 255 = no data) -> 0/1, in place, byte per byte
		echo "  thresholding occurrence at ${OCCTHRESH} %..."
		"${PYTHON}" - "${OUTPUT}" "${OCCTHRESH}" << 'PYEOF'
import sys
path, thr = sys.argv[1], int(sys.argv[2])
table = bytes(1 if thr <= v <= 100 else 0 for v in range(256))
with open(path, 'r+b') as f:
	while True:
		pos = f.tell()
		chunk = f.read(1 << 20)
		if not chunk:
			break
		f.seek(pos)
		f.write(chunk.translate(table))
PYEOF
	else
		echo "  no GSW tile available for this area."
	fi
fi

# --- 4. vector sources -------------------------------------------------------
# Everything below is burnt with the value 1 into the mask. Overlaps between
# sources are harmless: burning 1 over 1 stays 1.
VECTORS=()

# 4a. OSM water polygons: oceans and seas
if WantSource ocean ; then
	echo "OSM water polygons (oceans and seas)..."
	ZIP="${CACHE}/water-polygons-split-4326.zip"
	if [ ! -s "${ZIP}" ] ; then
		echo "  first use: downloading the global file (~800 MB, once)."
	fi
	Download "${OCEAN_URL}" "${ZIP}" || { echo "ERROR: cannot download ${OCEAN_URL}" ; exit 1 ; }

	# find the shapefile rather than assume the folder name inside the zip
	OCEANSHP=$(find "${CACHE}" -name "water_polygons.shp" 2>/dev/null | head -n 1)
	if [ -z "${OCEANSHP}" ] ; then
		command -v unzip > /dev/null 2>&1 || { echo "ERROR: unzip not found." ; exit 1 ; }
		echo "  unpacking..."
		unzip -q -o "${ZIP}" -d "${CACHE}"
		OCEANSHP=$(find "${CACHE}" -name "water_polygons.shp" | head -n 1)
	fi
	[ -n "${OCEANSHP}" ] || { echo "ERROR: water_polygons.shp not found in the archive." ; exit 1 ; }

	# build the spatial index once: without it every run scans the whole
	# global file, with it the clipping below is nearly instantaneous
	if [ ! -f "${OCEANSHP%.shp}.qix" ] ; then
		echo "  building the spatial index (once)..."
		ogrinfo -q "${OCEANSHP}" -sql "CREATE SPATIAL INDEX ON water_polygons" || true
	fi
	VECTORS+=("${OCEANSHP}")
fi

# 4b. live OpenStreetMap query
if WantSource osm ; then
	echo "OpenStreetMap live query (Overpass)..."
	OSMFILE="${WRKDIR}/osm_water.osm"
	QUERY="[out:xml][timeout:300];
	       ( way[\"natural\"=\"water\"](${YMIN},${XMIN},${YMAX},${XMAX});
	         relation[\"natural\"=\"water\"](${YMIN},${XMIN},${YMAX},${XMAX});
	         way[\"landuse\"=\"reservoir\"](${YMIN},${XMIN},${YMAX},${XMAX});
	         relation[\"landuse\"=\"reservoir\"](${YMIN},${XMIN},${YMAX},${XMAX});
	         way[\"waterway\"=\"riverbank\"](${YMIN},${XMIN},${YMAX},${XMAX});
	         relation[\"waterway\"=\"riverbank\"](${YMIN},${XMIN},${YMAX},${XMAX}); );
	       (._;>;); out body;"

	if [ "${GETTER}" = "curl" ] ; then
		curl -f -s --data-urlencode "data=${QUERY}" "${OVERPASS_URL}" -o "${OSMFILE}" || OSMFILE=""
	else
		wget -q -O "${OSMFILE}" --post-data="data=${QUERY}" "${OVERPASS_URL}" || OSMFILE=""
	fi

	if [ -n "${OSMFILE}" ] && [ -s "${OSMFILE}" ] ; then
		# every feature returned was selected by the query above, so the
		# whole multipolygons layer is water: no client side filtering needed
		VECTORS+=("${OSMFILE}")
	else
		echo "  Overpass returned nothing (area too large, or server busy). Skipped."
	fi
fi

# 4c. extra local files given with -w
IDX=0
while [ ${IDX} -lt ${#EXTRAFILES[@]} ] ; do
	[ -f "${EXTRAFILES[${IDX}]}" ] || { echo "ERROR: file not found: ${EXTRAFILES[${IDX}]}" ; exit 1 ; }
	VECTORS+=("${EXTRAFILES[${IDX}]}")
	IDX=$((IDX + 1))
done

# --- 5. clip and burn every vector source ------------------------------------
IDX=0
while [ ${IDX} -lt ${#VECTORS[@]} ] ; do
	SRC="${VECTORS[${IDX}]}"
	CLIP="${WRKDIR}/clip_${IDX}.gpkg"

	echo "Clipping $(basename "${SRC}") to the area of interest..."
	# -spat uses the spatial index, so a huge global file is read fast
	# -clipsrc cuts the polygons, keeping the temporary file small
	# -t_srs: whatever the source projection is, we work in WGS84
	case "${SRC}" in
		*.osm) LAYER="multipolygons" ;;
		*)     LAYER="" ;;
	esac

	ogr2ogr -f GPKG "${CLIP}" "${SRC}" ${LAYER} \
		-t_srs EPSG:4326 \
		-spat "${XMIN}" "${YMIN}" "${XMAX}" "${YMAX}" \
		-clipsrc "${XMIN}" "${YMIN}" "${XMAX}" "${YMAX}" \
		-nln water -nlt PROMOTE_TO_MULTI -skipfailures

	NFEAT=$(ogrinfo -ro -al -so "${CLIP}" 2>/dev/null | ${AWK} -F: '/Feature Count/ { gsub(/ /,"",$2) ; print $2 }')
	[ -z "${NFEAT}" ] && NFEAT=0
	echo "  ${NFEAT} water polygon(s) in the area."

	if [ ! -f "${OUTPUT}" ] ; then
		# nothing created yet: this source defines the raster, land at 0
		gdal_rasterize -q \
			-l water -burn 1 -init 0 \
			-ot Byte -of ENVI -co INTERLEAVE=BSQ \
			-a_srs EPSG:4326 \
			-te "${XMIN}" "${YMIN}" "${XMAX}" "${YMAX}" -ts "${NX}" "${NY}" \
			"${CLIP}" "${OUTPUT}"
	else
		gdal_rasterize -q -l water -burn 1 "${CLIP}" "${OUTPUT}"
	fi

	IDX=$((IDX + 1))
done

# --- 6. nothing at all found: still deliver a valid all-land mask ------------
if [ ! -f "${OUTPUT}" ] ; then
	echo "No water found in any source: writing an all-land mask."
	# the extent as a single polygon, burnt with 0. Written as geojson, whose
	# driver is always present, so this does not depend on the kml drivers
	# either. Going through a gpkg fixes the layer name across GDAL versions.
	printf '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[%s,%s],[%s,%s],[%s,%s],[%s,%s],[%s,%s]]]}}]}\n' \
		"${XMIN}" "${YMIN}" "${XMAX}" "${YMIN}" "${XMAX}" "${YMAX}" "${XMIN}" "${YMAX}" "${XMIN}" "${YMIN}" \
		> "${WRKDIR}/aoi.geojson"
	ogr2ogr -f GPKG "${WRKDIR}/aoi.gpkg" "${WRKDIR}/aoi.geojson" -nln water -nlt MULTIPOLYGON
	gdal_rasterize -q -l water -burn 0 -init 0 \
		-ot Byte -of ENVI -co INTERLEAVE=BSQ -a_srs EPSG:4326 \
		-te "${XMIN}" "${YMIN}" "${XMAX}" "${YMAX}" -ts "${NX}" "${NY}" \
		"${WRKDIR}/aoi.gpkg" "${OUTPUT}"
fi

# --- 7. make sure the header is a clean ENVI/Harris header -------------------
# A "data ignore value" would be read by ENVI/Harris as a NaN-like flag, so it
# is removed: every pixel of the mask is a valid 0 or 1.
if grep -q "data ignore value" "${OUTPUT}.hdr" 2>/dev/null ; then
	grep -v "data ignore value" "${OUTPUT}.hdr" > "${WRKDIR}/hdr" && mv "${WRKDIR}/hdr" "${OUTPUT}.hdr"
fi
rm -f "${OUTPUT}.aux.xml"

echo ""
echo "Done: ${OUTPUT} + ${OUTPUT}.hdr        (1 = water, 0 = land)"
echo "-------------------------------------------------------------"
cat "${OUTPUT}.hdr"
echo "-------------------------------------------------------------"
