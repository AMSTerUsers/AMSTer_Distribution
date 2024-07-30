#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at extracting from allPairsListing.txt
#   x (positive integer) shortest connections between all the pairs and plot the baseline plot. 
# It creates :
#		- a file named table_0_0_MaxShortest_x.txt that contains all the list of pairs for the mass processing,
#		- a file named allPairsListing_Max${MAX}.txt that contains all the list of pairs for plotting with baselinePlot
#		- a figure named baselinePlot_table_max_x.txt.png with the baseline plot
#
#
# Parameters : 	- path to allPairsListing.txt table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/allPairsListing.txt)
#				- max number of connection (e.g. 3)
#
#
# Dependencies:	- gnu grep and awk for more compatibility
#
# Hard coded:	- 
#
# V 1.0 (Sept 18, 2020)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20231227:	- Remove images from allPairsListing.txt that are in Quarantained 
# New in Distro V 2.2 20231229:	- Check that PATHTOQUANRANTINEDDATA contains subdirs named *.csl + is not empty
#								- also cp table_0_0_MaxShortest_${MAX}_Without_Quanrantained_Data.txt if no Quarantined data
# New in Distro V 2.3 20240423:	- display max and mean Bp, Bt and nr of pairs
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Apr 23, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

MSBASTABLE=$1			# path to MSBAS table (e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6/allPairsListing.txt)
MAX=$2					# max number of connection (e.g. 3)


PATHTABLEDIR=$(dirname "${MSBASTABLE}")


cd ${PATHTABLEDIR}

tail -n +8  ${MSBASTABLE} > allPairsListing_NoHeader.txt
head -7 ${MSBASTABLE} > Header_tmp.txt

# Just in case.... sort on master, then slave, then Bt then Bp
sort -n -k1,1 -k2,2 -k9,9 -k8,8  allPairsListing_NoHeader.txt > allPairsListing_Sort_1_2_9_8.txt

rm -f ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt
for IMG in `${PATHGNU}/gawk '{print $1}' allPairsListing_NoHeader.txt | sort | uniq`
do 
	${PATHGNU}/grep ^"    ${IMG}" -m ${MAX} allPairsListing_Sort_1_2_9_8.txt >> ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt
done 

rm -f allPairsListing_Sort_1_2_9_8.txt

echo "  Master	   Slave	 Bperp	 Delay" > ${PATHTABLEDIR}/table_max_${MAX}_ForPlot.txt
echo " " >> ${PATHTABLEDIR}/table_max_${MAX}_ForPlot.txt

# new tool requires file with Dummy Bp Mas Slv for plotting
${PATHGNU}/gawk '{print "Dummy \t" $8 "\t" $1 "\t" $2}' ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt > ${PATHTABLEDIR}/table_max_${MAX}_ForPlot.txt

# creates table file with all pairs selected for mass processing 
echo "   Master	   Slave	 Bperp	 Delay" > ${PATHTABLEDIR}/table_0_0_MaxShortest_${MAX}.txt
echo "" >> ${PATHTABLEDIR}/table_0_0_MaxShortest_${MAX}.txt
${PATHGNU}/gawk '{print $1 "\t" $2 "\t" $8 "\t\t" $9}' ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt >> ${PATHTABLEDIR}/table_0_0_MaxShortest_${MAX}.txt

# add headers
cat Header_tmp.txt ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt > ${PATHTABLEDIR}/allPairsListing_Max${MAX}.txt 
rm -f ${PATHTABLEDIR}/allPairsListing_Max${MAX}_NoHdr.txt

# Just in case, remove pairs with images that would be stored in .../SAR_CSL/sat/mode/Quarantained
# Get the path to original data 
LASTLINK=$(find . -maxdepth 1 -name '*.csl' -exec basename {} \; | tail -1) 2>/dev/null
PATHTOQUANRANTINEDDATA=$(readlink -f ${LASTLINK} | ${PATHGNU}/gawk -F"NoCrop" '/NoCrop/{print $1 "Quarantained"}') 2>/dev/null # read target of link and get everything before NoCrop and add Quanrantined at the end


if [ -n "$(find "${PATHTOQUANRANTINEDDATA}" -type d -name '*.csl' -print -quit)" ] && [ -n "$(ls -A "${PATHTOQUANRANTINEDDATA}")" ]   # Check that dir contains subdirs named *.csl and is not empty
	then
		echo " // Remove images from allPairsListing_Max${MAX}.txt  that are in ${PATHTOQUANRANTINEDDATA}."
		# get the date of img from dir names in /Quarantained  
		find "${PATHTOQUANRANTINEDDATA}" -maxdepth 1 -name '*.csl' -exec basename {} \; | ${PATHGNU}/grep -Eo '[0-9]{8}' > Quarantained_dates.txt
		# remove all pairs with img in Quanrnatine from allPairsListing_Max${MAX}.txt 
		cp -f "allPairsListing_Max${MAX}.txt" "allPairsListing_Max${MAX}_Without_Quanrantained_Data.txt"

		echo " //     as well as from table_0_0_MaxShortest_${MAX}.txt and table_max_${MAX}_ForPlot.txt  "
		# remove all pairs with img in Quanrnatine from table_max_${MAX}_ForPlot.txt
		cp -f "table_0_0_MaxShortest_${MAX}.txt" "table_0_0_MaxShortest_${MAX}_Without_Quanrantained_Data.txt"
		cp -f "table_max_${MAX}_ForPlot.txt" "table_max_${MAX}_ForPlot_Without_Quanrantained_Data.txt"
		
		while IFS= read -r QUARANTAINEDIMG
			do
				if [ "${QUARANTAINEDIMG}" != "" ] ; then 
					# Table
					${PATHGNU}/grep -v "${QUARANTAINEDIMG}" "allPairsListing_Max${MAX}_Without_Quanrantained_Data.txt" > "allPairsListing_Max${MAX}_Without_Quanrantained_Data_tmp.txt"
					cp -f "allPairsListing_Max${MAX}_Without_Quanrantained_Data_tmp.txt" "allPairsListing_Max${MAX}_Without_Quanrantained_Data.txt"
					# table
					${PATHGNU}/grep -v "${QUARANTAINEDIMG}" "table_0_0_MaxShortest_${MAX}_Without_Quanrantained_Data.txt" > "table_0_0_MaxShortest_${MAX}_Without_Quanrantained_Data_tmp.txt"
					cp -f "table_0_0_MaxShortest_${MAX}_Without_Quanrantained_Data_tmp.txt" "table_0_0_MaxShortest_${MAX}_Without_Quanrantained_Data.txt"
					# table_ForPlot
					${PATHGNU}/grep -v "${QUARANTAINEDIMG}" "table_max_${MAX}_ForPlot_Without_Quanrantained_Data.txt" > "table_max_${MAX}_ForPlot_Without_Quanrantained_Data_tmp.txt"
					cp -f "table_max_${MAX}_ForPlot_Without_Quanrantained_Data_tmp.txt" "table_max_${MAX}_ForPlot_Without_Quanrantained_Data.txt"
				fi
		done < "Quarantained_dates.txt"
	else 
		echo " // No quarantined data in ${PATHTOQUANRANTINEDDATA}. Copy allPairsListing_Max${MAX}.txt as allPairsListing_Max${MAX}_Without_Quanrantained_Data.txt"
		cp -f allPairsListing_Max${MAX}.txt allPairsListing_Max${MAX}_Without_Quanrantained_Data.txt
		echo " //     and table_max_${MAX}_ForPlot.txt as table_max_${MAX}_ForPlot_Without_Quanrantained_Data.txt"
		cp -f table_max_${MAX}_ForPlot.txt table_max_${MAX}_ForPlot_Without_Quanrantained_Data.txt
		echo " //     and table_0_0_MaxShortest_${MAX}.txt as table_0_0_MaxShortest_${MAX}_Without_Quanrantained_Data.txt"
		cp -f table_0_0_MaxShortest_${MAX}.txt table_0_0_MaxShortest_${MAX}_Without_Quanrantained_Data.txt

fi





# Get Max Bp and Bt as well as nr of pairs
NRPAIRS=$(cat ${PATHTABLEDIR}/table_max_${MAX}_ForPlot_Without_Quanrantained_Data.txt | wc -l )

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
done < "${PATHTABLEDIR}/table_max_${MAX}_ForPlot_Without_Quanrantained_Data.txt"

# Compute the mean of absolute values of all numbers in column 2
MEANBP=$(echo "scale=10; $SUMBP / $COUNT_LINES" | bc)
MEANBP=$(printf "%.2f" "$MEANBP")
# Compute the mean of all absolute differences in time
MEANBT=$(echo "scale=2; $SUMBT / $COUNT_LINES" | bc)

echo "${NRPAIRS} pairs ; Max ${MAXBP}m and ${MAXBT}days"
echo "	Mean of absolute baseline values : ${MEANBP}m ans ${MEANBT}days "
echo ""


# make the plot
baselinePlot -r ${PATHTABLEDIR} ${PATHTABLEDIR}/table_max_${MAX}_ForPlot_Without_Quanrantained_Data.txt


# update gnuplot and re-run to take into account the options 
search_string="All pairs considered"
replacement_string="Max ${MAX} shortests connections. No baselines (Bp or Bt) restriction."

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



rm -f allPairsListing_NoHeader.txt Header_tmp.txt

echo "------------------------------------"
echo "All img taken ${MAX} times "
echo "------------------------------------"

