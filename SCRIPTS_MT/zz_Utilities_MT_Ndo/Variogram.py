#!/opt/local/bin/python
######################################################################################
# This script computes a variogram of a velocity map provided as an Envi Harris image.
# The semivairiance displayed in the plot is  a measure of the average squared difference
# between points separated by a certain lag distance. It is calculated using the following formula:
#
#        1    N(h)
# Y(h)= ----  SUM[ Z(xi) - Z(xi+h)]^2
#       2N(h) i=1
#
# where Y(h)  = the semivariance at lag distance h
#		Z(xi) = the value of the variable at location xi
#		N(h)  = the number of pairs of points separated by lag distance h
#
# Units of the variogram are square of initial units. Normally, velocity maps from MSBAS 
#    inversions are in m/yr. Here we multiply the value time 100 for being in cm/yr.
#
# If image is too big, it can crash for memory issues... Try to crop the image by providing 
# 4 more parameters (First Line, First Col, Nr of lines and Nr of Columns).  
#
# Beware: processing a L x C image in a float 32 format (4 bytes per pixel) 
#         requires the following amount of RAM:
#
# 	                          (L x C) x (L x C) x 8
# 	Total Memory= L × C × 4 + ---------------------
# 	                                    2
#
#
# Parameters: -	Envi Harris velocity map (e.g. /Your/Path/MSBAS_LINEAR_RATE_UD.bin)
#				Note that it expects a header file with the same name + extension .hdr
#			  - n_lags parameter for Variogram, that is the number of lag bins  
#				(or intervals) into which the distance between data points is divided for 
#				the purpose of estimating the semivariance
#			  - the ML factor to reduce the size of the image and avoid memory overflow (1 keeps full res)
#			  - optional to crop the image: First Line, First Col, Nr of lines and Nr of Columns
#
# Hardcoded:  - 
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# launch command : python thisscript.py param1 param2
#
# New in Distro V 1.0 20241024:	- set up
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################

from skgstat import Variogram
import numpy as np
import matplotlib.pyplot as plt
import sys
import os
import subprocess

# Ensure there are enough command-line arguments
if len(sys.argv) < 4:  # Check for <input_img>, <n_lags>, <ML>
    print("Usage: script.py <input_img> <n_lags> <ML> [<FirstLines> <FirstColumns> <NumberOfLines> <NumberOfColumns>]")
    sys.exit(1)

input_img = sys.argv[1]
nlags = int(sys.argv[2])
mlfactor = int(sys.argv[3])

# Check if cropping parameters are provided
if len(sys.argv) > 7:
    FirstLines = int(sys.argv[4])
    FirstColumns = int(sys.argv[5])
    NumberOfLines = int(sys.argv[6])
    NumberOfColumns = int(sys.argv[7])
else:
    FirstLines = None
    FirstColumns = None
    NumberOfLines = None
    NumberOfColumns = None

# Check if input file exists
if not os.path.isfile(input_img):
    print(f"Input file {input_img} does not exist.")
    sys.exit(1)

header_file = input_img + '.hdr'

# Read and process the header file
def read_envi_header(header_file):
    grep_command = f"grep -E '(ines|amples|info)' {header_file}"
    grep_output = subprocess.check_output(grep_command, shell=True, text=True)
    header_info = {}
    for line in grep_output.splitlines():
        key, value = map(str.strip, line.split('=', 1))
        header_info[key] = value
    return header_info

def get_pixel_size(header_info):
    map_info = header_info.get('Map info', '').replace('{', '').replace('}', '').split(',')
    pixel_size_x = float(map_info[5])
    pixel_size_y = float(map_info[6])
    return pixel_size_x, pixel_size_y

header_info = read_envi_header(header_file)
lines, columns = int(header_info['Lines']), int(header_info['Samples'])
pixel_size_x, pixel_size_y = map(float, get_pixel_size(header_info))

print(f'\nNumber of lines: {lines}, Number of columns: {columns}')
print(f'Pixel size in X dir: {pixel_size_x}, Pixel size in Y dir: {pixel_size_y} \n')

# Read the data
with open(input_img, 'rb') as file:
    img = np.fromfile(file, dtype=np.float32)

data = img.reshape((lines, columns)) * 100

# Crop the data if cropping parameters are provided
if FirstLines is not None and FirstColumns is not None and NumberOfLines is not None and NumberOfColumns is not None:
    data = data[FirstLines:FirstLines + NumberOfLines, FirstColumns:FirstColumns + NumberOfColumns]
    plt.figure(figsize=(10, 8))
    plt.imshow(data, cmap='jet', origin='upper')
    plt.colorbar(label='Velocity (cm/yr)')
    plt.title('Cropped Image')
    plt.xlabel('Columns')
    plt.ylabel('Lines')
    plt.grid(False)
    #plt.show()
    plt.savefig(f'{input_img}_Crop_{FirstLines}_{FirstColumns}_{NumberOfLines}_{NumberOfColumns}.jpg', dpi=300)


# Average the pixels by the given factor
if mlfactor > 1:
    num_lines, num_columns = data.shape
    new_lines = num_lines - (num_lines % mlfactor)
    new_columns = num_columns - (num_columns % mlfactor)
    data = data[:new_lines, :new_columns]

    shape = (data.shape[0] // mlfactor, mlfactor, data.shape[1] // mlfactor, mlfactor)
    data = data.reshape(shape).mean(axis=(1, 3))

    plt.figure(figsize=(10, 8))
    plt.imshow(data, cmap='jet', origin='upper')
    plt.colorbar(label='Velocity (cm/yr)')
    plt.title('Cropped Image multilooked by {mlfactor}')
    plt.xlabel('Columns')
    plt.ylabel('Lines')
    plt.grid(False)
    #plt.show()
    plt.savefig(f'{input_img}_Crop_{FirstLines}_{FirstColumns}_{NumberOfLines}_{NumberOfColumns}_ML_{mlfactor}.jpg', dpi=300)
    lines = new_lines
    columns = new_columns

# Handle NaN values
data[np.isnan(data)] = 0

# Get coordinates and values
coords = np.column_stack(np.where(~np.isnan(data)))
values = data[~np.isnan(data)] 


# Create and plot the semivariogram
#V = Variogram(coords, values, normalize=True, n_lags=nlags, model='spherical', metric='euclidean')
V = Variogram(coords, values, normalize=False, n_lags=nlags, model='spherical')

plt.figure(figsize=(8, 6))
V.plot()
plt.title('Semivariogram (cm/yr)^2')
plt.grid(True)
plt.savefig(f'{input_img}_Vario_Crop_{FirstLines}_{FirstColumns}_{NumberOfLines}_{NumberOfColumns}_Nlags_{nlags}_ML_{mlfactor}.jpg', dpi=300)

# Calculate lag distances
if mlfactor > 1:
    lag_distances = V.bins * pixel_size_x * mlfactor / 1000  # Convert to kilometers
else:
    lag_distances = V.bins * pixel_size_x / 1000  # Convert to kilometers

# Plot semivariogram vs distance
plt.figure(figsize=(8, 6))
plt.plot(lag_distances, V.experimental, marker='o', linestyle='-')
plt.title('Semivariogram')
plt.xlabel('Lag Distance (km)')
plt.ylabel('Semivariance (cm/yr)^2')
plt.grid(True)
plt.xlim([0, np.max(lag_distances)])
plt.savefig(f'{input_img}_Vario_Crop__{FirstLines}_{FirstColumns}_{NumberOfLines}_{NumberOfColumns}_Nlags_{nlags}_ML_{mlfactor}_in_km.jpg', dpi=300)

plt.show()
