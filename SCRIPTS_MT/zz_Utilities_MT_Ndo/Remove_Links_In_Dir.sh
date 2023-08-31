#!/bin/bash
######################################################################################
# This script looks for links in each image dir (i.e. *.csl) in the current dir and remove them
#
# Must be launched in dir where all dirs are present. 
#
# Depedencies: 	- gnu find 
#
# New in V1.1:	- 
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 24, 2023"
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

