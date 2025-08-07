#!/opt/local/bin/python
######################################################################################
# This script swaps 0 and 1 in a mask file (in bytes).
# It renames the outputfile with an extra string _Swap01.
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: - input file (in bytes)
#
# launch command : python thisscript.py param1 
#
# New in Distro V 1.0 20241128:	- setup
# New in Distro V 1.1 20241223:	- remove backslash in printf to avoid error message
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import numpy as np
import sys
import os

if len(sys.argv) != 2:
    print("Usage: python script.py input_file")
    sys.exit(1)

input_file = sys.argv[1]

# Add the trailing string to the base name
output_file = f"{input_file}_Swap01"

try:
    # Load the mask image file as a NumPy array (assumes float32 input)
    data = np.fromfile(input_file, dtype=np.uint8)

    # Create a new array for the output
    output_data = np.zeros_like(data, dtype=np.uint8)

    # Flips 0 <-> 1
    output_data = data ^ 1  

    # Save the modified data to the output file
    output_data.tofile(output_file)

    print(f"Swap 0 and 1 completed. Modified file saved as '{output_file}'.")


except FileNotFoundError as e:
    print(f"Error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Error occurred: {e}")
    sys.exit(1)
