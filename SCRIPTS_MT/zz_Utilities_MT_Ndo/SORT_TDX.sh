#!/bin/bash
######################################################################################
# This script aims at sorting out the mess in the TDX or TSX data... 
# It will read all the sub dir until finding amplitude files in COMMON_PREVIEW dir and copy it as index_dateTtime.tif in
# _Check_common_images dir to be created in the current dir. The list of path with index is also 
# stored in _Check_common_images. 
#
# It will do the same with composite images in PREVIEW of each of the Tandem image dir in order to check the Primary and Secondary image of TDX
# This will be strored in _Check_single_images with their lists
#
# If launched in TSX dir,  _Check_common_images will be empty
#
# It must be launched in the dir that contains all the subdirs where TDX or TSX data are.
#
# Parameters: - none
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in V D 1.0.1:	   - bash for Linux compatibility 
# New in Distro V 1.2:  - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
#						- zap gremlins 
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

if [ -d _Check_common_images ] 
	then 
		while true; do
				read -p "_Check_common_images and _Check_single_images dir exist. Do you want to everwrite them ? "  yn
				case $yn in
					[Yy]* ) 
						rm -Rf _Check_common_images
						rm -Rf _Check_single_images
						break ;;
					[Nn]* ) 
	   					echo "OK then rename them before relaunching the sctipt" 
	   					exit 1	
						break ;;
					* ) echo "Please answer yes or no.";;
				esac
			done
	else
		mkdir _Check_common_images
		mkdir _Check_single_images
fi


# Check the amplitudes in COMMON_PREVIEW
i=1
for filename in `find . -type f -name "*amplitude.tif"`
   do
	  echo "$i:	${filename}" >> _Check_common_images/List_tif.txt
	  #get the date. Supposed to be in name two levels above
	  UPPERLEVEL="$(dirname "$filename")"
	  AGAINUPPER="$(dirname "$UPPERLEVEL")"		
	  DIRWITHDATE=`basename ${AGAINUPPER}`
	  DATETIF=`echo "${DIRWITHDATE}" | ${PATHGNU}/grep -Eo "_[0-9]{8}T[0-9]{6}" | head -1` # select _date_date_ where date is 8 numbers
	  
	  cp ${filename} _Check_common_images/${i}_${DATETIF}.tif
	  i=`echo "${i} + 1" | bc -l`
done

# Check the composite in PREVIEW
i=1
for filename in `find . -type f -name "COMPOSITE*.tif"`
   do
	  echo "$i:	${filename}" >> _Check_single_images/List_tif.txt
	  #get the date. Supposed to be in name two levels above
	  UPPERLEVEL="$(dirname "$filename")"
	  AGAINUPPER="$(dirname "$UPPERLEVEL")"		
	  DIRWITHDATE=`basename ${AGAINUPPER}`
	  DATETIF=`echo "${DIRWITHDATE}" | ${PATHGNU}/grep -Eo "_[0-9]{8}T[0-9]{6}" | head -1` # select _date_date_ where date is 8 numbers
	  
	  cp ${filename} _Check_single_images/${i}_${DATETIF}.tif
	  i=`echo "${i} + 1" | bc -l`
done

