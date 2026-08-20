#!/opt/local/amster_python_env/bin/python
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
# New in Distro V 2.0 20250813:	- launched from python3 venv
# New in Distro V 3.0 20260202:	- rewritten to make it much faster using vectorized implementation 
#								  numerically equivalent to scipy.linregress
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import os
import re
import shutil
import numpy as np
from datetime import datetime

# -------------------------------------------------------------
# File pattern
# get type of file and prepare hdr files for results
# Define the pattern to extract the type string
# -------------------------------------------------------------

pattern = r'^MSBAS_\d{8}T\d{6}_(UD|EW|NS|LOS)\.bin$'

files = [f for f in os.listdir('.') if re.match(pattern, f)]
if not files:
    raise RuntimeError("No MSBAS_*.bin files found")

match = re.match(pattern, files[0])
type_str = match.group(1)
hdr_file_to_cp = files[0].replace('.bin', '.bin.hdr')

print(f"Type of files: {type_str}. Computing reg. lin. (FAST mode)...")


# -------------------------------------------------------------
# Date extraction
# -------------------------------------------------------------
def extract_date_from_filename(filename):
    match = re.match(pattern, filename)
    if match:
        date_str = filename.split('_')[1][:8]
        date_obj = datetime.strptime(date_str, '%Y%m%d')
        return (date_obj - datetime(1970, 1, 1)).days
    return None


# -------------------------------------------------------------
# Fast vectorized regression
# -------------------------------------------------------------
def linear_regression_for_pixels(files):

    # Sort files by acquisition date
    dates_files = [(extract_date_from_filename(f), f) for f in files]
    dates_files = [(d, f) for d, f in dates_files if d is not None]
    dates_files.sort()

    dates, sorted_files = zip(*dates_files)
    X = np.asarray(dates, dtype=np.float64)

    # Read first file to get size
    first = np.fromfile(sorted_files[0], dtype=np.float32)
    n_pixels = first.size
    n_times = len(sorted_files)

    # Load all data
    all_data = np.zeros((n_pixels, n_times), dtype=np.float32)
    for i, f in enumerate(sorted_files):
        all_data[:, i] = np.fromfile(f, dtype=np.float32)

    # Output arrays
    coefficients = np.zeros(n_pixels, dtype=np.float32)
    stdevs = np.zeros(n_pixels, dtype=np.float32)
    r_squared = np.zeros(n_pixels, dtype=np.float32)

    # Skip mask (same logic as original) -  Check if the second and third values are zero
    ##valid = ~((all_data[:, 1] == 0) & (all_data[:, 2] == 0))
    ##if not np.any(valid):
    ##    return coefficients, stdevs, r_squared
    # 1) skip if 2nd and 3rd maps are zero
    skip_zero = (all_data[:, 1] == 0) & (all_data[:, 2] == 0)
    
    # 2) skip if any 3 consecutive identical values
    # shape: (n_pixels, n_times-2)
    triple_equal = (
        (all_data[:, :-2] == all_data[:, 1:-1]) &
        (all_data[:, 1:-1] == all_data[:, 2:])
    )
    
    skip_triple = np.any(triple_equal, axis=1)
    
    # Final valid mask
    valid = ~(skip_zero | skip_triple)
    
    if not np.any(valid):
        return coefficients, stdevs, r_squared

    # --- Regression math (identical to linregress) ---
    X_mean = X.mean()
    Xc = X - X_mean
    Sxx = np.sum(Xc ** 2)

    Y = all_data[valid].astype(np.float64)
    Y_mean = Y.mean(axis=1, keepdims=True)
    Yc = Y - Y_mean

    # slope
    Sxy = Yc @ Xc
    slope = Sxy / Sxx

    # fitted values
    Yfit = slope[:, None] * Xc

    # residuals
    resid = Yc - Yfit
    ss_res = np.sum(resid ** 2, axis=1)
    ss_tot = np.sum(Yc ** 2, axis=1)

    # r²
    r2 = 1.0 - ss_res / ss_tot

    # standard error of slope (same as linregress)
    n = X.size
    std_err = np.sqrt(ss_res / (n - 2)) / np.sqrt(Sxx)

    # Store results (m/yr)
    coefficients[valid] = slope * 365.25
    stdevs[valid] = std_err * 365.25
    r_squared[valid] = r2.astype(np.float32)

    return coefficients, stdevs, r_squared


# -------------------------------------------------------------
# Save results
# -------------------------------------------------------------
def save_binary_file(data, basename):
    out_bin = f"{basename}_{type_str}_recomputed.bin"
    out_hdr = out_bin + ".hdr"
    data.tofile(out_bin)
    shutil.copy(hdr_file_to_cp, out_hdr)
    print(f"Created {out_bin}")


# -------------------------------------------------------------
# Main
# -------------------------------------------------------------
if __name__ == "__main__":

    coeffs, stdv, r2 = linear_regression_for_pixels(files)

    save_binary_file(coeffs, "MSBAS_LINEAR_RATE")
    save_binary_file(stdv, "MSBAS_LINEAR_RATE_STD")
    save_binary_file(r2, "MSBAS_LINEAR_RATE_R2")


