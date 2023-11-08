#!/bin/bash
######################################################################################
# This script looks for links in each image dir (i.e. *.csl) in the current dir and remove them
#
# Must be launched in dir where all dirs are present. 
#
# Depedencies: 	- gnu find 
#
# V1.0 (Jul 24, 2023) 
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

