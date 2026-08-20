#!/opt/local/amster_python_env/bin/python
# -----------------------------------------------------------------------------
# Diff_Envi_DivCos.py aims at preparing files to be ingested by AMSTer for 
# GACOS atmospheric correction. 
#
# It computes  (FILE1 - FILE2) / cos(ANGLE), pixel per pixel,  and store the 
#   result as an ENVI file (binary + .hdr).
#
# Usage:   Diff_Envi_DivCos.py FILE1 FILE2 ANGLE [OUTPUT] [-RAD]
#                [-REF=NONE|MEAN|MEDIAN] [-REFMASK=file]
#                [-MINVALID=percent] [-MINPIX=n]
#
# Parameters: 	
#   FILE1, FILE2 : ENVI binary files, or their .hdr (a matching header must
#                  exist beside each file, either FILE.hdr or FILE_noext.hdr)
#   ANGLE        : either 
#					- a CONSTANT angle in DEGREES (OK for small maps), or
#					- an ENVI file containing a per pixel angle map 
#                     (same grid as FILE1 and FILE2). 
#			BEWARE: Use the INCIDENCE angle at the ground (with respect 
#				    to geoid, not local slope !!), not the look 
#              	    angle at the satellite.  				   
#   -RAD         : the angle map is in radians instead of degrees
#   -REF=        : remove a constant from the RESULT so that its MEAN or its
#                  MEDIAN over the reference zone becomes zero. 
#					REF=NONE (Default) only PRINTS the offset that would be
#							  removed and warns the user. 
#					REF=MEAN or MEDIAN: if provided with REFMASK, statistics 
#					   is computed on that small zone. If not, stat is computed 
#					   on whole image). It MUST be identical for all pairs !! 
#					   -REF=MEDIAN -REFMASK=stable.msk — best, if you have a 
#							zone that is stable across the whole time span.
#					   -REF=MEDIAN alone — good fallback, no mask needed, 
#							resists localized deformation.
#					   -REF=MEAN -REFMASK=... — fine, slightly more sensitive 
#							to unwrapping outliers inside the zone.
#					   -REF=MEAN alone — weakest, though still far better 
#							than not referencing.
#                  A model delay is absolute while an unwrapped displacement
#                  map is relative, so this constant is arbitrary: it must be
#                  removed, and removed the SAME way for every pair.
#   -REFMASK=    : ENVI mask (same grid) defining the REFERENCE zone; pixels
#                  finite and non zero are used (e.g. stable ground built with
#                  Mask_Builder.py). Without it the zone is every pixel where
#                  the result is finite.
#   -MINVALID=   : minimum percentage of the DECLARED zone that must be valid,
#                  default 50. The declared zone is the mask when -REFMASK is
#                  given, the whole image otherwise, so the same threshold
#                  suits both cases. This is the test that keeps the reference
#                  REPRESENTATIVE, hence consistent from one pair to the next:
#                  a pair where most of the zone decorrelated would otherwise
#                  be referenced on a different sub-population than the others.
#				   Values can be input as 50 or 50%
#   -MINPIX=     : minimum ABSOLUTE number of valid pixels, default 100. This
#                  is a different guard: a 30 pixel mask fully valid passes any
#                  percentage but its mean/median is just noise, since the
#                  precision of the offset depends on the number of INDEPENDENT
#                  samples (i.e. on the zone size versus the atmospheric
#                  correlation length), not on a fraction.
#
# Only the correction map is re-referenced: the displacement map it will be
# subtracted from keeps its own reference, so the result stays comparable with
# the maps corrected from the other models (MANGO...).
#
#   OUTPUT       : optional output binary name; the header is OUTPUT.hdr.
#                  Default is built from the dates of the two input files:
#                  DATE2_DATE1_GACOSIncidRef_DATE1_minus_DATE2_div_by_cos_ANGLE.r4
#                  (ANGLE being the value given, or the angle map name)
#                  where DATEn is the first YYYYMMDD found in FILEn name, and the
#                  GACOSIncidRef tag states HOW the map was built, so that maps
#                  made with different options never overwrite each other:
#                    INCID = IncidMap if ANGLE is a per pixel map of angles
#                            IncidVal if ANGLE is a constant angle
#                    REF   = MEAN or MEDIAN as given by -REF=
#                            NoRef if -REF is not given, or -REF=NONE
#                  Any case not described above falls back to the bare GACOS tag.
#
# Geometry, data type, byte order and header offset are read from the .hdr
# files, so any ENVI data type / number of bands / interleave is supported.
#
# All the inputs (FILE1, FILE2, the angle map, the reference mask) are brought to
# a common geometry BEFORE the computation: geographic Lat/Long on the WGS 84
# datum, in DEGREES, on the grid of FILE1, i.e. the AMSTer DEM convention. So the
# output is ALWAYS Lat/Long WGS 84 in degrees, as AMSTer expects further down the
# chain, whatever the tool that wrote the inputs (AMSTer, gdal, GACOS...).
#
#   - a file already Lat/Long WGS 84 in degrees and on the grid of FILE1 is used
#     as it is: the usual AMSTer case costs nothing and does not even need gdal
#   - a file in UTM or in any other projection, on another datum, in metres, or on
#     another Lat/Long grid, is transformed with gdalwarp into a copy written in a
#     scratch directory (removed on exit, kept with -KEEPTMP). THE INPUTS ARE
#     NEVER MODIFIED. What was done is printed and written in the output header.
#   - FILE1 defines the grid. If FILE1 itself is not Lat/Long it is reprojected
#     first, with the grid gdalwarp finds best, and the others follow.
#   - a file with NO map info can not be helped: not being georeferenced, no tool
#     can place it on the ground. It is refused, with the way to geocode it.
#
#   -RESAMPLE=   : gdalwarp resampling of the DATA when a transformation is
#                  needed: bilinear (default), near, cubic, cubicspline, lanczos,
#                  average, mode. A reference MASK is always resampled with near,
#                  as it holds classes and must not be interpolated. Complex data
#                  are refused rather than interpolated across fringes.
#   -KEEPTMP     : keep the scratch directory and print its path, to check what
#                  gdalwarp produced.
#
# Output data type is float32 (float64 / complex are preserved), NaN are
# propagated, and the ignore value / band names / interleave of FILE1 are kept.
#
# Mac OS X and Linux compatible.
#
# Dependencies:	- python3.10 and modules below (numpy, see import)
#				- gdal (gdalwarp, gdalinfo), ONLY when an input has to be
#				  transformed. Not needed for inputs already in Lat/Long WGS 84.
#
# New in Distro V 1.0:	- built with an AI assistance 
# New in Distro V 1.1:	- output header always geographic Lat/Long WGS 84 in
#						  degrees (AMSTer DEM convention), and geocoding of all
#						  the inputs read and checked instead of copied blindly
# New in Distro V 1.2:	- inputs not in Lat/Long WGS 84 degrees, or not on the
#						  grid of FILE1, are transformed with gdalwarp instead of
#						  being refused; -RESAMPLE= and -KEEPTMP added
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2016-2026
######################################################################################
import os
import re
import sys
import json
import math
import shutil
import atexit
import signal
import tempfile
import subprocess

# stay silent when the output is piped into head, grep... (no BrokenPipeError)
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

try:
	import numpy as np
except ImportError:
	sys.exit("ERROR: numpy is required (port install py-numpy / pip3 install numpy)")

PRG = os.path.basename(sys.argv[0])

ENVI2NP = {1: "u1", 2: "i2", 3: "i4", 4: "f4", 5: "f8", 6: "c8",
           9: "c16", 12: "u2", 13: "u4", 14: "i8", 15: "u8"}
NP2ENVI = dict((v, k) for k, v in ENVI2NP.items())

CHUNK = 1 << 22		# elements processed at once (memory friendly on big frames)
TAG = "GACOS"		# base tag inserted in the default output name
# what the tag adds about the options used, hence about how the map was built
TAG_INCID = {True: "IncidVal", False: "IncidMap"}		# keyed on "angle is a constant"
TAG_REF = {"MEAN": "MEAN", "MEDIAN": "MEDIAN", "NONE": "NoRef"}

# the output geocoding: geographic Lat/Long, WGS 84, degrees, as the AMSTer DEM
WGS84_A = 6378137.0			# semi major axis, m
WGS84_B = 6356752.3			# semi minor axis, m, as ENVI writes it
WGS84_IF = 298.257223563	# inverse flattening
# datum spelled differently by ENVI, gdal, GACOS... all mean WGS 84
WGS84_NAMES = ("wgs-84", "wgs84", "wgs 84", "wgs_84", "wgs_1984", "d_wgs_1984",
               "wgs 84 / geographic", "world geodetic system 1984")
CSSTRING = ('GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",'
            'SPHEROID["WGS_1984",%.1f,%.9f]],PRIMEM["Greenwich",0.0],'
            'UNIT["Degree",0.0174532925199433]]' % (WGS84_A, WGS84_IF))
GEOTOL = 0.01		# grids equal within a hundredth of a pixel

GDALWARP = "gdalwarp"
GDALINFO = "gdalinfo"
RESAMPLINGS = ("near", "bilinear", "cubic", "cubicspline", "lanczos", "average", "mode")
SCRATCH = {"dir": None, "keep": False}	# where the reprojected copies are written
GRIDS = {}								# grid of a file as gdal sees it, read once
NOTES = []								# transformations done, told in the output header


def GetDate(path):
	"""Date of a file: first YYYYMMDD found in its name, else name without extension."""
	base = os.path.basename(path)
	found = re.search(r"(?<!\d)(\d{8})(?!\d)", base)
	if found:
		return found.group(1)
	return os.path.splitext(base)[0]


def Tag(constant, refmode):
	"""Tag of the default output name, telling how the map was built:
	   GACOSIncidMapMEDIAN, GACOSIncidValNoRef... CONSTANT says whether the
	   angle was given as a value rather than as a map. Any combination not
	   described in TAG_INCID / TAG_REF falls back to the bare tag, so a new
	   option can never silently produce a misleading name."""
	incid = TAG_INCID.get(constant)
	ref = TAG_REF.get(refmode)
	if incid is None or ref is None:
		return TAG
	return "%s%s%s" % (TAG, incid, ref)


def Usage():
	sys.exit("Usage: %s FILE1 FILE2 ANGLE [OUTPUT] [-RAD]\n"
	         "              [-REF=NONE|MEAN|MEDIAN] [-REFMASK=file]\n"
	         "              [-MINVALID=percent] [-MINPIX=n]\n"
	         "              [-RESAMPLE=bilinear|near|cubic|...] [-KEEPTMP]\n"
	         "       computes (FILE1 - FILE2) / cos(ANGLE) and writes it in ENVI format\n"
	         "       ANGLE = constant in degrees, or ENVI map of angles (-RAD if in radians)\n"
	         "       -REF  = zeroes the mean/median of the result over the reference zone\n"
	         "       inputs not in Lat/Long WGS 84 degrees, or not on the grid of FILE1, are\n"
	         "       transformed with gdalwarp: the output is always Lat/Long WGS 84 degrees"
	         % PRG)


def ResolveImg(arg):
	"""Accept either the ENVI binary or its .hdr, return the binary."""
	if arg.endswith(".hdr"):
		cand = arg[:-4]
		if os.path.isfile(cand):
			return cand
		sys.exit("ERROR: %s exists but the ENVI binary %s is missing" % (arg, cand))
	if os.path.isfile(arg):
		return arg
	sys.exit("ERROR: can not find the ENVI binary file \"%s\"" % arg)


def ResolveHdr(img):
	"""Header of an image: IMG.hdr, else IMG_without_extension.hdr."""
	if os.path.isfile(img + ".hdr"):
		return img + ".hdr"
	noext = os.path.splitext(img)[0]
	if noext != img and os.path.isfile(noext + ".hdr"):
		return noext + ".hdr"
	sys.exit("ERROR: no header found for %s (expected %s.hdr or %s.hdr)"
	         % (img, img, noext))


def ReadHdr(path):
	"""Return (dict of fields, list of logical lines) of an ENVI header."""
	with open(path, "r", errors="replace") as fh:
		raw = fh.read()
	lines, buf = [], ""
	for line in raw.splitlines():
		buf = line if buf == "" else buf + " " + line.strip()
		if buf.count("{") > buf.count("}"):		# multi line value, keep reading
			continue
		lines.append(buf)
		buf = ""
	if buf != "":
		lines.append(buf)
	fields = {}
	for line in lines:
		if "=" in line:
			key, val = line.split("=", 1)
			fields[key.strip().lower()] = val.strip()
	return fields, lines


def GetInt(fields, key, path, default=None):
	if key not in fields:
		if default is None:
			sys.exit("ERROR: \"%s\" is missing in %s" % (key, path))
		return default
	try:
		return int(float(fields[key]))
	except ValueError:
		sys.exit("ERROR: \"%s = %s\" is not numeric in %s" % (key, fields[key], path))


def Braced(value):
	"""Comma separated fields of an ENVI { ... } value."""
	val = value.strip()
	if val.startswith("{"):
		val = val[1:]
	if val.endswith("}"):
		val = val[:-1]
	return [f.strip() for f in val.split(",")]


def Deg(value):
	"""Degrees written plainly (never in exponent notation, no trailing zeros)."""
	txt = ("%.12f" % value).rstrip("0")
	return txt + "0" if txt.endswith(".") else txt


def ReadGeo(fields, path):
	"""Geocoding of an ENVI header, as (geo, why):
	     geo = (lon, lat, dlon, dlat) of the reference pixel (1,1), in degrees on
	           the WGS 84 datum, or None when the file is not in that system,
	     why = None when geo is usable, else the reason in plain words, so that
	           the caller can reproject the file instead of giving up.

	   A file with no map info at all is fatal: it is not georeferenced, so no
	   tool, gdal included, can place it on the ground."""
	if "map info" not in fields:
		sys.exit("ERROR: no \"map info\" in %s: the file is not georeferenced, so it can\n"
		         "       neither be reprojected nor placed on the grid of the other maps.\n"
		         "       -> geocode it first (AMSTer geoProjection, or gdal_translate -a_srs\n"
		         "          -a_ullr if you know its corners)" % path)
	fld = Braced(fields["map info"])
	if len(fld) < 8:
		sys.exit("ERROR: \"map info\" of %s has %d fields instead of at least 8:\n       %s"
		         % (path, len(fld), fields["map info"]))
	if not fld[0].lower().startswith("geographic"):
		return None, "projected in \"%s\"" % fld[0]
	try:
		xref, yref, x0, y0, dlon, dlat = (float(v) for v in fld[1:7])
	except ValueError:
		sys.exit("ERROR: \"map info\" of %s is not numeric:\n       %s"
		         % (path, fields["map info"]))
	if fld[7].lower() not in WGS84_NAMES:
		return None, "on the datum \"%s\"" % fld[7]
	for extra in fld[8:]:			# units=Degrees is optional (gdal omits it)
		if extra.lower().startswith("units") and "degree" not in extra.lower():
			return None, "geocoded in \"%s\"" % extra
	if dlon <= 0.0 or dlat <= 0.0:
		sys.exit("ERROR: the pixel size of %s is %g x %g, it must be positive in \"map info\"\n"
		         "       (ENVI stores sizes, the latitude decreasing downwards is implicit)"
		         % (path, dlon, dlat))
	# the tie point is given for the pixel (xref, yref): express it at (1,1), as
	# gdal does too, so that both agree on where the image starts
	lon = x0 - (xref - 1.0) * dlon
	lat = y0 + (yref - 1.0) * dlat
	# Out of these bounds the header declares degrees but holds something else,
	# most often metres. Reprojecting would not help: gdalwarp would trust the
	# declaration, place the file at an absurd position and return an empty
	# overlap. The header itself is wrong and only the user can say what it is.
	if abs(lon) > 360.0 or abs(lat) > 90.0 or dlon > 1.0 or dlat > 1.0:
		sys.exit("ERROR: %s declares geographic WGS 84 but holds %s / %s with a pixel of\n"
		         "       %s x %s: these are not degrees, its \"map info\" is inconsistent.\n"
		         "       -> fix the header, or state the real system, e.g.\n"
		         "          gdal_translate -a_srs EPSG:32631 -of ENVI IN OUT"
		         % (path, Deg(lon), Deg(lat), Deg(dlon), Deg(dlat)))
	return (lon, lat, dlon, dlat), None


def SameGeo(geo, other):
	"""True if two geocodings describe the same grid, to GEOTOL pixel."""
	tlon, tlat = GEOTOL * geo[2], GEOTOL * geo[3]
	return (abs(other[0] - geo[0]) <= tlon and abs(other[1] - geo[1]) <= tlat and
	        abs(other[2] - geo[2]) <= tlon and abs(other[3] - geo[3]) <= tlat)


def GeoTxt(geo):
	"""Geocoding in one human readable line."""
	return ("Lat/Long WGS 84, upper left pixel at %s deg E / %s deg N, "
	        "pixel %s x %s deg" % (Deg(geo[0]), Deg(geo[1]), Deg(geo[2]), Deg(geo[3])))


def Gdal(prog):
	"""Path of a gdal tool. Only needed when something must be transformed, so a
	   pipeline already in Lat/Long WGS 84 keeps working without gdal at all."""
	path = shutil.which(prog)
	if path is None:
		sys.exit("ERROR: %s is needed to transform the inputs into Lat/Long WGS 84 but is\n"
		         "       not in the PATH (port install gdal, or apt install gdal-bin).\n"
		         "       Inputs already geocoded in Lat/Long WGS 84 on a common grid need\n"
		         "       no gdal at all." % prog)
	return path


def Run(cmd, what):
	"""Run a command, return its output, exit with its own message if it fails."""
	try:
		res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	except OSError as err:
		sys.exit("ERROR: can not run %s (%s)" % (cmd[0], err))
	out = res.stdout.decode("utf-8", "replace")
	if res.returncode != 0:
		sys.exit("ERROR: %s failed (exit %d):\n       %s\n%s"
		         % (what, res.returncode, " ".join(cmd), out))
	return out


def Scratch():
	"""Directory holding the reprojected copies, removed on exit unless -KEEPTMP."""
	if SCRATCH["dir"] is None:
		SCRATCH["dir"] = tempfile.mkdtemp(prefix="%s_TMP_" % os.path.splitext(PRG)[0])
		if SCRATCH["keep"]:
			print("scratch directory kept: %s" % SCRATCH["dir"])
		else:
			atexit.register(shutil.rmtree, SCRATCH["dir"], True)
	return SCRATCH["dir"]


def GdalGrid(path):
	"""(west, south, east, north, samples, lines) of a file as GDAL ITSELF sees it.

	   Read from gdalinfo rather than computed from map info, so that the target
	   grid given to gdalwarp is bit for bit the grid of the reference file and no
	   half pixel shift can creep in through a convention difference."""
	if path not in GRIDS:
		txt = Run([Gdal(GDALINFO), "-json", path], "gdalinfo on %s" % path)
		try:
			nfo = json.loads(txt)
			ul = nfo["cornerCoordinates"]["upperLeft"]
			lr = nfo["cornerCoordinates"]["lowerRight"]
			size = nfo["size"]
		except (ValueError, KeyError, IndexError):
			sys.exit("ERROR: can not read the grid of %s from \"gdalinfo -json\"" % path)
		GRIDS[path] = (ul[0], lr[1], lr[0], ul[1], size[0], size[1])
	return GRIDS[path]


def ToGeographic(fbin, hdr, what, kind, ref, method):
	"""Return (binary, header) of FBIN in geographic Lat/Long WGS 84 degrees and,
	   when REF = ((samples, lines), geo, path) is given, on the grid of REF.

	   Nothing is done, and gdal is not called, when the file already complies:
	   that is the normal AMSTer case. Otherwise gdalwarp writes a copy in the
	   scratch directory and that copy is used from there on. The inputs are
	   never touched."""
	fld, _ = ReadHdr(hdr)
	geo, why = ReadGeo(fld, hdr)
	size = (GetInt(fld, "samples", hdr), GetInt(fld, "lines", hdr))
	if ref is None:				# FILE1 defines the grid, it only has to be Lat/Long
		if why is None:
			return fbin, hdr
		reason = why
	else:
		if why is None and size == ref[0] and SameGeo(ref[1], geo):
			return fbin, hdr
		reason = why if why is not None else \
		         "on another grid (%d x %d, %s)" % (size[0], size[1], GeoTxt(geo))

	dt = np.dtype(ENVI2NP[GetInt(fld, "data type", hdr)])
	if dt.kind == "c":
		sys.exit("ERROR: %s is complex and would have to be resampled, which is not valid\n"
		         "       for complex or wrapped data (interpolating a phase across a fringe\n"
		         "       is meaningless). Unwrap and geocode it on the grid of FILE1 first."
		         % what)
	if kind == "mask":
		# a mask holds classes, not a signal: never interpolate it, and fill the
		# outside with 0, which this script already reads as "not in the zone"
		res, out_type, nodata = "near", None, "0"
	else:
		# NaN outside the source footprint, which this script already reads as void
		res, out_type, nodata = method, "Float64" if dt.itemsize == 8 else "Float32", "nan"

	dst = os.path.join(Scratch(), "LatLong_%s" % os.path.basename(fbin))
	cmd = [Gdal(GDALWARP), "-q", "-overwrite", "-t_srs", "EPSG:4326", "-of", "ENVI", "-r", res]
	if out_type is not None:
		cmd += ["-ot", out_type]
	cmd += ["-dstnodata", nodata]
	if ref is not None:
		grid = GdalGrid(ref[2])
		cmd += ["-te"] + ["%.12f" % v for v in grid[:4]]
		cmd += ["-ts", "%d" % grid[4], "%d" % grid[5]]
	cmd += [fbin, dst]
	print("%s is %s -> transformed in Lat/Long WGS 84 (gdalwarp -r %s)" % (what, reason, res))
	Run(cmd, "gdalwarp on %s" % fbin)

	NOTES.append("%s transformed in Lat/Long WGS 84 (gdalwarp -r %s)"
	             % (os.path.basename(fbin), res))
	# gdal names the header DST without its extension + .hdr, ResolveHdr knows it
	dst = ResolveImg(dst)
	hdst = ResolveHdr(dst)
	newfld, _ = ReadHdr(hdst)
	newgeo, newwhy = ReadGeo(newfld, hdst)
	if newwhy is not None:
		sys.exit("ERROR: gdalwarp did not return a Lat/Long WGS 84 file for %s: the result is\n"
		         "       %s" % (fbin, newwhy))
	if ref is not None and not SameGeo(ref[1], newgeo):
		sys.exit("ERROR: %s could not be put on the grid of FILE1:\n"
		         "         wanted: %s\n         got   : %s" % (what, GeoTxt(ref[1]), GeoTxt(newgeo)))
	return dst, hdst


def OpenEnvi(fbin, hdr, samples, lines, bands, what, geo=None):
	"""Check the grid of an ENVI file against samples/lines/bands, return a memmap."""
	fld, _ = ReadHdr(hdr)
	geom = tuple(GetInt(fld, k, hdr, 1 if k == "bands" else None)
	             for k in ("samples", "lines", "bands"))
	if geom != (samples, lines, bands):
		sys.exit("ERROR: the %s %s is %s while the data are %s (samples, lines, bands)\n"
		         "       -> resample it on the grid of the data first (Resample_ToGrid.sh)"
		         % (what, fbin, geom, (samples, lines, bands)))
	if geo is not None:
		# same number of pixels is not enough: they must cover the same ground.
		# After ToGeographic this can only fail on a bug, it is a safety net.
		other, why = ReadGeo(fld, hdr)
		if why is not None or not SameGeo(geo, other):
			sys.exit("ERROR: the %s %s is still not on the grid of the data:\n"
			         "         data: %s\n         %s: %s"
			         % (what, fbin, GeoTxt(geo), what,
			            why if why is not None else GeoTxt(other)))
	dtc = GetInt(fld, "data type", hdr)
	if dtc not in ENVI2NP:
		sys.exit("ERROR: unsupported ENVI data type %d in %s" % (dtc, hdr))
	order = ">" if GetInt(fld, "byte order", hdr, 0) == 1 else "<"
	dt = np.dtype(ENVI2NP[dtc]).newbyteorder(order)
	off = GetInt(fld, "header offset", hdr, 0)
	nelem = samples * lines * bands
	if os.path.getsize(fbin) < off + nelem * dt.itemsize:
		sys.exit("ERROR: %s is too small for what %s announces" % (fbin, hdr))
	return np.memmap(fbin, dtype=dt, mode="r", offset=off, shape=(nelem,))


def MaxAbs(mm):
	"""Max of |values| of a memmap, chunk by chunk, ignoring non finite values."""
	vmax = 0.0
	for i in range(0, mm.size, CHUNK):
		blk = np.abs(mm[i:i + CHUNK].astype("f8"))
		blk = blk[np.isfinite(blk)]
		if blk.size:
			vmax = max(vmax, float(blk.max()))
	return vmax


def main(argv):
	argv = list(argv)
	radians = False
	refmode = "NONE"
	refmask = None
	minvalid = 50.0
	minpix = 100
	method = "bilinear"
	keep = []
	for arg in argv:
		if arg == "-RAD":
			radians = True
		elif arg == "-KEEPTMP":
			SCRATCH["keep"] = True
		elif arg.startswith("-RESAMPLE="):
			method = arg[len("-RESAMPLE="):].lower()
			if method not in RESAMPLINGS:
				sys.exit("ERROR: -RESAMPLE must be one of %s, got \"%s\""
				         % (", ".join(RESAMPLINGS), method))
		elif arg.startswith("-REF="):
			refmode = arg[len("-REF="):].upper()
			if refmode not in ("NONE", "MEAN", "MEDIAN"):
				sys.exit("ERROR: -REF must be NONE, MEAN or MEDIAN, got \"%s\"" % refmode)
		elif arg.startswith("-REFMASK="):
			refmask = arg[len("-REFMASK="):]
		elif arg.startswith("-MINVALID="):
			try:
				minvalid = float(arg[len("-MINVALID="):].rstrip("%"))
			except ValueError:
				sys.exit("ERROR: -MINVALID must be a percentage")
			if not 0.0 <= minvalid <= 100.0:
				sys.exit("ERROR: -MINVALID must be between 0 and 100")
		elif arg.startswith("-MINPIX="):
			try:
				minpix = int(arg[len("-MINPIX="):])
			except ValueError:
				sys.exit("ERROR: -MINPIX must be an integer")
		elif arg.startswith("-"):
			sys.exit("ERROR: unknown option \"%s\"" % arg)
		else:
			keep.append(arg)
	argv = keep
	if not 4 <= len(argv) <= 5:
		Usage()

	f1 = ResolveImg(argv[1])
	f2 = ResolveImg(argv[2])
	h1 = ResolveHdr(f1)
	h2 = ResolveHdr(f2)

	# third parameter: a constant angle in degrees, or an ENVI map of angles
	angle, fang, hang, cosa = None, None, None, None
	try:
		angle = float(argv[3])
	except ValueError:
		fang = ResolveImg(argv[3])		# exits with a clear message if absent
		hang = ResolveHdr(fang)

	if angle is not None:
		if radians:
			sys.exit("ERROR: -RAD applies to an angle map, a constant angle is in degrees")
		cosa = math.cos(math.radians(angle))
		if abs(cosa) < 1e-9:
			sys.exit("ERROR: cos(%g deg) is null - division impossible" % angle)

	if len(argv) == 5:
		out = argv[4]
	else:
		# <DATE2>_<DATE1>_TAG_<DATE1>_minus_<DATE2>_div_by_cos_<ANGLE>.r4
		# the leading pair follows the AMSTer MAS_SLV naming, the rest states
		# explicitly which file was subtracted from which, and the tag which
		# options built it (angle as a map or as a value, referencing used)
		d1 = GetDate(f1)
		d2 = GetDate(f2)
		tag = argv[3] if angle is not None else os.path.splitext(os.path.basename(fang))[0]
		out = "%s_%s_%s_%s_minus_%s_div_by_cos_%s.r4" \
		      % (d2, d1, Tag(angle is not None, refmode), d1, d2, tag)

	for forbidden in (f1, f2, h1, h2):
		if os.path.realpath(out) == os.path.realpath(forbidden) or \
		   os.path.realpath(out + ".hdr") == os.path.realpath(forbidden):
			sys.exit("ERROR: output %s would overwrite an input file" % out)

	# ---- every input in Lat/Long WGS 84 degrees, on the grid of FILE1 --------
	# The names of the ORIGINAL files are kept for the messages and for the output
	# description: from here on f1, f2... may be reprojected copies in the scratch
	# directory, whose names would tell the user nothing.
	n1, n2 = os.path.basename(f1), os.path.basename(f2)
	nang = os.path.basename(fang) if fang is not None else None
	nmsk, fmsk, hmsk = None, None, None

	f1, h1 = ToGeographic(f1, h1, "FILE1 (%s)" % n1, "data", None, method)
	fld1, lin1 = ReadHdr(h1)
	refgrid = ((GetInt(fld1, "samples", h1), GetInt(fld1, "lines", h1)),
	           ReadGeo(fld1, h1)[0], f1)
	f2, h2 = ToGeographic(f2, h2, "FILE2 (%s)" % n2, "data", refgrid, method)
	if fang is not None:
		fang, hang = ToGeographic(fang, hang, "the angle map (%s)" % nang,
		                          "data", refgrid, method)
	if refmask is not None:
		fmsk = ResolveImg(refmask)
		hmsk = ResolveHdr(fmsk)
		nmsk = os.path.basename(fmsk)
		fmsk, hmsk = ToGeographic(fmsk, hmsk, "the reference mask (%s)" % nmsk,
		                          "mask", refgrid, method)

	fld1, lin1 = ReadHdr(h1)
	fld2, _ = ReadHdr(h2)

	geom = []
	for fld, path in ((fld1, h1), (fld2, h2)):
		geom.append(tuple(GetInt(fld, k, path, 1 if k == "bands" else None)
		                  for k in ("samples", "lines", "bands")))
	if geom[0] != geom[1]:
		sys.exit("ERROR: geometries still differ after alignment - %s: %s vs %s: %s\n"
		         "       (samples, lines, bands): the band numbers probably differ, which no\n"
		         "       resampling can fix" % (n1, geom[0], n2, geom[1]))
	samples, lines, bands = geom[0]

	# both are now geographic Lat/Long WGS 84 on the same grid: this is the
	# geocoding of the output, so it is read from the data, never guessed
	geo1 = ReadGeo(fld1, h1)[0]
	geo2 = ReadGeo(fld2, h2)[0]
	if geo2 is None or not SameGeo(geo1, geo2):
		sys.exit("ERROR: the two files are still not on the same grid after alignment:\n"
		         "         %s: %s\n         %s: %s"
		         % (n1, GeoTxt(geo1), n2, GeoTxt(geo2) if geo2 else "not Lat/Long WGS 84"))

	itl1 = fld1.get("interleave", "bsq").lower()
	itl2 = fld2.get("interleave", "bsq").lower()
	if bands > 1 and itl1 != itl2:
		sys.exit("ERROR: interleaves differ (%s vs %s) with %d bands - convert one of them first"
		         % (itl1, itl2, bands))

	info = []
	for fld, path, fbin in ((fld1, h1, f1), (fld2, h2, f2)):
		dtc = GetInt(fld, "data type", path)
		if dtc not in ENVI2NP:
			sys.exit("ERROR: unsupported ENVI data type %d in %s" % (dtc, path))
		order = ">" if GetInt(fld, "byte order", path, 0) == 1 else "<"
		dt = np.dtype(ENVI2NP[dtc]).newbyteorder(order)
		off = GetInt(fld, "header offset", path, 0)
		need = off + samples * lines * bands * dt.itemsize
		size = os.path.getsize(fbin)
		if size < need:
			sys.exit("ERROR: %s is too small (%d bytes) for the header %s which announces %d bytes\n"
			         "       -> check samples / lines / bands / data type / header offset"
			         % (fbin, size, path, need))
		info.append((dt, off))

	nelem = samples * lines * bands

	# result type: float32 by default, float64 / complex kept if an input needs it
	dtout = np.promote_types(info[0][0].newbyteorder("="), info[1][0].newbyteorder("="))
	if dtout.kind not in "fc":
		dtout = np.dtype("f4")
	work = "c16" if dtout.kind == "c" else "f8"
	dtfile = dtout.newbyteorder(info[0][0].byteorder)	# same byte order as FILE1

	a = np.memmap(f1, dtype=info[0][0], mode="r", offset=info[0][1], shape=(nelem,))
	b = np.memmap(f2, dtype=info[1][0], mode="r", offset=info[1][1], shape=(nelem,))

	amm = None
	if fang is not None:
		amm = OpenEnvi(fang, hang, samples, lines, bands, "angle map", geo1)
		vmax = MaxAbs(amm)
		# a SAR incidence angle is never below ~10 deg: a max around pi/2 means radians
		if not radians and vmax < 1.6:
			sys.exit("ERROR: the angles of %s do not exceed %.4f - they look like RADIANS.\n"
			         "       Add -RAD if they are, otherwise check the file." % (fang, vmax))
		if radians and vmax > 1.6:
			sys.exit("ERROR: -RAD given but the angles of %s reach %.4f - they look like DEGREES."
			         % (fang, vmax))

	mmask = None
	if refmask is not None:
		mmask = OpenEnvi(fmsk, hmsk, samples, lines, bands, "reference mask", geo1)

	if refmode != "NONE" and dtout.kind == "c":
		sys.exit("ERROR: -REF has no meaning on complex data")

	def Projected(i, j):
		"""(FILE1 - FILE2) / cos(angle) for the elements [i:j]. Single definition,
		   used both for the reference statistic and for the written result."""
		res = a[i:j].astype(work) - b[i:j].astype(work)
		if amm is None:
			return res / cosa
		cang = amm[i:j].astype("f8")
		if not radians:
			cang = np.radians(cang)
		cang = np.cos(cang)
		# grazing or void angles would explode: flag them instead
		cang[np.abs(cang) < 1e-9] = np.nan
		return res / cang

	# ---- first pass: statistic of the result over the reference zone --------
	total, npix, nzone, values = 0.0, 0, 0, []
	for i in range(0, nelem, CHUNK):
		j = min(i + CHUNK, nelem)
		blk = Projected(i, j)
		fin = np.isfinite(blk)
		if mmask is None:
			nzone += j - i
			ok = fin
		else:
			msk = mmask[i:j]
			inzone = np.isfinite(msk) & (msk != 0)
			nzone += int(inzone.sum())
			ok = fin & inzone
		sel = blk[ok]
		npix += sel.size
		total += float(sel.sum())
		if refmode == "MEDIAN":
			values.append(sel.astype("f4"))

	where = "mask %s" % nmsk if mmask is not None else "whole image"
	if npix == 0:
		sys.exit("ERROR: the reference zone (%s) contains no valid pixel" % where)
	valid = 100.0 * npix / nzone if nzone else 0.0
	zmean = total / npix
	zmedian = float(np.median(np.concatenate(values))) if refmode == "MEDIAN" else None

	print("reference zone (%s): %d pixels declared, %d valid (%.1f%%), mean %+.6f"
	      % (where, nzone, npix, valid, zmean), end="")
	print("" if zmedian is None else ", median %+.6f" % zmedian)

	if refmode == "NONE":
		offset = 0.0
		print("WARNING: -REF=NONE, the offset above is NOT removed. A model delay is\n"
		      "         absolute while a displacement map is relative: subtracting this\n"
		      "         map as it is would bias the corrected map by that amount.")
	else:
		if valid < minvalid:
			sys.exit("ERROR: only %.1f%% of the reference zone (%s) is valid, less than "
			         "-MINVALID=%g%%\n       -> this pair would be referenced on a "
			         "sub-population of the zone, hence\n          inconsistently with the "
			         "other pairs. Widen the zone, or discard this pair."
			         % (valid, where, minvalid))
		if npix < minpix:
			sys.exit("ERROR: only %d valid pixels in the reference zone (%s), less than "
			         "-MINPIX=%d\n       -> too few samples for a meaningful mean/median"
			         % (npix, where, minpix))
		offset = zmean if refmode == "MEAN" else zmedian

	# ---- second pass: write the result, referenced --------------------------
	try:
		with open(out, "wb") as fo:
			for i in range(0, nelem, CHUNK):
				j = min(i + CHUNK, nelem)
				res = Projected(i, j) - offset
				res.astype(dtfile).tofile(fo)
	except IOError as err:
		sys.exit("ERROR: can not write %s (%s)" % (out, err))

	# header rebuilt from the one of FILE1, so that ignore value, band names,
	# interleave... are kept. Everything describing the geocoding is dropped and
	# rewritten below in the AMSTer DEM convention: the fields of FILE1 may come
	# from gdal (no units), from ENVI (units=Meters is refused earlier), may have
	# a reference pixel elsewhere than (1,1), or an x start / y start offset.
	drop = ("description", "data type", "header offset", "file type",
	        "samples", "lines", "bands", "byte order",
	        "map info", "projection info", "coordinate system string",
	        "x start", "y start", "pixel size", "geo points", "rpc info")
	big = dtfile.byteorder == ">" or (dtfile.byteorder == "=" and sys.byteorder == "big")
	with open(out + ".hdr", "w") as fh:
		fh.write("ENVI\n")
		if angle is not None:
			how = "cos( %g deg )" % angle
		else:
			how = "cos( %s%s )" % (nang, "" if radians else " in deg")
		if refmode == "NONE":
			ref = "not referenced"
		else:
			ref = "referenced: %s over %s removed (%+.6f, %d px, %.1f%% valid)" \
		      % (refmode, where, offset, npix, valid)
		fh.write("description = { ( %s - %s ) / %s - %s%s - %s }\n"
		         % (n1, n2, how, ref, "".join(" - " + note for note in NOTES), PRG))
		fh.write("samples = %d\nlines = %d\nbands = %d\n" % (samples, lines, bands))
		fh.write("header offset = 0\nfile type = ENVI Standard\n")
		fh.write("data type = %d\n" % NP2ENVI[dtout.str[1:]])
		fh.write("byte order = %d\n" % (1 if big else 0))
		# geocoding, always geographic Lat/Long WGS 84 in degrees, tie point at
		# the pixel (1,1), i.e. exactly what an AMSTer DEM / geocoded map carries
		fh.write("map info = {Geographic Lat/Lon, 1.0000, 1.0000, %s, %s, %s, %s, "
		         "WGS-84, units=Degrees}\n"
		         % (Deg(geo1[0]), Deg(geo1[1]), Deg(geo1[2]), Deg(geo1[3])))
		fh.write("projection info = {1, %.1f, %.1f, 0.0, 0.0, WGS-84, units=Degrees}\n"
		         % (WGS84_A, WGS84_B))
		fh.write("coordinate system string = {%s}\n" % CSSTRING)
		for line in lin1:
			if "=" not in line:
				continue
			if line.split("=", 1)[0].strip().lower() in drop:
				continue
			fh.write(line.rstrip() + "\n")

	if angle is not None:
		how = "cos(%g deg) = %.6f" % (angle, cosa)
	else:
		how = "cos(%s), per pixel, in %s" % (nang, "radians" if radians else "degrees")
	print("%s written: %d x %d x %d, ENVI data type %d, divided by %s"
	      % (out, samples, lines, bands, NP2ENVI[dtout.str[1:]], how))
	print("geocoding: %s" % GeoTxt(geo1))
	if refmode != "NONE":
		print("offset removed: %+.6f (%s over %s, %d px, %.1f%% valid)"
		      % (offset, refmode, where, npix, valid))
	print("%s.hdr written" % out)


if __name__ == "__main__":
	main(sys.argv)
