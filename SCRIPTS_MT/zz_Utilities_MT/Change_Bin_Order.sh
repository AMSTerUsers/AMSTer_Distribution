#!/bin/bash
######################################################################################
# This script change binary order of all .bin file in pwd
#
# Parameters : - none
#
# Dependencies:	- gdal
#
# V1.0 beta (2018) 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)

# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, S. Samsonov v 1.0 2018/11/15 -                         
######################################################################################
echo
PRG=`basename "$0"`
VER="v2.0 AMSTer utilities"
AUT="Nicolas d'Oreye, (c)2016-18, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

ls *.bin > List_bin.txt 

for BIN in `cat List_bin.txt `
do 
	gdalwarp -of ENVI ${BIN} ${BIN}.big.bin
done 

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL HDR ADDED AND FILES MOVED- HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


