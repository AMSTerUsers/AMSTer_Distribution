#!/bin/bash
######################################################################################
# This script convert a list of PointsTS coordinates in pixels to keep the same locations on a different grid
# 
#
# Parameters:	- X0,Y0,DX,DY are the corner coordinates and resolution of the original maps (found in MapInfo in the hdr file)
# 				- x0,y0,dX,dY are the corner coordinates and resolution of the target maps (found in MapInfo in the hdr file)
# 				- input file full path
# 				- output file full path

# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- gawk

# New in V1.0 20250401: - cosmetic
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


# Input Parameters
X0=$1
Y0=$2
DX=$3
DY=$4
x0=$5
y0=$6
dx=$7
dy=$8

inputfile=$9
outputfile=${10}

# parameter display
echo "X0: ${X0}"
echo "Y0: ${Y0}"
echo "DX: ${DX}"
echo "DY: ${DY}"
echo "x0: ${x0}"
echo "y0: ${y0}"
echo "dx: ${dx}"
echo "dy: ${dy}"
echo "Input file: ${inputfile}"
echo "Output file: ${outputfile}"

echo ""

# mk output dir if it does not exists already
outputdir=$(dirname "${outputfile}")
if [ ! -d "$outputdir" ]; then
  echo "Directory ${outputdir} does not exists yet, I will create it..."
  mkdir -p "$outputdir"
fi

# Traitement du fichier avec gawk
${PATHGNU}/gawk -v X0="$X0" -v Y0="$Y0" -v DX="$DX" -v DY="$DY" -v x0="$x0" -v y0="$y0" -v dx="$dx" -v dy="$dy" 'NR==1 { print $0; next } {
    col1 = int((($2 * DX) + (X0 - x0)) / dx)
    col2 = int((($3 * DY) - (Y0 - y0)) / dy)
    print $1, col1, col2, $4, $5
}' "${inputfile}" > "${outputfile}"

# Confirmation 
echo "Conversion done. Results in ${outputfile}"

# Afficher les 15 premieres lignes du fichier de sortie
head -15 "${outputfile}"
