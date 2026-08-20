#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script computes a Gaussian filter and the gradient along X and Y axis of a
# UTM ENvi Harris image provided as input. 
#
# Parameters: -	UTM ENvi Harris image
#			  - Width of the Gaussian kernel filter (in meters) - e.g. 10.000 (10km)
#			Optional (after the two above, in any order): 
#			  - threshold=VALUE : gradient clipping threshold in m/m (default 0.6, i.e. ~31 deg slope). 
#				Pixels where |gradient| > threshold are set to NaN. Use a value <= 0 to disable clipping. 
#			  - firstlines=xx (or a bare integer xx) : for specific case where a water body located to 
#				the North of the image induced a strong NS trend: remove xx first lines and replace with NaN  
#
# Hardcoded:  - 
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# launch command : python thisscript.py param1 param2
#
# New in Distro V 1.1 20240123:	- Rename rep DefoDEM as DEM to avoid clash with some scripts 
#								  searching for comp dir with similar name 
# New in Distro V 2.0 20250813:	- launched from python3 venv
# New in Distro V 2.1 20251224:	- cope with dem.bin or dem and dem.hdr
#								- cope with .hdr containing lines or Lines and samples or Samples
#								- cope with .hdr containing extra white spaces between fields and values  
# New in Distro V 2.2 20260730:	- remove unused lines mask_gradient_x and mask_gradient_y 
# New in Distro V 2.3 20260730:	- threshold for gradient clipping is now an optional parameter 
#								  (threshold=VALUE, default 0.6 m/m; <= 0 disables clipping) 
#								- optional parameters (threshold, firstlines) parsed by name in any order, 
#								  a bare integer is still understood as the nr of first lines to discard 
#								- restore the gradient clipping that V2.2 had accidentally broken (the mask  
#								  definition lines had been commented out while still being used) and remove 
#								  the actually-unused np.where(... == 0 ...) lines 
# New in Distro V 2.4 20260730:	- add the threshold in the name of the contour plot jpg, i.e. 
#								  contour_plot_FiltKernelSizeXXX_ThresholdYYY.jpg 
#								- write ENVI headers DEM_grad_north.hdr and DEM_grad_east.hdr with the 
#								  Gaussian filter width and the clipping threshold added to the description 
#								  field, while keeping the pre-existing description (e.g. path to original DEM) 
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################

import numpy as np
from scipy.ndimage import gaussian_filter
import sys
import os
import re
import subprocess
import math

from numpy import *

import cv2

import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable

input_dem = sys.argv[1] 	# e.g. input_dem = "externalSlantRangeDEM.UTM.30x30.bil"
#FiltWin = float(sys.argv[2])		# e.g. 1, 2 or ...
FiltWin = int(sys.argv[2])			# Size of the kernel Gaussian filter (in m, eg.g 3000)


###### Optional parameters
# Defaults 
threshold = 0.6				# gradient clipping threshold in m/m: pixels where |gradient| > threshold are set to NaN.
							#   0.6 m/m ~ 31 deg slope. Pass a value <= 0 to disable the clipping. 
first_lines_to_discard = 0	# Nr of first (North) lines to blank out with NaN. Special case where a water body 
							#   located to the North of the image induces a strong NS trend. 
remove_first_lines = False

# Optional parameters are given after the two mandatory ones (input_dem and FiltWin), in any order:
#   - threshold=VALUE  (or thres=VALUE / clip=VALUE) : gradient clipping threshold in m/m (e.g. threshold=0.8)
#   - firstlines=VALUE (or first_lines=VALUE)        : nr of first lines to discard 
#   - a bare integer                                 : kept for backward compatibility -> nr of first lines to discard 
for arg in sys.argv[3:]:
    key_val = arg.split('=', 1)
    if len(key_val) == 2:
        key = key_val[0].strip().lower()
        val = key_val[1].strip()
        if key in ('threshold', 'thres', 'clip'):
            threshold = float(val)
        elif key in ('firstlines', 'first_lines', 'firstlinestodiscard'):
            first_lines_to_discard = int(val)
        else:
            print(f'Ignoring unknown optional parameter: {arg}')
    else:
        # bare value: old positional behaviour -> nr of first lines to discard 
        first_lines_to_discard = int(arg)

remove_first_lines = first_lines_to_discard > 0

if threshold > 0:
    print(f'Gradient clipping threshold: {threshold} m/m (pixels with |gradient| larger than that are set to NaN)')
else:
    print('Gradient clipping disabled (threshold <= 0)')
if remove_first_lines:
    print(f'First {first_lines_to_discard} lines will be blanked out with NaN \n')


# Read the input UTM Envi Harris dem as regular binary file
###########################################################
with open(input_dem, 'rb') as file:
    # Assuming 32-bit floating-point dem, adjust the dtype accordingly
    dem = np.fromfile(file, dtype=np.float32)

# Reads its header to get the nr of rows and columns and pixel size 
###################################################################
### Get the base filename without extension
###base_filename, _ = os.path.splitext(input_dem)
### Create the filename for the corresponding .hdr file
###header_file = base_filename + '.hdr'  # crashes if hdr is at the same level as .bin instead of .bin.hdr for instance 
def find_envi_header(input_dem):
    candidates = []

    # Case 1: input_dem.bin → input_dem.hdr
    base, ext = os.path.splitext(input_dem)
    if ext:
        candidates.append(base + '.hdr')

    # Case 2: input_dem → input_dem.hdr
    candidates.append(input_dem + '.hdr')

    for hdr in candidates:
        if os.path.isfile(hdr):
            return hdr

    raise FileNotFoundError(
        f"No ENVI header found for {input_dem}. Tried: {candidates}"
    )

header_file = find_envi_header(input_dem)

#def read_envi_header(header_file):
#    # Use grep to extract Lines and Samples lines
#    grep_command = f"grep -E '(ines|amples|info)' {header_file}"
#    grep_output = subprocess.check_output(grep_command, shell=True, text=True)
#
#    # Process the output to create a dictionary
#    header_info = {}
#    for line in grep_output.splitlines():
#        key, value = map(str.strip, line.split('=', 1))
#        header_info[key] = value
#    
#    return header_info
def read_envi_header(header_file):
    # Use grep to extract Lines, Samples, and Map info lines
    grep_command = f"grep -E '(ines|amples|info)' {header_file}"
    grep_output = subprocess.check_output(grep_command, shell=True, text=True)

    header_info = {}
    for line in grep_output.splitlines():
        if '=' in line:
            key, value = line.split('=', 1)
            key = key.strip().lower()  # lowercase keys, remove extra spaces
            value = value.strip()
            header_info[key] = value

    return header_info
    
#def get_lines_and_columns(header_info):
#    lines = int(header_info['Lines'])
#    samples = int(header_info['Samples'])
#    return lines, samples
#
#def get_pixel_size(header_info):
#    map_info = header_info.get('Map info', '').replace('{', '').replace('}', '').split(',')
#    pixel_size_x = float(map_info[5])
#    pixel_size_y = float(map_info[6])
#    return pixel_size_x, pixel_size_y

def get_lines_and_columns(header_info):
    lines = int(header_info['lines'])
    samples = int(header_info['samples'])
    return lines, samples

def get_pixel_size(header_info):
    map_info = header_info.get('map info', '').replace('{', '').replace('}', '').split(',')
    pixel_size_x = float(map_info[5])
    pixel_size_y = float(map_info[6])
    return pixel_size_x, pixel_size_y


def write_gradient_header(src_header_file, dst_header_file, extra_description):
    # Create an ENVI .hdr for a gradient file by copying the (cropped) DEM header  
    # and appending the Gaussian filter width and clipping threshold to its 'description' 
    # field. The pre-existing description (which typically holds the path to the original 
    # DEM) is KEPT, so nothing that was there before is lost; the new info is added after it. 
    # The gradient files have the same dimensions, data type (Float32) and map info as the 
    # input DEM, so copying the DEM header is correct. 
    with open(src_header_file, 'r') as f:
        hdr = f.read()
    # grab the existing description = { ... } content (possibly spanning several lines), if any 
    match = re.search(r'description\s*=\s*\{(.*?)\}', hdr, flags=re.IGNORECASE | re.DOTALL)
    existing_desc = match.group(1).strip() if match else ''
    # remove the existing description block from the header body before re-appending a merged one 
    hdr = re.sub(r'description\s*=\s*\{.*?\}', '', hdr, flags=re.IGNORECASE | re.DOTALL)
    hdr = hdr.rstrip() + '\n'
    # merged description: original content first (e.g. path to the original DEM), then new info 
    if existing_desc:
        new_desc = existing_desc.rstrip() + '\n' + extra_description
    else:
        new_desc = extra_description
    hdr = hdr + 'description = {\n' + new_desc + '}\n'
    with open(dst_header_file, 'w') as f:
        f.write(hdr)
    
    
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
if remove_first_lines:
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
# Blank out (set to NaN) the pixels where the local (filtered) slope exceeds the threshold. 
# threshold is provided as an optional parameter (default 0.6 m/m); a value <= 0 disables the clipping. 
if threshold > 0:
    # Create a mask for absolute values larger than threshold in gradients
    mask_gradient_x = np.abs(gradient_x) > threshold
    mask_gradient_y = np.abs(gradient_y) > threshold

    # Set gradient to nan where gradient is to be masked
    gradient_x[mask_gradient_x] = np.nan
    gradient_y[mask_gradient_y] = np.nan



# In case of specific purpose
#############################
if remove_first_lines:
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

# Write the corresponding ENVI headers, keeping track of the Gaussian filter width and 
# the gradient clipping threshold used, in the 'description' field 
if threshold > 0:
    threshold_str = f'{threshold} m/m'
else:
    threshold_str = 'disabled (threshold <= 0)'
description_text = (f'AMSTer Filter_and_Gradient.py gradient. '
                    f'Gaussian filter width = {FiltWin} m ({FilWin_in_pixels} pixels). '
                    f'Gradient clipping threshold = {threshold_str}.\n')
write_gradient_header(header_file, "DEM_grad_north.hdr", description_text)
write_gradient_header(header_file, "DEM_grad_east.hdr", description_text)


# Make a plot and save as jpg
#############################

# Plotting contours of the DEM on gradient_y and gradient_x with color-coded gradients, a scale bar,
# values on contour lines, and placing the scale bar a little further down
plt.figure(figsize=(12, 8))

# In case of specific purpose
#############################
if remove_first_lines:
    # remove 100 first lines
    dem = dem_full

# Contour levels for increments of 100 meters
contour_levels_100m = list(range(0, int(np.nanmax(dem))+100, 100))

# Plotting contours on the north-south gradient with a color scale
###################################################################
plt.subplot(1, 2, 1)

vmax_ns = np.nanmax(np.abs(gradient_y))		# note: builtin max is shadowed by 'from numpy import *', so use np here
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

vmax_ew = np.nanmax(np.abs(gradient_x))		# note: builtin max is shadowed by 'from numpy import *', so use np here

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
if threshold > 0:
    threshold_tag = f'{threshold}'
else:
    threshold_tag = 'None'
plt.savefig(f'contour_plot_FiltKernelSize{FilWin_in_pixels}_Threshold{threshold_tag}.jpg', dpi=300)

# Show the plot
#plt.show()
