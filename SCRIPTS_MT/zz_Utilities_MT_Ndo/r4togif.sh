#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at transforming all r4 matrix (of WIDTH pixel wide given as param) 
# from dir in jpg with date tag at given place (hard coded) and cropped at given dimensions 
# (hard coded), then make a GIF out of it. 
#
# MUST BE LAUNCHED FROM DIR WHERE R4 DATA ARE STORED
#
#
# Parameters :  - width of r4 files (in pixels)
#
# Dependencies:	 
#    	- gnu grep for more compatibility. 
#    	- convert (to create/crop jpg images)
# 		- cpxfiddle
#
# Hard coded:	- font size for date tag
#				- date tag position 
#				- crop position and size
#
# V 1.0 (Jul 25, 2022)
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
echo "Processing launched on $(date) " 
echo " " 


WIDTH=$1

# vvvvvvvvvvvvvvvvv Hard coded vvvvvvvvvvvvvvvv

# Date tag
FONTDATE=12 	# size of font for date tag
LABELX=10 		# X corner of DATE TAG
LABELY=10 		# Y corner of DATE TAG

# Crop crops as XxY size+X+Y offset (i.e. offset = upper left corner coord as displayed e.g. with Fiji)
# Adjust crop e.g. by testing on a jpg file as follow: convert img.jpg -crop 450x450+1435+1010 +repage imgCROP.jpg 
ULCORNERX=450
ULCORNERY=450
CROPSIZEX=1430
CROPSIZEY=1010

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


function MakeFig()
	{
		unset WDT E S TYPE COLOR ML FORMAT FILE
		local WDT=$1
		local E=$2
		local S=$3
		local TYPE=$4
		local COLOR=$5
		local ML=$6
		local FORMAT=$7
		local FILE=$8
		eval FILE=${FILE}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WDT} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WDT} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}
	

for IMG in `find . -maxdepth 1 -type f -name "*.r4"`
do 
	# get date 
	IMGDATE=`echo "${IMG}" | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select date where date is supposed to be the only 8 digits long string in name`

	# Make raster
	MakeFig ${WIDTH} 1.0 2.0 normal gray 1/1 r4 ${IMG}

	# Make jpg
	${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '2640>' ${IMG}.ras ${IMG}_temp.jpg 2> /dev/null


	# print date tag after convertion to avoid saturation
	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize ${FONTDATE} -fill black -annotate"
	POSDATECELL=" +${LABELX}+${LABELY} "

	${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${IMGDATE}" ${IMG}_temp.jpg ${IMG}.jpg 2> /dev/null
	rm -f ${IMG}_temp.jpg 

done

# convert all jpg as gif
${PATHCONV}/convert -delay 20 *jpg _movie.gif

# crop movie as XxY size+X+Y offset (i.e. offset = upper left corner coord as displayed e.g. with Fiji)
convert _movie.gif -coalesce -crop ${ULCORNERX}x${ULCORNERY}+${CROPSIZEX}+${CROPSIZEY} +repage _movie_Crop_.gif





