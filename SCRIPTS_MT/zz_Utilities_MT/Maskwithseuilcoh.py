#!/opt/local/bin/python
######################################################################################
# This script read an interferogram and a coherence file to create a mask and replace 
# interf values by white noise where coh < COHMUWPTHRESH
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
#################################

import sys
import math
import numpy as np
import os

#interfile = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR/crop_interf.r4'
#numcol = 600 
#numlin = 400 
#cohfile = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/crop_coh.r4'
#COHMUWPTHRESH =  0.0627

interfile = sys.argv[1]
numcol = sys.argv[2]
numlin = sys.argv[3]
cohfile = sys.argv[4]
COHMUWPTHRESH =  sys.argv[5]

numcol = int(numcol)
numlin = int(numlin)
COHMUWPTHRESH = float(COHMUWPTHRESH)

interf = np.fromfile("%s" % (interfile),dtype='float32')
coh = np.fromfile("%s" % (cohfile),dtype='float32')

interf = np.reshape(interf,(numlin,numcol))
coh = np.reshape(coh,(numlin,numcol))
interf = np.flipud(interf)
coh = np.flipud(coh)
 
randvalues = np.random.uniform(low=-math.pi, high=math.pi,size=interf.shape)
mask = np.ones(interf.shape)

k = np.where(coh <= COHMUWPTHRESH)
mask[k] = 0
mask = mask.astype('float32')
interf[k]=randvalues[k]

interf = np.reshape(np.flipud(interf),(numlin*numcol))
mask = np.reshape(np.flipud(mask),(numlin*numcol))

dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/interf_WN.tmp'), 'wb')
interf.tofile(output_file)
output_file.close()

output_file2 = open("%s%s" % (dir_path,'/mask.tmp'), 'wb')
mask.tofile(output_file2)
output_file2.close()


