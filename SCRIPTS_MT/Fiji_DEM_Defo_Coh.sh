#!/bin/bash
# -----------------------------------------------------------------------------------------
# Script to make Fiji figure wrapping deformation on amplitude using coherence as a mask
#   based on envi files. Size of the images are taken form header file. 
#
# Parameters: - PATHDEMAMPLI 	: path and name of DEM amplitude file in Envi format (no flip no flop !)
#									It can be computed by running ReGeocode_AmpliSeries.sh 
#									after having renamed the externalSlantRangeDEM as REGEOC_externalSlantRangeDEM  
#									Then REGEOC_externalSlantRangeDEM must be transformed in HillShaded using QGIS
#										i.e. Rasters > Analysis > Hill Shade
#									Then saved as envi.hdr and transformed in float using byte2float.py
#										(do not forget to create a header file and change datatype as = 4) 
#             - PATHFILECOH 	: path and name of coherence file in Envi format 
#             - PATHFILEDEFO 	: path and name of deformation file in Envi format
#
# Hard coded:	- path to Fiji is defined in .bashrc but the name of the software may differ. See at the end of script
#
# Dependencies:	- Fiji (ImageJ). 
#				- gnu sed for more compatibility. 
#    
# New in Distro V 1.0:	- Based on Fiji_Ampli_Defo_Coh
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

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

# vvv ----- Hard coded lines to check --- vvv 
# See Fiji command and options at the end
# ^^^ ----- Hard coded lines to check -- ^^^ 

PATHDEMAMPLI=$1
PATHFILECOH=$2
PATHFILEDEFO=$3

# Get files names
AMPLI=`basename ${PATHDEMAMPLI}`
DEFO=`basename ${PATHFILEDEFO}`
COH=`basename ${PATHFILECOH}`

# Get image size; suppose there is a header file in ampli dir 
# Do not put the first letter of grep searched word in case of cap/no cap letters
WIDTH=`grep "amples" ${PATHFILEDEFO}.hdr | cut -d= -f2 | ${PATHGNU}/gsed s"/ //g"`
LENGTH=`grep "ines" ${PATHFILEDEFO}.hdr | cut -d= -f2 | ${PATHGNU}/gsed s"/ //g"`
echo
echo "Image size is ${WIDTH}  x  ${LENGTH}"
echo 

# path one level up 
#PATHFILES=`echo $(dirname  $(dirname ${PATHDEMAMPLI}))`
PATHFILES=`echo $(dirname  $(dirname ${PATHFILEDEFO}))`

# Open Coherence
echo "run('Raw...', 'open=${PATHFILECOH} width=${WIDTH} height=${LENGTH} little-endian');" > FijiMacroDefo2Amp.txt
echo "run('8-bit');" >> FijiMacroDefo2Amp.txt

# Open deformation 
echo "run('Raw...', 'open=${PATHFILEDEFO} width=${WIDTH} height=${LENGTH} little-endian');" >> FijiMacroDefo2Amp.txt
echo "run('8-bit');" >> FijiMacroDefo2Amp.txt

# Open amplitude
#echo "'open=${PATHDEMAMPLI}';" >> FijiMacroDefo2Amp.txt
echo "run('Raw...', 'open=${PATHDEMAMPLI} width=${WIDTH} height=${LENGTH} little-endian');" >> FijiMacroDefo2Amp.txt
#echo "//run('Brightness/Contrast...');" >> FijiMacroDefo2Amp.txt
#echo "run('Enhance Contrast', 'saturated=0.35');" >> FijiMacroDefo2Amp.txt
#echo "run('8-bit');" >> FijiMacroDefo2Amp.txt

echo "run('RGB Color');" >> FijiMacroDefo2Amp.txt

# Create Stack
echo "selectWindow('${AMPLI}');" >> FijiMacroDefo2Amp.txt
echo "run('HSB Stack');" >> FijiMacroDefo2Amp.txt

# Get defo in stack
echo "selectWindow('${DEFO}');" >> FijiMacroDefo2Amp.txt
echo "run('Select All');" >> FijiMacroDefo2Amp.txt
echo "run('Copy');" >> FijiMacroDefo2Amp.txt
echo "selectWindow('${AMPLI}');" >> FijiMacroDefo2Amp.txt
echo "setSlice(1);" >> FijiMacroDefo2Amp.txt
echo "run('Paste');" >> FijiMacroDefo2Amp.txt
# Get coh in stack
echo "selectWindow('${COH}');" >> FijiMacroDefo2Amp.txt
echo "run('Select All');" >> FijiMacroDefo2Amp.txt
echo "run('Copy');" >> FijiMacroDefo2Amp.txt
echo "selectWindow('${AMPLI}');" >> FijiMacroDefo2Amp.txt
echo "setSlice(2);" >> FijiMacroDefo2Amp.txt
echo "run('Paste');" >> FijiMacroDefo2Amp.txt

echo "run('RGB Color');" >> FijiMacroDefo2Amp.txt
echo "saveAs('Tiff', '${PATHFILES}/AMPLI_COH_${DEFO}.tif');" >> FijiMacroDefo2Amp.txt
echo "close();" >> FijiMacroDefo2Amp.txt

${PATHGNU}/gsed "s/'/\"/g" FijiMacroDefo2Amp.txt > FijiMacroDefo2Amp2.txt 

case ${OS} in 
	"Linux") 
		${PATHFIJI}/ImageJ-linux64  --headless -batch FijiMacroDefo2Amp2.txt ;;
	"Darwin")
		${PATHFIJI}/ImageJ-macosx  --headless -batch FijiMacroDefo2Amp2.txt ;;
	*)
		echo "I can't figure out what is you opeating system. Please check"
		exit 0
		;;
esac						

echo
echo "Results AMPLI_COH_${DEFO}.tif "
echo " is store in ${PATHFILES}"

rm FijiMacroDefo2Amp.txt FijiMacroDefo2Amp2.txt 

