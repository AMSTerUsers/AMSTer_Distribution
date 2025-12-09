#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script crop the last line from a binary matrix (in bytes)
#
# Parameters: -	FILETOCROP 
#			  - NLINES
#			  - NCOLUMNS
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# New in Distro V 1.0:	- based on FLOPproducts.py.sh
# New in Distro V 1.1:  - add argument check (NdO Jul 8 2022)
# New in Distro V 1.2:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.0 20250813:	- launched from python3 venv
#
#
# launch command : python thisscript.py param1 param2
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2016-18
######################################################################################

import numpy as np
import sys
from numpy import *

filetoprocess = sys.argv[1]
numberoflines = sys.argv[2]
numberofcols = sys.argv[3]

#Check nr of arguments  
if len(sys.argv) != 4:
	print("Bad nr of arguments. Provide file (in float) to Crop for last line, NrOfLines and NrOfColumns")


print("")
print ("File to crop: %s" % (filetoprocess))
print ("Number of lines: %s" % (numberoflines))
print("")

#tests
#arr = np.array([1, 2, 3, 4, 5, 6, 7,8,9,10,11,12])

A = np.fromfile("%s" % (filetoprocess),dtype='float32')
print ("A shape: %s" % A.shape)

B = np.reshape(A, (int(numberoflines), int(numberofcols)))
#tests
#arrB=np.reshape(arr, (4, 3))

print ("B shape lines: %s" % B.shape[0])
print ("B shape col: %s" % B.shape[1])

C = np.delete(B, -1, axis=0)	# remove last line
#C = np.delete(B, -1, axis=1)	# remove last col

#tests
#arrC = np.delete(arrB, -1, axis=0) # remove last line 
print ("C shape lines : %s" % C.shape[0] )
print ("C shape col : %s" % C.shape[1] )

#tests
#print (arrB)
#print (arrC)


C.tofile("%s"".CropLastLine" % (filetoprocess))
