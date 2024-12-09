#!/bin/bash
######################################################################################
# This scripts aims at checking in the pwd that there is no duplicate directories named
# *MAS*_*SLV* and *SLV*_*MAS*. 
# If it happens, it will only keep the pair where MAS is a date smaller that SLV and
#   move the other in a dir named _DUPLICATED_DIR_WRONG_ORDER 
#
# 
# New in Distro V 1.0 20241030:	- Setup   
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# search duplicated dir with inverted dates

# Declare an indexed array to hold directories and their corresponding date pairs
dirs=()
keys=()

mkdir -p _DUPLICATED_DIR_WRONG_ORDER

# Loop through all directories in the current directory

for dir in *; do
    # Check if the item is a directory
    [ -d "$dir" ] || continue

    # Extract dates from the directory name using regex
    if [[ "$dir" =~ ([0-9]{8})_.*_([0-9]{8}) ]]; then
        date1="${BASH_REMATCH[1]}"
        date2="${BASH_REMATCH[2]}"

        # Create a key that represents the date pair in sorted order
        if [[ "$date1" -gt "$date2" ]]; then
            key="$date1,$date2"  # date1 is the most recent
        else
            key="$date2,$date1"  # date2 is the most recent
        fi

        # Store the directory name and key
        dirs+=("$dir")
        keys+=("$key")
    fi
done

# Check for pairs with reverse dates and decide which to delete
for ((i = 0; i < ${#keys[@]}; i++)); do
    for ((j = i + 1; j < ${#keys[@]}; j++)); do
        if [[ "${keys[i]}" == "${keys[j]}" ]]; then
            # Same date pair found, get the directory names
 
 			# get dates from i
 			if [[ "${dirs[i]}" =~ ([0-9]{8}).*([0-9]{8}) ]]; then
			    date11="${BASH_REMATCH[1]}"
			    date12="${BASH_REMATCH[2]}"
			    echo "Found dir ${date11}_${date12}"  # Output: 20231030 20231101
			fi
 			# get dates from j
 			if [[ "${dirs[j]}" =~ ([0-9]{8}).*([0-9]{8}) ]]; then
			    date21="${BASH_REMATCH[1]}"
			    date22="${BASH_REMATCH[2]}"
			    echo "Found dir ${date21}_${date22}"  # Output: 20231030 20231101
			fi
 			
        	if [[ "${date11}" -gt "${date21}" ]]; then
            		echo " => move: ${dirs[i]} (most recent first) in _DUPLICATED_DIR_WRONG_ORDER"
            		mv "${dirs[i]}" ./_DUPLICATED_DIR_WRONG_ORDER/
        		else
            		echo " => move: ${dirs[j]} (most recent first) in _DUPLICATED_DIR_WRONG_ORDER"
            		mv "${dirs[j]}" ./_DUPLICATED_DIR_WRONG_ORDER/
        	fi
			echo ""
        fi
    done
done