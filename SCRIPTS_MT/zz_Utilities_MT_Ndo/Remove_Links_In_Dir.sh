#!/bin/bash
######################################################################################
# This script looks for links in each image dir (i.e. *.csl) in the current dir and remove them
#
# Must be launched in dir where all dirs are present. 
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Depedencies: 	- gnu find 
#
# V1.0 (Jul 24, 2023) 
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


eval SOURCEDIR=$PWD

for DIRS in `ls -d *.csl`
	do 
		cd ${DIRS}
		$PATHGNU/find ./* -maxdepth 1 -type l -name "*.csl" -exec rm -f {} \;
		cd ..
	
done 

echo "+++++++++++++++++++++++++++++++++++++++++++++++"
echo " ALL LINKS REMOVED - HOPE IT WORKED"
echo "+++++++++++++++++++++++++++++++++++++++++++++++"

