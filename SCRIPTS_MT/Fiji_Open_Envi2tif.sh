#!/bin/bash
# -----------------------------------------------------------------------------------------
# Script to open Envi format file with Fiji and save in tif format. 
#      Size of the images are taken form header file. 
#
# Parameters: - PATHFILETOOPEN 	: path and name of image in Envi format
#									It required a hdr file with amplitude to get size image. 
#
# Hard coded:	- path to Fiji is defined in .bashrc but the name of the software may differ. See at the end of script
#
# Dependencies:	- Fiji (ImageJ). 
#				- gnu sed for more compatibility. 
#    
# New in Distro V 1.0:	- Based on developpement version and Beta V1.3
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 15, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

PATHFILETOOPEN=$1

# vvv ----- Hard coded lines to check --- vvv 
# See Fiji command and options at the end
# ^^^ ----- Hard coded lines to check -- ^^^ 

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

# Get files names
AMPLI=`basename ${PATHFILETOOPEN}`

# Get image size; suppose there is a header file in ampli dir 
# Do not put the first letter of grep searched word in case of cap/no cap letters
LENGTH=`grep "ines" ${PATHFILETOOPEN}.hdr | ${PATHGNU}/gsed s"/[^0-9]*//g"`
WIDTH=`grep "ampl" ${PATHFILETOOPEN}.hdr | ${PATHGNU}/gsed s"/[^0-9]*//g"`
echo 
echo "Image size is ${WIDTH} times  ${LENGTH}"
echo 

# path one level up 
PATHFILES=`echo $(dirname ${PATHFILETOOPEN})`

# Open file
echo "run('Raw...', 'open=${PATHFILETOOPEN} width=${WIDTH} height=${LENGTH} little-endian');" > FijiMacroOpen.txt
echo "run('8-bit');" >> FijiMacroOpen.txt

echo "saveAs('Tiff', '${PATHFILES}/${AMPLI}.tif');" >> FijiMacroOpen.txt
echo "close();" >> FijiMacroOpen.txt

${PATHGNU}/gsed "s/'/\"/g" FijiMacroOpen.txt > FijiMacroOpen2.txt 

case ${OS} in 
	"Linux") 
		${PATHFIJI}/ImageJ-linux64 --headless -batch FijiMacroOpen2.txt  ;;
	"Darwin")
		${PATHFIJI}/ImageJ-macosx --headless -batch FijiMacroOpen2.txt  ;;
	*)
		echo "I can't figure out what is you opeating system. Please check"
		exit 0
		;;
esac						

echo
echo "Results ${AMPLI}.tif "
echo " is store in ${PATHFILES}"

rm FijiMacroOpen.txt FijiMacroOpen2.txt 

