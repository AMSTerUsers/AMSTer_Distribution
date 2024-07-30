#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at verifying that the results from the mass processing are successfully 
#     stored at the appropriate place. 
# It will read the list of pairs supposed to be processed, then 
#    - check if data are stored in each Geocoded/Modes
#    - check if each dir of processed pair is stored in corresponding SAR_MASSPROCESS dir
# It will output a series of text files with the status of each of these checks.  
# it will then check if Geocoded products exists but not the Pair dir
#
# Parameters :      - file with the list of pairs supposed to be processed in the form of PRIMARY_SECONDARY dates (Table_...._NoBaselines.txt)
#					  or MASDATE	SLVDATE	BP	Bt (with or without header)
#                   - dir where Geocoded results are stored (eg. /.../SAR_MASSPROCESS/SAT/TRACK/CROP_SM_DATE_ZOOM_ML/Geocoded)
#					- optional: a date in the form YYYYMMDD: it will only check pairs with both Primary and Secondary dates >= that date  
#
# Dependencies:
#    - gnu sed and awk for more compatibility. 
#    - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
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
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.4 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on May 27, 2024"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


PAIRSFILE=$1				# file with the list of pairs supposed to be processed in the form of PRIMARY_SECONDARY dates
MASSPROCESSGEOCPATHTMP=$2		# dir where Geocoded results are stored (eg. /.../SAR_MASSPROCESS/SAT/TRACK/CROP_SM_DATE_ZOOM_ML/Geocoded)

if [ $# -lt 2 ] ; then echo “Usage $0 LIST_OF_PAIRS DIR_TO_GEOCODED”; exit; fi

# Remove possible trailing /
MASSPROCESSGEOCPATH=${MASSPROCESSGEOCPATHTMP%/} 

MASSPROCESSPATH=`echo ${MASSPROCESSGEOCPATH} | ${PATHGNU}/gsed "s%\/Geocoded%%" `

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
		echo “Restrict list of pairs to check to pairs with both Priamry and Secondary images after ${DATEFROM}”
		${PATHGNU}/gawk -v given_date="${DATEFROM}" -F '_' '$1 >= given_date && $2 >= given_date {print}' ${PAIRSFILE} > ${PAIRSFILE}_From${DATEFROM}.txt
		PAIRSFILE=${PAIRSFILE}_From${DATEFROM}.txt	
fi

# For ease of check : sort PAIRSFILE
sort ${PAIRSFILE} | ${PATHGNU}/gsed "s/_/ /g" > ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt
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

	if [ `find "${MASSPROCESSGEOCPATH}/${MODE}" -maxdepth 1 -type f -type f \( -name "*${MASDATE}_*${SLVDATE}*" -o -name "*${SLVDATE}_${MASDATE}*" \) 2>/dev/null | wc -l` -lt 1 ] 
		then
	    	echo "	Geocoded file ${MASDATE}_${SLVDATE} does not exist in ${MODE}"
	    	echo "${MASDATE}_${SLVDATE}" >> "Imgs_NotIn${MODE}.txt"
	   # For debugging
	   # else 
	   # 	echo "	Geocoded file ${MASDATE}_${SLVDATE} exists in ${MODE}"
	fi

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
rm -f ${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt


# Check if one mode is empty, that is the Imgs_NotIn*.txt file is the same as PAIRSFILE
i=0
for FILETOTEST in `cat -s MODES.TXT` 
do 
	if diff Imgs_NotIn${FILETOTEST}.txt ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt 2> /dev/null
		then
			echo "Imgs_NotIn${FILETOTEST}.txt is idential to ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt, that is no porducts of that mode were processed. Discard this mode from check."
			mv Imgs_NotIn${FILETOTEST}.txt EmptyMode_${FILETOTEST}.txt
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
			PAIR=${MASDATE}_${SLVDATE}
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

		done < ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt

		# Offers to remove geocoded products from /Geocoded and /Geocoded_Rasters that are from PAIR which dir are missing in MASSPROCESS
		if [ -f "_GeocOK_MissingPairDir.txt" ] && [ -s "_GeocOK_MissingPairDir.txt" ] ; then
			SpeakOut "Do you want to remove geocoded files and rasters which have no corresponding processing PAIR directory in MASSPROCESS ? " 
					while true; do
						read -p "Do you want to remove geocoded files and rasters which have no corresponding processing PAIR directory in MASSPROCESS (see _GeocOK_MissingPairDir.txt)? "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocOK_MissingPairDir.txt`    
									do 
										#MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										#SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										MASDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1`
										SLVDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1`

										for MODE in `cat -s MODES.TXT`
											do   
												#rm -f ${MASSPROCESSGEOCPATH}/${MODE}/*${PAIR}*
												#rm -f ${MASSPROCESSGEOCPATH}Rasters/${MODE}/*${PAIR}*
										
												#hopefuly a faster solution...
												find ${MASSPROCESSGEOCPATH}/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
												find ${MASSPROCESSGEOCPATH}Rasters/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 

											done 
									echo
									done
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi

		if [ -f "_GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt" ] && [ -s "_GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt" ] ; then
			SpeakOut "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? " 
					while true; do
						read -p "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? (see _GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt) "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocNotOK_AllGeocAreMissing_ExistingPairDir.txt`    
									do 
										#MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										#SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										MASDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1`
										SLVDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1`

										PAIRDIRTMP=$(find ${MASSPROCESSPATH}/ -maxdepth 1 -type d -name "*${MASDATE}*_*${SLVDATE}*")
										echo "Removing ${PAIRDIRTMP}..."
										rm -fR ${PAIRDIRTMP}
									done
								unset PAIRDIRTMP
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi
		if [ -f "_GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt" ] && [ -s "_GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt" ] ; then
			SpeakOut "Do you want to remove processing inverted pair dirs (i.e. SLV_MAS) that exist in MASSPROCESS for which there is no geoc product? " 
					while true; do
						read -p "Do you want to remove processing inverted pair dirs (i.e. SLV_MAS) that exist in MASSPROCESS for which there is no geoc product? (see _GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt) "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocNotOK_AllGeocAreMissing_ExistingInvertedPairDir.txt`    
									do 
										#MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										#SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										MASDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1`
										SLVDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1`

										PAIRDIRTMP=$(find ${MASSPROCESSPATH}/ -maxdepth 1 -type d -name "*${MASDATE}*_*${SLVDATE}*")
										echo "Removing ${PAIRDIRTMP}..."
										rm -fR ${PAIRDIRTMP}
									done
								unset PAIRDIRTMP
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi


		if [ -f "_GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt" ] && [ -s "_GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt" ] ; then		
			SpeakOut "Do you want to remove geocoded files and rasters which exits only for some modes but for which processing pair dir exists in MASSPROCESS ? Processing Pair dir will be removed as well. " 
					while true; do
						read -p "Do you want to remove geocoded files and rasters which exits only for some modes but for which processing pair dir exists in MASSPROCESS ? Processing Pair dir will be removed as well. (see _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt) "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt`    
									do 
										#MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										#SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										MASDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1`
										SLVDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1`

										for MODE in `cat -s MODES.TXT`
											do   
												#rm -f ${MASSPROCESSGEOCPATH}/${MODE}/*${PAIR}*
												#rm -f ${MASSPROCESSGEOCPATH}Rasters/${MODE}/*${PAIR}*

												#hopefuly a faster solution...
												find ${MASSPROCESSGEOCPATH}/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
												find ${MASSPROCESSGEOCPATH}Rasters/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
											done 
										PAIRDIRTMP=$(find ${MASSPROCESSPATH}/ -maxdepth 1 -type d -name "*${MASDATE}*_*${SLVDATE}*")
										echo "Removing ${PAIRDIRTMP}..."
										rm -fR ${PAIRDIRTMP}
									echo
									done
								unset PAIRDIRTMP
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi

		if [ -f "_GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt" ] && [ -s "_GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt" ] ; then		
			SpeakOut "Do you want to remove geocoded files and rasters which exits only for some modes and for which inverted processing pair dir (i.e. SLV_MAS) does not exist in MASSPROCESS ? " 
					while true; do
						read -p "Do you want to remove geocoded files and rasters which exits only for some modes and for which inverted processing pair dir (i.e. SLV_MAS) does not exist in MASSPROCESS (see _GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt) ? "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocNotOK_SomeGeocAreMissing_ExistingInvertedPairDir.txt`    
									do 
										#MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										#SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										MASDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1`
										SLVDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1`
										
										for MODE in `cat -s MODES.TXT`
											do   
												#rm -f ${MASSPROCESSGEOCPATH}/${MODE}/*${PAIR}*
												#rm -f ${MASSPROCESSGEOCPATH}Rasters/${MODE}/*${PAIR}*

												#hopefuly a faster solution...
												find ${MASSPROCESSGEOCPATH}/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
												find ${MASSPROCESSGEOCPATH}Rasters/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
											done 
										PAIRDIRTMP=$(find ${MASSPROCESSPATH}/ -maxdepth 1 -type d -name "*${MASDATE}*_*${SLVDATE}*")
										echo "Removing ${PAIRDIRTMP}..."
										rm -fR ${PAIRDIRTMP}
									echo
									done
								unset PAIRDIRTMP
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi
		if [ -f "_GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt" ] && [ -s "_GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt" ] ; then		
			SpeakOut "Do you want to remove geocoded files and rasters which exits only for some modes and for which processing pair dir does not exist in MASSPROCESS ? " 
					while true; do
						read -p "Do you want to remove geocoded files and rasters which exits only for some modes and for which processing pair dir does not exist in MASSPROCESS ? (see _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt) "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt`    
									do 
										#MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										#SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										MASDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1`
										SLVDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1`

										for MODE in `cat -s MODES.TXT`
											do   
												#rm -f ${MASSPROCESSGEOCPATH}/${MODE}/*${PAIR}*
												#rm -f ${MASSPROCESSGEOCPATH}Rasters/${MODE}/*${PAIR}*

												#hopefuly a faster solution...
												find ${MASSPROCESSGEOCPATH}/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
												find ${MASSPROCESSGEOCPATH}Rasters/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
											done 
									echo
									done
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi

		if [ -f "_GeocNotOK_AllGeocAreMissing_MissingPairDir.txt" ] && [ -s "_GeocNotOK_AllGeocAreMissing_MissingPairDir.txt" ] ; then		
			echo "The Following pairs are missing (not geocoded products nor pair dir found): "
			cat _GeocNotOK_AllGeocAreMissing_MissingPairDir.txt
		fi


	else  # if all list of missing images in mode are empty, check if pair dirs can be present in MASSPROCESS
		# Check pairs that are in MASSPROCESS  
		if [ -f DirPair_NotInMassProcess.txt ] && [ -s DirPair_NotInMassProcess.txt ] ; then
			sort ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt DirPair_NotInMassProcess.txt | uniq -u > PAIRSTOREMOVE.TXT
		fi
		# if  PAIRSTOREMOVE not empty
		if [ -f PAIRSTOREMOVE.txt ] && [ -s PAIRSTOREMOVE.txt ] ; then
				SpeakOut "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product?  " 
				while true; do
				read -p "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? (see PAIRSTOREMOVE.TXT) "  yn
					case $yn in
						[Yy]* ) 
								for PAIR in `cat -s PAIRSTOREMOVE.TXT`    
									do 
										#MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										#SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										MASDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1`
										SLVDATE=`echo ${PAIR} | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1`

										PAIRDIRTMP=$(find ${MASSPROCESSPATH}/ -maxdepth 1 -type d -name "*${MASDATE}*_*${SLVDATE}*")
										echo "Removing ${PAIRDIRTMP}..."
										rm -fR ${PAIRDIRTMP}
								done
								unset PAIRDIRTMP
								break ;;
						[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
					esac
				done
		fi
fi  # en of "if at least one mode is not empty"

# By security, test if some dir pairs are empty
#for PAIR in `ls -d ${MASSPROCESSPATH}/*_* | ${PATHGNU}/grep -v ".txt" | ${PATHGNU}/grep -v "_CheckResults"`    
for PAIR in `find ${MASSPROCESSPATH} -maxdepth 1 -mindepth 1 -type d -name "*_*" | ${PATHGNU}/grep -v ".txt" | ${PATHGNU}/grep -v "_CheckResults"`  
do	
	if [ ! -d ${PAIR}/i12/GeoProjection ] ; then echo "The dir ${PAIR} seems empty" ; echo ${PAIR} >> _Empty_Dirs.txt ; fi	
done
if [ -f _Empty_Dirs.txt ] ; then 
		SpeakOut "Do you want to remove empty dirs in MASSPROCESS?  " 
		while true; do
		read -p "Do you want to remove empty dirs in MASSPROCESS? (see _Empty_Dirs.txt) "  yn
			case $yn in
				[Yy]* ) 
						for PAIR in `cat -s _Empty_Dirs.txt`    
							do 
								PAIRDIRTMP=$(find ${MASSPROCESSPATH}/ -maxdepth 1 -type d -name "*${MASDATE}*_*${SLVDATE}*")
								rm -fR ${PAIRDIRTMP}
						done
						break ;;
				[Nn]* ) break ;;
					* ) 
						echo "Please answer yes or no.";;
			esac
		done
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

