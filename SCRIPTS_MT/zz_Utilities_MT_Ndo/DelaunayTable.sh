#!/bin/bash
######################################################################################
# This scripts computes an unweighted Delaunay triangulation based on the file  allPairsListing_Without_Quanrantained_Data.txt in the pwd. 
#
# 3 options are possible:
#	-BpMax=val in m: Delaunay triangles' Bp segments of more than val in m will be ignored 
#	-BtMax=val in days: Delaunay triangles' Bt segments of more than val in days will be ignored  
#	-Ratio=integer: ratio between X and Y axis for Delaunay triangulation to avoid elongated triangles
#                   i.e. 1m Bp is orthogonal to 1 day/float Bt (1m ortho to 1 day if no ratio provided) 
#
# It creates :
#		- a file named table_0_0_DelaunayRatioMaxBtMaxBp_0.txt 
#			that contains all the list of pairs for the mass processing (naming depends on parameters),
#		- a file named Delaunay_Triangulation_MaxBtdays_MaxBpm_xyRatio_PairsforPlot.txt 
#			that contains all the list of pairs for plotting with baselinePlot (naming depends on parameters),
#		- a figure named baselinePlot_Delaunay_Triangulation_xyRatioMaxBtMaxBp_PairsforPlot.txt.png 
#			with the baseline plot (naming depends on parameters)
#
# Requirements:	- it must be launched in the /.../SAR_SM/MSBAS/YourRegion/seti directory
#				- it needs the file allPairsListing.txt in that directory (computed with Prepa_MSBAS.sh)
#
# Dependencies:	- python script DelaunayTable.py
#
# New in Distro V 1.1 (Sept 21, 2023):	- do not filter Bp or Bt in python because it seems to cause (rare) problems
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20231219:	- Debug plots and table names when no Bt nor Bt restricted
# New in Distro V 2.2 20231223:	- Remove images from allPairsListing.txt that are in Quarantained 
# New in Distro V 2.3 20231229:	- Check that PATHTOQUANRANTINEDDATA contains subdirs named *.csl + is not empty
# New in Distro V 2.4 20240423:	- display max and mean Bp, Bt and nr of pairs
# New in Distro V 2.5 20240620:	- mute find error message when there is no quarantine data
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.5 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on June 20, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

PARAMFORPYTHON=""
TITLESTRING=""

RUNDIR=`pwd`
eval RNDM=`echo $(( $RANDOM % 10000 ))`


echo " //----------------------------------------------------------------------------------------------------"
echo " //You can run this script with the following parameters: -Ratio=float , -BpMax=integer, -BtMax=integer"
echo " //----------------------------------------------------------------------------------------------------"
echo
# Check if requires ratio
if [[ "${@#-Ratio=}" = "$@" ]]
	then
		echo " //Do not request Ratio for Delaunay triangulation."
		TITLESTRING=" 1m is orthogonal to 1day "
	else
		RATIO=`echo "$@" | ${PATHGNU}/gsed  's/.*-Ratio=//'  | cut -d " " -f 1`	# get everything -ratio= and before next " "
		echo " //Request Ratio ${RATIO} for Delaunay triangulation."
		#PARAMFORPYTHON=$(echo "${PARAMFORPYTHON} -Ratio=${RATIO}")
		PARAMFORPYTHON="-Ratio=${RATIO}"
		TITLESTRING=" 1m is orthogonal to 1day/${RATIO}"
fi
# Check if requires max Bp
if [[ "${@#-BpMax=}" = "$@" ]]
	then
		echo " //Do not restrict Delaunay triangulation with maximum Perpendicular Baseline."
		TITLESTRING=$(echo "${TITLESTRING} ; without Bp restriction")
	else
		MAXBP=`echo "$@" | ${PATHGNU}/gsed  's/.*-BpMax=//'  | cut -d " " -f 1`	# get everything -BpMax= and before next " "
		echo " //Restrict Delaunay triangulation to Perpendicular Baseline smaller than ${MAXBP}."
		#PARAMFORPYTHON=$(echo "${PARAMFORPYTHON} -BpMax=${MAXBP}")
		TITLESTRING=$(echo "${TITLESTRING} ; with Bp<${MAXBP}m")
fi
# Check if requires max Bt
if [[ "${@#-BtMax=}" = "$@" ]]
	then
		echo " //Do not restrict Delaunay triangulation with maximum Temporal Baseline."
		TITLESTRING=$(echo "${TITLESTRING} ; without Bt restriction")
	else
		MAXBT=`echo "$@" | ${PATHGNU}/gsed  's/.*-BtMax=//'  | cut -d " " -f 1`	# get everything -BtMax= and before next " "
		echo " //Restrict Delaunay triangulation to Temporal Baseline smaller than ${MAXBT}."
		#PARAMFORPYTHON=$(echo "${PARAMFORPYTHON} -BtMax=${MAXBT}")
		TITLESTRING=$(echo "${TITLESTRING} ; with Bt<${MAXBT}days")
fi
echo 

# Get the path to original data 
LASTLINK=$(find . -maxdepth 1 -name '*.csl' -exec basename {} \; | tail -1) 2>/dev/null
PATHTOQUANRANTINEDDATA=$(readlink -f ${LASTLINK} | ${PATHGNU}/gawk -F"NoCrop" '/NoCrop/{print $1 "Quarantained"}') 2>/dev/null # read target of link and get everything before NoCrop and add Quanrantined at the end

# Just in case, remove pairs with images that would be stored in .../SAR_CSL/sat/mode/Quarantained
if [ -n "$(find "${PATHTOQUANRANTINEDDATA}" -type d -name '*.csl' -print -quit)" ] && [ -n "$(ls -A "${PATHTOQUANRANTINEDDATA}")" ]   # Check that dir contains subdirs named *.csl and is not empty
	then
		echo " // Remove images from allPairsListing.txt that are in ${PATHTOQUANRANTINEDDATA}."
		# get the date of img from dir names in /Quarantained  
		find "${PATHTOQUANRANTINEDDATA}" -maxdepth 1 -name '*.csl' -exec basename {} \; | ${PATHGNU}/grep -Eo '[0-9]{8}' 2> /dev/null > Quarantained_dates.txt
		# remove all pairs with img in Quanrnatine from allPairsListing.txt
		cp "allPairsListing.txt" "allPairsListing_Without_Quanrantained_Data.txt"
		while IFS= read -r QUARANTAINEDIMG
			do
				if [ "${QUARANTAINEDIMG}" != "" ] ; then 
					${PATHGNU}/grep -v "${QUARANTAINEDIMG}" "allPairsListing_Without_Quanrantained_Data.txt" > "allPairsListing_Without_Quanrantained_Data_tmp.txt"
					cp -f "allPairsListing_Without_Quanrantained_Data_tmp.txt" "allPairsListing_Without_Quanrantained_Data.txt"
				fi
		done < "Quarantained_dates.txt"
	else 
		echo " // No quarantined data in ${PATHTOQUANRANTINEDDATA}. Copy allPairsListing.txt as allPairsListing_Without_Quanrantained_Data.txt"
		cp allPairsListing.txt allPairsListing_Without_Quanrantained_Data.txt
fi

python ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT_Ndo/DelaunayTable.py ${PARAMFORPYTHON}

echo
if [ "${MAXBP}" != "" ] && [ "${MAXBT}" != "" ] ; then
		# clean table_0_0_DelaunayRatio_0.txt for off baselines => mass processing
		# i.e. 4 col (2 lines header) Mas Slv Bp Bt
		if [ "${RATIO}" == "" ]
			then 
				TABLETOCLEAN=table_0_0_DelaunayNoRatio
			else
				# Ratio is provided to python as a float, hence naming may vary because of possible addition of .0 in Ratio name
				RATIONAME=`echo table_0_0_DelaunayRatio${RATIO}*_0.txt | cut -d o -f 2 | cut -d  _ -f 1`
				TABLETOCLEAN=table_0_0_DelaunayRatio${RATIONAME}	
		fi
		echo " //Filter ${TABLETOCLEAN}_0.txt: remove pairs with Bp > ${MAXBP} and Bt > ${MAXBT}"

		# filter from line 3 the values above Max Bp and Bt in col 3 and 4
		${PATHGNU}/gawk 'NR <= 2 || ($3 >= -'${MAXBP}' && $3 <= '${MAXBP}')' ${TABLETOCLEAN}_0.txt > ${TABLETOCLEAN}_0_${RNDM}_tmp.txt
		${PATHGNU}/gawk 'NR <= 2 || ($4 >= -'${MAXBT}' && $4 <= '${MAXBT}')' ${TABLETOCLEAN}_0_${RNDM}_tmp.txt > ${TABLETOCLEAN}_0_MaxBt${MAXBT}MaxBp${MAXBP}_0.txt
		rm -f ${TABLETOCLEAN}_0_${RNDM}_tmp.txt

		# clean Delaunay_Triangulation_NoRatio_PairsforPlot.txt for off baselines => plotting 
		# i.e. 4 col (no header ) Dummy Bp Mas Slv
		if [ "${RATIO}" == "" ]
			then 
				TABLETOCLEAN=Delaunay_Triangulation_NoRatio
			else
				# Ratio is provided to python as a float, hence naming may vary because of possible addition of .0 in Ratio name
				TABLETOCLEAN=Delaunay_Triangulation_xyRatio${RATIONAME}	
		fi
		echo " //Filter ${TABLETOCLEAN}_PairsforPlot.txt: remove pairs with Bp > ${MAXBP} and Bt > ${MAXBT}"

		${PATHGNU}/gawk '{if ($2 >= -'$MAXBP' && $2 <= '$MAXBP') print}' ${TABLETOCLEAN}_PairsforPlot.txt >  ${TABLETOCLEAN}_PairsforPlot_${RNDM}_tmp.txt 
		# compare difference between dates in col 3 and 4 to Bt and remove is above
		${PATHGNU}/gawk -v threshold="${MAXBT}" '{ date1 = $3; date2 = $4; 
			cmd = "date -d " date1 " +%s"; cmd | getline timestamp1; close(cmd); 
			cmd = "date -d " date2 " +%s"; cmd | getline timestamp2; close(cmd); 
			if (sqrt((timestamp2 - timestamp1)*(timestamp2 - timestamp1)) <= threshold * 86400 ) { print; } 	
		}' ${TABLETOCLEAN}_PairsforPlot_${RNDM}_tmp.txt > ${TABLETOCLEAN}MaxBt${MAXBT}MaxBp${MAXBP}_PairsforPlot.txt

		rm -f ${TABLETOCLEAN}_PairsforPlot_${RNDM}_tmp.txt
		TABLETOPLOT=${TABLETOCLEAN}MaxBt${MAXBT}MaxBp${MAXBP}_PairsforPlot.txt

	elif [ "${MAXBT}" != "" ] ; then
		# clean table_0_0_DelaunayRatio_0.txt for off baselines => mass processing
		# i.e. 4 col (2 lines header) Mas Slv Bp Bt
		if [ "${RATIO}" == "" ]
			then 
				TABLETOCLEAN=table_0_0_DelaunayNoRatio
			else
				# Ratio is provided to python as a float, hence naming may vary because of possible addition of .0 in Ratio name
				RATIONAME=`echo table_0_0_DelaunayRatio${RATIO}*_0.txt | cut -d o -f 2 | cut -d  _ -f 1`
				TABLETOCLEAN=table_0_0_DelaunayRatio${RATIONAME}	
		fi
		echo " //Filter ${TABLETOCLEAN}_0.txt: remove pairs with Bt > ${MAXBT}"

		# filter from line 3 the values above Max Bt in col and 4
		${PATHGNU}/gawk 'NR <= 2 || ($4 >= -'${MAXBT}' && $4 <= '${MAXBT}')' ${TABLETOCLEAN}_0.txt > ${TABLETOCLEAN}_0_MaxBt${MAXBT}_0.txt

		# clean Delaunay_Triangulation_NoRatio_PairsforPlot.txt for off baselines => plotting 
		# i.e. 4 col (no header ) Dummy Bp Mas Slv
		if [ "${RATIO}" == "" ]
			then 
				TABLETOCLEAN=Delaunay_Triangulation_NoRatio
			else
				# Ratio is provided to python as a float, hence naming may vary because of possible addition of .0 in Ratio name
				TABLETOCLEAN=Delaunay_Triangulation_xyRatio${RATIONAME}	
		fi
		echo " //Filter ${TABLETOCLEAN}_PairsforPlot.txt: remove pairs with Bt > ${MAXBT}"

		# compare difference between dates in col 3 and 4 to Bt and remove is above
		${PATHGNU}/gawk -v threshold="${MAXBT}" '{ date1 = $3; date2 = $4; 
			cmd = "date -d " date1 " +%s"; cmd | getline timestamp1; close(cmd); 
			cmd = "date -d " date2 " +%s"; cmd | getline timestamp2; close(cmd); 
			if (sqrt((timestamp2 - timestamp1)*(timestamp2 - timestamp1)) <= threshold * 86400 ) { print; } 	
		}' ${TABLETOCLEAN}_PairsforPlot.txt > ${TABLETOCLEAN}MaxBt${MAXBT}_PairsforPlot.txt

		TABLETOPLOT=${TABLETOCLEAN}MaxBt${MAXBT}_PairsforPlot.txt

	elif [ "${MAXBP}" != "" ] ; then
		# clean table_0_0_DelaunayRatio_0.txt for off baselines => mass processing
		# i.e. 4 col (2 lines header) Mas Slv Bp Bt
		if [ "${RATIO}" == "" ]
			then 
				TABLETOCLEAN=table_0_0_DelaunayNoRatio
			else
				# Ratio is provided to python as a float, hence naming may vary because of possible addition of .0 in Ratio name
				RATIONAME=`echo table_0_0_DelaunayRatio${RATIO}*_0.txt | cut -d o -f 2 | cut -d  _ -f 1`
				TABLETOCLEAN=table_0_0_DelaunayRatio${RATIONAME}	
		fi
		echo " //Filter ${TABLETOCLEAN}_0.txt: remove pairs with Bp > ${MAXBP} "

		# filter from line 3 the values above Max Bp in col 3 
		${PATHGNU}/gawk 'NR <= 2 || ($3 >= -'${MAXBP}' && $3 <= '${MAXBP}')' ${TABLETOCLEAN}_0.txt > ${TABLETOCLEAN}_0_MaxBp${MAXBP}_0.txt

		# clean Delaunay_Triangulation_NoRatio_PairsforPlot.txt for off baselines => plotting 
		# i.e. 4 col (no header ) Dummy Bp Mas Slv
		if [ "${RATIO}" == "" ]
			then 
				TABLETOCLEAN=Delaunay_Triangulation_NoRatio
			else
				# Ratio is provided to python as a float, hence naming may vary because of possible addition of .0 in Ratio name
				TABLETOCLEAN=Delaunay_Triangulation_xyRatio${RATIONAME}	
		fi
		echo " //Filter ${TABLETOCLEAN}_PairsforPlot.txt: remove pairs with Bp > ${MAXBP}"

		${PATHGNU}/gawk '{if ($2 >= -'$MAXBP' && $2 <= '$MAXBP') print}' ${TABLETOCLEAN}_PairsforPlot.txt > ${TABLETOCLEAN}MaxBp${MAXBP}_PairsforPlot.txt
		
		TABLETOPLOT=${TABLETOCLEAN}MaxBp${MAXBP}_PairsforPlot.txt
		
	else 
		if [ "${RATIO}" == "" ]
			then 
				TABLETOPLOT=Delaunay_Triangulation_NoRatio_PairsforPlot.txt  
			else
				# Ratio is provided to python as a float, hence naming may vary because of possible addition of .0 in Ratio name
				RATIONAME=`echo table_0_0_DelaunayRatio${RATIO}*_0.txt | cut -d o -f 2 | cut -d  _ -f 1`
				TABLETOPLOT=Delaunay_Triangulation_xyRatio${RATIONAME}_PairsforPlot.txt  
		fi
		echo " //Nobaseline filtering requested of "

fi

echo
echo " //Create the new baseline plot"
echo

# Get Max Bp and Bt as well as nr of pairs
NRPAIRS=$(cat ${RUNDIR}/${TABLETOPLOT} | wc -l )

# get the max and mean of absolute values for Bp and Bt
MEANBP=0
SUMBP=0
COUNT_LINES=0
MAXBP=0
ABS_VAL=0

MEANBT=0
SUMBT=0
MAXBT=0
tst1=0
tst2=0
abs_diff=0

while IFS=$'\t' read -r _ value date1 date2; do
    # Check if the value in column 2 (Bp) is numeric - avoid possible header
    if [[ $value =~ ^-?[0-9]*(\.[0-9]+)?$ ]]; then
 		# sum the abs of Bp
        ABS_VAL=$(echo "scale=10; if ($value < 0) -1*$value else $value" | bc)
        SUMBP=$(echo "$SUMBP + $ABS_VAL" | bc)
        ((COUNT_LINES++))
        # Get the max of Bp
        if (( $(echo "$ABS_VAL > $MAXBP" | bc -l) )) ; then MAXBP=$ABS_VAL  ; fi 

		# transform the dates in days
    	ts1=$(date -d "$date1" +%s)
    	ts2=$(date -d "$date2" +%s)
    	
    	# Calculate the difference in days and its absolute value
    	diff=$(( (ts2 - ts1) / (60*60*24) ))
    	abs_diff=${diff#-} # Get absolute value of difference
	
		# Get the max Bt
    	if (( $(echo "$abs_diff > $MAXBT" | bc -l) )) ; then MAXBT=$abs_diff  ; fi 
	
    	# Accumulate the absolute difference and increment the count
    	#SUMBT=$((SUMBT + abs_diff))
    	SUMBT=$(echo "$SUMBT + $abs_diff" | bc)
    fi
done < "${RUNDIR}/${TABLETOPLOT}"

# Compute the mean of absolute values of all numbers in column 2
MEANBP=$(echo "scale=10; $SUMBP / $COUNT_LINES" | bc)
MEANBP=$(printf "%.2f" "$MEANBP")
# Compute the mean of all absolute differences in time
MEANBT=$(echo "scale=2; $SUMBT / $COUNT_LINES" | bc)

echo "${NRPAIRS} pairs ; Max ${MAXBP}m and ${MAXBT}days"
echo "	Mean of absolute baseline values : ${MEANBP}m ans ${MEANBT}days "
echo ""

# plot proper baseline plot
baselinePlot -r ${RUNDIR} ${RUNDIR}/${TABLETOPLOT}

# update gnuplot and re-run to take into account the options 
search_string="All pairs considered"
replacement_string="Delaunay Triangulation pairs considered: ${TITLESTRING}  "

# Use sed to search and replace
${PATHGNU}/gsed -i "s%${search_string}%${replacement_string}%" baselinePlot.gnuplot

search_sm="Super Master date:"
replacement_sm="${NRPAIRS} pairs ; Max ${MAXBP}m and ${MAXBT}days ; Mean ${MEANBP}m and ${MEANBT}days ; Super Master date: "

# Use sed to search and replace
${PATHGNU}/gsed -i "s%${search_sm}%${replacement_sm}%" baselinePlot.gnuplot


echo
echo " //Replot with appropriate title"
gnuplot baselinePlot.gnuplot
echo 

## remove python baseline plot 
#PYTHONPLOT=`find ${RUNDIR} -type f -name 'Delaunay_Triangulation_Plot*.png' -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d ' ' -f 2-`
#rm -f ${PYTHONPLOT}

echo
echo " //++++++++++++++++++++++++++++++++++++++++++++++++"
echo " // All done - HOPE IT WORKED"
echo " //++++++++++++++++++++++++++++++++++++++++++++++++"
