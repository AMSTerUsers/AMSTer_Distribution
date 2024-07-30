#!/bin/bash
# -----------------------------------------------------------------------------------------
# Script to make Fiji figure wrapping deformation on amplitude using coherence as a mask
#   based on envi files. Size of the images are taken form header file. 
#
# Parameters: - PATHFILEAMPLI 	: path and name of amplitude file in Envi format (no flip nor flop !)
#									It required a hdr file with amplitude to get size image. 
#             - PATHFILECOH 	: path and name of coherence file in Envi format
#             - PATHFILEDEFO 	: path and name of deformation file in Envi format
#			  - Argument 4      : AMPLI_COH_MSBAS_LINEAR_RATE_** (output file)
#
# Hard coded:	- path to Fiji is defined in .bashrc but the name of the software may differ. See at the end of script
#
# Dependencies:	- Fiji (ImageJ). (!!! /etc/ImageMagick-6/policy.xml --> increase value to 8GiB at line <policy domain="resource" name="disk" value="1GiB"/>)
#				- gnu sed for more compatibility. 
#				- python3.8 + Numpy + script: CreateColorFrame.py
#				- a parameter file ${PATHFILEDEFO})/TS_parameters.txt with crop size etc...(to be updated manually depending on target)
#  
#Action:
#- Extraction of width and length data from amplitude header file
#- Execute CreateColorFrame.py 
#- Copy header file for new version of deformation and amplitude binary file (_2.0).
#- Write the ImageJscript in a temporary file (>>FijiMacro_${Random}.txt) and execute 
#- This script will create the Amplitude average tif file and the 4 	AMPLI_COH_MSBAS_LINEAR_RATE_** (output file)
#- Extract the data from TempFile (from CreateColorFrame.py)
#- Draw on the colorframe a line and the value at lowest, zero and highest value. Position of certain value must be adapted to the region.
#- Crop the AMPLI_COH_MSBAS_LINEAR_RATE and amplitude file (both TIF file) to an appropriate zoom and convert them to JPEG. This must be adapted to the region.
#- Save the Legend in a separate file to use in Time Serie graphics.
# 
# New in Distro V 1.0:	- Based on developpement version and Beta V1.2
# New in Distro V 1.1:	- Remove path to python3.8 to avoid prblm when run from several computers
# New in Distro V 1.2:	- update Linux Fiji command line (M Jaspard)
# New in Distro V 1.3:	- update Linux call of imageJ since V1.53c, that required --headless -batch instead of -b
# New in Distro V 1.4:	- update Linux call of imageJ on linux OS, require finally -b instead of batch  
# New in Distro V 1.4.1:- Do not export variable "${DISPLAY} anymore before calling ImageJ. (Give some issue on dellrack)"  
# New in Distro V 1.4.2:- export variable "${DISPLAY} =:10 before ImageJ script(The only value that works with linux and macos server)"  
# New in Distro V 1.4.3:- update V number in script and cosmetic in header
# New in Distro V 1.5:  - update to python3 using only python command (without serial nr) for launching python 
# New in Distro V 1.6:  - remove call python to launch python script to keep that info from script itself 
# New in Distro V 2.0:  - Use Helevetica font with Mac and FreeSans with Linux because recent convert version does not know Helvetica anymore  
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20231213:	- Calculate IJAmpMin and IJAmpMax with "gdalinfo -stats" instead of hard coded value
# New in Distro V 4.2 20240221:	- Add sleep of 5 seconds after the call of 'CreateColorFrame.py' to ensure new files are well created
# New in Distro V 4.3 20240701:	- Replace 'LOS' by 'GEOM' at line 293 (elif [ ${Direction} = 'GEOM' ]) because direction info was not written anymore
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


# vvv ----- Hard coded lines to check --- vvv 
source ${HOME}/.bashrc
# See Fiji command and options at the end
# ^^^ ----- Hard coded lines to check -- ^^^ 

PRG=`basename "$0"`
VER="Distro V4.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, Maxime Jaspard (c)2016-2021, Last modified on Jul 1, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

PATHFILEAMPLI=$1
PATHFILECOH=$2
PATHFILEDEFO=$3
FILEOUTPUT=$4


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
# path one level up 
PATHFILES=$(dirname ${PATHFILEDEFO})



echo "Crop_X = ${Crop_X}"
echo "Crop_Y = ${Crop_Y}"
echo "Crop_L = ${Crop_L}"
echo "Crop_H = ${Crop_H}"
DEFO=`basename ${PATHFILEDEFO}`

# Get image size; suppose there is a header file in ampli dir 
# Do not put the first letter of grep searched word in case of cap/no cap letters
WIDTH=`grep "amples" ${PATHFILEAMPLI}.hdr | cut -d= -f2 | ${PATHGNU}/gsed s"/ //g"`
LENGTH=`grep "ines" ${PATHFILEAMPLI}.hdr | cut -d= -f2 | ${PATHGNU}/gsed s"/ //g"`
echo
echo "Image size is ${WIDTH}  x  ${LENGTH}"
echo 

# Call of Python script to add a color legend on images
# Need to extract folder script path to avoid absolute path
#W_Script_Path=${PATH_SCRIPTS}/SCRIPTS_MT		# !!! temporary !!!


# Declare 3 variable for Deformation min max and position of zero in the legend.
TempFile=${PATHFILES}/temp.txt
echo '' > ${TempFile}


#/opt/local/bin/python3.8 ${PATH_SCRIPTS}/SCRIPTS_MT/CreateColorFrame.py ${PATHFILEDEFO} ${PATHFILECOH} ${PATHFILEAMPLI} ${WIDTH} ${TempFile} ${ParamFile}     >> /dev/null 2>&1 
#python3.8 ${PATH_SCRIPTS}/SCRIPTS_MT/CreateColorFrame.py ${PATHFILEDEFO} ${PATHFILECOH} ${PATHFILEAMPLI} ${WIDTH} ${TempFile} ${ParamFile}     >> /dev/null 2>&1 
${PATH_SCRIPTS}/SCRIPTS_MT/CreateColorFrame.py ${PATHFILEDEFO} ${PATHFILECOH} ${PATHFILEAMPLI} ${WIDTH} ${TempFile} ${ParamFile}   # >> /dev/null 2>&1 
# Wait to ensure that new files are well created
echo "wait 5 seconds to ensure the file is ready"
sleep 5 
#Create the associated hdr file for future utilisation (Binary file must be combine with hdr)
cp ${PATHFILEAMPLI}.hdr ${PATHFILEAMPLI}_2.0.hdr 
cp ${PATHFILEDEFO}.hdr ${PATHFILEDEFO}_2.0.hdr 


PATHFILECOH=${PATHFILECOH}_2.0
echo $PATHFILECOH
PATHFILEDEFO=${PATHFILEDEFO}_2.0
echo $PATHFILEDEFO
PATHFILEAMPLI=${PATHFILEAMPLI}_2.0
echo $PATHFILEAMPLI

# Get files names
AMPLI=`basename ${PATHFILEAMPLI}`
DEFO=`basename ${PATHFILEDEFO}`
COH=`basename ${PATHFILECOH}`

# Calculation of MinMax value to clip the amplitude image  
IJAmpMean=$(gdalinfo -stats ${PATHFILEAMPLI} | grep Mean | cut -d ',' -f 3 | cut -d '=' -f 2)
IJAmpStddev=$(gdalinfo -stats ${PATHFILEAMPLI} | grep Mean | cut -d ',' -f 4 | cut -d '=' -f 2)
echo "IJAmpMean: ${IJAmpMean}"
echo "IJAmpStddev:  ${IJAmpStddev}"
IJAmpMin=$(echo "$IJAmpMean - (3 * $IJAmpStddev)" | bc -l)
IJAmpMax=$(echo "$IJAmpMean + (3 * $IJAmpStddev)" | bc -l)
IJAmpMin=$(echo ${IJAmpMin} | sed 's/^\./0\./'  | sed 's/^-\./-0\./')
IJAmpMax=$(echo ${IJAmpMax} | sed 's/^\./0\./'  | sed 's/^-\./-0\./')
echo "IJAmpMin:  ${IJAmpMin}  ---- IJAmpMax: ${IJAmpMax}"



Random=$(echo ${RANDOM:0:3})
echo "" > FijiMacro_${Random}.txt 

# Open Coherence
echo "run('Raw...', 'open=${PATHFILECOH} image=[32-bit Real] width=${WIDTH} height=${LENGTH} little-endian');" >> FijiMacro_${Random}.txt
echo "run('8-bit');" >> FijiMacro_${Random}.txt

# Open deformation 
echo "run('Raw...', 'open=${PATHFILEDEFO} image=[32-bit Real] width=${WIDTH} height=${LENGTH} little-endian');" >> FijiMacro_${Random}.txt
echo "run('8-bit');" >> FijiMacro_${Random}.txt

# Open amplitude
echo "run('Raw...', 'open=${PATHFILEAMPLI} image=[32-bit Real] width=${WIDTH} height=${LENGTH} little-endian');" >> FijiMacro_${Random}.txt
echo "//run('Brightness/Contrast...');" >> FijiMacro_${Random}.txt
#echo "run('Enhance Contrast', 'saturated=0.35');" >> FijiMacro_${Random}.txt
echo "setMinAndMax(${IJAmpMin},${IJAmpMax});" >> FijiMacro_${Random}.txt
echo "run('8-bit');" >> FijiMacro_${Random}.txt
echo "run('RGB Color');" >> FijiMacro_${Random}.txt

# Create Stack
echo "selectWindow('${AMPLI}');" >> FijiMacro_${Random}.txt
echo "run('HSB Stack');" >> FijiMacro_${Random}.txt

# Get defo in stack
echo "selectWindow('${DEFO}');" >> FijiMacro_${Random}.txt
echo "run('Select All');" >> FijiMacro_${Random}.txt
echo "run('Copy');" >> FijiMacro_${Random}.txt
echo "selectWindow('${AMPLI}');" >> FijiMacro_${Random}.txt
echo "setSlice(1);" >> FijiMacro_${Random}.txt
echo "run('Paste');" >> FijiMacro_${Random}.txt
# Get coh in stack
echo "selectWindow('${COH}');" >> FijiMacro_${Random}.txt
echo "run('Select All');" >> FijiMacro_${Random}.txt
echo "run('Copy');" >> FijiMacro_${Random}.txt
echo "selectWindow('${AMPLI}');" >> FijiMacro_${Random}.txt
echo "setSlice(2);" >> FijiMacro_${Random}.txt
echo "run('Paste');" >> FijiMacro_${Random}.txt

echo "run('RGB Color');" >> FijiMacro_${Random}.txt
echo "saveAs('Tiff', '${PATHFILES}/${FILEOUTPUT}.tif');" >> FijiMacro_${Random}.txt
echo "close();" >> FijiMacro_${Random}.txt



${PATHGNU}/gsed "s/'/\"/g" FijiMacro_${Random}.txt > FijiMacro_${Random}2.txt 


case ${OS} in 
	"Linux") 
		export DISPLAY=:10
		font="FreeSans"
		# since imageJ V1.53c, option -b must be repalced by --headless
		#${PATHFIJI}/ImageJ-linux64 -b ./FijiMacro_${Random}2.txt ;;
		${PATHFIJI}/ImageJ-linux64  --headless -batch FijiMacro_${Random}2.txt ;;

	"Darwin")
		font="Helvetica"
		${PATHFIJI}/ImageJ-macosx  --headless -batch FijiMacro_${Random}2.txt ;;	
	*)
		echo "I can't figure out what is you opeating system. Please check"
		exit 0
		;;
esac						

echo
echo "Results ${PATHFILES}/${FILEOUTPUT}.tif "
echo " is store in ${PATHFILES}"
echo "font = ${font}"

rm FijiMacro_${Random}.txt 
rm FijiMacro_${Random}2.txt 

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

convert ${PATHFILES}/${FILEOUTPUT}.tif -draw "fill black stroke black stroke-width 2 line ${PosLeft},${MarkUp} ${PosLeft},${MarkDown}" ${PATHFILES}/${FILEOUTPUT}.tif
convert ${PATHFILES}/${FILEOUTPUT}.tif -draw "fill black stroke black stroke-width 2 line ${PosZero},${MarkUp} ${PosZero},${MarkDown}" ${PATHFILES}/${FILEOUTPUT}.tif	
convert ${PATHFILES}/${FILEOUTPUT}.tif -draw "fill black stroke black stroke-width 2 line ${PosRight},${MarkUp} ${PosRight},${MarkDown}" ${PATHFILES}/${FILEOUTPUT}.tif

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




convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosZero},${LegValPosH} '0'" ${PATHFILES}/${FILEOUTPUT}.tif	
convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosLeft},${LegValPosH} '${MinVal}'" ${PATHFILES}/${FILEOUTPUT}.tif	
convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosRight},${LegValPosH} '${MaxVal}'" ${PATHFILES}/${FILEOUTPUT}.tif	
convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosUnit},${LegUnitPosH} '[cm/year]'" ${PATHFILES}/${FILEOUTPUT}.tif

# Write just above the legend the information of the direction (Up, Down, East, West )
Direction=$(echo ${FILEOUTPUT} | cut -d '_' -f 6)
echo $Direction
if [ ${Direction} = 'EW' ]
	then
		convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosLeft},${LegTxtPosH} 'West '" ${PATHFILES}/${FILEOUTPUT}.tif
		convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosRight},${LegTxtPosH} 'East'" ${PATHFILES}/${FILEOUTPUT}.tif
elif [ ${Direction} = 'UD' ]
	then
		convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosLeft},${LegTxtPosH} 'Down '" ${PATHFILES}/${FILEOUTPUT}.tif
		convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosRight},${LegTxtPosH} 'Up'" ${PATHFILES}/${FILEOUTPUT}.tif
elif [ ${Direction} = 'GEOM' ]
	then
		convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosLeft},${LegTxtPosH} 'Backward sat.'" ${PATHFILES}/${FILEOUTPUT}.tif
		convert ${PATHFILES}/${FILEOUTPUT}.tif -pointsize ${LegendTxtSize} -font ${font} -draw "text ${PosRight_bis},${LegTxtPosH} 'Toward sat.'" ${PATHFILES}/${FILEOUTPUT}.tif
fi


rm ${TempFile}

Margin=$(GetParam Margin)
LegendWidth=$(GetParam LegendWidth)
LegendHeight=$(GetParam LegendHeight)
CropH=$((${LegendWidth}+${Margin}+${Margin}))
CropV=${LegendHeight}

convert ${PATHFILES}/${FILEOUTPUT}.tif -crop ${Crop_L}x${Crop_H}+${Crop_X}+${Crop_Y} ${PATHFILES}/${FILEOUTPUT}.jpg
# Crop the image and convert to jpg

#draw a black rectangle on the legend to make it invisble
convert ${PATHFILES}/${FILEOUTPUT}.jpg -draw "fill black rectangle 0,0 ${CropH},${CropV}" ${PATHFILES}/${FILEOUTPUT}.jpg
#Keep the entire image in this case

echo $DEFO

#Creation of a jpg with only the legend (to be inserted in time series)
#Create the name of the file based on deformation file name
Legend=$(echo "${DEFO//MSBAS_LINEAR_RATE/Legend}")
Legend=$(echo "${Legend//.bin_2.0/.jpg}")
# Extract the legend area from the composite file (will be use in "TimeSerieInfo.sh")
convert ${PATHFILES}/${FILEOUTPUT}.tif -crop ${CropH}x${CropV}+0+0 ${PATHFILES}/${Legend}
rm ${PATHFILES}/${FILEOUTPUT}.tif
