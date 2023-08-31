#!/opt/local/bin/python
######################################################################################
# This scripts output the minimum value of a file ignoring NaN. 
# If it the file contains ONLY NaN, it outputs nan. 
#
# Parameters: -	FILETOCHECK 
#			  - input file format (byte or float32)
#
# Dependencies:	- python3.10 and modules below (see import)
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 1.1:	- Comaptible with python 3 (NdO March 30, 2021)
# New in Distro V 1.2:	- hard code input format (byte or float32)
# New in Distro V 2.0: 	- Faster and more robust (NdO July 8, 2021)
# New in Distro V 2.1:  - add argument check (NdO Jul 8 2022)
#
# launch command : python thisscript.py param1 param2
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import sys
from numpy import *

# To avoid anoying warnings...
import warnings
warnings.filterwarnings("ignore")

filetoprocess = sys.argv[1]
INPUTformat = sys.argv[2]

#Check nr of arguments  
if len(sys.argv) != 2:
	print("Bad nr of arguments. Provide file test if full of NaN and input file fromat (byte or float32")



#INPUTformat=float32			# Keep this as default because used by build_header_msbas.sh
#INPUTformat=byte

A = np.fromfile("%s" % (filetoprocess),dtype=INPUTformat)
##MinA = nanmin(A)
#MaxA = nanmax(A)
##print ("%s" % (MinA))

# get min ignoring nan
print(np.nanmin(A))

