#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script drapes an ENVI raster (unwrapped interferogram, deformation map, ...) on
#  a DEM and modulates its opacity with the interferometric coherence:
#	- where coherence is high, the colour of the deformation is fully opaque,
#	- where coherence is low, it fades out and lets the shaded relief show through.
#
# Two renderings are available (--mode) :
#	drape	shaded-relief map seen from above (2.5D), with colour bars		[default]
#	3d	perspective view of the DEM surface painted with the deformation
#	both	the two of them
#
# With -i, the 3D view is first opened in a window where it can be rotated, zoomed and
#  vertically exaggerated with the mouse and the keyboard; the image is saved as seen when
#  the window is closed, and the corresponding options are echoed to re-create the same
#  view later without the window (e.g. in a mass processing).
#
# The deformation, the coherence and the DEM do not need to share the same grid nor the
#  same projection: everything is resampled on the grid of the deformation map with
#  gdalwarp. Geocoded products in UTM (meters) or in Lat/Long (dd) are both accepted.
#
# The DEM may be provided either as
#	- an ENVI file (i.e. a binary file with its .hdr header), or
#	- the AMSTer/CSL DEM header (DEM.txt): the matching ENVI .hdr is then created on
#	  the fly by DEM_AMSTer_txt2Envi_hdr.sh, which must be in the PATH.
#
# Parameters:	- path to the ENVI deformation map or unwrapped interferogram
#		- path to the DEM (ENVI binary, or its AMSTer DEM.txt header)
#
# Main options (see --help for all of them):
#		-i, --interactive     open the 3D view in a window to rotate, zoom and exaggerate it; the figure is saved when the window is closed (default: False)
#		-c FILE		ENVI coherence file driving the transparency
#		-o FILE		output image (default: <data file>_onDEM.png)
#		--mode M	drape | 3d | both
#		--vmin/--vmax	colour scale limits (default: --pct percentiles)
#		--pct PCT             percentile clipped at each end when vmin/vmax are not given (default: 2.0)
#		--wrap CYCLE	display the data modulo CYCLE (fringes)
#		--coh-min/--coh-max	coherence values mapped to fully transparent /
#					fully opaque
#		--zexag		vertical exaggeration of the relief
#
# More options:
#		-h, --help            show this help message and exit
#		--cmap CMAP           matplotlib colour map [jet, or hsv if --wrap] (default: None)
#		--sym                 symmetric colour scale centred on zero (default: False)
#		--scale SCALE         factor applied to the data, e.g. 100 to plot meters in cm (default: 1.0)
#		--unit UNIT           label of the colour bar (default: )
#		--wrap WRAP           display the data modulo CYCLE (fringes), after --scale (default: None)
#		--coh-min COH_MIN     coherence mapped to fully transparent (default: 0.15)
#		--coh-max COH_MAX     coherence mapped to fully opaque (default: 0.6)
#		--coh-gamma COH_GAMMA
#		                      curvature of the opacity ramp (>1 favours opacity) (default: 1.0)
#		--alpha-min ALPHA_MIN
#		                      minimum opacity, to keep a hint of colour everywhere (default: 0.0)
#		--az AZ               sun azimuth [deg] (default: 315.0)
#		--alt ALT             sun elevation [deg] (default: 45.0)
#		--blend {soft,overlay,hsv}
#		                      how the relief shades the colours (default: soft)
#		--contour CONTOUR     elevation contour interval [m], 0 to skip (default: 0.0)
#		--elev ELEV           3D view elevation [deg] (default: 40.0)
#		--azim AZIM           3D view azimuth [deg] (default: -70.0)
#		--zexag3d ZEXAG3D     vertical exaggeration of the 3D surface (default: 3.0)
#		--max3d MAX3D         largest dimension of the 3D surface, decimated if needed (default: 500)
#		--dem-resampling DEM_RESAMPLING
#		                      gdalwarp method for the DEM (default: cubic)
#		--coh-resampling COH_RESAMPLING
#		                      gdalwarp method for the coherence (default: bilinear)
#		--title TITLE         title of the figure [name of the data file] (default: None)
#		--dpi DPI
#		--keep-tmp            keep the resampled intermediate files (default: False)
#
# Examples:
#	# deformation map in meters plotted in cm, faded below 0.3 coherence:
#	Plot_Envi_on_DEM.py deformationMap_...Head253.4deg ${EXTERNAL_DEMS_DIR}/MyDEM.txt \
#		-c coherence_...Head253.4deg --scale 100 --unit "LOS displ. [cm]" \
#		--coh-min 0.3 --coh-max 0.7
#
#	# wrapped fringes (one cycle per 2.8 cm), viewpoint chosen in the 3D window:
#	Plot_Envi_on_DEM.py deformationMap_...Head253.4deg MyDEM -c coherence_...Head253.4deg \
#		--wrap 0.028 --mode 3d -i
#
#	# unwrapped interferogram in radians, symmetric colour scale:
#	Plot_Envi_on_DEM.py unwrappedPhase_...deg MyDEM -c coherence_...deg \
#		--sym --unit "[rad]" --mode both
#
# Dependencies:	- gdalwarp and gdalsrsinfo (GDAL binaries)
#		- python with numpy and matplotlib (AMSTer python environment)
#		- DEM_AMSTer_txt2Envi_hdr.sh, only if the DEM is given as DEM.txt
#
# New in Distro V 1.0 20260903:	- creation
# New in Distro V 1.1 20260903:	- interactive 3D view (-i): rotate, zoom and change the
#				  vertical exaggeration before saving the figure
# New in Distro V 1.2 20260909:	- the ENVI header built from an AMSTer DEM.txt is kept in
#				  the temporary directory instead of beside the DEM, which
#				  must not be described by a .txt and a .hdr at the same time
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LightSource, Normalize
from matplotlib.ticker import MaxNLocator

PRG = os.path.basename(sys.argv[0])
VER = "Distro V1.2 AMSTer script utilities"
AUT = "Nicolas d'Oreye, (c)2016-2026, Last modified on Sep 09, 2026"

# ENVI "data type" -> numpy type
ENVI_DTYPES = {1: "u1", 2: "i2", 3: "i4", 4: "f4", 5: "f8",
               12: "u2", 13: "u4", 14: "i8", 15: "u8"}


def die(msg):
	sys.exit("%s: ERROR - %s" % (PRG, msg))


# -----------------------------------------------------------------------------------------
# ENVI headers
# -----------------------------------------------------------------------------------------
def hdr_candidates(datafile):
	"""Return the possible names of the ENVI header of datafile.

	AMSTer names the header after the data file, sometimes with the dots of the
	file name replaced by underscores (e.g. ...Head253.4deg -> ...Head253_4deg.hdr).
	"""
	base = os.path.basename(datafile)
	candidates = []
	for name in (datafile + ".hdr",
	             os.path.join(os.path.dirname(datafile), base.replace(".", "_") + ".hdr"),
	             os.path.splitext(datafile)[0] + ".hdr"):
		if name not in candidates:
			candidates.append(name)
	return candidates


def find_hdr(datafile, mandatory=True):
	"""Return the ENVI header of datafile, or None if there is none and mandatory is False."""
	candidates = hdr_candidates(datafile)
	for hdr in candidates:
		if os.path.isfile(hdr):
			return hdr
	if mandatory:
		die("no ENVI header found for %s (looked for %s)"
		    % (datafile, ", ".join(candidates)))
	return None


def parse_envi_hdr(hdrfile):
	"""Return the header entries as a dict of lower case keys."""
	entries = {}
	buf = ""
	with open(hdrfile, "r", errors="replace") as f:
		for line in f:
			line = line.strip()
			buf = (buf + " " + line) if buf else line
			if buf.count("{") > buf.count("}"):
				continue			# value continues on next line
			if "=" in buf:
				key, val = buf.split("=", 1)
				entries[key.strip().lower()] = val.strip().strip("{}").strip()
			buf = ""
	return entries


class Raster(object):
	"""A single band ENVI raster with its grid."""

	def __init__(self, datafile):
		self.path = datafile
		self.hdr = find_hdr(datafile)
		e = parse_envi_hdr(self.hdr)

		self.nx = int(float(e["samples"]))
		self.ny = int(float(e["lines"]))
		self.offset = int(float(e.get("header offset", 0)))
		dtype = int(float(e["data type"]))
		if dtype not in ENVI_DTYPES:
			die("ENVI data type %d not handled (%s)" % (dtype, self.hdr))
		endian = "<" if int(float(e.get("byte order", 0))) == 0 else ">"
		self.dtype = np.dtype(endian + ENVI_DTYPES[dtype])
		self.description = e.get("description", "")

		nodata = e.get("data ignore value", "")
		try:
			self.nodata = float(nodata)		# "NAN" gives nan, which is fine
		except ValueError:
			self.nodata = None

		if "map info" not in e:
			die("no 'map info' in %s - the file must be geocoded" % self.hdr)
		mi = [t.strip() for t in e["map info"].split(",")]
		refx, refy = float(mi[1]), float(mi[2])
		x0, y0 = float(mi[3]), float(mi[4])
		dx, dy = float(mi[5]), float(mi[6])
		# Corner of the first pixel + GDAL-like geotransform. A negative latitude step
		# (AMSTer DEM in mathematical line order) simply gives a South-up raster.
		self.x0 = x0 - (refx - 1.0) * dx
		self.y0 = y0 + (refy - 1.0) * dy
		self.dx = dx
		self.dy = -dy
		# GDAL does not always write "units=Degrees", so also look at the projection name
		projection = mi[0].lower()
		self.geographic = ("geographic" in projection
		                   or "lat/lon" in projection.replace(" ", "")
		                   or any("degree" in t.lower() for t in mi))

	@property
	def extent(self):
		"""(xmin, ymin, xmax, ymax) of the grid."""
		x1 = self.x0 + self.nx * self.dx
		y1 = self.y0 + self.ny * self.dy
		return (min(self.x0, x1), min(self.y0, y1), max(self.x0, x1), max(self.y0, y1))

	def same_grid_as(self, other, tol=1e-6):
		return (self.nx == other.nx and self.ny == other.ny
		        and abs(self.dx - other.dx) < tol and abs(self.dy - other.dy) < tol
		        and abs(self.x0 - other.x0) < abs(self.dx) * 1e-3
		        and abs(self.y0 - other.y0) < abs(self.dy) * 1e-3)

	def gdal_path(self, tmpdir):
		"""Return a path where GDAL is able to find the header of this raster.

		GDAL only looks for <file>.hdr and <file without extension>.hdr, while AMSTer
		may name the header with the dots of the data file replaced by underscores
		(...Head253.4deg -> ...Head253_4deg.hdr). In that case both files are linked
		in the temporary directory under names GDAL does associate.
		"""
		if self.hdr == self.path + ".hdr":
			return self.path
		link = os.path.join(tmpdir, os.path.basename(self.path).replace(".", "_"))
		if not os.path.exists(link):
			os.symlink(os.path.abspath(self.path), link)
			os.symlink(os.path.abspath(self.hdr), link + ".hdr")
		return link

	def read(self):
		"""Read the band as float32, North-up, with the ignore value set to NaN."""
		expected = self.nx * self.ny
		data = np.fromfile(self.path, dtype=self.dtype, count=expected,
		                   offset=self.offset)
		if data.size != expected:
			die("%s holds %d values instead of %d x %d - check the header"
			    % (self.path, data.size, self.nx, self.ny))
		data = data.reshape(self.ny, self.nx).astype("f4")
		if self.dy > 0:					# South-up raster
			data = np.flipud(data)
		if self.nodata is not None and not np.isnan(self.nodata):
			data[data == self.nodata] = np.nan
		return data

	def pixel_size_meters(self):
		"""Pixel size in meters, needed to shade the relief consistently."""
		if not self.geographic:
			return abs(self.dx), abs(self.dy)
		ymid = self.y0 + 0.5 * self.ny * self.dy
		return (abs(self.dx) * 111320.0 * np.cos(np.radians(ymid)),
		        abs(self.dy) * 110540.0)


# -----------------------------------------------------------------------------------------
# Resampling on the grid of the deformation map
# -----------------------------------------------------------------------------------------
def dem_envi_from_txt(demtxt, tmpdir):
	"""Return an ENVI readable DEM (a binary having a .hdr) for an AMSTer DEM.txt.

	The ENVI header is built in tmpdir, beside a symbolic link to the DEM binary, and
	is thrown away with tmpdir at the end of the run. The directory of the original DEM
	is left untouched: a DEM must not be described by both an AMSTer .txt header and an
	ENVI .hdr, as AMSTer tools reading that directory could then pick the wrong one -
	and a stale .hdr would silently outlive any later edit of the .txt.

	A .hdr already sitting next to the DEM is the user's own and is used as it is.
	"""
	dem = demtxt[:-4]
	if not os.path.isfile(dem):
		die("%s does not exist - the DEM binary must sit next to its .txt header" % dem)
	existing = find_hdr(dem, mandatory=False)
	if existing:
		return dem
	if shutil.which("DEM_AMSTer_txt2Envi_hdr.sh") is None:
		die("no ENVI header for %s and DEM_AMSTer_txt2Envi_hdr.sh is not in the PATH - "
		    "convert the DEM header first" % dem)
	print("Creating a temporary ENVI header of the DEM from %s" % demtxt)
	link = os.path.join(tmpdir, os.path.basename(dem))
	os.symlink(os.path.abspath(dem), link)		# the binary is not copied: it is large
	shutil.copy2(demtxt, link + ".txt")
	run(["DEM_AMSTer_txt2Envi_hdr.sh", link + ".txt"])
	stray = find_hdr(dem, mandatory=False)
	if stray:					# written next to the original after all
		shutil.move(stray, link + ".hdr")
	if find_hdr(link, mandatory=False) is None:
		die("DEM_AMSTer_txt2Envi_hdr.sh did not create the ENVI header of %s" % dem)
	return link


def enable_gui_backend():
	"""Switch matplotlib to a GUI backend, so that a figure can be manipulated.

	Returns False when no window can be opened (no display, no GUI backend built in
	the python environment): the figure is then simply written without being shown.
	"""
	if sys.platform == "darwin":
		candidates = ["macosx", "QtAgg", "TkAgg"]
	else:
		candidates = ["QtAgg", "TkAgg"]
		if not (os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY")):
			print("WARNING: no graphical display - the 3D view cannot be manipulated")
			return False
	for backend in candidates:
		try:
			plt.switch_backend(backend)
			return True
		except Exception:
			continue
	print("WARNING: none of the %s matplotlib backends is available - the 3D view "
	      "cannot be manipulated" % ", ".join(candidates))
	return False


def save_figure(fig, name, dpi):
	"""Write the figure, whatever backend it was created with."""
	try:
		fig.savefig(name, dpi=dpi, bbox_inches="tight")
	except Exception:
		# a figure shown in a closed GUI window may have lost its canvas
		from matplotlib.backends.backend_agg import FigureCanvasAgg
		FigureCanvasAgg(fig)
		fig.savefig(name, dpi=dpi, bbox_inches="tight")
	plt.close(fig)
	print("Figure created: %s" % name)


def run(cmd):
	res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
	                     universal_newlines=True)
	if res.returncode != 0:
		die("command failed:\n  %s\n%s" % (" ".join(cmd), res.stdout))
	return res.stdout


def target_srs_file(ref, tmpdir):
	"""Write the projection of the reference raster in a wkt file for gdalwarp."""
	wkt = os.path.join(tmpdir, "target.wkt")
	out = run(["gdalsrsinfo", "-o", "wkt", "--single-line", ref.gdal_path(tmpdir)])
	out = out.strip()
	if not out.startswith(("PROJCRS", "GEOGCRS", "PROJCS", "GEOGCS")):
		die("gdalsrsinfo could not read the projection of %s" % ref.path)
	with open(wkt, "w") as f:
		f.write(out + "\n")
	return wkt


def resample_on(raster, ref, wkt, method, tmpdir, tag):
	"""Return raster resampled on the grid of ref (identity if grids already match)."""
	if raster.same_grid_as(ref):
		print("%-10s already on the grid of the deformation map" % tag)
		return raster
	xmin, ymin, xmax, ymax = ref.extent
	out = os.path.join(tmpdir, tag)
	print("%-10s resampled on the grid of the deformation map (%s)" % (tag, method))
	cmd = ["gdalwarp", "-overwrite", "-q", "-of", "ENVI", "-ot", "Float32",
	       "-t_srs", wkt, "-r", method,
	       "-te", repr(xmin), repr(ymin), repr(xmax), repr(ymax),
	       "-ts", str(ref.nx), str(ref.ny),
	       "-dstnodata", "nan"]
	if raster.nodata is not None:
		cmd += ["-srcnodata", "nan" if np.isnan(raster.nodata) else repr(raster.nodata)]
	run(cmd + [raster.gdal_path(tmpdir), out])
	return Raster(out)


# -----------------------------------------------------------------------------------------
# Colours: deformation coloured, faded on the shaded relief according to the coherence
# -----------------------------------------------------------------------------------------
def opacity_from_coherence(coh, cmin, cmax, gamma, floor):
	"""Linear ramp from cmin (transparent) to cmax (opaque), raised to 1/gamma."""
	if coh is None:
		return None
	alpha = (coh - cmin) / max(cmax - cmin, 1e-9)
	alpha = np.clip(alpha, 0.0, 1.0) ** (1.0 / gamma)
	alpha[~np.isfinite(coh)] = 0.0
	return floor + (1.0 - floor) * alpha


def composite(data, dem, alpha, norm, cmap, ls, dxm, dym, zexag, blend):
	"""RGB image: coloured data shaded by the relief, over the bare shaded relief."""
	valid = np.isfinite(data)
	filled = np.where(valid, data, norm.vmin)

	colours = cmap(norm(filled))[:, :, :3]
	colours = ls.shade_rgb(colours, dem, blend_mode=blend,
	                       vert_exag=zexag, dx=dxm, dy=dym)

	relief = ls.hillshade(dem, vert_exag=zexag, dx=dxm, dy=dym)
	grey = np.dstack([0.15 + 0.85 * relief] * 3)

	opacity = np.ones_like(data) if alpha is None else alpha.copy()
	opacity[~valid] = 0.0
	opacity = opacity[:, :, np.newaxis]
	return np.clip(opacity * colours + (1.0 - opacity) * grey, 0.0, 1.0)


# -----------------------------------------------------------------------------------------
# Figures
# -----------------------------------------------------------------------------------------
def add_coherence_legend(ax, cmap, args):
	"""Small bar, inside the map, showing how the coherence drives the opacity."""
	ramp = np.linspace(0.0, 1.0, 128)[np.newaxis, :, np.newaxis]
	colour = np.array(cmap(0.5)[:3])
	grey = np.array([0.75, 0.75, 0.75])
	bar = ramp * colour + (1.0 - ramp) * grey

	inset = ax.inset_axes([0.03, 0.04, 0.30, 0.022])
	inset.imshow(np.repeat(bar, 8, axis=0), aspect="auto",
	             extent=(args.coh_min, args.coh_max, 0.0, 1.0))
	inset.set_yticks([])
	inset.set_xticks([args.coh_min, args.coh_max])
	inset.tick_params(labelsize=6, length=2, pad=1)
	inset.set_xlabel("coherence", fontsize=6, labelpad=1)
	for spine in inset.spines.values():
		spine.set_linewidth(0.4)


def wrap_title(title, width=95):
	return "\n".join(textwrap.wrap(title, width)) if title else ""


def figure_drape(data, dem, alpha, rgb, ref, norm, cmap, args, title):
	xmin, ymin, xmax, ymax = ref.extent
	if ref.geographic:
		extent, xlabel, ylabel = (xmin, xmax, ymin, ymax), "Longitude [dd]", "Latitude [dd]"
	else:
		extent = (xmin / 1000.0, xmax / 1000.0, ymin / 1000.0, ymax / 1000.0)
		xlabel, ylabel = "Easting [km]", "Northing [km]"

	aspect = (ymax - ymin) / (xmax - xmin)
	if ref.geographic:				# a degree of longitude is shorter than
		aspect /= np.cos(np.radians(0.5 * (ymin + ymax)))	# a degree of latitude
	width = 7.5
	fig, ax = plt.subplots(figsize=(width, max(3.0, min(12.0, width * aspect + 1.2))),
	                       constrained_layout=True)
	ax.imshow(rgb, extent=extent, origin="upper", interpolation="nearest")
	if ref.geographic:
		ax.set_aspect(1.0 / np.cos(np.radians(0.5 * (ymin + ymax))))
	if args.contour > 0:
		levels = np.arange(np.floor(np.nanmin(dem) / args.contour) * args.contour,
		                   np.nanmax(dem), args.contour)
		ax.contour(np.linspace(extent[0], extent[1], ref.nx),
		           np.linspace(extent[3], extent[2], ref.ny),
		           dem, levels=levels, colors="k", linewidths=0.2, alpha=0.4)
	ax.set_xlabel(xlabel)
	ax.set_ylabel(ylabel)
	ax.set_title(wrap_title(title), fontsize=8)

	mappable = plt.cm.ScalarMappable(norm=norm, cmap=cmap)
	fig.colorbar(mappable, ax=ax, fraction=0.045, pad=0.02,
	             shrink=0.95).set_label(args.unit)
	if alpha is not None:
		add_coherence_legend(ax, cmap, args)
	return fig


def set_3d_box(ax, spans, zexag, zoom):
	"""Shape of the 3D box: the relief is exaggerated zexag times, and zoom fills the frame."""
	span_x, span_y, span_z = spans
	aspect = (span_x, span_y, max(span_z * zexag, 0.05 * span_x))
	try:
		ax.set_box_aspect(aspect, zoom=zoom)
	except TypeError:				# matplotlib older than 3.6
		ax.set_box_aspect(aspect)


def show_and_adjust_3d(fig, ax, spans, args):
	"""Open the 3D view, let it be manipulated, and return the options of the final view.

	The window blocks until it is closed. Rotation and right-button zoom are provided by
	matplotlib itself; the scroll wheel and the +/- keys are connected here.
	"""
	view = {"zexag": args.zexag3d, "zoom": 1.0}

	def refresh():
		set_3d_box(ax, spans, view["zexag"], view["zoom"])
		fig.canvas.draw_idle()

	def on_scroll(event):
		view["zoom"] *= 1.1 if event.button == "up" else 1.0 / 1.1
		view["zoom"] = min(max(view["zoom"], 0.2), 5.0)
		refresh()

	def on_key(event):
		if event.key in ("+", "="):
			view["zexag"] = min(view["zexag"] * 1.2, 50.0)
		elif event.key == "-":
			view["zexag"] = max(view["zexag"] / 1.2, 0.1)
		else:
			return
		refresh()

	fig.canvas.mpl_connect("scroll_event", on_scroll)
	fig.canvas.mpl_connect("key_press_event", on_key)
	try:
		fig.canvas.manager.set_window_title("Plot_Envi_on_DEM - close to save the figure")
	except AttributeError:
		pass

	print("\n3D view opened:")
	print("   drag with the left button   rotate")
	print("   drag with the right button, or scroll wheel   zoom")
	print("   + / -   increase / decrease the vertical exaggeration")
	print("   close the window   save the figure as it is seen\n")
	plt.show(block=True)

	view["elev"], view["azim"] = ax.elev, ax.azim
	print("View saved: --elev %.1f --azim %.1f --zexag3d %.2f  (zoom %.2f)"
	      % (view["elev"], view["azim"], view["zexag"], view["zoom"]))
	return view


def figure_3d(dem, rgb, ref, norm, cmap, args, title):
	step = max(1, int(np.ceil(max(ref.nx, ref.ny) / float(args.max3d))))
	z = dem[::step, ::step]
	c = rgb[::step, ::step]

	xmin, ymin, xmax, ymax = ref.extent
	if ref.geographic:
		dxm, dym = ref.pixel_size_meters()
		x = np.arange(z.shape[1]) * dxm * step / 1000.0
		y = np.arange(z.shape[0]) * dym * step / 1000.0
	else:
		x = np.linspace(xmin, xmax, z.shape[1]) / 1000.0
		y = np.linspace(ymin, ymax, z.shape[0]) / 1000.0
	X, Y = np.meshgrid(x, y[::-1])			# rows go from North to South

	fig = plt.figure(figsize=(8.5, 6.0))
	ax = fig.add_subplot(projection="3d", computed_zorder=False)
	ax.plot_surface(X, Y, z / 1000.0, facecolors=c, rstride=1, cstride=1,
	                shade=False, linewidth=0, antialiased=False)
	spans = (x[-1] - x[0], y[-1] - y[0], (np.nanmax(z) - np.nanmin(z)) / 1000.0)
	set_3d_box(ax, spans, args.zexag3d, 1.0)
	ax.view_init(elev=args.elev, azim=args.azim)
	ax.set_zlim(np.nanmin(z) / 1000.0, np.nanmax(z) / 1000.0)
	ax.zaxis.set_major_locator(MaxNLocator(4))
	ax.set_xlabel("Easting [km]" if not ref.geographic else "[km]", fontsize=8)
	ax.set_ylabel("Northing [km]" if not ref.geographic else "[km]", fontsize=8)
	ax.set_zlabel("Elevation [km]", fontsize=8)
	ax.tick_params(labelsize=7)
	ax.set_title(wrap_title(title), fontsize=8)

	mappable = plt.cm.ScalarMappable(norm=norm, cmap=cmap)
	fig.colorbar(mappable, ax=ax, fraction=0.025, pad=0.10,
	             shrink=0.55).set_label(args.unit, fontsize=8)
	fig.subplots_adjust(left=0.0, right=0.90, bottom=0.02, top=0.92)
	return fig, ax, spans


# -----------------------------------------------------------------------------------------
def parse_args():
	p = argparse.ArgumentParser(
		description="Drape an ENVI deformation map or unwrapped interferogram on a DEM, "
		            "with the opacity driven by the coherence.",
		formatter_class=argparse.ArgumentDefaultsHelpFormatter)
	p.add_argument("data", help="ENVI deformation map or unwrapped interferogram")
	p.add_argument("dem", help="DEM: ENVI binary, or AMSTer DEM.txt header")
	p.add_argument("-c", "--coherence", help="ENVI coherence file driving the opacity")
	p.add_argument("-o", "--out", help="output image [<data file>_onDEM.png]")
	p.add_argument("--mode", choices=["drape", "3d", "both"], default="drape")

	p.add_argument("--cmap", help="matplotlib colour map [jet, or hsv if --wrap]")
	p.add_argument("--vmin", type=float, help="lower colour limit [--pct percentile]")
	p.add_argument("--vmax", type=float, help="upper colour limit [--pct percentile]")
	p.add_argument("--pct", type=float, default=2.0,
	               help="percentile clipped at each end when vmin/vmax are not given")
	p.add_argument("--sym", action="store_true",
	               help="symmetric colour scale centred on zero")
	p.add_argument("--scale", type=float, default=1.0,
	               help="factor applied to the data, e.g. 100 to plot meters in cm")
	p.add_argument("--unit", default="", help="label of the colour bar")
	p.add_argument("--wrap", type=float,
	               help="display the data modulo CYCLE (fringes), after --scale")

	p.add_argument("--coh-min", type=float, default=0.15,
	               help="coherence mapped to fully transparent")
	p.add_argument("--coh-max", type=float, default=0.60,
	               help="coherence mapped to fully opaque")
	p.add_argument("--coh-gamma", type=float, default=1.0,
	               help="curvature of the opacity ramp (>1 favours opacity)")
	p.add_argument("--alpha-min", type=float, default=0.0,
	               help="minimum opacity, to keep a hint of colour everywhere")

	p.add_argument("--az", type=float, default=315.0, help="sun azimuth [deg]")
	p.add_argument("--alt", type=float, default=45.0, help="sun elevation [deg]")
	p.add_argument("--blend", choices=["soft", "overlay", "hsv"], default="soft",
	               help="how the relief shades the colours")
	p.add_argument("--zexag", type=float, default=2.0,
	               help="vertical exaggeration used for the shading")
	p.add_argument("--contour", type=float, default=0.0,
	               help="elevation contour interval [m], 0 to skip")

	p.add_argument("--elev", type=float, default=40.0, help="3D view elevation [deg]")
	p.add_argument("--azim", type=float, default=-70.0, help="3D view azimuth [deg]")
	p.add_argument("--zexag3d", type=float, default=3.0,
	               help="vertical exaggeration of the 3D surface")
	p.add_argument("-i", "--interactive", action="store_true",
	               help="open the 3D view in a window to rotate, zoom and exaggerate it; "
	                    "the figure is saved when the window is closed")
	p.add_argument("--max3d", type=int, default=500,
	               help="largest dimension of the 3D surface, decimated if needed")

	p.add_argument("--dem-resampling", default="cubic", help="gdalwarp method for the DEM")
	p.add_argument("--coh-resampling", default="bilinear",
	               help="gdalwarp method for the coherence")
	p.add_argument("--title", help="title of the figure [name of the data file]")
	p.add_argument("--dpi", type=int, default=200)
	p.add_argument("--keep-tmp", action="store_true",
	               help="keep the resampled intermediate files")
	return p.parse_args()


def main():
	print("\n%s %s, %s" % (PRG, VER, AUT))
	args = parse_args()

	for tool in ("gdalwarp", "gdalsrsinfo"):
		if shutil.which(tool) is None:
			die("%s is not in the PATH (GDAL binaries are required)" % tool)

	tmpdir = tempfile.mkdtemp(prefix="Plot_Envi_on_DEM_")
	try:
		demfile = (dem_envi_from_txt(args.dem, tmpdir)
		           if args.dem.endswith(".txt") else args.dem)

		ref = Raster(args.data)				# the grid of the figure
		dem_src = Raster(demfile)
		coh_src = Raster(args.coherence) if args.coherence else None

		wkt = target_srs_file(ref, tmpdir)
		dem = resample_on(dem_src, ref, wkt, args.dem_resampling, tmpdir, "DEM").read()
		coh = None
		if coh_src is not None:
			coh = resample_on(coh_src, ref, wkt, args.coh_resampling, tmpdir,
			                  "coherence").read()
		data = ref.read() * args.scale

		missing = np.isnan(dem).mean()
		if missing > 0.5:
			die("the DEM covers only %.0f%% of the deformation map footprint - "
			    "use a wider DEM" % (100 * (1 - missing)))
		if missing > 0:
			print("WARNING: DEM missing on %.1f%% of the footprint, filled with its "
			      "lowest elevation" % (100 * missing))
			dem = np.where(np.isnan(dem), np.nanmin(dem), dem)

		if args.wrap:
			data = np.mod(data, args.wrap)
			vmin, vmax = 0.0, args.wrap
			cmap = plt.get_cmap(args.cmap or "hsv")
		else:
			vmin = args.vmin if args.vmin is not None else np.nanpercentile(data, args.pct)
			vmax = args.vmax if args.vmax is not None else np.nanpercentile(data, 100 - args.pct)
			cmap = plt.get_cmap(args.cmap or "jet")
		if args.sym and not args.wrap:
			vmax = max(abs(vmin), abs(vmax))
			vmin = -vmax
		if vmax <= vmin:
			die("empty colour scale (vmin=%g, vmax=%g)" % (vmin, vmax))
		norm = Normalize(vmin=vmin, vmax=vmax)
		print("Colour scale: %g to %g %s" % (vmin, vmax, args.unit))

		alpha = opacity_from_coherence(coh, args.coh_min, args.coh_max,
		                               args.coh_gamma, args.alpha_min)
		dxm, dym = ref.pixel_size_meters()
		ls = LightSource(azdeg=args.az, altdeg=args.alt)
		rgb = composite(data, dem, alpha, norm, cmap, ls, dxm, dym,
		                args.zexag, args.blend)

		title = args.title if args.title else os.path.basename(args.data)
		out = args.out if args.out else os.path.basename(args.data) + "_onDEM.png"
		root, ext = os.path.splitext(out)
		ext = ext if ext else ".png"

		if args.mode in ("drape", "both"):
			name = out if args.mode == "drape" else root + "_drape" + ext
			fig = figure_drape(data, dem, alpha, rgb, ref, norm, cmap, args, title)
			save_figure(fig, name, args.dpi)
		if args.mode in ("3d", "both"):
			name = out if args.mode == "3d" else root + "_3D" + ext
			interactive = enable_gui_backend() if args.interactive else False
			fig, ax, spans = figure_3d(dem, rgb, ref, norm, cmap, args, title)
			if interactive:
				show_and_adjust_3d(fig, ax, spans, args)
			save_figure(fig, name, args.dpi)
	finally:
		if args.keep_tmp:
			print("Intermediate files kept in %s" % tmpdir)
		else:
			shutil.rmtree(tmpdir, ignore_errors=True)


if __name__ == "__main__":
	main()