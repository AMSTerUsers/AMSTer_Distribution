#!/opt/local/bin/python
######################################################################################
# This script flip the binary images files for being in the GIS geometry logic 
#
# Parameters: -	FILETOFLOP 
#			  - NLINES
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 1.1:	- print syntax ok for python 3  (NdO March 30, 2021)
# New in Distro V 1.2:  - add argument check (NdO Jul 8 2022)
# New in Distro V 1.3:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# launch command : python thisscript.py param1 param2
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
######################################################################################

import numpy as np
import sys
from numpy import *

filetoprocess = sys.argv[1]
numberoflines = sys.argv[2]

#Check nr of arguments   - watch out, it takes the script name as an argument 
if len(sys.argv) != 3:
	print("Bad nr of arguments. Provide file (float32) to Flip and the NrOfLines")


#print ""
#print "File to reverse: %s" % (filetoprocess)
#print "Number of lines: %s" % (numberoflines)
#print ""

print("")
print ("File to reverse: %s" % (filetoprocess))
print ("Number of lines: %s" % (numberoflines))
print("")

A = np.fromfile("%s" % (filetoprocess),dtype=float32)
B = np.split(A, int(numberoflines))
C = np.flipud(B)
C.tofile("%s"".flip" % (filetoprocess))
