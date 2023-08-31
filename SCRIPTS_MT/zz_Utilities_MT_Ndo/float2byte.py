#!/opt/local/bin/python
######################################################################################
# This script convert floats to byte (image can be read with cpxfiddle as -f c1)
#
# Parameters: - name of images to convert
#
# Dependencies : - python3.10 and modules below (see import) 
#
#
# New in Distro V 2.0:	- exporting without the array size as a header (i.e. not as .npy) 
# New in Distro V 2.1:	- ok with python3 
# New in Distro V 2.2:  - add argument check (NdO Jul 8 2022)
# New in Distro V 2.3:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import sys
from numpy import *
import os

flfile = sys.argv[1]

#Check nr of arguments  
if len(sys.argv) != 2:
	print("Bad nr of arguments. Provide float32 file to convert in bytes")


i = np.fromfile("%s" % (flfile),dtype='float32')
#i = i.astype(np.integer) 							# Causes an warning in python3 though seems OK but changed below for security
i = i.astype(np.int32) 
i=i.astype('B')
#np.save("%s%s" % (flfile,"byte"), i)

# without header 
output_file = open("%s%s" % (flfile,"Byte"), 'wb')
i.tofile(output_file)
output_file.close()
