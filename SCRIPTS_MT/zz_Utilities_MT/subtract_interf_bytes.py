#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script read two wrapped interferograms and substract 2 to 1
#
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
#################################

import sys
import numpy as np
import math
import os

#interfile1 = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/interf0_byte.tmp'
#interfile2 = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/rewrfilt.tmp'

interfile1 = sys.argv[1]
interfile2 = sys.argv[2]

interfwrp1 = np.fromfile("%s" % (interfile1),dtype='uint8')
interfwrp2 = np.fromfile("%s" % (interfile2),dtype='float32')

phi = interfwrp1*math.pi*2/256
psi = interfwrp2

res_interf = np.angle(np.exp((phi-psi)*1j))
ang_resid_float = res_interf.astype('float32')
dir_path = os.path.dirname(os.path.realpath(interfile1))
output_file = open("%s%s" % (dir_path,'/resid_float.tmp'), 'wb')
ang_resid_float.tofile(output_file)
output_file.close()

res_interf = (res_interf+math.pi)*256/(math.pi*2)
resid = res_interf % 256

arrondi = np.vectorize(round)
resid = arrondi(resid)
k=np.where(resid == 256)
resid[k]=255
print(resid.min())
print(resid.max())
resid = resid.astype('B')
dir_path = os.path.dirname(os.path.realpath(interfile1))
output_file = open("%s%s" % (dir_path,'/subtractinterf.tmp'), 'wb')
resid.tofile(output_file)
output_file.close()


