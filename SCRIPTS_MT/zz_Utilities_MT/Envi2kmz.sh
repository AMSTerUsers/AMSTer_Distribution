#!/bin/bash
######################################################################################
# This script transforms a ENVI in kmz
#
# Parameters: Envi file with path
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 1.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


INPUTFILE=$1

# direct; black and white = ok only for amplitude 
gdal_translate -of KMLSUPEROVERLAY  ${INPUTFILE} ${INPUTFILE}.kmz -co FORMAT=JPEG 

# trick if need colortable  - not operational - see how create color table with python gdal tool for instance 
#gdal_translate -of GTiff ${INPUTFILE} ${INPUTFILE}.tif
#gdaldem color-relief -nearest_color_entry -alpha -co format=png -of KMLSUPEROVERLAY ${INPUTFILE}.tif /Users/doris/PROCESS/SCRIPTS_MT/TemplatesForPlots/ColorTableGDAL.txt ${INPUTFILE}.kmz

