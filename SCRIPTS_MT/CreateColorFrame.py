#!/opt/local/amster_python_env/bin/python
# -*-coding:Utf-8 -*
#import struct
#	Dependencies: 
#	-  Python + Numpy
#	-  Python + GDAL (osgeo) -> only required for the GeoTIFF mode
#	- gnu sed for more compatibility
#	- Python + Numpy + script: CreateColorFrame.py
#
#	Two calling modes:
#
#	A/ ENVI mode (historical, 6 arguments) : Defo + Coh + Ampli are combined
#	- Argument 1 = Deformation file (ENVI binary file)
#	- Argument 2 = Coherence file (mask binary file)
#	- Argument 3 = Amplitude file (average binary file)
#	- Argument 4 = Width (data from amplitude header file)
#	- Argument 5 = Temp file (used to report value in the mother script)
#	- Argument 6 = Parameters files
#
#	B/ GeoTIFF mode : ONLY the deformation raster is processed
#	   (no coherence, no amplitude, hence no light background square built from
#	    the amplitude and no coherence masking: the legend is burnt directly in
#	    the deformation raster, and the surrounding square is set to NoData)
#	   Two ways to call it, both accepted:
#	   b1/ 3 arguments (recommended):
#	       - Argument 1 = Deformation file (.tif / .tiff)
#	       - Argument 2 = Temp file
#	       - Argument 3 = Parameters file
#	   b2/ same 6 arguments as the ENVI mode, for a drop-in replacement in the
#	       mother script: arguments 2 (coh), 3 (ampli) and 4 (width) are then
#	       simply IGNORED (they can be "NONE", "" or dummy values). The width and
#	       the number of lines are read from the GeoTIFF itself.
#
#	   Output file naming in GeoTIFF mode: the suffix is inserted BEFORE the
#	   extension, i.e. Defo.tif -> Defo_2.0.tif (a file named "Defo.tif_2.0"
#	   would not be recognized by GDAL/QGIS). Georeferencing (geotransform,
#	   projection, NoData) is preserved.
#	   A second (Byte) file Defo_2.0_msk.tif is also created: 255 where the
#	   deformation is valid, 0 on the NoData pixels and on the square around the
#	   legend. It plays the role of the coherence in the ENVI mode, i.e. it is
#	   used as the Saturation slice of the HSB figure by AmpTif_map.sh.
#
#	Action:
#	- Convert in array the 3-binary file (ENVI mode) or the single tif band (tif mode)
#	- Read data from parameters file
#	- Record the min/max value of deformation file
#	- Calculate delta = (max-min)/LegendWidth
#	- Copy the arrays 'Raw' to a new array 'Mod'
#	- ENVI mode: record the max value of Amplitude array (= lightest value of image)
#	- Create a rectangle where the legend will be located. The position of this rectangle is defined by 4 variables that must be adapted to region. (Top-Left pixel of this square is [i;k] and Bottom-Right  by [sq_H; sq_L])
#	- ENVI mode: in amplitude file, write the recorded max value to create a light square 
#	- ENVI mode: in coherence file, write 0.0 to avoid any deformation info at this place
#	  tif mode : in the deformation file, write NoData in that square instead
#	- Create a rectangle in the deformation image where the graduated color frame will be located. The position of this rectangle is defined by 4 variables that must be adapted to region. (Top-Left pixel of this square is [i;StartLeft]. Size of this rectangle is width x height [LegendWidth x (l-i)].
#	- In deformation file, create a horizontal frame in this rectangle.  
#	- ENVI mode: in coherence file, write 0.9 to make deformation info visible at this place.
#	- We write in the 1st pixel of deformation file a value = 120% of highest value. As the colorframe RGB will be generated with following color code: lowest value in the file = Red and highest value of the file = Red, we want a value 120% higher in order to have all our deformation values within the color from Red to Pink. 
#	- Write the output file(s) (= Input file + _2.0)
#	- Create an array with Min/Max value of deformation file and the position of colorframe in the image to add at the same place comments in others scripts. 
#	- Write all these info in the TempFile argument
#
# New in Distro V 1.0 20231213:	- convert potential negative infinite value to nan for amplitude file (Array_AmpliMod[_inf] = np.nan)
# New in Distro V 2.0 20250813:	- launched from python3 venv
# New in Distro V 3.0 20260731:	- accept GeoTIFF deformation file as input. In that case, only the 
#								  deformation image is processed (no coherence, no amplitude) and the 
#								  output is a georeferenced GeoTIFF <name>_2.0.tif
#								- in GeoTIFF mode, also write a Byte validity mask <name>_2.0_msk.tif 
#								  (255 = valid, 0 = NoData and legend square) that replaces the 
#								  coherence when building the HSB figure (see AmpTif_map.sh)
#								- NoData / NaN aware min-max computation in GeoTIFF mode
#								- clamp the legend geometry to the raster size instead of crashing
#								- suppress GDAL .aux.xml sidecar files (GDAL_PAM_ENABLED=NO)
# New in Distro V 3.1 20260804:	- GeoTIFF mode: ignore NaN, +/-inf and absurd magnitudes (see
#								  MAX_PLAUSIBLE_ABS) when computing min/max. An undeclared NoData sentinel
#								  such as -3.4e38 used to become min_ADR, which flattened delta so much
#								  that the whole legend and every valid pixel ended up on the same hue
#								  (uniformly red map, white where the mask said NoData)
#								- report the number of usable pixels and the min/max actually used
#
#
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# -----------------------------------------------------------------------------------------


import sys
import os
import numpy as np
import fnmatch

# Do not let GDAL pollute the disk with .aux.xml sidecar files
os.environ['GDAL_PAM_ENABLED'] = 'NO'

# Creation options for the output GeoTIFF. Keep it empty (i.e. plain uncompressed
# GeoTIFF) for maximum compatibility with msbas and the rest of the chain.
# e.g. GTIFF_CREATE_OPTIONS = ['COMPRESS=DEFLATE', 'PREDICTOR=3']
GTIFF_CREATE_OPTIONS = []

SUFFIX = '_2.0'

# A deformation rate whose magnitude exceeds this can not be real; it is a NoData sentinel
# that was either not declared in the raster, or declared with a value that does not compare
# equal to what is actually stored (exact float equality). Such values used to drive min/max
# and hence flattened the whole colour scale to a single hue.
MAX_PLAUSIBLE_ABS = 1.0e6


###############################################################################
# Helper functions
###############################################################################

def IsTiff(FilePath):
	"""Return True if FilePath looks like a (Big)TIFF, based on the extension 
	   first, then on the magic bytes as a fallback."""
	if FilePath is None or FilePath == '' :
		return False
	Ext = os.path.splitext(FilePath)[1].lower()
	if Ext in ('.tif', '.tiff') :
		return True
	try:
		with open(FilePath, 'rb') as fid:
			Magic = fid.read(4)
	except (IOError, OSError):
		return False
	# classic TIFF little/big endian, and BigTIFF little/big endian
	return Magic in (b'II\x2a\x00', b'MM\x00\x2a', b'II\x2b\x00', b'MM\x00\x2b')


def TiffOutputName(FilePath, Suffix):
	"""Defo.tif -> Defo_2.0.tif   (the suffix must stay before the extension 
	   otherwise GDAL/QGIS will not open the file)."""
	Base, Ext = os.path.splitext(FilePath)
	return Base + Suffix + Ext


def ReadTiff(FilePath):
	"""Read the first band of a GeoTIFF as a flat float32 array.
	   NoData is converted to NaN internally.
	   Returns (FlatArray, NrOfLines, NrOfPixels, RefInfo)."""
	try:
		from osgeo import gdal
	except ImportError:
		print("ERROR: GDAL python bindings (osgeo) are required to process GeoTIFF files.")
		sys.exit(1)
	gdal.UseExceptions()
	Ds = gdal.Open(FilePath, gdal.GA_ReadOnly)
	if Ds is None:
		print("ERROR: can not open %s with GDAL" % FilePath)
		sys.exit(1)
	if Ds.RasterCount > 1:
		print("WARNING: %s has %d bands; only band 1 is used." % (FilePath, Ds.RasterCount))
	Band = Ds.GetRasterBand(1)
	NoData = Band.GetNoDataValue()
	Arr = Band.ReadAsArray().astype('float32')
	NrOfLines, NrOfPixels = Arr.shape
	RefInfo = {'geotransform': Ds.GetGeoTransform(),
			   'projection': Ds.GetProjection(),
			   'metadata': Ds.GetMetadata(),
			   'nodata': NoData}
	Band = None
	Ds = None
	Arr = Arr.ravel()
	# make all invalid values NaN so that nanmin/nanmax are meaningful
	if NoData is not None and not np.isnan(NoData):
		Arr[Arr == np.float32(NoData)] = np.nan
	# NaN, +/-inf and absurd magnitudes can not be deformation rates. They are typically NoData
	# sentinels (+/-3.4e38, 1e30...) that were not declared, or declared with a value that the
	# exact equality above can not match. Turn them into NaN so that they drive neither the
	# colour scale nor the validity mask; otherwise the 8-bit conversion downstream collapses
	# every real value into a single hue (a uniformly red map and legend).
	with np.errstate(invalid='ignore'):
		Bad = ~np.isfinite(Arr) | (np.abs(Arr) > np.float32(MAX_PLAUSIBLE_ABS))
	NrBad = int(np.count_nonzero(Bad))
	if NrBad > 0:
		print("%i pixels of %s are unusable (NaN, inf or |value| > %g) and are masked out."
			  % (NrBad, os.path.basename(FilePath), MAX_PLAUSIBLE_ABS))
	Arr[Bad] = np.nan
	if NoData is None:
		print("WARNING: %s declares no NoData value." % os.path.basename(FilePath))
	return Arr, NrOfLines, NrOfPixels, RefInfo


def WriteTiff(FilePath, FlatArray, NrOfLines, NrOfPixels, RefInfo):
	"""Write a flat float32 array as a single band GeoTIFF, keeping the 
	   georeferencing of the input file. NaN are written back as the original 
	   NoData value when the input had a finite one."""
	from osgeo import gdal
	gdal.UseExceptions()

	NoDataIn = RefInfo['nodata']
	if NoDataIn is not None and not np.isnan(NoDataIn):
		NoDataOut = np.float32(NoDataIn)
		Out = np.where(np.isnan(FlatArray), NoDataOut, FlatArray).astype('float32')
	else:
		NoDataOut = np.float32(np.nan)
		Out = FlatArray.astype('float32')

	Drv = gdal.GetDriverByName('GTiff')
	Ds = Drv.Create(FilePath, NrOfPixels, NrOfLines, 1, gdal.GDT_Float32, options=GTIFF_CREATE_OPTIONS)
	if Ds is None:
		print("ERROR: can not create %s" % FilePath)
		sys.exit(1)
	if RefInfo['geotransform'] is not None:
		Ds.SetGeoTransform(RefInfo['geotransform'])
	if RefInfo['projection']:
		Ds.SetProjection(RefInfo['projection'])
	if RefInfo['metadata']:
		Ds.SetMetadata(RefInfo['metadata'])
	Band = Ds.GetRasterBand(1)
	Band.SetNoDataValue(float(NoDataOut))
	Band.WriteArray(Out.reshape(NrOfLines, NrOfPixels))
	Band.FlushCache()
	Band = None
	Ds = None


def WriteMaskTiff(FilePath, FlatMask, NrOfLines, NrOfPixels, RefInfo):
	"""Write a flat uint8 array (255 = valid pixel, 0 = NoData) as a Byte GeoTIFF.
	   Used downstream (e.g. AmpTif_map.sh) as the Saturation slice of the HSB 
	   figure, so that the NoData areas and the legend background appear white 
	   instead of taking the color of the lowest deformation value."""
	from osgeo import gdal
	gdal.UseExceptions()
	Drv = gdal.GetDriverByName('GTiff')
	Ds = Drv.Create(FilePath, NrOfPixels, NrOfLines, 1, gdal.GDT_Byte, options=GTIFF_CREATE_OPTIONS)
	if Ds is None:
		print("ERROR: can not create %s" % FilePath)
		sys.exit(1)
	if RefInfo['geotransform'] is not None:
		Ds.SetGeoTransform(RefInfo['geotransform'])
	if RefInfo['projection']:
		Ds.SetProjection(RefInfo['projection'])
	Band = Ds.GetRasterBand(1)
	Band.WriteArray(FlatMask.reshape(NrOfLines, NrOfPixels))
	Band.FlushCache()
	Band = None
	Ds = None


def Usage():
	print("Usage (ENVI mode) : CreateColorFrame.py Defo Coh Ampli Width TempFile ParamFile")
	print("Usage (tif  mode) : CreateColorFrame.py Defo.tif TempFile ParamFile")
	print("             or   : CreateColorFrame.py Defo.tif NONE NONE NONE TempFile ParamFile")


###############################################################################
# Arguments
###############################################################################

MaskRaw = None
AmpliRaw = None

if len(sys.argv) == 4 and IsTiff(sys.argv[1]):
	# GeoTIFF short call
	DefoRaw = sys.argv[1]
	TempFile = sys.argv[2]
	ParamFile = sys.argv[3]
	WidthRaw = None
elif len(sys.argv) == 7:
	# historical call (also accepted for GeoTIFF, args 2-3-4 are then ignored)
	DefoRaw = sys.argv[1]
	MaskRaw = sys.argv[2]
	AmpliRaw = sys.argv[3]
	WidthRaw = sys.argv[4]
	TempFile = sys.argv[5]
	ParamFile = sys.argv[6]
else:
	print("Issue occured when Running python script... bad argument number")
	Usage()
	sys.exit(1)

TIFF_MODE = IsTiff(DefoRaw)

if TIFF_MODE:
	DefoMod = TiffOutputName(DefoRaw, SUFFIX)
	MskMod = TiffOutputName(DefoRaw, SUFFIX + '_msk')
	print("GeoTIFF mode: only the deformation raster is processed (no coherence, no amplitude).")
	print("Output: %s" % DefoMod)
	print("Output: %s (validity mask, 255 = valid, 0 = NoData)" % MskMod)
else:
	if MaskRaw is None or AmpliRaw is None or WidthRaw is None:
		print("ENVI mode requires the 6 arguments.")
		Usage()
		sys.exit(1)
	DefoMod = DefoRaw + SUFFIX
	MaskMod = MaskRaw + SUFFIX
	AmpliMod = AmpliRaw + SUFFIX


###############################################################################
# Read the input raster(s)
###############################################################################

if TIFF_MODE:
	Array_DefoRaw, NrOfLines, WidthRaw, RefInfo = ReadTiff(DefoRaw)
	print("Width  = %d" % WidthRaw)
	print("Lines  = %d" % NrOfLines)
else:
	print(type (WidthRaw))
	Array_DefoRaw = np.fromfile(DefoRaw, dtype='float32')   #Read files as an array of float
	Array_MaskRaw = np.fromfile(MaskRaw, dtype='float32')   #Read files as an array of float
	Array_AmpliRaw = np.fromfile(AmpliRaw, dtype='float32')
	WidthRaw = int(WidthRaw)	#Convert the argument into integer
	NrOfLines = int(Array_DefoRaw.size // WidthRaw)


###############################################################################
# Read Data from parameters file 
###############################################################################

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

StartLeft = Margin

# Keep the legend inside the raster instead of crashing on out of range indices
if LegendWidth + (2 * StartLeft) > WidthRaw:
	NewLegendWidth = WidthRaw - (2 * StartLeft)
	if NewLegendWidth < 1:
		print("ERROR: raster too narrow (%d pixels) for Margin = %d" % (WidthRaw, StartLeft))
		sys.exit(1)
	print("WARNING: LegendWidth (%d) too large for a raster of %d pixels; reduced to %d." 
		  % (LegendWidth, WidthRaw, NewLegendWidth))
	LegendWidth = NewLegendWidth
if LegendHeight > NrOfLines:
	print("WARNING: LegendHeight (%d) larger than the raster height (%d); clamped." % (LegendHeight, NrOfLines))
	LegendHeight = float(NrOfLines)
if FrameBott > NrOfLines:
	print("WARNING: FrameBott (%d) larger than the raster height (%d); clamped." % (FrameBott, NrOfLines))
	FrameBott = float(NrOfLines)

if TIFF_MODE:
	# NoData has been turned into NaN, hence nanmin/nanmax
	if np.all(np.isnan(Array_DefoRaw)):
		print("ERROR: %s contains no usable value at all (only NoData, NaN or inf)." % DefoRaw)
		sys.exit(1)
	min_ADR = np.nanmin(Array_DefoRaw)
	max_ADR = np.nanmax(Array_DefoRaw)
	NrOk = int(np.count_nonzero(~np.isnan(Array_DefoRaw)))
	print("Colour scale taken from the %i usable pixels: min = %g, max = %g"
		  % (NrOk, min_ADR, max_ADR))
	if max_ADR == min_ADR:
		print("WARNING: min equals max, the colour scale will be flat (uniform hue).")
else:
	min_ADR = np.amin(Array_DefoRaw)
	max_ADR = np.amax(Array_DefoRaw)

delta = (max_ADR - min_ADR) / LegendWidth
Frame = min_ADR

Array_DefoMod = Array_DefoRaw.copy()

if not TIFF_MODE:
	#-Mask array preparation (nothing special)

	Array_MaskMod = Array_MaskRaw

	# Amplitude array preparation
	# Retrieve max value to create a white background for the legend
	# Build a square around the legend (sq_L and sq_H )
	# Convert to Log value

	Array_AmpliMod = np.nan_to_num(Array_AmpliRaw)	
	max_AAM = np.amax(Array_AmpliMod)
	max_AAM = max_AAM - ColorBackgrdLegnd	# To create a little bit of grey instead of flashy white

sq_L = LegendWidth + (2 * StartLeft)
sq_H = LegendHeight

# Build a bigger square to highlight the Framecolor
#  - ENVI mode: light square in the amplitude, coherence set to 0
#  - tif  mode: no amplitude nor coherence available, so the square is set to 
#               NoData (NaN) in the deformation raster itself
i=0
k=0
while i < sq_H:
	j = int((i*WidthRaw)+k);
	PixEnd = j + sq_L
	while j < PixEnd:
		if TIFF_MODE:
			Array_DefoMod[j] = np.nan
		else:
			Array_AmpliMod[j] = max_AAM
			Array_MaskMod[j] = 0.0
		j += 1
	i += 1

if not TIFF_MODE:
	# Convert Amplitude value to log10 for better contrast and convert potential negative infinite value to nan 
	Array_AmpliMod = np.log10(Array_AmpliMod) 
	_inf = np.isinf(Array_AmpliMod)
	Array_AmpliMod[_inf] = np.nan  

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
		if not TIFF_MODE:
			Array_MaskMod[j] = 0.9
		Frame += delta
		j += 1
	i += 1


# Write a higher value in one pixel to avoid one complete color cycle in the legend (based on lowest and highest value)
# Changing the value "5" will change the colour scale here but not in the KMz
Array_DefoMod[0] = max_ADR + ((max_ADR - min_ADR)/5)

######   Write output

if TIFF_MODE:
	WriteTiff(DefoMod, Array_DefoMod, NrOfLines, WidthRaw, RefInfo)
	# Companion validity mask: 255 where the deformation is valid, 0 elsewhere 
	# (original NoData + the square around the legend). 
	Array_Msk = np.where(np.isnan(Array_DefoMod), 0, 255).astype('uint8')
	WriteMaskTiff(MskMod, Array_Msk, NrOfLines, WidthRaw, RefInfo)
else:
	with open(DefoMod, "wb") as dest:	# Open a binary writable file
		Array_DefoMod.astype('float32').tofile(dest)    #Write in this file the array

	with open(MaskMod, "wb") as dest:	# Open a binary writable file
		Array_MaskMod.astype('float32').tofile(dest)    #Write in this file the array

	with open(AmpliMod, "wb") as dest:	# Open a binary writable file
		Array_AmpliMod.astype('float32').tofile(dest)    #Write in this file the array


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
