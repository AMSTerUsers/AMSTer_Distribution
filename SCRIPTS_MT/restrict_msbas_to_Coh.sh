#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at removing from a prepared msbas data set (eg DefoInterpolx2Detrend2) 
# all the images that does not satisfy a minimum average coherence on a selected zone provided by a kml.
# It is intended to run after build_header_msbas_criteria.sh or 
# after build_header_msbas_criteria_From_nvi_name_WithoutAcqTime.sh 
# and before running MSBAS.sh
#
# Run this for each mode to be cleaned
#
#  Script must be launched in the dir where msbas will be run, which contains all the Modei and Modei.txt. 
#
# Parameters are : 
#       - mode to clean (eg DefoInterpolx2Detrend2)
#		- coh threshold
#		- kml of zone where to test the coh
#		- path to coherence files : SAR_MASSPROCESS/SAT/TRK/REGION_ML/Geocoded/Coh
#
# Dependencies:	- function getStatForZoneInFile from CIS
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.2
# New in Distro V 1.1:	- Skip images already tested
#						- Do not name Full Modei with date and add possible all new files in _Full
#						 -backup Mode1.txt in Modei_Full named with date and time of the processing
# New in Distro V 1.2:	- keep list of pairs already checked against coh threshold with a generic name (MODEi/Checked_For_CohThreshold.txt) to be ignored in build_header_msbas_criteria.sh
# New in Distro V 1.3:	- keep track of list of pairs without coh threshold as _Full.txt
# New in Distro V 1.4:	- rename list of pairs checked against coh threshold to avoid confusion (Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt instead of Out_Of_Range_CohThreshold.txt)
#						- Keep track of pairs excluded because of coh threshold in List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KML}.txt
# New in Distro V 1.5:	- Force discarding pairs that would satisfy all criteria but that are contained in _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
# New in Distro V 1.6: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V 1.7: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.0 20241030:	- typo: $ was missing in lines mv ($){RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt...
#								- mute error message for rm files if they do not exist when performing restrict coh on pair selection from table rather than criteria
# New in Distro V 2.1 20250508:	- add notice that the script can handle a change of coherence threshold higher than the possible former one, but not smaller.
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on May 08, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


MODETOCLEAN=$1		# Mode to clean, i.e. MODEi as in MSBAS_RESULTS/MODEi
COHTHRESHOLD=$2		# Coherence threshold above which images are kept
KML=$3				# Zone where to test if Coherence threshold is satisfied  
PATHTOCOH=$4		# path to coherence files : SAR_MASSPROCESS/SAT/TRK/REGION_ML/Geocoded/Coh

echo ""

RNDM1=`echo $(( $RANDOM % 10000 ))`
RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`

RUNDIR=$(pwd)

if [ ! -d ${RUNDIR}/${MODETOCLEAN} ] ; then echo " You seems to be in the wrong dir or there is no mode to clean as claimed" ; exit ; fi
if [ $# -lt 4 ] ; then echo “Usage $0 ModeToClean CohThreshold Kml PathToCoh”; exit; fi

# Check if former run was done, then check the last one, then check if it used a Coh Threshold smaller than current one, in which case it can't work. 
# i.e. Search for the last file "CommandLine_restrict_msbas_to_Coh.sh_03_19_2025_13h53m_978.txt" 
# If it contains a Coh Threshold higher that the current one, exit... and suggest to create a new run from scratch in another dir 

if ls ${RUNDIR}/CommandLine_restrict_msbas_to_Coh.sh_*.txt 1>/dev/null 2>&1; then		# if any CommandLine_restrict_msbas_to_Coh.sh_*.txt exist
    # search for most recent one 
    LASTRUN=$(ls -t CommandLine_restrict_msbas_to_Coh.sh_*.txt 2>/dev/null | head -n 1)		# take the last one
	FORMERCOHTHRESH=$(${PATHGNU}/gawk 'NR==2 {print $2}' "${LASTRUN}")
	#if [ ${COHTHRESHOLD} -lt ${FORMERCOHTHRESH} ]
	if (( $(echo "${COHTHRESHOLD} < ${FORMERCOHTHRESH}" | bc -l) ))
		then 
			echo "You performed another Coherence Threshold restriction with a larger threshold (last used coh. thresh.: ${FORMERCOHTHRESH} ;  actual: ${COHTHRESHOLD}). "
			echo "I can't make a coh restriction with a smaller threshold in the same MSBAS dir. "
			echo "Please make another MSBAS from scratch in another directory"
			echo 
			echo "exiting"...
			exit
		else 
			#if [ ${COHTHRESHOLD} -gt ${FORMERCOHTHRESH} ] 
			if (( $(echo "${COHTHRESHOLD} > ${FORMERCOHTHRESH}" | bc -l) ))
				then
					echo "You performed another Coherence Threshold restriction with a smaller threshold (last used coh. thresh.: ${FORMERCOHTHRESH} ;  actual: ${COHTHRESHOLD}). "
					echo "I can operate such a new restriction in the same MSBAS dir with a larder coh threshold, though beware of possible confusion. "
					echo "A cleaner solution would be to make another MSBAS from scratch in another directory."
		
					SpeakOut "Do you want to continue ?" 
					while true; do
						read -p "Do you want to continue ?"  yn
						case $yn in
							[Yy]* ) 
								echo "OK, you know..."
								break ;;
							[Nn]* ) 
	   							exit 1	
								break ;;
							* ) echo "Please answer yes or no.";;
						esac
					done
				else 
					echo "Same Coh Thresold as former run. OK... "
			fi
	fi
fi

# Dump Command line used in CommandLine.txt
echo "$(dirname $0)/${PRG} run with following arguments : " > CommandLine_${PRG}_${RUNDATE}_${RNDM1}.txt
echo $@ >> CommandLine_${PRG}_${RUNDATE}_${RNDM1}.txt


echo "// backup ${MODETOCLEAN}"
mkdir -p ${RUNDIR}/${MODETOCLEAN}_Full
# do not cp Raster and RastersPrbml
cp -Rn ${RUNDIR}/${MODETOCLEAN}/*deg ${RUNDIR}/${MODETOCLEAN}_Full/ 
cp -Rn ${RUNDIR}/${MODETOCLEAN}/*.txt ${RUNDIR}/${MODETOCLEAN}_Full/  

echo "// backup ${MODETOCLEAN}.txt as ${MODETOCLEAN}_Full.txt (combined with possible former _Full.txt"
if [ -f "${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt" ] && [ -s "${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt" ] 
	then
		# another list exist yet. Cat both to be sure
		cat ${RUNDIR}/${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt > ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp.txt
		sort ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp.txt | uniq > ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt
		rm -f ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp.txt
	else 
		cp ${RUNDIR}/${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt
fi

# test if already performed a build_header_msbas_criteria.sh since last restrict_msbas_to_Coh.sh :
# search for ${MODETOCLEAN}_NoChoRestrict.txt, which is created by build_header_msbas_criteria.sh as ${MODETOCP}_NoChoRestrict.txt
#if [ -s ${RUNDIR}/${MODETOCLEAN}/${MODETOCLEAN}_NoChoRestrict.txt ]  	then 
#		# former coh threshol filtering was applied. Keep track of all pairs 
#		cp -f ${RUNDIR}/${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp.txt
#
#		cat ${RUNDIR}/${MODETOCLEAN}/${MODETOCLEAN}_NoChoRestrict.txt ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp.txt ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt> ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp2.txt
#		sort ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp2.txt | uniq > ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt
#		rm -f ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp.txt # ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full_tmp2.txt
#	else 
#		cp -f ${RUNDIR}/${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt
#
#fi

cd ${RUNDIR}/${MODETOCLEAN}

# Keep track of coherence table
if [ -f "${RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt" ] && [ -s "${RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt" ] 
	then 
		if [ -f "${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt" ] && [ -s "${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt" ] 
			then 
				cat ${RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt  > ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}_tmp.txt
				sort ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}_tmp.txt | uniq > ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt
				rm -f ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}_tmp.txt
			else 
				mv ${RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt		
		fi
fi

KMLNAME=`basename ${KML}`
# list of files to check - take it from ${MODETOCLEAN}.txt to avoid checking unnecessary files
sort ../${MODETOCLEAN}.txt | uniq > List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt
# get rid of leading path and tailing infos 
${PATHGNU}/gawk -F'/' '{print $2}' List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt > List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}_tmp.txt
${PATHGNU}/gawk -F' ' '{print $1}' List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}_tmp.txt > List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt
rm List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}_tmp.txt

echo "// prepare list of pairs to check (ignoring already checked ones)"
# do only those that are not checked yet
if [ -f "List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt" ] && [ -s "List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt" ]
	then 
		diff --new-line-format="" --unchanged-line-format="" List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt > List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt
		# prepare the list of checked files for next run
		cat  List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt > New_List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt
		sort New_List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt > List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt
		rm New_List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt
		# uodate list of files to ignore at next build_header_msbas_criteria.sh 
		cat List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt > Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header_tmp.txt
		sort Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header_tmp.txt | uniq > Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
		rm -f Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header_tmp.txt
	else 
		# first check
		cp List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt
		# prepare the list of checked files for next run
		mv List_All_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt
		# keep this as generic name in list to be ignored at next build_header_msbas_criteria.sh
		# otherwise build_header_msbas_criteria.sh would add them again and they would be not rejected here. Beware to keep the same threshold and kml
		cp List_Checked_img_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt 

fi

# force discarding pairs that are satisfying Bt and Bp and Coh criteria - may be needed if some pairs are known to be erroneous for whatever reason
# However, lines below might not be enough if pairs are already in Modei.txt. In such a case, run Exclude_Pairs_From_Mode.txt.sh before MSBAS.sh
if [ -f "_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt" ] && [ -s "_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt" ]  
	then 
		echo "// Exclude pairs that are in _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt even if they satisfy the Bt, Bp and Coh criteria "
		mv List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}_WithoutForceExclude.txt 
		${PATHGNU}/grep  -Fv -f _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}_WithoutForceExclude.txt > List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt 
	
fi

echo "// Check coh"
for IMGTOTEST in `cat List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt`
do 
	PAIR=`echo "${IMGTOTEST}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" ` # select _date_date_ where date is 8 numbers
	echo "Pair : ${PAIR}" 
	COHFILE=`ls ${PATHTOCOH} | ${PATHGNU}/grep ${PAIR} | ${PATHGNU}/grep -v .hdr  | ${PATHGNU}/grep -v .ras  | ${PATHGNU}/grep -v .xml` # avoid hdr but also xml if files were open in a gis or ras just in case... 
	CHECKCOH=`getStatForZoneInFile ${PATHTOCOH}/${COHFILE} ${KML}` # gives the mean coh in zone 
	echo "Mean Coh in ${KML}: ${CHECKCOH}"
	TSTREAL=`echo " ${CHECKCOH} > ${COHTHRESHOLD}" | bc -l`
	
	echo "${PAIR}	${CHECKCOH}" >> Coh_Table_${MODETOCLEAN}.txt
		
	if [ ${TSTREAL} -eq 1 ]
		then 
			echo "Mean coherence ${CHECKCOH} is better than ${COHTHRESHOLD}."
			echo "Keep ${IMGTOTEST}" 
		else 
			echo "Mean coherence ${CHECKCOH} is less than ${COHTHRESHOLD}."
			echo "Discard ${IMGTOTEST}"
			echo 
			# remove file from MODEDOCLEAN dir and .txt
			# Keep files in dir to be able to recompute msbas without coh threshold if required. 
			# To do so, just replace ${MODETOCLEAN}.txt with the file that is ${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt
			# rm -f ${RUNDIR}/${MODETOCLEAN}/${IMGTOTEST}
			grep -v ${PAIR} ${RUNDIR}/${MODETOCLEAN}.txt > ${RUNDIR}/${MODETOCLEAN}_tmp.txt
			rm ${RUNDIR}/${MODETOCLEAN}.txt
			mv ${RUNDIR}/${MODETOCLEAN}_tmp.txt ${RUNDIR}/${MODETOCLEAN}.txt
			# keep list of excluded files 
			grep ${PAIR} ${RUNDIR}/${MODETOCLEAN}_Full/${MODETOCLEAN}_Full.txt >> ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp.txt

	fi
done 

if [ -f "${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp.txt" ] && [ -s "${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp.txt" ]
	then
		if [ -f "${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}.txt" ] && [ -s "${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}.txt" ]
			then 
				# merge and sort with possibel existing one
				cat ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp.txt ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}.txt >  ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp2.txt

				sort ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp2.txt | uniq > ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}.txt
				rm ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp.txt  ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp2.txt
			else 
				sort ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp.txt | uniq > ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}.txt
				rm ${RUNDIR}/${MODETOCLEAN}_Full/List_Out_Of_Range_CohThreshold_${COHTHRESHOLD}_in_${KMLNAME}_tmp.txt

		fi
		
fi

# Rebuild table of coh in _Full
if [ -f "${RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt" ] && [ -s "${RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt" ]
	then 
		if [ -f "${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt" ] && [ -s "${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt" ] 
			then 
				cat ${RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt  > ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}_tmp.txt
				sort ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}_tmp.txt | uniq > ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt
				rm -f ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}_tmp.txt
			else 
				mv ${RUNDIR}/${MODETOCLEAN}/Coh_Table_${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full/Coh_Table_${MODETOCLEAN}.txt		
		fi
fi

rm List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}.txt List_ToCheck_For_Coh_${COHTHRESHOLD}_${KMLNAME}_WithoutForceExclude.txt 2>/dev/null

# to avoid confusion, keep only the Out_Of_Range*m_*days.txt in ${RUNDIR}/${MODETOCLEAN} because is the only one to ne complete 
rm ${RUNDIR}/${MODETOCLEAN}_Full/Out_Of_Range*m_*days.txt  2>/dev/null

# Remove old cmd line files 
find ${RUNDIR} -maxdepth 1 -name "CommandLine_*.txt" -type f -mtime +15 -exec rm -f {} \;

echo "-----------------------------------------------------------------"
echo " You better plot a new baseline plot to check your new data base : "
echo " See PlotBaselineGeocMSBAS.sh"
echo "-----------------------------------------------------------------"


