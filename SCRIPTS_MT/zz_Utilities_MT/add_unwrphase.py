#!/opt/local/bin/python3
######################################################################################
# This script add two unwrapped phases
#
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
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
