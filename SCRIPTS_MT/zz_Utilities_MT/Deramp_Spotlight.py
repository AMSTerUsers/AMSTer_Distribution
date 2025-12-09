#!/opt/local/amster_python_env/bin/python
################################################################################
# This script aims at deramping Spotlight interferograms (e.g. from ALOS2) in radar 
# geometry. It assess it by estimating the number or fringes on a given crop. 
# Fringe counting is performed based on FFT: 
# 	It stacks the FFT or each line (and/or columns) in image and search for the 
# 	position of the maxiumum (i.e. the nr of fringes). To assess the decimal part of fringe, 
# 	it removes recursively one pixel in the profiles until the position of the maximum 
# 	decrease by 1 (i.e. one fringe less), which occurs when one jumps at half fringe. 
# Then it interpolates that number of fringes to the whole image.  
#
# The sign of fringes is measured by comparing the phase value at 1/10th of a fringe on
# both sides of the maximums in the profile. If left side is smaller than right side, 
# (that is the phase looks like ...|\|\|\...) it means that phases are negative. If larger,     
# (that is the phase looks like .../|/|/|...) it means that phases are positive.
# 
# Parameters are:
#       - path to interferogram to deramp
#		- nr of lines and columns of the image
#       - First Y pixel for crop where to measure the fringes 
#		- Last Y pixel for crop where to measure the fringes
#		- First X pixel for crop where to measure the fringes
#		- Last X pixel for crop where to measure the fringes
#
# Dependencies:	- python3 
#   			- numpy
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
#################################

import sys
import numpy as np
import numpy.matlib
import os
import matplotlib.pyplot as plt


# LOAD INPUT
interfile = sys.argv[1]
#interfile = '/home/delphine/Documents/Unwr_INTERFERO_JLF/DetrendALOS/data/residualInterferogram.HH-HH.f.20200214_20201009_Bp-203.m_BT238days
numcol = sys.argv[2]
numlin = sys.argv[3]
numcol = int(numcol)
numlin = int(numlin)

firstY = sys.argv[4]
lastY = sys.argv[5]
firstX = sys.argv[6]
lastX = sys.argv[7]
firstY = int(firstY)
lastY = int(lastY)
firstX = int(firstX)
lastX = int(lastX)

interf = np.fromfile("%s" % (interfile),dtype='float32')
interfrshp = np.reshape(interf, (numlin, numcol))


# CROP 
# firstY=1100
# lastY=4400
# firstX=4500
# lastX=6300
numXcrop=lastX-firstX
numYcrop=lastY-firstY
print("Crop size:",numYcrop,"Lines and ",numXcrop,"Columns")
interfcrop=interfrshp[firstY:lastY,firstX:lastX]

# initialisation fringes count
stackX=0
stackY=0
for k in range(numYcrop):
	inputline=interfcrop[k,:]
	stackX=stackX+abs(np.fft.fft(inputline))
maxvalX=np.max(stackX[0:int(numYcrop/2)])
numFringecropX = np.argmax(stackX[0:int(numYcrop/2)])

for k in range(numXcrop):
	inputcol=interfcrop[:,k]
	stackY=stackY+abs(np.fft.fft(inputcol))
maxvalY=np.max(stackY[0:int(numXcrop/2)])
numFringecropY = np.argmax(stackY[0:int(numXcrop/2)])

print("init Fringe X:",numFringecropX,"; init Fringe Y:",numFringecropY)


# Precise fringe count on cropX
l=0
testNumFringeX=numFringecropX
if numFringecropX > 0:
	while testNumFringeX+1 > numFringecropX:
		l=l+1
		stackX=0
		for k in range(numYcrop):
			inputline=interfcrop[k,:-l]
			stackX=stackX+abs(np.fft.fft(inputline))
		maxvalX=np.max(stackX[0:int(numYcrop/2)])
		testNumFringeX = np.argmax(stackX[0:int(numYcrop/2)])
		print("number of cols removed :",l,"; number of fringes:",testNumFringeX)
	# Fringe count on full image

	pixPerFringeX = 2*(numXcrop+1-(l))/(2*(testNumFringeX)+1)		
	numFringeX = numcol / pixPerFringeX
#	print(numXcrop,testNumFringeX,pixPerFringeX,numFringeX,numcol)		
else : 
	numFringeX=0
	
	

# Precise fringe count on cropY	
l=0
testNumFringeY=numFringecropY
if numFringecropY > 0:
	while testNumFringeY+1 > numFringecropY:
		l=l+1
		stackY=0
		for k in range(numXcrop):
			inputcol=interfcrop[:-l,k]
			stackY=stackY+abs(np.fft.fft(inputcol))
		maxvalY=np.max(stackY[0:int(numXcrop/2)])
		testNumFringeY = np.argmax(stackY[0:int(numXcrop/2)])
		print("number of lines removed :",l,"; number of fringes:",testNumFringeY)
	
	# Fringe count on full image
	pixPerFringeY = 2*(numYcrop+1-(l))/(2*(testNumFringeY)+1)		
	numFringeY = numlin / pixPerFringeY
	print(numYcrop,l,testNumFringeY,pixPerFringeY,numFringeY,numlin)		
else : 
	numFringeY=0
	
print("Number of fringes on full image along X",numFringeX)
print("Number of fringes on full image along Y",numFringeY)

# Sign of detrend 
# search here the value of the phase in (a stack of) profile(s) along X and Y axis at
# 1/10 of a fringe on both sides of the maximum(s). Invert the sign of numFringeX or numFringeY
# if required (i.e. if left side is smaller than right side) 

# For now: hard coded:
numFringeX=-numFringeX
numFringeY=-numFringeY

# detrend
dx = 2*np.pi/numcol
dy = 2*np.pi/numlin

trendX=np.linspace(0,2*np.pi-dx,numcol)*numFringeX
trendY=np.linspace(0,2*np.pi-dy,numlin)*numFringeY

trendX_cpx=np.cos(trendX)-1j*np.sin(trendX)
trendX_cpx=np.reshape(trendX_cpx,[1,numcol])
trendX_cpx=np.matlib.repmat(trendX_cpx,numlin,1)

trendY_cpx=np.cos(trendY)-1j*np.sin(trendY)
trendY_cpx=np.reshape(trendY_cpx,[1,numlin])
trendY_cpx=np.matlib.repmat(trendY_cpx,numcol,1)

interf_cpx=np.cos(interfrshp)+1j*np.sin(interfrshp)
print(trendX_cpx.shape)
print(trendY_cpx.shape)
print(interf_cpx.shape)

t1=interf_cpx*trendX_cpx
print(t1.shape)

t2=np.transpose(t1)*trendY_cpx
print(t2.shape)

detrend=np.transpose(t2)

print(detrend.shape)
interfdetrended = np.angle(detrend)

#EXPORT RESULT
dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/detrendALOS.tmp'), 'wb')
interfdetrended.tofile(output_file)
output_file.close()


# PLOT
plt.figure()
plt.imshow(interfrshp)
plt.colorbar()

#plt.figure()
#plt.imshow(interfcrop)
#plt.colorbar()

plt.figure()
plt.imshow(np.angle(detrend))
plt.colorbar()

plt.show()

