#!/bin/bash
######################################################################################
# This script use slope and intercept stored in results.csv created by Load_and_Plot_Output_DEMDefo
# to compute a model and remove it for each defomap in input dir
# It will create the output dir and launch Compute_and_Substract_Defo_Dem.py for each file in inputdir 
#
# Dependencies:	- python3.10 and modules below (see import)
#				- Compute_and_Substract_Defo_Dem.py
#				- mkdir 
#
# Parameters: - Directory where defomaps are strored (i.e. DefoInterpolx2Detrend)
#			  - DEM with same size as defomaps
# 			  - File results.csv created by Load_and_Plot_Output_DEMDefo.py
# launch command : Compute_and_Substract_Defo_Dem_All_In_Dir.sh ${DEM} ${DEFODIR} "${Processdir}/resultats.csv"
#
# New in Distro V 1.0 20250121: DS	- save all plots at location of input file
# New in Distro V 1.0 20250318: DS	- file naming and storage dir changes
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2022 - could make better with more functions... when time.
######################################################################################

# directory where *.deg files are stored (i.e.DefoInterpolx2Detrend)
directory="$2"
DEM="$1"
File_correl="$3"

if [ "${directory: -1}" != "/" ]; then
  directory="$directory/"
fi

# Check in input dir exists
if [ ! -d "$directory" ]; then
  echo "Directory does not exist : $directory"
  exit 1
fi

echo " Process all defo maps in ${directory} with coeficients stored in ${File_correl}"
echo "I also use DEM : ${DEM}"

# Create COR_Defo_Dem as output dir at same level as input dir
BASE_DIR=$(dirname "$directory")
DIRNAME=$(basename "$directory")
OUTPUT_DIR="${directory}_Cor_Dem"
OUTPUT_DIRPNG="${BASE_DIR}Rasters/${DIRNAME}_Cor_Dem"

mkdir -p ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIRPNG}

# check output dir existence
if [ -d "${OUTPUT_DIR}" ]; then
    echo "${OUTPUT_DIR} exists, I can store corrected defo maps here."
else
    echo "Failed to find output directory."
fi

# Process all deformation maps
for deg_file in "$directory"/*deg; do
  # VXrifier si le fichier existe (au cas ou il n'y a pas de *.deg)
  if [ -f "$deg_file" ]; then
    BPval=$(echo $deg_file | sed -E 's/.*Bp([-+]?[0-9]*\.?[0-9]+)[^0-9].*/\1/')
    echo "Processing File : $deg_file"   
	echo "BPval = ${BPval}m"
	echo " "

	Compute_and_Substract_Defo_Dem.py ${DEM} ${deg_file} ${File_correl} ${OUTPUT_DIR}
	
  else
    echo "No file *.deg in directory : ${directory}."
  fi
done
echo "moving png files to ${OUTPUT_DIRPNG}"
mv ${OUTPUT_DIR}/*.png ${OUTPUT_DIRPNG}/

echo "All Done"
echo " "
