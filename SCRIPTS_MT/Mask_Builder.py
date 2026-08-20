#!/opt/local/amster_python_env/bin/python
#
# Mask_Builder.py INPUT OUTPUT [options]
#
# Builds a mask from a single band raster: every valid (finite, non-zero, non-nodata)
# pixel is set to VALID_VALUE (0.9 by default), everything else is set to 0.
#
# Input  : GeoTIFF, ENVI (with .hdr), or headerless raw float32 binary  -> auto-detected
# Output : format taken from the OUTPUT extension
#             .tif / .tiff  -> GeoTIFF (georeferencing/projection copied from input)
#             anything else -> ENVI (a .hdr is written when GDAL is available,
#                              otherwise plain raw float32 as in the previous versions)
#
# New in Distro V 2.0 20250813:	- launched from python3 venv
# New in Distro V 3.0 20260730:	- reads GeoTIFF as well as ENVI/raw binary
#				- writes GeoTIFF or ENVI, geocoding and projection preserved
#				- nodata values of the input are masked out as well
#				- no more 0/0 runtime warnings, proper exit codes
#				- GDAL_PAM_ENABLED=NO -> no .aux.xml sidecar files
#
# This script is part of the AMSTer Toolbox
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
##########################################################################################

# -*-coding:Latin-1 -*

from __future__ import print_function

import argparse
import os
import shutil
import sys

import numpy as np

# TIFF / BigTIFF magic numbers (little and big endian)
TIFF_MAGIC = (b"II*\x00", b"MM\x00*", b"II+\x00", b"MM\x00+")


def die(msg, code=1):
	print("ERROR: %s" % msg, file=sys.stderr)
	sys.exit(code)


def looks_like_tiff(path):
	"""True if the file is a TIFF, based on the extension or on the magic bytes."""
	if os.path.splitext(path)[1].lower() in (".tif", ".tiff"):
		return True
	try:
		with open(path, "rb") as fid:
			return fid.read(4) in TIFF_MAGIC
	except (IOError, OSError):
		return False


def load_gdal():
	"""Import GDAL if available, else return None."""
	try:
		from osgeo import gdal
	except ImportError:
		return None
	gdal.UseExceptions()
	gdal.SetConfigOption("GDAL_PAM_ENABLED", "NO")	# no .aux.xml sidecar files
	return gdal


def driver_for(path):
	"""GDAL driver name deduced from the output file extension."""
	if os.path.splitext(path)[1].lower() in (".tif", ".tiff"):
		return "GTiff"
	return "ENVI"


def build_mask(arr, valid, nodata=None):
	"""VALID where the pixel is finite, non-zero and not nodata; 0 elsewhere.

	Equivalent to the historical (B1/B1)*valid followed by nan_to_num, but without
	the 0/0 and inf/inf warnings.
	"""
	data = arr.astype("float64", copy=False)
	good = np.isfinite(data) & (data != 0.0)
	if nodata is not None and np.isfinite(nodata):
		good &= data != nodata
	return np.where(good, valid, 0.0).astype("float32")


def sidecar_hdr(path):
	"""Return the ENVI header of path if one can be found (file.ext.hdr or file.hdr)."""
	for candidate in (path + ".hdr", os.path.splitext(path)[0] + ".hdr"):
		if os.path.isfile(candidate):
			return candidate
	return None


def run_gdal(gdal, args):
	"""GeoTIFF or ENVI-with-header input: read with GDAL, keep the geocoding."""
	src = gdal.Open(args.input, gdal.GA_ReadOnly)
	if src.RasterCount > 1:
		print("WARNING: %i bands in input, only band 1 is used" % src.RasterCount)

	band = src.GetRasterBand(1)
	nodata = band.GetNoDataValue()
	mask = build_mask(band.ReadAsArray(), args.value, nodata)

	drv_name = driver_for(args.output)
	drv = gdal.GetDriverByName(drv_name)
	if drv is None:
		die("GDAL driver %s is not available" % drv_name)

	# uncompressed, non tiled, single band float32 -> safe for msbas and for AMSTer tools
	options = ["TILED=NO"] if drv_name == "GTiff" else []
	dst = drv.Create(args.output, src.RasterXSize, src.RasterYSize, 1,
			 gdal.GDT_Float32, options)

	geotransform = src.GetGeoTransform(can_return_null=True)
	if geotransform:
		dst.SetGeoTransform(geotransform)
	projection = src.GetProjection()
	if projection:
		dst.SetProjection(projection)

	dst_band = dst.GetRasterBand(1)
	dst_band.WriteArray(mask)
	if args.nodata_zero:
		dst_band.SetNoDataValue(0.0)
	dst_band.FlushCache()
	dst.FlushCache()
	dst_band = None
	dst = None
	src = None

	print("%s written (%s, %i x %i, Float32)"
	      % (args.output, drv_name, mask.shape[1], mask.shape[0]))
	return mask


def run_raw(args):
	"""Headerless raw binary input: historical behaviour, flat array in, flat array out."""
	if driver_for(args.output) == "GTiff":
		die("%s was not opened by GDAL (no readable header, or GDAL not installed), "
		    "so a GeoTIFF output cannot be georeferenced.\n"
		    "       Provide an ENVI .hdr next to the input, or ask for a binary output."
		    % args.input)

	arr = np.fromfile(args.input, dtype=args.dtype)
	if arr.size == 0:
		die("%s is empty or unreadable as %s" % (args.input, args.dtype))

	mask = build_mask(arr, args.value)
	with open(args.output, "wb") as dest:
		dest.write(mask.tobytes())

	# keep the mask usable in ENVI/QGIS by cloning the header of the input, if any
	hdr = sidecar_hdr(args.input)
	if hdr is not None:
		shutil.copyfile(hdr, args.output + ".hdr")
		print("header copied to %s.hdr" % args.output)

	print("%s written (raw %s, %i pixels, Float32)"
	      % (args.output, args.dtype, mask.size))
	return mask


def main():
	parser = argparse.ArgumentParser(
		description="Build a mask (VALID where the input is valid and non-zero, "
			    "0 elsewhere) from a GeoTIFF, ENVI or raw float32 raster.")
	parser.add_argument("input", help="input raster (GeoTIFF, ENVI or raw float32)")
	parser.add_argument("output", help="output mask (.tif/.tiff -> GeoTIFF, else ENVI/raw)")
	parser.add_argument("-v", "--value", type=float, default=0.9,
			    help="value given to the valid pixels (default 0.9)")
	parser.add_argument("-t", "--dtype", default="float32",
			    help="numpy dtype of a headerless raw input, e.g. float32, "
				 ">f4 for big endian (default float32)")
	parser.add_argument("--nodata-zero", action="store_true",
			    help="flag 0 as nodata in the output (GeoTIFF/ENVI only)")
	args = parser.parse_args()

	if not os.path.isfile(args.input):
		die("input file %s does not exist" % args.input)

	gdal = load_gdal()
	is_tiff = looks_like_tiff(args.input)

	if is_tiff and gdal is None:
		die("%s is a TIFF but the GDAL python bindings are not available in this "
		    "environment" % args.input)

	# GDAL handles GeoTIFF and ENVI-with-header; a headerless raw file falls back to numpy
	use_gdal = False
	if gdal is not None:
		try:
			probe = gdal.Open(args.input, gdal.GA_ReadOnly)
			use_gdal = probe is not None
			probe = None
		except Exception:
			use_gdal = False
		if not use_gdal and is_tiff:
			die("GDAL cannot open %s" % args.input)

	print("input  : %s (%s)" % (args.input, "GDAL" if use_gdal else "raw binary"))
	print("output : %s" % args.output)

	mask = run_gdal(gdal, args) if use_gdal else run_raw(args)

	print("------------")
	print("max value in mask: %s" % np.amax(mask))
	print("mask building done.")


if __name__ == "__main__":
	main()
