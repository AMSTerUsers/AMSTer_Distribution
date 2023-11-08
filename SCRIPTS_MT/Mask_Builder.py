#!/opt/local/bin/python
#
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series

# -*-coding:Latin-1 -*
#import struct
import sys
import os
import numpy as np
import fnmatch

#Check argument number 

if len(sys.argv) != 3:
	print("Issue occured when Running python script... bad argument number")
	

#Variable definition for the treatment of Coherence files

input = sys.argv[1]
print(input)
print('above the image file for deformation')
output = sys.argv[2]
print(output)

B1 = np.fromfile(input, dtype='float32')   #Read files as an array of float
B2 = (B1/B1)*0.9;
B3 = np.nan_to_num(B2)
x=np.amax(B3)			#Test valeur max dans fichier binaire
print ("------------")
print(x)

print('ending division coherence...')
dest = open(output, "wb")	# Open a binary writable file
dest.write(B3)    #Write in this file the array
dest.close()




