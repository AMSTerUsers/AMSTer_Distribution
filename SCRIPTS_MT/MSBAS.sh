#!/bin/bash
######################################################################################
# This script runs the (m)sbas, store results in sub dir and creates figs. 
# Beware, if choosing msbasv10, remember that it expects tif defo files. If files are 
# provided as envi format, they will be translated into tif automatically.  
#
# Parameters : - String PARAMNAME used to add to dir names where results will be stored. 
#                  This can help to remember eg some processing configs.
#			   - path and name of file containing the list of pixels (as COL RAW RADIUS) 
#				   for which one wants to output time series.
#			   - if a last param is given as --msbasvi (where i = version nr), then takes 
#					that one (if exist); if no, it takes the highest version of msbas available 
#
# ALL PARAMETERS ARE OPTIONAL BUT COMMENT IS MANDATORY IF ONE USE THE PIX LIST OUTPUT OR FORCE MSBAS VERSION      
#
# Dependencies:	- a header.txt file (built with build_header_msbas_criteria.sh)
#				- gnu sed and awk for more compatibility. 
#				- msbas, msbasv2 or msbasv3 
#    			- cpxfiddle is usefull though not mandatory. This is part of Doris package (TU Delft) available here :
#        			    http://doris.tudelft.nl/Doris_download.html. 
#				- script : 
#					+ Add_hdr_Files(_Less_Ras).sh 
#					+ Plot_All_LOS_ts_inDir.sh if run sbas
#					+ Plot_All_EW_UP_ts_inDir.sh if run msbas
#					+ Envi2ColorKmz.sh
#			    - seq
#				- Envi2msbastif.sh (which need GDAL python utils gdal_calc.py (in AMSTer venv) and gdalinfo)
#
# New in Distro V 1.0:	- Based on developpement version 2.1 and Beta V1.5
#				V 1.1:  - keep log of msbas processing 
# New in Distro V 2.0:	- create rasters within script Add_hdr_Files.sh
#						- better test if TS dirs are empty before deleting
# New in Distro V 2.1:	- do not create raster for all the deformation map. If need it, replace 
#							Add_hdr_Files_Less_Ras.sh with Add_hdr_Files.sh below
# New in Distro V 2.2:	- accounts for usage with msbasv4, i.e. that requires additional info in header files 
# New in Distro V 2.3:	- check header.txt if it exist and ensure compatibility with msbas version
# New in Distro V 3.0:	- if last param = --msbasvi (where i = version nr), then takes that one (if exist); if no 
#						  3rd param, takes the highest version of msbas available 
# New in Distro V 3.1:	- search for msbas version was missing in case of 2 param
#						- and an exit for test was left in the script...
# New in Distro V 3.2:	- search for msbas version was missing in case of 0 param
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20240109:	- When launched with only 1 param, it was not able to find the last version of msbas
#								- improve check empty dir at the end
# New in Distro V 4.2 20260113:	- error in removing NS dir if empty  
# New in Distro V 4.3 20260129:	- remove velocity maps in zz_ results dir in order to ensure 
#								  having the most recent maps in insets in TS plots using tags
# New in Distro V 4.4 20260409:	- ensures that PARAMNAME always starts with a _
# New in Distro V 5.0 20260730:	- also for msbasv10
#								- some cleaning 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 30, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

PARAMNAME=$1		# Comment for dir naming

# Function to search the last version of msbas 
	LastMsbasV()
		{
		#Loop v1-20; though v1 has no version nr
		CHECKMSBASV1=`which msbas | wc -l`
		if [ ${CHECKMSBASV1} -gt 0 ] ; then MSBAS="msbas" ; fi 
	
		for i in $(seq 2 20) 
			do 
				CHECKMSBASV[${i}]=`which msbasv${i} | wc -l`	
				if [ ${CHECKMSBASV[${i}]} -gt 0 ] 
					then 
						MSBAS="msbasv${i}" 
				fi 
		done
		}

# Function to search if data are tif or envi
detect_format() {
    _dir="$1"
    _ntif=$(find "$_dir" -maxdepth 1 -type f \( -iname '*.tif' -o -iname '*.tiff' \) 2>/dev/null | wc -l | tr -d '[:space:]')
    _nhdr=0
    # count only real ENVI headers (first non-empty line must be "ENVI")
    for _h in $(find "$_dir" -maxdepth 1 -type f -iname '*.hdr' 2>/dev/null); do
        if awk 'NF {print; exit}' "$_h" | tr -d '\r' | grep -qi '^ENVI'; then
            _nhdr=$((_nhdr + 1))
        fi
    done

    if   [ "$_ntif" -gt 0 ] && [ "$_nhdr" -eq 0 ]; then echo "TIFF" ; FORMAT="tif"
    elif [ "$_nhdr" -gt 0 ] && [ "$_ntif" -eq 0 ]; then echo "ENVI" ; FORMAT="envi"
    elif [ "$_nhdr" -gt 0 ] && [ "$_ntif" -gt 0 ]; then echo "MIXED (tif=$_ntif, envi=$_nhdr)" ; FORMAT="envi_and_tif"
    else echo "UNKNOWN (no tif, no ENVI hdr)" ; FORMAT="unknown"
    fi
}
	
# assign parameters
if [ $# -eq 2 ] ; then 
	# If one of the parameters contains the string --msbasv, which would mean that you want to use a given version of msbas
	if [[ "${@#--msbasv}" = "$@" ]]
		then
			echo "2nd param seems to be the pix list."
			PIXFILELIST="$2"	# path and filename for list of pixels (COL RAW RADIUS) for which one wants to output time series
			LastMsbasV
		else
			echo "Request specific msbas version $@."
			MSBAS=`echo $@ | cut -d - -f3`
			# Check if exist
			CHECKMSBAS=`which ${MSBAS} | wc -l`
			if [ ${CHECKMSBAS} -eq 0 ] 
				then 
					echo "Though it does not exist. Let's take the most recent version then..."
					LastMsbasV
			fi 
	fi
fi

if [ $# -eq 3 ] ; then 
	if [[ "$2" != *"--msbasv"* ]];
		then
			echo "2nd param seems to be the pix list."
			PIXFILELIST="$2"
			
			echo "and 3rd must be the msbas version"
			MSBAS=`echo $3 | cut -d - -f3`
			# Check if exist
			CHECKMSBAS=`which ${MSBAS} | wc -l`
			if [ ${CHECKMSBAS} -eq 0 ] 
				then 
					echo "Though it does not exist. Let's take the most recent version then..."
					LastMsbasV
			fi 			 
		else
			echo "2nd param seems to be the msbas version"
			MSBAS=`echo $2 | cut -d - -f3`
			# Check if exist
			CHECKMSBAS=`which ${MSBAS} | wc -l`
			if [ ${CHECKMSBAS} -eq 0 ] 
				then 
					echo "Though it does not exist. Let's take the most recent version then..."
					LastMsbasV
			fi 			 
			echo "and 3rd param seems to be the pix list."
			PIXFILELIST="$3"
	fi
fi

if [ $# -eq 0 ] || [ $# -eq 1 ] ; then 
	LastMsbasV
fi

if [[ $PARAMNAME != _* ]]; then
  COMMENT="_$PARAMNAME"
fi

echo
echo "Comment is: ${PARAMNAME}"
echo "msbas is: ${MSBAS}"
echo "pixlist is: ${PIXFILELIST}"

if [ ! -f header_original.txt ] ; then cp header.txt header_original.txt ; fi

if [ "${PIXFILELIST}" == "" ] ; then 
		echo "No pixel list provided. Will run without pixel time series."
		echo "  If you want to output time series for given pixels, also add a Comment for dir naming. See script."
	else 
		${PATHGNU}/gsed -i "s%I_FLAG = 0%I_FLAG = 2, ${PIXFILELIST}%" header.txt
fi

LOG_FILE=_MSBAS_log.txt

echo "MSBAS processing started on :" > ${LOG_FILE}
date >> ${LOG_FILE}
echo ""  >> ${LOG_FILE}


# Functions to ensure that header.txt is indeed in the form expected by the msbas version
headerv4to3 ()
{
	# Transform header.txt for msbasv4 in the form or msbasv3 or lower
	
	# ensure that header.txt does not contain the string "V_FLAG=0"
	if [ `${PATHGNU}/grep "V_FLAG" header.txt | wc -l` -gt 0 ] ; then 
		echo "header.txt seems formated for msbas v4; remove V_FLAG "
		${PATHGNU}/gsed -i '/V_FLAG/d' header.txt	# remove line with V_FLAG
	fi
	
	# ensure  that header.txt contains the string SET = ACQTIM, AVGHEAD, AVGINCID, MODEi.txt
	# search all lines in header.txt that contains the string SET and 7 words. If any, remove 0,
	while IFS= read -r line 
	do 
		if [ `echo $line | ${PATHGNU}/grep "SET" | wc -w` -eq 7 ] 
			then 
				NEWLINE=`echo "${line}" | ${PATHGNU}/gsed "s/SET = 0,/SET = /"` 
				${PATHGNU}/gsed -i "s/$line/${NEWLINE}/" header.txt 
		fi 
	done < header.txt	
}

headerv3to4 ()
{
	# Transform header.txt for msbasv3 or lower in the form or msbasv4
	
	# ensure that header.txt contains the string "V_FLAG=0"; if not, add it after I_FLAG line
	if [ `${PATHGNU}/grep "V_FLAG" header.txt | wc -l` -eq 0 ] ; then 
		echo "header.txt seems formated for msbas v < 4; add V_FLAG = 0 after line with I_FLAG"
		${PATHGNU}/gsed -i '/.*I_FLAG.*/a V_FLAG = 0 '${PATH_VARIABLES_IF_ANY}'\/WATCHOUTFORSLASHES' header.txt
	fi
	# ensure  that header.txt contains the string SET = 0, ACQTIME, AVGHEAD, AVGINCID, MODEi.txt
	# search all lines in header.txt that contains the string SET and 6 words. If any, add a 0,
	while IFS= read -r line 
	do 
		if [ `echo $line | ${PATHGNU}/grep "SET" | wc -w` -eq 6 ] 
			then 
				NEWLINE=`echo "${line}" | ${PATHGNU}/gsed "s/SET =/SET = 0,/"` 
				${PATHGNU}/gsed -i "s/$line/${NEWLINE}/" header.txt 
		fi 
	done < header.txt
}

headerv3to10 ()
{
	# Transform header.txt for msbasv3 or lower in the form or msbasv4

	# ensure that header.txt contains the string "D_FLAG=0"; if not, add it after I_FLAG line
	if [ `${PATHGNU}/grep "D_FLAG" header.txt | wc -l` -eq 0 ] ; then 
		echo "header.txt seems formated for msbas v < 4; add D_FLAG = 0 after line with I_FLAG"
		${PATHGNU}/gsed -i '/.*I_FLAG.*/a D_FLAG = 0 '${PATH_VARIABLES_IF_ANY}'\/WATCHOUTFORSLASHES' header.txt
	fi
	
	# ensure that header.txt contains the string "V_FLAG=0"; if not, add it after I_FLAG line
	if [ `${PATHGNU}/grep "V_FLAG" header.txt | wc -l` -eq 0 ] ; then 
		echo "header.txt seems formated for msbas v < 4; add V_FLAG = 0 after line with I_FLAG"
		${PATHGNU}/gsed -i '/.*I_FLAG.*/a V_FLAG = 0 '${PATH_VARIABLES_IF_ANY}'\/WATCHOUTFORSLASHES' header.txt
	fi
	# ensure  that header.txt contains the string SET = 0, ACQTIME, AVGHEAD, AVGINCID, MODEi.txt
	# search all lines in header.txt that contains the string SET and 6 words. If any, add a 0,
	while IFS= read -r line 
	do 
		if [ `echo $line | ${PATHGNU}/grep "SET" | wc -w` -eq 6 ] 
			then 
				NEWLINE=`echo "${line}" | ${PATHGNU}/gsed "s/SET =/SET = 0,/"` 
				${PATHGNU}/gsed -i "s/$line/${NEWLINE}/" header.txt 
		fi 
	done < header.txt
}

# run (m)sbas
case ${MSBAS} in 
	msbas)
		echo "run msbas V1"
		headerv4to3
		;;
	msbasv2)
		echo "run msbas V2"
		headerv4to3
		;;
	msbasv3)
		echo "run msbas V3"
		headerv4to3
		;;
	msbasv4)
		echo "run msbas V4"
		headerv3to4
		;;
	msbasv1*)
		echo "run msbas =< V10"
		echo " // BEWARE: mvsbas v10 invert by pixel and hence is way much slower than v4 !"
		headerv3to10
		;;
esac

# Launch inversion
##################

# If msbasv10, ensure that all data sets (but the DEM gradients if any) are in tif format
if [ "${MSBAS}" == "msbasv10" ] 
	then
		
		[ -f "header.txt" ] || { echo "ERROR: no header.txt in $PWD" >&2; exit 1; }

		while IFS= read -r line; do
		    line=$(printf '%s' "$line" | tr -d '\r')				# read line
		    		
		    # last comma-separated field = file with list of defo maps for mode i
		    listfile=$(printf '%s\n' "$line" | awk -F',' \
		        '{f=$NF; gsub(/^[[:space:]]+|[[:space:]]+$/,"",f); print f}')
		    [ -n "$listfile" ] || continue
		
		    if [ ! -f "$listfile" ]; then
		        echo "SET -> $listfile : MISSING list file"
		        continue
		    fi
		
		    # first field of first non-empty line should be the path to defo maps 
		    first=$(awk 'NF {print $1; exit}' "$listfile" | tr -d '\r')
		    if [ -z "$first" ]; then
		        echo "SET -> $listfile : empty list file"
		        continue
		    fi
		
		    if [ -d "$first" ]; then
		        defoModeDir="$first"
		    else
		        defoModeDir=$(dirname "$first")
		    fi
		
		    if [ ! -d "$defoModeDir" ]; then
		        echo "SET -> $listfile : data dir not found ($defoModeDir)"
		        continue
		    fi
		
		    echo "SET -> $listfile | dir: $defoModeDir | format: $(detect_format "$defoModeDir")"
		    
			case "${FORMAT}" in
				tif)	
					echo " // Defo maps are already in tif. Fine for msbasv10" ;;
				envi)	
					echo " // Defo maps are in envi. Need to be transformed in tif for msbasv10"
					mv "${defoModeDir}" "${defoModeDir}_envi" 
					Envi2msbastif.sh "${defoModeDir}_envi" "${defoModeDir}" 
					;;
				envi_and_tif*)	
					echo " // Defo maps are in envi and tif ??. Please check"
					exit
					;;
				unknown*)			
					echo " // Defo maps are in unknown format ??. Please check" 
					exit
					;;
			esac	
			unset FORMAT	
		done < <(${PATHGNU}/grep -E '^[[:space:]]*SET[[:space:]]*=' "header.txt")	# read "SET =" lines in header.txt
fi

${MSBAS} header.txt

echo "MSBAS processing stopped on :" >> ${LOG_FILE}
date >> ${LOG_FILE}
echo ""  >> ${LOG_FILE}

Add_hdr_Files_Less_Ras.sh "${PARAMNAME}" 	"--${MSBAS}"	# sort files in dir - must be version > 4.0 to cope with msbasv10

# delete unecessary TS dir
 if [ "$#" -eq 1 ] ; then 
	if [ -d "zz_LOS_TS${PARAMNAME}" ] && [ "$(ls -A zz_LOS_TS${PARAMNAME})" ]; then
			echo "zz_LOS_TS${PARAMNAME} is not Empty. Keep it."
		else
			echo "zz_LOS_TS${PARAMNAME} does not exist or is Empty. Remove it if appropriate."
			rm -Rf zz_LOS_TS${PARAMNAME} 2>/dev/null
	fi

	if [ -d "zz_UD_EW_TS${PARAMNAME}" ] && [ "$(ls -A zz_UD_EW_TS${PARAMNAME})" ]; then
			 echo "zz_UD_EW_TS${PARAMNAME} is not Empty. Keep it."
		else
			echo "zz_UD_EW_TS${PARAMNAME} does not exist or is Empty. Remove it if appropriate."
			rm -Rf zz_UD_EW_TS${PARAMNAME} 2>/dev/null
	fi
 
 	if [ -d "zz_UD_EW_NS_TS${PARAMNAME}" ] && [ "$(ls -A zz_UD_EW_NS_TS${PARAMNAME})" ]; then
			echo "zz_UD_EW_NS_TS${PARAMNAME} is not Empty. Keep it."
		else
			echo "zz_UD_EW_NS_TS${PARAMNAME} does not exist or is Empty. Remove it if appropriate."
			rm -Rf zz_UD_EW_NS_TS${PARAMNAME} 2>/dev/null
	fi
	
 	#	rm -Rf zz_LOS_TS${PARAMNAME} zz_UD_EW_TS${PARAMNAME}
 fi


# Clean possible former velocity maps in results to ensure having most recent maps in insets for TS plots
	# Find all zz_* directories without _TS_ in their name
	find . -maxdepth 1 -type d -name 'zz_*' ! -name '*_TS_*' | while read -r dir; do
	    images_dir="${dir}/_images"
	    if [ -d "${images_dir}" ]; then
	        echo "Cleaning former velocity maps in ${images_dir} in order to ensure having the updated tags in TS plots"
	        # Remove all files except .png, .tif, .jpg, .txt
	        find "${images_dir}" -maxdepth 1 -type f ! -name '*.png' ! -name '*.tif' ! -name '*.jpg' ! -name '*.txt' -exec rm -v {} \;
	    fi
	done


echo "(m)sbas processed (version ${MSBAS}), files moved to resp. dir and date(Time).txt files created" 

echo "MSBAS files moved to resp. dir and date(Time).txt files created" >> ${LOG_FILE}
echo "End of MSBAS.sh with ${MSBAS} on:" >> ${LOG_FILE}
date >> ${LOG_FILE}

