#!/opt/local/amster_python_env/bin/python
# -----------------------------------------------------------------------------------------
# This script wraps a geocoded raster (velocity or deformation map, e.g. the
# MSBAS_LINEAR_RATE_* or MSBAS_* products), given either as an ENVI binary + header
# pair or as a GeoTIFF, on a satellite imagery background and
# writes a publication ready figure with a colour scale, a distance scale bar and
# a frame graduated in UTM coordinates.
#
# The figure is drawn in the native UTM CRS read from the ENVI header, so the data
# are never resampled on a foreign grid: only the background imagery is warped
# (Web Mercator -> UTM). The axes are therefore metric, which makes the distance
# scale and the UTM graduations exact rather than approximate.
#
# In interactive mode the map can be panned and zoomed; at each new view the
# imagery is re-tiled and re-warped and the data re-averaged from full resolution,
# so zooming reveals more detail instead of bigger pixels. Closing the window
# writes the figure as left on screen.
#
# Usage:  ./Envi2GoogleEarthMap.py RASTER_FILE [OUTPUT_FIGURE] [options]
#         ./Envi2GoogleEarthMap.py --help  for all the options
#
# Parameters are :
#		- Path to the geocoded raster to map: ENVI binary or GeoTIFF, recognised
#		  from its content and not from its name (mandatory, unless --coherence
#		  is given alone to map a coherence raster)
#		- Path to the output figure (optional, default <ENVI_FILE>.png; may also be
#		  given with -o/--output, which takes precedence. The extension sets the
#		  format: png, pdf, svg, eps, jpg, tif...)
#
# Main options (see --help for the others):
#		--nodata VAL[,VAL]	no-data value(s) on top of NaN and the header's
#							'data ignore value'; nothing is assumed, but a dominant
#							value is reported so it can be masked knowingly
#		--coherence FILE	coherence raster on the same grid; damps the overlay
#							where coherence is low. Given alone, the coherence is
#							mapped itself, in greyscale from 0 to 1
#		--kind CLASS		rate / deformation / coherence, when the file name does
#							not say it
#		--band N			band to map in a multi-band GeoTIFF
#		--cmap NAME			vik (default) or vik-balanced, or any matplotlib name
#							vik, vik-balanced, RdYlBu_r, jet
#		--label / --unit	colour scale title and unit; both deduced from the
#							file name when not given
#		--title TEXT		optional figure title; nothing drawn without it
#		--basemap NAME		esri (default), esri-topo, osm or none
#		--local-image FILE	use a Google Earth Pro capture or a GeoTIFF instead
#		-i					interactive window; the figure is written on closing, i.e. 
#							taking into account manual zoom before closing.
#		--clim MIN MAX		force the colour scale limits (e.g. --clim -1 1)
#
# Dependencies:	- python3 in the AMSTer venv, with numpy, matplotlib, pyproj and Pillow
#				- osgeo/gdal, to read a GeoTIFF input or the bounds of a GeoTIFF
#				  given to --local-image. Not needed for ENVI input.
#				- an internet access for the imagery tiles, unless --local-image or
#				  --basemap none is used. Tiles are cached in ~/.cache/Envi2GoogleEarthMap_tiles
#				- Resample_ToGrid.sh, if the coherence is not on the data grid
#
# New in Distro V 1.0 20260907:	- set up
# New in Distro V 1.1 20260907:	- a coherence file can be mapped on its own, either as the plain
#								  input or through --coherence with no input; it then gets a black
#								  and white colour scale fixed from 0 to 1
#								- --kind to force the product class when the file name does not
#								  follow the naming convention
#								- the colour scale arrows are now drawn only on the ends the data
#								  actually exceed
# New in Distro V 1.2 20260907:	- the input may be a GeoTIFF as well as an ENVI pair, for the
#								  data and for the coherence independently; the format is detected
#								  from the file content, not from its extension
#								- --band / --coh-band for multi-band GeoTIFF, --coh-hdr for an
#								  ENVI coherence whose header sits elsewhere
#								- any projected CRS in metres is accepted, not only UTM; the
#								  GeoTIFF band nodata is honoured like ENVI data ignore value
#								- fix: the input and output parameters can now be given in any
#								  order with respect to the options. argparse matches positionals
#								  in contiguous chunks, so "in.bin --nodata 0 out.png" used to be
#								  rejected with "unrecognized arguments: out.png"
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
"""
Wrap a geocoded velocity or deformation map -- ENVI binary + header, or
GeoTIFF -- on satellite imagery, with a colour scale, a distance scale bar and
a UTM frame.

Colour scale
------------
The default is "vik" from Crameri's Scientific colour maps: perceptually
uniform, safe under red-green deficiency, and monotone in lightness within
each arm so it survives greyscale printing. "vik-balanced" additionally
equalises the lightness of the two arms, so neither sign of motion reads as
the louder one. Any matplotlib name also works; the rainbow maps are refused
a silent pass and draw a warning.

The colour scale title and unit are deduced from the file name -- a LINEAR
RATE product is a velocity in m/yr, anything else is a cumulative deformation
in m -- and the component token (LOS, EW, UD, NS) names the direction. Both
are overridable with --label and --unit. The figure title is optional and
nothing is drawn without --title.

Coherence
---------
--coherence takes a coherence raster on the same grid and uses it to damp the
overlay pixel by pixel: below --coh-range LO the overlay is invisible and the
imagery shows through, above HI it is fully opaque. Poorly constrained areas
then look uncertain instead of being read as signal. The grid must match
exactly; a mismatch is an error rather than a silent resampling.

No-data
-------
--nodata is optional and adds nothing by default beyond NaN and the header's
own 'data ignore value'.  Nothing is guessed, because "0 means no data" is an
assumption, not a fact: a detrended rate map can legitimately contain exact
zeros.  When a single value dominates the histogram the script says so and
tells you what to pass, e.g.

    Envi2GoogleEarthMap.py rate.bin --nodata 0
    Envi2GoogleEarthMap.py rate.bin --nodata 0,-9999

Background imagery -- three interchangeable sources:
  --basemap esri        Esri World Imagery XYZ tiles (default, no API key)
  --basemap none        flat background, no imagery
  --local-image FILE    any image you already have, with its geographic bounds
                        (--image-bounds) or as a GeoTIFF.  This is the route
                        for genuine Google Earth imagery: in Google Earth Pro
                        use "File > Save Image...", which gives you the N/S/E/W
                        bounds to pass to --image-bounds.  Programmatic
                        scraping of Google's tile servers is not supported
                        here because it breaks their terms of use.

Examples
--------
# batch: straight to a PNG next to the binary
./Envi2GoogleEarthMap.py MSBAS_LINEAR_RATE_LOS.bin --nodata 0

# interactive: explore, zoom, then close the window to save what you see
./Envi2GoogleEarthMap.py MSBAS_LINEAR_RATE_LOS.bin --nodata 0 -i --clim -1 1

# a Google Earth Pro capture as background
./Envi2GoogleEarthMap.py rate.bin --nodata 0 --local-image ge.jpg \
        --image-bounds -63.70 -32.10 -61.85 -30.10

Requires: numpy, matplotlib, pyproj, Pillow  (osgeo/gdal only for GeoTIFF input)
"""

import argparse
import collections
import math
import os
import re
import sys
import time
import urllib.request

import numpy as np

import matplotlib

PRG = os.path.basename(__file__)
VER = "Distro V1.2 AMSTer script utilities"
AUT = "Nicolas d'Oreye, (c)2016-2026, Last modified on Sep 07, 2026"

plt = None          # bound by setup_backend() once the backend is chosen


# ----------------------------------------------------------------------------
# 0. Backend
# ----------------------------------------------------------------------------

# Tried in turn for -i; the first one that imports wins.
GUI_BACKENDS = ("macosx", "qtagg", "tkagg", "qt5agg", "gtk3agg")


def setup_backend(interactive):
    """Bind the global `plt`. Returns True only if a real GUI is usable.

    matplotlib defers loading a backend, so merely importing pyplot proves
    nothing: the failure would surface much later, at the first subplots()
    call. switch_backend() resolves it immediately, which is what turns an
    unusable backend into a clean fallback here rather than a crash halfway
    through the plot.
    """
    global plt
    matplotlib.use("Agg", force=True)
    import matplotlib.pyplot as pyplot
    plt = pyplot
    if not interactive:
        return False

    # On a headless Linux box (ssh without X forwarding) tkinter imports fine
    # and only fails when a window is created, so check for a display first.
    if sys.platform != "darwin" and not (os.environ.get("DISPLAY")
                                         or os.environ.get("WAYLAND_DISPLAY")):
        sys.stderr.write("No DISPLAY: -i needs a graphical session "
                         "(ssh -X / -Y). Writing the figure instead.\n")
        return False

    for name in GUI_BACKENDS:
        try:
            pyplot.switch_backend(name)
            return True
        except Exception:
            continue
    pyplot.switch_backend("Agg")
    sys.stderr.write("No interactive backend available (tried %s). "
                     "Writing the figure instead.\n" % ", ".join(GUI_BACKENDS))
    return False


def halo(width=2.2):
    """White outline so annotations stay legible over dark imagery."""
    import matplotlib.patheffects as pe
    return [pe.withStroke(linewidth=width, foreground="w")]


# ----------------------------------------------------------------------------
# 1. ENVI header
# ----------------------------------------------------------------------------

# ENVI "data type" code -> numpy base type
ENVI_DTYPES = {1: "u1", 2: "i2", 3: "i4", 4: "f4", 5: "f8",
               12: "u2", 13: "u4", 14: "i8", 15: "u8"}


def find_header(binary_path):
    """Return the .hdr that goes with a binary, trying the usual AMSTer spellings."""
    stem, ext = os.path.splitext(binary_path)
    candidates = [binary_path + ".hdr",                     # file.bin.hdr
                  stem + ".hdr",                            # file.hdr
                  stem + "_" + ext.lstrip(".") + ".hdr"]    # file_bin.hdr (AMSTer)
    for cand in candidates:
        if os.path.isfile(cand):
            return cand
    sys.exit("No ENVI header found. Tried:\n  " + "\n  ".join(candidates))


def read_envi_hdr(path):
    """Parse an ENVI header into a dict of lower-case keys -> string values."""
    with open(path, "r", errors="replace") as fh:
        text = fh.read()
    # collapse braced values onto one line so a simple key = value split works
    text = re.sub(r"\{[^}]*\}", lambda m: m.group(0).replace("\n", " "), text)
    hdr = {}
    for line in text.splitlines():
        if "=" not in line:
            continue
        key, val = line.split("=", 1)
        hdr[key.strip().lower()] = val.strip().strip("{}").strip()
    for required in ("samples", "lines", "data type"):
        if required not in hdr:
            sys.exit("Header %s is missing '%s'" % (path, required))
    return hdr


def geo_from_hdr(hdr, epsg_override=None):
    """Extract pixel size, upper-left corner and EPSG code from 'map info'.

    Returns (x_ul, y_ul, dx, dy, epsg, crs_label) where x_ul/y_ul are the
    coordinates of the *outer* upper-left corner of the first pixel.
    """
    if "map info" not in hdr:
        sys.exit("Header has no 'map info': the file is not geocoded.")
    f = [t.strip() for t in hdr["map info"].split(",")]
    proj = f[0].upper()
    # map info = {proj, ref_x, ref_y, ref_easting, ref_northing, dx, dy, ...}
    ref_x, ref_y = float(f[1]), float(f[2])
    east, north = float(f[3]), float(f[4])
    dx, dy = float(f[5]), float(f[6])

    # ref_x/ref_y are 1-based pixel indices of the reference point and refer to
    # that pixel's upper-left corner. Shift to pixel (1,1) to anchor the grid.
    x_ul = east - (ref_x - 1.0) * dx
    y_ul = north + (ref_y - 1.0) * dy

    if epsg_override:
        return x_ul, y_ul, dx, dy, int(epsg_override), "EPSG:%s" % epsg_override

    if not proj.startswith("UTM"):
        sys.exit("This script draws metric UTM maps; 'map info' says '%s'.\n"
                 "Reproject first (gdalwarp -t_srs EPSG:326xx/327xx) or pass "
                 "--epsg." % proj)
    zone = int(float(f[7]))
    south = f[8].strip().lower().startswith("s")
    epsg = (32700 if south else 32600) + zone
    label = "UTM zone %d%s / WGS84" % (zone, "S" if south else "N")
    return x_ul, y_ul, dx, dy, epsg, label


# ----------------------------------------------------------------------------
# 1b. Colour maps
# ----------------------------------------------------------------------------

# "vik" from Crameri's Scientific colour maps (doi:10.5281/zenodo.1243862,
# MIT licence), embedded as 256 packed RGB hex triplets so the figure looks
# the same on every machine: vik ships with matplotlib only from 3.10, and
# depending on cmcrameri being installed would make the default fragile.
#
# It is the default because it is measurably the best behaved of the usual
# candidates for a signed field (measured in CIELAB on 256 samples):
#
#   cmap        step-size CV   L* asymmetry   step-size CV under deuteranopia
#   vik            0.008          8.7 L*              0.130
#   coolwarm       0.052          0.3 L*              0.151
#   RdBu_r         0.246          4.4 L*              0.233
#   RdYlBu_r       0.288          6.9 L*              0.338
#   jet            0.388         22.4 L*              0.488
#
# step-size CV is the spread of perceptual distance per equal data step: low
# means equal changes in velocity look like equal changes in colour, so the
# eye is not invited to see structure the data does not contain. vik keeps
# that under both deuteranopia and protanopia, and its lightness is monotone
# within each arm, so the map still reads correctly printed in greyscale.
VIK_HEX = (
    "001261011462011563011764011865011a66021c67021d68"
    "021f6902206a02226b02236c02256d02276e02286f022a70"
    "022b71022d72022e73023074023175023376023477023678"
    "02377902397a023a7b033c7c033e7d033f7e03417f034280"
    "034481034582034783034984034a85044c86044d87044f88"
    "05518905528a06548b06568c07578d08598f095b900b5d91"
    "0c5e920e6093106294116496136697156798176999196b9a"
    "1c6d9c1e6f9d20719e2373a02575a12877a22b79a42d7ba5"
    "307da6337fa83681a93983ab3c85ac3f87ad4289af458bb0"
    "488db24b90b34e92b45194b65496b75798b95a9aba5d9cbb"
    "619ebd64a0be67a2c06aa4c16da6c271a8c474aac577acc6"
    "7aaec87db0c980b2ca84b4cc87b6cd8ab8ce8dbad090bcd1"
    "94bed297c0d49ac2d59dc4d6a0c5d8a3c7d9a7c9daaacbdc"
    "adcdddb0cfdeb3d1dfb6d3e1bad5e2bdd6e3c0d8e4c3dae5"
    "c6dbe6c9dde7ccdfe8cfe0e8d2e1e9d5e3e9d8e4e9dbe5e9"
    "dee6e9e0e6e9e2e7e8e5e7e8e7e7e7e8e7e5eae6e4ebe6e2"
    "ece5e0ede4deeee3dceee1daeee0d8eeded5eeddd3eedbd0"
    "eed9cdedd7cbedd5c8ecd3c5ecd1c3ebd0c0eacebde9ccba"
    "e9cab8e8c8b5e7c6b2e6c4b0e5c1ade4bfaae4bea8e3bca5"
    "e2baa2e1b8a0e0b69ddfb49adfb298deb095ddae93dcac90"
    "dbaa8ddba88bdaa688d9a486d8a283d7a081d69f7ed69d7c"
    "d59b79d49977d39774d39572d29470d1926dd0906bcf8e68"
    "cf8c66ce8b64cd8961cc875fcc855dcb835aca8258c98056"
    "c97e53c87c51c77b4fc6794cc6774ac57548c47445c37243"
    "c27041c26e3fc16d3cc06b3abf6938be6736be6533bd6431"
    "bc622fbb602dba5e2ab85c28b75a26b65824b55521b3531f"
    "b2511db04f1baf4c18ad4a16ab4814a94512a74310a5400f"
    "a33e0da13c0b9f390a9c37099a3508983307963107942f06"
    "912d068f2b068d29068b2706892606872406852206832106"
    "811f067f1e067e1d067c1b067a1a06781806761706741506"
    "7314067113076f11076d10076c0e076a0d07680c07670a07"
    "6509076307076206076004085e03085d02085b0108590008"
)

# Red-green deficiency is the common one, so a red-to-green ramp is out; the
# rainbow maps are worse still, being non-monotone in lightness (jet reverses
# lightness in 40% of its steps, which manufactures false gradients).
CVD_UNSAFE = ("jet", "rainbow", "gist_rainbow", "nipy_spectral", "hsv",
              "brg", "RdYlGn", "Spectral", "gist_ncar")

# sRGB <-> CIELAB, needed only for the lightness-balanced variant below.
_XYZ = np.array([[0.4124, 0.3576, 0.1805],
                 [0.2126, 0.7152, 0.0722],
                 [0.0193, 0.1192, 0.9505]])
_WHITE = np.array([0.95047, 1.0, 1.08883])


def _srgb_to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def _linear_to_srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def rgb_to_lab(rgb):
    t = (_srgb_to_linear(rgb) @ _XYZ.T) / _WHITE
    f = np.where(t > 216 / 24389.0, np.cbrt(t), (841 / 108.0) * t + 4 / 29.0)
    return np.stack([116 * f[:, 1] - 16,
                     500 * (f[:, 0] - f[:, 1]),
                     200 * (f[:, 1] - f[:, 2])], axis=1)


def lab_to_rgb(lab):
    fy = (lab[:, 0] + 16) / 116.0
    f = np.stack([fy + lab[:, 1] / 500.0, fy, fy - lab[:, 2] / 200.0], axis=1)
    t = np.where(f ** 3 > 216 / 24389.0, f ** 3, (116 * f - 16) / (24389 / 27.0))
    return np.clip(_linear_to_srgb((t * _WHITE) @ np.linalg.inv(_XYZ).T), 0, 1)


def vik_colors():
    """The 256 embedded vik colours as an (N, 3) float array."""
    flat = "".join(VIK_HEX)
    vals = np.array([int(flat[i:i + 2], 16) for i in range(0, len(flat), 2)])
    return vals.reshape(-1, 3) / 255.0


def balance_lightness(rgb):
    """Mirror-average the L* profile so both arms carry equal visual weight.

    vik is very nearly perceptually uniform but its dark blue arm reaches
    L* 11 against L* 20 for the dark red arm, so at equal magnitude one sign
    of motion looks stronger than the other. Averaging L* with its mirror
    image, leaving a* and b* untouched, drops that asymmetry from 8.7 to
    0.77 L* -- and happens to improve uniformity under deuteranopia too.
    Chroma is unchanged, so it still reads as vik.
    """
    lab = rgb_to_lab(rgb)
    lab[:, 0] = 0.5 * (lab[:, 0] + lab[::-1, 0])
    return lab_to_rgb(lab)


def get_cmap(name):
    """Resolve a colormap name, adding the embedded scientific maps."""
    from matplotlib.colors import LinearSegmentedColormap
    key = name.lower().replace("_", "-")
    if key in ("vik", "vik-r", "vik-balanced", "vik-balanced-r"):
        colors = vik_colors()
        if "balanced" in key:
            colors = balance_lightness(colors)
        if key.endswith("-r"):
            colors = colors[::-1]
        return LinearSegmentedColormap.from_list(key, colors, N=256)
    if name.rstrip("_r") in CVD_UNSAFE or name in CVD_UNSAFE:
        sys.stderr.write(
            "Warning: '%s' is not colour-blind safe and its lightness is not "
            "monotone, which fabricates gradients. Consider vik or "
            "vik-balanced.\n" % name)
    try:
        return plt.get_cmap(name)
    except Exception:
        sys.exit("Unknown colormap '%s'. Built in here: vik, vik-balanced "
                 "(add -r to reverse), plus any matplotlib name." % name)


# ----------------------------------------------------------------------------
# 2. Data
# ----------------------------------------------------------------------------

def apply_nodata(data, tokens, path):
    """Turn every declared no-data value into NaN, and say which were applied.

    NaN is nodata by definition; the rest come from the format's own
    declaration (ENVI 'data ignore value' or the GeoTIFF band nodata) plus
    whatever --nodata adds. Nothing is guessed.
    """
    applied = []
    for tok in tokens:
        tok = str(tok).strip()
        if tok == "" or tok.lower() == "none":
            continue
        if tok.lower() == "nan":
            applied.append("NaN")               # already nodata by definition
            continue
        try:
            val = np.float32(float(tok))
        except ValueError:
            sys.exit("Cannot read '%s' as a no-data value." % tok)
        data[data == val] = np.nan
        applied.append("%g" % val)
    if applied:
        # name the file: with --coherence two rasters are loaded and an
        # unlabelled second line looks like a duplicate
        sys.stderr.write("No-data in %s: %s\n"
                         % (os.path.basename(path),
                            ", ".join(sorted(set(applied)))))
    return data


def load_data(binary_path, hdr, nodata_arg):
    """Read the raster as float32 with every declared nodata turned into NaN.

    nodata_arg is the raw --nodata string, or None. NaN is always nodata and
    the header's 'data ignore value' is always honoured; nothing else is assumed.
    """
    ns, nl = int(hdr["samples"]), int(hdr["lines"])
    if int(hdr.get("bands", 1)) != 1:
        sys.exit("Multi-band files are not handled; extract one band first.")
    code = int(hdr["data type"])
    if code not in ENVI_DTYPES:
        sys.exit("Unsupported ENVI data type %d" % code)
    endian = ">" if hdr.get("byte order", "0").strip() == "1" else "<"
    dtype = np.dtype(endian + ENVI_DTYPES[code])

    expected = ns * nl * dtype.itemsize
    offset = int(hdr.get("header offset", 0))
    actual = os.path.getsize(binary_path) - offset
    if actual != expected:
        sys.exit("Size mismatch: %s holds %d bytes but the header describes "
                 "%d (%d x %d x %s)." % (binary_path, actual, expected,
                                         ns, nl, dtype.str))

    data = np.fromfile(binary_path, dtype=dtype, offset=offset)
    data = data.reshape(nl, ns).astype(np.float32)

    tokens = []
    if hdr.get("data ignore value"):
        tokens.append(hdr["data ignore value"])
    if nodata_arg:
        tokens.extend(nodata_arg.split(","))
    data = apply_nodata(data, tokens, binary_path)

    return data


def suggest_nodata(data, sample_step=7, threshold=0.15, fixed_scale=False):
    """Warn if one exact value dominates the finite pixels.

    A diagnostic, never an action: sentinels such as 0 are reported so the user
    decides, because in a detrended product exact zeros can be real measurements.
    """
    sample = data[::sample_step, ::sample_step]
    sample = sample[np.isfinite(sample)]
    if sample.size < 100:
        return
    values, counts = np.unique(sample, return_counts=True)
    top = counts.argmax()
    frac = counts[top] / float(sample.size)
    if frac < threshold:
        return
    consequence = ("it will cover the map with that one colour"
                   if fixed_scale else "it will flatten the colour scale")
    sys.stderr.write(
        "Warning: %.1f%% of the valid pixels hold exactly %g. If that is a "
        "no-data sentinel rather than a measurement, re-run with --nodata %g "
        "-- otherwise %s.\n"
        % (100 * frac, values[top], values[top], consequence))


def describe_product(path, label=None, unit=None, kind="auto"):
    """Guess what the raster holds from its name; explicit arguments win.

    AMSTer/MSBAS names carry the quantity: a LINEAR RATE product is a velocity
    in m/yr, a coherence product is dimensionless on [0, 1], and anything else
    is a cumulative deformation in m. The component token, when present, names
    the direction. These are only defaults -- --kind forces the class and
    --label / --unit override the wording for names the convention misses.

    Returns (label, unit, kind) with kind one of rate / deformation / coherence.
    """
    name = os.path.basename(path).upper()
    if kind == "auto":
        if re.search(r"(?:^|[\W_])COH[A-Z]*(?:[\W_]|$)", name):
            kind = "coherence"
        elif re.search(r"LINEAR[\W_]*RATE", name):
            kind = "rate"
        else:
            kind = "deformation"

    if kind == "coherence":
        auto_label, auto_unit = "Coherence", ""
    else:
        auto_unit = "m/yr" if kind == "rate" else "m"
        quantity = "velocity" if kind == "rate" else "displacement"
        components = [("LOS", "LOS"), ("EW", "East-West"), ("UD", "Vertical"),
                      ("UP", "Vertical"), ("NS", "North-South")]
        direction = ""
        for token, pretty in components:
            if re.search(r"(?:^|[\W_])%s(?:[\W_]|$)" % token, name):
                direction = pretty + " "
                break
        auto_label = (direction + quantity) if direction else quantity.capitalize()

    final_label = label or auto_label
    final_unit = auto_unit if unit is None else unit
    if label is None or unit is None:
        note = {"coherence": "  (coherence -> greyscale, fixed 0 to 1)",
                "rate": "",
                "deformation": "  (no LINEAR RATE in the name -> "
                               "treated as a deformation map)"}[kind]
        sys.stderr.write("Quantity: %s%s%s\n" % (
            final_label, " [%s]" % final_unit if final_unit else "", note))
    return final_label, final_unit, kind


# A raster, however it was stored: the rest of the script only ever needs
# these, so ENVI and GDAL formats converge here and nothing downstream cares.
Raster = collections.namedtuple(
    "Raster", "data x_ul y_ul dx dy epsg crs_label path")


def is_tiff(path):
    """Recognise (Big)TIFF by its magic bytes rather than by extension.

    AMSTer products are not always named with an extension, so trusting the
    suffix would misread a file whose name happens to end in .tif and refuse
    a perfectly good one that carries no suffix at all.
    """
    try:
        with open(path, "rb") as fh:
            magic = fh.read(4)
    except OSError as exc:
        sys.exit("Cannot read %s: %s" % (path, exc))
    return magic in (b"II*\x00", b"MM\x00*",      # classic TIFF
                     b"II+\x00", b"MM\x00+")      # BigTIFF


def crs_label_from_srs(srs):
    """A short human label for a spatial reference, UTM spelled out if it is."""
    zone = srs.GetUTMZone()                 # >0 north, <0 south, 0 = not UTM
    if zone:
        datum = (srs.GetAttrValue("DATUM") or "")
        pretty = "WGS84" if "WGS_1984" in datum else datum.replace("_", " ")
        label = "UTM zone %d%s" % (abs(zone), "N" if zone > 0 else "S")
        return label + (" / %s" % pretty if pretty else "")
    return srs.GetName() or "projected CRS"


def read_gdal(path, band=1, epsg_override=None, nodata_arg=None):
    """Read one band of any GDAL-readable raster (GeoTIFF and friends)."""
    # An ImportError is not the only way gdal can be unusable: osgeo often
    # imports cleanly while its compiled gdal_array is built against a
    # different numpy, and the failure then surfaces as a traceback at the
    # first ReadAsArray. Probe array access here so the diagnosis is a
    # sentence rather than a stack trace.
    try:
        from osgeo import gdal, osr
        gdal.UseExceptions()
        from osgeo import gdal_array                # noqa: F401  (probe only)
    except Exception as exc:
        sys.exit("Cannot use gdal to read %s:\n  %s\n"
                 "gdal must be importable and built against the numpy in use "
                 "(a numpy 1.x / 2.x mismatch shows up exactly like this).\n"
                 "An ENVI binary + header pair needs no gdal at all."
                 % (path, exc))
    try:
        ds = gdal.Open(path)
    except Exception as exc:
        sys.exit("gdal cannot open %s: %s" % (path, exc))

    if band < 1 or band > ds.RasterCount:
        sys.exit("%s holds %d band(s); --band %d is out of range."
                 % (path, ds.RasterCount, band))
    if ds.RasterCount > 1 and band == 1:
        sys.stderr.write("%s holds %d bands, mapping band 1 (--band to "
                         "choose).\n" % (os.path.basename(path),
                                         ds.RasterCount))

    gt = ds.GetGeoTransform()
    if gt is None:
        sys.exit("%s carries no geotransform: it is not geocoded." % path)
    if abs(gt[2]) > 1e-9 or abs(gt[4]) > 1e-9:
        sys.exit("%s has a rotated geotransform, which this script does not "
                 "draw. Make it north-up first: gdalwarp -t_srs <same CRS> "
                 "in.tif out.tif" % path)
    x_ul, dx, y_ul, dy = gt[0], gt[1], gt[3], -gt[5]
    if dx <= 0 or dy <= 0:
        sys.exit("%s has a non-standard pixel orientation (dx %g, dy %g); "
                 "re-write it north-up with gdalwarp." % (path, gt[1], gt[5]))

    # CRS: metric axes are what make the scale bar and the frame exact, so a
    # geographic (degree) CRS has to be reprojected rather than silently drawn
    epsg, label = epsg_override, None
    srs = osr.SpatialReference(wkt=ds.GetProjection())
    if epsg_override:
        label = "EPSG:%s" % epsg_override
    else:
        if not ds.GetProjection():
            sys.exit("%s carries no CRS. Give one with --epsg." % path)
        if not srs.IsProjected():
            sys.exit("%s is in a geographic CRS (%s), so its axes are degrees "
                     "and no metric scale bar is possible.\nReproject first, "
                     "e.g. gdalwarp -t_srs EPSG:326xx/327xx in.tif out.tif"
                     % (path, srs.GetName()))
        units = srs.GetLinearUnits()
        if abs(units - 1.0) > 1e-6:
            sys.exit("%s uses %g m map units; this script assumes metres. "
                     "Reproject with gdalwarp." % (path, units))
        code = srs.GetAuthorityCode(None)
        epsg = int(code) if code else None
        label = crs_label_from_srs(srs)
        if epsg is None:
            sys.exit("Cannot resolve an EPSG code for the CRS of %s (%s). "
                     "Pass --epsg." % (path, label))

    raster = ds.GetRasterBand(band)
    data = raster.ReadAsArray().astype(np.float32)

    tokens = []
    fill = raster.GetNoDataValue()
    if fill is not None:
        tokens.append(repr(fill))
    if nodata_arg:
        tokens.extend(nodata_arg.split(","))
    data = apply_nodata(data, tokens, path)
    ds = None
    return Raster(data, x_ul, y_ul, dx, dy, epsg, label, path)


def read_envi(path, hdr_path=None, epsg_override=None, nodata_arg=None):
    """Read an ENVI binary through its header."""
    hdr = read_envi_hdr(hdr_path or find_header(path))
    x_ul, y_ul, dx, dy, epsg, label = geo_from_hdr(hdr, epsg_override)
    data = load_data(path, hdr, nodata_arg)
    return Raster(data, x_ul, y_ul, dx, dy, epsg, label, path)


def read_raster(path, hdr_path=None, band=1, epsg_override=None,
                nodata_arg=None):
    """Read an ENVI pair or a GDAL raster, whichever this file actually is."""
    if hdr_path:
        return read_envi(path, hdr_path, epsg_override, nodata_arg)
    if is_tiff(path):
        return read_gdal(path, band, epsg_override, nodata_arg)
    stem, ext = os.path.splitext(path)
    for cand in (path + ".hdr", stem + ".hdr",
                 stem + "_" + ext.lstrip(".") + ".hdr"):
        if os.path.isfile(cand):
            return read_envi(path, cand, epsg_override, nodata_arg)
    try:                                   # any other format gdal can open
        return read_gdal(path, band, epsg_override, nodata_arg)
    except SystemExit:
        sys.exit("Cannot read %s: no ENVI header was found next to it and gdal "
                 "does not recognise the format.\nFor an ENVI binary, put its "
                 ".hdr beside it or give it with --hdr." % path)


def same_grid(a, b):
    """True when two rasters sit on exactly the same pixel grid."""
    tol = 0.5 * a.dx
    return (a.data.shape == b.data.shape
            and a.epsg == b.epsg
            and abs(a.dx - b.dx) < 1e-6 and abs(a.dy - b.dy) < 1e-6
            and abs(a.x_ul - b.x_ul) < tol and abs(a.y_ul - b.y_ul) < tol)


def describe_grid(r):
    return ("%d x %d, %g m, origin %.1f / %.1f, EPSG %s"
            % (r.data.shape[1], r.data.shape[0], r.dx, r.x_ul, r.y_ul, r.epsg))


def load_coherence(path, reference, hdr_path=None, band=1, nodata=None):
    """Load a coherence raster and insist it is on exactly the reference grid.

    Silently resampling here would hide a real mismatch, so a differing grid
    is an error: put the two on one grid first (Resample_ToGrid.sh). Format is
    irrelevant -- an ENVI rate map can be damped by a GeoTIFF coherence and
    the other way round, as long as the grids agree.
    """
    coh = read_raster(path, hdr_path, band, None, nodata)
    if not same_grid(reference, coh):
        sys.exit("The coherence grid does not match the data grid:\n"
                 "  data      %s\n  coherence %s\n"
                 "Put them on a common grid first (Resample_ToGrid.sh)."
                 % (describe_grid(reference), describe_grid(coh)))
    return coh.data


def coherence_alpha(coh, lo, hi, alpha_max):
    """Map coherence to opacity: <= lo fully transparent, >= hi fully opaque."""
    weight = np.clip((coh - lo) / max(hi - lo, 1e-9), 0.0, 1.0)
    weight = np.where(np.isfinite(coh), weight, 0.0)
    return alpha_max * weight


def valid_bbox(data, margin=0):
    """Row/column slice enclosing the finite pixels, with an optional margin."""
    rows = np.flatnonzero(np.isfinite(data).any(axis=1))
    cols = np.flatnonzero(np.isfinite(data).any(axis=0))
    if rows.size == 0:
        sys.exit("No valid pixel left after nodata masking.")
    r0 = max(rows[0] - margin, 0)
    r1 = min(rows[-1] + 1 + margin, data.shape[0])
    c0 = max(cols[0] - margin, 0)
    c1 = min(cols[-1] + 1 + margin, data.shape[1])
    return slice(r0, r1), slice(c0, c1)


def block_mean(data, factor):
    """Average factor x factor blocks, ignoring NaN. Keeps NaN where all-NaN."""
    if factor <= 1:
        return data
    nl, ns = data.shape
    nl2, ns2 = (nl // factor) * factor, (ns // factor) * factor
    if nl2 == 0 or ns2 == 0:
        return data
    cut = data[:nl2, :ns2].reshape(nl2 // factor, factor, ns2 // factor, factor)
    with np.errstate(invalid="ignore"):
        good = np.isfinite(cut)
        total = np.where(good, cut, 0).sum(axis=(1, 3))
        count = good.sum(axis=(1, 3))
        out = np.where(count > 0, total / np.maximum(count, 1), np.nan)
    return out.astype(np.float32)


# ----------------------------------------------------------------------------
# 3. Background imagery
# ----------------------------------------------------------------------------

TILE_SOURCES = {
    "esri": ("https://server.arcgisonline.com/ArcGIS/rest/services/"
             "World_Imagery/MapServer/tile/{z}/{y}/{x}",
             "Imagery: Esri, Maxar, Earthstar Geographics"),
    "esri-topo": ("https://server.arcgisonline.com/ArcGIS/rest/services/"
                  "World_Topo_Map/MapServer/tile/{z}/{y}/{x}",
                  "Basemap: Esri"),
    "osm": ("https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            "Basemap: (C) OpenStreetMap contributors"),
}
TILE_PX = 256


def lonlat_to_pixel(lon, lat, zoom):
    """Web Mercator global pixel coordinates at a given zoom."""
    n = TILE_PX * 2.0 ** zoom
    lat = np.clip(lat, -85.05112878, 85.05112878)
    x = (lon + 180.0) / 360.0 * n
    s = np.sin(np.radians(lat))
    y = (0.5 - np.log((1 + s) / (1 - s)) / (4 * np.pi)) * n
    return x, y


def lonlat_bounds(transformer, extent, n=64):
    """Geographic bounding box of a UTM rectangle, sampled along its edges."""
    x0, x1, y0, y1 = extent
    xs = np.linspace(x0, x1, n)
    ys = np.linspace(y0, y1, n)
    bx = np.concatenate([xs, xs, np.full(n, x0), np.full(n, x1)])
    by = np.concatenate([np.full(n, y0), np.full(n, y1), ys, ys])
    lon, lat = transformer.transform(bx, by)
    return lon.min(), lon.max(), lat.min(), lat.max()


def warp_to_utm(sampler, transformer, extent, nx, ny, rows_per_chunk=256):
    """Inverse-warp a source image into the UTM grid defined by `extent`.

    `sampler(lon, lat) -> (r, g, b)` does the source-side lookup, so the same
    warping code serves both a tile mosaic and a local image.
    """
    x0, x1, y0, y1 = extent
    xs = x0 + (np.arange(nx) + 0.5) * (x1 - x0) / nx     # pixel centres
    ys = y1 - (np.arange(ny) + 0.5) * (y1 - y0) / ny
    out = np.zeros((ny, nx, 3), dtype=np.uint8)
    for r0 in range(0, ny, rows_per_chunk):              # chunked: flat memory
        r1 = min(r0 + rows_per_chunk, ny)
        gx, gy = np.meshgrid(xs, ys[r0:r1])
        lon, lat = transformer.transform(gx, gy)
        out[r0:r1] = sampler(lon, lat)
    return out


def bilinear(src, u, v):
    """Bilinear lookup into an (H, W, 3) float array at fractional u, v."""
    height, width = src.shape[:2]
    u = np.clip(u, 0, width - 1)
    v = np.clip(v, 0, height - 1)
    u0, v0 = np.floor(u).astype(np.intp), np.floor(v).astype(np.intp)
    u1 = np.minimum(u0 + 1, width - 1)
    v1 = np.minimum(v0 + 1, height - 1)
    fu = (u - u0)[..., None]
    fv = (v - v0)[..., None]
    top = src[v0, u0] * (1 - fu) + src[v0, u1] * fu
    bot = src[v1, u0] * (1 - fu) + src[v1, u1] * fu
    return np.clip(top * (1 - fv) + bot * fv, 0, 255).astype(np.uint8)


class TileBasemap:
    """XYZ tile imagery, re-mosaicked on demand for whatever view is asked for."""

    def __init__(self, source, transformer, cache_dir,
                 zoom_override=None, max_tiles=2000):
        self.url_tpl, self.credit = TILE_SOURCES[source]
        self.source = source
        self.transformer = transformer
        self.cache_dir = cache_dir
        self.zoom_override = zoom_override
        self.max_tiles = max_tiles
        self._mosaic_key = None
        self._mosaic = None
        self._origin = (0, 0)
        self._zoom = 0

    def _zoom_for(self, extent, out_px, lat_mid):
        if self.zoom_override is not None:
            return self.zoom_override
        target = (extent[1] - extent[0]) / float(max(out_px, 1))   # m / pixel
        ground = 156543.03392 * math.cos(math.radians(lat_mid))
        return int(round(math.log2(ground / target)))

    def _tile(self, zoom, tx, ty):
        from PIL import Image
        url = self.url_tpl.format(z=zoom, x=tx, y=ty)
        name = re.sub(r"[^0-9A-Za-z]+", "_", url).strip("_") + ".img"
        path = os.path.join(self.cache_dir, name)
        if not os.path.isfile(path):
            req = urllib.request.Request(
                url, headers={"User-Agent": "Envi2GoogleEarthMap/1.2"})
            blob, last = None, None
            for _ in range(3):
                try:
                    with urllib.request.urlopen(req, timeout=30) as resp:
                        blob = resp.read()
                    break
                except Exception as exc:          # transient network hiccups
                    last = exc
            if blob is None:
                raise RuntimeError("tile %d/%d/%d failed: %s"
                                   % (zoom, tx, ty, last))
            with open(path, "wb") as fh:
                fh.write(blob)
        return np.asarray(Image.open(path).convert("RGB"), dtype=np.uint8)

    def _mosaic_for(self, zoom, lon_min, lon_max, lat_min, lat_max):
        px0, py0 = lonlat_to_pixel(lon_min, lat_max, zoom)
        px1, py1 = lonlat_to_pixel(lon_max, lat_min, zoom)
        tx0, tx1 = int(px0 // TILE_PX), int(px1 // TILE_PX)
        ty0, ty1 = int(py0 // TILE_PX), int(py1 // TILE_PX)
        key = (zoom, tx0, tx1, ty0, ty1)
        if key == self._mosaic_key:
            return                                 # same tiles, nothing to do

        os.makedirs(self.cache_dir, exist_ok=True)
        nx, ny = tx1 - tx0 + 1, ty1 - ty0 + 1
        total = nx * ny
        mosaic = np.zeros((ny * TILE_PX, nx * TILE_PX, 3), dtype=np.uint8)
        sys.stderr.write("Basemap %s: zoom %d, %d tiles\n"
                         % (self.source, zoom, total))
        missing = 0
        for j, ty in enumerate(range(ty0, ty1 + 1)):
            for i, tx in enumerate(range(tx0, tx1 + 1)):
                try:
                    mosaic[j * TILE_PX:(j + 1) * TILE_PX,
                           i * TILE_PX:(i + 1) * TILE_PX] = self._tile(
                               zoom, tx, ty)
                except RuntimeError as exc:
                    missing += 1
                    if missing <= 3:
                        sys.stderr.write("  warning: %s\n" % exc)
        if missing:
            sys.stderr.write("  %d of %d tiles missing\n" % (missing, total))
        self._mosaic_key, self._mosaic = key, mosaic
        self._origin = (tx0 * TILE_PX, ty0 * TILE_PX)
        self._zoom = zoom

    def render(self, extent, nx, ny):
        lon_min, lon_max, lat_min, lat_max = lonlat_bounds(
            self.transformer, extent)
        zoom = self._zoom_for(extent, nx, 0.5 * (lat_min + lat_max))
        zoom = max(0, min(19, zoom))
        while zoom > 0:                            # respect the tile budget
            px0, py0 = lonlat_to_pixel(lon_min, lat_max, zoom)
            px1, py1 = lonlat_to_pixel(lon_max, lat_min, zoom)
            ntiles = ((int(px1 // TILE_PX) - int(px0 // TILE_PX) + 1)
                      * (int(py1 // TILE_PX) - int(py0 // TILE_PX) + 1))
            if ntiles <= self.max_tiles:
                break
            zoom -= 1
        self._mosaic_for(zoom, lon_min, lon_max, lat_min, lat_max)
        src = self._mosaic.astype(np.float32)
        ox, oy = self._origin
        z = self._zoom

        def sample(lon, lat):
            px, py = lonlat_to_pixel(lon, lat, z)
            return bilinear(src, px - ox - 0.5, py - oy - 0.5)

        return warp_to_utm(sample, self.transformer, extent, nx, ny)


class ImageBasemap:
    """A single local image with lon/lat bounds (W, S, E, N)."""

    def __init__(self, path, bounds, transformer):
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = None
        self.src = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
        self.bounds = bounds
        self.transformer = transformer
        self.credit = "Imagery: %s" % os.path.basename(path)

    def render(self, extent, nx, ny):
        height, width = self.src.shape[:2]
        w, s, e, n = self.bounds
        src = self.src

        def sample(lon, lat):
            u = (lon - w) / (e - w) * width - 0.5
            v = (n - lat) / (n - s) * height - 0.5
            return bilinear(src, u, v)

        return warp_to_utm(sample, self.transformer, extent, nx, ny)


def geotiff_bounds(path):
    """Lon/lat bounds of a GeoTIFF, using gdal if it is available."""
    try:
        from osgeo import gdal, osr
    except ImportError:
        sys.exit("Reading a GeoTIFF needs gdal; otherwise give --image-bounds.")
    ds = gdal.Open(path)
    gt = ds.GetGeoTransform()
    nx, ny = ds.RasterXSize, ds.RasterYSize
    corners = [(gt[0], gt[3]), (gt[0] + nx * gt[1], gt[3] + ny * gt[5])]
    src = osr.SpatialReference(wkt=ds.GetProjection())
    dst = osr.SpatialReference()
    dst.ImportFromEPSG(4326)
    dst.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
    tr = osr.CoordinateTransformation(src, dst)
    (w, n, _), (e, s, _) = [tr.TransformPoint(x, y) for x, y in corners]
    return (w, s, e, n)


# ----------------------------------------------------------------------------
# 4. Map decorations
# ----------------------------------------------------------------------------

def utm_frame(ax, crs_label):
    """Ticks on all four sides, labels left and bottom, coordinates in km."""
    from matplotlib.ticker import FuncFormatter, MaxNLocator
    km = FuncFormatter(lambda v, _: "%g" % (v / 1000.0))
    for axis in (ax.xaxis, ax.yaxis):
        axis.set_major_locator(MaxNLocator(nbins=6, steps=[1, 2, 2.5, 5, 10]))
        axis.set_major_formatter(km)
    ax.tick_params(which="major", direction="in", length=6, width=1.0,
                   top=True, bottom=True, left=True, right=True,
                   labeltop=False, labelright=False)
    ax.tick_params(which="minor", direction="in", length=3, width=0.7,
                   top=True, bottom=True, left=True, right=True)
    ax.minorticks_on()
    for spine in ax.spines.values():
        spine.set_linewidth(1.2)
        spine.set_zorder(5)
    ax.set_xlabel("Easting (km) -- %s" % crs_label)
    ax.set_ylabel("Northing (km)")


def nice_length(span):
    """A round scale-bar length, closest to a quarter of the map width.

    Only 1/2/5/10 x 10**n are allowed so halves and quarters of the bar are
    round numbers too -- those are what the intermediate ticks are labelled with.
    """
    raw = max(span, 1e-6) / 4.0
    power = 10.0 ** math.floor(math.log10(raw))
    options = [step * power for step in (1, 2, 5, 10)]
    return min(options, key=lambda v: abs(math.log(v / raw)))


def scale_bar(ax, extent, frac_x=0.06, frac_y=0.055, height_frac=0.010):
    """Alternating black/white bar with labelled ends. Returns its artists."""
    from matplotlib.patches import Rectangle
    x0, x1, y0, y1 = extent
    span_x, span_y = x1 - x0, y1 - y0
    length = nice_length(span_x)
    n_seg = 4
    bx = x0 + frac_x * span_x
    by = y0 + frac_y * span_y
    bh = height_frac * span_y

    artists = []
    for k in range(n_seg):
        patch = Rectangle((bx + k * length / n_seg, by), length / n_seg, bh,
                          facecolor="k" if k % 2 == 0 else "w",
                          edgecolor="k", linewidth=0.8, zorder=6)
        ax.add_patch(patch)
        artists.append(patch)
    unit = "km" if length >= 1000 else "m"
    for frac in (0.0, 0.5, 1.0):
        val = length * frac
        txt = "%g" % (val / 1000.0 if unit == "km" else val)
        if frac == 1.0:
            txt += " " + unit
        artists.append(ax.text(bx + frac * length, by + 1.6 * bh, txt,
                               ha="center", va="bottom", fontsize=8,
                               zorder=7, path_effects=halo()))
    return artists


def north_arrow(ax, extent, frac_x=0.94, frac_y=0.885):
    """Grid-north arrow. Returns its artists."""
    x0, x1, y0, y1 = extent
    x = x0 + frac_x * (x1 - x0)
    y = y0 + frac_y * (y1 - y0)
    dy = 0.055 * (y1 - y0)
    arrow = ax.annotate("", xy=(x, y + dy), xytext=(x, y), zorder=7,
                        arrowprops=dict(facecolor="w", edgecolor="k",
                                        width=3.0, headwidth=11,
                                        headlength=10, linewidth=0.8))
    label = ax.text(x, y + 1.20 * dy, "N", ha="center", va="bottom",
                    fontsize=10, fontweight="bold", zorder=7,
                    path_effects=halo())
    return [arrow, label]


# ----------------------------------------------------------------------------
# 5. The map itself
# ----------------------------------------------------------------------------

class MapView:
    """Holds the full-resolution data and rebuilds the view on demand.

    Every refresh re-derives both layers for the *current* axes limits: the
    overlay is block-averaged straight from the full-resolution array, and the
    background is re-warped (and re-tiled, at a zoom suited to the new scale)
    rather than magnified. That is what makes zooming reveal more detail
    instead of bigger pixels.
    """

    def __init__(self, data, x_ul, y_ul, dx, dy, basemap, cmap,
                 vmin, vmax, alpha, crs_label, full_res=False,
                 coherence=None, coh_range=(0.2, 0.7)):
        self.data = data
        self.coherence = coherence
        self.coh_range = coh_range
        self.x_ul, self.y_ul, self.dx, self.dy = x_ul, y_ul, dx, dy
        self.basemap = basemap
        self.alpha = alpha
        self.full_res = full_res
        self.crs_label = crs_label
        nl, ns = data.shape
        self.full_extent = (x_ul, x_ul + ns * dx, y_ul - nl * dy, y_ul)

        self.cmap = get_cmap(cmap).copy()
        self.cmap.set_bad(alpha=0.0)               # nodata stays transparent
        self.vmin, self.vmax = vmin, vmax

        self.fig = self.ax = None
        self.bg_artist = self.data_artist = None
        self._deco = []
        self._timer = None
        self._busy = False

    # -- layer construction --------------------------------------------------

    def target_px(self, scale=1.0):
        """Horizontal pixel budget of the axes, optionally scaled for saving."""
        try:
            width = self.ax.get_window_extent().width
        except Exception:
            width = 900.0
        return max(64, int(width * scale))

    def data_for(self, extent, target_px):
        """Block-average the full-res data over `extent` to ~target_px wide."""
        x0, x1, y0, y1 = extent
        nl, ns = self.data.shape
        c0 = int(np.clip(np.floor((x0 - self.x_ul) / self.dx), 0, ns - 1))
        c1 = int(np.clip(np.ceil((x1 - self.x_ul) / self.dx), c0 + 1, ns))
        r0 = int(np.clip(np.floor((self.y_ul - y1) / self.dy), 0, nl - 1))
        r1 = int(np.clip(np.ceil((self.y_ul - y0) / self.dy), r0 + 1, nl))
        sub = self.data[r0:r1, c0:c1]

        factor = 1 if self.full_res else max(1, (c1 - c0) // target_px)
        out = block_mean(sub, factor)
        # the coherence must go through the identical averaging, or the
        # opacity would stop lining up with the values it is damping
        coh = (block_mean(self.coherence[r0:r1, c0:c1], factor)
               if self.coherence is not None else None)
        # block_mean truncates to whole blocks: report the extent it really covers
        used_l, used_s = out.shape[0] * factor, out.shape[1] * factor
        sub_extent = (self.x_ul + c0 * self.dx,
                      self.x_ul + (c0 + used_s) * self.dx,
                      self.y_ul - (r0 + used_l) * self.dy,
                      self.y_ul - r0 * self.dy)
        return out, coh, sub_extent

    # -- figure --------------------------------------------------------------

    def build(self, fig_w, fig_h, title, label, unit, extend="both"):
        # constrained layout re-solves on every draw: with aspect="equal" the
        # axes box changes shape at each zoom, which a one-off
        # tight_layout() cannot follow (clipped axis labels).
        self.fig, self.ax = plt.subplots(figsize=(fig_w, fig_h),
                                         layout="constrained")
        ax = self.ax
        ax.set_facecolor("0.85")
        ax.set_xlim(self.full_extent[0], self.full_extent[1])
        ax.set_ylim(self.full_extent[2], self.full_extent[3])
        ax.set_aspect("equal")

        self.bg_artist = ax.imshow(
            np.zeros((1, 1, 3), np.uint8), extent=self.full_extent,
            origin="upper", interpolation="bilinear", zorder=1)
        self.bg_artist.set_visible(False)
        self.data_artist = ax.imshow(
            np.ma.masked_invalid(np.zeros((1, 1), np.float32)),
            extent=self.full_extent, origin="upper", cmap=self.cmap,
            vmin=self.vmin, vmax=self.vmax, alpha=self.alpha,
            interpolation="nearest", zorder=2)

        utm_frame(ax, self.crs_label)
        if title:
            ax.set_title(title)

        cbar = self.fig.colorbar(self.data_artist, ax=ax, fraction=0.045,
                                 pad=0.03, extend=extend, shrink=0.85)
        cbar.set_label("%s [%s]" % (label, unit) if unit else label)
        cbar.solids.set_alpha(1.0)

        credit = getattr(self.basemap, "credit", None)
        if credit:
            ax.text(0.995, 0.005, credit, transform=ax.transAxes, ha="right",
                    va="bottom", fontsize=6.5, zorder=7,
                    path_effects=halo(1.6))
        return self.fig

    def refresh(self, scale=1.0):
        """Rebuild both layers and the decorations for the current view."""
        if self._busy:
            return
        self._busy = True
        try:
            ax = self.ax
            x0, x1 = sorted(ax.get_xlim())
            y0, y1 = sorted(ax.get_ylim())
            extent = (x0, x1, y0, y1)
            nx = self.target_px(scale)
            ny = max(1, int(round(nx * (y1 - y0) / (x1 - x0))))

            block, coh, block_extent = self.data_for(extent, nx)
            self.data_artist.set_data(np.ma.masked_invalid(block))
            self.data_artist.set_extent(block_extent)
            if coh is not None:
                opacity = coherence_alpha(coh, self.coh_range[0],
                                          self.coh_range[1], self.alpha)
                self.data_artist.set_alpha(
                    np.where(np.isfinite(block), opacity, 0.0))

            if self.basemap is not None:
                self.bg_artist.set_data(self.basemap.render(extent, nx, ny))
                self.bg_artist.set_extent(extent)
                self.bg_artist.set_visible(True)

            for artist in self._deco:
                artist.remove()
            self._deco = scale_bar(ax, extent) + north_arrow(ax, extent)

            # set_extent nudges the limits: put them back (guarded by _busy)
            ax.set_xlim(x0, x1)
            ax.set_ylim(y0, y1)
        finally:
            self._busy = False

    # -- interactivity -------------------------------------------------------

    def connect(self, debounce_ms=400):
        """Redraw once the view settles, so dragging does not fetch tiles."""
        self._timer = self.fig.canvas.new_timer(interval=debounce_ms)
        self._timer.single_shot = True
        self._timer.add_callback(self._on_settled)

        def on_limits_changed(_ax):
            if self._busy:
                return
            self._timer.stop()
            self._timer.start()

        self.ax.callbacks.connect("xlim_changed", on_limits_changed)
        self.ax.callbacks.connect("ylim_changed", on_limits_changed)

    def _on_settled(self):
        try:
            self.refresh()
            self.fig.canvas.draw_idle()
        except Exception as exc:                   # never kill the GUI loop
            sys.stderr.write("Refresh failed: %s\n" % exc)


# ----------------------------------------------------------------------------
# 6. Main
# ----------------------------------------------------------------------------

def parse_args(argv):
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("files", nargs="*", metavar="INPUT [OUTPUT]",
                   help="the geocoded raster to map -- an ENVI binary (with "
                        "its .hdr) or a GeoTIFF, recognised automatically -- "
                        "and optionally the output figure, whose extension "
                        "sets the format (png, pdf, svg, eps, jpg...). The "
                        "input may be omitted if --coherence is given, to map "
                        "the coherence itself; the output defaults to "
                        "<input>.png.")
    p.add_argument("-o", "--output", dest="output_opt", default=None,
                   help="same as the second parameter, and takes precedence "
                        "over it")
    p.add_argument("--hdr", help="ENVI header, if not next to the binary "
                                 "(ignored for a GeoTIFF)")
    p.add_argument("--band", type=int, default=1,
                   help="band to map in a multi-band GeoTIFF (default 1)")
    p.add_argument("--epsg", help="override the CRS from 'map info'")

    p.add_argument("--nodata", default=None,
                   help="optional: extra no-data value(s), comma separated, "
                        "e.g. --nodata 0 or --nodata 0,-9999. NaN and the "
                        "header's 'data ignore value' always apply.")
    p.add_argument("--no-crop", action="store_true",
                   help="keep the full grid instead of cropping to valid data")
    p.add_argument("--margin", type=int, default=20,
                   help="pixels of margin kept around the data (default 20)")

    p.add_argument("--unit", default=None,
                   help="unit on the colour scale; default is deduced from the "
                        "file name (m/yr for a LINEAR RATE product, else m)")
    p.add_argument("--label", default=None,
                   help="colour scale title; default is deduced from the file "
                        "name, e.g. 'LOS velocity' or 'Vertical displacement'")
    p.add_argument("--title", default=None,
                   help="optional figure title; nothing is drawn without it")
    p.add_argument("--kind", default="auto",
                   choices=("auto", "rate", "deformation", "coherence"),
                   help="what the raster holds; deduced from the file name by "
                        "default. 'coherence' fixes the scale to greyscale 0-1.")
    p.add_argument("--cmap", default=None,
                   help="colour scale: vik (default) or vik-balanced from the\nScientific colour maps, or any matplotlib name; add -r to reverse")
    p.add_argument("--clim", nargs=2, type=float, metavar=("MIN", "MAX"),
                   help="fixed colour limits")
    p.add_argument("--pct", nargs=2, type=float, default=(2.0, 98.0),
                   metavar=("LO", "HI"),
                   help="percentiles used when --clim is absent (2 98)")
    p.add_argument("--asymmetric", action="store_true",
                   help="do not force the colour scale to be symmetric about 0")
    p.add_argument("--alpha", type=float, default=0.75,
                   help="overlay opacity, 0-1 (default 0.75). With --coherence "
                        "this is the opacity reached at full coherence.")

    p.add_argument("--coherence",
                   help="optional coherence raster on the same grid; the "
                        "overlay is damped pixel by pixel where coherence is "
                        "low, so poorly constrained areas fade into the "
                        "background instead of being read as signal")
    p.add_argument("--coh-range", nargs=2, type=float, default=(0.2, 0.7),
                   metavar=("LO", "HI"),
                   help="coherence mapped to opacity: <=LO invisible, >=HI "
                        "fully opaque (default 0.2 0.7)")
    p.add_argument("--coh-nodata", default=None,
                   help="extra no-data value(s) for the coherence raster")
    p.add_argument("--coh-hdr",
                   help="ENVI header of the coherence, if not beside it")
    p.add_argument("--coh-band", type=int, default=1,
                   help="band to use in a multi-band coherence GeoTIFF")

    p.add_argument("--basemap", default="esri",
                   choices=sorted(TILE_SOURCES) + ["none"],
                   help="imagery source (default esri)")
    p.add_argument("--local-image",
                   help="use this image as background (GeoTIFF, or any image "
                        "together with --image-bounds)")
    p.add_argument("--image-bounds", nargs=4, type=float,
                   metavar=("W", "S", "E", "N"),
                   help="lon/lat bounds of --local-image")
    p.add_argument("--zoom", type=int, help="force the tile zoom level")
    p.add_argument("--tile-cache",
                   default=os.path.expanduser("~/.cache/Envi2GoogleEarthMap_tiles"),
                   help="tile cache directory")
    p.add_argument("--credit", help="override the imagery credit line")

    p.add_argument("-i", "--interactive", action="store_true",
                   help="open a pan/zoom window; the figure is written when "
                        "the window is closed")
    p.add_argument("--no-save", action="store_true",
                   help="with -i, explore only and write nothing")
    p.add_argument("--width", type=float, default=9.0,
                   help="figure width in inches (default 9)")
    p.add_argument("--max-height", type=float, default=10.5,
                   help="cap the figure height in inches; the width is reduced "
                        "to keep the scene proportions (default 10.5)")
    p.add_argument("--dpi", type=int, default=200, help="output dpi")
    p.add_argument("--full-res", action="store_true",
                   help="plot every data pixel instead of block-averaging to "
                        "the figure resolution")
    p.add_argument("--pdf", action="store_true", help="also write a PDF")
    # argparse matches positionals in contiguous chunks, so
    # "in.bin --nodata 0 out.png" leaves the second positional unplaceable and
    # is rejected outright. Collecting the leftovers ourselves makes the
    # parameters order-independent, which is what anyone typing a long command
    # line will expect.
    args, extra = p.parse_known_args(argv)
    stray_options = [a for a in extra if a.startswith("-") and a != "-"]
    if stray_options:
        p.error("unrecognized arguments: %s" % " ".join(stray_options))
    args.files = list(args.files) + [a for a in extra if a not in stray_options]

    if len(args.files) > 2:
        p.error("expected at most an input and an output, got: %s"
                % " ".join(args.files))
    args.binary = args.files[0] if args.files else None
    args.output = args.files[1] if len(args.files) > 1 else None
    return args


def resolve_output(binary, positional, option):
    """Work out where the figure goes and check the format is supported.

    The output can be given as the second parameter or with -o/--output, the
    option winning. Its extension selects the format, so no separate format
    flag is needed; an unknown extension is refused rather than silently
    written as a PNG under a misleading name.
    """
    out = option or positional
    if not out:
        return os.path.splitext(binary)[0] + ".png"
    if os.path.isdir(out):                      # a directory: keep the stem
        stem = os.path.basename(os.path.splitext(binary)[0])
        return os.path.join(out, stem + ".png")
    ext = os.path.splitext(out)[1].lstrip(".").lower()
    if not ext:
        return out + ".png"
    # a throwaway figure is the only reliable way to ask the *active* backend
    # what it can write; it costs about a millisecond
    probe = plt.figure()
    supported = sorted(probe.canvas.get_supported_filetypes())
    plt.close(probe)
    if ext not in supported:
        sys.exit("Cannot write '%s': unknown figure format '%s'.\n"
                 "Supported here: %s" % (out, ext, ", ".join(supported)))
    parent = os.path.dirname(os.path.abspath(out))
    if not os.path.isdir(parent):
        sys.exit("Cannot write '%s': %s does not exist." % (out, parent))
    return out


def main(argv=None):
    args = parse_args(argv)
    sys.stderr.write("\n%s %s, %s\n" % (PRG, VER, AUT))
    sys.stderr.write("Processing launched on %s\n\n"
                     % time.strftime("%a %b %d %H:%M:%S %Z %Y"))
    has_gui = setup_backend(args.interactive)

    # A coherence file on its own is a legitimate product to map, so allow it
    # to be passed either as the plain input or through --coherence with no
    # input at all. Damping a raster by itself is meaningless, so in that case
    # the coherence becomes the data and the damping is dropped.
    if args.binary is None:
        if not args.coherence:
            sys.exit("Nothing to map: give an ENVI binary, or --coherence "
                     "alone to map a coherence raster.")
        args.binary, args.coherence = args.coherence, None
    elif args.coherence and os.path.realpath(args.coherence) == \
            os.path.realpath(args.binary):
        sys.stderr.write("--coherence is the file being mapped: damping it by "
                         "itself would be meaningless, ignoring it.\n")
        args.coherence = None

    out = resolve_output(args.binary, args.output, args.output_opt)
    try:
        import pyproj
    except ImportError:
        sys.exit("pyproj is required (pip install pyproj).")

    raster = read_raster(args.binary, args.hdr, args.band, args.epsg,
                         args.nodata)
    x_ul, y_ul, dx, dy = raster.x_ul, raster.y_ul, raster.dx, raster.dy
    epsg, crs_label = raster.epsg, raster.crs_label

    label, unit, kind = describe_product(args.binary, args.label, args.unit,
                                         args.kind)
    is_coherence = (kind == "coherence")
    cmap_name = args.cmap or ("gray" if is_coherence else "vik")

    data = raster.data
    suggest_nodata(data, fixed_scale=is_coherence)

    coherence = None
    if args.coherence:
        coherence = load_coherence(args.coherence, raster, args.coh_hdr,
                                   args.coh_band, args.coh_nodata)

    # --- geometry -----------------------------------------------------------
    if args.no_crop:
        rows, cols = slice(0, data.shape[0]), slice(0, data.shape[1])
    else:
        rows, cols = valid_bbox(data, margin=args.margin)
    data = np.ascontiguousarray(data[rows, cols])
    if coherence is not None:
        coherence = np.ascontiguousarray(coherence[rows, cols])
    x_ul += cols.start * dx
    y_ul -= rows.start * dy
    aspect = (data.shape[0] * dy) / (data.shape[1] * dx)

    fig_w = args.width
    fig_h = max(3.0, fig_w * aspect)
    if args.max_height and fig_h > args.max_height:
        fig_w *= args.max_height / fig_h
        fig_h = args.max_height

    # --- colour limits (fixed once, so zooming does not move the scale) -----
    finite = data[np.isfinite(data)]
    if finite.size == 0:
        sys.exit("Nothing left to plot.")
    if args.clim:
        vmin, vmax = args.clim
    elif is_coherence:
        # coherence is bounded and absolute: percentiles would stretch the
        # scale differently for every scene and make maps incomparable
        vmin, vmax = 0.0, 1.0
    else:
        vmin, vmax = np.percentile(finite, args.pct)
        if not args.asymmetric:
            vmax = max(abs(vmin), abs(vmax))
            vmin = -vmax
    # the colorbar arrows must state a fact: they mean "values continue past
    # this end". On a bounded quantity such as coherence clipped to 0-1 an
    # arrow would claim values that cannot exist.
    below = bool(finite.min() < vmin - 1e-12)
    above = bool(finite.max() > vmax + 1e-12)
    extend = {(True, True): "both", (True, False): "min",
              (False, True): "max", (False, False): "neither"}[(below, above)]
    del finite

    # --- background ---------------------------------------------------------
    to_wgs84 = pyproj.Transformer.from_crs(epsg, 4326, always_xy=True)
    basemap = None
    if args.local_image:
        bounds = args.image_bounds
        if bounds is None:
            bounds = geotiff_bounds(args.local_image)
            sys.stderr.write("GeoTIFF bounds: %.5f %.5f %.5f %.5f\n" % bounds)
        basemap = ImageBasemap(args.local_image, bounds, to_wgs84)
    elif args.basemap != "none":
        basemap = TileBasemap(args.basemap, to_wgs84, args.tile_cache,
                              args.zoom)
    if basemap is not None and args.credit:
        basemap.credit = args.credit

    # --- draw ---------------------------------------------------------------
    view = MapView(data, x_ul, y_ul, dx, dy, basemap, cmap_name,
                   vmin, vmax, args.alpha, crs_label, args.full_res,
                   coherence, tuple(args.coh_range))
    fig = view.build(fig_w, fig_h, args.title, label, unit, extend)
    view.refresh()

    if args.interactive and has_gui:
        view.connect()
        if args.no_save:
            sys.stderr.write("Pan and zoom with the toolbar. "
                             "Nothing will be written (--no-save).\n")
        else:
            sys.stderr.write("Pan and zoom with the toolbar. "
                             "Close the window to write %s\n" % out)
        plt.show()                                 # returns once closed
        if args.no_save:
            return
        # the screen may be coarser than --dpi: rebuild at the saving resolution
        view.refresh(scale=float(args.dpi) / fig.dpi)

    fig.savefig(out, dpi=args.dpi)
    sys.stderr.write("Wrote %s\n" % out)
    if args.pdf and not out.lower().endswith(".pdf"):
        pdf = os.path.splitext(out)[0] + ".pdf"
        fig.savefig(pdf)
        sys.stderr.write("Wrote %s\n" % pdf)
    plt.close(fig)


if __name__ == "__main__":
    main()
