#!/bin/bash
######################################################################################
# This script will check all directories in a RESAMPLED dir to verify the presence of 
#  - the resampled data for each image if it is not S1-IW, or 
#  - presence of slantRangeDEM in each image in SAR_CSL if it is S1-IW.
# 
# It will print - the total number of .csl images found in the input RESAMPLED folder, 
#               - the total number of missing Data or empty pair folders (for non S1-IW) or missing slantRangeDEM file (for S1-IW) 
# 		and which images are wrong (empty .csl or missing slantRangeDEM)
#
#
# Parameters: - full path to directory to test where RESAMPLED data are stored, e.g. 
#				/.../SAR_SM/RESAMPLED/YourSat/YourRegionTrak
#
# Dependencies:	- updateParameterFile from AMSTer Engine
#
# New in Distro V 1.0 20251125
# New in Distro V 2.0 20251127 (NdO):	- add check for S1-IW data
#										- check that non S1-IW dir are not empty
#										- store wrong resampled data in file
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2025, Last modified on Nov 25, 2025" 
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo " "

modedir="$1"

pf_root="${modedir}"

# Check that the PF_<mode> directory exists
	[ -d "$pf_root" ] || { echo "No such directory: $pf_root"; exit 1; }

# Firs check the type of satellite
	# Get the first matching masterSLCImageInfo.txt that allows to check the sat and mode
	MASINFO=$(${PATHGNU}/find ${modedir} -type f -path "*/i12/TextFiles/masterSLCImageInfo.txt" -print -quit)
	
	# Get the Sat name
	SAT=$(updateParameterFile ${MASINFO} "Sensor ID")
	# If S1, check mode (IW or SM)
	if [[ ${SAT} == S1* ]]
		then 
			scene_id=$(updateParameterFile ${MASINFO} "Scene ID")
			
  			if [[ -z "$scene_id" ]]
  				then
  			  		echo "Scene ID token not found in ${MASINFO}; it shouldn't happen ; exit"
  			  		exit 1
  			fi

  			# Extract the string between the first and second underscore
  			# e.g. from S1B_IW_SLC__1SDV... -> first remove up to first _, then take up to next _
  			mode=${scene_id#*_}    # remove up to first underscore -> IW_SLC__1SDV...
  			mode=${mode%%_*}      # remove from second underscore onward -> IW

			echo "Satellite is:	${SAT}"
			SAT="S1"
			echo "Mode is:	${mode}"
	else
		echo "Satellite is: ${SAT}"
	fi

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
eval RNDM1=`echo $(( $RANDOM % 10000 ))`

# Check existance of slantRangeDEM (and slantRangeMask) if SI-IW, or img.csl/Data otherwise
	if [ "${SAT}" == "S1" ] && [ "${mode}" == "IW" ]
		then 
			INSARINFO=$(${PATHGNU}/find ${modedir} -type f -path "*/i12/TextFiles/InSARParameters.txt" -print -quit)
			MASPATH=$(updateParameterFile ${INSARINFO} "Master image file path")
			#eval ROOTMASPATH="$(dirname "${MASPATH}")"
			ROOTMASPATH=$(dirname "$(envsubst <<< "$MASPATH")")	# less dangerous than eval
			
			echo "------------------------------------------------------------------"
			echo "Searching for slantRangeDEM in : ${ROOTMASPATH}/img.csl/Data"
			echo "------------------------------------------------------------------"
			
			count_total=0
			count_missing=0
			
			# Read results in the main shell (no subshell ; counters work)
			while IFS= read -r -d '' DEM; do
			    count_total=$((count_total + 1))
			
			    if [ ! -f "$DEM/externalSlantRangeDEM" ]; then
			        echo "Missing externalSlantRangeDEM in: $DEM"
			        echo "Missing externalSlantRangeDEM in: $DEM" >> ${modedir}/_Wrong_Coreg_Pairs_${RUNDATE}_${RNDM1}.txt
			        count_missing=$((count_missing + 1))
			        
			    fi
			done < <(${PATHGNU}/find "${ROOTMASPATH}" -maxdepth 2 -type d -path "*.csl/Data" -print0 )
			
			echo "------------------------------------------------------------------"
			echo " Total Img.csl folders found:     $count_total"
			echo " Nr of Img.csl folders missing Data/slantRangeDEM file:  $count_missing"
			echo "------------------------------------------------------------------"
			echo "------------------------------------------------------------------"
			echo		
		else 
			echo ""
			echo "Searching for .csl folders without a 'Data' directory in: $pf_root"
			echo "------------------------------------------------------------------"
			
			count_total=0
			count_missing=0

			rm -f "${modedir}/_Wrong_Coreg_Pairs.txt"
			
			# Read results in the main shell (no subshell ; counters work)
			while IFS= read -r -d '' PATHTOPAIR; do
				PAIR=$(basename "${PATHTOPAIR}") 
			    if [[ "${PAIR}" != *ModulesForCoreg* && "${PAIR}" != *Ampli_Img_Reduc* ]]
			    	then 
			    		count_total=$((count_total + 1))
		
        				# Check if PATHTOPAIR dir contains no sub dirs: 
						if [ -d "${PATHTOPAIR}" ] && ! ${PATHGNU}/find "${PATHTOPAIR}" -mindepth 1 -type d -print -quit | grep -q .
							then
						    	echo "Resampled pair dir contains no subdirectories: ${PATHTOPAIR} "
						    	echo "Resampled pair dir contains no subdirectories: ${PATHTOPAIR} " >> ${modedir}/_Wrong_Coreg_Pairs_${RUNDATE}_${RNDM1}.txt
						    	count_missing=$((count_missing + 1))
							else
			    				# check if contains Data
			    				if [ -d "${PATHTOPAIR}" ] && ! ${PATHGNU}/find "${PATHTOPAIR}" -mindepth 4 -type d -name "Data" -print -quit | grep -q .
			    					then 
			    				    	SLV=$(echo "${PAIR}" | cut -d _ -f 2)
			    				    	echo "Missing Data/ in: $PATHTOPAIR/i12/InSARProducts/${SLV}.csl"
			    				    	echo "Missing Data/ in: $PATHTOPAIR/i12/InSARProducts/${SLV}.csl" >> ${modedir}/_Wrong_Coreg_Pairs_${RUNDATE}_${RNDM1}.txt
			    				    	count_missing=$((count_missing + 1))
			    				fi
						fi
					#else 
			    	#	echo "Skip check dir ${PATHTOPAIR}"
				fi
			done < <(${PATHGNU}/find "$pf_root" -maxdepth 2 -type d -path "*/SM*Crop*SM_*/*" -print0 )		# search all pair dirs
			
			echo "------------------------------------------------------------------"
			echo " Total Img.csl folders found:     $count_total"
			echo " Nr of Img.csl folders missing Data/ subfoled:  $count_missing"
			echo "------------------------------------------------------------------"
			echo "------------------------------------------------------------------"
			echo
	fi		
	
	if [ -f "${modedir}/_Wrong_Coreg_Pairs_${RUNDATE}_${RNDM1}.txt" ] && [ -s "${modedir}/_Wrong_Coreg_Pairs_${RUNDATE}_${RNDM1}.txt" ] 
		then 
			echo
			echo "See wrong coregistration images in ${modedir}/_Wrong_Coreg_Pairs_${RUNDATE}_${RNDM1}.txt"	
	fi