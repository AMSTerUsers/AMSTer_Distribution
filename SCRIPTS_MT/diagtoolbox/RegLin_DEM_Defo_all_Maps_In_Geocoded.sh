#!/bin/bash
######################################################################################
# This script computes the linear regression between DEM and deformation for all maps in input dir
# DEM and DEFO must be of the same size.  
#
# Dependencies:	- python3.10 and modules below (see import)
#				- RegLin_DEM_Defo_modif.py 
#
# Parameters: DEM DEFODIR 
# launch command : RegLin_DEM_Defo_all_Maps_In_Geocoded.sh ${DEM} ${DEFODIR}

#
# V 1.0 (2022)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20250121: DS	- Append file name, coefficients and r2 to output file name output.txt in current dir
# 								DS	- Comment figure display and save as png
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2022 - could make better with more functions... when time.
######################################################################################



# Specifier le repertoire o chercher les fichiers *.deg
DEM="$1"
DIRECTORY="$2"


if [ "${DIRECTORY: -1}" != "/" ]; then
  DIRECTORY="$DIRECTORY/"
fi

# Vrifier si le rpertoire existe
if [ ! -d "$DIRECTORY" ]; then
  echo "Dir does not exist : $DIRECTORY"
  exit 1
else 
	echo "I will process all images in ${DIRECTORY}"  
fi

# write output file header line
echo "defo	slope	intercept	r2" > "output.txt"

# loop over all *.deg files in dir
for deg_file in "$DIRECTORY"/*deg; do
  if [ -f "$deg_file" ]; then
    echo "Processing File : $deg_file"
    RegLin_DEM_Defo.py  "$DEM" "$deg_file"
  else
    echo "No file *.deg  in dir ${DIRECTORY}."
  fi
done