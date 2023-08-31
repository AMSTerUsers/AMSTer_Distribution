#!/bin/bash
# -----------------------------------------------------------------------------------------
# Script to make RGB figure combining 2 amplitude maps and a coherence file using Fiji 
#   based on envi files. Size of the images are taken form header file. Useful to track
#   changes occuring between images such as flooding, lava flows emplacments etc...
#
# Parameters: - PATHAMP1 	: path and name of amplitude file 1 in Envi format (no flip nor flop !)
#									It required a hdr file with amplitude to get size image. 
#			  - PATHAMP2 	: path and name of amplitude file 2 in Envi format (no flip nor flop !)
#             - PATHFILECOH 	: path and name of coherence file in Envi format
#
# Hard coded:	- path to Fiji is defined in .bashrc but the name of the software may differ. See at the end of script
#
# Dependencies:	- Fiji (ImageJ). (!!! /etc/ImageMagick-6/policy.xml --> increase value to 8GiB at line <policy domain="resource" name="disk" value="1GiB"/>)
#				- gnu sed for more compatibility. 
#  
# 
# New in Distro V 1.0:	- Based on AmpDefo_map.sh V1.4.2
# New in Distro V 1.1:	- 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------


# vvv ----- Hard coded lines to check --- vvv 
source ${HOME}/.bashrc
# See Fiji command and options at the end
# ^^^ ----- Hard coded lines to check -- ^^^ 

PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, Maxime Jaspard (c)2016-2022, Last modified on Jan 20, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo


PATHAMP1=$1			# may differ from coh file
PATHAMP2=$2			# may differ from coh file
PATHFILECOH=$3		# may differ from amp files ; results will be in coh dir


# path where results will be stored
PATHFILES=$(dirname $(dirname ${PATHAMP1}))


# Get files names
AMP1=`basename ${PATHAMP1}`
AMP2=`basename ${PATHAMP2}`
COH=`basename ${PATHFILECOH}`

DATE1=`echo  ${AMP1} | ${PATHGNU}/grep -Eo "[0-9]{8}"  | head -1 ` # Suppose date of ampli is written as 8 cahracters date in first occurrence in file name
DATE2=`echo  ${AMP2} | ${PATHGNU}/grep -Eo "[0-9]{8}"  | head -1 ` # Suppose date of ampli is written as 8 cahracters date in first occurrence in file name

FILEOUTPUT=Ampl_${DATE1}_${DATE2}_Coh

# Get image size; suppose there is a header file in ampli dir 
# Do not put the first letter of ${PATHGNU}/grep searched word in case of cap/no cap letters
WIDTH=`grep "amples" ${PATHAMP1}.hdr | cut -d= -f2 | ${PATHGNU}/gsed s"/ //g"`
LENGTH=`grep "ines" ${PATHAMP1}.hdr | cut -d= -f2 | ${PATHGNU}/gsed s"/ //g"`
echo
echo "Image size is ${WIDTH}  x  ${LENGTH}"
echo 

#Create the associated hdr file for future utilisation (Binary file must be combine with hdr)
#cp ${PATHFILECOH}.hdr ${PATHFILES}/${FILEOUTPUT}.hdr 

Random=$(echo ${RANDOM:0:3})
echo "" > FijiMacro_${Random}.txt 

# Open Coherence
echo "run('Raw...', 'open=${PATHFILECOH} image=[32-bit Real] width=${WIDTH} height=${LENGTH} little-endian');" >> FijiMacro_${Random}.txt
echo "run('8-bit');" >> FijiMacro_${Random}.txt

# Open amplitude 1
echo "run('Raw...', 'open=${PATHAMP1} image=[32-bit Real] width=${WIDTH} height=${LENGTH} little-endian');" >> FijiMacro_${Random}.txt
#echo "//run('Brightness/Contrast...');" >> FijiMacro_${Random}.txt
echo "run('Enhance Contrast', 'saturated=0.35');" >> FijiMacro_${Random}.txt
echo "run('8-bit');" >> FijiMacro_${Random}.txt
echo "run('RGB Color');" >> FijiMacro_${Random}.txt

# Open amplitude 2
echo "run('Raw...', 'open=${PATHAMP2} image=[32-bit Real] width=${WIDTH} height=${LENGTH} little-endian');" >> FijiMacro_${Random}.txt
#echo "//run('Brightness/Contrast...');" >> FijiMacro_${Random}.txt
echo "run('Enhance Contrast', 'saturated=0.35');" >> FijiMacro_${Random}.txt
echo "run('8-bit');" >> FijiMacro_${Random}.txt
echo "run('RGB Color');" >> FijiMacro_${Random}.txt

# Create Stack
echo "selectWindow('${AMP1}');" >> FijiMacro_${Random}.txt
echo "run('HSB Stack');" >> FijiMacro_${Random}.txt

# Get amp2 in stack
echo "selectWindow('${AMP2}');" >> FijiMacro_${Random}.txt
echo "run('Select All');" >> FijiMacro_${Random}.txt
echo "run('Copy');" >> FijiMacro_${Random}.txt
echo "selectWindow('${AMP1}');" >> FijiMacro_${Random}.txt
echo "setSlice(1);" >> FijiMacro_${Random}.txt
echo "run('Paste');" >> FijiMacro_${Random}.txt

# Get coh in stack
echo "selectWindow('${COH}');" >> FijiMacro_${Random}.txt
echo "run('Select All');" >> FijiMacro_${Random}.txt
echo "run('Copy');" >> FijiMacro_${Random}.txt
echo "selectWindow('${AMP1}');" >> FijiMacro_${Random}.txt
echo "setSlice(2);" >> FijiMacro_${Random}.txt
echo "run('Paste');" >> FijiMacro_${Random}.txt

echo "run('RGB Color');" >> FijiMacro_${Random}.txt
echo "saveAs('Tiff', '${PATHFILES}/${FILEOUTPUT}.tif');" >> FijiMacro_${Random}.txt
echo "close();" >> FijiMacro_${Random}.txt



${PATHGNU}/gsed "s/'/\"/g" FijiMacro_${Random}.txt > FijiMacro_${Random}2.txt 



case ${OS} in 
	"Linux") 
		export DISPLAY=:10
		# since imageJ V1.53c, option -b must be repalced by --headless
		#${PATHFIJI}/ImageJ-linux64 -b ./FijiMacro_${Random}2.txt ;;
		${PATHFIJI}/ImageJ-linux64  --headless -batch FijiMacro_${Random}2.txt ;;
	"Darwin")
		${PATHFIJI}/ImageJ-macosx  --headless -batch FijiMacro_${Random}2.txt ;;
	*)
		echo "I can't figure out what is you opeating system. Please check"
		exit 0
		;;
esac						

echo
echo "Results are in ${PATHFILES}/${FILEOUTPUT}.tif "

open  ${PATHFILES}/${FILEOUTPUT}.tif 

rm FijiMacro_${Random}.txt 
rm FijiMacro_${Random}2.txt 

