#!/bin/bash
######################################################################################
# This script lists all modes in a SAT directory, and if requested, uses the
# List_CSL_Images_In_Modes.sh script to list all CSL images available for each mode
# and outputs the information in a file.
#
# Parameters: 
# - directory_full_path : Full path to the SAT directory (e.g., /path/to/SAT)
# - REGION : Region name to filter the directories (e.g., "Region1")
# - STARTDATE : Start date in format YYYYMMDD (optional)
# - ENDDATE : End date in format YYYYMMDD (optional)
#
# Dependencies:
# - find, grep, wc, basename, awk, sort
# - List_CSL_Images_In_Mode.sh
#
# Command to launch the script:
#   List_All_Modes_and_All_Images.sh <Directory_SAT_full_path> <REGION> <STARTDATE> <ENDDATE>
#
# Outputs:
# - Mode name, number of images per mode, first image date, last image date.
#
# New in Distro V 1.1 20250109:   - Outputs mode name, number of images per mode, plus total image count.
#   							  - Filters based on the provided start and end dates.
# New in Distro V 1.2 20250116:   - Adds Region Name and S1 satellite.
# New in Distro V 1.3 20250305:   - cosmetic ${}
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 
######################################################################################

PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Jan 16, 2025" 
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo " "


CURRENTDIR=$(pwd)
cd
source .bashrc
cd ${CURRENTDIR}

# Check input 
if [ -z "$1" ]; then
    echo "Usage: $0 <directory_Sat_full_path> <STARTDATE> <ENDDATE>"
    exit 1
fi

# Vérifier si l'argument optionnel "CSL" est fourni
csl_mode=true



# Directory path given as argument, add slash if needed
dir_sat_path="${1%/}"
last_dir_name=$(basename "${dir_sat_path%/}")
output_file="${last_dir_name}_mode_list.txt"

echo $dir_sat_path
echo $last_dir_name
echo $output_file

REGION="$2"
# Dates de filtre (START et END)
start_date="$3"
end_date="$4"

# Empty output if it exists already 
> "$output_file"
echo "# Directory: ${dir_sat_path} From ${start_date} to ${end_date}" >> "${output_file}"
echo "# Columns: Mode Name	Number of Images	First Image Date	Last Image Date" >> "${output_file}"

# Variables pour le total des images
total_images=0
modes=0


# List all mode directories in SAT directory:
for dir_mode in  "${dir_sat_path}/${REGION}_*/" ; do
	echo ${dir_mode}
    # Check if dir_mode is valid directory
    if [ -d "${dir_mode}" ]; then
        # Extract basename
        dir_name=$(basename "${dir_mode}")
        modes=$((modes + 1))
        
        echo " "
        echo "Listing CSL images in mode: ${dir_name}"
        num_images=0
        first_date="-"
        last_date="-"

        if [ "${csl_mode}" = true ]; then
            # Call script to list CSL images
            List_CSL_Images_In_Mode.sh "${dir_mode}"
            # Read images from the output file of List_CSL_Images_In_Mode.sh
            csl_list_file="${dir_name}_csl_list.txt"
            if [ -f "${csl_list_file}" ]; then
                # Filtrer les images selon les dates et extraire les dates des fichiers
                filtered_images=$("${PATHGNU}"/grep -E "[0-9]{8}" "${csl_list_file}" | "${PATHGNU}"/gawk -v start="${start_date}" -v end="${end_date}" '
                {
                    # Extraire la date yyyymmdd
                    match($0, /[0-9]{8}/, arr);
                    image_date = arr[0];
                    if ((!start || image_date >= start) && (!end || image_date <= end)) {
                        print image_date;
                    }
                }' | sort)
                
                # Compter les images filtrées
                num_images=$(echo "${filtered_images}" | wc -l)
                total_images=$((total_images + num_images))

                # Déterminer les premières et dernières dates si des images existent
                if [ "${num_images}" -gt 0 ]; then
                    first_date=$(echo "${filtered_images}" | head -n 1)
                    last_date=$(echo "${filtered_images}" | tail -n 1)
                fi
            fi
        fi

        # Add mode, image count, and dates to output file
        echo "${dir_name}	${num_images}	${first_date}	${last_date}" >> "${output_file}"
    fi
done


# Rechercher la première et la dernière date globales dans le fichier de sortie
first_date_global=$("${PATHGNU}"/gawk -F'\t' 'NR > 2 && $3 ~ /^[0-9]{8}$/ {print $3}' "${output_file}" | sort | head -n 1)
last_date_global=$("${PATHGNU}"/gawk -F'\t' 'NR > 2 && $4 ~ /^[0-9]{8}$/ {print $4}' "${output_file}" | sort | tail -n 1)


# Add total number of images to the output file
echo " " >> "${output_file}"
echo "Total images: ${total_images}" >> "${output_file}"
echo "Overall first date: ${first_date_global}" >> "${output_file}"
echo "Overall last date: ${last_date_global}" >> "${output_file}"

echo " "
echo "Total images: ${total_images}"
echo "Overall first date: ${first_date_global}"
echo "Overall last date: ${last_date_global}"

echo " "
echo "Number of modes processed: ${modes}"
echo "All modes done."