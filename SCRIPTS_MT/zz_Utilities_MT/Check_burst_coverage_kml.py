#!/opt/local/bin/python
#
# The scrip reads a target KML provided as first parameter and all the bursts KMLs
# within the directory.
# Then it checks that the combined geometries of all bursts KMLs fully cover the 
# target area, meaning that the union of all small areas should be at least as large as 
# the target area.  
#
# If the coverage is OK, it answers: 		" Total small KML polygons detected: N" (with N = number of bursts)
#											"The target KML is fully covered by the bursts KMLs."
#
# If the coverage is NOT OK, it answers: 	"  Total small KML polygons detected: N" (with N = number of bursts)
# 											"The target KML is NOT fully covered. Saving coverage plot for review..."
# 											"Coverage plot saved at: /.../S1/YourRegion_Track/NoCrop/S1?_Trk_DATE_?.csl/Info/PerBurstInfo/Coverage_YourKkmlName.png"
#											"The target KML is NOT fully covered by the bursts KMLs."
# Optional: add option -p to save the coverage plot even if cover is OK. 
# 
# The plot displays - the target kml in red (its file name is reminded in the title of the plot)
#					- each burst (with its name) in blue  
#
# Parameters:	- Path to target kml (footprint that must be overlapped by bursts)
#				- Path to directory with all the bursts kml (e.g. /.../S1/YourRegion_Track/NoCrop/S1?_Trk_DATE_?.csl/Info/PerBurstInfo) 
#				- optional; if add -p option, it will save the plot of target and bursts overlap in the directory with all the bursts kml
#				  even if the overlap is OK. This might be useful when you suspect more bursts than needed
#
# New in V1.1 25 Feb 2025: 	- also OK with target kml that are not polygon
# 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2025/02/24 - could make better with more functions... when time.
# ******************************************************************************

import os
import xml.etree.ElementTree as ET
from shapely.geometry import Polygon, MultiPolygon, LineString
from shapely.ops import unary_union
import argparse
import matplotlib.pyplot as plt
import geopandas as gpd

# Function to parse KML and extract geometry

def parse_kml(kml_file):
    coordinates_list = []
    tree = ET.parse(kml_file)
    root = tree.getroot()

    # Detect namespace dynamically
    ns = {'kml': 'http://www.opengis.net/kml/2.2'}
    if root.tag.startswith("{"):
        ns_prefix = root.tag.split("}")[0][1:]
        ns = {'kml': ns_prefix}  
        query_prefix = "kml:"
    else:
        ns = None
        query_prefix = ""

    # Extract Polygons
    for polygon in root.findall(f'.//{query_prefix}Polygon', ns):
        coords_text = polygon.find(f'.//{query_prefix}outerBoundaryIs/{query_prefix}LinearRing/{query_prefix}coordinates', ns)
        if coords_text is not None and coords_text.text:
            coords = [(float(x.split(',')[0]), float(x.split(',')[1])) for x in coords_text.text.strip().split()]
            if len(coords) > 2:
                coordinates_list.append(coords)

    # Extract LineString (Convert to Buffered Polygon)
    for linestring in root.findall(f'.//{query_prefix}LineString', ns):
        coords_text = linestring.find(f'.//{query_prefix}coordinates', ns)
        if coords_text is not None and coords_text.text:
            coords = [(float(x.split(',')[0]), float(x.split(',')[1])) for x in coords_text.text.strip().split()]
            if len(coords) > 1:
                # Convert LineString to a small buffered polygon
                line = LineString(coords)
                buffer_poly = line.buffer(0.01)  # Adjust buffer size as needed
                coordinates_list.append(list(buffer_poly.exterior.coords))

    # Extract MultiGeometry (Recursive Handling)
    for multigeom in root.findall(f'.//{query_prefix}MultiGeometry', ns):
        for geom in multigeom:
            coords_text = geom.find(f'.//{query_prefix}coordinates', ns)
            if coords_text is not None and coords_text.text:
                coords = [(float(x.split(',')[0]), float(x.split(',')[1])) for x in coords_text.text.strip().split()]
                if len(coords) > 1:
                    coordinates_list.append(coords)

    if not coordinates_list:
        print(f"  Warning: No valid geometries found in {kml_file}")

    return coordinates_list

# Function to convert coordinates into Shapely polygons
def kml_to_polygon(kml_file):
    polygons = []
    coordinates_list = parse_kml(kml_file)

    for coordinates in coordinates_list:
        if len(coordinates) > 2:
            polygons.append(Polygon(coordinates))

    if not polygons:
        return None
    elif len(polygons) == 1:
        return polygons[0]
    else:
        return MultiPolygon(polygons)

# Function to check if the target KML is fully covered by smaller KMLs
def check_coverage(target_kml, small_kml_directory, save_plot=False):
    target_polygon = kml_to_polygon(target_kml)
    
    if target_polygon is None:
        print(f" Target KML {target_kml} could not be parsed into a polygon.")
        return False
    
    small_polygons = []
    small_kml_files = []  # Store burst filenames

    for small_kml in os.listdir(small_kml_directory):
        if small_kml.endswith('.kml'):
            small_kml_path = os.path.join(small_kml_directory, small_kml)
            small_polygon = kml_to_polygon(small_kml_path)
            if small_polygon:
                small_polygons.append(small_polygon)
                small_kml_files.append(os.path.splitext(small_kml)[0])  # Store filename without extension
            else:
                print(f" Warning: {small_kml} could not be parsed into a polygon.")

    print(f" Total small KML polygons detected: {len(small_polygons)}")

    if not small_polygons:
        print(" No valid small KMLs were found.")
        return False

    combined_small_polygon = unary_union(small_polygons)
    fully_covered = combined_small_polygon.covers(target_polygon)

    if not fully_covered:
        print(" The target KML is NOT fully covered. Saving coverage plot for review...")
        plot_polygons(target_kml, target_polygon, small_polygons, small_kml_files, small_kml_directory)
    elif save_plot:
        print(" The target KML is fully covered, but saving coverage plot as requested...")
        plot_polygons(target_kml, target_polygon, small_polygons, small_kml_files, small_kml_directory)

    return fully_covered

# Function to plot and save polygons
def plot_polygons(target_kml, target_polygon, small_polygons, small_kml_files, output_directory):
    fig, ax = plt.subplots(figsize=(8, 8))

    # Extract filename without extension for target
    target_name = os.path.splitext(os.path.basename(target_kml))[0]

    # Plot all burst (small) KML polygons
    for poly, filename in zip(small_polygons, small_kml_files):
        gpd.GeoSeries(poly).plot(ax=ax, color='blue', alpha=0.5, edgecolor='black', linewidth=1)
        
        # Compute centroid for labeling
        centroid = poly.centroid
        ax.text(centroid.x, centroid.y, filename, fontsize=4, ha='center', color='black')

    # Plot the target KML polygon
    gpd.GeoSeries(target_polygon).plot(ax=ax, color='red', alpha=0.3, edgecolor='black', linewidth=2)

    # Add a legend manually
    from matplotlib.patches import Patch
    legend_patches = [
        Patch(facecolor='blue', edgecolor='black', alpha=0.5, label=f"Burst KMLs ({len(small_polygons)})"),
        Patch(facecolor='red', edgecolor='black', alpha=0.3, label="Target KML")
    ]
    ax.legend(handles=legend_patches)

    plt.title(f"Coverage Check for {target_name}.kml")  # Set title with target KML name
    plt.xlabel("Longitude")
    plt.ylabel("Latitude")
    plt.grid(True)

    # Save plot with target name in filename
    output_file = os.path.join(output_directory, f"Coverage_{target_name}.png")
    plt.savefig(output_file, dpi=300, bbox_inches="tight")
    plt.close()

    print(f" Coverage plot saved at: {output_file}")
        
# Main function
def main():
    parser = argparse.ArgumentParser(description="Check if small KML files cover a target KML.")
    parser.add_argument('target_kml', help="The path to the target KML file.")
    parser.add_argument('small_kml_directory', help="The directory containing the small KML files.")
    parser.add_argument('-p', '--plot', action='store_true', help="Save the coverage plot even if the target is fully covered.")

    args = parser.parse_args()

    if check_coverage(args.target_kml, args.small_kml_directory, args.plot):
        print("The target KML is fully covered by the bursts KMLs.")
    else:
        print("The target KML is NOT fully covered by the bursts KMLs.")

if __name__ == '__main__':
    main()
