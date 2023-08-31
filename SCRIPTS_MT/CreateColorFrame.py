#!/opt/local/bin/python
# -*-coding:Utf-8 -*
#import struct
#	Dependencies: 
#	-  Python + Numpy
#	- gnu sed for more compatibility
#	- Python + Numpy + script: CreateColorFrame.py
#	Arguments:
#	- Argument 1 = Deformation file (binary file)
#	- Argument 2 = Coherence file (mask binary file)
#	- Argument 3 = Amplitude file (average binary file)
#	- Argument 4 = Width (data from amplitude header file)
#	- Argument 5 = Temp file (used to report value in the mother script)
#	- Argument 6 = Parameters files
#
#	Action:
#	- Convert in array the 3-binary file
#	- Read data from parameters file
#	- Record the min/max value of deformation file
#	- Calculate delta = (max-min)/LegendWidth
#	- Copy the 3 arrays ‘Raw’ to a new array ‘Mod’
#	- Record the max value of Amplitude array (= lightest value of image)
#	- Create a rectangle in the amplitude image where the legend will be located. The position of this rectangle is defined by 4 variables that must be adapted to region. (Top-Left pixel of this square is [i;k] and Bottom-Right  by [sq_H; sq_L])
#	- In amplitude file, write the recorded max value to create a light square 
#	- In coherence file, write 0.0 to avoid any deformation info at this place
#	- Create a rectangle in the deformation image where the graduated color frame will be located. The position of this rectangle is defined by 4 variables that must be adapted to region. (Top-Left pixel of this square is [i;StartLeft]. Size of this rectangle is width x height [LegendWidth x (l-i)].
#	- In deformation file, create a horizontal frame in this rectangle.  
#	- In coherence file, write 0.9 to make deformation info visible at this place.
#	- We write in the 1st pixel of deformation file a value = 120% of highest value. As the colorframe RGB will be generated with following color code: lowest value in the file = Red and highest value of the file = Red, we want a value 120% higher in order to have all our deformation values within the color from Red to Pink. 
#	- Write the 3 output binary file (= Input file + _2.0)
#	- Create an array with Min/Max value of deformation file and the position of colorframe in the image to add at the same place comments in others scripts. 
#	- Write all these info in the 5th argument: TemFile 





import sys
import os
import numpy as np
import fnmatch

#Check argument number 

if len(sys.argv) != 7:
	print("Issue occured when Running python script... bad argument number")
	
#Variable definition for the treatment of amplitude files

DefoRaw = sys.argv[1]
MaskRaw = sys.argv[2]
AmpliRaw = sys.argv[3]
WidthRaw = sys.argv[4]
TempFile = sys.argv[5]
ParamFile = sys.argv[6]
DefoMod = DefoRaw + '_2.0'
MaskMod = MaskRaw + '_2.0'
AmpliMod = AmpliRaw + '_2.0'

print(type (WidthRaw))
Array_DefoRaw = np.fromfile(DefoRaw, dtype='float32')   #Read files as an array of float
Array_MaskRaw = np.fromfile(MaskRaw, dtype='float32')   #Read files as an array of float
Array_AmpliRaw = np.fromfile(AmpliRaw, dtype='float32')


# Read Data from parameters file 
with open(ParamFile, "r") as params:
	for line in params:
	  if 'Margin' in line:
		   Margin = int(line.split('\t')[0])
	  if 'LegendWidth' in line:
		   LegendWidth = int(line.split('\t')[0])	
	  if 'ColorBackgrdLegnd' in line:
 		   ColorBackgrdLegnd = float(line.split('\t')[0])
	  if 'LegendHeight' in line:
 		   LegendHeight = float(line.split('\t')[0])
	  if 'FrameTop' in line:
 		   FrameTop = float(line.split('\t')[0])
	  if 'FrameBott' in line:
 		   FrameBott = float(line.split('\t')[0])
#-Deformation array preparation. Retrieve min/max value to create the color legend.
#Create array of 400 pixels to build the color legend 
#This array will be a linear incrementation from the lowest to the highest value of the Defo binary file
# Variable LegendWidth is the length of the frame legend

WidthRaw = int(WidthRaw)	#Convert the argument into integer
StartLeft = Margin


min_ADR = np.amin(Array_DefoRaw)
max_ADR = np.amax(Array_DefoRaw)


delta= (max_ADR - min_ADR)/LegendWidth
Frame = min_ADR

Array_DefoMod = Array_DefoRaw

#-Mask array preparation (nothing special)

Array_MaskMod = Array_MaskRaw

# Amplitude array preparation
# Retrieve max value to create a white background for the legend
# Build a square around the legend (sq_L and sq_H )
# Convert to Log value

Array_AmpliMod = np.nan_to_num(Array_AmpliRaw)	
max_AAM = np.amax(Array_AmpliMod)
max_AAM = max_AAM - ColorBackgrdLegnd	# To create a little bit of grey instead of flashy white
sq_L = LegendWidth + (2*StartLeft)
sq_H = LegendHeight

# Build a bigger square in the amplitude view to highlight the Framecolor
i=0
k=0
while i < sq_H:
	j = int((i*WidthRaw)+k);
	PixEnd = j + sq_L
	while j < PixEnd:
		Array_AmpliMod[j] = max_AAM
		Array_MaskMod[j] = 0.0
		j += 1
	i += 1

Array_AmpliMod = np.log10(Array_AmpliMod)   
# Add the color legend to the Deformation array and a mask to the Mask array
#Start the legend at 20 pixels from left and 20 pixels from the top

i=FrameTop
l=FrameBott
while i < l:
	Frame = min_ADR
	j = int((i*WidthRaw) + StartLeft);
	PixEnd = j + LegendWidth
	while j < PixEnd:
		Array_DefoMod[j] = Frame
		Array_MaskMod[j] = 0.9
		Frame += delta
		j += 1
	i += 1



# Write a higher value in one pixel to avoid one complete color cycle in the legend (based on lowest and highest value)
# Changing the value "5" will change the colour scale here but not in the KMz
Array_DefoMod[0] = max_ADR + ((max_ADR - min_ADR)/5)

######   Write output


dest = open(DefoMod, "wb")	# Open a binary writable file
dest.write(Array_DefoMod)    #Write in this file the array
dest.close()


dest = open(MaskMod, "wb")	# Open a binary writable file
dest.write(Array_MaskMod)    #Write in this file the array
dest.close()

dest = open(AmpliMod, "wb")	# Open a binary writable file
dest.write(Array_AmpliMod)    #Write in this file the array
dest.close()


### Write to the output of this script the 3 followings information:
# 1.	Max Value of deformation rate	(*100 for cm/an)
# 2. 	Min Value of deformation rate
# 3.	Position of zero in the legend (from to left in pixels)	
	
array_legend = np.zeros(5)

MinVal= min_ADR*100
MaxVal= max_ADR*100
PosZero = (abs((min_ADR/(max_ADR-min_ADR))*LegendWidth))+StartLeft  #abs = valeur absolue
PosLeft = StartLeft
PosRight = StartLeft + LegendWidth


# print("-------")
# print(min_ADR)
# print(max_ADR)
# print(MinVal)
# print(MaxVal)
# print(PosLeft)
# print(PosZero)
# print(PosRight)
# print("-------")



array_legend[0] = MinVal
array_legend[1] = MaxVal
array_legend[2] = PosLeft
array_legend[3] = PosZero
array_legend[4] = PosRight

print("aaaa")
print(array_legend)
dest = open(TempFile, "w+")
dest.write(str(array_legend[0]))
dest.write("\n")
dest.write(str(array_legend[1]))
dest.write("\n")
dest.write(str(array_legend[2]))
dest.write("\n")
dest.write(str(array_legend[3]))
dest.write("\n")
dest.write(str(array_legend[4]))
dest.close()
print("bbbb")
