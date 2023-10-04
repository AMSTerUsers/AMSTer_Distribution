#!/bin/bash
######################################################################################
# This scripts computes an unweighted Delaunay triangulation based on the file  allPairsListing.txt in the pwd. 
#
# 3 options are possible:
#	-BpMax=val in m: Delaunay triangles' Bp segments of more than val in m will be ignored 
#	-BpMax=val in days: Delaunay triangles' Bt segments of more than val in days will be ignored  
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
# New in Distro V 1.1:	- do not filter Bp or Bt in python because it seems to cause (rare) problems
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2023/09/19 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2023, Last modified on Sept 21, 2023"
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
				TABLETOCLEAN=table_0_0_DelaunayNoRatio
			else
				# Ratio is provided to python as a float, hence naming may vary because of possible addition of .0 in Ratio name
				RATIONAME=`echo table_0_0_DelaunayRatio${RATIO}*_0.txt | cut -d o -f 2 | cut -d  _ -f 1`
				TABLETOCLEAN=table_0_0_DelaunayRatio${RATIONAME}	
		fi

		TABLETOPLOT=${TABLETOCLEAN}_PairsforPlot.txt
		echo " //Nobaseline filtering requested of "

fi

echo
echo " //Create the new baseline plot"
echo
# plot proper baseline plot
baselinePlot -r ${RUNDIR} ${RUNDIR}/${TABLETOPLOT}

# update gnuplot and re-run to take into account the options 
search_string="All pairs considered"
replacement_string="Delaunay Triangulation pairs considered: ${TITLESTRING}"


# Use sed to search and replace
${PATHGNU}/gsed -i "s%${search_string}%${replacement_string}%" baselinePlot.gnuplot

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
