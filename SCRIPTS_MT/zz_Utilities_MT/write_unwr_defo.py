#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script write unwrapped phases and deformation maps
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in V1.1 :	- add line or col of zero's instead of NaN to get file of even size
# New in Distro V 2.0 20250813:	- launched from python3 venv
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
#################################


import sys
import numpy as np
import os
import math

#interfile = '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/RECUNWR_F2B/addinterf.tmp'
#hwlen = 0.0277
#numcol = 600
#numlin = 400
#addcolnan = 1
#addlinnan = 1

interfile = sys.argv[1]
hwlen = sys.argv[2]
numcol = sys.argv[3]
numlin = sys.argv[4]
addcolnan = sys.argv[5]
addlinnan = sys.argv[6]


hwlen = float(hwlen)
numcol = int(numcol)
numlin = int(numlin)
addcolnan = int(addcolnan)
addlinnan = int(addlinnan)
interf = np.fromfile("%s" % (interfile),dtype='float32')
interf = np.reshape(interf,(numlin,numcol),order='C')
interf = np.flipud(interf)

if (addcolnan==1):
	colnan = np.zeros((numlin,1))
	#colnan[:] = np.nan
	interf=np.concatenate((interf,colnan),axis=1)
	numcol = numcol + 1

if (addlinnan==1):
	linnan = np.zeros((1,numcol))
	#linnan[:] = np.nan
	interf=np.concatenate((interf,linnan),axis=0)
	numlin = numlin + 1


unwr = -interf
unwr = unwr.astype('float32')
dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/interf_deroule_final.r4'), 'wb')
unwr.tofile(output_file)
output_file.close()

defo = interf*hwlen/(2*math.pi)
defo = defo.astype('float32')
dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/defomap.r4'), 'wb')
defo.tofile(output_file)
output_file.close()
