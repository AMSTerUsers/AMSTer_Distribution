#!/opt/local/bin/python
######################################################################################
# This script replaces 0 with NaN in byte or float32 file (format set in second param).
# BEWARE, output file is ALWAYS IN FLOAT32 to allows coding NaN
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: - FILETOCHECK 
#			  - input file format (byte or float32)
#
# launch command : python thisscript.py param1 param2
#
# New in V 1.1:	- compatible python 3 
#				- do not write file as .npy to avoid possible additional header (NdO March 30, 2021)
# New in V 1.2:	- put the input format as variable
# New in V 2.0: - Faster, more robust and take input format as second param(NdO July 8, 2021)
# New in V 2.1:  - add argument check (NdO Jul 8 2022)
# New in V 2.2:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
#
# CIS script utilities
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import sys
from numpy import *

filetoprocess = sys.argv[1]
INPUTformat = sys.argv[2]

#Check nr of arguments  
if len(sys.argv) != 3:
	print("Bad nr of arguments. Provide file where to replace zeros by NaNs and its format (float32 or byte); beware output file will always be float32")


#INPUTformat=float32
#INPUTformat=byte


#A = np.fromfile("%s" % (filetoprocess),dtype=float32)
A = np.fromfile("%s" % (filetoprocess),dtype=INPUTformat)

##A=A.astype('float')
##A[A == 0] = 5.
##A=A.astype('float')

A=A.astype('float')
A[A == 0] = np.nan
A=A.astype('float32')

#np.save("%s%s" % (filetoprocess,"NaN"), A)
A.tofile("%s%s" % (filetoprocess,"NaN"))
print("Output file is in float32")
