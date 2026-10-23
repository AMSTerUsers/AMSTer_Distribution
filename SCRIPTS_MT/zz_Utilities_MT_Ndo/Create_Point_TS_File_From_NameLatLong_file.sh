#!/bin/bash
#
# The script aims at reading a list of Lat Long coordinates provided as a 3 col file 
# NAME	Lat	Long (tab separated)
# such as what is produced with Get_pix_Name_And_Coord_from_kml.py
# It outputs a file with the list of points that will be used to produce time series at MSBAS.sh
# step, that us a file with a one line header "name 		x 	y	radiusX raduisY" 
# followed by 5 columns with pix name, X, Y, radiusX and raduisY
# Note that we force here the radius to 3. Change if needed.  
#
# Paramerters: 	- file with list of "Name Lat Long" coordinates of pixels  
#				- a header file to convert Lat Long coordinates in X and Y 
#				- the name of the Points_TS_YourRegion.txt file (e.g. cope with the 
#					expected name when performing MSBAS.sh)
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependency: 	- UTM2EnviPosition.py
#
# New in Distro V 1.0  20241231: - setup 
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



# Input file containing tab-separated columns
PointList="$1"	# e.g. /Volumes/hp-D3602-Data_RAID5/MSBAS/_TapgaonBolde_S1_Auto_Max3Shortests/__FIGURES/SLIDE_LS_ref_points_TapgaonBolde_Frame.txt

# header file 
HeaderFile="$2" # e.g. "/Volumes/hp-D3602-Data_RAID5/MSBAS/_TapgaonBolde_S1_Auto_Max3Shortests/zz_UD_Auto_2_0.04_TapgaonBolde/MSBAS_20190130T122227_UD.bin.hdr"

# Output file to store the results
output_file="$3"	# e.g "/Volumes/hp-1650-Data_Share1/Data_Points/Points_TS_TapgaonBolde.txt"

echo "name 		x 	y	radiusX raduisY" > "$output_file"

# Read each line of the input file
while IFS=$'\t' read -r col1 col2 col3; do
    # Ensure there are no empty lines
    if [[ -n "$col1" && -n "$col2" && -n "$col3" ]]; then
        # Execute the script with the parameters
        Output=$(UTM2EnviPosition.py "$HeaderFile" "$col2" "$col3" "-LATLONG")  # e.g. "Pixel Position (Option -LATLONG): X=2535, Y=965"
        echo "$Output"
        X_value=$(echo "$Output" | ${PATHGNU}/sed -n 's/.*X=\([0-9]*\).*/\1/p')
        Y_value=$(echo "$Output" | ${PATHGNU}/sed -n 's/.*Y=\([0-9]*\).*/\1/p')
        echo "$col1 $X_value $Y_value 3 3" >> "$output_file"
    fi
done < "$PointList"
