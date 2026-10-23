#!/opt/local/amster_python_env/bin/python
# The script aims at multiplying a float file by -1
#
# Parameters:	- file to multiply 
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#

# New in Distro V 1.0  20260312: - set up 
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
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