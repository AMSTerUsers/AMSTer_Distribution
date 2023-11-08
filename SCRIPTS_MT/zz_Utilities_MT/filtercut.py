#!/opt/local/bin/python3
######################################################################################
# This script read an unwrapped phase and apply cutting filter
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
#################################

import sys
import numpy as np
import os
import math

#interfile = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/res_unwr.tmp'
#numcol = 600
#numlin = 400
#n_it = 1 
#cutini = 12.5 
#coefreq = 0.9

interfile = sys.argv[1]
numcol = sys.argv[2]
numlin = sys.argv[3]
n_it = sys.argv[4]
cutini = sys.argv[5]
coefreq = sys.argv[6]
	
numcol = int(numcol)
numlin = int(numlin)
n_it = int(n_it)	
cutini = float(cutini)
coefreq = float(coefreq)

t1=np.linspace(1,numcol,numcol)
t2=np.linspace(1,numlin,numlin)
T1,T2=np.meshgrid(t1,t2,indexing='xy')

cut=cutini*n_it**coefreq
print(cut)
P=2/(1+np.exp(((T1/cut)**2+(T2/cut)**2))**2)
P[int(numlin/2):numlin,:]=np.flipud(P[0:int(numlin/2),:])
P[:,int(numcol/2):numcol]=np.fliplr(P[:,0:int(numcol/2)])


interfunwr = np.fromfile(interfile,dtype='float32')
unwr = np.reshape(interfunwr,(numlin,numcol),order='C')

fftunwr = np.fft.fft2(unwr)
fftunwrflt = fftunwr*P
unwr_flt = np.fft.ifft2(fftunwrflt)
unwr_flt = unwr_flt.real
unwr_flt = unwr_flt.astype('float32')

rewr = unwr_flt % (2*math.pi)
unwr_flt = np.reshape((unwr_flt),(numlin*numcol))

dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/unwrfilt.tmp'), 'wb')
unwr_flt.tofile(output_file)
output_file.close()

rewr = unwr_flt % (2*math.pi)

output_file = open("%s%s" % (dir_path,'/rewrfilt.tmp'), 'wb')
rewr.tofile(output_file)
output_file.close()

