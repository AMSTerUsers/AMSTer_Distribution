#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at re-plotting LoS double difference time series of points  
# after a msbas processing performed from an automated cron step3. 
# The scripts is to be run after a complete msbas processing performed in a cron step 3.
#
# The script MUST be launched in the dir where the msbas was performed, e.g. 
#     $PATH_3602/MSBAS/_REGION_SAT_Auto
# 
# Parameters are : 
#       - a list of pair of points and its description (e.g. ${PATH_SCRIPTS}/SCRIPTS_MT/_cron_scripts/List_DoubleDiff_EW_UD_${LABEL}.txt)
#			It must contain lines like e.g.
#				1795 1398 1803 1373 _BOR_BOM_NS_WestSide
#		- the mode (e.g. Asc or 3987_L_D (must be as in the name of the dir in msbas dir)
# 		- the string that follows zz_EW or zz_UD in the name of the dir where the results of the msbas are stored 
# 			(e.g. _Auto_2_0.004_PF)
#		- optional; a path to EVENTS table for plotting on the figure (e.g. ${PATH_1650}/EVENTS_TABLES/${LABEL})
#
#       
# Dependencies:	- PlotTS.sh
#
# New in Distro V 1.1 20251114:	- quote variables; cosmetic
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Nov 14, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

FILEPAIRS=$1 			# e.g. "${PATH_SCRIPTS}/SCRIPTS_MT/_cron_scripts/List_DoubleDiff_LOS_Region.txt"
MODE=$2					# e.g. Asc or 3987_L_D (must be as in the name of the dir in msbas dir)
INVERTIONPARAM=$3		# e.g. _Auto_2_0.04_PF
EVENTS=$4				# e.g. ${PATH_1650}/EVENTS_TABLES/Region

# Test if EW and UD data are in pwd 
MSBASDIR=$(pwd)

LOSDATADIR="${MSBASDIR}/zz_LOS_${MODE}${INVERTIONPARAM}"

if [ -d "${LOSDATADIR}" ] && [ "$(ls -A $LOSDATADIR)" ] ; then
	echo "  // OK, LOS ${MODE} Directory exists. "
else
	echo "  // Directory ${MSBASDIR}/zz_LOS_${MODE}${INVERTIONPARAM} with msbas results does not exist or is empty. Please check...."
	exit
fi

function PlotAllLOS()
	{
	unset X1 Y1 X2 Y2 DESCRIPTION 
	local X1=$1
	local Y1=$2
	local X2=$3
	local Y2=$4
	local DESCRIPTION=$5

	cd ${MSBASDIR}/zz_LOS_"${MODE}""${INVERTIONPARAM}"/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/_Time_series

	if [ "${EVENTS}" == "" ]
		then
			${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g # remove -f if does not want the linear fit
		else
			${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events="${EVENTS} " # remove -f if does not want the linear fit etc..		
	fi


	COORDLABELNAME1=${X1}_${Y1}"${INVERTIONPARAM}"
	COORDLABELNAME2=${X2}_${Y2}"${INVERTIONPARAM}"
	COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}"${INVERTIONPARAM}"		

	mv ${MSBASDIR}/zz_LOS_"${MODE}""${INVERTIONPARAM}"/timeLine${X1}_${Y1}.eps ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLine_"${COORDLABELNAME1}".eps 2>/dev/null
	mv ${MSBASDIR}/zz_LOS_"${MODE}""${INVERTIONPARAM}"/timeLine${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLine_"${COORDLABELNAME2}".eps 2>/dev/null
	mv ${MSBASDIR}/zz_LOS_"${MODE}""${INVERTIONPARAM}"/timeLine${X1}_${Y1}_${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLine_"${COORDLABELNAME12}".eps 2>/dev/null

	mv ${MSBASDIR}/zz_LOS_"${MODE}""${INVERTIONPARAM}"/timeLine${X1}_${Y1}.txt ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/_Time_series/ 2>/dev/null
	mv ${MSBASDIR}/zz_LOS_"${MODE}""${INVERTIONPARAM}"/timeLine${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/_Time_series/ 2>/dev/null
	mv ${MSBASDIR}/zz_LOS_"${MODE}""${INVERTIONPARAM}"/timeLine${X1}_${Y1}_${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/_Time_series/ 2>/dev/null

	rm -f ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLine_"${COORDLABELNAME12}"_Combi_"${MODE}".jpg
	mv ${MSBASDIR}/zz_LOS_"${MODE}""${INVERTIONPARAM}"/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLine_"${COORDLABELNAME12}"_Combi_"${MODE}".jpg 2>/dev/null

	}


while read -r X1 Y1 X2 Y2 DESCR
	do	
		PlotAllLOS ${X1} ${Y1} ${X2} ${Y2} "${DESCR}" "${MODE}"
done < "${FILEPAIRS}"


rm -f ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/__Combi/*.jpg
mv ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/*_Combi*.jpg ${MSBASDIR}/zz_LOS_TS_"${MODE}""${INVERTIONPARAM}"/__Combi/

