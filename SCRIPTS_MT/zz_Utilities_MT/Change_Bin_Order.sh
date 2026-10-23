#!/bin/bash
######################################################################################
# This script change binary order of all .bin file in pwd
#
# Parameters : - none
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- gdal
#
# V1.0 beta (2018) 
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



ls *.bin > List_bin.txt 

for BIN in `cat List_bin.txt `
do 
	gdalwarp -of ENVI ${BIN} ${BIN}.big.bin
done 

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL HDR ADDED AND FILES MOVED- HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


