#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script computes the mean of all ampl images in dir. 
#
# Parameters: - none
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
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20241010:	- Corrected Y list to use a list instead of a generator
# New in Distro V 4.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
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

nroffiles = len(fnmatch.filter(os.listdir('.'), '*deg'))
print('Nr of amplitude files *deg in dir:', nroffiles)

filenames = sorted(glob.glob('*deg'))

X = [np.fromfile("%s" % (filenames[i]),dtype=float32)  for i in range(int(nroffiles)) ]
#Y = np.vstack((x.ravel() for x in X))
Y = np.vstack([x.ravel() for x in X])  # Corrected to use a list instead of a generator

Z2 = np.mean(Y,axis = 0)

Z2.tofile("ampli.mean" )

print("Mean amplitude written in current dir")