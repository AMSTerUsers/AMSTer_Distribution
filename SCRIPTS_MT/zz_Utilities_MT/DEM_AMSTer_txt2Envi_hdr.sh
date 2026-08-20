#!/bin/bash
######################################################################################
# This script aims at changing a DEM from csl format to envi format.
# BEWARE: it does not change the line ordering (from mathematical to geographical order). 
#  	Instead, it changes the sign of the Latitude step, making the GIS software to read them 
#			in the apparent correct order. 
# The output DEM in Envi format remains in the directory and a .hdr header file with the
#  same name as the DEM is created in the directroy. 
#
# Parameters: - path to DEM.txt file, that is the DEM header in csl format.  
#
# Dependencies:	- updateParameterFile function from AMSTer Engine 
#
#
# New in Distro V 1.0 20251223: - creation
# New in Distro V 1.1 20260219: - rename current script from cslDEM2envi.sh into DEM_AMSTer_txt2Envi_hdr.sh 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2025, Last modified on Feb 19, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

INPUTDEMTXT="$1"		# path to DEM.txt in CSL format

if [[ "${INPUTDEMTXT}" == *.txt ]]; then
  OUTPUT="${INPUTDEMTXT%.txt}.hdr"
else
  echo "Input file MUST be the path to the DEM.txt header file, that is the DEM header file in CSL format"
  exit 1
fi

# function to extract Parameters
function GetParamFromTXT()
	{
	unset CRITERIA 
	local CRITERIA
	CRITERIA=$1

	unset KEY
	local KEY

	KEY=`echo ${CRITERIA} | tr ' ' _`
	updateParameterFile ${INPUTDEMTXT} ${KEY}
	}

# Get parameters values

DEM_PATH="$(GetParamFromTXT "Georeferenced DEM file path")"
SAMPLES="$(GetParamFromTXT "X (longitude) dimension [pixels]")"
LINES="$(GetParamFromTXT "Y (latitude) dimension [pixels]")"
LL_LON="$(GetParamFromTXT "Lower left corner longitude [dd]")"
LL_LAT="$(GetParamFromTXT "Lower left corner latitude [dd]")"
LON_STEP="$(GetParamFromTXT "Longitude sampling [dd]")"
LAT_STEP="$(GetParamFromTXT "Latitude sampling [dd]")"
GEOID_INFO="$(GetParamFromTXT "Height type")"

# Invert sign of latitude step
LAT_STEP_NEG=$(awk -v v="$LAT_STEP" 'BEGIN { printf "%.15f", -v }')

# Create .hdr file in same dir 
cat > "$OUTPUT" <<EOF
ENVI
File type = ENVI Standard
Description = {Generated from DEM ${DEM_PATH} 
with respect to height:${GEOID_INFO}
Geographic coordinates
Automatic conversion - BEWARE: mathematical order read with negative latitude step !}
Header offset = 0
Bands = 1
Data type = 4
byte order = 0
Samples = ${SAMPLES}
Lines = ${LINES}
Map info = {Geographic Lat/Lon, 1.0, 1.0, ${LL_LON}, ${LL_LAT}, ${LON_STEP}, ${LAT_STEP_NEG}, WGS84, units=Degrees}
Data ignore value = NAN
EOF

echo "ENVI header created : $OUTPUT"
