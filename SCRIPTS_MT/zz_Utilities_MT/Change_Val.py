#!/opt/local/bin/python
######################################################################################
# This script replaces given value with another in byte or float32 file.
# Original file is saved as file_{FindVal}_ReplacedBy_{ReplaceVal}
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: - FILETOCHECK 
#			  - value to find
#			  - value to replace
#			  - input file format (byte or float32)
#
# launch command : python thisscript.py param1 param2 param3 param4
#
# New in V 1.1:	- 
#
# CIS script utilities
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import sys

filetoprocess = sys.argv[1]
FindVal = float(sys.argv[2])  # Convert the argument to a float
ReplaceVal = float(sys.argv[3])  # Convert the argument to a float
INPUTformat = sys.argv[4]

if len(sys.argv) != 5:
    print("Bad nr of arguments. Provide file where to replace values, val to find, val to replace, and file format (float32 or byte)")
    sys.exit(1)

if INPUTformat not in ('float32', 'byte'):
    print("Invalid file format. Please specify 'float32' or 'byte'.")
    sys.exit(1)

try:
    A = np.fromfile(filetoprocess, dtype=np.float32 if INPUTformat == 'float32' else np.byte)
    # Make a copy of the original data
    B = A.copy()

    # Find the indices where the FindVal appears in the array
    mask = A == FindVal

    # Replace the values at those indices with ReplaceVal
    A[mask] = ReplaceVal

    # Write the modified array back to the binary file
    A.tofile(filetoprocess)

    print(f"Replacement successful. {FindVal} was replaced with {ReplaceVal} in the file '{filetoprocess}'.")
    A.tofile(f"{filetoprocess}_{FindVal}_ReplacedBy_{ReplaceVal}")
    B.tofile(f"{filetoprocess}")  
      
except FileNotFoundError:
    print(f"Error: The file '{filetoprocess}' was not found.")
    sys.exit(1)
except Exception as e:
    print(f"Error occurred: {e}")
    sys.exit(1)



