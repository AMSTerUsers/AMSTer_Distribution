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
# Parameters :      - file with the list of pairs supposed to be processed in the form of MASTER_SLAVE dates (Table_...._NoBaselines.txt)
#                   - dir where Geocoded results are stored (eg. /.../SAR_MASSPROCESS/SAT/TRACK/CROP_SM_DATE_ZOOM_ML/Geocoded)
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
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2015/08/24 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.6 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 19, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


PAIRSFILE=$1				# file with the list of pairs supposed to be processed in the form of MASTER_SLAVE dates
MASSPROCESSGEOCPATHTMP=$2		# dir where Geocoded results are stored (eg. /.../SAR_MASSPROCESS/SAT/TRACK/CROP_SM_DATE_ZOOM_ML/Geocoded)

# Remove possible trailing /
MASSPROCESSGEOCPATH=${MASSPROCESSGEOCPATHTMP%/} 

MASSPROCESSPATH=`echo ${MASSPROCESSGEOCPATH} | ${PATHGNU}/gsed "s%\/Geocoded%%" `

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
# Compatible Pairs (in the form of "date_date"; also for S1):
 if ${PATHGNU}/grep -q Delay "${PAIRSFILE}"
 	then
   		# If PAIRFILE = table from Prepa_MSBAS.sh, it contains the string "Delay", then
		# Remove header and extract only the pairs in ${PAIRFILE}
		cat ${PAIRSFILE} | tail -n+3 | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${PAIRSFILE}_NoBaselines_${RNDM1}.txt 
	else
		# If PAIRFILE = list of images to play, it contains already only the dates
		cp ${PAIRSFILE} ${PAIRSFILE}_NoBaselines_${RNDM1}.txt
 fi

PAIRSFILE=${PAIRSFILE}_NoBaselines_${RNDM1}.txt

mkdir -p ${MASSPROCESSPATH}/_CheckResults
cd ${MASSPROCESSPATH}/_CheckResults

# For ease of check : sort PAIRSFILE
sort ${PAIRSFILE} > ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt
${PATHGNU}/gsed "s/_/ /g" ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt > ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt

# some stuff for later
ls ${MASSPROCESSGEOCPATH} | ${PATHGNU}/grep -v Ampli | ${PATHGNU}/grep -v .txt > MODES.TXT # List all modes except Ampli because we know that must exist anyway
NROFALLMODE=`wc -l < MODES.TXT`

if [ $# -lt 2 ] ; then echo “Usage $0 LIST_OF_PAIRS DIR_TO_GEOCODED”; exit; fi

# Function to test existence of file in dir
function CheckGeocProduct()
	{
	unset MODE  
	MODE=$1 # e.g Coh
	if [ `find ${MASSPROCESSGEOCPATH}/${MODE}/*${MASDATE}*_*${SLVDATE}* -type f 2>/dev/null | wc -l` -lt 1 ] 
		then 
			if [ `find ${MASSPROCESSGEOCPATH}/${MODE}/*${SLVDATE}*_*${MASDATE}* -type f 2>/dev/null | wc -l` -lt 1 ] 
				then 
					echo "Geocoded file ${MASDATE}_${SLVDATE} does not exist in ${MODE}"
					echo "${MASDATE}_${SLVDATE}" >> Imgs_NotIn${MODE}.txt 
			fi
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

#for PAIR in `cat -s ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt`    
while read -r MASDATE SLVDATE
do	
#	MASDATE=`echo ${PAIR} | cut -d _ -f 1`
#	SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
	PAIR=${MASDATE}_${SLVDATE}
	# Check files in Geocoded
	if [ `find ${MASSPROCESSGEOCPATH}/Ampli/*${MASDATE}*mod* -type f 2>/dev/null | wc -l` -lt 1 ] ; then echo "Geocoded file ${MASDATE} does not exist in Ampli" ; echo "${MASDATE}" >> Img_NotInAmpli_tmp.txt ; fi	
	if [ `find ${MASSPROCESSGEOCPATH}/Ampli/*${SLVDATE}*mod* -type f 2>/dev/null | wc -l` -lt 1 ] ; then echo "Geocoded file ${SLVDATE} does not exist in Ampli" ; echo "${SLVDATE}" >> Img_NotInAmpli_tmp.txt ; fi	
	
	for MODE in `cat -s MODES.TXT`
	do   
		CheckGeocProduct ${MODE} 
	done &
	wait
	
	# Check pairs/i12 dir in MASSPROCESSGEOCPATH 
	if [ -d ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection ] 
		then 
			echo "A dir ${PAIR} exists in ${MASSPROCESSPATH}" 
		else 
			if [ -d ${MASSPROCESSPATH}/*${SLVDATE}*_*${MASDATE}*/i12/GeoProjection ] 
				then 
					echo "A dir ${SLVDATE}_${MASDATE} exists in ${MASSPROCESSPATH}"
				else
					echo "A dir ${PAIR} or ${SLVDATE}_${MASDATE} does not exist in ${MASSPROCESSPATH}"
					echo "${PAIR}" >> DirPair_NotInMassProcess.txt 
			fi
	fi	
	NFILES=`ls ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection | wc -w`
	if [ ${NFILES} == "0" ]
		then 
			# check if it could be because mas and slave were swapped
			NFILES=`ls ${MASSPROCESSPATH}/*${SLVDATE}*_*${MASDATE}*/i12/GeoProjection | wc -w`
			if [ ${NFILES} == "0" ]
				then 
					echo "${PAIR} : ${NFILES}  (nothing in swapped neither !)" >> Number_Geoc_Files_inPairs.txt
				else 
					echo "${PAIR} : ${NFILES} (see swapped dir)" >> Number_Geoc_Files_inPairs.txt
			fi
		else 
			echo "${PAIR} : ${NFILES}" >> Number_Geoc_Files_inPairs.txt
	fi
done < ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt

if [ -f "${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt" ] && [ -s "${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt" ] ; then sort ${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt | uniq > Img_NotInAmpli.txt ; fi
rm -f ${MASSPROCESSPATH}/_CheckResults/Img_NotInAmpli_tmp.txt


# Check if one mode is empty, that is the Imgs_NotIn*.txt file is the same as PAIRSFILE
i=0
for FILETOTEST in `cat -s MODES.TXT` 
do 
	if diff Imgs_NotIn${FILETOTEST}.txt ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt > /dev/null
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
rm -f _GeocNotOK_ExistingPairDir.txt
rm -f _GeocNotOK_MissingPairDir.txt
rm -f _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt
rm -f _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt
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
					fi	
				else 
					if [ "${MISSING}" == "${NROFMODE}" ] 
						then 
							if [ -d ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection ] 
								then 
									if [ -d ${MASSPROCESSPATH}/*${SLVDATE}*_*${MASDATE}*/i12/GeoProjection ] 
										then
											echo "${PAIR} not OK : All Geocoded products are missing BUT a dir exists in MASSPROCESSPATH. " 
											echo ${PAIR} >> _GeocNotOK_ExistingPairDir.txt
										else 
											echo "${PAIR} OK though inverted during mass processing for sake of efficiency. Not a problem. " 
									fi
								else 
									echo "${PAIR} not OK :  Geocoded products and process dir are missing." 
									echo ${PAIR} >> _GeocNotOK_MissingPairDir.txt
							fi	
						else
							if [ -d ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*/i12/GeoProjection ] 
								then 
									echo "${PAIR} not OK : Some Geocoded products are missing BUT a dir exists in MASSPROCESSPATH." 
									echo ${PAIR} >> _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt
								else 
									echo "${PAIR} not OK :  Some Geocoded products are missing and process dir are missing." 
									echo ${PAIR} >> _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt
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
										MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
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

		if [ -f "_GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt" ] && [ -s "_GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt" ] ; then		
			SpeakOut "Do you want to remove geocoded files and rasters which exits only for some modes and for which processing pair dir does not exist in MASSPROCESS ? " 
					while true; do
						read -p "Do you want to remove geocoded files and rasters which exits only for some modes and for which processing pair dir does not exist in MASSPROCESS (see _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt) ? "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocNotOK_SomeGeocAreMissing_MissingPairDir.txt`    
									do 
										MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
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

		if [ -f "_GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt" ] && [ -s "_GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt" ] ; then		
			SpeakOut "Do you want to remove geocoded files and rasters which exits only for some modes but for which processing pair dir exists in MASSPROCESS ? Processing Pair dir will be removed as well. " 
					while true; do
						read -p "Do you want to remove geocoded files and rasters which exits only for some modes but for which processing pair dir exists in MASSPROCESS ? Processing Pair dir will be removed as well. (see _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt) "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocNotOK_SomeGeocAreMissing_ExistingPairDir.txt`    
									do 
										MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										for MODE in `cat -s MODES.TXT`
											do   
												#rm -f ${MASSPROCESSGEOCPATH}/${MODE}/*${PAIR}*
												#rm -f ${MASSPROCESSGEOCPATH}Rasters/${MODE}/*${PAIR}*

												#hopefuly a faster solution...
												find ${MASSPROCESSGEOCPATH}/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
												find ${MASSPROCESSGEOCPATH}Rasters/${MODE}/ -name "*${MASDATE}*_*${SLVDATE}*" -print0 | xargs -0 rm 
											done 
										rm -fR ${MASSPROCESSPATH}/${PAIR}
									echo
									done
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi

		if [ -f "_GeocNotOK_ExistingPairDir.txt" ] && [ -s "_GeocNotOK_ExistingPairDir.txt" ] ; then
			SpeakOut "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? " 
					while true; do
						read -p "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? (see _GeocNotOK_ExistingPairDir.txt) "  yn
						case $yn in
							[Yy]* ) 
								for PAIR in `cat -s _GeocNotOK_ExistingPairDir.txt`    
									do 
										MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										rm -Rf ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*
									done
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi



	else  # if all mode are empty, check if pair dirs can be present in MASSPROCESS
		# Check pairs that are in MASSPROCESS  
		sort ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted.txt DirPair_NotInMassProcess.txt | uniq -u > PAIRSTOREMOVE.TXT

		# if  PAIRSTOREMOVE not empty
		if [ -f PAIRSTOREMOVE.txt ] && [ -s PAIRSTOREMOVE.txt ] ; then
				SpeakOut "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product?  " 
				while true; do
				read -p "Do you want to remove processing pair dirs that exist in MASSPROCESS for which there is no geoc product? (see PAIRSTOREMOVE.TXT) "  yn
					case $yn in
						[Yy]* ) 
								for PAIR in `cat -s PAIRSTOREMOVE.TXT`    
									do 
										MASDATE=`echo ${PAIR} | cut -d _ -f 1`
										SLVDATE=`echo ${PAIR} | cut -d _ -f 2`
										rm -Rf ${MASSPROCESSPATH}/*${MASDATE}*_*${SLVDATE}*
								done
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
								rm -Rf *${MASDATE}*_*${SLVDATE}*
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
echo "Pairs with MAS and SLV swapped when SLV is SuperMaster may be ignored in the _GeocNotOK_ExistingPairDir.txt.    "
sort -rk 3,3 Number_Geoc_Files_inPairs.txt

rm -f  ${PAIRSFILE}_NoBaselines_${RNDM1}.txt ${MASSPROCESSPATH}/_CheckResults/PairFiles_NoBaselines_Sorted_NoUnderscore.txt

