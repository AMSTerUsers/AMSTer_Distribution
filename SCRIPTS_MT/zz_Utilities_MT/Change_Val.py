#!/opt/local/amster_python_env/bin/python
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
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20214418:	- change byte type 0->255 instead of signed byte -128->127
# New in Distro V 3.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


import numpy as np
import sys

filetoprocess = sys.argv[1]
FindVal = float(sys.argv[2])  # Convert the argument to a float
#ReplaceVal = float(sys.argv[3])  # Convert the argument to a float
ReplaceVal = int(sys.argv[3])  # Convert the argument to a int
INPUTformat = sys.argv[4]

if len(sys.argv) != 5:
    print("Bad nr of arguments. Provide file where to replace values, val to find, val to replace, and file format (float32 or byte)")
    sys.exit(1)

if INPUTformat not in ('float32', 'byte'):
    print("Invalid file format. Please specify 'float32' or 'byte'.")
    sys.exit(1)


try:
	#A = np.fromfile(filetoprocess, dtype=np.float32 if INPUTformat == 'float32' else np.byte) # np.byte corresponds to a signed 8-bit integer in NumPy, meaning values range from -128 to 127, not 0–255. If your file uses unsigned bytes (0–255), the dtype should be np.uint8.
    A = np.fromfile(filetoprocess, dtype=np.float32 if INPUTformat == 'float32' else np.uint8)

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



