#!/bin/bash
######################################################################################
# This script transforms a ENVI files in color kmz to be open in GoogleEarh for instance 
#
# Parameters: 	- Envi file with path
#
# Dependencies: - color table
#				- gdal
#
# Hard coded:	- color table (with path): ColorTableGDAL.txt, ColorTableKMZ.txt, ColorTableKMZ_2.txt... 
#					Feel free to change your table !
#
# New in Distro V 1.0:	- Based on Beta V1.0
#				V 1.0.1: - fix prblm of path to ColorTableKMZ.txt
#				V 1.0.2: - fix bug in naming hdr (dot was missing before binFlatColor.hdr)
# New in Distro V 1.1.0: - Color tables are now in TemplatesForPlots
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

INPUTFILE=$1

# Color - Uggly color table - I know...  
COLORTABLE=${PATH_SCRIPTS}/SCRIPTS_MT/TemplatesForPlots/ColorTableKMZ.txt
#COLORTABLE=/${HOME}/SAR/SCRIPTS_MT/TemplatesForPlots/ColorTableKMZ.txt

#COLORTABLE=/Users/doris/PROCESS/SCRIPTS_MT/TemplatesForPlots/ColorTableGDAL0_255.txt

gdal_translate -scale -0.05 0.05 0 16 -of ENVI ${INPUTFILE} ${INPUTFILE}Flat 
gdaldem color-relief -of ENVI  ${INPUTFILE}Flat ${COLORTABLE} ${INPUTFILE}FlatColor
INPUTFILENOBIN=`echo "${INPUTFILE%.*}"`
gdal_translate -of KMLSUPEROVERLAY ${INPUTFILE}FlatColor ${INPUTFILE}FlatColor.kmz -co FORMAT=JPEG 
mv ${INPUTFILENOBIN}.hdr ${INPUTFILENOBIN}.binFlatColor.hdr

rm -f ${INPUTFILE}Flat ${INPUTFILE}Flat.aux.xml


