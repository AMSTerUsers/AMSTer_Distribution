#!/opt/local/bin/python
######################################################################################
# This script replaces 255 in 0 (to keep) and 0 in 1 (to mask) from a file in bytes.
# It renames the outputfile with an extra string _255and0_to_0and1.
# It also copy input the header file as the output header file
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: - input file (in bytes)
#
# launch command : python thisscript.py param1 
#
# New in Distro V 1.0 20214418:	- setup
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import numpy as np
import sys
import os
import shutil  # For copying files

if len(sys.argv) != 2:
    print("Usage: python script.py input_file")
    sys.exit(1)

input_file = sys.argv[1]

# Derive the base name (without extension) and the extension
base_name, ext = os.path.splitext(input_file)

# Add the trailing string to the base name
output_file = f"{base_name}_255and0_to_0and1{ext}"

# Possible header file names
input_hdr_file_with_ext = f"{input_file}.hdr"
input_hdr_file_no_ext = f"{os.path.splitext(input_file)[0]}.hdr"

# Derive output header file name
output_hdr_file = f"{output_file}.hdr"

try:
    # Load the ENVI image file as a NumPy array (assumes float32 input)
    data = np.fromfile(input_file, dtype=np.byte)

    # Create a new array for the output
    output_data = np.zeros_like(data, dtype=np.uint8)

    # Replace 255.0 with 0
    output_data[data == 255.0] = 0

    # Replace 0.0 with 1
    output_data[data == 0.0] = 1

    # Save the modified data to the output file
    output_data.tofile(output_file)

    print(f"\nProcessing complete. Modified file saved as '{output_file}'.")

    # Check for the appropriate header file
    if os.path.exists(input_hdr_file_with_ext):
        shutil.copy(input_hdr_file_with_ext, output_hdr_file)
        print(f"Header file copied from '{input_hdr_file_with_ext}' to '{output_hdr_file}'.\n")
    elif os.path.exists(input_hdr_file_no_ext):
        shutil.copy(input_hdr_file_no_ext, output_hdr_file)
        print(f"Header file copied from '{input_hdr_file_no_ext}' to '{output_hdr_file}'.\n")
    else:
        print("Warning: No header file found. Ensure the output file has the correct header manually.\n")

except FileNotFoundError as e:
    print(f"Error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Error occurred: {e}")
    sys.exit(1)
