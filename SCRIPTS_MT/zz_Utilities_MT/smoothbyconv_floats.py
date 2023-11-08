#!/opt/local/bin/python
######################################################################################
# This script smooth an interferogram (float32) using a 2-D convolution
# with a matrix ones(3x3)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
######################################################################################

import sys
import os
import numpy as np
import cmath
from scipy import signal
import math


#interfile = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/interf0_float.tmp'
#numcol =  600
#numlin =  400

interfile = sys.argv[1]
numcol =  sys.argv[2]
numlin =  sys.argv[3]

numcol = int(numcol)
numlin = int(numlin)

print(interfile, numcol, numlin) 

phi_int = np.fromfile("%s" % (interfile),dtype='float32')
pha = np.reshape(phi_int,(numlin,numcol), order='C')

amp=np.ones(pha.shape)
Z = amp*np.exp(pha*1j)
Zreel=Z.real
Zimag=Z.imag

matfilt=np.ones((3,3))

Zreelsmooth = signal.convolve2d(Zreel, matfilt, mode='same')
Zimagsmooth = signal.convolve2d(Zimag, matfilt, mode='same')
phaseangle = np.vectorize(math.atan2)
phasesmooth = phaseangle(Zimagsmooth, Zreelsmooth)
phasesmooth = (phasesmooth+2*math.pi) % (2*math.pi)
pha_comp=np.exp(phasesmooth*1j)

Re=pha_comp.real
Im=pha_comp.imag
Cp = np.zeros((numlin,numcol*2))
for k in range(numcol):
	Cp[:,2*k]=Re[:,k]
	Cp[:,2*k+1]=Im[:,k]
	

phasesmoothlist=np.reshape(Cp,numlin*numcol*2, order='C')
phasesmoothlist=phasesmoothlist.astype('float32')

dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/phasmooth.float'), 'wb')
phasesmoothlist.tofile(output_file)
output_file.close()



