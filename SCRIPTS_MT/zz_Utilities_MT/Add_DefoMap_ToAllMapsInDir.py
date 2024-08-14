#!/opt/local/bin/python
#
# This script adds to all deformation maps in the current dir a given defo map of the same size. 
# That defo map is the difference between two defo maps provided as parameters. 
# All the defo maps of the pwd must be named like MSBAS_YYYYMMDDThhmmss_[UD or EW].bin
# 
# This can be used to add an offset to a series of defo map when msbas inversion is performed 
# in two parts. It is then recommended to perform the msbas inversions as follow: 
# - part 1: from beginning to a given date (at least 7 times the max temporal baseline taken for the inversion, i.e. BT),
# - part 2: from 3 times max BT before the end or part 1 till the end (must be at least 7 time max BT long). 
# Note that if max BT is short (i.e. equivalent of only a small number of orbit cycles), then it is advised to 
# take 1 year instead of BT in the following reasoning. 
#
# The date of the 2 defo maps (taken from part1 and part 2) provided as parameters must be of the same date 
# (that is the date of day at about 1.5 BT before the end of part1), as follow (see vertical arrow): 
#
#                                                        2 defo maps
#                                                            |
#                                                            v
# begin   BT    BT    BT                            BT    BT    BT    end
#   |xxxxx|-----|-----|------- ...Part1... ---------|-----|ooooo|xxxxx|
#
# 												  begin   BT    BT    BT                            BT    BT    BT    end
# 												    |xxxxx|ooooo|-----|------- ...Part2... ---------|-----|-----|xxxxx|
# where - = good results in each TS
#		x = less accurate msbas results 
#		o = overlapping good results in each TS 
#
# By choosing that date, there must be nearly no offset left between part1 and 2 time series. Only 
# the last BT of part 1 and the first BT of part 2 are affected by insufficient number of pairs 
# taken for the inversion during these periods of time. 
#
# Hence, to merge the 2 parts and get a full time series (part 1 + part 2), consider merging 
# (part1 - last BT) and (part2 - first BT), that is 
#                                                        2 defo maps
#                                                            |
#                                                            v
# begin   BT    BT    BT                            BT    BT    
#   |xxxxx|-----|-----|------- ...Part1... ---------|-----|ooo  BT    BT                            BT    BT    BT    end
# 												              ooo|-----|------- ...Part2... ---------|-----|-----|xxxxx|
#
#
# WARNING: it must be run in the directory containing all the defo maps. 
#          IT WILL OVERWRITE THE DEFO MAPS !!!
#
# Parameters: 	- defo map from part 1 at date = last 1.5 BT   
#				- defo map from part 2 at date = first 1.5 BT 
#
# New in Distro V 1.0  20240729: - set up 
# New in Distro V 1.1  20240812: - adapt pattern to LOS modes as well
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


import os
import numpy as np
import sys
import re

print("")

def is_valid_msb_name(filename):
    """Check if the filename follows the MSBAS_YYYYMMDDTHHmmss_UD.bin or MSBAS_YYYYMMDDTHHmmss_EW.bin pattern."""
    pattern = r'^MSBAS_\d{8}T\d{6}_(UD|EW|NS|LOS)\.bin$'
    return re.match(pattern, filename) is not None

def add_reference_from_files(reference_file1, reference_file2, directory='.'):
    # Read the reference data
    reference_data1 = np.fromfile(reference_file1, dtype=np.float32)
    reference_data2 = np.fromfile(reference_file2, dtype=np.float32)

    reference_data = reference_data1 - reference_data2

    
    # Iterate over each file in the directory
    for filename in os.listdir(directory):
        if is_valid_msb_name(filename):
            # Full path to the file
            file_path = os.path.join(directory, filename)
            
            # Read the current file's data
            file_data = np.fromfile(file_path, dtype=np.float32)
            
            # Ensure the files have the same size
            if file_data.shape != reference_data.shape:
                print(f"Skipping {filename}: size mismatch.")
                continue
            
            # Subtract reference data from the file's data
            new_data = file_data + reference_data 
            
            # Write the new data back to the binary file
            new_data.tofile(file_path)
            print(f"Processed {filename}.")
        else:
            print(f"Skipping {filename}: Not a defo map - skip it.")

# Usage
if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python script.py reference_file_part1 reference_file_part2")
        sys.exit(1)
    
    reference_file1 = sys.argv[1]
    reference_file2 = sys.argv[2] 
    
    # Check if the reference file exists
    if not os.path.exists(reference_file1):
        print(f"Reference file1 {reference_file1} not found.")
        sys.exit(1)
        if not os.path.exists(reference_file2):
           print(f"Reference file2 {reference_file2} not found.")
           sys.exit(1)
   
    # Perform the subtraction
    add_reference_from_files(reference_file1, reference_file2)
