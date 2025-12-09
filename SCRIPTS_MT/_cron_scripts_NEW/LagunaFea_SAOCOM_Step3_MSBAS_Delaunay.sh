#!/bin/bash
# Script intends to run in a cronjob an automatic systematic (re)processinf of msbas time 
# series when new images were made available. If SAOCOM images were updated, corresponding products 
# will be taken into account at the time of processing with new images. 
# 
# It will prepare and run MSBAS only if no other mass process is in progress.
# It also plots several time series and double differences based on provided list of points. 
#
# Optional : perform a selection of pairs based on a mean coh computed on a provided footprint.
#			This might be usefull for regions known to be affected by strong seasonal decorrelation. 
#			For instance, ensuring a mean coh of at least 0.235 on the Laguna_Maule area (Chile) 
#			ensured a proper estimation of the deformation. Not performing that selection based 
#			on the coh underestimated the defo up to 60%.
#
# NOTE: - MSBAS Calibration is disabled because deformation maps are detrended at processing. 
#
# Parameters: - none 
#
# Hardcoded: - a lot... se below paragraph named HARD CODED but also adapt below depending on the number of modes 
#			 - suppose everywhere that modes are DefoInterpolx2Detrend
#
# Dependencies:	- 
#
# New in Distro V 1,0 20231110:	- init
# New in Distro V 1.1 20231228:	- Remove images before June 1st 2015 to avoid stripes in images
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Dec 28, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

cd

TODAY=`date`
MM=$(date +%m)
DD=$(date +%d)
YYYY=$(date +%Y)

# vvvvvvvvv Hard coded lines vvvvvvvvvvvvvv
	# some parameters
	#################
		# Max baselines (used for all the mode in present case but you can change)
		#BP=10000			# max perpendicular baseline - Not used becasue use Delaunay's table instead
		#BT=10000			# max temporal baseline - Not used becasue use Delaunay's table instead
		
		LABEL=LagunaFea		# Label for file naming (used for naming zz_ dirs with results and figs etc)

		#R_FLAG
		# Order
		ORDER=2
		# Lambda
		LAMBDA=0.04
		
	# some files and PATH for each mode
	###################################
		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
		SAOCOMASC=${PATH_3601}/SAR_MASSPROCESS/SAOCOM/LagunaFea_042_A/SMNoCrop_SM_20231010_Zoom1_ML8
		SAOCOMDESC=${PATH_3601}/SAR_MASSPROCESS/SAOCOM/LagunaFea_152_D/SMNoCrop_SM_20231105_Zoom1_ML8

		# Path to dir where list of compatible pairs files are computed (need one for each mode)
		SET1=${PATH_1650}/SAR_SM/MSBAS/LagunaFea/set1
		SET2=${PATH_1650}/SAR_SM/MSBAS/LagunaFea/set2
		
		# Tables names
		TABLESET1=${SET1}/table_0_0_DelaunayRatio30.0_0.txt
		TABLESET2=${SET2}/table_0_0_DelaunayRatio30.0_0.txt

		# Path to LaunchParameters.txt files for each mode (need one for each mode)
		LAUNCHPARAMPATH=$PATH_1650/Param_files/SAOCOM
		LAUNCHPARAMASC=${LAUNCHPARAMPATH}/LagunaFea_042_A/LaunchMTparam_SAOCOM_LagunaFea_Asc_Zoom1_ML8_SM.txt
		LAUNCHPARAMDESC=${LAUNCHPARAMPATH}/LagunaFea_152_D/LaunchMTparam_SAOCOM_LagunaFea_Desc_Zoom1_ML8_SM.txt

	# Events tables
	###############
		# Read polarisation changes and make table (must be 3 col like VV	StartDate	StopDate)
		# Do not forget to update the table ${PATH_1650}/EVENTS_TABLES/${LABEL}/Polarisation_Change_${LABEL}.txt 
		#		based on ${PATH_1650}/SAR_CSL/SAOCOM/LagunaFea_152_D/NoCrop/___img_with_pol_VV_instead_of_HH.txt
		
		# comment below if you do not want to plt events
		EVENTS=${PATH_1650}/EVENTS_TABLES/${LABEL}

	# Path to dir where MSBAS will be computed
	###########################################
		#MSBASDIRCRITERIA=${BP}m_${BT}days
		MSBASDIRCRITERIA=DelaunayRatio30
		MSBASDIR=${PATH_3602}/MSBAS/_${LABEL}_SAOCOM_Auto_${MSBASDIRCRITERIA}
		
	# Date Restriction
	##################
	DATERESTRIC1="YES"	# If YES, will remove dates from Mode 1 based on parma here after
	DATERESTRIC2="YES"	# If YES, will remove dates from Mode 2 based on parma here after

		REMOVEBEFORE1="20200701"	# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEAFTER1="NONE"			# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEBEFORE2="20200701"	# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEAFTER2="NONE"			# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
	
		REMOVEBETWEEN1="NO"	# If YES, it will remove all and only pairs with one of the dates between dates REMOVEBEFORE and REMOVEAFTER, providing that these two dates are not empty
		REMOVEBETWEEN2="NO"	# If YES, it will remove all and only pairs with one of the dates between dates REMOVEBEFORE and REMOVEAFTER, providing that these two dates are not empty

	# Coherence restriction
	########################		
		IFCOH="NO"		# YES or NO

		if [ ${IFCOH} == "YES" ] 
			then 

				# Path to kml zone used to check coherence
				KMLCOH=${PATH_1650}/kml/YOUR_PATH.kml	

				# Coherence restriction threshold (to be compared to mean coh computed on KMLCOH)
				COHRESTRICT=0.235

				# Exclude pairs from modes: If pairs are incidentally above Coh Threshold, 
				# they can be excluded if they are stored as DATE_DATE in a list named 
				# ${MSBASDIR}/DefoInterpolx2Detrendi/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
				# and parameter below set to YES 
				EXCLUDE1="NO"	# YES or NO
				EXCLUDE2="NO"	# YES or NO

				if [ ! -s ${KMLCOH} ] ; then echo "Missing kml for coherence estimation. Please Check" ; exit ; fi
			else 
				EXCLUDE1="NO"	# always NO of course
				EXCLUDE2="NO"	# always NO of course		
		fi

	# Path to list of points for plotting time series
	#################################################
		# List of SINGLE points for plotting time series with error bars  
		TIMESERIESPTSDESCR=${PATH_1650}/Data_Points/Points_TS_${LABEL}.txt

		# List of PAIRS of points for plotting double difference (i.e. without error bar) in EW and UD, ASC and Desc... 
		# 	Note: if pixels are coherent in all modes, these can be the same list
		DOUBLEDIFFPAIRSEWUD=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_LagunaFea.txt
		DOUBLEDIFFPAIRSASC=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_LagunaFea.txt
		DOUBLEDIFFPAIRSDESC=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_LagunaFea.txt
		
		# Path to dir where jpg figs of location of each pair of points are stored
		#PATHLOCA=${PATH_3602}/MSBAS/zz_insets/${LABEL}
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	PATHCRONJOB=${PATH_SCRIPTS}/SCRIPTS_MT/_cron_scripts_NEW
	CRONJOB2=${PATHCRONJOB}/LagunaFea_SAOCOM_Step2_MassProc.sh

# ^^^^^^^^^^ Hard coded lines ^^^^^^^^^^^^

# Prepare directories
#####################
	mkdir -p ${MSBASDIR}

	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	mkdir -p ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

	# in Coh threshold restriction
	if [ ${IFCOH} == "YES" ] ; then 
		mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
		mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
		mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series
	fi
	
	cd ${MSBASDIR}

# prepare points lists
######################
	TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCR}")
	cp -f ${TIMESERIESPTSDESCR}  ${MSBASDIR}/${TIMESERIESPTNAME}
	TIMESERIESPTSDESCR=${MSBASDIR}/${TIMESERIESPTNAME}
	#cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/${TIMESERIESPTNAME}.tmp  #.tmp is now as the original; the original will be cut from first line (title)
	# Remove header and naming in 1st col from Pts list
	${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCR}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	# remove 3rd col
	#${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//3' /Users/doris/PROCESS/SCRIPTS_MT/_cron_scripts/Cln_${LABEL}.txt
	TIMESERIESPTS=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
# functions
###########

function RemoveDates()
		{
		unset MODENR 		#  Mode Nr
		unset REMOVEBETWEEN	#  Remove or not between dates 
		unset REMOVEBEFORE	#  Remove or not before date
		unset REMOVEAFTER	#  Remove or not after date

		MODENR=$1
		REMOVEBETWEEN=$2
		REMOVEBEFORE=$3
		REMOVEAFTER=$4
		echo ""
		if [ "${REMOVEBETWEEN}" == "YES" ]  ; 
			then
				if [ "${REMOVEBEFORE}" == "NONE" ] || [ "${REMOVEAFTER}" == "NONE" ] 
					then
						echo "  // You requested to remove all pairs from mode ${MODENR} with an image between provided dates but at least one date is missing. Check parameters REMOVEBEFORE and REMOVEAFTER in the present cron script. "
						exit
					else 	
						if [ "${REMOVEAFTER}" -lt "${REMOVEBEFORE}" ]
							then
								MINDATE=${REMOVEAFTER}
								MAXDATE=${REMOVEBEFORE}
							else
								MINDATE=${REMOVEBEFORE}
								MAXDATE=${REMOVEAFTER}
						fi
						echo "  // Shall remove all pairs with an image between ${MINDATE} and ${MAXDATE} (included) in mode ${MODENR}."
				fi

				# Remove between dates
				cp -f ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}_WITHdatesBetween${MINDATE}and${MAXDATE}.txt
				# Remove pairs with images before MAXDATE	
				RemovePairsFromModeList_WithImagesBefore.sh ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${MAXDATE} 
				# Creates a file named e.g. ${MSBASDIR}/DefoInterpolx2Detrend1After_${MAXDATE}_${MM}_${DD}_${YYYY}.txt
				# Remove pairs with images after MINDATE
				RemovePairsFromModeList_WithImagesAfter.sh ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${MINDATE} 
				# Creates a file named e.g. ${MSBASDIR}/DefoInterpolx2Detrend1Below_${MINDATE}_${MM}_${DD}_${YYYY}.txt
				cat ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt_Below${MINDATE}_${MM}_${DD}_${YYYY}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt_After${MAXDATE}_${MM}_${DD}_${YYYY}.txt > ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}_WithoutDatesBetween${MINDATE}and${MAXDATE}.txt
				cp -f ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}_WithoutDatesBetween${MINDATE}and${MAXDATE}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt
			else 
				if [ "${REMOVEBEFORE}" != "NONE" ] && [ "${REMOVEAFTER}" != "NONE" ] ; then 
					echo "  // You requested to remove all pairs from mode ${MODENR} with an image before ${REMOVEBEFORE} and after ${REMOVEAFTER}. " 
					echo "  // This is not possible unless you wanted to remove only the pairs between these dates. In that case you must set the parameter REMOVEBETWEEN${MODENR} to YES in the present cron script."
					echo "  // Otherwise, simply set in the present cron script REMOVEBEFORE${MODENR} or REMOVEAFTER${MODENR} to NONE, depending on your needs."
					exit
				fi
				if [ "${REMOVEBEFORE}" != "NONE" ] ; then
					echo "  // Shall remove all pairs with an image before ${REMOVEBEFORE} from mode ${MODENR}."
					# Remove before given date	
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}_WithoutRemoveDatesBefore${REMOVEBEFORE}.txt
					RemovePairsFromModeList_WithImagesBefore.sh ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${REMOVEBEFORE} 
					# Creates a file named e.g. DefoInterpolx2Detrend1.txt_After20150601_12_28_2023.txt
					cp ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt_After${REMOVEBEFORE}_${MM}_${DD}_${YYYY}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt
				fi
				if [ "${REMOVEAFTER}" != "NONE" ] ; then 
					echo "  // Shall remove all pairs with an image after ${REMOVEAFTER} from mode ${MODENR}."
					# Remove after given date	
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}_WithoutRemoveDatesAfter${REMOVEAFTER}.txt
					RemovePairsFromModeList_WithImagesAfter.sh ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${REMOVEAFTER} 
					# Creates a file named e.g. DefoInterpolx2Detrend1.txt_Below20150601_12_28_2023.txt
					cp ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt_Below${REMOVEAFTER}_${MM}_${DD}_${YYYY}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt
				fi
		fi
		echo ""
	}

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
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g   # remove -f if does not want the linear fit etc..
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit etc..		
		fi
		mv ${MSBASDIR}/timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps
		mv ${MSBASDIR}/timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps

		mv ${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg
		rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg
		mv ${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg
		
		mv ${MSBASDIR}/timeLine_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
		mv ${MSBASDIR}/timeLine_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
	
#		rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
		}

	function PlotAllNoCoh()
		{
		unset X1 Y1 X2 Y2 DESCRIPTION
		local X1=$1
		local Y1=$2
		local X2=$3
		local Y2=$4
		local DESCRIPTION=$5


		if [ "${EVENTS}" == "" ]
			then
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g   # remove -f if does not want the linear fit etc..
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit etc..		
		fi
#		rm plotTS*.gnu timeLines_*.png 
	
		if [ -f "${MSBASDIR}/timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] ; then 
			mv ${MSBASDIR}/timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps
		fi
		if [ -f "${MSBASDIR}/timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps
		fi 
		if [ -f "${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps

#			# add map tag in fig
#			convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg
#			# get location from dir with coh threshold (where it was added manually)
#			convert ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_NoCohThresh.jpg
			rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_Combi.jpg
			mv ${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_Combi.jpg

			mv ${MSBASDIR}/timeLine_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.txt
			mv ${MSBASDIR}/timeLine_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.txt
		fi
	
#		rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg
		}

	function PlotAllLOS()
		{
		unset X1 Y1 X2 Y2 DESCRIPTION 
		local X1=$1
		local Y1=$2
		local X2=$3
		local Y2=$4
		local DESCRIPTION=$5
	
		cd ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	
		if [ "${EVENTS}" == "" ]
			then
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g # remove -f if does not want the linear fit
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit etc..		
		fi
#		rm plotTS*.gnu timeLine*.png 

		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}_${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps

		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}_${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_Asc.jpg
		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_${MODE}.jpg
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_${MODE}.jpg
	
#		rm -f ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
		}

	function MSBASmode()
		{
		unset MODE # e.g. Asc or Desc
		local MODE=$1
		cd ${MSBASDIR}
		cp -f ${MSBASDIR}/header_${MODE}.txt  header.txt 
		${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}

		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		# remove header line to avoid error message 
		#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
		while read -r DESCR X Y RX RY
			do	
				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
				mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
				# there is no automatic plotting by msbas when only in LOS 
		done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
		# Why not some double difference plotting
		while read -r X1 Y1 X2 Y2 DESCR
			do	
				PlotAllLOS ${X1} ${Y1} ${X2} ${Y2} ${DESCR} ${MODE}
		done < ${FILEPAIRS}						
	
		# move all plots in same dir 
		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/*.jpg
		mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi*.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
		# move all time series in dir 
		#mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
		}


# Check that there is no other cron (Step 2 or 3) or manuam SuperMaster_MassProc.sh running
###########################################################################################
	# Check that no other cron job step 3 (MSBAS) or manual SuperMaster_MassProc.sh is running
	CHECKMB=`ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" | wc -l`
		#### For Debugging
		# echo "ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v ${PATHGNU}/grep | ${PATHGNU}/grep -v /dev/null | wc -l" > CheckRun.txt
		# echo ${CHECKMB} >> CheckRun.txt
		# ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" >> CheckRun.txt

	if [ ${CHECKMB} -gt 3 ] ; then # use ${PATHGNU}/grep -v "grep "  instead of ${PATHGNU}/grep -v "grep ${PRG}" because depending on environment, it may miss the second version
			REASON=" another ${PRG} is running" 
			STOPRUN="YES"
		else
			# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
			CHECKASC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${LAUNCHPARAMASC} | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
			CHECKDESC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${LAUNCHPARAMDESC} | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
	
			# For unknown reason it counts 1 even when no process is running
			if [ ${CHECKASC} -ne 0 ] || [ ${CHECKDESC} -ne 0 ] ; then REASON="  SuperMaster_MassProc.sh in progress (probably manual)" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi  	
	fi 

	# Check that no other cron job step 2 (SuperMaster_MassProc.sh) is running
	CHECKMP=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" | wc -l`

	if [ ${CHECKMP} -ne 0 ] ; then REASON=" SuperMaster_MassProc.sh in progress (from ${CRONJOB2})" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi 

	if [ "${STOPRUN}" == "YES" ] 
		then 
			echo "MSBAS attempt aborted on ${TODAY} because ${REASON}" >>  ${MSBASDIR}/_last_MSBAS_process.txt
			echo "MSBAS attempt aborted on ${TODAY} because ${REASON}"
			#mv -f  ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp  ${MSBASDIR}/${TIMESERIESPTSDESCR}
			exit
	fi

# Check defo maps in SAR_MASSPROCESS
####################################
# Remove possible duplicate geocoded products in SAR_MASSPROCESS/.../Geocoded/... 
# i.e. remove in each MODE (but Ampl) possible products from same pair of dates but with different Bp, Ha etc.. that would results from 
# reprocessing with updated image. If duplicated product detected, it keeps only the most recent product.  

	cd ${SAOCOMASC}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${SAOCOMDESC}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	wait
	
# Get date (in sec) of last available processed pairs in each MODE
##################################################################
	# get the name of last available processed pair in each MODE

    # ls crashes when too many files 
	#LASTASC=`ls -lt ${SAOCOMASC}/Geocoded/DefoInterpolx2Detrend | head -n 2 | tail -n 1 | sed 's/.* //'` # may be messing up if txt files are created for any other purpose in the dir... 
	#LASTDESC=`ls -lt ${SAOCOMDESC}/Geocoded/DefoInterpolx2Detrend | head -n 2 | tail -n 1 | sed 's/.* //'`
	LASTASC=`find ${SAOCOMASC}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTDESC=`find ${SAOCOMDESC}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	# get date in sec of last available processed pairs in each MODE
	LASTASCTIME=`stat -c %Y ${LASTASC}`
	LASTDESCTIME=`stat -c %Y ${LASTDESC}`

# Check if first run and if  appropriate, get time of last images in time series
################################################################################
	if [ -f "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] && [ -s "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] 
		then   
			echo "Existing ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence not the first run"
			FIRSTRUN=NO
			FORMERLASTASCTIME=`head -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`
			FORMERLASTDESCTIME=`head -2 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1` # tail -1 ok also but this is ready for case where more than 2 lines are present in _Last_MassProcessed_Pairs_Time.txt
			
			if [ ${FORMERLASTASCTIME} -eq ${LASTASCTIME} ] && [ ${FORMERLASTDESCTIME} -eq ${LASTDESCTIME} ]  # if no more recent file is available since the last cron processing
				then
					echo "MSBAS finished on ${TODAY} without new pairs to process"  >>  ${MSBASDIR}/_last_MSBAS_process.txt
					echo "MSBAS finished on ${TODAY} without new pairs to process"
					#mv -f  ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp  ${MSBASDIR}/${TIMESERIESPTSDESCR}
					exit
			fi
		else  
			echo "No ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence first run"
			FIRSTRUN=YES
	fi

# Remove possible broken links in MSBAS/.../MODEi and clean corresponding files 
################################################################################
# (clean if required MODEi.txt and Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt if any)
	if [ "${FIRSTRUN}" == "NO" ] ; then 
		echo "Remove Broken Links and Clean txt file in existing ${MSBASDIR}/DefoInterpolx2Detrend"
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend1 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend2 &
		wait
		echo "Possible broken links in former existing MODEi dir are cleaned"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)	
		if [ ${IFCOH} == "YES" ] ; then 
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend1_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend2_Full &
			wait
			echo "Possible broken links in former existing MODEi_Full dir are cleaned"
			echo ""
		fi
	fi

# Check MSBAS/.../MODEi.txt file
################################
cd ${MSBASDIR}

# Remove possible lines with less that 4 columns
	if [ "${FIRSTRUN}" == "NO" ] ; then 
		mv DefoInterpolx2Detrend1.txt DefoInterpolx2Detrend1_all4col.txt
		mv DefoInterpolx2Detrend2.txt DefoInterpolx2Detrend2_all4col.txt
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend1_all4col.txt > DefoInterpolx2Detrend1.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend2_all4col.txt > DefoInterpolx2Detrend2.txt 
		rm -f DefoInterpolx2Detrend1_all4col.txt DefoInterpolx2Detrend2_all4col.txt
		echo "All lines in former existing MODEi.txt have 4 columns"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			mv ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full_all4col.txt
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full_all4col.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full_all4col.txt
			echo "All lines in former existing MODEi_Full.txt have 4 columns"
			echo ""
		fi
	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after image update) 
		cd ${MSBASDIR}
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATH_3601}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATH_3601}/SAR_MASSPROCESS &
		wait
		echo "All lines in former existing MODEi.txt are ok"
		echo ""
	
		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1_Full ${PATH_3601}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2_Full ${PATH_3601}/SAR_MASSPROCESS &
			wait
			echo "All lines in former existing MODEi_Full.txt are ok"
			echo ""	
		fi
	
	fi

# Prepare MSBAS
###############
#	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_criteria.sh DefoInterpolx2Detrend 2 ${BP} ${BT} ${SAOCOMASC} ${SAOCOMDESC} 
	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh DefoInterpolx2Detrend 2 ${TABLESET1} ${TABLESET2} ${SAOCOMASC} ${SAOCOMDESC} 
	
	# update here the R_FLAG if needed
	${PATHGNU}/gsed -i "s/R_FLAG = 2, 0.02/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt
	# because interferos are detreneded, i.e. averaged to zero, there is no need to calibrate again 
	${PATHGNU}/gsed -i 's/C_FLAG = 10/C_FLAG = 0/' ${MSBASDIR}/header.txt

	# Check again that files are OK
		# ensure that format is ok, that is with 4 columns 
		mv DefoInterpolx2Detrend1.txt DefoInterpolx2Detrend1_all4col.txt
		mv DefoInterpolx2Detrend2.txt DefoInterpolx2Detrend2_all4col.txt
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend1_all4col.txt > DefoInterpolx2Detrend1.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend2_all4col.txt > DefoInterpolx2Detrend2.txt 
		# keep track of prblms
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend1_all4col.txt > DefoInterpolx2Detrend1_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend2_all4col.txt > DefoInterpolx2Detrend2_MissingCol.txt 
		rm -f DefoInterpolx2Detrend1_all4col.txt DefoInterpolx2Detrend2_all4col.txt
		
		# Need again to check for duplicated lines with different Bp in Col 2 resulting from orbit update 
		if [ ${IFCOH} == "YES" ] ; then 
			echo "Remove lines in newly created MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATH_3601}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATH_3601}/SAR_MASSPROCESS &
			wait
			echo "All lines in new MODEi.txt should be ok"
			echo ""	
		fi
		
	# Remove some dates if needed
	if [ "${DATERESTRIC1}" == "YES" ] ; then 
		RemoveDates	"1"	"${REMOVEBETWEEN1}" "${REMOVEBEFORE1}" "${REMOVEAFTER1}"
		# that is ; mode 1, NO remove between dates, remove before 20200701, do not remove after a given date
	fi
	if [ "${DATERESTRIC2}" == "YES" ] ; then
		RemoveDates "2"	"${REMOVEBETWEEN2}" "${REMOVEBEFORE2}" "${REMOVEAFTER2}"
		# that is ; mode 1, NO remove between dates, remove before 20200707, do not remove after a given date
	fi


# Let's go
##########
	cd ${MSBASDIR}
	cp -f header.txt header_back.txt 
 
 	# EW-UD without coh threshold restriction 
 	#-----------------------------------------
 		if [ ${IFCOH} == "YES" ] 
 		then 
 			# This is the run without coh restriction from dual run where a coh restriction will be requested after
 			# Prepare stuff from possible former run with coh restriction
 			#------------------------------------------------------------
 			case ${FIRSTRUN} in 
 				"YES") 
 					# one have only the newly created MODEi dir and MODEi.txt
 					cp -R ${MSBASDIR}/DefoInterpolx2Detrend1 ${MSBASDIR}/DefoInterpolx2Detrend1_Full
 					cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
 					cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
 				
 					cp -R ${MSBASDIR}/DefoInterpolx2Detrend2 ${MSBASDIR}/DefoInterpolx2Detrend2_Full
 					cp -f ${MSBASDIR}/DefoInterpolx2Detrend2.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
 					cp -f ${MSBASDIR}/DefoInterpolx2Detrend2.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt
 					;;
 				"NO")
 					# one must merge the newly created MODEi dir and MODEi.txt with former _Full ones
 					sort ${MSBASDIR}/DefoInterpolx2Detrend1.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt
 					sort ${MSBASDIR}/DefoInterpolx2Detrend2.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt
 				
 					sort ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt
 					sort ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt
 				
 					cat ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
 					cat ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt
 				
 					cp -R -n ${MSBASDIR}/DefoInterpolx2Detrend1 ${MSBASDIR}/DefoInterpolx2Detrend1_Full
 					cp -R -n ${MSBASDIR}/DefoInterpolx2Detrend2 ${MSBASDIR}/DefoInterpolx2Detrend2_Full
 					cp -f ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
 					cp -f ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
 				
 					rm -f ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt 
 					rm -f ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt
 					;;	
 			esac
 			# trick the header file						
 			${PATHGNU}/gsed -i 's/DefoInterpolx2Detrend1.txt/DefoInterpolx2Detrend1_Full.txt/' ${MSBASDIR}/header.txt
 			${PATHGNU}/gsed -i 's/DefoInterpolx2Detrend2.txt/DefoInterpolx2Detrend2_Full.txt/' ${MSBASDIR}/header.txt
 		 
 		 	${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${TIMESERIESPTS}
 		
 			# Make baseline plot 
 	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
 	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
 
 			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
 	 		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
 	
 			while read -r DESCR X Y RX RY
 	 		do	
 	 				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
 	 				mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
 	 				mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
 	 		done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
 			# Why not some double difference plotting
 			while read -r X1 Y1 X2 Y2 DESCR
 				do	
 					PlotAllNoCoh ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
 			done < ${DOUBLEDIFFPAIRSEWUD}
 
 	  		# move all plots in same dir 
 			rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/*.jpg
 	  		mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
 	  
 	  		# move all time series in dir 
 	 		mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series/
 
 		 else
 			# i.e. without any coh threshold restriction
 			# -------------------------------------------
 			${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
 
 			# Make baseline plot 
 			PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1.txt
 			PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2.txt
 
 			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
 			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
 
 			while read -r DESCR X Y RX RY
 				do	
 					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
 					mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
 					mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
 			done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
 			# Why not some double difference plotting
 			while read -r X1 Y1 X2 Y2 DESCR
 				do	
 					PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
 			done < ${DOUBLEDIFFPAIRSEWUD}	
 
 			# move all plots in same dir 
 			rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/*.jpg
 			mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
 
 			# move all time series in dir 
 			mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
 		fi 
 
 	# EW-UD with coh threshold restriction 
 	#--------------------------------------
 		if [ ${IFCOH} == "YES" ] ; then
 			cd ${MSBASDIR}
 			cp -f header_back.txt header.txt
 
 			# run restrict_msbas_to_Coh.sh         
 			restrict_msbas_to_Coh.sh DefoInterpolx2Detrend1 ${COHRESTRICT} ${KMLCOH} ${SAOCOMASC}/Geocoded/Coh
 			restrict_msbas_to_Coh.sh DefoInterpolx2Detrend2 ${COHRESTRICT} ${KMLCOH} ${SAOCOMDESC}/Geocoded/Coh
 		
 			# Force pair exclusion 
 			if [ ${EXCLUDE1} == "YES" ] ; then 
 				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend1
 			fi 
 			if [ ${EXCLUDE2} == "YES" ] ; then 
 				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend2
 			fi 
 			
 			cd ${MSBASDIR}
 			${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
 
 			# Make baseline plot 
 			PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1.txt
 			PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2.txt
 		
 			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
 			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
 
 			while read -r DESCR X Y RX RY
 				do	
 					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
 					mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
 					mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
 			done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
 			# Why not some double difference plotting
 			while read -r X1 Y1 X2 Y2 DESCR
 				do	
 					PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
 			done < ${DOUBLEDIFFPAIRSEWUD}	
 						
 			# move all plots in same dir 
 			rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/*.jpg
 			mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
 
 			# move all time series in dir 
 			mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
 		fi
 	
 	# Asc and Desc (with coh restriction if one is requested)
  	#--------------------------------------------------------
  		# Prepare header files
 		#   backup header
 		cp -f ${MSBASDIR}/header.txt ${MSBASDIR}/header_UD_EW.txt 
 
 		# Change  second occurrence of "SET = " with "#SET = "
 		${PATHGNU}/gsed  '0,/SET = /! {0,/SET = / s/SET = /#SET = /}' ${MSBASDIR}/header.txt > ${MSBASDIR}/header_Asc.txt 
 		# Change  first occurrence of "SET = " with "#SET = "
 		${PATHGNU}/gsed '0,/SET =/{s/SET =/#SET =/}' ${MSBASDIR}/header.txt > ${MSBASDIR}/header_Desc.txt 

		# ASC
 			FILEPAIRS=${DOUBLEDIFFPAIRSASC}
 			MSBASmode Asc
  		
 		# DESC
  			FILEPAIRS=${DOUBLEDIFFPAIRSDESC}
 			MSBASmode Desc
 
  		# Back to normal for next run and get out
  			cp -f ${MSBASDIR}/header_UD_EW.txt ${MSBASDIR}/header.txt 		 				

			TODAY=`date`
			echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt

			echo "${LASTASCTIME}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
			echo "${LASTDESCTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
		
	#mv -f ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp ${MSBASDIR}/${TIMESERIESPTSDESCR}

# All done...
