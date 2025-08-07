#!/opt/local/bin/python
#
# The scrip reads a target KML provided as first parameter and all the KMLs named map-overlayX.kml in a directory. These KMLs
# are comming from RAW Sentinel 1 images (all kml files must be copied in a dir and named with trailing X, where X is an integer).
# 
# Then it checks that the combined geometries of all  KMLs fully cover the 
# target area, meaning that the union of all small areas should be at least as large as 
# the target area.  
#
# If the coverage is OK, it answers: 		"V Target is fully covered by overlays"
#
# If the coverage is NOT OK, it answers: 	"X Target is NOT fully covered by overlays." 
#											"Uncovered area (square degrees): ... "
#											and it plots a figure with the kml's footprints
#
# Optional: add option -p to save the coverage plot even if cover is OK. 
# 
# Parameters:	- Path to target kml (footprint that must be overlapped by KMLs)
#				- Path to directory with all the KMLs named 
#				- optional; if add -p option, it will save the plot of target and KMLs overlap in the directory with all the KMLs
#				  even if the overlap is OK. 
#
# New in V1.1 
# 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2025/02/24 - could make better with more functions... when time.
# ******************************************************************************

import sys
from pathlib import Path
from xml.etree import ElementTree as ET

import matplotlib.pyplot as plt
from shapely.geometry import Polygon
from shapely.ops import unary_union

# ---- Helpers -----------------------------------------------------------
def parse_coord_string(coord_string: str):
    parts = coord_string.strip().split()
    return [tuple(map(float, p.split(',')[:2])) for p in parts]

def polygon_from_kml(file_path: Path, coord_xpath: str, ns: dict):
    tree = ET.parse(file_path)
    root = tree.getroot()
    coord_el = root.find(coord_xpath, ns)
    if coord_el is None:
        raise ValueError(f'No coordinates found in {file_path}')
    coords = parse_coord_string(coord_el.text)
    if coords[0] != coords[-1]:
        coords.append(coords[0])
    return Polygon(coords)

def plot_polygon(ax, polygon, facecolor, edgecolor, label=None, alpha=0.4, zorder=1):
    if polygon.is_empty:
        return
    if polygon.geom_type == 'Polygon':
        polys = [polygon]
    elif polygon.geom_type == 'MultiPolygon':
        polys = polygon.geoms
    else:
        return
    for poly in polys:
        x, y = poly.exterior.xy
        ax.fill(x, y, facecolor=facecolor, edgecolor=edgecolor, alpha=alpha, label=label, zorder=zorder)
        label = None  # avoid duplicate legend entries

# ---- Namespaces --------------------------------------------------------
NS_OVERLAY = {'gx': 'http://www.google.com/kml/ext/2.2'}
NS_TARGET = {'kml': 'http://www.opengis.net/kml/2.2'}

# ---- Args --------------------------------------------------------------
if len(sys.argv) < 3 or len(sys.argv) > 4:
    print("Usage: python check_kml_coverage.py <target.kml> <overlay_dir> [-p]")
    sys.exit(1)

target_path = Path(sys.argv[1])
overlay_dir = Path(sys.argv[2])
force_plot = len(sys.argv) == 4 and sys.argv[3] == "-p"

if not target_path.exists():
    print(f"Error: target file not found: {target_path}")
    sys.exit(1)

if not overlay_dir.exists() or not overlay_dir.is_dir():
    print(f"Error: overlay directory not found or not a directory: {overlay_dir}")
    sys.exit(1)

# ---- Read overlays -----------------------------------------------------
overlay_polys = []
for fp in overlay_dir.glob('map-overlay*.kml'):
    try:
        poly = polygon_from_kml(
            fp,
            './/gx:LatLonQuad/coordinates',
            NS_OVERLAY
        )
        overlay_polys.append(poly)
    except Exception as e:
        print(f"Warning: failed to parse {fp.name}: {e}")

if not overlay_polys:
    print("Error: No valid overlay polygons found.")
    sys.exit(1)

overlay_union = unary_union(overlay_polys)

# ---- Read target -------------------------------------------------------
try:
    target_poly = polygon_from_kml(
        target_path,
        './/kml:Polygon/kml:outerBoundaryIs/kml:LinearRing/kml:coordinates',
        NS_TARGET
    )
except Exception as e:
    print(f"Error: failed to parse target file: {e}")
    sys.exit(1)

# ---- Coverage test -----------------------------------------------------
is_covered = overlay_union.covers(target_poly)

print('✅ Target is fully covered by overlays.' if is_covered else
      '❌ Target is NOT fully covered by overlays.')

# ---- Plotting ----------------------------------------------------------
if not is_covered or force_plot:
    fig, ax = plt.subplots(figsize=(10, 8))

    for poly in overlay_polys:
        plot_polygon(ax, poly, facecolor='skyblue', edgecolor='blue', label='Overlay', alpha=0.4, zorder=1)

    plot_polygon(ax, target_poly, facecolor='none', edgecolor='red', label='Target', alpha=1.0, zorder=2)

    if not is_covered:
        uncovered = target_poly.difference(overlay_union)
        plot_polygon(ax, uncovered, facecolor='gold', edgecolor='orange', label='Uncovered', alpha=0.6, zorder=3)
        print(f'   Uncovered area (square degrees): {uncovered.area:.6f}')

    ax.legend()
    ax.set_title("Target Coverage by Overlay KMLs")
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.grid(True)
    plt.tight_layout()
    output_file = overlay_dir / f'coverage_plot.png'
    plt.savefig(output_file, dpi=300)

