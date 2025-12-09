#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at searching in the current directory (and subdirectories)
# for all the products (SLC, RESMAPLED, MASSPROCESSED) computed with a AMSTer Engine version
# before a given date (provided as a parameter) 
#
# Parameters : 	- date from which AMSTer Engine version must be searched for 
#			 	- type of products to search for:	CSL will search for image reading and DEM projection
#													COREG will search for coregistration on SM
#													PAIRS will search for processed pairs 
#													AMPLI will search for processed pairs used for SAR_SM/AMPLITUDES
#
# Dependencies:	- gawk, gfind, ggrep
#
# Hard coded:	- none
#
# MUST BE RUN IN DIR TO CHECK
#
#
# New in Distro V 1.0 20240821:	- set up
# New in Distro V 1.1 20250530:	- add option to check AMPLITUDES
#								- correct typo in file naming: Processing_Pair[s]_w_AMSTerEngine_V.txt 

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on May 30, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) "
echo " "

MASTERDATE=$1  # Date from which AMSTer Engine version must be searched for as YYYYMMDD
TYPE=$2

if [ $# -lt 2 ] ; then echo "Usage $0 DATE_BEFORE_WHICH_PRODUCTS_PROCESSED_WITH_AMSTER_VERSION_IS_SEARCHED_FOR(i.e. yyyymmdd) TYPE_OF_PRODUCTS(i.e. CSL, COREG or PAIRS)"; exit; fi


case "${TYPE}" in 
	"CSL")
			echo 
			echo "// Search for image reading:"
			echo "----------------------------"
			
			#${PATHGNU}/gfind . -type f -name "Read_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '
			${PATHGNU}/gfind . \
			    -type d \( -name "Data" -o -name "Headers" -o -name "BurstsLists.txt" -o -name "Info" \) -prune -o \
			    -type f -name "Read_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | \
			    ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '

			{
			    # Extract the filename and the matched line separately
			    split($0, parts, ":")
			    filepath = parts[1]
			    line = parts[3]
			   # print filepath
			   # print line 
			   # print
			
			   # Extract the directory path without the filename
			    n = split(filepath, path_parts, "/")
			    dirpath = ""
			    for (i = 1; i < n; i++) {
			        dirpath = dirpath path_parts[i] "/"
			    }
			
			
			    # Extract the date from the line
			    match(line, /[0-9]{8}/, arr)
			    file_date = arr[0]
			
			    # Compare the extracted date with the given date
			    if (file_date < given_date) {
			        #print filepath
			        printf(dirpath "	processed with version:	" file_date "\n")
			
			    }
			}'
			
			echo 
			echo "// Search for DEM projection:"
			echo "----------------------------"
			
			#${PATHGNU}/gfind . -type f -name "Projecting_DEM_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '
			${PATHGNU}/gfind . \
			    -type d \( -name "Data" -o -name "Headers" -o -name "BurstsLists.txt" -o -name "Info" \) -prune -o \
			    -type f -name "Projecting_DEM_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | \
			    ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '
			{
			    # Extract the filename and the matched line separately
			    split($0, parts, ":")
			    filepath = parts[1]
			    line = parts[3]
			   # print filepath
			   # print line 
			   # print
			
			   # Extract the directory path without the filename
			    n = split(filepath, path_parts, "/")
			    dirpath = ""
			    for (i = 1; i < n; i++) {
			        dirpath = dirpath path_parts[i] "/"
			    }
			
			
			    # Extract the date from the line
			    match(line, /[0-9]{8}/, arr)
			    file_date = arr[0]
			
			    # Compare the extracted date with the given date
			    if (file_date < given_date) {
			        #print filepath
			        printf(dirpath "	processed with version:	" file_date "\n")
			
			    }
			}'
	
		;;
	"COREG")
			echo 
			echo "// Search for coregistration:"
			echo "-----------------------------"
			
			#${PATHGNU}/gfind . -type f -name "Coreg_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '
			${PATHGNU}/gfind . \
			    -type d \( -name "i12" \) -prune -o \
			    -type f -name "Coreg_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | \
			    ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '

			{
			    # Extract the filename and the matched line separately
			    split($0, parts, ":")
			    filepath = parts[1]
			    line = parts[3]
			   # print filepath
			   # print line 
			   # print
			
			   # Extract the directory path without the filename
			    n = split(filepath, path_parts, "/")
			    dirpath = ""
			    for (i = 1; i < n; i++) {
			        dirpath = dirpath path_parts[i] "/"
			    }
			
			
			    # Extract the date from the line
			    match(line, /[0-9]{8}/, arr)
			    file_date = arr[0]
			
			    # Compare the extracted date with the given date
			    if (file_date < given_date) {
			        #print filepath
			        printf(dirpath "	processed with version:	" file_date "\n")
			
			    }
			}'
		;;
		
	"PAIRS")
			echo 
			echo "// Search for mass processing pairs:"
			echo "------------------------------------"

			# ${PATHGNU}/gfind . -type f -name "Processing_Pairs_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '

			${PATHGNU}/gfind . \
			    -type d \( -name "Geocoded" -o -name "GeocodedRasters" -o -name "i12" \) -prune -o \
			    -type f -name "Processing_Pair_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | \
			    ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '
			{
			    # Extract the filename and the matched line separately
			    split($0, parts, ":")
			    filepath = parts[1]
			    line = parts[3]
			   # print filepath
			   # print line 
			   # print
			
			   # Extract the directory path without the filename
			    n = split(filepath, path_parts, "/")
			    dirpath = ""
			    for (i = 1; i < n; i++) {
			        dirpath = dirpath path_parts[i] "/"
			    }
			
			
			    # Extract the date from the line
			    match(line, /[0-9]{8}/, arr)
			    file_date = arr[0]
			
			    # Compare the extracted date with the given date
			    if (file_date < given_date) {
			        #print filepath
			        printf(dirpath "	processed with version:	" file_date "\n")
			
			    }
			}'	
		;;
	"AMPLI")
			echo 
			echo "// Search for pairs used for AMPLITUES:"
			echo "---------------------------------------"

			${PATHGNU}/gfind . \
			    -type d \( -name "i12" -o -name "_AMPLI"  \) -prune -o \
			    -type f -name "Processing_Pair_w_*.txt" -exec ${PATHGNU}/ggrep -H "Last created AMSTer Engine source dir suggest " {} \; | \
			    ${PATHGNU}/gawk -v given_date="${MASTERDATE}" '
			{
			    # Extract the filename and the matched line separately
			    split($0, parts, ":")
			    filepath = parts[1]
			    line = parts[3]
			   # print filepath
			   # print line 
			   # print
			
			   # Extract the directory path without the filename
			    n = split(filepath, path_parts, "/")
			    dirpath = ""
			    for (i = 1; i < n; i++) {
			        dirpath = dirpath path_parts[i] "/"
			    }
			
			
			    # Extract the date from the line
			    match(line, /[0-9]{8}/, arr)
			    file_date = arr[0]
			
			    # Compare the extracted date with the given date
			    if (file_date < given_date) {
			        #print filepath
			        printf(dirpath "	processed with version:	" file_date "\n")
			
			    }
			}'	
		;;
		
	*)
			echo 
			echo "I can't figure out which type of products you want to search for. "
			echo "Enter as a second parameter, either CSL, COREG or PAIRS. "
			echo "Exiting..."
			exit	
		;;
		

esac

echo "// All search done in :"
pwd
echo "----------------------------"
echo "----------------------------"

