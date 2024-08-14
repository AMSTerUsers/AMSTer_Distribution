#!/opt/local/bin/python
#
# The script aims at computing a linear regression through all the defo maps from the 
# current directory and output a mean linear velocity, the stdv and the r2 maps. 
#
# Note that to speed up the process, it does not compute the linear regression if the value 
# of the pixel in the 2nd and 3rd maps are zero. In such a case, it would simply store zero  
# for that pixel in the mean linear velocity, stdv, and r2 map. 
# We take the 2nd and 3rd maps as the first map is in principle the reference one, that is
# it is supposed to be zero displacement everywhere. We do not expect exact zero 
# displacements in real cases. Nevertheless, if it would happen by accident in 2nd map,
# there is very little chances taht it would also happen in the 3rd map.  
# We also skip the linear regression if there are 3 successive identical data.   

# Parameters:	- none
#  

# New in Distro V 1.0  20240730: - set up 
# New in Distro V 1.1  20240731: - discards pixels where there are 3 successive identical  
#									values in the data for the reg lin. 
#									Indeed it would attest that 
#									the part 1 and part 2 do not share exactly the same 
#									footprint. We need to keep only the common foorprint
#									among all the pairs. 
#									We do not test 0 because if the foorptint of second part 
#									is smaller than the one from the first part, the non  
#									overlapping part will be filled with the constant offset 
#									bewteen parts.   
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import os
import numpy as np
from scipy.stats import linregress
import re
from datetime import datetime
import shutil

# get type of file and prepare hdr files for results
# Define the pattern to extract the type string
pattern = r'^MSBAS_\d{8}T\d{6}_(UD|EW|NS|LOS)\.bin$'

# List all relevant files in the current directory
files = [f for f in os.listdir('.') if f.startswith('MSBAS_') and f.endswith('.bin')]

# Check if there are any files
if files:
    # Extract the type string from the first file in the list
    match = re.match(pattern, files[0])
    if match:
        type_str = match.group(1)  # Extracted type string
        print(f"Type of files: {type_str}. Computing reg. lin. ; please wait...")

        # Construct the corresponding .hdr file name
        hdr_file_to_cp = files[0].replace('.bin', '.bin.hdr')
    else:
        print("First MSBAS file does not match expected pattern.")
else:
    print("No files named with nmae starting with MSBAS and ending with .bin found.")


def extract_date_from_filename(filename):
    """Extracts the date from the filename in YYYYMMDD format and returns it as a numerical value (days since epoch)."""
    pattern = r'^MSBAS_(\d{8})T\d{6}_(UD|EW|NS|LOS)\.bin$'
    match = re.match(pattern, filename)
    if match:
        date_str = match.group(1)
        #type_str = match.group(2)
        date_obj = datetime.strptime(date_str, '%Y%m%d')
        days_since_epoch = (date_obj - datetime(1970, 1, 1)).days
        return days_since_epoch#, type_str
    else:
        # Print a message and return None for files that don't match the pattern
        print(f"Skipping file: {filename} (not a defo map)")
        return None#, None


def linear_regression_for_pixels(files):
    """Performs linear regression on each pixel's values across time (files) and returns the coefficients, standard deviations, and R-squared values."""
    # Extract dates and sort files by date
    dates_files = [(extract_date_from_filename(f), f) for f in files]
    dates_files = [(d, f) for d, f in dates_files if d is not None]
    
    if not dates_files:
        print("No valid defo maps found. Exiting.")
        return None, None

    dates_files.sort()
    dates, sorted_files = zip(*dates_files)
    
    # Convert dates to numpy array
    X = np.array(dates)
    
    # Read the first file to get the shape
    first_file_data = np.fromfile(sorted_files[0], dtype=np.float32)
    shape = first_file_data.shape
    num_files = len(sorted_files)
    
    # Prepare arrays to store regression coefficients and standard deviations
    coefficients = np.zeros(shape, dtype=np.float32)
    stdevs = np.zeros(shape, dtype=np.float32)
    r_squared = np.zeros(shape, dtype=np.float32)
    
    # Stack all data into a 2D array where each row is a pixel and each column is a time point
    all_data = np.zeros((shape[0], num_files), dtype=np.float32)
    
    for i, filename in enumerate(sorted_files):
        data = np.fromfile(filename, dtype=np.float32)
        all_data[:, i] = data
    
    # Perform linear regression for each pixel
    for pixel_idx in range(shape[0]):
        y = all_data[pixel_idx]
        
        # Check if the second and third values are zero
        if y[1] == 0 and y[2] == 0:
            # Skip linear regression, results remain zero
            coefficients[pixel_idx] = 0
            stdevs[pixel_idx] = 0
            r_squared[pixel_idx] = 0
        else:
            # Check if the same value occurs three times consecutively
            has_consecutive_repeats = any(y[j] == y[j + 1] == y[j + 2] for j in range(len(y) - 2))
            
            if has_consecutive_repeats:
                # Same value occurs three times consecutively, skip linear regression, store zeros
                coefficients[pixel_idx] = 0
                stdevs[pixel_idx] = 0
                r_squared[pixel_idx] = 0
            else:
                # Perform linear regression
                slope, intercept, r_value, _, std_err = linregress(X, y)
                coefficients[pixel_idx] = slope * 365.25  # velocity in m/yr
                stdevs[pixel_idx] = std_err * 365.25  # velocity in m/yr
                r_squared[pixel_idx] = r_value ** 2
    return coefficients, stdevs, r_squared

def save_binary_file(data, filename, type_str):
    """Saves the given data to a binary file."""
    new_filename = f"{filename}_{type_str}_recomputed.bin"
    new_filename_hdr = f"{filename}_{type_str}_recomputed.bin.hdr"
    data.tofile(new_filename)
    # Copy the .hdr file to the new destination
    shutil.copy(hdr_file_to_cp, new_filename_hdr)
    print(f"Create {new_filename_hdr}.")

# Main script
if __name__ == '__main__':
    # List all relevant files in the current directory
    files = [f for f in os.listdir('.') if f.startswith('MSBAS_') and f.endswith('.bin')]
    
    files[0]
    
    # Perform linear regression for each pixel
    coefficients, stdevs, r_squared = linear_regression_for_pixels(files)

    # Use type_str from the first file (assumed to be the same for all)
    #type_str = types[0]
    
    # Save the coefficients and standard deviations to binary files if data was processed
    if coefficients is not None and stdevs is not None:
        save_binary_file(coefficients, 'MSBAS_LINEAR_RATE', type_str)
        save_binary_file(stdevs, 'MSBAS_LINEAR_RATE_STD', type_str)
        save_binary_file(r_squared, 'MSBAS_LINEAR_RATE_R2', type_str)

