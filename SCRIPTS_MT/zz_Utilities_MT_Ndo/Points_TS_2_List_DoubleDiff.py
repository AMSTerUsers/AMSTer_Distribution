#!/opt/local/bin/python
#
# The script aims at creating a list coordinates and name for double difference TS computation. 
# It copes with the expected name when performing MSBAS.sh
#
# NOTE: if you do not want to combine every points, split your processing by points from sub-regions. 
#
# Paramerters: 	- the name of the Points_TS_YourRegion.txt file (e.g. cope with the 
#					expected name when performing MSBAS.sh)
# 			 	- the name of the List_DoubleDiff_EW_UD_YourRegion.txt file (e.g. cope with the 
#					expected name when performing MSBAS.sh)
#
# Dependency: 	- none
#
# New in Distro V 1.0  20241231: - setup 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import sys

# Input and output file paths
input_file = sys.argv[1]  # e.g. /Volumes/hp-1650-Data_Share1/Data_Points/Points_TS_TapgaonBolde.txt
output_file = sys.argv[2]  # e.g. /Volumes/hp-1650-Data_Share1/Data_Points/List_DoubleDiff_EW_UD_TapgaonBolde.txt

# Read the input file, skipping the header
pixels = []

with open(input_file, 'r') as infile:
    header = infile.readline()  # Read and discard the header
    for line in infile:
        parts = line.split()
        if len(parts) >= 3:  # Ensure there are enough columns (name, x, y)
            name = parts[0]
            x = parts[1]
            y = parts[2]
            pixels.append((name, x, y))

# Write the output file
with open(output_file, 'w') as outfile:
    for i in range(len(pixels)):
        name1, x1, y1 = pixels[i]
        for j in range(i + 1, len(pixels)):
            name2, x2, y2 = pixels[j]
            combined_name = f"_{name1}_{name2}"
            outfile.write(f"{x1} {y1} {x2} {y2} {combined_name}\n")

print(f"Output written to {output_file}")
