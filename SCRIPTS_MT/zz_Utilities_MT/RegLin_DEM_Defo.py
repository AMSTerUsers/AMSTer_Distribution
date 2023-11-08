#!/opt/local/bin/python
######################################################################################
# This script computes the lineear regression between DEM and deformation and 
# save plot in current directory. DEM and DEFO must be of the same size.  
#
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: DEM DEFO 
# launch command : python thisscript.py param1 param2 
#
# V 1.0 (2022)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2022 - could make better with more functions... when time.
######################################################################################

import numpy as np
from matplotlib import pyplot as plt

import sys
from numpy import *

#import files
dem = sys.argv[1]
defo = sys.argv[2]

# Import Files and make arrays
A = np.fromfile("%s" % (dem),dtype=float32)
B = np.fromfile("%s" % (defo),dtype=float32)

x = np.array(A[~np.isnan(A)&~np.isnan(B)]) 			#faster than  np.asarray ?
y = np.array(B[~np.isnan(B)&~np.isnan(A)]*1000)		# transform defo in mm

# compute r2
correl_matrix = np.corrcoef(x, y)
corrxy = correl_matrix[0,1]
rsquared = corrxy**2

# search of ^y = kx + d
k, d = np.polyfit(x, y, 1)	# 1 stands for the 
y_pred = k*x + d

# plot
plt.plot(x, y, '.', linestyle="None")
plt.plot(x, y_pred)
plt.plot(x, y_pred)
plt.title(f'slope = {round (k,5)}mm/m, intercept = {round (d,3)}, r2 = {round (rsquared,5)}')

plt.xlabel('dem [m]')
plt.ylabel('defo [mm]')

plt.savefig('_dem_defo.png')

#plt.show()


