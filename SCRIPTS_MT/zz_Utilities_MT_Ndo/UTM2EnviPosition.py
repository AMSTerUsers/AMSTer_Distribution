#!/opt/local/bin/python
#
# The script aims at converting coordinates into pixel positions in an ENVI raster file.
# It reads geographical information provided in the .hdr file.
#
# Coordinates can be provided as Lat Long (decimal) or UTM  (must be in the same UTM zone as 
# one indicated in the header file). Note that despite the info from the header file, 
# data in file are probably in pseudo mercator. Hence the script will take care of it. 
#
# Parameters: 	- the hdr file 
#				- the coordinates to search for position in file
#				- format descriptor of provided input coordinates: either -LATLONG, -UTM or -PSEUDO_UTM
#
# Example: 
# 	UTM2EnviPosition.py /YourPath/MSBAS_20190130T122227_UD.bin.hdr 85.5963570646316 27.943339178788 -LATLONG
# 	  should answer something like: 	Pixel Position (Option -LATLONG): X=2060, Y=770
# 	UTM2EnviPosition.py /YourPath/MSBAS_20190130T122227_UD.bin.hdr 9528543 3241833 -PSEUDO_UTM
# 	  should answer something like: 	Pixel Position (Option -PSEUDO_UTM): X=2060, Y=770
# 	UTM2EnviPosition.py /YourPath/MSBAS_20190130T122227_UD.bin.hdr 361910 3091718 -UTM
#		should answer something like: 	Pixel Position (Option -UTM): X=2060, Y=770
#
# New in Distro V 1.0  20241231: - setup 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import math
import sys
from pyproj import Transformer

def parse_header(header_path):
    """
    Parses the ENVI .hdr file to extract relevant metadata.
    :param header_path: Path to the ENVI header (.hdr) file
    :return: Dictionary with parsed header information
    """
    header_info = {'map_info': {}}
    with open(header_path, 'r') as file:
        for line in file:
            if 'map info' in line.lower():
                map_info = line.split('=')[1].strip('{} \n').split(',')
                header_info['map_info']['upper_left_x'] = float(map_info[3])
                header_info['map_info']['upper_left_y'] = float(map_info[4])
                header_info['map_info']['pixel_size_x'] = float(map_info[5])
                header_info['map_info']['pixel_size_y'] = float(map_info[6])
                header_info['utm_zone'] = int(map_info[7])  # UTM zone
                header_info['hemisphere'] = map_info[8].strip().lower()  # Hemisphere
    return header_info

def utm_to_pixel(x, y, header_info):
    """
    Converts UTM coordinates to pixel positions in an ENVI raster.
    :param x: UTM X coordinate
    :param y: UTM Y coordinate
    :param header_info: Dictionary with header metadata
    :return: Tuple (pixel_x, pixel_y)
    """
    upper_left_x = header_info['map_info']['upper_left_x']
    upper_left_y = header_info['map_info']['upper_left_y']
    pixel_size_x = header_info['map_info']['pixel_size_x']
    pixel_size_y = header_info['map_info']['pixel_size_y']
    pixel_x = (x - upper_left_x) / pixel_size_x
    pixel_y = (upper_left_y - y) / pixel_size_y  # Y direction reversed
    return int(math.floor(pixel_x)), int(math.floor(pixel_y))

def transform_coordinates(x, y, from_crs, to_crs):
    """
    Transforms coordinates from one CRS to another.
    :param x: Input X coordinate
    :param y: Input Y coordinate
    :param from_crs: Source CRS as EPSG code
    :param to_crs: Destination CRS as EPSG code
    :return: Transformed coordinates (x, y)
    """
    transformer = Transformer.from_crs(from_crs, to_crs, always_xy=True)
    return transformer.transform(x, y)

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python script.py <hdr_file> <input_x> <input_y> <option>")
        print("Options: -UTM, -PSEUDO_UTM, -LATLONG")
        sys.exit(1)

    hdr_file = sys.argv[1]
    input_x = float(sys.argv[2])
    input_y = float(sys.argv[3])
    option = sys.argv[4].upper()

    # Parse the header file
    header_metadata = parse_header(hdr_file)
    zone = header_metadata['utm_zone']
    hemisphere = header_metadata['hemisphere']
    utm_epsg = 32600 + zone if hemisphere == 'north' else 32700 + zone

    # Determine action based on the selected option
    if option == "-UTM":
        # Option 1: UTM coordinates already match the header file's CRS
        pixel_pos = utm_to_pixel(input_x, input_y, header_metadata)
        print(f"Pixel Position (Option -UTM): X={pixel_pos[0]}, Y={pixel_pos[1]}")

    elif option == "-PSEUDO_UTM":
        # Option 2: Transform from Pseudo-Mercator (EPSG:3857) to UTM
        transformed_x, transformed_y = transform_coordinates(input_x, input_y, "EPSG:3857", f"EPSG:{utm_epsg}")
        pixel_pos = utm_to_pixel(transformed_x, transformed_y, header_metadata)
        print(f"Pixel Position (Option -PSEUDO_UTM): X={pixel_pos[0]}, Y={pixel_pos[1]}")

    elif option == "-LATLONG":
        # Option 3: Transform from Latitude/Longitude (EPSG:4326) to UTM
        transformed_x, transformed_y = transform_coordinates(input_x, input_y, "EPSG:4326", f"EPSG:{utm_epsg}")
        pixel_pos = utm_to_pixel(transformed_x, transformed_y, header_metadata)
        print(f"Pixel Position (Option -LATLONG): X={pixel_pos[0]}, Y={pixel_pos[1]}")

    else:
        print(f"Invalid option: {option}. Use -UTM, -PSEUDO_UTM, or -LATLONG.")
        sys.exit(1)



## Following script considers that data in file are in pseudo mercator instead of as indicated in MapInfo
#
#import math
#import sys
#from pyproj import Transformer
#
#def utm_to_pixel(x, y, header_info):
#    """
#    Converts UTM coordinates to pixel positions in an ENVI raster.
#
#    :param x: UTM X coordinate
#    :param y: UTM Y coordinate
#    :param header_info: Dictionary with header metadata (from .hdr file)
#    :return: Tuple (pixel_x, pixel_y) representing the pixel position
#    """
#    # Extract header information
#    upper_left_x = header_info['map_info']['upper_left_x']
#    upper_left_y = header_info['map_info']['upper_left_y']
#    pixel_size_x = header_info['map_info']['pixel_size_x']
#    pixel_size_y = header_info['map_info']['pixel_size_y']
#    
#    # Calculate pixel coordinates
#    pixel_x = (x - upper_left_x) / pixel_size_x
#    pixel_y = (upper_left_y - y) / pixel_size_y  # Note the reversed y-direction
#
#    # Return as integers (pixel indices)
#    return int(math.floor(pixel_x)), int(math.floor(pixel_y))
#
#def parse_header(header_path):
#    """
#    Parses the ENVI .hdr file to extract relevant metadata.
#    
#    :param header_path: Path to the ENVI header (.hdr) file
#    :return: Dictionary with parsed header information
#    """
#    header_info = {
#        'map_info': {}
#    }
#    
#    with open(header_path, 'r') as file:
#        for line in file:
#            if 'map info' in line.lower():
#                # Extract map info details
#                map_info = line.split('=')[1].strip('{} \n').split(',')
#                header_info['map_info']['upper_left_x'] = float(map_info[3])
#                header_info['map_info']['upper_left_y'] = float(map_info[4])
#                header_info['map_info']['pixel_size_x'] = float(map_info[5])
#                header_info['map_info']['pixel_size_y'] = float(map_info[6])
#                header_info['utm_zone'] = int(map_info[7])  # Extract UTM zone
#                header_info['hemisphere'] = map_info[8].strip().lower()  # Extract hemisphere
#    
#    return header_info
#
#def transform_coordinates(x, y, header_info):
#    """
#    Reprojects coordinates from Pseudo-Mercator to UTM.
#
#    :param x: X coordinate in Pseudo-Mercator (EPSG:3857)
#    :param y: Y coordinate in Pseudo-Mercator (EPSG:3857)
#    :param header_info: Dictionary with header metadata
#    :return: Reprojected UTM coordinates (x, y)
#    """
#    # Determine UTM EPSG code based on zone and hemisphere
#    zone = header_info['utm_zone']
#    hemisphere = header_info['hemisphere']
#    utm_epsg = 32600 + zone if hemisphere == 'north' else 32700 + zone
#
#    # Define transformer: Pseudo-Mercator to UTM
#    transformer = Transformer.from_crs("EPSG:3857", f"EPSG:{utm_epsg}", always_xy=True)
#    utm_x, utm_y = transformer.transform(x, y)
#    
#    return utm_x, utm_y
#
#if __name__ == "__main__":
#    # Check if the required arguments are provided
#    if len(sys.argv) != 4:
#        print("Usage: python script.py <hdr_file> <pseudo_mercator_x> <pseudo_mercator_y>")
#        sys.exit(1)
#
#    # Read parameters from the command line
#    hdr_file = sys.argv[1]
#    pseudo_x = float(sys.argv[2])
#    pseudo_y = float(sys.argv[3])
#
#    # Parse the header file
#    header_metadata = parse_header(hdr_file)
#
#    # Transform coordinates from Pseudo-Mercator to UTM
#    utm_x, utm_y = transform_coordinates(pseudo_x, pseudo_y, header_metadata)
#
#    # Convert UTM coordinates to pixel position
#    pixel_pos = utm_to_pixel(utm_x, utm_y, header_metadata)
#    print(f"Pixel Position: X={pixel_pos[0]}, Y={pixel_pos[1]}")


## Following script works if data in file as indicated in MapInfo instead of pseudo mercator 
#
# import math
# import sys
# 
# def utm_to_pixel(x, y, header_info):
#     """
#     Converts UTM coordinates to pixel positions in an ENVI raster.
# 
#     :param x: UTM X coordinate
#     :param y: UTM Y coordinate
#     :param header_info: Dictionary with header metadata (from .hdr file)
#     :return: Tuple (pixel_x, pixel_y) representing the pixel position
#     """
#     # Extract header information
#     upper_left_x = header_info['map_info']['upper_left_x']
#     upper_left_y = header_info['map_info']['upper_left_y']
#     pixel_size_x = header_info['map_info']['pixel_size_x']
#     pixel_size_y = header_info['map_info']['pixel_size_y']
#     
#     # Calculate pixel coordinates
#     pixel_x = (x - upper_left_x) / pixel_size_x
#     pixel_y = (upper_left_y - y) / pixel_size_y  # Note the reversed y-direction
# 
#     # Return as integers (pixel indices)
#     return int(math.floor(pixel_x)), int(math.floor(pixel_y))
# 
# def parse_header(header_path):
#     """
#     Parses the ENVI .hdr file to extract relevant metadata.
#     
#     :param header_path: Path to the ENVI header (.hdr) file
#     :return: Dictionary with parsed header information
#     """
#     header_info = {
#         'map_info': {}
#     }
#     
#     with open(header_path, 'r') as file:
#         for line in file:
#             if 'map info' in line.lower():
#                 # Extract map info details
#                 map_info = line.split('=')[1].strip('{} \n').split(',')
#                 header_info['map_info']['upper_left_x'] = float(map_info[3])
#                 header_info['map_info']['upper_left_y'] = float(map_info[4])
#                 header_info['map_info']['pixel_size_x'] = float(map_info[5])
#                 header_info['map_info']['pixel_size_y'] = float(map_info[6])
#     
#     return header_info
# 
# if __name__ == "__main__":
#     # Check if the required arguments are provided
#     if len(sys.argv) != 4:
#         print("Usage: python script.py <hdr_file> <utm_x> <utm_y>")
#         sys.exit(1)
# 
#     # Read parameters from the command line
#     hdr_file = sys.argv[1]
#     utm_x = float(sys.argv[2])
#     utm_y = float(sys.argv[3])
# 
#     # Parse the header file
#     header_metadata = parse_header(hdr_file)
# 
#     # Convert UTM coordinates to pixel position
#     pixel_pos = utm_to_pixel(utm_x, utm_y, header_metadata)
#     print(f"Pixel Position: X={pixel_pos[0]}, Y={pixel_pos[1]}")

