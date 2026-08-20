#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at checking all files to be ingested by msbas (macOS + Linux):
#
# Reports, for every raster used by an msbas run (located thanks to header.txt), 
# whether it declares NoData = nan and how many IEEE NaN pixels it actually contains.
#
# With optional parameter -f (fix), each offending file is fixed IN PLACE: 
# NaN/Inf pixels are replaced with 0 and NoData is set to 0, which is what msbas uses 
# internally. No new file is created and header.txt/set list files never need to be repointed.
#
# A backup of the original is kept alongside it as "<file>.bak" (made once; a pre-existing .bak
# is never overwritten, so rerunning -f repeatedly still only ever backs up the true original).
#
# Usage:
#   ./Check_msbas_inputs_for_nan.sh header.txt          # report only
#   ./Check_msbas_inputs_for_nan.sh -f header.txt       # report and fix in place (keeps .bak)
#
# Compatible with macOS and Linux (POSIX-safe, no bash 4 features).
#
# Must be launched in msbas dir containing the subdirs with data to invert.  
# 
# Parameters are : 
# 		- the header.txt file 
#       - optional "-f" (to be placed before the header.txt) to not only test agains Nan but also removing them
#
# Dependencies:	- 
#
# New in Distro V 1.1 :	- 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 30, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

FIX="NO"
if [ "$1" == "-f" ] ; then FIX="YES" ; shift ; fi

HEADER="$1"
if [ "${HEADER}" == "" ] || [ ! -f "${HEADER}" ] ; then
	echo "Usage: $(basename "$0") [-f] header.txt"
	exit 1
fi

# Prefer the AMSTer Python venv (AMSTer_install.sh installs the GDAL/osgeo bindings there
# specifically, matched to the system's GDAL) rather than relying on the calling shell having
# activated it - a plain "python3" on PATH is very unlikely to have osgeo available at all.
# Falls back to whatever python3 is on PATH if the venv isn't found (e.g. running outside a
# full AMSTer install).
AMSTER_VENV_PY="/opt/local/amster_python_env/bin/python3"
if [ -x "${AMSTER_VENV_PY}" ] ; then
	PYTHON3="${AMSTER_VENV_PY}"
else
	PYTHON3="python3"
fi

command -v gdalinfo > /dev/null 2>&1 || { echo "ERROR: gdalinfo not found in PATH." ; exit 1 ; }
command -v "${PYTHON3}" > /dev/null 2>&1 || { echo "ERROR: ${PYTHON3} not found." ; exit 1 ; }
"${PYTHON3}" -c "from osgeo import gdal" 2>/dev/null || { echo "ERROR: the GDAL bindings (osgeo) are not available for ${PYTHON3}." ; exit 1 ; }

HDRDIR=$(dirname "${HEADER}")

# ---- collect every raster referenced by the run -------------------------------------------------
# DD_NSEW_FILES = north,east  and  SET = type,time,azimuth,incidence,listfile
# The list files hold one raster per line, path in the first column.
RASTERS=""

DDLINE=$(grep -v "^[[:space:]]*#" "${HEADER}" | grep "DD_NSEW_FILES" | head -1 | cut -d= -f2)
if [ "${DDLINE}" != "" ] ; then
	for F in $(echo "${DDLINE}" | tr ',' ' ') ; do
		RASTERS="${RASTERS} ${HDRDIR}/$(echo "${F}" | tr -d '[:space:]')"
	done
fi

for LST in $(grep -v "^[[:space:]]*#" "${HEADER}" | grep "^[[:space:]]*SET" | awk -F, '{gsub(/[[:space:]]/,"",$5); print $5}') ; do
	if [ -f "${HDRDIR}/${LST}" ] ; then
		for F in $(awk 'NF && $1 !~ /^#/ {print $1}' "${HDRDIR}/${LST}") ; do
			RASTERS="${RASTERS} ${HDRDIR}/${F}"
		done
	else
		echo "WARNING: set list file ${HDRDIR}/${LST} not found; skipped. "
	fi
done

if [ "${RASTERS}" == "" ] ; then echo "No raster found from ${HEADER}." ; exit 1 ; fi

# ---- inspect (and optionally fix) ---------------------------------------------------------------
printf "%-52s %-12s %-14s %s\n" "FILE" "NoData" "NaN pixels" "STATUS"
NBAD=0

for R in ${RASTERS} ; do
	if [ ! -f "${R}" ] ; then
		printf "%-52s %-12s %-14s %s\n" "$(basename "${R}")" "-" "-" "MISSING"
		continue
	fi

	OUT=$(FIXFLAG="${FIX}" "${PYTHON3}" - "${R}" <<'PYEOF'
import os, sys, shutil
import numpy as np
from osgeo import gdal
gdal.UseExceptions()

path = sys.argv[1]
ds = gdal.Open(path)
band = ds.GetRasterBand(1)
nd = band.GetNoDataValue()
arr = band.ReadAsArray().astype(np.float32)
nan = int(np.isnan(arr).sum())
ndstr = "none" if nd is None else ("nan" if nd != nd else "%g" % nd)

status = "ok"
if nan > 0:
    status = "NEEDS FIX"
    if os.environ.get("FIXFLAG") == "YES":
        drv = ds.GetDriver()
        geotransform = ds.GetGeoTransform()
        projection = ds.GetProjection()
        xsize, ysize = ds.RasterXSize, ds.RasterYSize
        arr = np.nan_to_num(arr, nan=0.0, posinf=0.0, neginf=0.0)

        # Keep a backup of the true original the first time this file is fixed.
        # Never overwritten afterwards, so rerunning -f repeatedly (e.g. after tweaking
        # something else) can't clobber it with an already-fixed version.
        bak = path + ".bak"
        if not os.path.exists(bak):
            shutil.copy2(path, bak)

        # Write to a temp file in the same directory, then atomically replace the
        # original - safer than writing into an already-open dataset in place, and
        # this way the original is never left partially written if something goes
        # wrong midway. The original dataset/band must be closed first so the
        # replace isn't fighting an open file handle.
        tmp = path + ".nanfix_tmp_%d" % os.getpid()
        dst = drv.Create(tmp, xsize, ysize, 1, gdal.GDT_Float32)
        dst.SetGeoTransform(geotransform)
        dst.SetProjection(projection)
        ob = dst.GetRasterBand(1)
        ob.WriteArray(arr)
        ob.SetNoDataValue(0.0)
        ob.FlushCache()
        dst = None
        ob = None
        band = None
        ds = None
        os.replace(tmp, path)
        status = "fixed in place (backup: " + os.path.basename(bak) + ")"

print("%s\t%d\t%s" % (ndstr, nan, status))
PYEOF
	)

	ND=$(echo "${OUT}" | cut -f1)
	NN=$(echo "${OUT}" | cut -f2)
	ST=$(echo "${OUT}" | cut -f3)
	printf "%-52s %-12s %-14s %s\n" "$(basename "${R}")" "${ND}" "${NN}" "${ST}"
	if [ "${NN}" != "0" ] ; then NBAD=$((NBAD + 1)) ; fi
done

echo ""
if [ ${NBAD} -eq 0 ] ; then
	echo "  // No NaN found: the DLASCL error does not come from NaN in these rasters. "
else
	echo "  // ${NBAD} file(s) contain NaN pixels, which is what makes LAPACK reject those pixels. "
	if [ "${FIX}" == "NO" ] ; then
		echo "  // Rerun with -f to fix them in place (NaN/Inf -> 0, NoData set to 0). "
		echo "  // A backup of each original is kept alongside it as <file>.bak. "
	else
		echo "  // Fixed in place: NaN/Inf pixels set to 0 and NoData set to 0. Originals were "
		echo "  // backed up as <file>.bak. Rerun msbas directly - no need to edit ${HEADER} "
		echo "  // or the set list files. "
	fi
fi