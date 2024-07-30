#!/opt/local/bin/python
######################################################################################
# This script computes a Gaussian filter and the gradient along X and Y axis of a
# UTM ENvi Harris image provided as input. 
#
# Parameters: -	UTM ENvi Harris image
#			  - Width of the Gaussian kernel filter (in meters) - e.g. 10.000 (10km)
#			  - xx: for specific case where a water body located to the North of the image 
#				induced a strong NS trend: remove xx first lines and replace with NaN  
#
# Hardcoded:  - 
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# launch command : python thisscript.py param1 param2
#
# New in Distro V 1.1 20240123:	- Rename rep DefoDEM as DEM to avoid clash with some scripts 
#								  searching for comp dir with similar name 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################

import numpy as np
from scipy.ndimage import gaussian_filter
import sys
import os
import subprocess
import math

from numpy import *

import cv2

import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable

input_dem = sys.argv[1] 	# e.g. input_dem = "externalSlantRangeDEM.UTM.30x30.bil"
#FiltWin = float(sys.argv[2])		# e.g. 1, 2 or ...
FiltWin = int(sys.argv[2])			# Size of the kernel Gaussian filter (in m, eg.g 3000)


###### For specific purpose if first lines to be removed 
# Check the number of command-line arguments; if a third one is there, 
# it means that you need to remove that amount of first lines in dem
num_arguments = len(sys.argv)
if num_arguments >= 4:
    first_lines_to_discard = int(sys.argv[3]) 		# Nr of first lines to remove and replace with NaN for specific case where a water body located to the North of the image


# Read the input UTM Envi Harris dem as regular binary file
###########################################################
with open(input_dem, 'rb') as file:
    # Assuming 32-bit floating-point dem, adjust the dtype accordingly
    dem = np.fromfile(file, dtype=np.float32)

# Reads its header to get the nr of rows and columns and pixel size 
###################################################################
# Get the base filename without extension
base_filename, _ = os.path.splitext(input_dem)
# Create the filename for the corresponding .hdr file
header_file = base_filename + '.hdr'

def read_envi_header(header_file):
    # Use grep to extract Lines and Samples lines
    grep_command = f"grep -E '(ines|amples|info)' {header_file}"
    grep_output = subprocess.check_output(grep_command, shell=True, text=True)

    # Process the output to create a dictionary
    header_info = {}
    for line in grep_output.splitlines():
        key, value = map(str.strip, line.split('=', 1))
        header_info[key] = value
    
    return header_info

def get_lines_and_columns(header_info):
    lines = int(header_info['Lines'])
    samples = int(header_info['Samples'])
    return lines, samples

def get_pixel_size(header_info):
    map_info = header_info.get('Map info', '').replace('{', '').replace('}', '').split(',')
    pixel_size_x = float(map_info[5])
    pixel_size_y = float(map_info[6])
    return pixel_size_x, pixel_size_y


header_info = read_envi_header(header_file)
lines, columns = get_lines_and_columns(header_info)
pixel_size_x, pixel_size_y = get_pixel_size(header_info)

print(f'Number of lines: {lines}')
print(f'Number of columns: {columns} \n')

print(f'Pix size in X dir: {pixel_size_x}')
print(f'Pix size in Y dir: {pixel_size_y} \n')

if pixel_size_x == pixel_size_y:
    pixel_size = int(pixel_size_x)
    print(f'Pixel sizes in X and Y directions are the same: {pixel_size} meters')

else:
    print("Pixel sizes in X and Y directions are different; script is not designed for that; exit here.")
    sys.exit(1)  # Use 1 to indicate an error exit status


# Compute the kernel Gaussian filter windows size in pixels 
# to be as close as the desired windows size, though as odd number 
##################################################################
win_size_in_pix = FiltWin / pixel_size
FilWin_in_pixels = math.floor(win_size_in_pix) if math.floor(win_size_in_pix) % 2 != 0 else math.floor(win_size_in_pix) - 1

print(f'Windows size in pixels to get a {FiltWin}m wide Gaussian kernel (made odd): {FilWin_in_pixels} pixels \n')

# and for a 10 km low pass:
Tenkm_in_pix = 10000 / pixel_size
Fil10km_in_pixels = math.floor(Tenkm_in_pix) if math.floor(Tenkm_in_pix) % 2 != 0 else math.floor(Tenkm_in_pix) - 1

# Read the dem as matrix
########################
dem = dem.reshape((lines ,columns))

# In case of specific purpose
#############################
if num_arguments >= 4:
    # remove 100 first lines
    dem_full = dem
    dem = dem[first_lines_to_discard:, :]
    
# Replace NaN with zeros to avoid gaps in filtered dem
# This is necessary if using GaussianBlur with large window
###########################################################
where_are_NaNs = isnan(dem)
dem[where_are_NaNs] = 0


## Apply the Gaussian filter
#############################
## option 0: use Gaussian filter with sigma instead of kernel window width. 
# In that case, all the compitations about the number of pixels etc are wrong.   
#filtered_dem = gaussian_filter(dem, sigma=FiltWin, mode='constant', cval=np.nan)

## option 1: low and high pass filter
## Remove 10km wide low pass filtered dem from dem 
#filtered_10kmlowpass_dem = cv2.GaussianBlur(dem, (Fil10km_in_pixels, Fil10km_in_pixels), 0)  # Adjust the kernel size (e.g., (5, 5)) and other parameters as needed
#high_pass_filtered_dem = dem - filtered_10kmlowpass_dem
## Apply Gaussian filter with cv2 to high pass dem
#filtered_dem = cv2.GaussianBlur(high_pass_filtered_dem, (FilWin_in_pixels, FilWin_in_pixels), 0)  # Adjust the kernel size (e.g., (5, 5)) and other parameters as needed

## option 2: simple low pass filter filter
## Apply Gaussian filter with cv2 to dem
filtered_dem = cv2.GaussianBlur(dem, (FilWin_in_pixels, FilWin_in_pixels), 0)  # Adjust the kernel size (e.g., (5, 5)) and other parameters as needed

# Compute gradient in the y-direction (replace this with your specific gradient computation)
gradient_y = -1 * np.gradient(filtered_dem, axis=0) / np.array([pixel_size]) 		# -1 because of NS axis convention in numpy (origin = upper left) compared to utm (origin = lower left) 

# Compute the gradient along the X direction
gradient_x = np.gradient(filtered_dem, axis=1) / np.array([pixel_size]) 

# Clip gradient
###############
threshold = 0.6	# in m/m

# Create a mask for absolute values larger than threshold in gradients
mask_gradient_x = np.abs(gradient_x) > threshold
mask_gradient_y = np.abs(gradient_y) > threshold

# Set gradient to nan where gradient is to be masked
gradient_x[mask_gradient_x] = np.nan
gradient_y[mask_gradient_y] = np.nan

# replace zero with NaN
mask_gradient_x = np.where(mask_gradient_x == 0, np.nan, mask_gradient_x)
mask_gradient_y = np.where(mask_gradient_y == 0, np.nan, mask_gradient_y)



# In case of specific purpose
#############################
if num_arguments >= 4:
    # Create an array with NaN values of the same shape as the original dem matrix
    nan_lines = np.full((first_lines_to_discard, columns), np.nan)
    # Stack the nan_lines on top of the original matrix
    gradient_x = np.vstack((nan_lines, gradient_x))
    gradient_y = np.vstack((nan_lines, gradient_y))

# Write the filtered and gradient dem back to binary files
output_file_y = "DEM_grad_north.bin"
with open(output_file_y, 'wb') as file:
    gradient_y.flatten().astype(np.float32).tofile(file)

output_file_x = "DEM_grad_east.bin"
with open(output_file_x, 'wb') as file:
    gradient_x.flatten().astype(np.float32).tofile(file)


# Make a plot and save as jpg
#############################

# Plotting contours of the DEM on gradient_y and gradient_x with color-coded gradients, a scale bar,
# values on contour lines, and placing the scale bar a little further down
plt.figure(figsize=(12, 8))

# In case of specific purpose
#############################
if num_arguments >= 4:
    # remove 100 first lines
    dem = dem_full

# Contour levels for increments of 100 meters
contour_levels_100m = list(range(0, int(np.nanmax(dem))+100, 100))

# Plotting contours on the north-south gradient with a color scale
###################################################################
plt.subplot(1, 2, 1)

vmax_ns = max(abs(np.nanmin(gradient_y)), np.nanmax(gradient_y))
img_ns = plt.imshow(gradient_y, cmap='bwr', origin='upper', vmin=-vmax_ns, vmax=vmax_ns)  # Blue to White to Red colormap
#img_ns = plt.imshow(gradient_y, cmap='bwr', origin='upper')  # Blue to White to Red colormap
plt.title(f'DEM contours wrapped on North-South Gradient \nwith filter windows size {FiltWin} meters ({FilWin_in_pixels} pixels)')
#contour_levels = 5  # Adjust the number of contour levels as needed
#contour_ns = plt.contour(dem, levels=contour_levels, colors='black', linewidths=0.5)

contour_ns = plt.contour(dem, levels=contour_levels_100m, colors='black', linewidths=0.5)


# Adding legends to X and Y axes
plt.xlabel(f'Nr of pixels in X direction (1 pix = {pixel_size} m)')
plt.ylabel(f'Nr of pixels in Y direction (1 pix = {pixel_size} m)')

plt.clabel(contour_ns, inline=True, fmt='%1.0f', fontsize=8)  # Print values on contour lines

# Adding a color scale bar
divider_ns = make_axes_locatable(plt.gca())
cax_ns = divider_ns.append_axes("bottom", size="5%", pad=0.6)  # Adjust the pad value for positioning
plt.colorbar(img_ns, cax=cax_ns, orientation="horizontal", label='Gradient [m/m]')

# Plotting contours on the east-west gradient with a color scale
###################################################################
plt.subplot(1, 2, 2)

vmax_ew = max(abs(np.nanmin(gradient_x)), np.nanmax(gradient_x))

img_ew = plt.imshow(gradient_x, cmap='bwr', origin='upper', vmin=-vmax_ew, vmax=vmax_ew)  # Blue to White to Red colormap
plt.title(f'DEM contours wrapped on East-West Gradient \nwith filter windows size {FiltWin} meters ({FilWin_in_pixels} pixels)')

contour_ew = plt.contour(dem, levels=contour_levels_100m, colors='black', linewidths=0.5)
#contour_ew = plt.contour(dem, levels=contour_levels, colors='black', linewidths=0.5)

# Adding legends to X and Y axes
plt.xlabel(f'Nr of pixels in X direction (1 pix = {pixel_size} m)')
plt.ylabel(f'Nr of pixels in Y direction (1 pix = {pixel_size} m)')

plt.clabel(contour_ew, inline=True, fmt='%1.0f', fontsize=8)  # Print values on contour lines

# Adding a color scale bar
divider_ew = make_axes_locatable(plt.gca())
cax_ew = divider_ew.append_axes("bottom", size="5%", pad=0.6)  # Adjust the pad value for positioning
plt.colorbar(img_ew, cax=cax_ew, orientation="horizontal", label='Gradient [m/m]')

# Adjust layout
plt.tight_layout()

# Save the plot as a JPEG image
plt.savefig(f'contour_plot_FiltKernelSize{FilWin_in_pixels}.jpg', dpi=300)

# Show the plot
#plt.show()
