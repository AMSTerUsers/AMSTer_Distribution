#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at creating a gif from all geocoded amplitude rasters that are in SAR_MASSPROCESS/GeocodedRasters/Ampli
#
# MUST BE LAUNCHED FROM DIR WHERE AMPLI ARE STORED
#
# Parameters :  - X and Y coord of date tag position
#				- font size for date tag
#				- output images resolution 
#				- output dir where to store results 
#
# Hard coded:	- Some hard coded info about plot style : font, color...
#
# Dependencies:	 
#		- convert
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

LABELX=$1					# position of the date label in jpg fig of mod
LABELY=$2					# position of the date label in jpg fig of mod
FONTSIZE=$3 				# size of date tag font (e.g. 24)
RESOL=$4					# resolution of output images (e.g. 2640 for normal images or 10640 for huges images such as S1)
OUTPUTDIR=$5				# where to store gif

mkdir -p ${OUTPUTDIR}

# test if we are in a GeocodedRaster dir 

AMPLDIR=$(pwd)

cd ..

GEOCRASDIR=`basename $(pwd)`

if [ ${GEOCRASDIR} != "GeocodedRasters" ] ; then echo " You seems to be in the wrong dir. You must be in something like SAR_MASSPROCESS/SAT/TRK/REGION_ML/GeocodedRasters/Ampli" ; exit ; fi

cd ${AMPLDIR}
for AMPLIRAS in `ls *.ras`
do 
	# Get date to tag
	DATEIMG=`echo "${AMPLIRAS}" | cut -d . -f 1 | ${PATHGNU}/grep -Eo "[0-9]{8}" `
	echo "Convert ${DATEIMG}"
	# cosmetic adjustements 
	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize ${FONTSIZE} -fill black -annotate"
	POSDATECELL=" +${LABELX}+${LABELY} "
	${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize "${RESOL}>" ${AMPLIRAS} ${OUTPUTDIR}/${AMPLIRAS}_temp.jpg > /dev/null 2>&1
	# print tag after convertion to avoid saturation
	${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${DATEIMG}" ${OUTPUTDIR}/${AMPLIRAS}_temp.jpg ${OUTPUTDIR}/${AMPLIRAS}.jpg > /dev/null 2>&1
	rm ${OUTPUTDIR}/${AMPLIRAS}_temp.jpg
done 

cd ${OUTPUTDIR}
${PATHCONV}/convert -delay 20 *jpg _Ampli.gif
rm *.jpg

