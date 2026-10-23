#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at verifying that the results from the mass processing are successfully 
#     stored at the appropriate place. 
# It will read the list of pairs supposed to be processed, then 
#    - check if data are stored in each Geocoded/Modes
#    - check if each dir of processed pair is stored in corresponding SAR_MASSPROCESS dir
# It will output a series of text files with the status of each of these checks.  
# it will then check if Geocoded products exists but not the Pair dir
# It then offers to remove inconsistent products. Before any deletion, the exact path of each 
#    file or dir to be removed is displayed and a confirmation is asked (y/n/a(ll)/q(uit)).
#    Nothing outside of the SAR_MASSPROCESS dir is ever removed. 
#
# Parameters :      - file with the list of pairs supposed to be processed in the form of PRIMARY_SECONDARY dates (Table_...._NoBaselines.txt)
#					  or MASDATE	SLVDATE	BP	Bt (with or without header)
#                   - dir where Geocoded results are stored (eg. /.../SAR_MASSPROCESS/SAT/TRACK/CROP_SM_DATE_ZOOM_ML/Geocoded)
#					- optional: a date in the form YYYYMMDD: it will only check pairs with both Primary and Secondary dates >= that date  
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:
#    - gnu sed and awk for more compatibility. 
#    - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#	 - function RenameVolNameToVariable from __HardCodedLines.sh
#    - must be run in an interactive Terminal (confirmations are read from /dev/tty)
#
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.2.2
# 				V 1.1: 	- speed up the script by using find instead of ls
#						- speed up the script by running loop on modes in background
#						- speed up the script by reading pair files with read loop and assign directely mas and slv dates to param
# 				V 1.2: 	- do not list .txt in mode list
# 				V 1.3: 	- change ls with find to avoir too long argument error
# 				V 1.4: 	- Remove possible trailing / at the end of MASSPROCESSGEOCPATH taken as parameter 2 (would prevent to detect GeocodedRasters dir)
# 				V 1.5: 	- do notlist itself while searching empty pair dirs in MASSPROCESSPATH
# New in Distro V 1.6: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20240105:	- background sign & in for/do loop was at wrong place
#								- typo in error muting at diff operation
#								- test if DirPair_NotInMassProcess.txt exist before sorting to avoid error msg
#								- make it faster with one liners
# New in Distro V 2.2 20240507:	- compatible with tables in the form of 4 col (MAS SLV Bp Bt, with or without header)
#								- get the ${PAIRSFILE}_NoBaselines_${RNDM1}.txt  in _CheckResults instead of same dir as original (seti)
#								- do not create file PairFiles_NoBaselines.txt (i.e. MAS_SLV) but directly  PairFiles_NoBaselines_Sorted_NoUnderscore.txt (i.e. MAS SLV) 
#								- some cleaning and cosmetic; improve search for all modes 
#								- debug search for existing files in MODES
#								- debug removing pair dirs for S1, which are named with more than only the dates 
#								- debug isting of missing pair dirs 
# New in Distro V 2.3 20240508:	- offer the option to start the check from a given date provided as a 3rd param
# New in Distro V 2.4 20240527:	- more robust way to get MAS and SLV dates from PAIR dir before deleting stuffs
# New in Distro V 2.5 20241220:	- Do not verify pairs with images in Quarantained
# New in Distro V 2.6 20250417:	- Check that dates of Primary and Secondary images are not empty before deleting directories of files
#								- debug rm ${FIRSTPAIR}/i12/TextFiles/InSARParameters_StateVar.txt
#								- add quotes around some directories and files names for robustness and security 
# New in Distro V 2.7 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
# New in Distro V 2.8 20261023:	- Ask confirmation before any deletion, displaying the exact path of what will be removed 
#								  (y/n, a=all next ones of the same category, q=quit the category). 
#								  Deletion code gathered in functions AskYesNo, ListGeocProducts, ListPairDirs, 
#								  ConfirmAndRemove and RemovePairProducts. Refuse to delete outside of SAR_MASSPROCESS.
#								- debug removing empty dirs: was using dates of the last pair checked instead of the empty dir itself
#								- debug removing inverted pair dirs (SLV_MAS) and their geocoded products: 
#								  were searched only as MAS_SLV hence never found. Now searched in both orders. 
#								- debug empty mode detection: PairFiles_NoBaselines_Sorted.txt was not created anymore since V2.2 
#								  and Imgs_NotIn*.txt must be sorted before comparison
#								- debug PAIRSTOREMOVE.TXT (was tested as PAIRSTOREMOVE.txt) and only offer it when 
#								  no geocoded product exists at all
#								- only consider files (not dirs) when removing geocoded products; no more rm without argument
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.8 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 23, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 



# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
# needed for function RenameVolNameToVariable
# ^^^ ----- Hard coded lines to check -- ^^^ 

PAIRSFILE=$1					# file with the list of pairs supposed to be processed in the form of PRIMARY_SECONDARY dates
MASSPROCESSGEOCPATHTMP=$2		# dir where Geocoded results are stored (eg. /.../SAR_MASSPROCESS/SAT/TRACK/CROP_SM_DATE_ZOOM_ML/Geocoded)

if [ $# -lt 2 ] ; then echo "Usage $0 LIST_OF_PAIRS DIR_TO_GEOCODED"; exit; fi

# Remove possible trailing /
MASSPROCESSGEOCPATH=${MASSPROCESSGEOCPATHTMP%/} 

MASSPROCESSPATH=`echo ${MASSPROCESSGEOCPATH} | ${PATHGNU}/gsed "s%\/Geocoded%%" `

# MASSPROCESSPATH is also the safety boundary for any deletion; make sure it is a real dir
if [ "${MASSPROCESSPATH}" = "" ] || [ "${MASSPROCESSPATH}" = "${MASSPROCESSGEOCPATH}" ] || [ ! -d "${MASSPROCESSPATH}" ] ; then 
	echo "Can't figure out the SAR_MASSPROCESS dir from ${MASSPROCESSGEOCPATH} (must be /.../Geocoded). Exit."
	exit 1
fi

# Compatible Pairs (in the form of "date_date"; also for S1):
 if ${PATHGNU}/grep -q Delay "${PAIRSFILE}"
 	then
   		# If PAIRFILE = table from Prepa_MSBAS.sh, it contains the string "Delay", then
		# Remove header and extract only the pairs in ${PAIRFILE}
		cat ${PAIRSFILE} | tail -n+3 | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${PAIRSFILE}_NoBaselines_${RNDM1}.txt 
	else
		# Check if the first line has 4 columns
		first_line=$(head -n 1 "${PAIRSFILE}")
		if [[ $(echo "$first_line" | awk -F '[[:space:]]+' '{print NF}') -ne 4 ]]; then
			# First line does not have 4 columns, i.e. it must be something like MAS_SLV
			# If PAIRFILE = list of images to play, it contains already only the dates
			cp ${PAIRSFILE} ${PAIRSFILE}_NoBaselines_${RNDM1}.txt
		else
			# First line has 4 columns, i.e. it must be in the form of MAS SLV Bp BT, thought without header
			cat ${PAIRSFILE} | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${PAIRSFILE}_NoBaselines_${RNDM1}.txt 
		fi
 fi

mkdir -p ${MASSPROCESSPATH}/_CheckResults
cd ${MASSPROCESSPATH}/_CheckResults

PAIRSFILENAME=$(basename ${PAIRSFILE})
mv -f ${PAIRSFILE}_NoBaselines_${RNDM1}.txt ${MASSPROCESSPATH}/_CheckResults/${PAIRSFILENAME}_NoBaselines_${RNDM1}.txt
PAIRSFILE=${MASSPROCESSPATH}/_CheckResults/${PAIRSFILENAME}_NoBaselines_${RNDM1}.txt

# If third param (=from date), then restrict pairs to check from a given date 
if [ $# -eq 3 ] 
	then 
		DATEFROM=$3				# a date in the form YYYYMMDD: it will only check pairs with both Primary and Secondary dates >= that date  
		echo "Restrict list of pairs to check to pairs with both Priamry and Secondary images after ${DATEFROM}"
		${PATHGNU}/gawk -v given_date="${DATEFROM}" -F '_' '$1 >= given_date && $2 >= given_date {print}' ${PAIRSFILE} > ${PAIRSFILE}_From${DATEFROM}.txt
		PAIRSFILE=${PAIRSFILE}_From${DATEFROM}.txt	
fi

# For ease of check : sort PAIRSFILE
sort -u ${PAIRSFILE} > ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt
${PATHGNU}/gsed "s/_/ /g" ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt > ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt
rm -f ${PAIRSFILE} 

# some stuff for later
find "${MASSPROCESSGEOCPATH}" -mindepth 1 -maxdepth 1 -type d -not -path "*/Ampli" -exec basename {} \; > MODES.TXT # List all modes except Ampli because we know that must exist anyway
NROFALLMODE=`wc -l < MODES.TXT`

# Some functions
################

function SpeakOut()
	{
	unset MESSAGE 
	local MESSAGE
	MESSAGE=$1
	# Check OS
	OS=`uname -a | cut -d " " -f 1 `

	case ${OS} in 
		"Linux") 
			espeak "${MESSAGE}" ;;
		"Darwin")
			say "${MESSAGE}" 	;;
		*)
			echo "${MESSAGE}" 	;;
	esac			
	}
	
# Function to test existence of file in dir
function CheckGeocProduct()
	{
	unset MODE  
	MODE=$1 # e.g Coh
	#if [ `find ${MASSPROCESSGEOCPATH}/${MODE}/*${MASDATE}*_*${SLVDATE}* -type f 2>/dev/null | wc -l` -lt 1 ] 
	#	then 
	#		if [ `find ${MASSPROCESSGEOCPATH}/${MODE}/*${SLVDATE}*_*${MASDATE}* -type f 2>/dev/null | wc -l` -lt 1 ] 
	#			then 
	#				echo "Geocoded file ${MASDATE}_${SLVDATE} does not exist in ${MODE}"
	#				echo "${MASDATE}_${SLVDATE}" >> Imgs_NotIn${MODE}.txt 
	#		fi
	#fi	

	if [ `${PATHGNU}/find "${MASSPROCESSGEOCPATH}/${MODE}" -maxdepth 1 -type f -type f \( -name "*${MASDATE}_*${SLVDATE}*" -o -name "*${SLVDATE}_${MASDATE}*" \) 2>/dev/null | wc -l` -lt 1 ] 
		then
	    	echo "	Geocoded file ${MASDATE}_${SLVDATE} does not exist in ${MODE}"
	    	echo "${MASDATE}_${SLVDATE}" >> "Imgs_NotIn${MODE}.txt"
	   # For debugging
	   # else 
	   # 	echo "	Geocoded file ${MASDATE}_${SLVDATE} exists in ${MODE}"
	fi

	}
	
function GetParamFromFile()
	{
	unset CRITERIA 
	local CRITERIA
	CRITERIA=$1

	unset KEY

	local KEY

	KEY=`echo ${CRITERIA} | tr ' ' _`
	
	updateParameterFile ${FIRSTPAIRPARAMFILE}_StateVar.txt ${KEY}
	}	
	

function RemoveQuarantined()
	{
	FILETOCLN=$1
	if [ -f ${FILETOCLN} ] && [ -s ${FILETOCLN} ]
		then 
			mkdir -p ${MASSPROCESSPATH}/_CheckResults/Quarantined
			${PATHGNU}/ggrep -F -f ${MASSPROCESSPATH}/_CheckResults/_Quarantined_ImagesDates.txt -v ${FILETOCLN} > ${FILETOCLN}_Without_Quarantined_Img.txt
			${PATHGNU}/ggrep -F -f ${MASSPROCESSPATH}/_CheckResults/_Quarantined_ImagesDates.txt ${FILETOCLN} > ${FILETOCLN}_Quarantined.txt
			
			mv -f ${FILETOCLN}_Without_Quarantined_Img.txt ${FILETOCLN}
			mv -f ${MASSPROCESSPATH}/_CheckResults/*_Quarantined.txt ${MASSPROCESSPATH}/_CheckResults/Quarantined/
			
			if [ -f ${FILETOCLN} ] && [ ! -s ${FILETOCLN} ]
				then 
					echo " ${FILETOCLN} is empty; remove it" 
					rm  ${FILETOCLN}	
			fi
	fi
	}

# Ask a yes/no question. Returns 0 for yes, 1 for no.
function AskYesNo()
	{
	local QUESTION=$1
	local yn
	while true; do
		read -p "${QUESTION} [y/n] " yn < /dev/tty
		case ${yn} in
			[Yy]* ) return 0 ;;
			[Nn]* ) return 1 ;;
			* ) echo "Please answer yes or no." ;;
		esac
	done
	}

# List the exact path of the geocoded files and rasters of pair MASDATE SLVDATE (given as $1 $2), 
#   in all modes and in both orders (MAS_SLV or SLV_MAS), as done when checking the products.
function ListGeocProducts()
	{
	local MAS=$1
	local SLV=$2
	local MODE
	local DIR
	for MODE in `cat -s MODES.TXT`
	do
		for DIR in "${MASSPROCESSGEOCPATH}/${MODE}" "${MASSPROCESSGEOCPATH}Rasters/${MODE}"
		do
			if [ -d "${DIR}" ] ; then 
				find "${DIR}" -type f \( -name "*${MAS}*_*${SLV}*" -o -name "*${SLV}*_*${MAS}*" \)
			fi
		done
	done
	}

# List the exact path of the processing pair dir(s) of pair MASDATE SLVDATE (given as $1 $2) 
#   in MASSPROCESS, in both orders (MAS_SLV or SLV_MAS).
function ListPairDirs()
	{
	local MAS=$1
	local SLV=$2
	find "${MASSPROCESSPATH}" -mindepth 1 -maxdepth 1 -type d \( -name "*${MAS}*_*${SLV}*" -o -name "*${SLV}*_*${MAS}*" \)
	}

# Display the exact paths listed in file $1 (one per line) and ask for confirmation before deleting them:
#   y = delete them ; n = skip them ; a = delete them and all the next ones of the same category without asking again ;
#   q = skip them and stop for this category. 
#   Returns 1 if the user asked to quit (q), 0 otherwise.
#   For safety, it never deletes anything that is not strictly inside ${MASSPROCESSPATH}.
#   REMOVEALL must be set to "no" by the caller at the beginning of each category.
function ConfirmAndRemove()
	{
	local LISTFILE=$1
	local ANSWER
	local ITEM

	if [ ! -s "${LISTFILE}" ] ; then echo "  Nothing found to remove." ; return 0 ; fi

	echo "  The following will be PERMANENTLY deleted:"
	while read -r ITEM ; do echo "     ${ITEM}" ; done < "${LISTFILE}"

	if [ "${REMOVEALL}" != "yes" ] ; then
		while true ; do
			read -p "  Delete these ? [y]es / [n]o / [a]ll (these and next ones without asking) / [q]uit this category : " ANSWER < /dev/tty
			case ${ANSWER} in
				[Yy]* ) break ;;
				[Aa]* ) REMOVEALL="yes" ; break ;;
				[Nn]* ) echo "  Skipped." ; return 0 ;;
				[Qq]* ) echo "  Stop removing for this category." ; return 1 ;;
				* ) echo "  Please answer y, n, a or q." ;;
			esac
		done
	fi

	while read -r ITEM ; do
		case "${ITEM}" in
			"${MASSPROCESSPATH}"/?* ) 
				echo "  Removing ${ITEM}"
				rm -rf "${ITEM}" ;;
			* ) 
				echo "  SAFETY: ${ITEM} is not inside ${MASSPROCESSPATH}; I do not remove it." ;;
		esac
	done < "${LISTFILE}"
	return 0
	}

# For each pair listed in file $1, collect the exact paths of the geocoded products (if $2 is GEOC or GEOC_AND_DIR)
#   and/or of the processing pair dir (if $2 is DIR or GEOC_AND_DIR), then display them and ask for confirmation 
#   before deleting (see ConfirmAndRemove).
function RemovePairProducts()
	{
	local PAIRLIST=$1
	local WHAT=$2
	local TOREMOVE="${MASSPROCESSPATH}/_CheckResults/_ToRemove_tmp.txt"
	local PAIR

	REMOVEALL="no"
	for PAIR in `cat -s "${PAIRLIST}"`
	do
		MASDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1`
		SLVDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1`
		echo
		if [ "${MASDATE}" = "" ] || [ "${SLVDATE}" = "" ] || [ "${MASDATE}" = "${SLVDATE}" ] ; then
			echo "Something went wrong: can't get two dates from ${PAIR}. I will not remove anything for that pair."
			echo "  Check ${PAIRLIST} and clean manually."
			continue
		fi
		echo "Pair ${MASDATE}_${SLVDATE}:"
		rm -f "${TOREMOVE}"
		touch "${TOREMOVE}"
		if [ "${WHAT}" = "GEOC" ] || [ "${WHAT}" = "GEOC_AND_DIR" ] ; then ListGeocProducts "${MASDATE}" "${SLVDATE}" >> "${TOREMOVE}" ; fi
		if [ "${WHAT}" = "DIR" ]  || [ "${WHAT}" = "GEOC_AND_DIR" ] ; then ListPairDirs "${MASDATE}" "${SLVDATE}" >> "${TOREMOVE}" ; fi

		if ! ConfirmAndRemove "${TOREMOVE}" ; then break ; fi
	done
	rm -f "${TOREMOVE}"
	}
	
	
rm -f Img_NotInAmpli.txt
rm -f Imgs_NotInCoh.txt
rm -f Imgs_NotInDefo.txt
rm -f Imgs_NotInDefoInterpol.txt
rm -f Imgs_NotInDefoInterpolDetrend.txt
rm -f Imgs_NotInDefoInterpolx2Detrend.txt
rm -f Imgs_NotInInterfFilt.txt
rm -f Imgs_NotInInterfResid.txt
rm -f Imgs_NotInUnwrapPhase.txt
rm -f Number_Geoc_Files_inPairs.txt

rm -f DirPair_NotInMassProcess.txt


rm -f ./Quarantined/Img_NotInAmpli.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Imgs_NotInCoh.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Imgs_NotInDefo.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Imgs_NotInDefoInterpol.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Imgs_NotInDefoInterpolDetrend.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Imgs_NotInDefoInterpolx2Detrend.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Imgs_NotInInterfFilt.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Imgs_NotInInterfResid.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Imgs_NotInUnwrapPhase.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/Number_Geoc_Files_inPairs.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/DirPair_NotInMassProcess.txt_Without_Quarantined_Img.txt

rm -f ./Quarantined/PairFiles_NoBaselines_Sorted_NoUnderscore.txt_Without_Quarantined_Img.txt
rm -f ./Quarantined/_GeocNotOK_AllGeocAreMissing_MissingPairDir.txt_Without_Quarantined_Img.txt



# Check data in Quarantine: 
###########################

# take first pair in ${MASSPROCESSPATH} that contains a */i12/TextFiles/InSARParameters.txt where one can get the path to SAR_CSL dir
FIRSTPAIRPARAMFILE=$(${PATHGNU}/gfind ${MASSPROCESSPATH} -mindepth 3 -maxdepth 4 -type f -name "InSARParameters.txt" | head -n 1)

# and get the list of quarantined images ()
if [ -f "${FIRSTPAIRPARAMFILE}" ]
	then 
		echo "Get path to SAR_CSL from ${FIRSTPAIRPARAMFILE}"
		RenameVolNameToVariable ${FIRSTPAIRPARAMFILE} ${FIRSTPAIRPARAMFILE}_StateVar.txt
		PATHMAS=$(GetParamFromFile "Master image file path [CSL image format]")
		PATHCSLDIRNoCrop=$(dirname ${PATHMAS})
		eval PATHCSLDIR=$(dirname ${PATHCSLDIRNoCrop})
		if [ -d "${PATHCSLDIR}/Quarantained" ]
			then
				${PATHGNU}/gfind ${PATHCSLDIR}/Quarantained -maxdepth 1 -type d -name "*.csl" | grep -oE '[0-9]{8}' > ${MASSPROCESSPATH}/_CheckResults/_Quarantined_ImagesDates.txt
			else 
				echo "No quarantined images in ${PATHCSLDIR}/Quarantained"

		fi
	else 
		echo "  No InSARParameters.txt file, "
		echo "  Hence, I can't figure out where is the SAR_CSL dir and check if there are quarantined files. "
		echo "  "
fi 

while read -r MASDATE SLVDATE
do	
	PAIR=${MASDATE}_${SLVDATE}
	echo -n "Check pair ${MASDATE}_${SLVDATE} : " 

	# Check files in Geocoded
	if [ `find ${MASSPROCESSGEOCPATH}/Ampli/*${MASDATE}*mod* -type f 2>/dev/null | wc -l` -lt 1 ] ; then echo "Geocoded file ${MASDATE} does not exist in Ampli" ; echo "${MASDATE}" >> Img_NotInAmpli_tmp.txt ; fi	
	if [ `find ${MASSPROCESSGEOCPATH}/Ampli/*${SLVDATE}*mod* -type f 2>/dev/null | wc -l` -lt 1 ] ; then echo "Geocoded file ${SLVDATE} does not exist in Ampli" ; echo "${SLVDATE}" >> Img_NotInAmpli_tmp.txt ; fi	
	
	for MODE in `cat -s MODES.TXT`
	do   
		CheckGeocProduct ${MODE}  &
	done
	wait

	#echo -n "	Start checking PAIR dir in MASS_PROCESS @" ; date '+ %H:%M:%S'
	# Check pairs/i12 dir in MASSPROCESSGEOCPATH 
	if [ -d ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection ] 
		then 
			echo " OK: a pair dir exists in ${MASSPROCESSPATH}" 
		else 
			if [ -d ${MASSPROCESSPATH}/*${SLVDATE}*_*${MASDATE}*/i12/GeoProjection ] 
				then 
					echo " OK: an inverted pair dir exists in ${MASSPROCESSPATH}"
				else
					echo " 	NOT OK !! : no pair nor inverted pair DIRECTROY in ${MASSPROCESSPATH}"
					echo "${PAIR}" >> DirPair_NotInMassProcess.txt 
			fi
	fi	

	#echo -n "	Start checking nr of Geocoded files @" ; date '+ %H:%M:%S'	
	NFILES=`ls ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection 2>/dev/null | wc -w`
	# TOOO SLOW :
	#NFILES=$(find "${MASSPROCESSPATH}" -type d -name "*${MASDATE}_*${SLVDATE}*" -path "*/i12/GeoProjection" -exec sh -c 'echo "$1"/* | wc -w' _ {} \; 2>/dev/null)

	if [ ${NFILES} == "0" ]
		then 
			# check if it could be because mas and slave were swapped
			NFILES=`ls ${MASSPROCESSPATH}/*${SLVDATE}*_*${MASDATE}*/i12/GeoProjection 2>/dev/null | wc -w`
			# TOOO SLOW :
			#NFILES=$(find "${MASSPROCESSPATH}" -type d -name "*${SLVDATE}_*${MASDATE}*" -path "*/i12/GeoProjection" -exec sh -c 'echo "$1"/* | wc -w' _ {} \; 2>/dev/null)
			if [ ${NFILES} == "0" ]
				then 
					echo "${PAIR} : ${NFILES}  (nothing in swapped neither !)" >> Number_Geoc_Files_inPairs.txt
				else 
					echo "${PAIR} : ${NFILES} (see swapped dir)" >> Number_Geoc_Files_inPairs.txt
			fi
		else 
			echo "${PAIR} : ${NFILES}" >> Number_Geoc_Files_inPairs.txt
	fi

# TOOO SLOW BELOW
#	NFILES=$(find "${MASSPROCESSPATH}" \( -type d -name "*${MASDATE}_*${SLVDATE}*" -o -type d -name "*${SLVDATE}_*${MASDATE}*" \) -path "*/i12/GeoProjection" -exec bash -c 'echo "$1"/*' _ {} \; 2>/dev/null | wc -w)
#
#	if [ ${NFILES} -eq 0 ]; then
#			echo "${PAIR} : ${NFILES} (nothing in either direction!)" >> Number_Geoc_Files_inPairs.txt
#		else
#			echo "${PAIR} : ${NFILES}" >> Number_Geoc_Files_inPairs.txt
#	fi
done < ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt

if [ -f "${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt" ] && [ -s "${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt" ] ; then sort ${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt | uniq > Img_NotInAmpli.txt ; fi
rm -f "${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt"


# Check if one mode is empty, that is the Imgs_NotIn*.txt file is the same as PAIRSFILE
i=0
for FILETOTEST in `cat -s MODES.TXT` 
do 
	if [ -f "Imgs_NotIn${FILETOTEST}.txt" ] && sort -u "Imgs_NotIn${FILETOTEST}.txt" | diff -q - ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt > /dev/null
		then
			echo "Imgs_NotIn${FILETOTEST}.txt is idential to ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt, that is no porducts of that mode were processed. Discard this mode from check."
			mv "Imgs_NotIn${FILETOTEST}.txt" "EmptyMode_${FILETOTEST}.txt"
			i=`echo "$i + 1" | bc -l`
			echo $i
	fi
done 

# Get the nr of non empty modes in Geocoded dir
NROFMODE=`echo "${NROFALLMODE} - $i" | bc -l`

rm -f _GeocOK_MissingPairDir.txt

rm -f _GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt
rm -f _GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt
rm -f _GeocNotOK_AllGeocAreMissing_MissingPairDir.txt

rm -f _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt
rm -f _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt
rm -f _GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt
rm -f _Empty_Dirs.txt


# If at least one mode is not empty
NROFNOTEMPTY=`ls Imgs_*.txt 2>/dev/null | wc -l `
if  [ ${NROFNOTEMPTY} != 0 ]
	then 
		# Check if all geocoded files exist and/or dir exists
		#for PAIR in `cat -s ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt`    
		while read -r MASDATE SLVDATE
		do	
			#MASDATE=`echo ${PAIR} | cut -d _ -f 1`
			#SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
			#Check if a pair is in some check files 
			if [ "${MASDATE}" != "" ] && [ "${SLVDATE}" != "" ] ; then 
					PAIR="${MASDATE}_${SLVDATE}"
					MISSING=`grep -o ${PAIR} Imgs_*.txt | wc -l`
					echo -n " Missing ${MISSING} geocoded products / ${NROFMODE} modes;  "
					if [ ${MISSING} == 0 ] 
						then 
							if [ ! -d ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection ] 
								then 
									if [ ! -d ${MASSPROCESSPATH}/*${SLVDATE}*_*${MASDATE}*/i12/GeoProjection ] 
										then
											echo "${PAIR} not OK : All Geocoded products are stored correctly for that pair BUT a dir is missing in MASSPROCESS" 
											echo ${PAIR} >> _GeocOK_MissingPairDir.txt
										else
											echo "${PAIR} OK though inverted during mass processing for sake of efficiency. Not a problem. " 
									fi
								else 
									echo "All Geocoded products are stored correctly and ${PAIR} dir is OK. Not a problem. " 
							fi	
						else 
							if [ ${MISSING} == ${NROFMODE} ] 
								then 
									if [ -d ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection ] 
										then 
											echo "${PAIR} not OK : All Geocoded products are missing BUT a dir exists in MASSPROCESSPATH. " 
											echo ${PAIR} >> _GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt
										else 
											if [ -d ${MASSPROCESSPATH}/*${SLVDATE}*_*${MASDATE}*/i12/GeoProjection ] 
												then
													echo "${PAIR} not OK : All Geocoded products are missing BUT an INVERTED dir exists in MASSPROCESSPATH. " 
													echo ${PAIR} >> _GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt
												else 
													echo "${PAIR} not OK : All Geocoded products and process dir are missing." 
													echo ${PAIR} >> _GeocNotOK_AllGeocAreMissing_MissingPairDir.txt
											fi
									fi	
								else
									if [ -d ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection ] 
										then 
											echo "${PAIR} not OK : Some Geocoded products are missing BUT a dir exists in MASSPROCESSPATH." 
											echo ${PAIR} >> _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt
										else 
											if [ -d ${MASSPROCESSPATH}/*${SLVDATE}*_*${MASDATE}*/i12/GeoProjection ] 
												then
													echo "${PAIR} not OK : Some Geocoded products are missing BUT an INVERTED dir exists in MASSPROCESSPATH. " 
													echo ${PAIR} >> _GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt
												else 
													echo "${PAIR} not OK : Some Geocoded products are missing and process dir are missing." 
													echo ${PAIR} >> _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt
											fi
									fi	
							fi
					fi
			fi
		done < ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt
		echo " ************************************************************************************"
		echo " ************************************************************************************"
		echo " WARNING : choosing to remove the files and directories here after may be harmfull"
		echo "         if you do not have the expected directory structure and naming convetion."
		echo " It might be wise to chose not to delete automatically these files and directories. "
		echo " Instead you can do it manually thanks to the products listed in the corresponding files."
		echo " ************************************************************************************"
		echo " ************************************************************************************"
		# Offers to remove geocoded products from /Geocoded and /GeocodedRasters that are from PAIR which dir are missing in MASSPROCESS
		if [ -f "_GeocOK_MissingPairDir.txt" ] && [ -s "_GeocOK_MissingPairDir.txt" ] ; then
			SpeakOut "Do you want to remove geocoded files and rasters which have no corresponding processing PAIR directory in MASSPROCESS ? " 
			if AskYesNo "Do you want to remove geocoded files and rasters which have no corresponding processing PAIR directory in MASSPROCESS (see _GeocOK_MissingPairDir.txt)? " ; then
				RemovePairProducts "_GeocOK_MissingPairDir.txt" "GEOC"
			fi
		fi

		# Offers to remove processing pair dirs that exist in MASSPROCESS but for which all geocoded products are missing
		if [ -f "_GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt" ] && [ -s "_GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt" ] ; then
			SpeakOut "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? " 
			if AskYesNo "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? (see _GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt) " ; then
				RemovePairProducts "_GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt" "DIR"
			fi
		fi

		# Same for inverted processing pair dirs (i.e. SLV_MAS)
		if [ -f "_GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt" ] && [ -s "_GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt" ] ; then
			SpeakOut "Do you want to remove processing inverted pair dirs (i.e. SLV_MAS) that exist in MASSPROCESS for which there is no geoc product? " 
			if AskYesNo "Do you want to remove processing inverted pair dirs (i.e. SLV_MAS) that exist in MASSPROCESS for which there is no geoc product? (see _GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt) " ; then
				RemovePairProducts "_GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt" "DIR"
			fi
		fi

		# Offers to remove incomplete geocoded products AND their processing pair dir 
		if [ -f "_GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt" ] && [ -s "_GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt" ] ; then		
			SpeakOut "Do you want to remove geocoded files and rasters which exits only for some modes but for which processing pair dir exists in MASSPROCESS ? Processing Pair dir will be removed as well. " 
			if AskYesNo "Do you want to remove geocoded files and rasters which exits only for some modes but for which processing pair dir exists in MASSPROCESS ? Processing Pair dir will be removed as well. (see _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt) " ; then
				RemovePairProducts "_GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt" "GEOC_AND_DIR"
			fi
		fi

		# Same for inverted processing pair dirs (i.e. SLV_MAS)
		if [ -f "_GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt" ] && [ -s "_GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt" ] ; then		
			SpeakOut "Do you want to remove geocoded files and rasters which exits only for some modes and for which an inverted processing pair dir (i.e. SLV_MAS) exists in MASSPROCESS ? Processing Pair dir will be removed as well. " 
			if AskYesNo "Do you want to remove geocoded files and rasters which exits only for some modes and for which an inverted processing pair dir (i.e. SLV_MAS) exists in MASSPROCESS ? Processing Pair dir will be removed as well. (see _GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt) " ; then
				RemovePairProducts "_GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt" "GEOC_AND_DIR"
			fi
		fi

		# Offers to remove incomplete geocoded products for which there is no processing pair dir
		if [ -f "_GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt" ] && [ -s "_GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt" ] ; then		
			SpeakOut "Do you want to remove geocoded files and rasters which exits only for some modes and for which processing pair dir does not exist in MASSPROCESS ? " 
			if AskYesNo "Do you want to remove geocoded files and rasters which exits only for some modes and for which processing pair dir does not exist in MASSPROCESS ? (see _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt) " ; then
				RemovePairProducts "_GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt" "GEOC"
			fi
		fi

		if [ -f "_GeocNotOK_AllGeocAreMissing_MissingPairDir.txt" ] && [ -s "_GeocNotOK_AllGeocAreMissing_MissingPairDir.txt" ] ; then		
			echo "The Following pairs are missing (not geocoded products nor pair dir found): "
			cat _GeocNotOK_AllGeocAreMissing_MissingPairDir.txt
		fi


	else  # No Imgs_NotIn*.txt file left: either all geocoded products exist, or all modes were discarded as empty 
		if [ ${NROFMODE} -eq 0 ] 
			then
				# No geocoded product at all: offer to remove the pair dirs that exist in MASSPROCESS,
				#   i.e. all pairs from the list except those without pair dir (DirPair_NotInMassProcess.txt)
				if [ -f DirPair_NotInMassProcess.txt ] 
					then 
						sort ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt DirPair_NotInMassProcess.txt | uniq -u > PAIRSTOREMOVE.TXT
					else 
						cp ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt PAIRSTOREMOVE.TXT
				fi
				if [ -f PAIRSTOREMOVE.TXT ] && [ -s PAIRSTOREMOVE.TXT ] ; then
					SpeakOut "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product?  " 
					if AskYesNo "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? (see PAIRSTOREMOVE.TXT) " ; then
						RemovePairProducts "PAIRSTOREMOVE.TXT" "DIR"
					fi
				fi
			else 
				echo "All geocoded products were found for all modes. Nothing to remove."
		fi
fi  # end of "if at least one mode is not empty"

# By security, test if some dir pairs are empty
#for PAIR in `ls -d ${MASSPROCESSPATH}/*_* | ${PATHGNU}/grep -v ".txt" | ${PATHGNU}/grep -v "_CheckResults"`    
for PAIR in `find ${MASSPROCESSPATH} -maxdepth 1 -mindepth 1 -type d -name "*_*" | ${PATHGNU}/grep -v ".txt" | ${PATHGNU}/grep -v "_CheckResults"`  
do	
	if [ ! -d ${PAIR}/i12/GeoProjection ] ; then echo "The dir ${PAIR} seems empty; at least it does not have a i12/GeoProjection directory" ; echo ${PAIR} >> _Empty_Dirs.txt ; fi	
done
if [ -f _Empty_Dirs.txt ] ; then 
	SpeakOut "Do you want to remove empty dirs in MASSPROCESS?  " 
	if AskYesNo "Do you want to remove empty dirs in MASSPROCESS? (see _Empty_Dirs.txt) " ; then
		# _Empty_Dirs.txt already contains the exact path of each dir 
		REMOVEALL="no"
		for PAIRDIR in `cat -s _Empty_Dirs.txt`    
		do 
			echo
			# Check again that it is still a dir without i12/GeoProjection before offering to remove it
			if [ -d "${PAIRDIR}" ] && [ ! -d "${PAIRDIR}/i12/GeoProjection" ] ; then
				echo "${PAIRDIR}" > "${MASSPROCESSPATH}/_CheckResults/_ToRemove_tmp.txt"
				if ! ConfirmAndRemove "${MASSPROCESSPATH}/_CheckResults/_ToRemove_tmp.txt" ; then break ; fi
			fi
		done
		rm -f "${MASSPROCESSPATH}/_CheckResults/_ToRemove_tmp.txt"
	fi
fi



# Remove quarantined images from each error file (if exist) 
if [ -f ${MASSPROCESSPATH}/_CheckResults/_Quarantined_ImagesDates.txt ] && [ -s ${MASSPROCESSPATH}/_CheckResults/_Quarantined_ImagesDates.txt ]
	then 
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/_GeocNotOK_AllGeocAreMissing_MissingPairDir.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/DirPair_NotInMassProcess.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Imgs_NotInCoh.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Imgs_NotInDefo.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Imgs_NotInDefoInterpol.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Imgs_NotInDefoInterpolDetrend.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Imgs_NotInDefoInterpolx2Detrend.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Imgs_NotInInterfFilt.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Imgs_NotInInterfResid.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Imgs_NotInUnwrapPhase.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/Number_Geoc_Files_inPairs.txt"
		RemoveQuarantined "${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt"
		
		#rm ${FIRSTPAIR}/i12/TextFiles/InSARParameters_StateVar.txt 2/dev/null
		rm -f "${FIRSTPAIRPARAMFILE}_StateVar.txt" #2/dev/null
		
fi

rm -f MODES.TXT PAIRSTOREMOVE.TXT

echo "Check in Number_Geoc_Files_inPairs.txt if all pairs have the same number of geocoded files. Discrepencies would reflect processing problem : "
echo "I list that file for you here. "
echo "Note : "
echo "    For each pair with a new image, there must be a set of 4 new geocoded files corresponding to the new image amplitude. "
echo "    The first pair ever processed should have another 4 additional amplitude files because the tw oimages are new.  "
echo "    If some pairs were swapped during processing, the number of files indicated here will be followed by: (see swapped dir)"
echo "Pairs with PRM and SCD swapped when SCD is Global Primary (SuperMaster) may be ignored in the _GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt.    "
sort -rk 3,3 Number_Geoc_Files_inPairs.txt

#rm -f ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt