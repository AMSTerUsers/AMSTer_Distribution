#!/opt/local/bin/python
######################################################################################
# This script computes the mean and median of all coh images in dir. 
#
# Parameters: - coh threshold
#
# Dependencies : - python3 and modules below (see import)
#
# Note: opencv4 can be imported as cv2 
#
# launch command : python thisscript.py param1 param2 
#
# Check carefully that numpy and OpenCV are installed and that the path to python is correct in line 1 of the script 
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 2.0:	- Count itself the number of *deg files in dir 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import scipy.ndimage
import matplotlib.pyplot as plt
import glob
import os
import fnmatch

import sys
#import scipy
import cv2 #as cv
from numpy import *
# #from scipy.signal import medfilt2d
from matplotlib import pyplot as plt

# To avoid anoying warnings...
import warnings
warnings.filterwarnings("ignore")

#nroffiles = sys.argv[1]
cohthreshold = sys.argv[1]

nroffiles = len(fnmatch.filter(os.listdir('.'), '*deg'))
print('Nr of coherence files *deg in dir:', nroffiles)

filenames = sorted(glob.glob('*deg'))

X = [np.fromfile("%s" % (filenames[i]),dtype=float32)  for i in range(int(nroffiles)) ]
Y = np.vstack((x.ravel() for x in X))
Z1 = np.median(Y,axis = 0)
Z2 = np.mean(Y,axis = 0)
Z2 = np.float32(Z2)


# Check min max if NaN
#print "Median min is %s" % (nanmin(Z1))
#print "Median max is %s" % (nanmax(Z1))
#print "Mean min is %s" % (nanmin(Z2))
#print "Mean max is %s" % (nanmax(Z2))

# threshold
ret,Z3 = cv2.threshold(Z2,float(cohthreshold),1,cv2.THRESH_BINARY)

Z3 = np.int8(Z3)

Z1.tofile("coherence.median" )
Z2.tofile("coherence.mean" )
Z3.tofile("coherence_above_%s.mean" % float(cohthreshold))

print("Mean, Median and coherence above threshold written in current dir")