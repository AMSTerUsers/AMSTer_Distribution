#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script checks if an area provided as a kml file is included in another area
# provided as a second kml file. 
# It will answer [True] if all the corners of the small kml are within the large kml
# and [False] otherwise
#
# Parameters:	- smaller kml to check if included in larger kml
#				- larger kml to check if it includes smaller kml
#
# Dependencies:	- geopandas
#
# Hard coded: - none
# 
# New in Distro V 1.0 20240208:	- new script
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import sys

from xml.dom import minidom
from shapely.geometry import Polygon, Point
#from shapely.geometry.polygon import PolygonAdapter


if len(sys.argv) != 3:
	print("Usage: python script.py <smaller_kml_file> <larger_kml_file>")
	sys.exit(1)


kml_small = sys.argv[1] 	# kml with path
kml_large = sys.argv[2] 	# kml with path

#print(f'Check if \n {kml_small} \nis included in \n {kml_large} \n')

def parse_kml(file_path):
	#Parses a KML file and returns a list of polygon coordinates.
	polygons = []

	with open(file_path, 'r') as f:
		doc = minidom.parseString(f.read())

	# Check if the file contains GroundOverlay or Placemark elements
	ground_overlays = doc.getElementsByTagName('GroundOverlay')
	placemarks = doc.getElementsByTagName('Placemark')

	if ground_overlays:
		for overlay in ground_overlays:
			coords = overlay.getElementsByTagName('coordinates')[0].firstChild.data.strip()
			coord_list = [list(map(float, p.split(',')))[:2] for p in coords.split()]  # Exclude the third coordinate
			polygons.append(coord_list)
	elif placemarks:
		for placemark in placemarks:
			coords = placemark.getElementsByTagName('coordinates')[0].firstChild.data.strip()
			coord_list = [list(map(float, p.split(',')))[:2] for p in coords.split()]  # Exclude the third coordinate
			polygons.append(coord_list)
	else:
		print("No valid elements found in the KML file.")

	#print(f'coord_list of {file_path}:\n{coord_list} \n')
	return polygons
	
def is_included(polygon_coords_1, polygon_coords_2):
	#Checks if polygon defined by polygon_coords_1 is included in polygon defined by polygon_coords_2.
	polygon1 = Polygon(polygon_coords_1)
	polygon2 = Polygon(polygon_coords_2)

	# Check if all points of polygon1 are contained within polygon2
	return all(Point(x, y).within(polygon2) for x, y in polygon1.exterior.coords)

def check_inclusion(kml_small, kml_large):
	#Checks if the polygons in kml_small are included in the polygons in kml_large.
	polygons_1 = parse_kml(kml_small)
	polygons_2 = parse_kml(kml_large)

	inclusion_results = []

	for poly1 in polygons_1:
		for poly2 in polygons_2:
			inclusion_results.append(is_included(poly1, poly2))

	return inclusion_results

inclusion_results = check_inclusion(kml_small, kml_large)
print(inclusion_results)

