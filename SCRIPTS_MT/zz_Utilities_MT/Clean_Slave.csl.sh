#!/bin/bash
# This script aims at removing the interpolated slave images from processing dir. 
#    However, text files are kept in case some re-filtering or re-unwrapping is required
#
# The script must be launched in the SAR_MASSPROCESS/S1/MODE_TRK/SMCropXXX_SMXXXX
#
# Attention : processes will remove a lot of things. Use with A LOT of care. 
#
# Parameters are:
#       - 
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- 
#
# Hard coded:	- 
#
# New in Distro V 1.1:	20191019
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 



# Check that we are indeed in a SAR_MASSPROCESS/S1/MODE_TRK/SMCropXXX_SMXXXX


# Remove data
#for DIRS in `ls -d S1?_*_*_?_S1?_*_*_? 2> /dev/null`
for DIRS in `ls -d ????????_???????? 2> /dev/null`
	do
		#rm -f ${DIRS}/i12/InSARProducts/S1*.interpolated.csl/Data/SLCData.??
		rm -f ${DIRS}/i12/InSARProducts/*.interpolated.csl/Data/SLCData.??
		echo "delete ${DIRS}/i12/InSARProducts/*.interpolated.csl/Data/SLCData.??"
		
done
