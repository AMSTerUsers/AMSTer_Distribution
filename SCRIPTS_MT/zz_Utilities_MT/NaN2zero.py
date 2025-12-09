#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script replaces NaN with 0 in byte or float32 file (format set in second param) 
# in order to be used e.g. for sbas.
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: - FILETOCHECK 
#			  - input file format (byte or float32)
#
# launch command : python thisscript.py param1 param2
#
# New in V 1.1:	- compatible python 3 
# New in V 1.2:	- put the input format as variable
# New in V 2.0: - Faster, more robust and take input format as second param(NdO July 8, 2021)
# New in V 2.1:  - add argument check (NdO Jul 8 2022)
# New in V 2.2:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.0 20250813:	- launched from python3 venv
# New in Distro V 4.1 20250911:	- fix issue with format 
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import sys
import os

# Check number of arguments
if len(sys.argv) != 3:
    print("Bad number of arguments. Provide file where to replace NaNs by zeros and its format (float32 or byte)")
    sys.exit(1)

filetoprocess = sys.argv[1]
INPUTformat = sys.argv[2]

# Map format to numpy dtype
if INPUTformat.lower() == "float32":
    dtype = np.float32
elif INPUTformat.lower() == "byte":
    dtype = np.uint8
else:
    raise ValueError("INPUTformat must be 'float32' or 'byte'")

# Read the file
A = np.fromfile(filetoprocess, dtype=dtype)

# Replace NaNs with 0 only if float32
if dtype == np.float32:
    A[np.isnan(A)] = 0

# Save output
outfile = f"{filetoprocess}zero"
A.tofile(outfile)

print(f"Processed file saved as {outfile}")

# import numpy as np
# import sys
# from numpy import *
# 
# filetoprocess = sys.argv[1]
# INPUTformat = sys.argv[2]
# #destinationIfWrong = sys.argv[2]
# 
# #Check nr of arguments  
# if len(sys.argv) != 3:
# 	print("Bad nr of arguments. Provide file where to replace NaNs by zeros and its format (float32 or byte)")
# 
# #INPUTformat=float32
# #INPUTformat=byte
# 
# if INPUTformat.lower() == "float32":
#     dtype = np.float32
# elif INPUTformat.lower() == "byte":
#     dtype = np.uint8
# else:
#     raise ValueError("INPUTformat must be 'float32' or 'byte'")
# 
# #A = np.fromfile("%s" % (filetoprocess),dtype=float32)			# e.g defo maps
# #A = np.fromfile("%s" % (filetoprocess),dtype=byte)				# e.g masks 
# A = np.fromfile("%s" % (filetoprocess),dtype=dtype)
# 
# ##mask = np.isnan(A)
# ##masked_A = np.ma.masked_array(A, mask)
# #B = masked_A.filled(0)
# #np.save("%s" % (filetoprocess), masked_A.filled(0))
# 
# ##masked_A.filled(0).tofile("%s%s" % (filetoprocess,"zero"))
# 
# 
# where_are_NaNs = isnan(A)
# A[where_are_NaNs] = 0
# 
# A.tofile("%s%s" % (filetoprocess,"zero"))
