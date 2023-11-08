#!/bin/bash
######################################################################################
# This script transforms a ENVI in kmz
#
# Parameters: Envi file with path
#
# New in Distro V 1.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
######################################################################################

INPUTFILE=$1

# direct; black and white = ok only for amplitude 
gdal_translate -of KMLSUPEROVERLAY  ${INPUTFILE} ${INPUTFILE}.kmz -co FORMAT=JPEG 

# trick if need colortable  - not operational - see how create color table with python gdal tool for instance 
#gdal_translate -of GTiff ${INPUTFILE} ${INPUTFILE}.tif
#gdaldem color-relief -nearest_color_entry -alpha -co format=png -of KMLSUPEROVERLAY ${INPUTFILE}.tif /Users/doris/PROCESS/SCRIPTS_MT/TemplatesForPlots/ColorTableGDAL.txt ${INPUTFILE}.kmz

