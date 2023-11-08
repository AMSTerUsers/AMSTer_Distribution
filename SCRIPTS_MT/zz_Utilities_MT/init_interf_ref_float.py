#!/opt/local/bin/python
######################################################################################
# This script converts interf in float into an input file in floats
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# Delphine Smittarello, (c)2016
######################################################################################
import sys
import os
import numpy as np
import math

#interfile = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/interf_WN.tmp.CropLastCol.CropLastLine'
#numcol =  600
#numlin =  400

interfile = sys.argv[1]
numcol =  sys.argv[2]
numlin =  sys.argv[3]

numcol = int(numcol)
numlin = int(numlin)
print(interfile, numcol, numlin) 
interf = np.fromfile("%s" % (interfile),dtype='float32')

interf = -1*interf 
interf_reshape = np.reshape(interf,(numlin,numcol), order='C')
interf_reshape = np.flipud(interf_reshape+ math.pi)
phi = (interf_reshape)

phi_int = np.reshape(phi,(numlin*numcol))
phi_int = phi_int.astype('float32')
dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/interf0_float.tmp'), 'wb')
phi_int.tofile(output_file)
output_file.close()
