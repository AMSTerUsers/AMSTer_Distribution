#!/bin/bash
######################################################################################
# This script will list all images with a *.csl extension that are located in a 
# NoCrop directory within a specified mode directory.
#
# Parameters: 
# - directory_full_path : Full path to the mode directory (e.g., /path/to/mode)
#
# Dependencies: 
# - find, grep (GNU versions)
#
# Launch command: 
#   List_CSL_Images_In_Modes <Directory_Mode_full_path>
#
# Outputs:
# - A list of .csl images found in the NoCrop directory. The list is saved to a file
#   named "<mode_directory_name>_csl_list.txt".
#
# New in Distro V 1.1 20250109:   - Added comment to display CSL images found.
# New in Distro V 1.2 20250124:   - Adapted the regular expression to find tracks with 2 or 3 digits in their names (e.g., S1A_01_20220101_A).
#
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Jan 24, 2025" 
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo " "


# Check input 
if [ -z "$1" ]; then
    echo "Usage: $0 <directory_mode_full_path>"
    exit 1
fi

# Directory path given as argument, add slash if needed
dir_path="${1%/}/"

# print dir_path :
echo "Processing : ${dir_path}"

# Check if dir_path is a valid directory
if [ ! -d "$dir_path" ]; then
    echo "Error : input path is not valid, Please check"    
    exit 1
fi

# Get mode name for output naming 
last_dir_name=$(basename "${dir_path%/}")

output_file="${last_dir_name}_csl_list.txt"

# Empty output if it exist already 
> "$output_file"

# Search for .csl sub dir in NoCrop directory.
# then write all names in output file
${PATHGNU}/find "${dir_path}NoCrop/" -type d -name "*.csl" | ${PATHGNU}/grep -E "/NoCrop/([0-9]{8}|S1[A-Z]_[0-9]{2,3}_[0-9]{8}_[A-Z])\.csl$" | while read -r file
do
    # keep only .csl dir name
    sub_dir=$(basename "$file")
    # display image name
#    echo "$sub_dir"
    # write image name in output file
    if ! ${PATHGNU}/grep -Fxq "$sub_dir" "$output_file"; then
        echo "$sub_dir" >> "$output_file"
    fi
done

if [ -f "$output_file" ] && [ ! -s "$output_file" ]; then
	echo "no images in mode ${dir_path}, I remove the empty output file"
	echo " "
	rm "$output_file"
	else
	echo "CSL image list recorded in $output_file"	
	imagescsl=$(wc -l <  "$output_file")
	#imagescsl=$((modes - 1))
	echo "Number of csl images : $imagescsl"

fi
