#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script converts interf in float into an input file in bytes 
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# Delphine Smittarello, (c)2016
######################################################################################
import sys
import os
import numpy as np
import math

interfile = sys.argv[1]
numcol =  sys.argv[2]
numlin =  sys.argv[3]

interfile = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/interf0_float.tmp'
numcol =  600
numlin =  400


numcol = int(numcol)
numlin = int(numlin)
print(interfile, numcol, numlin) 
interf = np.fromfile("%s" % (interfile),dtype='float32')

interf = -1*interf 
interf_reshape = np.reshape(interf,(numlin,numcol), order='C')
interf_reshape = np.flipud(interf_reshape+ math.pi)
phi = (interf_reshape)*255/2/math.pi
arrondi = np.vectorize(round)
phi_int = arrondi(phi)

#replace banking rounding by half to up rounding
phid = phi % 0.5
k = np.where(phid==0)
arrondiup = np.vectorize(math.ceil)
phi_int[k]=arrondiup(phi[k])


phi_int = np.reshape(phi_int,(numlin*numcol))
phi_int = phi_int.astype('B')
dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/interf0_byte.tmp'), 'wb')
phi_int.tofile(output_file)
output_file.close()
