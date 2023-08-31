#!/opt/local/bin/python
######################################################################################
# This script checks if file contains at least one NaN or not. 
# If not, it outputs the minimal value; if yes, it outputs nan. 
#
# Parameters: -	FILETOCHECK 
#			  - input file format (byte or float32)
#
# Dependencies:	- python3.10 and modules below (see import)
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 1.1:	- Comaptible with python 3 (NdO March 30, 2021)
# New in Distro V 1.2:	- hard code input format (byte or float32)
# New in Distro V 2.0: 	- Faster, more robust and take input format as second param(NdO July 8, 2021)
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

filetoprocess = sys.argv[1]
INPUTformat = sys.argv[2]

#Check nr of arguments  
if len(sys.argv) != 2:
	print("Bad nr of arguments. Provide file to search for some possible NaN(s) and input file fromat (byte or float32")


#INPUTformat=float32			# Keep this as default because used by build_header_msbas_criteria.sh
#INPUTformat=byte

A = np.fromfile("%s" % (filetoprocess),dtype=INPUTformat)
##MinA = nanmin(A)
#MaxA = nanmax(A)
##print ("%s" % (MinA))

if(np.isnan(A).any()):
    print("nan")
else:
    MinA = min(A)
    print ("%s" % (MinA))
