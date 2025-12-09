#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script add two unwrapped phases
#
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# Delphine Smittarello, (c)2016
#################################

import sys
import numpy as np
import os

#interfile1 = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/resid_float.tmp' 
#interfile2 = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/interfcum.tmp'


interfile1 = sys.argv[1]
interfile2 = sys.argv[2]
#numcol = sys.argv[3]
#numlin = sys.argv[4]

#numcol = int(numcol)
#numlin = int(numlin)

interf1 = np.fromfile("%s" % (interfile1),dtype='float32')
interf2 = np.fromfile("%s" % (interfile2),dtype='float32')

addpha = interf1+interf2 
addpha = addpha.astype('float32')

dir_path = os.path.dirname(os.path.realpath(interfile1))
output_file = open("%s%s" % (dir_path,'/addinterf.tmp'), 'wb')
addpha.tofile(output_file)
output_file.close()
