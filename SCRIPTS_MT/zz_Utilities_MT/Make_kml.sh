#!/bin/bash
######################################################################################
# This script creates a kml based on a list of coordinates provided as input.
# Usage: Make_kml.sh "lon1 lat1,lon2 lat2,...,lonN latN" output.kml
#
# Parameters:	- list of pairs of longitudes and latitudes. 
#					Lat and Long are separated by a space.
#					Pairs are separated by a comas
#					The whole set of coordinates is between double quotes, eg.
# 					"-70.6898267839218 -36.90762895618818,-70.03362627002683 -36.89749957901811,-70.09693399654567 -36.05291395012518,-70.71831691721114 -36.06796170586554,-70.6898267839218 -36.90762895618818" 
#				- name of the output kml
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
#
# New in Distro V 2.0 202ymmdd:	- 
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




COORDS="$1"
OUTPUT="$2"


if [[ -z "$COORDS" || -z "$OUTPUT" ]]; then
  echo "Usage: $0 \"lon1 lat1,...,lonN latN\" output.kml"
  exit 1
fi

if [[ $COORDS != \"*\" ]]; then
    echo "List of coordinates must be wrapped between double quotes "
fi

# Split into individual coordinates and format into KML-style
#KML_COORDS=$(echo "$COORDS" | tr ',' '\n' | awk '{print $1 "," $2 ",0"}')
KML_COORDS=$(echo "$COORDS" | tr ',' '\n' | awk '{printf("%s,%s,0 ", $1, $2)}')

# Write the KML file
cat > "$OUTPUT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
	<name>Generated Polygon AMSTer</name>
	<Placemark>
		<name>Polygon</name>
		<Polygon>
			<outerBoundaryIs>
				<LinearRing>
					<coordinates>
						${KML_COORDS}
					</coordinates>
				</LinearRing>
			</outerBoundaryIs>
		</Polygon>
	</Placemark>
</Document>
</kml>
EOF

echo "KML written to $OUTPUT"
