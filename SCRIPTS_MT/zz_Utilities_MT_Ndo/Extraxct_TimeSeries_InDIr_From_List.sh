#!/bin/bash
# The present script will extract, for each point from a list of Col(X) and Lines(Y) positions,   
# the time series of defo from all the defo maps in the present dir. It will read the first hdr
# file to extract the required informations about the images. 
#
# Time series will be stored in a specific sub dir in the directory containing the deformation
#	files and their hdr files, named by the name of the list of points' positions, the date and a random nr
#
# Parameters: 	- path to the directory with the deformation files, e.g.
#				  /3602/MSBAS/_YourPlace_Sat_Auto_xm_ydays/zz_EW_Auto_Order_Lambda_YourPlace  
#				- the list of coordinates to search for position in file
#
#
# Dependencies : - getLineThroughStack (if used with 4 param)
#
# New in Distro V 1.0 20250508:	- (Il n'y a pas de "oui mais")
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on May 8, 2025"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "


PATHTODATA=$1      		# path to the dir where deformation files and their hdr files are stored
						# e.g. /3602/MSBAS/_YourPlace_Sat_Auto_xm_ydays/zz_EW_Auto_Order_Lambda_YourPlace
PATHTOPOSITIONS=$2		# path to the list of points positions in Columns and Lines

LISTNAME=$(basename ${PATHTOPOSITIONS})


cd ${PATHTODATA}

# get the first non empty hdr file from PATHTODATA
HDR=$(find . -maxdepth 1 -type f -name "*.hdr" ! -size 0c | head -n 1)

if [ "${HDR}" == "" ] ; then echo "No .hdr file, exiting..." ; exit ; fi

# Create the dir where to store the results 
	TODAY=`date`
	MM=$(date +%m)
	DD=$(date +%d)
	YYYY=$(date +%Y)
	RNDM=`echo $(($RANDOM % 1000))`
	
	STORAGEDIR="${LISTNAME}_${YYYY}${MM}${DD}_${RNDM}"
	mkdir -p "${PATHTODATA}/${STORAGEDIR}"

# Move all possible existing timeLine*.txt files from PATHTODATA in TMP dir (they will be restored after)
	shopt -s nullglob
	files=(timeLine*.txt)
	if (( ${#files[@]} )); then
	    echo "Former timeLine*.txt files exist in ${PATHTODATA}; move them in TMP_timeLine dir. They will be restored after"
	    echo
	    mkdir -p TMP_timeLine
		mv -f ${PATHTODATA}/timeLine*.txt /${PATHTODATA}/TMP_timeLine/
	else
	    NOTMPDIR="NOTMPDIR"
	fi

# Create time series timeLine*.txt
	while read -r X Y
		do	
			echo "extract time series for point ${X} ${Y} in ${PATHTODATA}"
			getLineThroughStack ${PATHTODATA} ${X} ${Y} 
		
		done < ${PATHTOPOSITIONS}

# move all computed timeLine*.txt files in STORAGEDIR
	mv -f timeLine*.txt ${PATHTODATA}/${STORAGEDIR}/

# restore existing timeLine*.txt files in PATHTODATA (if any)
	if [ "${NOTMPDIR}" != "NOTMPDIR" ] ; then 
		echo 
	    echo "Restore timeLine*.txt files in ${PATHTODATA}..."
		mv -f ${PATHTODATA}/TMP_timeLine/timeLine*.txt ${PATHTODATA}
	    rm -Rf TMP_timeLine
	fi
	
echo " All done... "