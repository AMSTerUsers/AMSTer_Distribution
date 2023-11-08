#!/bin/bash
######################################################################################
# This script merge the jpg into a gif movie
# using : convert -delay 20 *jpg movie.gif
#
# Parameters :	- SAT
#				- TRK
#				- REGION 
#
# Dependencies:	- convert 
# 
# New in Distro V 1.0:	- Based on developpement version 1.1 and Beta V1.0.2
# New in Distro V 1.1:	- ignore sigma0 for gif
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

SAT=$1
TRK=$2
REGION=$3

if [ $# -lt 3 ] ; then echo “Usage $0 SAT TRK REGION”; exit; fi

${PATHCONV}/convert -delay 20 *mod.fl*p.jpg _movie_${SAT}_${TRK}_${REGION}.gif #ignore sigma0 for gif

