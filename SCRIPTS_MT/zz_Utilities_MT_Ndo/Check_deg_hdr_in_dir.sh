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
# Dependencies:
#	 - none
#
# New in Distro V 1.0 20240829:		- set up
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 29, 2024"

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

