#!/bin/bash
######################################################################################
# This script remove the data in the I12/InSARProducts/slaves.interpolated.csl in each 
#  pair dirs in a SAR_MASSPROCESS dir. It keeps however the dir structure and Info files
#  in case re-processing in required (only possible after insarProductsGeneration of course). 
#
# USE WITH A LOT OF CARE
#
# Parameters: - the dir where mass processed pairs are stored, e.g.
#				  e.g. /Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/DRC_VVP_D_21/SMNoCrop_SM_20151014_Zoom1_ML8
#
# V1.0: 20200106
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


MASSPROCESSDIRTOCLEAN=$1


if [ $# -lt 1 ] ; then echo “Usage $0 path_to_MSBAS/Site/MODEi”; exit; fi

if [ `echo ${MASSPROCESSDIRTOCLEAN} | ${PATHGNU}/grep "/SAR_MASSPROCESS/" | ${PATHGNU}/grep "/S1/" | wc -l` -ne 1 ] ; then 
	echo "Not in a S1/../SAR_MASSPROCESS dir. Are you sure you want to continue ? Remove test in script then..." 

	read -p "Continue (y/n)?" choice
	case "$choice" in 
	  y|Y ) echo "yes";;
	  n|N ) echo "no";;
	  * ) echo "invalid, please answer y or n";;
	esac	
fi  

cd ${MASSPROCESSDIRTOCLEAN}

FREESPACEBEFORE=`df --output='avail' $PWD | tail -n 1`
echo "Free space before cleaning: ${FREESPACEBEFORE}"

for d in $(find "$PWD" -maxdepth 1 -type d -name "S1*_*")
do
  SUBD=`echo $d/i12/InSARProducts/S1*.interpolated.csl`
  echo "Clean ${SUBD}/Data and /Headers"
  rm -Rf ${SUBD}/Data
  rm -Rf ${SUBD}/Headers
done 

FREESPACEAFTER=`df --output='avail' $PWD | tail -n 1`
FREESPACEAFTERTB=`df -H --output='avail' $PWD | tail -n 1`

GAIN=`echo "( ${FREESPACEAFTER} - ${FREESPACEBEFORE} ) / 1000000000 " | bc `

echo
echo "Free space before cleaning: ${FREESPACEBEFORE}"
echo "Free space after cleaning: ${FREESPACEAFTER}"
echo "${GAIN} Tb freed; ${FREESPACEAFTERTB} available"
echo "Note: on Mac OS X, sometimes the disk space is not updated for obscure reason... " 

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES COPIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++
