#!/bin/bash
######################################################################################
# This script remove all occurrence of a product (defined by date_date_Bp_Ha_Bt_Head...)
#   in Geocoded and GeocodedRasters. The criteria t osearch for the files to delete are
#   provided by a string such as: 
# 		S1_DRC_VVP_A_174-37.0deg_20190717_20191108_Bp-27.3m_HA518.9m_BT114days_Head102.1deg  
#
# Use with care. It will ask for comfirmation before deleting though (remove option -i if unwanted). 
#
# Must be launched in dir that contains Geocoded and GeocodedRasters
#
# N.d'Oreye, v 1.0 2019/06/26 	-    
# N.d'Oreye, v 1.1 2021/07/07 	- security for empty criteria...                  
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

CRITERIA=$1  #must be in the form of e.g. S1_DRC_VVP_A_174-37.0deg_20190717_20191108_Bp-27.3m_HA518.9m_BT114days_Head102.1deg
#TARGETDIR=/Volumes/hp-D3602-Data_RAID5/SAR_MASSPROCESS_2/CSK/Virunga_Desc/_Quarantained

if [ ${CRITERIA} == ""] ; then exit 0 ; fi

cd Geocoded
	echo "Search in Geocoded for files with "
	echo "    ${CRITERIA} "
	find . -type f -name "*${CRITERIA}*" -type f -exec rm -f {} \;
#	find ./* -type f -name "*${CRITERIA}*" -type f -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +

cd .. 

cd GeocodedRasters
	echo "Search in GeocodedRasters for files with "
	echo "    ${CRITERIA} "
	find . -type f -name "*${CRITERIA}*" -type f -exec rm -f {} \;
#	find ./* -type f -name "*${CRITERIA}*" -type f -exec sh -c 'mv "$@" "$0"' ${TARGETDIR}/	 {} +	

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CLEANED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


