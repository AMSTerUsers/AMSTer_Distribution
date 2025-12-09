#!/opt/local/amster_python_env/bin/python
#
# The script aims at extracting pixel name and coordinates from a kml file.
# It reads name from the "layer" field and the coordinates from the "coordinates" field.
# Output is saved in a text file with the same name as the kml file with .txt extension instead
#
# Parameters: 	- the kml file 
#
#
# New in Distro V 1.0  20241231: - setup 
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import xml.etree.ElementTree as ET
import sys
import os

# Check if the user has provided the KML file as a parameter
if len(sys.argv) != 2:
    print("Usage: python extract_coords.py <path_to_kml_file>")
    sys.exit(1)

# Get the KML file path from the command-line argument
kml_file = sys.argv[1]

# Define the namespace (since your KML file uses a namespace)
namespace = {'kml': 'http://www.opengis.net/kml/2.2'}

# Extract the directory and base name (without extension) of the KML file
dir_name = os.path.dirname(kml_file)  # Get the directory of the KML file
base_name = os.path.splitext(os.path.basename(kml_file))[0]  # Get the base name without extension
output_file_name = os.path.join(dir_name, f"{base_name}.txt")  # Combine dir with output file name

try:
    # Parse the KML file
    tree = ET.parse(kml_file)
    root = tree.getroot()

    # Open the output file in the same directory as the KML file
    with open(output_file_name, 'w') as output_file:
        # Iterate through each Placemark in the KML file
        for placemark in root.findall('.//kml:Placemark', namespace):
            # Extract the layer value
            layer = placemark.find(".//kml:SimpleData[@name='layer']", namespace)
            if layer is not None:
                layer_value = layer.text.strip()
            else:
                continue

            # Extract the coordinates value
            coordinates = placemark.find(".//kml:Point/kml:coordinates", namespace)
            if coordinates is not None:
                coordinates_value = coordinates.text.strip()
                # Split coordinates into longitude, latitude, altitude
                coords = coordinates_value.split(',')
                if len(coords) >= 2:
                    lon = coords[0].strip()  # Longitude
                    lat = coords[1].strip()  # Latitude
                    # Write the layer and coordinates to the output file, separating by tab
                    output_file.write(f"{layer_value}\t{lon}\t{lat}\n")

    print(f"Coordinates and layers have been extracted and saved to {output_file_name}.")
    
except ET.ParseError as e:
    print(f"Error parsing the KML file: {e}")
except FileNotFoundError:
    print(f"Error: The file '{kml_file}' was not found.")



 