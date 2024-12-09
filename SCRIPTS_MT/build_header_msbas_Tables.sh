#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at :
#		- copy only the deformation maps of pairs that fulfills criteria from 
#			+ a Delaunay table (created with DelaunayTable.sh) or 
#			+ a Shortest Connection table (created with Extract_x_Shortest_Connections.sh) or 
#			+ a Max Bp and Bt table (created with Prepa_MSBAS.sh)  
#		  for each mode. 
#		  Notes:
#			1) Enter the table in the same order as the path to each mode after!! 
#			2) You can mix the type of tables (e.g. mode 1 an be a Delaunay and mode 2 a Shortest connection etc...) 
#			3) To manually ADD pairs to your table, create a list with the same structure as the pair table 
#			   (i.e. 4 col: MAS SLV BP BT, with or without a header), at the same place of your table, 
#			   with the same name, thought ending with _AdditionalPairs.txt rather than .txt
#			   E.g. table_0_0_DelaunayRatio0.3_0_MaxBt400_0.txt ==> table_0_0_DelaunayRatio0.3_0_MaxBt400_0_AdditionalPairs.txt
#			4) To manually REMOVE pairs from your table, create a list with the same structure as the pair table 
#			   (i.e. 4 col: MAS SLV BP BT, with or without a header), at the same place of your table, 
#			   with the same name, thought ending with _ExcludePairs.txt rather than .txt
#			   E.g. table_0_0_DelaunayRatio0.3_0_MaxBt400_0.txt ==> table_0_0_DelaunayRatio0.3_0_MaxBt400_0_ExcludePairs.txt
#		- creating the required list_of_InSAR_files.txt with path to defo files, Bperp, MasDate, SlavDate
#		- creating the header.txt required for the msbas processing
#		- creating hdr files for results
#       - check if files are OK or NaN
#		- it also output files with incidence angle, heading and acquisition time  
#	If former run was operated with a coherence threshold restriction, the script will ignore pairs that were already identified as unsatisfactory. 
#
#  Script must be launched in the dir where msbas will be run. 
#
# Attention, if one update an existing MSBAS processing after having added new interferograms, 
#            ensure that the new links will be made from the same computer as the first build.
#
# Parameters are : 
#       - mode (that is type of products to use such as DefoInterpolx2Detrend; must be the name of the subdir where data are stored)
# 		- nr of modes
#		- a table_0_0_DelaunayRatioxxxMaxBtxxxMaxBpxxx_0.txt table (created with DelaunayTable.sh) 
#		    OR a table_0_0_MaxShortest_x.txt table (created with Extract_x_Shortest_Connections.sh)
#			OR a table_BtMin_BtMax_BpMin_BpMax.txt (created with Prepa_MSBAS.sh for Max Bp and Bt)
#			FOR EACH MODE AND IN THE SAME ORDER AS THE PATH BELOW
#			You can use different type of table for each mode. 
#		- path to each mode
#		- [--msbasvi]: optionally, you ca force the creation of the header file for a given version of msbas. 
#		              If no --msbasvi (either --msbas or --msbasvi where i is a number above 2) is provided, 
#					  the script searches for the most recent version of msbas available on your computer
#					  
#
# ex: build_header_msbas_DelaunayShortest.sh DefoInterpolx2Detrend 2 .../SAR_SM/MSBAS/Region/set1/table_0_20_0_450.txt .../SAR_SM/MSBAS/Region/set2/table_0_0_DelaunayRatio1MaxBt30MaxBp400_0.txt .../SAR_MASSPROCESS/Sat/Region_Asc/Resampled_Primary_CropName_Zoom1_ML4 .../SAR_MASSPROCESS/Sat/Region_Desc/Resampled_Primary_CropName_Zoom1_ML4 
#       
# Dependencies:	- python 
#				- checkOnlyNaN.py script
#				- gnu sed and awk for more compatibility. 
#
###	Header.txt file must be something like 
###		FORMAT = 0 							# use here 0 - small endian, use 1 - big endian if required
###		FILE_SIZE = 1226, 1376  			# lines and columns taken e.g from geocoded defo.hdr 
###		WINDOW_SIZE = 0, 1225, 0, 1375		# can apply crop if required. Attention count start at 0
###		R_FLAG = 2, 0.04					# Rank regularistaion order and Lambda for Thickonov regularisation
###		T_FLAG = 0							# 1= ONLY FOR R_FLAG 0 : remove topo residuals (eg if pix dem >> interfero) ; 0=no
###		C_FLAG = 0							# pixel(s) coordinates of reference region: Nr of ref, line, col of each ref, radius for all ref pix
###												e.g: C_FLAG = 2, 452, 822, 237, 259, 32,32	 
###		I_FLAG = 0							# 0= auto run; 1= ask for coord of pix for time series; 2=takes coord from par.txt file
###												e.g: I_FLAG = 2, par.txt		
### 	 SET = 034122, -191.72, 42.02074792667776040000, DefoInterpolx2Detrend1.txt    # time of acquisition, Az heading, Incid angle, list_of_InSAR_files
#
#
# New in Distro V 1.0:	- Based on build_header_msbas_criteria.sh v 8.0
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20231113:	- typo in AUT 
# New in Distro V 2.2 20231114:	- Definitin of PATHMODE was wrong in loop 
# New in Distro V 2.3 20240423:	- add usage if launched without parameters 
# New in Distro V 2.4 20240704:	- change sign of incidence angle if satellite is Right looking
# New in Distro V 2.5 20240813:	- For Mac OSX, use coreutils fct gnproc instead of sysctl -n hw.ncpu 
# New in Distro V 2.6 20240919:	- remove first empty line (if any) in files before comparing 
#								  with grep -Fvf in order to avoid resulting empty file
#								- make grep -Fvf with fct LinesInFile2NotInFile1, where FILE 1 si sort and uniq for safety

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.6 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 19, 2024"
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# vvv ----- Hard coded lines to check --- vvv 
source $HOME/.bashrc 
# ^^^ ----- Hard coded lines to check -- ^^^ 

	
MODE=$1				# eg Defo, DefoInterpolDetrend or DefoInterpolx2Detrend...
NRMODES=$2			# Nr of modes
# Next parameters are: 
# the path to all the tables, then 
# the path to pairs and geocoded defo files, for each modes (IN THE SAME ORDER as tables)
# [--msbasv] if you want to force preparing the header to a given version. If not it will do it for the most recent version available 

if [ $# -lt 2 ] ; then echo "Usage $0 MODE NRMODES PATH2TABLESxNRModes PATHS2SMxNRModes"; exit; fi

echo ""

# Some functions 
################

# Function to take all lines in FILETOSEARCH that are not in LINESTOSKIP and save in FLITERED
LinesInFile2NotInFile1()
{
	local LINESTOSKIP
	local FILETOSEARCH
	local FLITERED

	LINESTOSKIP=$1
	FILETOSEARCH=$2
	FLITERED=$3

	# just in case...
	sort ${LINESTOSKIP} | uniq > temp.txt
	mv temp.txt ${LINESTOSKIP}

	# remove possible first empty line to avoid prblm with grep -Fvf
	${PATHGNU}/sed -i '1{/^$/d}' ${LINESTOSKIP}
	${PATHGNU}/sed -i '1{/^$/d}' ${FILETOSEARCH}
	# take all lines in FILETOSEARCH that are not in LINESTOSKIP and save in FLITERED
	${PATHGNU}/grep -Fvf ${LINESTOSKIP} ${FILETOSEARCH}  > ${FLITERED}

}

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

# Function to remove the two first lines of a file if it contains the string Master		
RemoveHeader()
	{		
	INPUTFILE=$1
	# Cat table and ADDPAIRSFILE, then remove EXCLUDEPAIRSFILE
	if ${PATHGNU}/ggrep -q "Master" "${INPUTFILE}"
		then
   			tail -n +3 "${INPUTFILE}" > "${INPUTFILE}_NoHeader.txt"
   		else
   			cat "${INPUTFILE}" > "${INPUTFILE}_NoHeader.txt"
	fi
	}

# Function to check if a filename contains dates from a 4 columns file
ContainsDates() 
	{
		local filename="$1"
		local date_pair=$(echo "$filename" | ${PATHGNU}/ggrep -oE '[0-9]{8}_[0-9]{8}')
		if  [[ " ${date12[*]} " =~ " ${date_pair} " ]] || [[ " ${date21[*]} " =~ " ${date_pair} " ]] 
			then
		    	return 0	# success 
		fi
		return 1			# failure
	}
# Function to process each mode
PrepareModeI()
	{
		# Prepare j_th mode
		local HDRMOD
		local MODETOCP
		local MASSPROCESSPATH
		local PATHONLYTABLE 	
		local PATHTABLENAME
		local ADDPAIRSFILE
		local EXCLUDEPAIRSFILE
		local date12
		local date21
		local fields
		local ALL_FILE_NAMES
		local ALL_MATCHING_FILES
		local file_name
		local LINE 
		local FILEONLY
		local MASTERDATE
		local SLAVEDATE
		local PAIR
		local INCIDENCE
		local BPERP
		local HEADREAL
		local HEAD
		local ACQTIME
		local BTEMP
		local PATHRAS
		local FILES_TO_TEST
		local NAN
		local DATEM
		local DATES
		
		i=$1
		
		HDRMOD=`find ${PATHMODE[${i}]} -maxdepth 1 -type f -name "*.hdr"  | head -n 1`	# one envi header file for that mode to get some info
		MODETOCP=`echo $MODE${i}` 			# get only the name without path (that is Defo" and with index, i.e. Defo1)
		MASSPROCESSPATH="$(dirname "$(dirname "$PATHMODE[${i}]")")"  # two levels up; needed for keeping track of possible pairs in table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt
		# Check table with _AdditionalPairs.txt
		PATHONLYTABLE=$(dirname "${PATHTABLE[${i}]}")						# Path to table 
		PATHTABLENAME=`echo "${PATHTABLE[${i}]}" | sed 's/\.[^.]*$//'`		# Path + name of table without last extension

		# Check if a table with same name thought ending with _AdditionalPairs.txt and not empty does exist
		if [ -f "${PATHTABLENAME}_AdditionalPairs.txt" ] && [ -s "${PATHTABLENAME}_AdditionalPairs.txt" ] 
			then
				echo "//  Will add pairs from ${PATHTABLENAME}_AdditionalPairs.txt for ${MODETOCP}"
				ADDPAIRSFILE="${PATHTABLENAME}_AdditionalPairs.txt"
			else 
				echo "//  No _AdditionalPairs.txt files for ${MODETOCP}"
				if [ ! -f "${PATHONLYTABLE}/dummy_empty_file_to_kill.txt" ] ; then touch "${PATHONLYTABLE}/dummy_empty_file_to_kill.txt" ; fi
				ADDPAIRSFILE="${PATHONLYTABLE}/dummy_empty_file_to_kill.txt"
		fi
		# Check if a table with same name thought ending with _ExcludePairs.txt and not empty does exist
		if [ -f "${PATHTABLENAME}_ExcludePairs.txt" ] && [ -s "${PATHTABLENAME}_ExcludePairs.txt" ] 
			then
				echo "//  Will exclude pairs from ${PATHTABLENAME}_ExcludePairs.txt for ${MODETOCP}"
				EXCLUDEPAIRSFILE="${PATHTABLENAME}_ExcludePairs.txt"
			else 
				echo "//  No _ExcludePairs.txt files for ${MODETOCP}"
		fi
		echo
		cd ${MODETOCP}
		
		#Remove the 2 lines header from the 3 tables if they contains one, i.e. if they contains the string Master (tables are named _NoHeader.txt)
		RemoveHeader ${PATHTABLE[${i}]}

		# Add pairs if any must be forced...
		if [ -f "${ADDPAIRSFILE}" ] && [ -s "${ADDPAIRSFILE}" ] 
			then 
				RemoveHeader ${ADDPAIRSFILE} 
				# cat the table and the pairs to add, wort and uniq
				sort ${PATHTABLE[${i}]}_NoHeader.txt ${ADDPAIRSFILE}_NoHeader.txt | uniq > TABLETOPROCESS_tmp${i}.txt
				rm -f ${PATHTABLE[${i}]}_NoHeader.txt ${ADDPAIRSFILE}_NoHeader.txt
			else
				mv -f ${PATHTABLE[${i}]}_NoHeader.txt TABLETOPROCESS_tmp${i}.txt
		fi
		
		# Remove pairs that are in exclude
		if [ -f "${EXCLUDEPAIRSFILE}" ] && [ -s "${EXCLUDEPAIRSFILE}" ] 
			then 
				RemoveHeader ${EXCLUDEPAIRSFILE}
				${PATHGNU}/gawk 'NR == FNR { values[$1,$2] = 1; values[$2,$1] = 1; next } !($1,$2) in values && !($2,$1) in values' ${EXCLUDEPAIRSFILE}_NoHeader.txt TABLETOPROCESS_tmp${i}.txt > TABLETOPROCESS_${i}.txt
				rm -f TABLETOPROCESS_tmp${i}.txt # do not remove rm -f ${EXCLUDEPAIRSFILE}_NoHeader.txt now
			else 
				mv -f TABLETOPROCESS_tmp${i}.txt TABLETOPROCESS_${i}.txt
		fi
		
		# Now one must find all deformation maps that contains mas_slv or slv_mas in their name where mas and slv are numbers from the two first col of TABLETOPROCESS_${i}.txt
		# Read the date columns from TABLETOPROCESS_${i}.txt into an array
		date12=()
		date21=()
		while read -r DATE1 DATE2 dummy dummy 
		do
		    date12+=("${DATE1}_${DATE2}")
		    date21+=("${DATE2}_${DATE1}")
		done < "TABLETOPROCESS_${i}.txt"

		
		# List files from ${PATHMODE[${i}] sub dir where the deformation maps named *deg are stored 
		ALL_FILE_NAMES=("${PATHMODE[${i}]}"/*deg)

		# Find files with matching dates
		echo "  // Searching for deformation files consistant with provided table(s): "		

		# To simulate random rotating bar
		chars=("-" "/" "\\" "|")

		ALL_MATCHING_FILES=()
		for file_name in "${ALL_FILE_NAMES[@]}"; do
		    if ContainsDates "${file_name}"
		    	then
		        	echo "Selected in input table: ${file_name}"
		        	
		        	# Variable with list of matching files
		        	ALL_MATCHING_FILES+=("${file_name}")
		        			        	# File with full path from SAR_MASSPROCESS/.../deformationMap.....deg
		        	echo "${file_name}" >> ${MODETOCP}.txt
		        	basename "${file_name}" >> ${MODETOCP}_NoPath.txt
		        else 
				    random_char="${chars[RANDOM % ${#chars[@]}]}"
    				echo -ne "Searching: $random_char	\r"
		       # 	echo "Not selected in input table: ${file_name}"
		    fi
		done
		# clean rotating bar
		echo -ne "\033[K"
		
		# Get only the new ones
		if [ -f ../${MODETOCP}.txt ] 
			then
				# new security in case of previous crash
				sort ../${MODETOCP}.txt | uniq > ../${MODETOCP}_tmp.txt
				${PATHGNU}/gawk 'NF>=4' ../${MODETOCP}_tmp.txt > ../${MODETOCP}.txt	
				rm -f ../${MODETOCP}_tmp.txt
	
				# previous MSBAS already prepapred. Check only new entries and remove from ${MODETOCP}.txt the entries already processed
				# First trim MODE from beginning of each line in ../${MODETOCP}.txt
				${PATHGNU}/gsed -i "s%.*${MODE}${i}\/%%g" ../${MODETOCP}.txt  # remove all up to /Defo/ included, i.e. with no path but still with Bp and dates
	
				# keep only what is not in ../${MODETOCP}.txt to which we have removed path and info about dates and baselines
				cp ../${MODETOCP}.txt _tmps_Processes_pairs.txt
				${PATHGNU}/gsed -i "s%deg .*%deg%g" _tmps_Processes_pairs.txt  # remove trailing infos about date and baselines	(was already without path)
	
				sort _tmps_Processes_pairs.txt | uniq > _tmps_Processes_pairs_sorted.txt 						# i.e. info from existing MODEi.txt
	
					#Check first that files listed in ../${MODETOCP}.txt cleaned, that is _tmps_Processes_pairs.txt, are the same as those in /MODEi
					#find . -maxdepth 1 -type l -name "*deg" -print | while read filename ; do basename "${filename}" ; done >  _files_in_${MODE}${i}_NoPath.txt 
					ls | ${PATHGNU}/grep "deg" > _files_in_${MODE}${i}_NoPath.txt 
					sort  _files_in_${MODE}${i}_NoPath.txt | uniq >  _files_in_${MODE}${i}_NoPath_sorted.txt 	# i.e. info from existing MODEi dir
	
					rm _files_in_${MODE}${i}_NoPath.txt
					# take all lines in FILE2 that are not in FILE1 and save in FILE3
					#${PATHGNU}/grep -Fvf _files_in_${MODE}${i}_NoPath_sorted.txt _tmps_Processes_pairs_sorted.txt  > _Files_Not_In_Dir_but_in_${MODE}${i}.txt
					LinesInFile2NotInFile1 "_files_in_${MODE}${i}_NoPath_sorted.txt" "_tmps_Processes_pairs_sorted.txt" "_Files_Not_In_Dir_but_in_${MODE}${i}.txt"
					
					${PATHGNU}/gsed -i "s%^%${PATHMODE}\/%g"  _Files_Not_In_Dir_but_in_${MODE}${i}.txt # add again the path at beginning of each line
					#diff _files_in_${MODE}${i}_NoPath_sorted.txt _tmps_Processes_pairs_sorted.txt | ${PATHGNU}/grep "deg" | ${PATHGNU}/gsed s/\>//g | ${PATHGNU}/gsed s/\<//g
					rm  _tmps_Processes_pairs.txt _files_in_${MODE}${i}_NoPath_sorted.txt
	
				sort ${MODETOCP}_NoPath.txt | uniq > ${MODETOCP}_NoPath_sorted.txt
				rm 	${MODETOCP}_NoPath.txt 		

				# take all lines in FILE2 that are not in FILE1 and save in FILE3
				#${PATHGNU}/grep -Fvf _tmps_Processes_pairs_sorted.txt ${MODETOCP}_NoPath_sorted.txt > ${MODETOCP}_NoPath_only_new.txt
				LinesInFile2NotInFile1 "_tmps_Processes_pairs_sorted.txt" "${MODETOCP}_NoPath_sorted.txt" "${MODETOCP}_NoPath_only_new.txt"
				
				rm  ${MODETOCP}_NoPath_sorted.txt _tmps_Processes_pairs_sorted.txt 
				
				${PATHGNU}/gsed -i "s%^%${PATHMODE}\/%g"  ${MODETOCP}_NoPath_only_new.txt # add again the path at beginning of each line
				mv -f  ${MODETOCP}_NoPath_only_new.txt ${MODETOCP}.txt
				
				if [ -f "_Files_Not_In_Dir_but_in_${MODE}${i}.txt" ] && [ -s "_Files_Not_In_Dir_but_in_${MODE}${i}.txt" ] 
					then 
						cat _Files_Not_In_Dir_but_in_${MODE}${i}.txt ${MODETOCP}.txt > ${MODETOCP}_tmp.txt 
						sort ${MODETOCP}_tmp.txt | uniq > ${MODETOCP}.txt 
						rm -f ${MODETOCP}_tmp.txt
				fi
				# hence ${MODETOCP}.txt contains now the Out_of_Range and the new ones to process (with partial path and no tailing info about baselines)
				rm _Files_Not_In_Dir_but_in_${MODE}${i}.txt
			else 
				# No previous MSBAS prepapred. Process all entries in ${MODETOCP}.txt
				echo "First MSBAS preparation for this mode"
		fi

		# To speed up : 
		# If already checked against Coh threshold, some out of range lines are identified. 
		# Before removing them from the list of pairs to reprocess, one may need to keep some out of range:
		# Remove from Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt each line that contains out of range pairs that were however asked to be 
		# maintained because they would for instance complete the baselineplot. 
		# Such a list of out-of-range pairs to keep must be listed in ${MASSPROCESSPATH}/table_0_${MAXBP}_0_${MAXBT}_AdditionalPairs.txt. 
		# Not sure it is worth to do this however for coh... 
		# Remove from ${MODETOCP}.txt each line that contains what is in lines of Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
		#-----------------------------------------------------------------------------------------------
		
		# Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt contains 1 col with file name but without any path 
		if [ -f Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt ] && [ -s Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt ]    # Do not look at version in MODETOCP_Full because it does not contains the last pairs checked 
			then
				mv ${MODETOCP}.txt ${MODETOCP}_NoChoRestrict.txt
				# remove possible pairs out of range that are in SAR_SM/MSBAS/region/seti/table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt (also in SAR_MASSPROCESS)
				# This may be dangerous though because it would force to keep pairs with low level of coh. Not sure if we shoudl offer that possibility...  May be wise to remove? 
				if [ -f "${ADDPAIRSFILE}" ] && [ -s "${ADDPAIRSFILE}" ]
					then
						# remove pairs from Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
						while read -r MASDATEFORCE SLVDATEFORCE dummy1 dummy2 
							do	
							# remove lines with string ${MASDATE}_${SLVDATE} in out of range
							${PATHGNU}/gsed -i "/${MASDATEFORCE}_${SLVDATEFORCE}/d" Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
						done < ${ADDPAIRSFILE} 
	
				fi 		
				
				# take all lines in FILE2 that are not in FILE1 and save in FILE3
				#${PATHGNU}/grep -Fv -f Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt ${MODETOCP}_NoChoRestrict.txt > ${MODETOCP}.txt 
				LinesInFile2NotInFile1 "Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt" "${MODETOCP}_NoChoRestrict.txt" "${MODETOCP}.txt"
				
				# do not remove ${MODETOCP}_NoChoRestrict.txt
		fi	

		# CREATES THE .TXT FILE
	 	for LINE in `cat -s ${MODETOCP}.txt`
	 	do
			# Proceed if a CPU is free 
			if test "$(jobs | wc -l)" -ge ${CPU} 
				then
					case ${OS} in 
						"Linux") 
							wait -n 	;;
						"Darwin")
							waitn		;;
					esac	
			fi
			# Run tests in pseudo parallelism
			{
	
	  		#LINENOPATH=`echo ${LINE} | ${PATHGNU}/gawk -F '/' '{print $NF}'` 	# Line with file name as deformationMap.....deg without path
	 		FILEONLY=`echo ${LINE} | ${PATHGNU}/gawk -F '/' '{print $NF}'` 	# Line with file name as deformationMap.....deg without path
	 
	 		MASTERDATE=`echo ${LINE} | ${PATHGNU}/grep -oP '\D+\K\d+' | ${PATHGNU}/gsed -n '/[0-9]\{8\}/p' | head -2  | tail -1`
	 		SLAVEDATE=`echo ${LINE} | ${PATHGNU}/grep -oP '\D+\K\d+' | ${PATHGNU}/gsed -n '/[0-9]\{8\}/p' | tail -1`
	 
			PAIR=`echo ${ROOTPATH[${i}]}/*${MASTERDATE}*_*${SLAVEDATE}*`	# path up to DateMaster_DateSlave  
	 
	 		INCIDENCE=`updateParameterFile ${PAIR}/i12/TextFiles/masterSLCImageInfo.txt "Incidence angle at median slant range"`
			LOOKDIR=`updateParameterFile ${PAIR}/i12/TextFiles/masterSLCImageInfo.txt "Look direction"` 
 
	 		BPERP=`updateParameterFile ${PAIR}/i12/TextFiles/InSARParameters.txt "Perpendicular baseline component at image centre"` 
	 
	 		HEADREAL=`updateParameterFile ${PAIR}/i12/TextFiles/masterSLCImageInfo.txt "Azimuth heading"` 
	 		HEAD=`echo ${HEADREAL} | cut -d . -f 1 `
	 
	 		# Heading in CSL is counted conterclockwize from East. Transform in azimuth from North
	 		if [ "${HEAD}" -ge "245" ] 
	 			then # hence it is Descending (probably around 257)
	 				HEAD=`echo "90 - ${HEAD}" | bc`
	 			else # hence it is Ascending, (probably around 100) 
	 				HEAD=`echo "360 - ${HEAD} + 90" | bc`
	 		fi
	 
	 		# get AcquisitionTime from file
	 		ACQTIME=`updateParameterFile ${PAIR}/i12/TextFiles/masterSLCImageInfo.txt "Acquisition time" | tr -dc '[0-9]'` 
	 
	 		# get dates images as yyyy , mm , dd
	 		BTEMP=`updateParameterFile ${PAIR}/i12/TextFiles/InSARParameters.txt "Temporal baseline [day]"` 
	 
	 				# Dump incidence angle if one wants to do some statistics
	 				echo  ${INCIDENCE} >> ../IncidenceAngles_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
	 				echo  ${LOOKDIR} >> ../LookDirection_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
	 				
	 				# Dump heading if one wants to do some statistics
	 				echo  ${HEAD} >> ../Heading_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
	 	
	 				# Dump Acquisition time 
	 				echo  ${ACQTIME} >> ../AcquisitionTime_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
	 
	 				# copy also rasters for check
	 				PATHRAS=${MASSPROCESSPATH}/GeocodedRasters/${MODE}
	 
	 				# get the target of link because numpy does not like links...
	 				# LINE is not a link 
	 				NAN=`checkOnlyNaN.py ${PATHMODE}/${FILEONLY} float32`
	 				if [ "${NAN}" == "nan" ]
	 					then 
	  						ln -s ${PATHRAS}/${FILEONLY}.ras PrblmRasters/${FILEONLY}.ras 
	  						ln -s ${PATHMODE}/${FILEONLY} PrblmRasters/${FILEONLY}
	  						echo "  // Do not copy ${LINE}"
	  						echo "  //   because full of NaN - reprocess if possible."
	  					else 
	 						if [ ! -f Rasters/${FILEONLY}.ras ] ; then ln -s ${PATHRAS}/${FILEONLY}.ras Rasters/${FILEONLY}.ras ; fi
	 						if [ ! -f ${FILEONLY} ] 
	 							then 
	 								ln -s ${PATHMODE}/${FILEONLY} ${FILEONLY} 
	 								echo "${LINE} copied (link)" 
	 								# put in file
	 								if [ ${MASTERDATE} -lt ${SLAVEDATE} ] 
	 									then
	 										echo "${LINE} ${BPERP} ${MASTERDATE} ${SLAVEDATE}" >> ../${MODETOCP}.txt
	 									else 
											echo "Secondary date appears before Primary date. I guess you are dealing with non S1 WS and using a pair with the Global Primary (SuperMaster)..."
	 										echo "${LINE} ${BPERP} ${SLAVEDATE} ${MASTERDATE}" >> ../${MODETOCP}.txt
	 								fi
	 							else 
	 								echo "${LINE} exist"
	 								# Because ../${MODETOCP}.txt was reset, must write it here again 
	 								echo "${LINE} ${BPERP} ${SLAVEDATE} ${MASTERDATE}" >> ../${MODETOCP}.txt
	 						fi
	 						
	 				fi

			} &
		done 
		wait 	
	

		rm ${MODETOCP}.txt
		cd ..
		${PATHGNU}/gsed -i "s%.*\/${MODE}${i}\/%%g" ${MODETOCP}.txt  # remove all up to /Defo$i/ included	
		${PATHGNU}/gsed -i "s%.*\/${MODE}\/%%g" ${MODETOCP}.txt  # remove all up to /Defo/ included	
		${PATHGNU}/gsed "s%^%${MODE}${i}\/%g" ${MODETOCP}.txt > ${MODETOCP}_tmp.txt # add Defo$j/ at beginning of each line
		sort ${MODETOCP}_tmp.txt | uniq > ${MODETOCP}.txt
		rm -f ${PATHONLYTABLE}/dummy_empty_file_to_kill.txt ${MODETOCP}_tmp.txt 	2>/dev/null
		
		# in case of re-processing and remove pairs that were previously accepted, one must remove them again from ../${MODETOCP}.txt
		if [ -f "${EXCLUDEPAIRSFILE}" ] && [ -s "${EXCLUDEPAIRSFILE}" ] 
			then 
				while read -r DATE1 DATE2 dummy dummy 
				do
					# search MAS and SLV date 
					if [ "${DATE1}" -gt "${DATE2}" ] 
						then 
							DATEM="${DATE2}"  
							DATES="${DATE1}" 
						else   
							DATEM="${DATE1}" 
							DATES="${DATE2}" 
					fi
					# remove lines from ../${MODETOCP}.txt which contains "MAS SLV"  (do not search in file name as it can be reversed) 
					grep -v "${DATEM} ${DATES}" ${MODETOCP}.txt > ${MODETOCP}_tmp.txt
					mv -f ${MODETOCP}_tmp.txt ${MODETOCP}.txt
				done < "${EXCLUDEPAIRSFILE}_NoHeader.txt"
				rm -f ${EXCLUDEPAIRSFILE}_NoHeader.txt
		fi	
		
	}

# Let's go
##########

# Check if the number of parameters is even (not taking into account the optional version of msbas parameter)
# to ensure that the nr of tables is the same as the path to geocoded products 
	# Initialize a flag to check if "--msbasv" parameter is present
	msbasv_found=false
	
	# Iterate through the parameters
	for param in "$@"; do
		if [[ "$param" == "--msbas"* ]]
			then
				# exclude that param from the counting of param
				msbasv_found=true
				# assign version of msbas
				MSBAS=`echo "${param}" | cut -d - -f3`
				echo "  // You requested to prepare the header.txt for the specific version of ${MSBAS}"
		fi
	done
	echo "  // Ensure to run MSBAS.sh with the same version of msbas."

	if [ "$msbasv_found" = true ]
		then
	
			# Exclude the "--msbasv" parameter from the count
			num_params=$(($# - 1))
			
			if [ $(($num_params % 2)) -eq 0 ]
				then
					echo "  // OK: same nr of tables and paths."
				else
					echo "  // The number of tables and paths seems different, please check. "
					echo "Usage $0 MODE NR_OF_MODES PATH_TO_ALL_TABLES PATH_TO_ALL_GEOCODED "
					echo "  // Also, ensure that the path to tables are entered in the same order as the path to geocoded products"
					echo "Exiting..."
					exit
			fi
		else
			# assign version of msbas
			LastMsbasV
			echo "  // Header.txt will be prepared for the last version of msbas available on your computer, that is ${MSBAS}"

			if [ $# -eq 0 ]; then
					echo "No parameters provided. Exiting..."
					exit
				elif [ $(($# % 2)) -eq 0 ]; then
					echo "  // OK: same nr of tables and paths."
				else
					echo "  // The number of tables and paths seems different, please check. "
					echo "Usage $0 MODE NR_OF_MODES PATH_TO_ALL_TABLES PATH_TO_ALL_GEOCODED"
					echo "  // Also, ensure that the path to tables are entered in the same order as the path to geocoded products"
					echo "Exiting..."
					exit
			fi
	fi

RNDM1=`echo $(( $RANDOM % 10000 ))`

# Dump Command line used in CommandLine.txt
echo "$(dirname $0)/${PRG} run with following arguments : \n" > CommandLine_${PRG}_${RNDM1}.txt
index=1 
for arg in $*
do
  echo "$arg" >> CommandLine_${PRG}_${RNDM1}.txt
  let "index+=1"
done 


# To speed up, make first all dirs and index the tables with i index accordingly
for ((i=1;i<=${NRMODES};i++));
do 
	n=`expr "${i}" + ${NRMODES} + 2`;	# Start counting from NRMODES+2 because 2 first parameters and the NRMODES tables are not mode paths, i.e. $n = is path to 1st mode, $n+1= 2nd mode etc... 
	ROOTPATH[${i}]=${!n}
	PATHMODE=${!n}/Geocoded/${MODE}		# path to dir where defo maps of ith mode are stored : e.g. /Volumes/hp-D3600-Data_Share1/SAR_MASSPROCESS/CSK/Virunga_Asc/Resampled_20120702_Crop_NyigoCrater_-1.520_-1.540_29.200_29.220_Zoom1_ML4/Geocoded/Defo 
	PATHMODE[${i}]=${PATHMODE}			# same as before but named with an index for further call
	HDRMOD=`find ${PATHMODE} -maxdepth 1 -type f -name "*.hdr"  | head -n 1`	# one envi header file for that mode to get some info
	#HDRMOD=`ls ${PATHMODE}/*.hdr | head -n 1`	# one envi header file for that mode to get some info 
	MODETOCP=`echo $MODE${i}` 			# get only the name without path (that is Defo" and with index, i.e. Defo1)

	mkdir -p ${MODETOCP}
	
	cd ${MODETOCP}
	mkdir -p Rasters
	mkdir -p PrblmRasters
	
	cd ..

	m=`expr "${i}" + 2`;			# Start counting from +2 because 2 first parameters are not table paths, i.e. $m = is path to 1st table, $n+1= 2nd table etc... 
	PATHTABLE=${!m}
	PATHTABLE[${i}]=${PATHTABLE}	# path to table with an index for further call

done


# pseudo parallel by running on all but one CPU (fatser than gnuparallel) 
#-------------------------------------------------------------------------
# test nr of CPUs
# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		NCPU=`nproc` 	;;
	"Darwin")
		#NCPU=`sysctl -n hw.ncpu` 
		NCPU=$(gnproc)
		
		# must define a function because old bash on Mac does not know wait -n option
		waitn ()
			{ StartJobs="$(jobs -p)"
			  CurJobs="$(jobs -p)"
			  while diff -q  <(echo -e "$StartJobs") <(echo -e "$CurJobs") >/dev/null
			  do
			    sleep 1
			    CurJobs="$(jobs -p)"
			  done
			}
		
		;;
esac			

CPU=$((NCPU-1))
echo "Run max ${CPU} processes at a time "

# Prepare Modei dirs and Modei.txt files based on Tables  
for ((i=1;i<=${NRMODES};i++));
do 
	n=`expr "${i}" + ${NRMODES} + 2`;	# Start counting from NRMODES+2 because 2 first parameters and the NRMODES tables are not mode paths, i.e. $n = is path to 1st mode, $n+1= 2nd mode etc... 
	ROOTPATH[${i}]=${!n}
	PATHMODE=${!n}/Geocoded/${MODE}		# path to dir where defo maps of ith mode are stored : e.g. /Volumes/hp-D3600-Data_Share1/SAR_MASSPROCESS/CSK/Virunga_Asc/Resampled_20120702_Crop_NyigoCrater_-1.520_-1.540_29.200_29.220_Zoom1_ML4/Geocoded/Defo 
	PATHMODE[${i}]=${PATHMODE}			# same as before but named with an index for further call

	echo "  // Start mode ${i}"
	echo "  //   with: ${PATHMODE[${i}]}"
	echo "  //   with: ${PATHTABLE[${i}]}"

	PrepareModeI ${i} &

done

wait


# Header.txt 
rm -f header.txt
NRLINES=`${PATHGNU}/grep "Samples" ${HDRMOD} | cut -c 9-30 | tr -dc '[0-9].' `
NRCOLMSS=`${PATHGNU}/grep "Lines" ${HDRMOD} | cut -c 9-30 | tr -dc '[0-9].' `
WINLINES=`expr "$NRLINES" - 1`
WINCOLMS=`expr "$NRCOLMSS" - 1`
echo 	"FORMAT = 0" 	> header.txt 			# Small/Big endian
echo	"FILE_SIZE = ${NRLINES}, ${NRCOLMSS}"  >> header.txt
echo	"WINDOW_SIZE = 0, ${WINLINES}, 0, ${WINCOLMS}"  >> header.txt
echo	"R_FLAG = 2, 0.02"  >> header.txt  		# Lambda for Thickonov regularisation
echo	"T_FLAG = 0"  >> header.txt  	# 1=remove topo residuals (eg if pix dem >> interfero) ; 0=no
echo	"C_FLAG = 10"  >> header.txt  		# pixel(s) coordinates of reference region: Nr of ref, line, col of each ref, radius for all ref pix, e.g: C_FLAG = 2, 452, 822, 237, 259, 32,32
if [ "${MSBAS}" == "msbasv4" ] ; then echo 	"V_FLAG=0"   >> header.txt ; fi		#  V_FLAG=0 - compute displacement time series as before and V_FLAG=1 - compute velocity time series, in this case linear rate is acceleration.
#echo	"TAV_FLAG = 0"  >> header.txt		# Gausian filtering in temporal domain; 0 = off or width of Gauss. Win. (in yrs)
echo	"I_FLAG = 0"  >> header.txt  		# 0= auto run; 1= ask for coord of pix for time series; 2=takes coord from par.txt file, 	e.g: I_FLAG = 2, par.txt	

# For each mode, set Az heading, Incid angle, list_of_InSAR_files
for ((i=1;i<=${NRMODES};i++));
do 
	# Remove white lines before computing average
	${PATHGNU}/gsed -i ' /^$/d' IncidenceAngles_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt
	${PATHGNU}/gsed -i ' /^$/d' Heading_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt
	${PATHGNU}/gsed -i ' /^$/d' AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt
	
	AVGINCID[${i}]=`${PATHGNU}/gawk '{ total += $1 } END { print total/NR }' IncidenceAngles_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt`
	AVGHEAD[${i}]=`${PATHGNU}/gawk '{ total += $1 } END { print total/NR }' Heading_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt `

	# Change time in sec for average computation
	cat AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt | ${PATHGNU}/gawk '{gsub(/../, "& ",$1); split($1, a, FS); print (a[1] * 3600) + (a[2] *60) + a[3]}' > AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days_InSec.txt
	# Get average time in sec
	ACQTIMESEC[${i}]=`${PATHGNU}/gawk '{ total += $1 } END { print total/NR }' AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days_InSec.txt`
	# back in hhmmss
	ACQTIME[${i}]=`echo "${ACQTIMESEC[${i}]}" | awk  '{ h = int($1 / 3600) ; m = int((($1 / 3600)-h ) * 60) ; sec = int($1 - ((3600 * h ) + ( 60 * m))) ; printf("%02d%02d%02d\n", h, m, sec) }'`  # ensure that all a integer and 2 digits long

	rm -f AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days_InSec.txt

	# Check if Right or Left looking
	# get one image in mode 
	sort -u LookDirection_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt -o LookDirection_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt	# sort and remove duplicate lines in LookDirection file.
	# I suppose that all acquisition are taken in the same looking geom, hence one can take the first line of the supposed one line LookDirection_... file 
	LOOKDIR=`head -1 LookDirection_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt` 
	
	if [ "${LOOKDIR}" == "Left looking" ] 
		then 
			AVGINCID[${i}]="-${AVGINCID[${i}]}"
	fi


	case ${MSBAS} in 
		msbasv4)
			#msbasv4 (> Oct 2020) needs	
			#	SET=0, ${ACQTIME[${i}]}, ${AVGHEAD[${i}]}, ${AVGINCID[${i}]}, ${MODE}${i}.txt - for insar range measurements
			#   SET=1, ${ACQTIME[${i}]}, ${AVGHEAD[${i}]}, ${AVGINCID[${i}]}, ${MODE}${i}.txt - for insar azimuth measurements
			echo "SET = 0, ${ACQTIME[${i}]}, ${AVGHEAD[${i}]}, ${AVGINCID[${i}]}, ${MODE}${i}.txt"  >> header.txt 
			;;
		*)
			echo "SET = ${ACQTIME[${i}]}, ${AVGHEAD[${i}]}, ${AVGINCID[${i}]}, ${MODE}${i}.txt"  >> header.txt
			;;
	esac
done

# Dump a header file for further uses : 
cp ${HDRMOD} HDR.hdr

# remove old logs > MAXLOG defined below (in days), e.g. 60 days or any other value
MAXLOG=30
find . -maxdepth 1 -name "CommandLine_build_header_msbas_criteria.sh_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;


echo "May want to make a baseline plot for each mode. See PlotBaselineGeocMSBAS.sh"
echo "May want to check if no defo file are empty. See Check_Interfero_Not_Empty_In_Zone.sh"


