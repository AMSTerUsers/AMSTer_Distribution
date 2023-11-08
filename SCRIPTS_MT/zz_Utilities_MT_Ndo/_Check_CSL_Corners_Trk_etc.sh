#!/bin/bash
######################################################################################
# This script checks the characteristics of all the *.csl images in directory and 
#  list them in a log file
#
# Parameters:	- None
#
#
# Dependencies:	- bc
#
#
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

printf "%-10s%-10s%-15s%-12s%-15s%-15s%-15s%-15s%-15s%-30s%-40s \n" "Date" "Time" "Mode" "LookDir" "LookAngl[deg]"  "Xsize[pix]" "Ysize[pix]" "Xsampl[m]" "Ysampl[m]" "Center/Ext-Lon " "Center/Ext-Lat" > List_Img_Characteristics.txt  

for IMGPATH in `ls -d *.csl`
do 
	echo " Search in ${IMGPATH}/Info/SLCImageInfo.txt..."

	SCENEDATE=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Acquisition date"`	 	# yyyymmdd
	SCENETIME=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Acquisition time"`	 	# hh:mm:ss

	SCENEMODE=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Heading direction"`
	ORBMODE=`echo ${SCENEMODE} | cut -d " " -f 1`											# Asc or Desc
	
	LOOKINGDIR=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Look direction"`		# Right or Left looking
	LOOKDIR=`echo ${LOOKINGDIR} | cut -d " " -f 1`											# Asc or Desc
	
	MEANANGLE=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Incidence angle at median slant range"`	# in deg
	MEANINCIDE=`echo ${MEANANGLE} | cut -c 1-6`	

	AZSAMP=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Azimuth sampling"`		# in m
	RGSAMP=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Range sampling"`			# in m
	AZSAMP=`echo ${AZSAMP} | cut -c 1-8`
	RGSAMP=`echo ${RGSAMP} | cut -c 1-8`

	RGSIZE=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Range dimension"`			# in pix 
	AZSIZE=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Azimuth dimension"`		# in pix


	SCENELOC=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "Scene location"`		# center - sometimes empty 
		CENTERLON=`echo ${SCENELOC} | cut -d: -f2 | ${PATHGNU}/grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tr '\n' ' ' | tr -d '[:space:]'; echo ""` # select Long as integer with sign
		CENTERLAT=`echo ${SCENELOC} | cut -d: -f3 | ${PATHGNU}/grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tr '\n' ' ' | tr -d '[:space:]'; echo ""` # select Lat as integer with sign

 	if [ "${CENTERLON}" = "" ]
 		then 
 			MINX=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "(0;0) Easting"`		# center - sometimes empty 
 			MAXX=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "(maxRange;0) Easting"`		# center - sometimes empty 
 			MINY=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "(0;0) Northing"`		# center - sometimes empty 
 			MAXY=`updateParameterFile ./${IMGPATH}/Info/SLCImageInfo.txt "(0;maxAzimuth) Northing"`		# center - sometimes empty 
 
 				CENTERLON="${MINX}-${MAXX}" # select Long as integer with sign
 				CENTERLAT="${MINY}-${MAXY}" # select Lat as integer with sign
 		
 	fi


	printf "%-10s%-10s%-15s%-12s%-15s%-15s%-15s%-15s%-15s%-30s%-40s \n"  "${SCENEDATE}" "${SCENETIME}" "${ORBMODE}" "${LOOKDIR}" "${MEANINCIDE}" "${RGSIZE}" "${AZSIZE}" "${AZSAMP}" "${RGSAMP}" "${CENTERLON}" "${CENTERLAT}" >> List_Img_Characteristics.txt  

done 