#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at preparing the MSBAS data sets and computing baselines table
#   Data must be already in csl format. 
# Can force using a given Global Primary (super master) if one do not want to compute a new one while just 
#   adding an image to a large existing data base.
# Will add manual pairs if an appropriate file is provided (see New in V2.0 below)
# Since V4.0, it can also accomodate two sets of baseline criteria: one applied for the 
#             period before a given date, and the second, after the given date.
#      
#
# Parameters : - path to dir with the csl dataset prepared for MSBAS (lns creaetd by lns_All_img.sh)
#              - max Bp
#              - Max Btemp
#              (- Min Bp - obsolate since V3.0......UNLESS you want to work with old tools)
#              (- Min Btemp - obsolate since V3.0...UNLESS you want to work with old tools)
#              - Date of Global Primary (SuperMaster)       
#              - optional max Bp2
#              - optional Max Btemp2
#              (- optional Min Bp2 - obsolate since V3.0......UNLESS you want to work with old tools)
#              (- optional Min Btemp2 - obsolate since V3.0...UNLESS you want to work with old tools)
#              - optional DATE from which you want to apply Bp2 and Bt2 instead of Bp1 and Bt1
#
# Dependencies:	- gnu sed and awk for more compatibility.
#    			- functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#				- AMSTer Engine tools: baselinePlot (D. Derauw from AMSTer Engine V20220510 - formerly named AMSTerEngine)
# 				Obsolate since V3.0
#    			- script build_bperp_file.sh (which needs plotspan.sh )
#				- AMSTer Engine tools: initiateBaselinesComputation... (L. Libert) 
#
# New in Distro V 1.0:	- Based on developpement version 3.3 and Beta V1.2
# New in Distro V 2.0:	- If a file named table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt exists 
#						  in SETi dir with a list of pairs in the form  
#						  "DatePrimary	   DateSecondary	   Bp	   Bt", without header, 
#						  it will paste these pairs to the table_BpMin_BpMax_Btmin_Btmax.txt.
#						  This is usefull when some pairs above Bp and Bt must be kept in the  
#						  beseline ployt to ensure trianlgle closure or time continuity
# New in Distro V 2.1:	- Remove header of table with additional pairs if any
# New in Distro V 2.2:	- if do not want to recomputer a Global Primary, ensure that a SM date was provied. 
# New in Distro V 2.3:	- correction of test for nr of parameters (thanks to A. Dille)
# New in Distro V 3.0:	- use tool developped by DD instead of those by L. Libert. 
#						- make the baseline plot using baselinePlot instead of build_bperp_file.sh and plot_span.sh
# New in Distro V 3.1:	- Create a initBaseline.txt file as needed by the computeBaselinesPlotFile to be allowed to keep some old tools  
# New in Distro V 3.2:	- Now actually work with old and new version of AMSTEer Engine (formerly MasTerEngine), that is with D Derauw or L Libert tools for baseline plotting.
#						  New is faster and more accurate, Old allows comuting tables with minimum Bt and Bp other than 0 
# New in Distro V 3.3:	- typo on searching for baselinePlot2 instead of baselinePlot and wrong call of second if at double test
# New in Distro V 3.4:	- prepare bperp_file.txt and SM_Approx_baselines.txt also when using new tools for baseline plots for further plots if needed
# New in Distro V 3.5:	- Big bug correction: some files where not replaced but data were added making them to grow infinitely and slowing up the process... 
# New in Distro V 3.6:	- ignore empty lines in pairs file
# New in Distro V 3.7:	- Debug usage of old tools if baselinePlot does not exists
# New in Distro V 4.0:	- Allows changing Bp and or Bt criteria after a specific date (incl. that date), e.g. to take into account a change in satellite orbital tube policy.
#						  NOTE that in that case, there MUST be a SMFORCED date provided. 
#						- change some if "-s" option with "-f" or add quotes in names
#						- see logical tree of the script at the end of this file 
#						- create the setParametersFile.txt using initiateMSBAS if needed (using old tools for the first time)
#						- correct bug to test if new or old tool was needed 
# New in Distro V 4.1:	- rename table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt as 
#						  table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt to avoid possible confusion  
# New in Distro V 4.2:	- Debug addition of 2 sets of pairs when used with DUAL criteria and NEW processing tools 
# New in Distro V 4.3:	- When add AdditionalPairs, proceed to sort and uniq based only on dates of MAS and SLV to avoid possible duplication if 
#						  Additional Pairs are added with an accidentally different BP or Bt value
#						- remove possible double empt lines
# New in Distro V 4.4: - use gdate
# New in Distro V 4.5: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 5.0: - Rename MasTer Toolbox as AMSTer Software
#					   - rename Master and AMSTer as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

if [ $# -lt 3 ] ; then echo "Usage $0 path_to_SETi MaxBp MaxBt [DateGlobalPrimary]"; exit; fi

if [ $# -eq 3 ] || [ $# -eq 4 ] # New tools only require 3 or 4 param
	then 
		echo "// Try to process with AMSTer Engine tools from May 2022; Check if required files are available"
		SET=$1					# path to dir with the csl dataset prepared for MSBAS
		BP=$2					# Max Bperp
		BT=$3					# Max Btemp
		SMFORCED=$4				# SM date
		if [ `baselinePlot | wc -l` -eq 0 ] 
			then 
				echo "// AMSTer Engine tools from May 2022 does not exist yet"
				echo "// Set Min Bp and Bt to zero and use old tools." 
				VERTOOL="OLD"
			else 
				VERTOOL="NEW"
		fi
		BPMIN=0				# Min Bperp
		BTMIN=0				# Min Btemp
		
		# and no change of baseline criteria from a given date
		DUALCRITERIA="NO"
		
	elif [ $# -eq 5 ] || [ $# -eq 6 ] ; then # Old tools  require 5 or 6 param

		if [ `baselinePlot | wc -l` -eq 0 ] 
			then 
				echo "// Process with AMSTer Engine tools before May 2022"	
				SET=$1					# path to dir with the csl dataset prepared for MSBAS
				BP=$2					# Max Bperp
				BT=$3					# Max Btemp
				BPMIN=$4				# Min Bperp
				BTMIN=$5				# Min Btemp
				SMFORCED=$6				# SM date
				VERTOOL="OLD"		
						
			else
				echo "// You have AMSTer Engine tools from May 2022 but entered parameters as for old tools"
				if [ "$4" -eq 0 ] && [ "$5" -eq 0 ] 
					then
						echo "// But you use Min BP or BT == zero. Hence you can to use new tools." 
						SET=$1					# path to dir with the csl dataset prepared for MSBAS
						BP=$2					# Max Bperp
						BT=$3					# Max Btemp
						BPMIN=0				# Min Bperp
						BTMIN=0				# Min Btemp
						SMFORCED=$6				# SM date

						VERTOOL="NEW"
					else
						echo "// But you asked for Min BP or BT other than zero. Hence you indeed need to use old tools." 
						SET=$1					# path to dir with the csl dataset prepared for MSBAS
						BP=$2					# Max Bperp
						BT=$3					# Max Btemp
						BPMIN=$4				# Min Bperp
						BTMIN=$5				# Min Btemp
						SMFORCED=$6				# SM date

						VERTOOL="OLD"
				fi
		fi
		
		# and no change of baseline criteria from a given date
		DUALCRITERIA="NO"

	elif [ $# -eq 7 ]  ; then 
		# New tools with change in baselines criteria
		echo "// Try to process with AMSTer Engine tools from May 2022; Check if required files are available"
		SET=$1					# path to dir with the csl dataset prepared for MSBAS
		BP1=$2					# Max Bperp
		BT1=$3					# Max Btemp
		SMFORCED=$4				# SM date
		BP2=$5					# Max Bperp 2
		BT2=$6					# Max Btemp 2
		DATECHANGE=$7			# Date from which one take into account the second Bperp and Btemp criteria  	
		
		if [ `baselinePlot | wc -l` -eq 0 ] 
			then 
				echo "// AMSTer Engine tools from May 2022 does not exist yet"
				echo "// Set Min Bp and Bt to zero and use old tools." 
				VERTOOL="OLD"
			else 
				VERTOOL="NEW"
		fi
		BPMIN1=0				# Min Bperp
		BTMIN1=0				# Min Btemp
		BPMIN2=0				# Min Bperp
		BTMIN2=0				# Min Btemp
		
		# and baseline criteria change from a given date
		DUALCRITERIA="YES"

	else [ $# -eq 11 ]  # old tools with change in baselines criteria
		if [ `baselinePlot | wc -l` -eq 0 ] 
				then 
					echo "// Process with AMSTer Engine tools before May 2022 with a change of baseline criteria from ${11}"	
					SET=$1					# path to dir with the csl dataset prepared for MSBAS
					BP1=$2					# Max Bperp
					BT1=$3					# Max Btemp
					BPMIN1=$4				# Min Bperp
					BTMIN1=$5				# Min Btemp
					SMFORCED=$6				# SM date
					BP2=$7					# Max Bperp 2
					BT2=$8					# Max Btemp 2
					BPMIN2=$9				# Min Bperp 2 
					BTMIN2=${10}			# Min Btemp 2
					DATECHANGE=${11}		# Date from which one take into account the second Bperp and Btemp criteria						
					
					VERTOOL="OLD"					
				else
					echo "// You have AMSTer Engine tools from May 2022 but entered parameters as for old tools"
					if [ $4 -eq 0 ] && [ $5 -eq 0 ] && [ $9 -eq 0 ] && [ ${10} -eq 0 ] 
						then
							echo "// But you use Min BP or BT == zero . Hence you can to use new tools with a change of baseline criteria from ${11}." 
							SET=$1					# path to dir with the csl dataset prepared for MSBAS
							BP1=$2					# Max Bperp
							BT1=$3					# Max Btemp
							SMFORCED=$4				# SM date
							BP2=$5					# Max Bperp 2
							BT2=$6					# Max Btemp 2
							DATECHANGE=$7			# Date from which one take into account the second Bperp and Btemp criteria  	

							BPMIN1=0				# Min Bperp
							BTMIN1=0				# Min Btemp
							BPMIN2=0				# Min Bperp
							BTMIN2=0				# Min Btemp
					
							VERTOOL="NEW"
						else
							echo "// But you asked for Min BP or BT other than zero. Hence you indeed need to use old tools with a change of baseline criteria from ${11}." 
							SET=$1					# path to dir with the csl dataset prepared for MSBAS
							BP1=$2					# Max Bperp
							BT1=$3					# Max Btemp
							BPMIN1=$4				# Min Bperp
							BTMIN1=$5				# Min Btemp
							SMFORCED=$6				# SM date
							BP2=$7					# Max Bperp 2
							BT2=$8					# Max Btemp 2
							BPMIN2=$9				# Min Bperp 2 
							BTMIN2=${10}			# Min Btemp 2
							DATECHANGE=${11}		# Date from which one take into account the second Bperp and Btemp criteria						

							VERTOOL="OLD"
					fi
		fi

		# and baseline criteria change from a given date
		DUALCRITERIA="YES"


 fi


cd ${SET}

# Because we need it
####################
echo "  Master	   Slave	 Bperp	 Delay" > ${SET}/two_lines_header.txt
echo "" >> ${SET}/two_lines_header.txt



# Some functions
#################

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

function MergeTables()
	{
	local TABLERAWM			# Do not unset these variables
	local TABLETOADDM
	
	TABLERAW=$1		# e.g. table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt
	TABLETOADD=$2	# e.g. table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt

		# remove header if any from additional pairs list
		if [ `${PATHGNU}/grep "Master" ${SET}/${TABLETOADD} | wc -c` -gt 0 ] 
			then 
				tail -n +3 ${SET}/${TABLETOADD} > ${SET}/${TABLETOADD}_NoHeader.txt
			else 
				cp -f ${SET}/${TABLETOADD} ${SET}/${TABLETOADD}_NoHeader.txt
		fi 

		# Keep original table for debug
		cp -f ${SET}/${TABLERAW} ${SET}/${TABLERAW}_BEFORE_ADDING_PAIRS.txt
		# remove header from main table
		if [ `${PATHGNU}/grep "Master" ${SET}/${TABLERAW} | wc -c` -gt 0 ] 
			then 
				tail -n +3 ${SET}/${TABLERAW} > ${SET}/${TABLERAW}_NoHeader.txt
			else 
				cp -f ${SET}/${TABLERAW} ${SET}/${TABLERAW}_NoHeader.txt
		fi 

		# Merge tables without header
		cat ${SET}/${TABLERAW}_NoHeader.txt ${SET}/${TABLETOADD}_NoHeader.txt > ${SET}/${TABLERAW}_tmp.txt
		#ensure that there is no duplicate

		#sort ${SET}/${TABLERAW}_tmp.txt | uniq > ${SET}/${TABLERAW}_NoHeader.txt
		# based on 2 first col only
		sort -u -k1,2 ${SET}/${TABLERAW}_tmp.txt > ${SET}/${TABLERAW}_NoHeader.txt
		
		# add header
		cat  ${SET}/two_lines_header.txt ${SET}/${TABLERAW}_NoHeader.txt > ${SET}/${TABLERAW}
		rm ${SET}/${TABLERAW}_tmp.txt
		# Do not remove ${SET}/${TABLETOADD}_NoHeader.txt and ${SET}/${TABLERAW}_NoHeader.txt 

	}	

function SortUniqOnTwoFirstCol()
	{	
	unset FILETOSORT 
	local FILETOSORT
	FILETOSORT=$1

	#remove header
	if [ `head -1 ${FILETOSORT} | ${PATHGNU}/grep Master | wc -l` -gt 0 ] 
		then 
			head -2 ${FILETOSORT} > File_Header.txt
			tail -n +3 ${FILETOSORT} > ${FILETOSORT}_NoHeader.txt
			sort -u -k1,2 ${FILETOSORT}_NoHeader.txt > ${FILETOSORT}_NoHeader.txt_sorted_uniq_Col12.txt 
			cat File_Header.txt ${FILETOSORT}_NoHeader.txt_sorted_uniq_Col12.txt > ${FILETOSORT}_sorted_uniq_Col12.txt 
			rm -f File_Header.txt ${FILETOSORT}_NoHeader.txt_sorted_uniq_Col12.txt 
		else 
			sort -u -k1,2 ${FILETOSORT} > ${FILETOSORT}_sorted_uniq_Col12.txt 
	fi
	}

function AddPairsNewBaselinePlotTool()
	{
	local TABLERAW
	local TABLETOADD
	local SELECTEDACQUISITIONSPATIALREPARTITION
	local SELECTEDPAIRLISTING
	
	TABLERAW=$1		# e.g. table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt
	TABLETOADD=$2	# e.g. table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt
	SELECTEDACQUISITIONSPATIALREPARTITION=$3		# e.g. selectedAcquisitionsSpatialRepartition_BpMax=${BP}_BTMax=${BT}.txt
	SELECTEDPAIRLISTING=$4		# e.g. selectedPairsListing_BpMax=${BP}_BTMax=${BT}.txt

		MergeTables "${TABLERAW}" "${TABLETOADD}"		# Produces a new TABLERAW with additional pairs with and without header (${TABLERAW}_NoHeader.txt and ${TABLERAW})

		## NEED ALSO TO UPDATE THE selectedAcquisitionsSpatialRepartition_BpMax=${BPLOC}_BTMax=${BTLOC}.txt and selectedPairsListing_BpMax=${BPLOC}_BTMax=${BTLOC}.txt FOR PLOTTING
		#chech that all images listed in table_${BPMINLOC}_${BPLOC}_${BTMINLOC}_${BTLOC}_AdditionalPairs.txt has an entry in selectedAcquisitionsSpatialRepartition_BpMax=${BPLOC}_BTMax=${BTLOC}.txt. If not, get it from acquisitionsRepartition.txt
		
			# save it with new name for not mixing up files and plots
			cp -f ${SELECTEDACQUISITIONSPATIALREPARTITION} ${SELECTEDACQUISITIONSPATIALREPARTITION}_ADD_PAIRS.txt
		
			# get all dates sorted and uniq (8 characters long string):
			${PATHGNU}/grep -o '\<.\{8\}\>' "${SET}/${TABLETOADD}_NoHeader.txt" | sort | uniq > ListNewDates.txt

			while read -r NEWDATE
				do 
					# if NEWDATE is NOT in selectedAcquisitionsSpatialRepartition_BpMax=${BPLOC}_BTMax=${BTLOC}_ADD_PAIRS.txt, add it
					if ! ${PATHGNU}/grep -q ${NEWDATE} "${SELECTEDACQUISITIONSPATIALREPARTITION}_ADD_PAIRS.txt"
						then
							echo "// ${NEWDATE} not yet in ${SELECTEDACQUISITIONSPATIALREPARTITION}_ADD_PAIRS.txt; add it"
							${PATHGNU}/grep ${NEWDATE} acquisitionsRepartition.txt >> ${SELECTEDACQUISITIONSPATIALREPARTITION}_ADD_PAIRS.txt
					fi
			done < ListNewDates.txt 
			echo 
			
			## update the selectedPairsListing_BpMax=${BPLOC}_BTMax=${BTLOC}.txt
			# save it with new name for not mixing up files and plots
			cp -f ${SELECTEDPAIRLISTING} ${SELECTEDPAIRLISTING}_ADD_PAIRS.txt
			while read -r NEWMAS NEWSLAV DUMMY1 DUMMY2
				do 
					${PATHGNU}/grep ${NEWMAS} allPairsListing.txt | ${PATHGNU}/grep ${NEWSLAV}  >> ${SELECTEDPAIRLISTING}_ADD_PAIRS.txt
			done < ${SET}/${TABLETOADD}_NoHeader.txt
	
		#replot the table with additional pairs
		cp -f ${SET}/baselinePlot.gnuplot ${SET}/baselinePlot_ADD_PAIRS.gnuplot
		#edit baselinePlot_ADD_PAIRS.gnuplot
		${PATHGNU}/gsed -i "s/selectedAcquisitionsSpatialRepartition.txt/${SELECTEDACQUISITIONSPATIALREPARTITION}_ADD_PAIRS.txt/" ${SET}/baselinePlot_ADD_PAIRS.gnuplot
		${PATHGNU}/gsed -i "s/selectedPairsListing.txt/${SELECTEDPAIRLISTING}_ADD_PAIRS.txt/" ${SET}/baselinePlot_ADD_PAIRS.gnuplot
		${PATHGNU}/gsed -i "s/imageSpatialLocalization/imageSpatialLocalization_ADD_PAIRS/" ${SET}/baselinePlot_ADD_PAIRS.gnuplot
		${PATHGNU}/gsed -i "s/baselinePlot/baselinePlot_ADD_PAIRS/" ${SET}/baselinePlot_ADD_PAIRS.gnuplot
		echo
		# replot		
		gnuplot ${SET}/baselinePlot_ADD_PAIRS.gnuplot
		echo
		}

function ProcessBaselinePlotNewMethod()
	{	
		# Note that baselinePlot creates the following tables:
		# - allPairsListing.txt												WHICH IS a 10 col file with 9 lines header
		# - acquisitionsRepartition.txt										WHICH IS a 3 col file with 5 lines header
		# - selectedPairsListing_BpMax=BP_BTMax=BT.txt						WHICH IS a 10 col file with 9 lines header
		# - selectedAcquisitionsSpatialRepartition_BpMax=BP_BTMax=BT.txt	WHICH IS a 3 col file with 5 lines header
		# - table_0_BP_0_BT.txt												WHICH IS a 4 col file with 2 lines header
		# - selectedPairsListing.txt 										WHICH IS A LINK TO selectedPairsListing_BpMax=BP_BTMax=BT.txt
		# - selectedAcquisitionsSpatialRepartition.txt						WHICH IS A LINK TO selectedAcquisitionsSpatialRepartition_BpMax=BP_BTMax=BT.txt
		# - baselinePlot.gnuplot
		# - imageSpatialLocalization_BpMax=BP_BTMax=BT.txt.png
		# - baselinePlot_BpMax=BP_BTMax=BT.txt.png

						
		if [ "${DUALCRITERIA}" == "NO" ] 
			then
				echo
 				echo "// Compute BaselinePlot with provided criteria : Bp=${BP} dT=${BT} "	
				baselinePlot ${SET} ${SET} BpMax=${BP} dTMax=${BT}  # second call of ${SET} is to output results in current dir
				SM=`grep "Identified Super Master" ${SET}/allPairsListing.txt | cut -d ":" -f2 | ${PATHGNU}/gsed 's/\t//g' | ${PATHGNU}/gsed 's/ //g'`
 				echo "// BaselinePlot computed. New Global Promary (Super Master) is  ${SM}."		
 				TABLEFORBPERP=table_0_${BP}_0_${BT}.txt	
 				SUFFIX="0_${BP}_0_${BT}"
 				echo
			else
				echo " // clean former tables "
 				rm -f table_0_${BP1}_0_${BT1}.txt 
 				rm -f table_0_${BP2}_0_${BT2}.txt 
 				rm -f table_0_${BPMAX}_0_${BTMAX}.txt 

				# first set of criteria :				
				echo
 				echo "// Compute BaselinePlot with first set of criteria : Bp=${BP1} dT=${BT1} "	
				baselinePlot ${SET} ${SET} BpMax=${BP1} dTMax=${BT1}  # second call of ${SET} is to output results in current dir
 				cp baselinePlot.gnuplot baselinePlot_BpMax=${BP1}_BTMax=${BT1}.txt.gnuplot
	
				SM=`grep "Identified Super Master" ${SET}/allPairsListing.txt | cut -d ":" -f2 | ${PATHGNU}/gsed 's/\t//g' | ${PATHGNU}/gsed 's/ //g'`
 				echo "// BaselinePlot computed. New Global Promary (Super Master) is  ${SM}."	
				echo

				# second set of criteria :
				echo
 				echo "// Compute BaselinePlot with second set of criteria : Bp=${BP2} dT=${BT2} "	
				# Proceed only if not done yet with same criteria
				if [ ! -f table_0_${BP2}_0_${BT2}.txt  ] 
					then 
						baselinePlot ${SET} ${SET} BpMax=${BP2} dTMax=${BT2}  # second call of ${SET} is to output results in current dir
						cp baselinePlot.gnuplot baselinePlot_BpMax=${BP2}_BTMax=${BT2}.txt.gnuplot
					else
						echo "//  .. Skip it because table_0_${BP2}_0_${BT2}.txt  already computed - same criteria as for first part"
				fi
				
				# Proceed to a global run with largest criteria from which we will restrict the pairs to plot
				echo
 				echo "// Compute BaselinePlot with largest criteria (from set1 and 2): Bp=${BPMAX} dT=${BTMAX} "	
				# Proceed only if not done yet with same criteria
				if [ ! -f table_0_${BPMAX}_0_${BTMAX}.txt  ] 
					then 
						baselinePlot ${SET} ${SET} BpMax=${BPMAX} dTMax=${BTMAX} 
						cp baselinePlot.gnuplot baselinePlot_BpMax=${BPMAX}_BTMax=${BTMAX}.txt.gnuplot
					else 
						echo "//  .. Skip it because table_0_${BPMAX}_0_${BTMAX}.txt  already computed with same criteria"
				fi
				
				# Select pairs before DATECHANGE (incl. DATECHANGE) and reshape the file in 4 tab separated col file (Bt Bp MAS SLV ; Bp in second to be similar to output from Coh Restriction script)
				echo
 				echo "// Select pairs before ${DATECHANGE} "	
					cat selectedPairsListing_BpMax=${BP1}_BTMax=${BT1}.txt | tail -n+9 | ${PATHGNU}/gawk ' ( ( $1 <= '${DATECHANGE}') || ( $2 <= '${DATECHANGE}' ) ) ' | ${PATHGNU}/gawk '{print $9 "\t" $8 "\t" $1 "\t" $2}' > BTMax=${BT1}_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}.txt
				# Select pairs after DATECHANGE (incl. DATECHANGE) and reshape the file in 4 tab separated col file (Bp Bt MAS SLV)
				echo
 				echo "// Select pairs after ${DATECHANGE} "	
					cat selectedPairsListing_BpMax=${BP2}_BTMax=${BT2}.txt | tail -n+9 | ${PATHGNU}/gawk ' ( ( $1 >= '${DATECHANGE}') || ( $2 >= '${DATECHANGE}' ) ) ' | ${PATHGNU}/gawk '{print $9 "\t" $8 "\t" $1 "\t" $2}' > BTMax=${BT2}_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt

				# Merge both files (sorted (based on 3rd col) and uniq) 
				echo
 				echo "// Merge pairs before and after ${DATECHANGE} "	
					cat BTMax=${BT1}_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}.txt BTMax=${BT2}_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt | sort -k3 | uniq > BTMax=${BT1}_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_BTMax=${BT2}_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt

				# Save it also in form similar to what Prepa_msbas.sh produces, that is MAS and SLV in 1st and 2nd col 
				# i.e. OK for mass processing 
				echo
 				echo "// Create table of pairs for further mass processing as MAS SLV BP(as integer) BT "	
					# rename input file to avoid messing up with special characters in name while executing awk...
					cp -f BTMax=${BT1}_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_BTMax=${BT2}_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt tmpAWK.txt
					# with real BP
					#${PATHGNU}/gawk '{print $3 "\t" $4 "\t" $2 "\t" $1}' tmpAWK.txt > table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt
					${PATHGNU}/gawk '{gsub(/\..*/,"",$2);print $3 "\t" $4 "\t" $2 "\t" $1}' tmpAWK.txt > table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt
					
					cat two_lines_header.txt table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt > table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt
					TABLEFORBPERP=table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt
					SUFFIX="0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After"

				# Save it also in form similar to what restrict_msbas_to_Coh.sh produces, that is MAS and SLV in 3rd and 4th col
				# i.e. OK for baselinePlot and gnuplot tools ; First col must be text
				echo
 				echo "// Create table for plotting with gnuplot "
					# rename input file to avoid messing up with special characters in name while executing awk...
					cp -f BTMax=${BT1}_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_BTMax=${BT2}_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt tmpAWK.txt
					${PATHGNU}/gawk '{print "Dummy" "\t" $2 "\t" $3 "\t" $4}' tmpAWK.txt > Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt

				echo
 				echo "// Make merged BaselinePlot with both criteria "	
				baselinePlot -r ${SET} ${SET}/Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt 
				
 				cp baselinePlot.gnuplot baselinePlot_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt.gnuplot

				# Note that baselinePlot -r creates the following tables:
				# - restrictedAcquisitionsRepartition.txt_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt	WHICH IS a 3 col file with 4 (!!!!!!) lines header
				# - restrictedPairSelection_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt					WHICH IS a 10 col file with 9 lines header
				# - imageSpatialLocalization_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt.png
				# - baselinePlot_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt.png
				echo
				rm -f tmpAWK.txt
 		fi
	}
	

	
# Let's go
##########

echo 
echo
if [ "${VERTOOL}" == "OLD" ] 
	then
		
		if [ ! -f ${SET}/setParametersFile.txt ] ; then 
			echo "// It seems that your seti directory and/or required files are not ready yet; I can't find ${SET}/setParametersFile.txt. See manual. Exit"
			exit 
		fi
		
		rm -f approximateBaselinesTable.txt initBaselines.txt
		
		timeSorting ${SET}
		initiateBaselinesComputation ${SET}
		approximateBaselines ${SET}/setParametersFile.txt

		if [ "${DUALCRITERIA}" == "NO" ] 
			then
				# Only one set of criteria 
				updateParameterFile ${SET}/setParametersFile.txt "Minimum baseline [m]" ${BPMIN}
				updateParameterFile ${SET}/setParametersFile.txt "Maximum baseline [m]" ${BP}
				updateParameterFile ${SET}/setParametersFile.txt "Minimum temporal delay [days]" ${BTMIN}
				updateParameterFile ${SET}/setParametersFile.txt "Maximum temporal delay [days]" ${BT}
				
				updateParameterFile ${SET}/setParametersFile.txt "Path to triangle table containing baseline and delay values" ${SET}/approximateBaselinesTable.txt
				
				selectInterferometricPairs ${SET}/setParametersFile.txt
			else 
				# Process first set of criteria 
					echo "//////////////////////////////////////////////////////////"
					echo "// Select interferometric pairs with first set of criteria"
					echo
					updateParameterFile ${SET}/setParametersFile.txt "Minimum baseline [m]" ${BPMIN1}
					updateParameterFile ${SET}/setParametersFile.txt "Maximum baseline [m]" ${BP1}
					updateParameterFile ${SET}/setParametersFile.txt "Minimum temporal delay [days]" ${BTMIN1}
					updateParameterFile ${SET}/setParametersFile.txt "Maximum temporal delay [days]" ${BT1}
					
					updateParameterFile ${SET}/setParametersFile.txt "Path to triangle table containing baseline and delay values" ${SET}/approximateBaselinesTable.txt

					selectInterferometricPairs ${SET}/setParametersFile.txt
	
					# Select all lines in table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}.txt that contains at least one date before or equal to DATECHANGE : 
					# remove header and remove what is before DATECHANGE and rename 
					cat table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}.txt | tail -n+3 | ${PATHGNU}/gawk '( ( $1 <= '${DATECHANGE}') || ( $2 <= '${DATECHANGE}' ) ) ' > table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}.txt
				
					# Keep info from first run for possible selection of SM later
					cp -f ${SET}/approximateBaselinesTable.txt ${SET}/approximateBaselinesTable_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}.txt 
				
				# Process second set of criteria 
					echo "///////////////////////////////////////////////////////////"
					echo "// Select interferometric pairs with second set of criteria"
					echo
					updateParameterFile ${SET}/setParametersFile.txt "Minimum baseline [m]" ${BPMIN2}
					updateParameterFile ${SET}/setParametersFile.txt "Maximum baseline [m]" ${BP2}
					updateParameterFile ${SET}/setParametersFile.txt "Minimum temporal delay [days]" ${BTMIN2}
					updateParameterFile ${SET}/setParametersFile.txt "Maximum temporal delay [days]" ${BT2}
					
					updateParameterFile ${SET}/setParametersFile.txt "Path to triangle table containing baseline and delay values" ${SET}/approximateBaselinesTable.txt

					selectInterferometricPairs ${SET}/setParametersFile.txt
					
					# Select all lines in table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_${DATECHANGE}.txt that contains at least one date after or equal to DATECHANGE : 
					# remove header and remove what is before DATECHANGE and rename 
					cat table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}.txt | tail -n+3 | ${PATHGNU}/gawk '( ( $1 >= '${DATECHANGE}') || ( $2 >= '${DATECHANGE}' ) ) ' > table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_${DATECHANGE}.txt
	
				# Merge both lists, sort them and ensure no duplication
					cat table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}.txt table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_${DATECHANGE}.txt | sort | uniq > table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_NoHeader.txt
					
				# get the header back 
					cat two_lines_header.txt table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_NoHeader.txt > table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After.txt
					rm -f table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_NoHeader.txt
		fi
fi

# Here only tables are created. Need to build the bperp, span and span1 files 

# ask if one wants to re-compute a SM. If not it will keep the one that is already 
#                 in the setParametersFile.txt. Use this option ONLY when it is about adding new data to an existing dataset

if [ "${DUALCRITERIA}" == "YES" ] 
	then
		# Select largest criteria 
		BPMAX=$((${BP1} > ${BP2} ? ${BP1} : ${BP2}))
		BTMAX=$((${BT1} > ${BT2} ? ${BT1} : ${BT2}))		
fi

SpeakOut "Do you want to search for a new Global Primary image?" 
while true; do
    read -p "Do you want to search for a new Global Primary image (Super Master)? (say no only when it is about adding new data to an existing dataset): "  yn
    case $yn in
        [Yy]* ) 
			if [ "${VERTOOL}" == "OLD" ] 
				then
					if [ "${DUALCRITERIA}" == "NO" ] 
						then
							globalMaster ${SET}/approximateBaselinesTable.txt 
				         	# Get the supermaster
				 			SM=`grep "Path to global master" ${SET}/setParametersFile.txt | cut -d* -f1 | ${PATHGNU}/gsed 's/\t//g' | ${PATHGNU}/gsed 's/.$//' | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d . -f 1`
						else
							globalMaster ${SET}/approximateBaselinesTable_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}.txt 
				         	# Get the supermaster
				 			SM=`grep "Path to global master" ${SET}/setParametersFile.txt | cut -d* -f1 | ${PATHGNU}/gsed 's/\t//g' | ${PATHGNU}/gsed 's/.$//' | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d . -f 1`
					fi
		 			echo "// New Global Primary (Super Master) is  ${SM}."
				else
					# Compute baselinePlot New Method for Dual or non Dual cases
					ProcessBaselinePlotNewMethod
					echo "New Global Primary (Super Master) is  ${SM}."	
 			fi
        	
        	if [ "${DUALCRITERIA}" == "YES" ] 
        		then 
        			echo "// Note that the Global Primary (Super Master) (i.e. ${SM}) was computed using the first set of baselines criteria."
        	fi
        	
        	break ;;
        [Nn]* ) 
 			# No search for new SM
 			if [ "${VERTOOL}" == "OLD" ] 
				then
					if [ $# -lt 6 ] ; then echo "Usage $0 path_to_SETi MaxBp MaxBt MinBp MinBt DateGlobalPrimary, PLEASE PROVIDE A GLOBAL PRIMARY (SUPER MASTER)"; exit; fi
 					echo
					echo "// Use the Global Primary (Super Master) set as last parameter in the current run, that is  ${SMFORCED}"
					echo "// Let's check what is in setParametersFile.txt :"
					grep "Path to global master" ${SET}/setParametersFile.txt
					echo ""
					if [ -z ${SMFORCED} ]
						then # no FORMCED SM provided; will take it from existing setParametersFile.txt
							echo "// No Global Primary (Super Master) provided in the command line; shall take it from the setParametersFile.txt. Hope it is the good one."
							SM=`grep "Path to global master" ${SET}/setParametersFile.txt | cut -d* -f1 | ${PATHGNU}/gsed 's/\t//g' | ${PATHGNU}/gsed 's/.$//' | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d . -f 1`
						else 
							echo "// Shall take the Global Primary (Super Master) provided in the command line"
							SM=${SMFORCED}
					fi
 
 				else
       				if [ $# -lt 4 ] ; then echo "Usage $0 path_to_SETi MaxBp MaxBt DateGlobalPrimary, PLEASE PROVIDE A GLOBAL PRIMARY (SUPER MASTER)"; exit; fi

					#if [ -s ${SET}/allPairsListing.txt ] 
					if [ -f "${SET}/allPairsListing.txt" ] && [ -s "${SET}/allPairsListing.txt" ] 
						then 
							echo
							echo "// Use the Global Primary (Super Master) set as last parameter in the current run, that is  -${SMFORCED}-"
							echo "// Let's check what is in ${SET}/allPairsListing.txt :"
							SMEXISTING=`grep "Identified Super Master" ${SET}/allPairsListing.txt | head -1 | cut -d ":" -f2 | ${PATHGNU}/gsed 's/\t//g' | ${PATHGNU}/gsed 's/ //g'`
							echo "// Existing Global Primary (Super Master) is -${SMEXISTING}-."
							echo ""
						
							echo "// First compute table(s) and plots with default SM"

							# Compute baselinePlot New Method for Dual or non Dual cases
							ProcessBaselinePlotNewMethod
							echo
							echo "// Table(s) and plots with default SM done... "
							echo

							if [ "${SMFORCED}" != "${SMEXISTING}" ] 
								then 
									echo "// Warning: you asked for keeping the Global Primary (Super Master) but the existing SM (${SMEXISTING}) does not fit with the provided one (${SMFORCED})..."
									echo "// Will use the one provided. Please check"

									# change SM in files allPairsListing.txt, selectedPairsListing_BpMax=400_BTMax=400.txt (wich is linked to selectedPairsListing.txt) and baselinePlot.gnuplot
									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/allPairsListing.txt
									if [ "${DUALCRITERIA}" == "YES" ] 
        								then 
        									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP1}_BTMax=${BT1}.txt
        									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP2}_BTMax=${BT2}.txt 2>/dev/null
        									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BPMAX}_BTMax=${BTMAX}.txt 2>/dev/null
										else
											${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP}_BTMax=${BT}.txt
        							fi
									${PATHGNU}/gsed -i "s/${SM}/${SMFORCED}/" ${SET}/baselinePlot.gnuplot
									# Redo the plots       					
									${PATHGNU}/gnuplot baselinePlot.gnuplot

							fi
							if [ "${SMFORCED}" != "${SM}" ] 
								then 
									echo "// Then change SM in plots with ${SMFORCED}"

									# change SM in files allPairsListing.txt, selectedPairsListing_BpMax=400_BTMax=400.txt (wich is linked to selectedPairsListing.txt) and baselinePlot.gnuplot
									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/allPairsListing.txt
									if [ "${DUALCRITERIA}" == "YES" ] 
        								then 
        									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP1}_BTMax=${BT1}.txt
        									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP2}_BTMax=${BT2}.txt 2>/dev/null
        									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BPMAX}_BTMax=${BTMAX}.txt 2>/dev/null
										else
											${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP}_BTMax=${BT}.txt
        							fi
									${PATHGNU}/gsed -i "s/${SM}/${SMFORCED}/" ${SET}/baselinePlot.gnuplot
									# Redo the plots       					
									${PATHGNU}/gnuplot baselinePlot.gnuplot
							fi
	
						else
							echo "// Global Primary (Super Master) not computed yet. Compute it and force to ${SMFORCED}."
							
							echo "// First compute table(s) and plots with default SM"
							# Compute baselinePlot New Method for Dual or non Dual cases
							ProcessBaselinePlotNewMethod

							echo "// Then change SM in plots with ${SMFORCED}"
							
							# change SM in files allPairsListing.txt, selectedPairsListing_BpMax=400_BTMax=400.txt (wich is linked to selectedPairsListing.txt) and baselinePlot.gnuplot
							${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/allPairsListing.txt
							if [ "${DUALCRITERIA}" == "YES" ] 
        						then 
        							${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP1}_BTMax=${BT1}.txt
       								${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP2}_BTMax=${BT2}.txt 2>/dev/null
        							${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BPMAX}_BTMax=${BTMAX}.txt 2>/dev/null
								else
									${PATHGNU}/gsed -i "s/Identified Super Master: ${SM}/Identified Super Master: ${SMFORCED}/" ${SET}/selectedPairsListing_BpMax=${BP}_BTMax=${BT}.txt
        					fi
							${PATHGNU}/gsed -i "s/${SM}/${SMFORCED}/" ${SET}/baselinePlot.gnuplot
							# Redo the plots       					
							${PATHGNU}/gnuplot baselinePlot.gnuplot
					fi
			fi
			
			break ;;
        * ) echo "// Please answer yes or no.";;
    esac
done


# if a file named table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt exists, 
# add these pairs to the table 
echo
if [ "${VERTOOL}" == "OLD" ] 
	then
		if [ "${DUALCRITERIA}" == "NO" ] 
        	then 
				# OLD and No DUAL
				if [ -f "${SET}/table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt" ] 
					then
						MergeTables table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt
						rm table_${BPMIN}_${BP}_${BTMIN}_${BT}_NoHeader.txt 
				
						# Just keep track of former plot for comparison
						if [ -f span_${BPMIN}_${BP}_${BTMIN}_${BT}.jpg ] ; then cp -f span_${BPMIN}_${BP}_${BTMIN}_${BT}.jpg span_${BPMIN}_${BP}_${BTMIN}_${BT}_BEFORE_ADD.jpg ; fi
				fi

				# Prepare bperp_file.txt for plot and plot it.
				build_bperp_file.sh  ${SET}/table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt ${SM}
				# open  ${SET}/span.jpg

				# Rename bperp_file.txt for further use
				#echo " If run script on Windows hp server, ignore following errors dues to permissions prblms"
				#echo  "$(tput setaf 1)$(tput setab 7) If run script on Windows hp server, ignore following errors dues to permissions prblms $(tput sgr 0)"	
				mv bperp_file.txt bperp_file_${BPMIN}_${BP}_${BTMIN}_${BT}.txt
				#mv span.txt span_${BPMIN}_${BP}_${BTMIN}_${BT}.txt
				#mv span1.txt span1_${BPMIN}_${BP}_${BTMIN}_${BT}.txt
			else 
				# OLD and DUAL
				CRITERIA1="${BPMIN1}_${BP1}_${BTMIN1}_${BT1}"
				CRITERIA2="${BPMIN2}_${BP2}_${BTMIN2}_${BT2}"
				
				if [ -f "${SET}/table_${CRITERIA1}_AdditionalPairs.txt" ] 
					then
						echo "/////////////////////////////////////"
						echo "// Proceed with first set of criteria"
						echo "//"
						echo "// Add table_${CRITERIA1}_AdditionalPairs.txt to pair table "
						MergeTables table_${CRITERIA1}_Before_${DATECHANGE}.txt table_${CRITERIA1}_AdditionalPairs.txt 
						echo

						cp -f table_${CRITERIA1}_Before_${DATECHANGE}.txt ${SET}/table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt 
						build_bperp_file.sh ${SET}/table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt ${SM}

						echo "// Done with first set of criteria ; rename file..."
						# rename files
						mv -f bperp_file_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt bperp_file_${CRITERIA1}_Before_${DATECHANGE}.txt
						mv -f span_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt span_${CRITERIA1}_Before_${DATECHANGE}.txt
						mv -f span1_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt span1_${CRITERIA1}_Before_${DATECHANGE}.txt
						mv -f span_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.jpg span_${CRITERIA1}_Before_${DATECHANGE}.jpg
						mv -f SM_Approx_baselines_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt SM_Approx_baselines_${CRITERIA1}_Before_${DATECHANGE}.txt

						rm -f ${SET}/table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt

						echo "/////////////////////////////////////"
					else
						echo "/////////////////////////////////////"
						echo "// Proceed with first set of criteria"
						echo "//"
						echo "// No additional pairs in table_${CRITERIA1}_AdditionalPairs.txt"
						echo "//"
						# Prepare bperp_file.txt for plot and plot it.
						
						build_bperp_file.sh  table_${CRITERIA1}_Before_${DATECHANGE}.txt ${SM}
						echo "// Done with first set of criteria ; rename file..."
						# rename files
						mv -f bperp_file_${CRITERIA1}.txt bperp_file_${CRITERIA1}_Before_${DATECHANGE}.txt
						mv -f span_${CRITERIA1}.txt span_${CRITERIA1}_Before_${DATECHANGE}.txt
						mv -f span1_${CRITERIA1}.txt span1_${CRITERIA1}_Before_${DATECHANGE}.txt
						mv -f span_${CRITERIA1}.jpg span_${CRITERIA1}_Before_${DATECHANGE}.jpg
						echo "////////////////////////////////////////////////////"
				fi
				echo
				if [ -f "${SET}/table_${CRITERIA2}_AdditionalPairs.txt" ] 
					then
						echo "/////////////////////////////////////"
						echo "// Proceed with second set of criteria"
						echo "//"
						echo "// Add table_${CRITERIA2}_AdditionalPairs.txt to pair table "
						MergeTables table_${CRITERIA2}_After_${DATECHANGE}.txt table_${CRITERIA2}_AdditionalPairs.txt 
						echo
						cp -f table_${CRITERIA2}_After_${DATECHANGE}.txt ${SET}/table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt 
						build_bperp_file.sh ${SET}/table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt ${SM}

						echo "// Done with second set of criteria ; rename file..."
						# rename files
						mv -f bperp_file_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt bperp_file_${CRITERIA2}_After_${DATECHANGE}.txt
						mv -f span_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt span_${CRITERIA2}_After_${DATECHANGE}.txt
						mv -f span1_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt span1_${CRITERIA2}_After_${DATECHANGE}.txt
						mv -f span_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.jpg span_${CRITERIA2}_After_${DATECHANGE}.jpg
						mv -f SM_Approx_baselines_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt SM_Approx_baselines_${CRITERIA2}_After_${DATECHANGE}.txt

						rm -f ${SET}/table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt
						echo "/////////////////////////////////////"
					else
						echo "//////////////////////////////////////"
						echo "// Proceed with second set of criteria"
						echo "//"
						echo "// No additional pairs in table_${CRITERIA2}_AdditionalPairs.txt"
						# Prepare bperp_file.txt for plot and plot it.

						build_bperp_file.sh  table_${CRITERIA2}_After_${DATECHANGE}.txt ${SM}
						echo "// Done with second set of criteria ; rename file..."
						# rename files
						mv -f bperp_file_${CRITERIA2}.txt bperp_file_${CRITERIA2}_After_${DATECHANGE}.txt
						mv -f span_${CRITERIA2}.txt span_${CRITERIA2}_After_${DATECHANGE}.txt
						mv -f span1_${CRITERIA2}.txt span1_${CRITERIA2}_After_${DATECHANGE}.txt
						mv -f span_${CRITERIA2}.jpg span_${CRITERIA2}_After_${DATECHANGE}.jpg
						echo "////////////////////////////////////////////////////"
				fi

				if [ -f "${SET}/table_${CRITERIA1}_AdditionalPairs.txt" ] || [ -f "${SET}/table_${CRITERIA2}_AdditionalPairs.txt" ] 
					then
						# Merge both lists without headers, sort them and ensure no duplication
							# Keep copy of table before adding pairs 
							cp -f table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.txt table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_BEFORE_ADDITIONAL_PAIRS.txt 2>/dev/null

						# merge tables Before and After
							# Just to be sure again... 
							if [ ! -f table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader.txt ]
								then 
									cp table_${CRITERIA1}_Before_${DATECHANGE}.txt table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader.txt
							fi
							if [ `${PATHGNU}/grep "Master" table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader.txt | wc -c` -gt 0 ] 
								then 
									tail -n +3 table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader.txt > table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader_tmp.txt
									mv -f table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader_tmp.txt table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader.txt
									rm -f table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader_tmp.txt
							fi 
	
							if [ ! -f table_${CRITERIA2}_After_${DATECHANGE}_NoHeader.txt ]
								then 
									cp table_${CRITERIA2}_After_${DATECHANGE}.txt table_${CRITERIA2}_After_${DATECHANGE}_NoHeader.txt
							fi
							if [ `${PATHGNU}/grep "Master" table_${CRITERIA2}_After_${DATECHANGE}_NoHeader.txt | wc -c` -gt 0 ] 
								then 
									tail -n +3 table_${CRITERIA2}_After_${DATECHANGE}_NoHeader.txt > table_${CRITERIA2}_After_${DATECHANGE}_NoHeader_tmp.txt
									mv -f table_${CRITERIA2}_After_${DATECHANGE}_NoHeader_tmp.txt table_${CRITERIA2}_After_${DATECHANGE}_NoHeader.txt
									rm -f table_${CRITERIA2}_After_${DATECHANGE}_NoHeader_tmp.txt
							fi 
						# sort and uniq based only on 2 first col
						#cat table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader.txt table_${CRITERIA2}_After_${DATECHANGE}_NoHeader.txt | sort | uniq > table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader.txt
						cat table_${CRITERIA1}_Before_${DATECHANGE}.txt_NoHeader.txt table_${CRITERIA2}_After_${DATECHANGE}_NoHeader.txt > table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader_NotSorted.txt
						sort -u -k1,2 table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader_NotSorted.txt > table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader.txt
						rm -f table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader_NotSorted.txt
						# add header
						cat two_lines_header.txt table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader.txt > table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.txt

					else
						# merge tables Before and After
						# sort and uniq based only on 2 first col
						#cat table_${CRITERIA1}_Before_${DATECHANGE}.txt table_${CRITERIA2}_After_${DATECHANGE}.txt | sort | uniq > table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader.txt
						cat table_${CRITERIA1}_Before_${DATECHANGE}.txt table_${CRITERIA2}_After_${DATECHANGE}.txt > table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader_NotSorted.txt
						sort -u -k1,2 table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader_NotSorted.txt > table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader.txt
						rm -f table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader_NotSorted.txt
						# add header
						cat two_lines_header.txt table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After_NoHeader.txt > table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.txt

				fi			
		
				# Prepare bperp_file.txt for plot and plot it.
				echo 
				echo "//////////////////////////////////////"
				echo "// Proceed with both sets of criteria"
				# set a dummy mane for operating the scripts below
				cp -f table_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.txt table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt 

				build_bperp_file.sh  ${SET}/table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt  ${SM}
				echo "// Done with both sets of criteria ; rename file..."

				mv -f bperp_file_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt bperp_file_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.txt
				mv -f span_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt span_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.txt
				mv -f span1_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt span1_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.txt
				mv -f span_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.jpg span_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.jpg
				mv -f SM_Approx_baselines_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt SM_Approx_baselines_${CRITERIA1}_Before_${DATECHANGE}_And_${CRITERIA2}_After.txt
				
				rm -f ${SET}/table_BPMINDUAL_BPDUAL_BTMINDUAL_BTDUAL.txt
				echo "////////////////////////////////////////////////////"			
				# open  ${SET}/span.jpg
		
				# Rename bperp_file.txt for further use
				#echo " If run script on Windows hp server, ignore following errors dues to permissions prblms"
				#echo  "$(tput setaf 1)$(tput setab 7) If run script on Windows hp server, ignore following errors dues to permissions prblms $(tput sgr 0)"	
#				mv bperp_file.txt bperp_file_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After.txt
				#mv span.txt span_${BPMIN}_${BP}_${BTMIN}_${BT}.txt
				#mv span1.txt span1_${BPMIN}_${BP}_${BTMIN}_${BT}.txt	
	
		fi
	else
		# NEW
		if [ "${DUALCRITERIA}" == "NO" ] 
        	then 
				# NEW and NO DUAL
				if [ -f "${SET}/table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt" ] 
					then					
						echo "//  Additional Pairs will be added (from ${SET}/table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt)"
						TABLEIN=table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt										# 4 col file : MAS SLV BP BT (with or without header)
						TABLEIN_ADDITIONAL=table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt			# 4 col file : MAS SLV BP BT (with or without header)
						SPATIALREPART=selectedAcquisitionsSpatialRepartition_BpMax=${BP}_BTMax=${BT}.txt	# 3 col file with 5 lines header: DATE X Y
						PAIRSELECT=selectedPairsListing_BpMax=${BP}_BTMax=${BT}.txt							# 10 col file with 9 lines header: MAS SLV ..... BP BT HA

						AddPairsNewBaselinePlotTool ${TABLEIN} ${TABLEIN_ADDITIONAL} ${SPATIALREPART} ${PAIRSELECT}
					
						TABLEFORBPERP=table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt	
						SUFFIX="${BPMIN}_${BP}_${BTMIN}_${BT}"
					else
						echo "// No additional pairs in table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt"
				fi
			else 
				# NEW and DUAL
				if [ -f "${SET}/table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_AdditionalPairs.txt" ] || [ -f "${SET}/table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_AdditionalPairs.txt" ] 
					then
						TABLEIN=table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt								# 4 col file : MAS SLV BP BT (with or without header)

						TABLEIN_ADDPART1=table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_AdditionalPairs.txt								# 4 col file : MAS SLV BP BT (with or without header)
						TABLEIN_ADDPART2=table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_AdditionalPairs.txt								# 4 col file : MAS SLV BP BT (with or without header)

						echo "// You have additional pairs for ${TABLEIN} ; add them here"
						# Ensure there is no header
						if [ -f "${SET}/${TABLEIN_ADDPART1}" ] && [ `${PATHGNU}/grep "Master" ${SET}/${TABLEIN_ADDPART1} | wc -c` -gt 0 ] 
							then 
								tail -n +3 ${SET}/${TABLEIN_ADDPART1} > ${SET}/${TABLEIN_ADDPART1}_NoHeader.txt
							else 
								cp -f ${SET}/${TABLEIN_ADDPART1} ${SET}/${TABLEIN_ADDPART1}_NoHeader.txt
						fi 
						if [ -f "${SET}/${TABLEIN_ADDPART2}" ] && [ `${PATHGNU}/grep "Master" ${SET}/${TABLEIN_ADDPART2} | wc -c` -gt 0 ] 
							then 
								tail -n +3 ${SET}/${TABLEIN_ADDPART2} > ${SET}/${TABLEIN_ADDPART2}_NoHeader.txt
							else 
								cp -f ${SET}/${TABLEIN_ADDPART2} ${SET}/${TABLEIN_ADDPART2}_NoHeader.txt
						fi 

						# Merge all possible Additional Pairs tables as a file named ${TABLEIN_ADDITIONAL}						
						TABLEIN_ADDITIONAL=table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_AdditionalPairs.txt	# 4 col file : MAS SLV BP BT (without header, sorted and uniq)
						# sort and uniq based on 2 first col
						#cat ${SET}/${TABLEIN_ADDPART1}_NoHeader.txt ${SET}/${TABLEIN_ADDPART2}_NoHeader.txt | sort | uniq > ${TABLEIN_ADDITIONAL} 2>/dev/null
						cat ${SET}/${TABLEIN_ADDPART1}_NoHeader.txt ${SET}/${TABLEIN_ADDPART2}_NoHeader.txt > ${TABLEIN_ADDITIONAL}_NotSorted 2>/dev/null
						sort -u -k1,2 ${TABLEIN_ADDITIONAL}_NotSorted > ${TABLEIN_ADDITIONAL}
						rm -f ${TABLEIN_ADDITIONAL}_NotSorted

						# names of output files 																
						SPATIALREPART=restrictedAcquisitionsRepartition.txt_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt		# 3 col file with 5 lines header: DATE X Y
						PAIRSELECT=restrictedPairSelection_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt	# 10 col file with 9 lines header: MAS SLV ..... BP BT HA
						
						AddPairsNewBaselinePlotTool ${TABLEIN} ${TABLEIN_ADDITIONAL} ${SPATIALREPART} ${PAIRSELECT}
						
						# Rename restrictedAcquisitionsRepartition
						cp -f ${SPATIALREPART} ${SPATIALREPART}_Before_ADD_PAIRS.txt
						mv -f ${SPATIALREPART}_ADD_PAIRS.txt ${SPATIALREPART}
						# Rename restrictedPairSelection
						cp -f ${PAIRSELECT} ${PAIRSELECT}_Before_ADD_PAIRS.txt
						mv -f ${PAIRSELECT}_ADD_PAIRS.txt ${PAIRSELECT}

						# Header already added in MergeTables fct in AddPairsNewBaselinePlotTool						
						#cat two_lines_header.txt table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt > table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_header.txt
						#TABLEFORBPERP=table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_header.txt
						TABLEFORBPERP=table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt
						SUFFIX="0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After"
					else
						echo "// No additional pairs for table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_AdditionalPairs.txt"
					
				fi			

# 				if [ -f "${SET}/table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_AdditionalPairs.txt" ] 
# 					then
# 						echo "// You have additional pairs for set 2 in table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_AdditionalPairs.txt ; add them here"
# 						
# 						TABLEIN=table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt									# 4 col file : MAS SLV BP BT (with or without header)
# 						TABLEIN_ADDITIONAL=table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_AdditionalPairs.txt									# 4 col file : MAS SLV BP BT (with or without header)
# 						SPATIALREPART=restrictedAcquisitionsRepartition.txt_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt		# 3 col file with 5 lines header: DATE X Y
# 						PAIRSELECT=restrictedPairSelection_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt	# 10 col file with 9 lines header: MAS SLV ..... BP BT HA
# 						
# 						AddPairsNewBaselinePlotTool ${TABLEIN} ${TABLEIN_ADDITIONAL} ${SPATIALREPART} ${PAIRSELECT}
# 
# 						# Rename restrictedAcquisitionsRepartition
# 						cp -f ${SPATIALREPART} ${SPATIALREPART}_Before_ADD_PAIRS_Part2.txt
# 						mv -f ${SPATIALREPART}_ADD_PAIRS.txt ${SPATIALREPART}
# 						# Rename restrictedPairSelection
# 						cp -f ${PAIRSELECT} ${PAIRSELECT}_Before_ADD_PAIRS_Part2.txt
# 						mv -f ${PAIRSELECT}_ADD_PAIRS.txt ${PAIRSELECT}
# 
# 						# Header already added in MergeTables fct in AddPairsNewBaselinePlotTool
# 						#cat two_lines_header.txt table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt > table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_header.txt
# 						#TABLEFORBPERP=table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_header.txt
# 						TABLEFORBPERP=table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt
# 
# 						SUFFIX="0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After"
# 					else
# 						echo "// No additional pairs for set 2 in table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_AdditionalPairs.txt"
# 						
# 				fi	
		fi

		echo
		# Create a initBaselines.txt from allPairsLisint.txt
		#####################################################
		echo "// Create a initBaselines.txt from allPairsLisint.txt"
		echo
		cp allPairsListing.txt initBaselines.txt
		# shape the file
		# remove header, sort, remove leading spaces
		${PATHGNU}/grep -v "#" initBaselines.txt | sort | ${PATHGNU}/gsed "s/^[ \t]*//" > initBaselines_sorted.txt
		#get date of first image 
		FIRSTIMG=`cat initBaselines_sorted.txt | head -1 | ${PATHGNU}/grep -Eo "[0-9]{8} " | head -1`
		# keep only lines starting with FIRSTIMG and keep only col 1 (MAS), 2 (SLV), 3 (BP), and -4 (-Bt) tab separated
		cat initBaselines_sorted.txt | ${PATHGNU}/grep "^${FIRSTIMG}*" | ${PATHGNU}/gawk -v OFS='\t' '{print $1,	$2,	$8,	-$9}' > initBaselines.txt 

		rm -f ListNewDates.txt initBaselines_sorted.txt 

		# Create files for further plots as prepared in build_bperp_files.sh 
		# SM_Approx_baselines.txt and  bperp_file.txt
		# (would be too slow to run it here because it would make the plots again)
		####################################################################
		echo "// Create files for further plots as prepared in build_bperp_files.sh"
		echo
		cp ${TABLEFORBPERP} bperp_file.tmp
 
		# get rid of header if any
		if [ `${PATHGNU}/grep "Master" bperp_file.tmp | wc -c` -gt 0 ] 
			then 
				tail -n +3 bperp_file.tmp > bperp_file
		fi 

		cp allPairsListing.txt SM_Approx_baselines.txt
		# shape the file
		# remove header, sort, remove leading spaces
		${PATHGNU}/grep -v "#" SM_Approx_baselines.txt | sort | ${PATHGNU}/gsed "s/^[ \t]*//" > SM_Approx_baselines_sorted.txt
		# keep only lines containing SM and keep only col 1 (MAS), 2 (SLV), 3 (BP), and -4 (-Bt) tab separated
		cat SM_Approx_baselines_sorted.txt | ${PATHGNU}/grep "${SM}" | ${PATHGNU}/gawk -v OFS='\t' '{print $1,	$2,	$8,	-$9}' > SM_Approx_baselines.txt
		rm -f SM_Approx_baselines_sorted.txt

		rm -f  bperp_file.txt

		i=1
		while read MAS SLV BpPAIR BtPAIR
		do
				echo "// Processing pair ${MAS} ${SLV}"
				echo "//  --> Bp and Bt are  ${BpPAIR} ${BtPAIR}" 
				# Get Bt and Bp for Master-SM pair
				if [ "${MAS}" == "" ] && [ "${SLV}" == "" ]
					then 
						echo "// Ignore empty lines"
					else
						if [ ${MAS} == ${SM} ]
							then 
								BpMAS=0
								BtMAS=0
							else 
								BpMAS=`grep ${MAS} SM_Approx_baselines.txt | cut -f3`
								BtMAS=`grep ${MAS} SM_Approx_baselines.txt | cut -f4`
								if [ ${MAS} -ge ${SM} ]
									then 
									 BtMAS=`echo "(${BtMAS} * -1)" | bc -l `
									 BpMAS=`echo "(${BpMAS} * -1)" | bc -l `
								fi
						fi
						echo "//  --> Bp and Bt of Primary_GlobalPrimary ${MAS}_${SM} are ${BpMAS} ${BtMAS}" 
						# Get Bt and Bp for Slave-SM pair
						if [ ${SLV} == ${SM} ]
							then 
								BpSLV=0	
								BtSLV=0
							else 
								BpSLV=`grep ${SLV} SM_Approx_baselines.txt | cut -f3`		
								BtSLV=`grep ${SLV} SM_Approx_baselines.txt | cut -f4`
								if [ ${SLV} -ge ${SM} ]
									then 
										BtSLV=`echo "(${BtSLV} * -1)" | bc -l `
										BpSLV=`echo "(${BpSLV} * -1)" | bc -l `
								fi
						fi 	
						echo "//  --> Bp and Bt of Secondary_GlobalPrimary ${SLV}_${SM} are ${BpSLV} ${BtSLV}" 
						echo "${i}  ${MAS}  ${SLV}  ${BtPAIR}  ${BpPAIR}  ${BtMAS}  ${BtSLV}  ${BpMAS}  ${BpSLV}" >> bperp_file.txt
						i=`expr "$i" + 1`
				fi
				
		done < bperp_file

		cp SM_Approx_baselines.txt SM_Approx_baselines_${SUFFIX}.txt
		cp bperp_file.txt bperp_file_${SUFFIX}.txt
		
		rm -f  bperp_file.tmp bperp_file

		# Create files for further plots as prepared in plotspan.sh 
		# span.txt and span1.txt
		# (would be too slow to run it here because it would make the plots again)
		####################################################################
		echo "// Create files for further plots as prepared in plotspan.sh"
		echo

		rm -f span.txt span1.txt 

		#while read n m s bp t t1 t2 b1 b2
		while read n m s t bp t1 t2 b1 b2
		do

			yyyy=`echo $m | cut -b 1-4`
			mm=`echo $m | cut -b 5-6`
			dd=`echo $m | cut -b 7-8`

			# date in decimal year : depends on leap year or not. DOY is decreased by 0.5 to mimick noon and avoid prblm at first or last day
			leapm=`${PATHGNU}/gdate --date="${yyyy}1231" +%j`
			mastertemp=`${PATHGNU}/gdate --date="${yyyy}${mm}${dd}" +%j`
			master=`echo ${mastertemp} ${leapm} ${yyyy} | ${PATHGNU}/gawk '{printf("%f",(($1-0.5)/$2) + $3);}'` 
			#master=`echo $yyyy $mm $dm | ${PATHGNU}/gawk '{printf("%.17g\n",$1+(($2-1)*30.25+$3)/365);}'` 

			yyyy=`echo $s | cut -b 1-4`
			mm=`echo $s | cut -b 5-6`
			dd=`echo $s | cut -b 7-8`

			leaps=`${PATHGNU}/gdate --date="${yyyy}1231" +%j`
			slavetemp=`${PATHGNU}/gdate --date="${yyyy}${mm}${dd}" +%j`
			slave=`echo ${slavetemp} ${leaps} ${yyyy} | ${PATHGNU}/gawk '{printf("%f",(($1-0.5)/$2) + $3);}'` 
			#slave=`echo $yyyy $mm $dm | ${PATHGNU}/gawk '{printf("%.17g\n",$1+(($2-1)*30.25+$3)/365);}'` 

			delta=`echo $master, $slave | ${PATHGNU}/gawk '{printf("%f",$2-$1)}'` 

			bpdelta=`echo $b1, $b2 | ${PATHGNU}/gawk '{printf("%f",$2-$1)}'`

			echo $master $b1 $delta $bpdelta >> span.txt

			md=`echo $master $delta | ${PATHGNU}/gawk '{printf("%f",$1+$2)}'`
			bpd=`echo $b1 $bpdelta | ${PATHGNU}/gawk '{printf("%f",$1+$2)}'`

			echo $master $b1 >> span1.txt
			echo $md $bpd >> span1.txt

			let "i=i+1"

		done < bperp_file_${SUFFIX}.txt

		mv span.txt span_${SUFFIX}.txt 
		mv span1.txt span1_${SUFFIX}.txt 

fi

echo 
# Just in case... 
# DO NOT DO THIS BELOW WHEN ADDING PAIRS AS IT WOULD COME BACK TO LIST BEFORE ADDING PAIRS 
# if [ "${DUALCRITERIA}" == "YES" ] && [ -f "${SET}/table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt" ] 
# 	then 
# 		mv -f table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt 	2>/dev/null
# fi

rm two_lines_header.txt

# Remove possible double blank lines 

${PATHGNU}/gsed -i '/^$/N;/^\n$/D' ${SET}/table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt 

echo 
echo "// All done; hope it worked"


########################################################################################
# If OLD tools
# 	If NO DUAL
# 		=> Compute selection with BP and BT: table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt
# 			via
# 				timeSorting ${SET}
# 				initiateBaselinesComputation ${SET}
# 				approximateBaselines ${SET}/setParametersFile.txt
# 				selectInterferometricPairs ${SET}/setParametersFile.txt
# 
# 	If DUAL
# 		=> Compute selection part 1 with BP1 and BT1 etc: 	table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}.txt 
# 															table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}.txt
# 		=> Compute selection part 2 with BP2 and BT2 etc: 	table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}.txt 
# 															table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_${DATECHANGE}.txt
# 		=> Merge tables: table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After.txt
# 		
# 		
# New SM ? 
# YES: 
# 	If OLD		
# 		If NO DUAL: 
# 			=> Compute SM (using globalMaster ${SET}/approximateBaselinesTable.txt)
# 		If DUAL: 
# 			=> Compute SM on part 1 (using globalMaster ${SET}/approximateBaselinesTable.txt)
# 	If NEW: 
# 		ProcessBaselinePlotNewMethod, i.e. 
# 			If NO DUAL: 
# 				=> Create BaselinePlot (using baselinePlot ${SET} ${SET} BpMax=${BP} dTMax=${BT})
# 				=> Calcule SM
# 			If DUAL: 
# 				=> Create BaselinePlot on part 1 (using baselinePlot ${SET} ${SET} BpMax=${BP1} dTMax=${BT1})
# 				=> Calcule SM on part 1 
# 				=> Create BaselinePlot on part 2 (using baselinePlot ${SET} ${SET} BpMax=${BP2} dTMax=${BT2})
# 				=> Create BaselinePlot on MAX (using baselinePlot ${SET} ${SET} BpMax=${BPMAX} dTMax=${BTMAX})
# 				
# 				=> Merge tables : table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt
# 				=> draw Merged baseline Plot
# NO: 
# 	If OLD		
# 		=> keep SM=SMFORCED	(or take a new one if does not exist yet)		
# 	If NEW: 
# 		If already computed
# 			=> Read existing SM 
# 			=> ProcessBaselinePlotNewMethod: compute baselinePlot (Dual or not)
# 			If SMFORCED not same as SM (existing or new), create new plots
# 				and get	table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt
# 				or 		table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt
# 		
# 		If not yet
# 			=> ProcessBaselinePlotNewMethod: compute baselinePlot (Dual or not)
# 			Change SM and make new plots using SMFORCED
# 				and get table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt
# 				or 		table_0_${BP}_0_${BT}.txt
# 							
# In case of AdditionalPAirs: 
# If OLD		
# 	If NO DUAL: 	
# 		=> MergeTables table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt
# 		=> build and plot bperp_file_${BPMIN}_${BP}_${BTMIN}_${BT}.txt	
# 	If DUAL: 
# 		=> MergeTables table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}.txt table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_AdditionalPairs.txt 
# 		=> MergeTables table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_${DATECHANGE}.txt table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_AdditionalPairs.txt 
# 		=> keep copy oftable_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After.txt 
# 			as table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After_BEFORE_ADDITIONAL_PAIRS.txt
# 		=> merge tables Before and After and add header in 
# 			table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After.txt
# 		=> build and plot bperp_file_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_Before_${DATECHANGE}_And_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_After.txt
# If NEW		
# 	If NO DUAL: 	
# 		=> AddPairsNewBaselinePlotTool table_${BPMIN}_${BP}_${BTMIN}_${BT}.txt table_${BPMIN}_${BP}_${BTMIN}_${BT}_AdditionalPairs.txt selectedAcquisitionsSpatialRepartition_BpMax=${BP}_BTMax=${BT}.txt selectedPairsListing_BpMax=${BP}_BTMax=${BT}.txt	
# 
# 	If DUAL:
# 		=> AddPairsNewBaselinePlotTool table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt table_${BPMIN1}_${BP1}_${BTMIN1}_${BT1}_AdditionalPairs.txt restrictedAcquisitionsRepartition.txt_table_Dummy_0_BP1_0_BT1_Till_DATECHG_0_BP2_0_BT2_After.txt restrictedPairSelection_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt
# 			and rename as default for part 2 if needed
#  
# 		=> AddPairsNewBaselinePlotTool table_0_${BP1}_0_${BT1}_Till_${DATECHANGE}_0_${BP2}_0_${BT2}_After.txt table_${BPMIN2}_${BP2}_${BTMIN2}_${BT2}_AdditionalPairs.txt restrictedAcquisitionsRepartition.txt_table_Dummy_0_BP1_0_BT1_Till_DATECHG_0_BP2_0_BT2_After.txt restrictedPairSelection_Dummy_BpMax=${BP1}_MAS_SLV_Before_${DATECHANGE}_Dummy_BpMax=${BP2}_MAS_SLV_After_${DATECHANGE}.txt
# 			and rename as default 	
# 			
# 			
# 	Create a initBaselines.txt from allPairsLisint.txt
# 	
# 	Create files for further plots as prepared in build_bperp_files.sh
# 

