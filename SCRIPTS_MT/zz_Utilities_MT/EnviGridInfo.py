#!/opt/local/amster_python_env/bin/python
"""
EnviGridInfo.py

Read the grid definition of a raster (ENVI, GeoTiff, ...) through gdalinfo and
print it as shell variable assignments, together with the XYZ tile zoom level
required to fill that grid at a given oversampling factor.

Only the standard library is used: the geometry comes from "gdalinfo -json",
so any format known to GDAL is accepted and no python GDAL bindings are needed.

Usage:
    EnviGridInfo.py RASTER FACTOR MAXZOOM WKT_OUTPUT_FILE

    RASTER            template raster (e.g. an ENVI amplitude or MSBAS file)
    FACTOR            integer oversampling factor (output pixels per template
                      pixel in each direction). This is exactly the
                      RateResolutionFactor of the AMSTer web pages.
    MAXZOOM           highest tile zoom level allowed for the tile server
    WKT_OUTPUT_FILE   file where the template projection is written as WKT

Output (on stdout, meant for "eval"):
    NX, NY            template size in pixels
    PIXX, PIXY        template pixel size in map units
    ULX, ULY          upper left corner (map units)
    LRX, LRY          lower right corner (map units)
    OUTNX, OUTNY      output size in pixels
    CENTERLAT         latitude of the scene centre (deg)
    TARGETRES         target ground resolution (m)
    ZOOM              tile zoom level to request
    NTILES            rough number of tiles to be downloaded
"""

import json
import math
import os
import subprocess
import sys

EARTH_CIRCUMFERENCE = 2.0 * math.pi * 6378137.0   # WGS84 equator, metres
TILE_SIZE = 256                                   # pixels, XYZ/TMS standard


def Die(message):
    sys.stderr.write("EnviGridInfo.py: %s\n" % message)
    sys.exit(1)


def GdalInfo(raster):
    """Return the gdalinfo -json dictionary of raster."""
    try:
        raw = subprocess.check_output(["gdalinfo", "-json", raster],
                                      stderr=subprocess.PIPE)
    except OSError:
        Die("gdalinfo not found in PATH")
    except subprocess.CalledProcessError:
        Die("gdalinfo cannot open %s" % raster)
    try:
        return json.loads(raw.decode("utf-8", "replace"))
    except ValueError:
        Die("cannot parse the gdalinfo output of %s" % raster)


def main():
    if len(sys.argv) != 5:
        Die("usage: EnviGridInfo.py RASTER FACTOR MAXZOOM WKT_OUTPUT_FILE")

    raster = sys.argv[1]
    try:
        factor = int(sys.argv[2])
        maxzoom = int(sys.argv[3])
    except ValueError:
        Die("FACTOR and MAXZOOM must be integers")
    wktfile = sys.argv[4]

    if factor < 1:
        Die("FACTOR must be 1 or more")
    if not os.path.exists(raster):
        Die("%s does not exist" % raster)

    info = GdalInfo(raster)

    # ---- template grid ----------------------------------------------------
    gt = info.get("geoTransform")
    if gt is None:
        Die("%s has no geotransform: it is not georeferenced" % raster)
    if abs(gt[2]) > 0.0 or abs(gt[4]) > 0.0:
        Die("%s has a rotated geotransform, which is not supported" % raster)

    nx, ny = int(info["size"][0]), int(info["size"][1])
    ulx, uly = float(gt[0]), float(gt[3])
    lrx, lry = ulx + nx * float(gt[1]), uly + ny * float(gt[5])
    pixx, pixy = abs(float(gt[1])), abs(float(gt[5]))

    # ---- projection, written as WKT for gdalwarp -t_srs -------------------
    wkt = info.get("coordinateSystem", {}).get("wkt")
    if not wkt:
        Die("%s has no coordinate system: cannot build a background map"
            % raster)
    try:
        handle = open(wktfile, "w")
        handle.write(wkt)
        handle.write("\n")
        handle.close()
    except IOError as err:
        Die("cannot write %s (%s)" % (wktfile, err))

    # ---- footprint in geographic coordinates ------------------------------
    # The ground size is derived from the WGS84 footprint rather than from the
    # pixel size, so that the script works whatever the units of the template
    # projection are (metres, feet, degrees...).
    extent = info.get("wgs84Extent")
    if not extent or not extent.get("coordinates"):
        Die("gdalinfo cannot express the footprint of %s in WGS84" % raster)
    corners = extent["coordinates"][0]
    lons = [float(c[0]) for c in corners]
    lats = [float(c[1]) for c in corners]

    if max(lons) - min(lons) > 180.0:
        Die("the footprint seems to cross the antimeridian, "
            "which is not supported")

    centerlat = (min(lats) + max(lats)) / 2.0
    coslat = math.cos(math.radians(centerlat))
    if coslat < 1.0e-6:
        Die("polar footprints are not supported by web mercator tiles")

    width_m = (max(lons) - min(lons)) / 360.0 * EARTH_CIRCUMFERENCE * coslat
    height_m = (max(lats) - min(lats)) / 360.0 * EARTH_CIRCUMFERENCE
    if width_m <= 0.0 or height_m <= 0.0:
        Die("the footprint of %s has a null size" % raster)

    # ---- output grid and required zoom level ------------------------------
    outnx, outny = nx * factor, ny * factor
    targetres = width_m / outnx      # metres per output pixel

    # Ground resolution of a tile pixel: EARTH_CIRCUMFERENCE * cos(lat) /
    # (TILE_SIZE * 2**zoom). Take the first zoom level at least as detailed
    # as the output grid, so that no tile pixel has to be interpolated up.
    zoom = int(math.ceil(math.log(EARTH_CIRCUMFERENCE * coslat /
                                  (TILE_SIZE * targetres), 2.0)))
    zoom = max(0, min(maxzoom, zoom))

    tileres = EARTH_CIRCUMFERENCE * coslat / (TILE_SIZE * 2.0 ** zoom)
    ntiles = (math.ceil(width_m / tileres / TILE_SIZE + 1) *
              math.ceil(height_m / tileres / TILE_SIZE + 1))

    for name, value in (("NX", nx), ("NY", ny),
                        ("PIXX", pixx), ("PIXY", pixy),
                        ("ULX", ulx), ("ULY", uly),
                        ("LRX", lrx), ("LRY", lry),
                        ("OUTNX", outnx), ("OUTNY", outny),
                        ("CENTERLAT", round(centerlat, 6)),
                        ("TARGETRES", round(targetres, 4)),
                        ("ZOOM", zoom),
                        ("NTILES", int(ntiles))):
        sys.stdout.write("%s=%s\n" % (name, repr(value).strip("'")))


if __name__ == "__main__":
    main()
