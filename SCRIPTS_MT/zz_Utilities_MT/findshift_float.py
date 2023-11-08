#!/opt/local/bin/python
######################################################################################
# This script read an interferogram and an unwrapped phase, rewrap the unwr and 
#   find the optimal shift between both wrapped phases
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
#################################
#python3 findshift_float.py '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/residualInterferogram.VV-VV.20210519_20210531_Bp-4.85m_BT12days' '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/unwrfilt.tmp' 6356 5876

import sys
import math
import matplotlib
import numpy as np
import os
import matplotlib.pyplot as plt

#interfile_ref = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/interf_ref_float.tmp'
#interfile_cum = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/interfcum.tmp'
#numcol = 600
#numlin = 400

interfile_ref = sys.argv[1]
interfile_cum = sys.argv[2]
numcol = sys.argv[3]
numlin = sys.argv[4]


numcol = int(numcol)
numlin = int(numlin)

interfcum = np.fromfile("%s" % (interfile_cum),dtype='float32')
interf_ref = np.fromfile("%s" % (interfile_ref),dtype='float32')
interf_ref_reshape = np.reshape(interf_ref,(numlin,numcol), order='C')
interf_ref_reshape = np.flipud(interf_ref_reshape)
interf_ref_reshape = -1*interf_ref_reshape+math.pi
interfcum_rshp = np.reshape(interfcum,(numlin,numcol))

interfrewrp = interfcum_rshp % (math.pi*2)


ref = np.reshape(interf_ref_reshape,(numlin*numcol),order='F')
rewrp = np.reshape(interfrewrp,(numlin*numcol),order='F')

zref = np.exp(ref*1j)
zrewrp = np.exp(rewrp*1j)
zdiff = zrewrp*np.conj(zref)

angzdiff = np.angle(zdiff) % (math.pi*2)

num_bins = np.linspace(0,math.pi*2,255)

n, bins, patches = plt.hist(angzdiff, num_bins)
#n = np.flipud(n)         
n2 = np.concatenate((n[205:255] , n , n[0:50]))    
#sliding average
taille = 11
matfilt=np.ones((taille))
convn2_one3 = (np.convolve(n2, matfilt,mode='same'))/taille

k = np.where(convn2_one3 == np.amax(convn2_one3))
y = np.linspace(0,354,355)

shift = y[k]-48
print("Shift is: %s" % shift)
if (shift.shape[0]>1):
	if(shift[0]<0):
		shift=shift[1]
	else:
		shift=shift[0]

shift = 2*math.pi*shift/256
print("Shift is: %s" % shift)

interfshift = interfcum_rshp-shift
interfshift = interfshift.astype('float32')

dir_path = os.path.dirname(os.path.realpath(interfile_cum))
output_file2 = open("%s%s" % (dir_path,'/interfshifted.tmp'), 'wb')
interfshift.tofile(output_file2)
output_file2.close()


