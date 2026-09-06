#!/bin/bash
# ----------------------------------------------------------------------------
# CreateBackgroundMaps.sh
#
# Create the "satview" and "terrain" background maps required by the AMSTer
# defo_region web pages, i.e. the two images that ZoneMaker_2.0.sh crops to
# show the time series pairs of points on a satellite or relief background.
#
# The maps are built directly from an XYZ tile server and resampled onto
# EXACTLY the grid of a template AMSTer product (same projection, same
# footprint, pixel size divided by an integer factor). This replaces the
# manual QGIS export described in the "Side procedure" chapter of the
# AMSTer Web Page documentation.
#
# The oversampling factor given with -f IS the RateResolutionFactor to be
# written in the parameters file: the output has exactly FACTOR times more
# columns and lines than the template, so the ratio is exact by construction
# (no need to divide image sizes afterwards).
#
# Hardcoded:	-	VIEWURL='https://mt1.google.com/vt/lyrs=s&hl=en&x=${x}&y=${y}&z=${z}'
#
# Usage:
#   CreateBackgroundMaps.sh -e TEMPLATE [options]
#
#   -e TEMPLATE   template raster of the region: any georeferenced ENVI or
#                 GeoTiff product (amplitude, MSBAS deformation...). Give the
#                 binary file, not the .hdr (a trailing .hdr is ignored).
#   -d DOCDIR     output directory, i.e. the Documents folder of the web page
#                 (default: current directory)
#   -v VIEW       sat | terrain | both                       (default: both)
#   -f FACTOR     integer oversampling factor = RateResolutionFactor
#                                                            (default: 2)
#   -z ZOOM       force the tile zoom level (default: computed from FACTOR)
#   -u URL        tile URL template, with ${x} ${y} ${z} placeholders.
#                 Overrides the default server for the requested view.
#   -r METHOD     gdalwarp resampling: cubic, bilinear, average, near
#                                                            (default: cubic)
#   -x EXT        extension of the tiff output: tif | tiff    (default: tif)
#   -p PARAMFILE  parameters file to update (a .bak copy of the file as it was
#                 before the run is kept). Are set:
#                   . RateResoSatView, RateResoSattelite, RateResoSatellite
#                     and any other RateResoSat* spelling -> FACTOR. They all
#                     describe the same ratio and must stay consistent.
#                   . RateResoTerrain -> FACTOR
#                   . Crop_L, Crop_H -> size of TEMPLATE, and Crop_X, Crop_Y
#                     -> 0, i.e. no crop at all of the products
#                   . WebPage -> the name given with -w, if any
#                 A parameter that is not in the file is added next to the
#                 ones of the same family.
#   -w NAME       name of the region to write in the WebPage parameter
#                 (requires -p). Nothing is written without it.
#   -c NB         simultaneous connections to the tile server (default: 2).
#                 Lower it to 1 if the server keeps timing out.
#   -a NB         attempts allowed for one map (default: 6). Tiles already
#                 fetched are cached, so each attempt resumes where the
#                 previous one stopped.
#   -C CACHEDIR   gdal wms tile cache (default: ${HOME}/.cache/gdalwmscache).
#                 Point it to a large volume for big regions, and keep it
#                 between runs.
#   -n            dry run: print the grid that would be built and stop
#   -h            this help
#
# Example:
#   CreateBackgroundMaps.sh -f 5 -p /opt/local/www/apache2/html/defo-PF/parameters.txt \
#        -e /.../MSBAS/_PF_S1.../zz_LOS_TS_Asc.../ampli_20230115_deg \
#        -d /opt/local/www/apache2/html/defo-PF/Documents
#
# Dependencies: - gdal (gdalinfo, gdalwarp, gdal_translate) with the WMS driver,
#				- EnviGridInfo.py
#              	- the AMSTer python environment.
#
# Beware: fetching tiles from a commercial tile server may not be allowed by
# its terms of service. Check them, or point -u to a service you are entitled
# to use, e.g. ESRI World Imagery:
#   -u 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}'
#
# N.B.: the AMSTer web page documentation is not consistent about the name of
#       these files (satview.tif, satview.tiff, terrain.tif, terrain.tiff) nor
#       about which google layer is which. Check what ZoneMaker_2.0.sh and
#       your parameters file actually read, and adjust -x / -u if needed.
#
# New in Distro V 1.0 20260904:	- created with assistance of AI
# New in Distro V 1.1 20260904:	- update all the RateResoSat* parameters, whatever
#								  their name or spelling, and add RateResoTerrain
#								  when it is missing
# 								- set Crop_L/Crop_H to the size of the template and
#								  Crop_X/Crop_Y to 0
#								- write the WebPage parameter (-w). Add it if missing.
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 04, 2026"

set -u

PRG=$(basename "$0")
SCRIPTDIR=$(cd "$(dirname "$0")" && pwd)
PYTHON=/opt/local/amster_python_env/bin/python
GRIDINFO="${SCRIPTDIR}/EnviGridInfo.py"

# GNU tools on Mac are expected in ${PATHGNU} as in all AMSTer scripts
if [ "${PATHGNU:-}" != "" ] && [ -x "${PATHGNU}/gawk" ] ; then
	AWK="${PATHGNU}/gawk"
	SED="${PATHGNU}/gsed"
else
	AWK=awk
	SED=sed
fi

# defaults
TEMPLATE=""
DOCDIR="."
VIEW="both"
FACTOR=2
FORCEDZOOM=""
USERURL=""
RESAMPLE="cubic"
EXT="tif"
PARAMFILE=""
REGIONNAME=""
CONNECTIONS=2
ATTEMPTS=6
CACHEDIR="${HOME}/.cache/gdalwmscache"
PARAMBACKUPDONE="no"
DRYRUN="no"
TILEUA="Mozilla/5.0 (compatible; AMSTer CreateBackgroundMaps)"

Usage()
{
	${SED} -n '3,/^# New in Distro/p' "$0" | ${SED} 's/^# \{0,1\}//' | ${SED} '$d'
	exit "${1:-0}"
}

Die()
{
	echo ""
	echo "!!! ${PRG}: $1"
	echo ""
	exit 1
}

CheckTool()
{
	command -v "$1" > /dev/null 2>&1 || Die "$1 is required but not in PATH"
}

# ----------------------------------------------------------------------------
# Set the parameters attached to a view: name, tile server, parameter keyword
# ----------------------------------------------------------------------------
SetView()
{
	case "$1" in
		sat)
			VIEWNAME="satview"
			# PARAMKEY is a prefix: every parameter whose name starts with it
			# is updated, so that all the spellings met in the parameters
			# files (RateResoSatView, RateResoSattelite, RateResoSatellite)
			# stay consistent with the factor actually used here. PARAMNAME
			# is the name written if none of them is present yet.
			PARAMKEY="RateResoSat[A-Za-z]*"
			PARAMNAME="RateResoSatellite"
			PARAMDESC="(Rate of pixels number in the satellite view compare with envi files)"
			# google satellite imagery
			VIEWURL='https://mt1.google.com/vt/lyrs=s&hl=en&x=${x}&y=${y}&z=${z}'
			VIEWMAXZOOM=20
			;;
		terrain)
			VIEWNAME="terrain"
			PARAMKEY="RateResoTerrain"
			PARAMNAME="RateResoTerrain"
			PARAMDESC="(Rate of pixels number in the terrain view compare with envi files)"
			# google terrain / relief
			VIEWURL='https://mt1.google.com/vt/lyrs=p&hl=en&x=${x}&y=${y}&z=${z}'
			VIEWMAXZOOM=17
			;;
		*)
			Die "unknown view $1 (expected sat, terrain or both)"
			;;
	esac
	if [ "${USERURL}" != "" ] ; then VIEWURL="${USERURL}" ; fi
}

# ----------------------------------------------------------------------------
# Write the GDAL WMS descriptor of an XYZ tile server
#   $1 = descriptor file, $2 = url template, $3 = zoom level
# ----------------------------------------------------------------------------
WriteTileDescriptor()
{
	# & is not valid as such in xml
	URLXML=$(printf '%s' "$2" | ${SED} 's/&/\&amp;/g')

	# unquoted heredoc: ${URLXML} is expanded, \${x} stays literal for GDAL
	cat > "$1" << EOF
<GDAL_WMS>
    <Service name="TMS">
        <ServerUrl>${URLXML}</ServerUrl>
    </Service>
    <DataWindow>
        <UpperLeftX>-20037508.34</UpperLeftX>
        <UpperLeftY>20037508.34</UpperLeftY>
        <LowerRightX>20037508.34</LowerRightX>
        <LowerRightY>-20037508.34</LowerRightY>
        <TileLevel>$3</TileLevel>
        <TileCountX>1</TileCountX>
        <TileCountY>1</TileCountY>
        <YOrigin>top</YOrigin>
    </DataWindow>
    <Projection>EPSG:3857</Projection>
    <BlockSizeX>256</BlockSizeX>
    <BlockSizeY>256</BlockSizeY>
    <BandsCount>3</BandsCount>
    <MaxConnections>${CONNECTIONS}</MaxConnections>
    <Timeout>120</Timeout>
    <UserAgent>${TILEUA}</UserAgent>
    <!-- Only the codes that really mean "no tile here" are turned into empty
         blocks. Throttling and server errors must remain errors, otherwise
         the map silently gets black holes where the server refused to
         answer. -->
    <ZeroBlockHttpCodes>204,404</ZeroBlockHttpCodes>
    <Cache>
        <Path>${CACHEDIR}</Path>
    </Cache>
</GDAL_WMS>
EOF
}

# ----------------------------------------------------------------------------
# Add a parameter line to an AMSTer parameters file, next to the parameters of
# the same family if there are any, at the end of the file otherwise.
#   $1 = file, $2 = parameter name, $3 = value, $4 = description,
#   $5 = regex of the family the new line must be grouped with
# ----------------------------------------------------------------------------
AddParameter()
{
	ADD_FILE="$1" ; ADD_NAME="$2" ; ADD_VALUE="$3"
	ADD_DESC="$4" ; ADD_FAMILY="$5"

	ADD_LINE=$(printf '%s\t\t# %s %s' "${ADD_VALUE}" "${ADD_NAME}" "${ADD_DESC}")

	# insert after the last line of the family, to keep the file readable
	ADD_AT=$(grep -n "#[[:space:]]*${ADD_FAMILY}" "${ADD_FILE}" | tail -1 | cut -d: -f1)
	if [ "${ADD_AT}" = "" ] ; then
		ADD_AT=$(${AWK} 'END { print NR }' "${ADD_FILE}")
	fi

	# the file is rewritten in place rather than replaced by a mv, so that
	# its owner and rights (apache _www) are preserved
	${AWK} -v at="${ADD_AT}" -v new="${ADD_LINE}" '
		{ print }
		NR == at { print new }
		END { if (at == 0) { print new } }
	' "${ADD_FILE}" > "${TMPWORK}/parameters.new" \
		|| Die "cannot prepare the new ${ADD_FILE}"
	cat "${TMPWORK}/parameters.new" > "${ADD_FILE}" \
		|| Die "cannot write ${ADD_FILE} (restore it from ${ADD_FILE}.bak)"

	echo "   ${ADD_NAME} was missing in ${ADD_FILE}: added with the value ${ADD_VALUE}"
}

# ----------------------------------------------------------------------------
# Update a parameter in an AMSTer parameters file. The parameter is designated
# by a regex matching its whole name, so that a single call can update all the
# names and spellings under which the same information is stored: the
# resolution ratio of the satellite background map for instance appears as
# RateResoSatView, RateResoSattelite or RateResoSatellite depending on the
# region, and all of them must follow the factor used to build the map.
# If no line matches, the parameter is added.
#   $1 = file, $2 = regex of the parameter name, $3 = new value,
#   $4 = name to write if the parameter is missing, $5 = its description,
#   $6 = regex of the family the new line must be grouped with
# ----------------------------------------------------------------------------
UpdateParameter()
{
	PRM_FILE="$1" ; PRM_KEY="$2" ; PRM_VALUE="$3"
	PRM_NAME="$4" ; PRM_DESC="$5" ; PRM_FAMILY="$6"

	if [ ! -f "${PRM_FILE}" ] ; then
		echo "   Warning: ${PRM_FILE} not found, ${PRM_NAME} not updated"
		return
	fi

	# one backup per run only: this function is called several times and the
	# .bak must keep the file as it was before the run, not after the first
	# update
	if [ "${PARAMBACKUPDONE}" = "no" ] ; then
		cp -p "${PRM_FILE}" "${PRM_FILE}.bak" || Die "cannot back up ${PRM_FILE}"
		PARAMBACKUPDONE="yes"
	fi

	# The file is read from a scratch copy and rewritten in place, so that
	# its owner and rights are preserved and successive calls accumulate
	# instead of starting again from the backup.
	cp "${PRM_FILE}" "${TMPWORK}/parameters.in" || Die "cannot read ${PRM_FILE}"

	# The name must end at a character that cannot belong to a parameter
	# name, otherwise a key such as Crop_L would also match Crop_Length.
	# The value is replaced but the separator between the value and the
	# comment is kept, so the alignment of the file is not disturbed.
	${AWK} -v value="${PRM_VALUE}" -v key="${PRM_KEY}" \
			-v nbfile="${TMPWORK}/nbupdated.txt" '
		$0 ~ ("#[ \t]*" key "([^A-Za-z0-9_]|$)") {
			separator = $0
			sub(/#.*/, "", separator)               # value + separator
			sub(/^[^ \t]*/, "", separator)          # separator alone
			if (separator == "") { separator = "\t\t" }
			comment = $0
			sub(/^[^#]*/, "", comment)              # comment alone
			$0 = value separator comment
			nb++
		}
		{ print }
		END { print nb + 0 > nbfile }
	' "${TMPWORK}/parameters.in" > "${PRM_FILE}" \
		|| Die "cannot update ${PRM_FILE} (restore it from ${PRM_FILE}.bak)"

	NBUPDATED=$(cat "${TMPWORK}/nbupdated.txt")
	if [ "${NBUPDATED}" -eq 0 ] ; then
		AddParameter "${PRM_FILE}" "${PRM_NAME}" "${PRM_VALUE}" "${PRM_DESC}" \
			"${PRM_FAMILY}"
	elif [ "${NBUPDATED}" -eq 1 ] ; then
		echo "   ${PRM_NAME} set to ${PRM_VALUE} in ${PRM_FILE}"
	else
		echo "   ${NBUPDATED} lines named like ${PRM_NAME} set to ${PRM_VALUE} in ${PRM_FILE}"
	fi
}

# ----------------------------------------------------------------------------
# Update the parameters that do not depend on the view: the crop, which is set
# to the full size of the template, and the name of the web page.
# ----------------------------------------------------------------------------
UpdateCommonParameters()
{
	# NX and NY, the size of the template, come from EnviGridInfo.py. The
	# factor is irrelevant here, hence 1.
	GRID=$("${PYTHON}" "${GRIDINFO}" "${TEMPLATE}" 1 20 \
			"${TMPWORK}/template.prj") || exit 1
	eval "${GRID}"

	echo ""
	echo "--- parameters file --------------------------------------------"

	# Crop_L/Crop_H are the size of the images the web page displays, and
	# Crop_X/Crop_Y the top left corner of that crop: the whole template
	# means the full size at the origin.
	UpdateParameter "${PARAMFILE}" "Crop_L" "${NX}" "Crop_L" \
		"(Horizontal size of the cropped zone)" "Crop_"
	UpdateParameter "${PARAMFILE}" "Crop_H" "${NY}" "Crop_H" \
		"(Vertical size of the cropped zone)" "Crop_"
	UpdateParameter "${PARAMFILE}" "Crop_X" "0" "Crop_X" \
		"(Top left X coordinate of the cropped zone)" "Crop_"
	UpdateParameter "${PARAMFILE}" "Crop_Y" "0" "Crop_Y" \
		"(Top left Y coordinate of the cropped zone)" "Crop_"

	if [ "${REGIONNAME}" != "" ] ; then
		UpdateParameter "${PARAMFILE}" "WebPage" "${REGIONNAME}" "WebPage" \
			"(Name of the web page)" "WebPage"
	fi
}

# ----------------------------------------------------------------------------
# Build one background map
#   $1 = view (sat or terrain)
# ----------------------------------------------------------------------------
BuildMap()
{
	SetView "$1"

	if [ "${FORCEDZOOM}" != "" ] ; then
		MAXZOOM="${FORCEDZOOM}"
	else
		MAXZOOM="${VIEWMAXZOOM}"
	fi

	# Grid of the template and zoom level to request. NX, NY, OUTNX, OUTNY,
	# ULX, ULY, LRX, LRY, ZOOM, TARGETRES, NTILES come from EnviGridInfo.py
	GRID=$("${PYTHON}" "${GRIDINFO}" "${TEMPLATE}" "${FACTOR}" "${MAXZOOM}" \
			"${TMPWORK}/template.prj") || exit 1
	eval "${GRID}"

	if [ "${FORCEDZOOM}" != "" ] ; then ZOOM="${FORCEDZOOM}" ; fi

	TIFF="${DOCDIR}/${VIEWNAME}.${EXT}"
	JPG="${DOCDIR}/${VIEWNAME}.jpg"

	echo ""
	echo "--- ${VIEWNAME} ------------------------------------------------"
	echo "   template     : ${NX} x ${NY} px, pixel ${PIXX} x ${PIXY}"
	echo "   output grid  : ${OUTNX} x ${OUTNY} px (factor ${FACTOR}),"
	echo "                  about ${TARGETRES} m/px at latitude ${CENTERLAT}"
	echo "   tile zoom    : ${ZOOM} (about ${NTILES} tiles to fetch)"
	echo "   raw tiff size: about $((OUTNX / 1024 * OUTNY / 1024 * 3)) MB"
	echo "   output       : ${TIFF}"

	if [ "${DRYRUN}" = "yes" ] ; then
		echo "   dry run, nothing done"
		return
	fi

	WriteTileDescriptor "${TMPWORK}/${VIEWNAME}_tiles.xml" "${VIEWURL}" "${ZOOM}"

	# -te/-ts rather than -tr: the output grid is then exactly the template
	# footprint sampled FACTOR times finer, with no rounding of the size.
	# No compression and no tiling: keep the tiff readable by Fiji/ImageJ.
	#
	# Tile servers drop connections when they are asked for tens of thousands
	# of tiles, and a single lost tile aborts gdalwarp. Every tile that did
	# arrive is however kept in the wms cache, so simply running gdalwarp
	# again resumes the download instead of restarting it: only the missing
	# tiles go back to the network. Hence the loop below.
	ATTEMPT=1
	PAUSE=30
	while : ; do
		echo "   fetching and resampling tiles, attempt ${ATTEMPT} of ${ATTEMPTS}..."
		if gdalwarp \
			-overwrite \
			--config GDAL_CACHEMAX 512 \
			--config GDAL_HTTP_CONNECTTIMEOUT 30 \
			--config GDAL_HTTP_TIMEOUT 120 \
			--config GDAL_HTTP_MAX_RETRY 10 \
			--config GDAL_HTTP_RETRY_DELAY 5 \
			-t_srs "${TMPWORK}/template.prj" \
			-te "${ULX}" "${LRY}" "${LRX}" "${ULY}" \
			-ts "${OUTNX}" "${OUTNY}" \
			-r "${RESAMPLE}" \
			-multi -wo NUM_THREADS=ALL_CPUS \
			-of GTiff -co COMPRESS=NONE -co INTERLEAVE=PIXEL \
			"${TMPWORK}/${VIEWNAME}_tiles.xml" "${TMPWORK}/${VIEWNAME}.tif" ; then
			break
		fi

		CACHESIZE=$(du -sh "${CACHEDIR}" 2>/dev/null | cut -f1)
		echo "   attempt ${ATTEMPT} interrupted. Tiles fetched so far are kept in"
		echo "   ${CACHEDIR} (${CACHESIZE:-unknown size}) and will not be downloaded again."

		if [ "${ATTEMPT}" -ge "${ATTEMPTS}" ] ; then
			Die "the ${VIEWNAME} map is still incomplete after ${ATTEMPTS} attempts.
    The cache is kept, so relaunch the same command to carry on. If the
    server keeps timing out, it is throttling you: retry with -c 1, or
    take the imagery from another server with -u (see the header of
    this script)."
		fi

		echo "   waiting ${PAUSE} s before the next attempt..."
		sleep "${PAUSE}"
		ATTEMPT=$((ATTEMPT + 1))
		PAUSE=$((PAUSE * 2))
		if [ "${PAUSE}" -gt 300 ] ; then PAUSE=300 ; fi
	done

	mv -f "${TMPWORK}/${VIEWNAME}.tif" "${TIFF}" || Die "cannot write ${TIFF}"
	echo "   ${TIFF} done"

	# jpg twin, used for the insets of the LOS time series plots
	if [ "${OUTNX}" -gt 65500 ] || [ "${OUTNY}" -gt 65500 ] ; then
		echo "   Warning: ${OUTNX} x ${OUTNY} exceeds the jpeg limit of 65500 px,"
		echo "            ${JPG} not created. Use a smaller factor if you need it."
	else
		gdal_translate -q -of JPEG -co QUALITY=90 -b 1 -b 2 -b 3 \
			"${TIFF}" "${JPG}" || Die "cannot create ${JPG}"
		rm -f "${JPG}.aux.xml"
		echo "   ${JPG} done"
	fi

	if [ "${PARAMFILE}" != "" ] ; then
		UpdateParameter "${PARAMFILE}" "${PARAMKEY}" "${FACTOR}" \
			"${PARAMNAME}" "${PARAMDESC}" "RateReso"
	fi
}

# ----------------------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------------------
while getopts "e:d:v:f:z:u:r:x:p:w:c:a:C:nh" OPTION ; do
	case "${OPTION}" in
		e) TEMPLATE="${OPTARG}" ;;
		d) DOCDIR="${OPTARG}" ;;
		v) VIEW="${OPTARG}" ;;
		f) FACTOR="${OPTARG}" ;;
		z) FORCEDZOOM="${OPTARG}" ;;
		u) USERURL="${OPTARG}" ;;
		r) RESAMPLE="${OPTARG}" ;;
		x) EXT="${OPTARG}" ;;
		p) PARAMFILE="${OPTARG}" ;;
		w) REGIONNAME="${OPTARG}" ;;
		c) CONNECTIONS="${OPTARG}" ;;
		a) ATTEMPTS="${OPTARG}" ;;
		C) CACHEDIR="${OPTARG}" ;;
		n) DRYRUN="yes" ;;
		h) Usage 0 ;;
		*) Usage 1 ;;
	esac
done

[ "${TEMPLATE}" = "" ] && Usage 1

# a .hdr was probably given instead of the ENVI binary file
case "${TEMPLATE}" in
	*.hdr) TEMPLATE="${TEMPLATE%.hdr}" ;;
esac
[ -f "${TEMPLATE}" ] || Die "template ${TEMPLATE} does not exist"
[ -d "${DOCDIR}" ] || Die "output directory ${DOCDIR} does not exist"
[ -w "${DOCDIR}" ] || Die "output directory ${DOCDIR} is not writable"

case "${FACTOR}" in
	""|*[!0-9]*) Die "the factor (-f) must be a positive integer" ;;
esac
[ "${FACTOR}" -ge 1 ] || Die "the factor (-f) must be 1 or more"

case "${EXT}" in
	tif|tiff) ;;
	*) Die "the extension (-x) must be tif or tiff" ;;
esac

if [ "${REGIONNAME}" != "" ] && [ "${PARAMFILE}" = "" ] ; then
	Die "the region name (-w) can only be written in a parameters file (-p)"
fi

case "${CONNECTIONS}" in
	""|*[!0-9]*) Die "the number of connections (-c) must be a positive integer" ;;
esac
[ "${CONNECTIONS}" -ge 1 ] || Die "the number of connections (-c) must be 1 or more"

case "${ATTEMPTS}" in
	""|*[!0-9]*) Die "the number of attempts (-a) must be a positive integer" ;;
esac
[ "${ATTEMPTS}" -ge 1 ] || Die "the number of attempts (-a) must be 1 or more"

mkdir -p "${CACHEDIR}" || Die "cannot create the tile cache ${CACHEDIR}"

CheckTool gdalinfo
CheckTool gdalwarp
CheckTool gdal_translate
[ -x "${PYTHON}" ] || Die "the AMSTer python is not at ${PYTHON}"
[ -f "${GRIDINFO}" ] || Die "EnviGridInfo.py is missing next to ${PRG}"

gdalinfo --formats | grep -q "WMS" || Die "your gdal has no WMS driver: tiles cannot be read"

TMPWORK=$(mktemp -d "${TMPDIR:-/tmp}/CreateBackgroundMaps.XXXXXX") \
	|| Die "cannot create a temporary directory"
trap 'rm -rf "${TMPWORK}"' 0 1 2 3 15

# ----------------------------------------------------------------------------
# Run
# ----------------------------------------------------------------------------
echo ""
echo "${PRG}: background maps from ${TEMPLATE}"

case "${VIEW}" in
	sat)     BuildMap sat ;;
	terrain) BuildMap terrain ;;
	both)    BuildMap sat ; BuildMap terrain ;;
	*)       Die "unknown view ${VIEW} (expected sat, terrain or both)" ;;
esac

if [ "${PARAMFILE}" != "" ] && [ "${DRYRUN}" = "no" ] ; then
	UpdateCommonParameters
fi

echo ""
echo "${PRG}: done. Move on with the web page if the maps look right,"
echo "        and set BuildMapsView / BuildSatView to Yes in the parameters"
echo "        file for the next run of Main.sh so that ZoneMaker_2.0.sh"
echo "        rebuilds the sub-area views."
echo ""
