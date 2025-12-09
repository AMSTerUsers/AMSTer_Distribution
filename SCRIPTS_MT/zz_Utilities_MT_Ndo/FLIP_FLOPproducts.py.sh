#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script flip & flop the binary image file 
#
# Parameters: FILETOFLIP NLINES
# launch command : python thisscript.py param1 param2
#
# Dependencies:	- python3.10 and modules below (see import)
#
# New in Distro V 1.1:	- Updated and adapted to python3
# New in Distro V 1.2:  - add argument check (NdO Jul 8 2022)
# New in Distro V 1.3:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import sys
from numpy import *

filetoprocess = sys.argv[1]
numberoflines = sys.argv[2]

#Check nr of arguments  
if len(sys.argv) != 3:
	print("Bad nr of arguments. Provide file (float32) to FlipFlop and the NrOfLines")


print ("")
print ("File to reverse: %s" % (filetoprocess))
print ("Number of lines: %s" % (numberoflines))
print ("")

A = np.fromfile("%s" % (filetoprocess),dtype=float32)
B = np.split(A, int(numberoflines))
C = np.flipud(B)
D = np.fliplr(C)
D.tofile("%s"".rev" % (filetoprocess))
