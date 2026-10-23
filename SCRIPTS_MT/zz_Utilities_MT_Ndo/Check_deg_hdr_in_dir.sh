#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at checking that all files ending with deg in the current dir has 
# another file ending with .hdr extension. It also checks that there is no hdr file without 
# deg file. 
#
# MUST BE LAUNCHED IN DIR WHERE DEG FILES ARE
#
# Parameters : - none
#
# Hard coded: none
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:
#	 - none
#
# New in Distro V 1.0 20240829:		- set up
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


# Check for missing .hdr files corresponding to each .deg file
for deg_file in *deg; do
    hdr_file="${deg_file}.hdr"
    if [[ ! -e "$hdr_file" ]]; then
        echo "Missing hdr file: $hdr_file"
    fi
done

# Check for orphan .hdr files without corresponding .deg files
for hdr_file in *.hdr; do
    deg_file="${hdr_file%.hdr}"
    if [[ ! -e "$deg_file" ]]; then
        echo "Orphan (without deg file): $hdr_file"
    fi
done

