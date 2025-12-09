#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at re-plotting EW and UD double difference time series of points  
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
# 		- the string that follows zz_EW or zz_UD in the name of the dir where the results of the msbas are stored 
# 			(e.g. _Auto_2_0.004_PF)
#		- optional; a path to EVENTS table for plotting on the figure (e.g. ${PATH_1650}/EVENTS_TABLES/${LABEL})
#
#
# Hardcoded: 	- in case of 3D displacements, the vector plots requires the crop and parametrers adjusted  in lines 
#					Plot_vectorDispl_DEM.py ${WHEREDEM} ${NSDISPL} ${EWDISPL} --scalevalue 0.5 --dwsple 15 --x_min 955 --x_max 1249 --y_min 1005 --y_max 1349
#					Plot_vectorDispl_DEM.py ${WHEREDEM} ${NSDISPL} ${EWDISPL} --scalevalue 0.5 --dwsple 15 --x_min 955 --x_max 1249 --y_min 1005 --y_max 1349 --contour
#				and after
#       
# Dependencies:	- PlotTS_all_comp.sh
#
# New in Distro V 1.1 2024xxxx:	- 
# New in Distro V 2.0 20250918:	- add NS if any
# New in Distro V 2.1 20251113:	- OLL was not defined and quote variables
#								- debug search of 2D or 3D
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Nov 13, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

DOUBLEDIFFPAIRSEWUD=$1 	# e.g. "${PATH_SCRIPTS}/SCRIPTS_MT/_cron_scripts/List_DoubleDiff_EW_UD_Region.txt"
INVERTIONPARAM=$2		# e.g. _Auto_2_0.004_PF
EVENTS=$3				# e.g. ${PATH_1650}/EVENTS_TABLES/Region

# Test if EW and UD data are in pwd 
MSBASDIR=$(pwd)

EWDATADIR="${MSBASDIR}/zz_EW${INVERTIONPARAM}"

if [ -d "${EWDATADIR}" ] && [ "$(ls -A $EWDATADIR)" ] ; then
	echo " // OK, EW Directory exists. "
else
	echo " // Directory ${MSBASDIR}/zz_EW${INVERTIONPARAM} with msbas results does not exist or is empty. Please check...."
	exit
fi
echo ""

comp=$(ls -d *_UD_EW_NS_*/ 2>/dev/null | head -n 1)

if [ "${comp}" != "" ] ; then
    echo " // Detect directroy with 3D components, hence plot UD_EW_NS time series "
    ALLCOMP="UD_EW_NS"
else
    echo " // Detect no directroy with 3D components, hence plot UD_EW time series "
    ALLCOMP="UD_EW"
fi

function PlotAll()
	{
	unset X1 Y1 X2 Y2 DESCRIPTION
	local X1=$1
	local Y1=$2
	local X2=$3
	local Y2=$4
	local DESCRIPTION=$5

	if [ "${EVENTS}" == "" ]
		then
			${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "${INVERTIONPARAM}" ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g  # remove -f if does not want the linear fit
		else
			${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "${INVERTIONPARAM}" ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events="${EVENTS}"  # remove -f if does not want the linear fit			
	fi

	COORDLABELNAME1="${X1}_${Y1}${INVERTIONPARAM}"
	COORDLABELNAME2="${X2}_${Y2}${INVERTIONPARAM}"
	COORDLABELNAME12="${X1}_${Y1}_${X2}_${Y2}${INVERTIONPARAM}"		
	
	mv ${MSBASDIR}/timeLines_"${COORDLABELNAME1}".eps ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLines_"${COORDLABELNAME1}".eps 2>/dev/null
	mv ${MSBASDIR}/timeLines_"${COORDLABELNAME2}".eps ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLines_"${COORDLABELNAME2}".eps 2>/dev/null

	mv ${MSBASDIR}/timeLines_"${COORDLABELNAME12}".eps ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLines_"${COORDLABELNAME12}".eps 2>/dev/null

   	#rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg
   	rm -f ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLines_"${COORDLABELNAME12}"_Combi.jpg
	mv ${MSBASDIR}/timeLines_"${COORDLABELNAME12}"_Combi.jpg ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLines_"${COORDLABELNAME12}"_Combi.jpg 2>/dev/null
	
	mv ${MSBASDIR}/timeLine_UD_"${COORDLABELNAME12}".txt ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}/""${DESCRIPTION}_"timeLines_UD_"${COORDLABELNAME12}".txt 2>/dev/null
	mv ${MSBASDIR}/timeLine_EW_"${COORDLABELNAME12}".txt ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLines_EW_"${COORDLABELNAME12}".txt 2>/dev/null

	if [ "${ALLCOMP}" == "UD_EW_NS" ] ; then
		mv ${MSBASDIR}/timeLine_NS_"${COORDLABELNAME12}".txt ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/"${DESCRIPTION}"_timeLines_NS_"${COORDLABELNAME12}".txt 2>/dev/null
	fi

	}


while read -r X1 Y1 X2 Y2 DESCR
	do	
		PlotAll ${X1} ${Y1} ${X2} ${Y2} "${DESCR}"
done < "${DOUBLEDIFFPAIRSEWUD}"	

# move all plots in same dir 
rm -f ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/__Combi/*.jpg
mv ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/*_Combi.jpg ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/__Combi/

# move all time series in dir 
mv ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/*.txt ${MSBASDIR}/zz_"${ALLCOMP}"_TS"${INVERTIONPARAM}"/_Time_series/



if [ "${ALLCOMP}" == "UD_EW_NS" ] ; then
	# Vector Plot of EW-NS components
	
	WHEREDEM=$(find ${MSBASDIR}/DEM/ -maxdepth 1 -type f -name "externalSlantRangeDEM.UTM.*.bil")
	NSDISPL="${MSBASDIR}/zz_NS${INVERTIONPARAM}/MSBAS_LINEAR_RATE_NS.bin"
	EWDISPL="${MSBASDIR}/zz_EW${INVERTIONPARAM}/MSBAS_LINEAR_RATE_EW.bin"
	
	# Create vector plot without crop if clipped in header.txt
	Plot_vectorDispl_DEM.py "${WHEREDEM}" "${NSDISPL}" "${EWDISPL}" --scalevalue 0.5 --dwsple 15 --x_min 955 --x_max 1249 --y_min 1005 --y_max 1349
	Plot_vectorDispl_DEM.py "${WHEREDEM}" "${NSDISPL}" "${EWDISPL}" --scalevalue 0.5 --dwsple 15 --x_min 955 --x_max 1249 --y_min 1005 --y_max 1349 --contour
	
	# where options are number of lines and col to crop from original image 
	# as follow: --x_min 50 --x_max 115 --y_min 100 --y_max 240 means keep from 50 to 115 col and from 100 to 240 lines)
				
	# Full vector plt
	Plot_vectorDispl_DEM.py "${WHEREDEM}" "${NSDISPL}" "${EWDISPL}" --scalevalue 0.5 --dwsple 15
	Plot_vectorDispl_DEM.py "${WHEREDEM}" "${NSDISPL}" "${EWDISPL}" --scalevalue 0.5 --dwsple 15 --contour
				
	mkdir -p ${MSBASDIR}/zz_VectorPlot
	mv -f EW_NS_Vector_Displ*.jpg ${MSBASDIR}/zz_VectorPlot/
fi