#!/bin/bash
# -----------------------------------------------------------------------------------------
# Script to make Fiji figure using only deformation tif map (used instead of AmpDefo_map.sh 
# because msbasv10 using tif files may use pix tracking defor maps and hence have no coh and ampl)
#   Size of the images are taken form tif file. 
#
# Parameters: - PATHFILEDEFO 	: path and name of deformation file in GeoTIFF format
#			  - Argument 2      : AMPLI_COH_MSBAS_LINEAR_RATE_** (output file) - not fake name for sake of compatibility
#
# Hard coded:	- path to Fiji is defined in .bashrc but the name of the software may differ. See at the end of script
#
# Dependencies:	- __ImageMagickFcts.sh (sourced: sets IMCONVERT and FONT_OPT, same as TimeSeriesInfo_HP.sh)
#				- ImageMagick 6 or 7, or GraphicsMagick
#				- Fiji (ImageJ). (!!! /etc/ImageMagick-6/policy.xml --> increase value to 8GiB at line <policy domain="resource" name="disk" value="1GiB"/>)
#				  Note: ImageJ opens the tif files created here with its native reader, hence 
#				  these MUST be uncompressed and untiled. This is what CreateColorFrame.py does 
#				  by default (GTIFF_CREATE_OPTIONS = []); do not add COMPRESS=... there.
#				- gnu sed for more compatibility. 
#				- gdal (gdalinfo) to get the image size 
#				- python3 + Numpy + GDAL + script: CreateColorFrame.py (Distro V3.0 or above, 
#				  i.e. the version that accepts a GeoTIFF as deformation file)
#				- a parameter file ${PATHFILEDEFO})/TS_parameters.txt with crop size etc...(to be updated manually depending on target)
#  
#Action:
#- Extraction of width and length data from the deformation tif file (gdalinfo)
#- Execute CreateColorFrame.py, which creates:
#		* the deformation tif with the color frame burnt in it	: ..._2.0.tif
#		* a validity mask (255 = valid, 0 = NoData + legend square)	: ..._2.0_msk.tif
#- Write the ImageJscript in a temporary file (>>FijiMacro_${Random}.txt) and execute 
#- The HSB figure is built with:	Hue = deformation, Saturation = validity mask, Brightness = 255
#  (in AmpDefo_map.sh: Hue = deformation, Saturation = coherence, Brightness = amplitude).
#  The NoData areas and the square around the legend hence appear white instead of taking 
#  the color of the lowest deformation value. 
#- Extract the data from TempFile (from CreateColorFrame.py)
#- Draw on the colorframe a line and the value at lowest, zero and highest value. Position of certain value must be adapted to the region.
#- Crop the MSBAS_LINEAR_RATE file (TIF file) to an appropriate zoom and convert it to JPEG. This must be adapted to the region.
#- Save the Legend in a separate file to use in Time Serie graphics.
# 
# New in Distro V 1.0:	- Based on AmpDefo_map.sh V 4.4
# New in Distro V 1.1 20260731:	- do not require coherence nor amplitude :
#								   * call CreateColorFrame.py with its 3 arguments tif syntax
#								   * output of CreateColorFrame.py is now ..._2.0.tif (suffix 
#								     before the extension) and not ..._2.0
#								   * remove the amplitude clipping (IJAmpMin/IJAmpMax)
#								   * Fiji macro opens the tif files directly (no Raw... import) 
#								     and uses the validity mask as Saturation and a constant 
#								     white image as Brightness
#								   * fix the name of the Legend jpg for tif files
# New in Distro V 1.2 20260804:	- change the way to define Direction
# 								- add the missing NS arm in the direction legend (South / North) 
# 								- accept an optional crop window (args 3 to 6) overriding the Crop_* of 
#								  TS_parameters.txt, so that a caller can feed a crop centred on the two 
#								  pixels of a time series and still get the map extracted correctly 
# New in Distro V 1.3 20260804:	- source __ImageMagickFcts.sh and call ${IMCONVERT} instead of convert, 
#								  so that ImageMagick 6, ImageMagick 7 and GraphicsMagick are all 
#								  supported as in TimeSeriesInfo_HP.sh 
#								- use ${FONT_OPT} instead of a hard coded Helvetica/FreeSans, which 
#								  recent convert versions may not know 
# New in Distro V 1.4 20260804:	- write a Legend_*_scale.txt next to the Legend_*.jpg holding the 
#								  min / max the colour bar was built with, converted back to the 
#								  unit of the raster (CreateColorFrame.py reports them *100 for the 
#								  [cm/year] label) and before the truncation to 2 decimals, so that 
#								  TimeSeriesInfo_HP.sh V7.2 (SCALEFROM=LEGEND) can scale its 
#								  thumbnails on exactly the same range as the bar 
# 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


# vvv ----- Hard coded lines to check --- vvv 
source ${HOME}/.bashrc

source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# needed to get FONT_OPT, i.e. the -font option that convert can honour on this machine
source ${PATH_SCRIPTS}/SCRIPTS_MT/__ImageMagickFcts.sh
	# sets TOOL and IMCONVERT (convert / magick / gm convert), sets FONT_OPT if it is not
	# already defined, and defines do_composite
# See Fiji command and options at the end
# ^^^ ----- Hard coded lines to check -- ^^^ 

PRG=`basename "$0"`
VER="Distro V1.4 AMSTer script utilities"
AUT="Nicolas d'Oreye, Maxime Jaspard (c)2016-2021, Last modified on Aug 04, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

PATHFILEDEFO=$1
FILEOUTPUT=$2
# Optional arguments 3 to 6: Crop_X Crop_Y Crop_L Crop_H, i.e. the window used to extract the 
# map from the composite. They override the Crop_* of TS_parameters.txt. Meant for the case 
# where PATHFILEDEFO is already a crop around the two pixels of a time series, padded on top 
# by the band in which CreateColorFrame.py burns the colour ramp: the caller then knows the 
# window, TS_parameters.txt does not. 
CROPARG_X=$3
CROPARG_Y=$4
CROPARG_L=$5
CROPARG_H=$6

ParamFile=$(dirname ${PATHFILEDEFO})/TS_parameters.txt

function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${ParamFile} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}
	

Crop_X=$(GetParam Crop_X)
Crop_Y=$(GetParam Crop_Y)
Crop_L=$(GetParam Crop_L)
Crop_H=$(GetParam Crop_H)

if [ "${CROPARG_L}" != "" ] && [ "${CROPARG_H}" != "" ]
	then
		Crop_X=${CROPARG_X}
		Crop_Y=${CROPARG_Y}
		Crop_L=${CROPARG_L}
		Crop_H=${CROPARG_H}
		echo "Crop window imposed by the caller instead of taken from TS_parameters.txt"
fi
# path one level up 
PATHFILES=$(dirname ${PATHFILEDEFO})



echo "Crop_X = ${Crop_X}"
echo "Crop_Y = ${Crop_Y}"
echo "Crop_L = ${Crop_L}"
echo "Crop_H = ${Crop_H}"
DEFO=`basename ${PATHFILEDEFO}`

# Get image size from the tif file itself 
##WIDTH=`grep "amples" ${PATHFILEAMPLI}.hdr | cut -d= -f2 | ${PATHGNU}/gsed s"/ //g"`
##LENGTH=`grep "ines" ${PATHFILEAMPLI}.hdr | cut -d= -f2 | ${PATHGNU}/gsed s"/ //g"`

WIDTH=$(gdalinfo ${PATHFILEDEFO} | ${PATHGNU}/gawk -F'[ ,]+' '/^Size is/ {print $3}')
LENGTH=$(gdalinfo ${PATHFILEDEFO} | ${PATHGNU}/gawk -F'[ ,]+' '/^Size is/ {print $4}')

if [ "${WIDTH}" == "" ] || [ "${LENGTH}" == "" ]
	then
		echo "ERROR: can not get the size of ${PATHFILEDEFO} with gdalinfo. Is it a valid tif file ?"
		exit 1
fi

echo
echo "Image size is ${WIDTH}  x  ${LENGTH}"
echo 

# Call of Python script to add a color legend on images
# Need to extract folder script path to avoid absolute path
#W_Script_Path=${PATH_SCRIPTS}/SCRIPTS_MT		# !!! temporary !!!


# Declare 3 variable for Deformation min max and position of zero in the legend.
TempFile=${PATHFILES}/temp.txt
echo '' > ${TempFile}


# In tif mode, CreateColorFrame.py only needs the deformation file: no coherence, no 
# amplitude, and the width is read from the tif itself.
# (the 6 arguments syntax below is still accepted, args 2-3-4 being simply ignored)
#${PATH_SCRIPTS}/SCRIPTS_MT/CreateColorFrame.py ${PATHFILEDEFO} NONE NONE ${WIDTH} ${TempFile} ${ParamFile}   # >> /dev/null 2>&1 
${PATH_SCRIPTS}/SCRIPTS_MT/CreateColorFrame.py ${PATHFILEDEFO} ${TempFile} ${ParamFile}   # >> /dev/null 2>&1 
# Wait to ensure that new files are well created
echo "wait 5 seconds to ensure the file is ready"
sleep 5 
#No hdr file to copy here: all the georeferencing info is inside the tif files 
#cp ${PATHFILEAMPLI}.hdr ${PATHFILEAMPLI}_2.0.hdr 
#cp ${PATHFILEDEFO}.hdr ${PATHFILEDEFO}_2.0.hdr 


# Names of the files created by CreateColorFrame.py in tif mode: the suffix is inserted 
# BEFORE the extension, i.e. Defo.tif --> Defo_2.0.tif and Defo_2.0_msk.tif
EXTDEFO="${PATHFILEDEFO##*.}"
PATHFILEDEFO="${PATHFILEDEFO%.*}_2.0.${EXTDEFO}"
PATHFILEMSK="${PATHFILEDEFO%.*}_msk.${EXTDEFO}"
echo $PATHFILEDEFO
echo $PATHFILEMSK

if [ ! -f "${PATHFILEDEFO}" ] || [ ! -s "${PATHFILEDEFO}" ]
	then
		echo "ERROR: ${PATHFILEDEFO} was not created. Check CreateColorFrame.py (Distro V3.0 or above required)."
		exit 1
fi
if [ ! -f "${PATHFILEMSK}" ] || [ ! -s "${PATHFILEMSK}" ]
	then
		echo "ERROR: ${PATHFILEMSK} was not created. Check CreateColorFrame.py (Distro V3.0 or above required)."
		exit 1
fi

# Get files names; these are also the ImageJ window titles because the files are opened 
# with open() and not imported as raw data 
# DO NOT MOVE THESE LINES ABOVE LINE 144
DEFO=`basename ${PATHFILEDEFO}`
MSK=`basename ${PATHFILEMSK}`

# No amplitude anymore, hence no clipping of the amplitude to compute (IJAmpMin/IJAmpMax) 


Random=$(echo ${RANDOM:0:3})
echo "" > FijiMacro_${Random}.txt 

# Open deformation (32-bit float tif with the color frame burnt in it) 
# resetMinAndMax to be sure the 8-bit conversion is scaled on the whole range of the file, 
# including the pixel [0;0] that CreateColorFrame.py sets 20% above the max to avoid a 
# complete cycle of the hue in the legend
echo "open('${PATHFILEDEFO}');" >> FijiMacro_${Random}.txt
echo "resetMinAndMax();" >> FijiMacro_${Random}.txt
echo "run('8-bit');" >> FijiMacro_${Random}.txt

# Open the validity mask (Byte tif: 255 = valid, 0 = NoData and legend square). 
# It plays the role of the coherence of AmpDefo_map.sh
echo "open('${PATHFILEMSK}');" >> FijiMacro_${Random}.txt

# Create a constant white image; it will be the container of the figure and provides the 
# Brightness slice (there is no amplitude to modulate it) 
echo "newImage('FIGURE', '8-bit white', ${WIDTH}, ${LENGTH}, 1);" >> FijiMacro_${Random}.txt
echo "run('RGB Color');" >> FijiMacro_${Random}.txt

# Create Stack
echo "selectWindow('FIGURE');" >> FijiMacro_${Random}.txt
echo "run('HSB Stack');" >> FijiMacro_${Random}.txt

# Get defo in stack (Hue)
echo "selectWindow('${DEFO}');" >> FijiMacro_${Random}.txt
echo "run('Select All');" >> FijiMacro_${Random}.txt
echo "run('Copy');" >> FijiMacro_${Random}.txt
echo "selectWindow('FIGURE');" >> FijiMacro_${Random}.txt
echo "setSlice(1);" >> FijiMacro_${Random}.txt
echo "run('Paste');" >> FijiMacro_${Random}.txt
# Get mask in stack (Saturation)
echo "selectWindow('${MSK}');" >> FijiMacro_${Random}.txt
echo "run('Select All');" >> FijiMacro_${Random}.txt
echo "run('Copy');" >> FijiMacro_${Random}.txt
echo "selectWindow('FIGURE');" >> FijiMacro_${Random}.txt
echo "setSlice(2);" >> FijiMacro_${Random}.txt
echo "run('Paste');" >> FijiMacro_${Random}.txt
# Slice 3 (Brightness) is left at 255 everywhere 

echo "run('RGB Color');" >> FijiMacro_${Random}.txt
echo "saveAs('Tiff', '${PATHFILES}/${FILEOUTPUT}.tif');" >> FijiMacro_${Random}.txt
echo "close();" >> FijiMacro_${Random}.txt



${PATHGNU}/gsed "s/'/\"/g" FijiMacro_${Random}.txt > FijiMacro_${Random}2.txt 

# Pick the Fiji launcher: new Jaunch "fiji" or a legacy platform binary
	if [ -x "${PATHFIJI}/fiji" ]; then
	    FIJI="${PATHFIJI}/fiji"               # new Jaunch (Mac arm64, Linux, ...)
	elif [ -x "${PATHFIJI}/ImageJ-linux64" ]; then
	    FIJI="${PATHFIJI}/ImageJ-linux64"     # legacy Linux
	elif [ -x "${PATHFIJI}/ImageJ-macosx" ]; then
	    FIJI="${PATHFIJI}/ImageJ-macosx"      # legacy Intel Mac
	else
	    echo "ERROR: no Fiji/ImageJ launcher found in ${PATHFIJI}" >&2
	    exit 1
	fi

case ${OS} in 
	"Linux") 
		export DISPLAY=:10
		#font="FreeSans"		# NdO Aug 04 2026: now handled by FONT_OPT
		# since imageJ V1.53c, option -b must be repalced by --headless
		#${PATHFIJI}/ImageJ-linux64 -b ./FijiMacro_${Random}2.txt ;;
		#${PATHFIJI}/ImageJ-linux64  --headless -batch FijiMacro_${Random}2.txt ;;
		"${FIJI}" --headless -batch "FijiMacro_${Random}2.txt" ;;

	"Darwin")
		#font="Helvetica"	# NdO Aug 04 2026: now handled by FONT_OPT
		#${PATHFIJI}/ImageJ-macosx  --headless -batch FijiMacro_${Random}2.txt ;;	
		"${FIJI}" --headless -batch "FijiMacro_${Random}2.txt" ;;

	*)
		echo "I can't figure out what is you opeating system. Please check"
		exit 0
		;;
esac						

echo
echo "Results ${PATHFILES}/${FILEOUTPUT}.tif "
echo " is store in ${PATHFILES}"
echo "font option = ${FONT_OPT}"

rm FijiMacro_${Random}.txt 
rm FijiMacro_${Random}2.txt 

if [ ! -f "${PATHFILES}/${FILEOUTPUT}.tif" ]
	then
		echo "ERROR: Fiji did not create ${PATHFILES}/${FILEOUTPUT}.tif"
		echo "       If ImageJ complains about the tif format, check that CreateColorFrame.py "
		echo "       writes uncompressed tif files (GTIFF_CREATE_OPTIONS = [])."
		exit 1
fi

# Draw the info in the legend
i=0
for line in $(cat ${TempFile})
	do
		array[$i]=$line
		let "i++"
		echo $i
	done

echo ${array[*]}
MinVal=${array[0]}
MaxVal=${array[1]}
PosLeft=${array[2]}
PosZero=${array[3]}
PosRight=${array[4]}

# NdO Aug 04 2026: keep the limits the colour bar was built with, next to the bar itself, so that
# TimeSeriesInfo_HP.sh V7.2+ (SCALEFROM=LEGEND) can scale its thumbnails on exactly the same range.
# CreateColorFrame.py writes array_legend[0..1] = min_ADR*100 and max_ADR*100, i.e. in cm/yr for the
# '[cm/year]' label of the bar, whereas the raster itself is in m/yr: divide by 100 so that the file
# is in the SAME unit as the tif, and do it BEFORE the truncation to 2 decimals further down.
# One line: "<min> <max>", in raster units.
LegendScale=$(echo "${DEFO//MSBAS_LINEAR_RATE/Legend}")
LegendScale="${LegendScale%_2.0.tif}"
LegendScale="${LegendScale%_2.0.tiff}"
LegendScale="${LegendScale%.bin_2.0}"
LegendScale="${LegendScale%.bin}"
LegendScale="${LegendScale}_scale.txt"
${PATHGNU}/gawk -v mn="${MinVal}" -v mx="${MaxVal}" \
	'BEGIN {printf "%.9g %.9g\n", mn/100, mx/100}' > ${PATHFILES}/${LegendScale}
echo "Colour bar limits kept in ${LegendScale}: $(cat ${PATHFILES}/${LegendScale}) (raster units)"

LegendTxtSize=$(GetParam LegendTxtSize)
MarkUp=$(GetParam MarkUp)
MarkDown=$(GetParam MarkDown)
LegValPosH=$(GetParam LegValPosH)
LegUnitPosH=$(GetParam LegUnitPosH)
LegTxtPosH=$(GetParam LegTxtPosH)
LegAdjZero=$(GetParam LegAdjZero)
LegAdjMin=$(GetParam LegAdjMin)
LegAdjMax=$(GetParam LegAdjMax)
LegAdjLOS=$(GetParam LegAdjLOS)
LegAdjUnit=$(GetParam LegAdjUnit)

${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -draw "fill black stroke black stroke-width 2 line ${PosLeft},${MarkUp} ${PosLeft},${MarkDown}" ${PATHFILES}/${FILEOUTPUT}.tif
${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -draw "fill black stroke black stroke-width 2 line ${PosZero},${MarkUp} ${PosZero},${MarkDown}" ${PATHFILES}/${FILEOUTPUT}.tif	
${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -draw "fill black stroke black stroke-width 2 line ${PosRight},${MarkUp} ${PosRight},${MarkDown}" ${PATHFILES}/${FILEOUTPUT}.tif

# Change the position to center the value under the vertical lines
# Define a poistion for the units information
# Scale the min - max value to 2 decimal
PosZero=$(echo "${PosZero}-${LegAdjZero}" |bc -l)
PosLeft=$(echo "${PosLeft}-${LegAdjMin}" |bc -l)
PosRight=$(echo "${PosRight}-${LegAdjMax}" |bc -l)
PosRight_bis=$(echo "${PosRight}-${LegAdjLOS}" |bc -l)
PosUnit=$(echo "${PosLeft}+${LegAdjUnit}" |bc -l)
MinVal=$(bc -l <<<"scale=2; ${MinVal}/1")  #Tronquer a 2 decimal et ajouter 15 a PosZero
MaxVal=$(bc -l <<<"scale=2; ${MaxVal}/1")  #Tronquer a 2 decimal et ajouter 15 a PosZero




${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosZero},${LegValPosH} '0'" ${PATHFILES}/${FILEOUTPUT}.tif	
${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosLeft},${LegValPosH} '${MinVal}'" ${PATHFILES}/${FILEOUTPUT}.tif	
${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosRight},${LegValPosH} '${MaxVal}'" ${PATHFILES}/${FILEOUTPUT}.tif	
${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosUnit},${LegUnitPosH} '[cm/year]'" ${PATHFILES}/${FILEOUTPUT}.tif

# Write just above the legend the information of the direction (Up, Down, East, West )
#Direction=$(echo ${FILEOUTPUT} | cut -d '_' -f 6)
case "${FILEOUTPUT}" in
	*_EW) Direction="EW" ;;
	*_UD) Direction="UD" ;;
	*_NS) Direction="NS" ;;
	*)    Direction="GEOM" ;;
esac

echo $Direction
if [ ${Direction} = 'EW' ]
	then
		${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosLeft},${LegTxtPosH} 'West '" ${PATHFILES}/${FILEOUTPUT}.tif
		${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosRight},${LegTxtPosH} 'East'" ${PATHFILES}/${FILEOUTPUT}.tif
elif [ ${Direction} = 'UD' ]
	then
		${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosLeft},${LegTxtPosH} 'Down '" ${PATHFILES}/${FILEOUTPUT}.tif
		${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosRight},${LegTxtPosH} 'Up'" ${PATHFILES}/${FILEOUTPUT}.tif
elif [ ${Direction} = 'NS' ]
	then
		${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosLeft},${LegTxtPosH} 'South '" ${PATHFILES}/${FILEOUTPUT}.tif
		${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosRight},${LegTxtPosH} 'North'" ${PATHFILES}/${FILEOUTPUT}.tif
elif [ ${Direction} = 'GEOM' ]
	then
		${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosLeft},${LegTxtPosH} 'Backward sat.'" ${PATHFILES}/${FILEOUTPUT}.tif
		${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} ${FONT_OPT} -draw "text ${PosRight_bis},${LegTxtPosH} 'Toward sat.'" ${PATHFILES}/${FILEOUTPUT}.tif
fi


rm ${TempFile}

Margin=$(GetParam Margin)
LegendWidth=$(GetParam LegendWidth)
LegendHeight=$(GetParam LegendHeight)
CropH=$((${LegendWidth}+${Margin}+${Margin}))
CropV=${LegendHeight}

${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -crop ${Crop_L}x${Crop_H}+${Crop_X}+${Crop_Y} ${PATHFILES}/${FILEOUTPUT}.jpg
# Crop the image and convert to jpg

#draw a black rectangle on the legend to make it invisble
${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.jpg -draw "fill black rectangle 0,0 ${CropH},${CropV}" ${PATHFILES}/${FILEOUTPUT}.jpg
#Keep the entire image in this case

echo $DEFO

#Creation of a jpg with only the legend (to be inserted in time series)
#Create the name of the file based on deformation file name
# The name MUST end up as Legend_XX.jpg (Legend_UD.jpg, Legend_EW.jpg, Legend_GEOM_UD.jpg...) 
# because TimeSeriesInfo_HP.sh rebuilds exactly that name from the AMPLI_COH_... jpg and 
# tests it against a list of expected names.
# Beware: with tif files the deformation file is now ..._2.0.tif and not ....bin_2.0
Legend=$(echo "${DEFO//MSBAS_LINEAR_RATE/Legend}")
Legend="${Legend%_2.0.tif}"		# tif files, e.g. MSBAS_LINEAR_RATE_UD.tif 
Legend="${Legend%_2.0.tiff}"	# idem with a .tiff extension 
Legend="${Legend%.bin_2.0}"		# envi files, for sake of compatibility 
Legend="${Legend%.bin}"			# in case the tif was named MSBAS_LINEAR_RATE_UD.bin.tif 
Legend="${Legend}.jpg"
echo "Legend file: ${Legend}"
# Extract the legend area from the composite file (will be use in "TimeSerieInfo.sh")
${IMCONVERT} ${PATHFILES}/${FILEOUTPUT}.tif -crop ${CropH}x${CropV}+0+0 ${PATHFILES}/${Legend}
rm ${PATHFILES}/${FILEOUTPUT}.tif

# Remove the temporary validity mask (the ..._2.0.tif is kept, as the ..._2.0 files of AmpDefo_map.sh) 
rm -f ${PATHFILEMSK}
# ...and uncomment the following line if you do not want to keep the deformation file with the color frame 
#rm -f ${PATHFILEDEFO}