#!/opt/local/bin/python
######################################################################################
# This script filters an image using a square windows (size must be odd, e.g. 5 is ok). 
#
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: FILETOFILTER NRLINES NRCOLS FILTERSIZE
# launch command : python thisscript.py param1 param2 param3
#
# New in Distro V 1.1:  - add argument check (NdO Jul 8 2022)
# New in Distro V 1.2:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
#
# CIS script utilities
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import sys
#import scipy
import cv2
from numpy import *
#from scipy.signal import medfilt2d
from matplotlib import pyplot as plt

filetoprocess = sys.argv[1]
numberoflines = sys.argv[2]
numberofcols = sys.argv[3]
filtersize = sys.argv[4]

#Check nr of arguments  
if len(sys.argv) != 5:
	print("Bad nr of arguments. Provide file (float32) to filter, NrOfLines, NrOfColumns and FilterWindowSize (must be odd)")

A = np.fromfile("%s" % (filetoprocess),dtype=float32)
#B = np.split(A, int(numberoflines))
B = np.array(A)
shape = (int(numberoflines), int(numberofcols))
C=(B.reshape(shape))
#C = scipy.signal.medfilt2d(B, kernel_size=filtersize)
D = cv2.medianBlur(C, int(filtersize))


D.tofile("%s"".filt" % (filetoprocess))
#C.tofile("%s"".filt""%s" % (filetoprocess,filtersize))
