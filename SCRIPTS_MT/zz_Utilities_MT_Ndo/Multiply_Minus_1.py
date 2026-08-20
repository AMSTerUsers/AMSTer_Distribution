#!/opt/local/amster_python_env/bin/python
# The script aims at multiplying a float file by -1
#
# Parameters:	- file to multiply 

# New in Distro V 1.0  20260312: - set up 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import sys
import numpy as np

if len(sys.argv) != 3:
    print("Usage: python Multiply_Minus_1.py <input_file> <output_file>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

# adjust dtype if needed
data = np.fromfile(input_file, dtype=np.float32)

data = -data

data.tofile(output_file)