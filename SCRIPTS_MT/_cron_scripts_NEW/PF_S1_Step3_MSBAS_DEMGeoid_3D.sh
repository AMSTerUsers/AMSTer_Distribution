#!/bin/bash
# Script intends to run in a cronjob an automatic systematic (re)processing of msbas time 
# series when new images were made available. If orbits were updated, corresponding products 
# will be taken into account at the time of processing with new images. 
# 
# It will prepare and run MSBAS only if no other mass process is in progress.
# It also plots several time series and double differences based on provided list of points. 
#
# Optional : perform a selection of pairs based on a mean coh computed on a provided footprint.
#			This might be useful for regions known to be affected by strong seasonal decorrelation. 
#			For instance, ensuring a mean coh of at least 0.235 on the Laguna_Maule area (Chile) 
#			ensured a proper estimation of the deformation. Not performing that selection based 
#			on the coh underestimated the defo up to 60%.
#
# NOTE: - MSBAS Calibration is disabled because deformation maps are detrended at processing. 
#
# WARNING: 	build_header_msbas_criteria.sh requires all table files with the same Bp and Bt names, hence one must link 
#			SM table using 50m 50 days as tables named with 70m 70 days baselines
#
# Parameters: - none 
#
# Hardcoded: - a lot... se below paragraph named HARD CODED but also adapt below depending on the number of modes 
#			 - suppose everywhere that modes are DefoInterpolx2Detrend
#
# Dependencies:	- Replot_EW_UD_DoubleDiff_TS_From_Cron_Step3.sh (specific to Reunion Island, i.e. to replot LS points with other EVENTS)
#				- Replot_LoS_DoubleDiff_TS_From_Cron_Step3.sh (specific to Reunion Island, i.e. to replot LS points with other EVENTS)
#
# New in Distro V 1.0 20260127:	- based on version 2D Distro V 5.2.0 (20260115) and cron step3 3D for Funu (V 2.2.0 20260115)
#								- consider only the North of the Island for the Land slides 
# New in Distro V 1.1.0 2026730 :	- force msbasv4								
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 30, 2026"


echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

cd

TODAY=`date`

# vvvvvvvvv Hard coded lines vvvvvvvvvvvvvv

	# Variables to check that no other cron job step 1 or 2 is running from another computer
	# in this case, crons 1 and 2 are launched from Pro-Silver
	TARGET="PF"
	PATH_DIR_FOR_FLAG="$PATH_3610/SAR_MASSPROCESS/S1/"
	PATH_DIR_FOR_FLAG_SM="$PATH_3610/SAR_MASSPROCESS/"	# here need two different flags because there are two processings possible


	# some parameters
	#################

		LABEL=PF_3D 	# Label for file naming (used for naming zz_ dirs with results and figs etc)
		LABELEVENTS=PF_LS	# Label for EVENTS and Points 

		# Mode
		#DEFOMODE=DefoInterpol
		DEFOMODE=DefoInterpolx2Detrend

		#R_FLAG
		# Order
		ORDER=1
		# Lambda
		LAMBDA=0.04
		
		# Crop region to invert
			# current FILE_SIZE is: 2268, 1985
			# desired WINDOW_SIZE is: 950, 1190, 350, 740
			XMIN=950
			XMAX=1190
			YMIN=350
			YMAX=740

		
	# some files and PATH for each mode
	###################################

		# Path to Seti
		PATHSETI=${PATH_1650}/SAR_SM/MSBAS
			# Path to dir where list of compatible pairs files are computed (need one for each mode)
			SET1=${PATH_1650}/SAR_SM/MSBAS/PF/set1
			SET2=${PATH_1650}/SAR_SM/MSBAS/PF/set2
			SET3=${PATH_1650}/SAR_SM/MSBAS/PF/set3
			SET4=${PATH_1650}/SAR_SM/MSBAS/PF/set4

		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
		# Path to SAR_MASSPROCESS
		PATHMASSPROCESS=$PATH_3610/SAR_MASSPROCESS
			# SM
			S1ASCSM=$PATH_3610/SAR_MASSPROCESS/S1/PF_SM_A_144/SMCrop_SM_20190808_Reunion_-21.41--20.85_55.2-55.85_Zoom1_ML8
			S1DESCSM=$PATH_3610/SAR_MASSPROCESS/S1/PF_SM_D_151/SMCrop_SM_20181013_Reunion_-21.41--20.85_55.2-55.85_Zoom1_ML8
			# IW
			S1ASCIW=$PATH_3610/SAR_MASSPROCESS/S1/PF_IW_A_144/SMNoCrop_SM_20180831_Zoom1_ML2
			S1DESCIW=$PATH_3610/SAR_MASSPROCESS/S1/PF_IW_D_151/SMNoCrop_SM_20200622_Zoom1_ML2

		# Path to LaunchParameters.txt files for each mode (need one for each mode)
			# SM
			LAUNCHPARAMASCSM=LaunchMTparam_S1_SM_Reunion_Asc_Zoom1_ML8_DEMGeoid.txt
			LAUNCHPARAMDESCSM=LaunchMTparam_S1_SM_Reunion_Desc_Zoom1_ML8_DEMGeoid.txt
			# IW
			LAUNCHPARAMASCIW=LaunchMTparam_S1_IW_Reunion_Asc_Zoom1_ML2_MassProc_DEMGeoid.txt
			LAUNCHPARAMDESCIW=LaunchMTparam_S1_IW_Reunion_Desc_Zoom1_ML2_MassProc_DEMGeoid.txt


		# Baseline Tables names
			# (SM) 
				# Set 1 (SM)
				SET1BP=50
				SET1BT=50
				DATECHG=20220501
				SET1BP2=90
				SET1BT2=50
				
				# Also set 2 - stopped because no more S1B 
				# Set 2 (SM) 
				SET2BP=50
				SET2BT=50
			# (IW)
				# Also set 3 - stopped because no more S1B  
				SET3BP=70
				SET3BT=70

				# Set 4 (IW)
				SET4BP=70
				SET4BT=70
				DATECHG=20220501
				SET4BP2=90
				SET4BT2=70	
			# Max Bp and Bt (for MSBAS dir naming)
				BP=50_90m
				BT=50_70days		
			TABLESET1=${SET1}/table_0_${SET1BP}_0_${SET1BT}_Till_${DATECHG}_0_${SET1BP2}_0_${SET1BT2}_After.txt
			TABLESET2=${SET2}/table_0_${SET2BP}_0_${SET2BT}.txt
			TABLESET3=${SET3}/table_0_${SET3BP}_0_${SET3BT}.txt
			TABLESET4=${SET4}/table_0_${SET4BP}_0_${SET4BT}_Till_${DATECHG}_0_${SET4BP2}_0_${SET4BT2}_After.txt

	# Events tables
	###############
		EVENTS=${PATH_1650}/EVENTS_TABLES/${LABELEVENTS}
	
	# Path to dir where MSBAS will be computed
	###########################################
		MSBASDIR=${PATH_3602}/MSBAS/_${LABEL}_S1_Auto_"${BP}"_"${BT}"days  
		# NOTE HERE UNUSUAL NAMING TO REMEMBER THAT IT WAS PREPRARED WITH DATA SETS WITH DIFFERENT MAX BT

		mkdir -p ${MSBASDIR}/${DEFOMODE}1
		mkdir -p ${MSBASDIR}/${DEFOMODE}2

		
	# Coherence restriction
	########################		
		IFCOH="NO"		# YES or NO

		#if [ ${IFCOH} == "YES" ] 
		#	then 
		#
		#		# Path to kml zone used to check coherence
		#		KMLCOH=${PATH_1650}/kml/YOUR_PATH.kml	
		#
		#		# Coherence restriction threshold (to be compared to mean coh computed on KMLCOH)
		#		COHRESTRICT=0.235
		#
		#		# Exclude pairs from modes: If pairs are incidentally above Coh Threshold, 
		#		# they can be excluded if they are stored as DATE_DATE in a list named 
		#		# ${MSBASDIR}/DefoInterpolx2Detrendi/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
		#		# and parameter below set to YES 
		#		EXCLUDE1="NO"	# YES or NO
		#		EXCLUDE2="NO"	# YES or NO
		#		EXCLUDE3="NO"	# YES or NO
		#		EXCLUDE4="NO"	# YES or NO
		#	
		#		if [ ! -s ${KMLCOH} ] ; then echo "Missing kml for coherence estimation. Please Check" ; exit ; fi
		#	
		#	else 
		#		EXCLUDE1="NO"	# always NO of course
		#		EXCLUDE2="NO"	# always NO of course		
		#		EXCLUDE3="NO"	# always NO of course
		#		EXCLUDE4="NO"	# always NO of course			
		#fi

	# Path to list of points for plotting time series
	#################################################
		# List of SINGLE points for plotting time series with error bars  
		TIMESERIESPTSDESCR=${PATH_1650}/Data_Points/Points_TS_${LABEL}.txt

		# List of PAIRS of points for plotting double difference (i.e. without error bar) in EW and UD, ASC and Desc... 
		# 	Note: if pixels are coherent in all modes, these can be the same list
		DOUBLEDIFFPAIRSEWUD=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
		DOUBLEDIFFPAIRSASCSM=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
		DOUBLEDIFFPAIRSDESCSM=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
		DOUBLEDIFFPAIRSASCIW=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
		DOUBLEDIFFPAIRSDESCIW=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
		DOUBLEDIFFPAIRSASCSMIW=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
		DOUBLEDIFFPAIRSDESCSMIW=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	CRONJOB2=PF_S1_Step2_MassProc.sh
	CRONJOB2SM=PF_S1_Step2_MassProc_SM.sh

	CRONJOB2D=PF_S1_Step3_MSBAS_DEMGeoid.sh

	# All components
	################
	ALLCOMP=UD_EW_NS

	# 3D
	####
	FG=75 	# size of the filtering window in m (e.g. 10000, that is 10 km)
		
	# LINESTOSKIP=100 # Specific to Bukavu: because Lake Kivu occupies a large part of the 
		# image to the North, it may induce a bias in the NS gradient. Hence the first 
		# 100 lines are skipped at computing the dem gradients
# ^^^^^^^^^^ Hard coded lines ^^^^^^^^^^^^

# Prepare directories
#####################
	mkdir -p ${MSBASDIR}

	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMIWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMIWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMIWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMIWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMIWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_SMIWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

	# in Coh threshold restriction
	if [ ${IFCOH} == "YES" ] ; then 
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series
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
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g  # remove -f if does not want the linear fit
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit			
		fi
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME1=${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME2=${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}
        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
		
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME1}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME1}.eps
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME2}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME2}.eps

		mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}.eps

        rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg
		
		mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}.txt
		mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}.txt
	
		if [ "${ALLCOMP}" == "UD_EW_NS" ] ; then 
			mv ${MSBASDIR}/timeLine_NS_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_NS_${COORDLABELNAME12}.txt
		fi
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
	
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME1=${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME2=${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}
        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
	
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] ; then 
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME1}_NoCohThresh.eps
		fi
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME2}_NoCohThresh.eps
		fi 
 
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh.eps

           rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg

			mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}_NoCohThresh.txt
			mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}_NoCohThresh.txt
		fi

		if [ "${ALLCOMP}" == "UD_EW_NS" ] ; then 
			mv ${MSBASDIR}/timeLine_NS_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_NS_${COORDLABELNAME12}_NoCohThresh.txt
		fi
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
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME1=${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME2=${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}
        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}		

		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME1}.eps
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME2}.eps
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}.eps

		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/
	
        rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg

		}

	function MSBASmode()
		{
		unset MODE # e.g. SMIWasc or IWdesc
		local MODE=$1
		cd ${MSBASDIR}
		cp -f ${MSBASDIR}/header_${MODE}.txt  header.txt 
		${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS} --msbasv4

		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		# remove header line to avoid error message 
		while read -r DESCR X Y RX RY
			do	
				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
				mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
				mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf 2>/dev/null
				# there is no automatic plotting by msbas when only in LOS 
		done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
		# Why not some double difference plotting
		while read -r X1 Y1 X2 Y2 DESCR
			do	
				PlotAllLOS ${X1} ${Y1} ${X2} ${Y2} ${DESCR} ${MODE}
		done < ${FILEPAIRS}						
	
		# move all plots in same dir 
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		
		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/__Combi/*.jpg
		mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/*_Combi*.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/__Combi/
		}

# Check that there is no other Step3 running
#############################################
	CHECKCRON3=`ps -Af | ${PATHGNU}/grep "Step3" | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" | grep -v "Crons_1_2_3.sh"  | wc -l`
	if [ ${CHECKCRON3} -gt 0 ] ; then 
			REASON=" another Step3 is running, which may overload the computer; pause here" 
			STOPRUN="YES"
	fi


# Check that there is no other cron (Step 2 or 3) or manual SuperMaster_MassProc.sh running
###########################################################################################

	RUNDATE=$(date "+%m_%d_%Y_%Hh%Mm")
	RNDM=$(( $RANDOM % 10000 ))
	
	# Create a Flag file that warns that crons are running for the target and make a trap to delete it when script ends or is stopped by ctrl-C (not if terminated by reboot or kill -9)
	FLAGFILE="${PATH_DIR_FOR_FLAG}"/"Running_crons_${TARGET}_${RUNDATE}_${RNDM}.txt"
	FLAGFILE_SM="${PATH_DIR_FOR_FLAG_SM}"/"Running_crons_${TARGET}_${RUNDATE}_${RNDM}.txt"

	cleanup() {
	  rm -f "${FLAGFILE}" "${FLAGFILE_SM}" 2>/dev/null
	}

	trap cleanup EXIT INT TERM

	# Check that no other cron job step 1 or 2 is running, e.g from another computer
		if find "$PATH_DIR_FOR_FLAG" "$PATH_DIR_FOR_FLAG_SM" \
		    -maxdepth 1 -name "Running_crons_${TARGET}*" -print -quit | grep -q .; then
		  echo "Another cron is running for ${TARGET}. Aborting."
		  exit 1
		fi
	
	# Create the flag files
		touch "$FLAGFILE" "$FLAGFILE_SM"
    	echo "start cron 3 at $(date '+%Y-%m-%d %H:%M:%S')" >> "${FLAGFILE}"
    	echo "start cron 3 at $(date '+%Y-%m-%d %H:%M:%S')" >> "${FLAGFILE_SM}"


	# Check that no other cron job step 3 (MSBAS) or manual SuperMaster_MassProc.sh is running
	CHECKMB=`ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null"  | grep -v "Crons_1_2_3.sh"  | wc -l`
		#### For Debugging
		# echo "ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v ${PATHGNU}/grep | ${PATHGNU}/grep -v /dev/null | wc -l" > CheckRun.txt
		# echo ${CHECKMB} >> CheckRun.txt
		# ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" >> CheckRun.txt

	if [ ${CHECKMB} -gt 3 ] ; then # use ${PATHGNU}/grep -v "grep "  instead of ${PATHGNU}/grep -v "grep ${PRG}" because depending on environment, it may miss the second version
			REASON=" another ${PRG} is running" 
			STOPRUN="YES"
		else
			# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
			CHECKASCSM=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${LAUNCHPARAMASCSM} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | grep -v "Crons_1_2_3.sh"  | wc -l` 
			CHECKDESCSM=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${LAUNCHPARAMDESCSM} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | grep -v "Crons_1_2_3.sh"  | wc -l` 
			CHECKASCIW=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${LAUNCHPARAMASCIW} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | grep -v "Crons_1_2_3.sh"  | wc -l` 
			CHECKDESCIW=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${LAUNCHPARAMDESCIW} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | grep -v "Crons_1_2_3.sh"  | wc -l` 
	
	
			# For unknown reason it counts 1 even when no process is running
			if [ ${CHECKASCSM} -ne 0 ] || [ ${CHECKDESCSM} -ne 0 ] || [ ${CHECKASCIW} -ne 0 ] || [ ${CHECKDESCIW} -ne 0 ]; then REASON="  SuperMaster_MassProc.sh in progress (probably manual)" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi  	
	fi 

	# Check that no other cron job step 2 (SuperMaster_MassProc.sh) is running
	CHECKMPIW=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | grep -v "Crons_1_2_3.sh"  | wc -l`
	CHECKMPSM=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2SM} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | grep -v "Crons_1_2_3.sh"  | wc -l`
	if [ ${CHECKMPIW} -ne 0 ] || [ ${CHECKMPSM} -ne 0 ] ; then REASON=" SuperMaster_MassProc.sh in progress (from ${CRONJOB2} or ${CRONJOB2SM})" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi 

	# Check that no other cron job step 3 2D (SuperMaster_MassProc.sh) is running
	CHECKMP=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2D} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | grep -v "Crons_1_2_3.sh" | wc -l`
	if [ ${CHECKMP} -ne 0 ] ; then REASON=" Same cron job step 3 though in 2D in progress (${CRONJOB3D})" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi 

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
# reprocessing with updated orbits. If duplicated product detected, it keeps only the most recent product.  

	cd ${S1ASCSM}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${S1DESCSM}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${S1ASCIW}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${S1DESCIW}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	wait
	
# Get date (in sec) of last available processed pairs in each MODE
##################################################################
	# get the name of last available processed pair in each MODE

	LASTASCSM=`find ${S1ASCSM}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTDESCSM=`find ${S1DESCSM}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTASCIW=`find ${S1ASCIW}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTDESCIW=`find ${S1DESCIW}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	# get date in sec of last available processed pairs in each MODE
	LASTASCTIMESM=`stat -c %Y ${LASTASCSM}`
	LASTDESCTIMESM=`stat -c %Y ${LASTDESCSM}`
	LASTASCTIMEIW=`stat -c %Y ${LASTASCIW}`
	LASTDESCTIMEIW=`stat -c %Y ${LASTDESCIW}`


# Check if first run and if  appropriate, get time of last images in time series
################################################################################
	if [ -f "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] && [ -s "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] 
		then   
			echo "Existing ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence not the first run"
			FIRSTRUN=NO
			FORMERLASTASCTIMESM=`head -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`
			FORMERLASTDESCTIMESM=`head -2 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLASTASCTIMEIW=`head -3 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLASTDESCTIMEIW=`tail -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`

			
			if [ ${FORMERLASTASCTIMESM} -eq ${LASTASCTIMESM} ] && [ ${FORMERLASTDESCTIMESM} -eq ${LASTDESCTIMESM} ] &&  [ ${FORMERLASTASCTIMEIW} -eq ${LASTASCTIMEIW} ] && [ ${FORMERLASTDESCTIMEIW} -eq ${LASTDESCTIMEIW} ]  # if no more recent file is available since the last cron processing
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
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}1 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}2 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}3 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}4 &
		wait
		echo "Possible broken links in former existing MODEi dir are cleaned"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)	
		if [ ${IFCOH} == "YES" ] ; then 
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}1_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}2_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}3_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}4_Full &
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
		mv ${DEFOMODE}1.txt ${DEFOMODE}1_all4col.txt
		mv ${DEFOMODE}2.txt ${DEFOMODE}2_all4col.txt
		mv ${DEFOMODE}3.txt ${DEFOMODE}3_all4col.txt
		mv ${DEFOMODE}4.txt ${DEFOMODE}4_all4col.txt	
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}3_all4col.txt > ${DEFOMODE}3.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}4_all4col.txt > ${DEFOMODE}4.txt 
	
		rm -f ${DEFOMODE}1_all4col.txt ${DEFOMODE}2_all4col.txt ${DEFOMODE}3_all4col.txt ${DEFOMODE}4_all4col.txt
		echo "All lines in former existing ${DEFOMODE}i.txt have 4 columns"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			mv ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt
			mv ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt 
			rm -f ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt
			echo "All lines in former existing ${DEFOMODE}i_Full.txt have 4 columns"
			echo ""
		fi
	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
		cd ${MSBASDIR}
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1 ${PATH_3601}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2 ${PATH_3601}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}3 ${PATH_3601}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}4 ${PATH_3601}/SAR_MASSPROCESS &
		wait
		echo "All lines in former existing MODEi.txt are ok"
		echo ""
	
		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1_Full ${PATH_3601}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2_Full ${PATH_3601}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}3_Full ${PATH_3601}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}4_Full ${PATH_3601}/SAR_MASSPROCESS &
			wait
			echo "All lines in former existing MODEi_Full.txt are ok"
			echo ""	
		fi
	
	fi

# Prepare MSBAS
###############
	#${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_criteria.sh DefoInterpolx2Detrend 4 ${BP} ${BT} ${S1ASCSM} ${S1DESCSM} ${S1ASCIW} ${S1DESCIW}
	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh ${DEFOMODE} 4 ${TABLESET1} ${TABLESET2} ${TABLESET3} ${TABLESET4} ${S1ASCSM} ${S1DESCSM} ${S1ASCIW} ${S1DESCIW}

	# if 3D, add NS component for msbas inversion 
	Add_NS_comp_msbas.sh "${FG}" Force ${LINESTOSKIP}		# Force forces to recompute the filtering just in case one would have change FG value. It should be fast anyway. 

	# update here the R_FLAG if needed
	#${PATHGNU}/gsed -i "s/R_FLAG = 2, 0.02/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt
	${PATHGNU}/gsed -i "s/^R_FLAG.*/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt

	## If interferos are detreneded, i.e. averaged to zero, there is no need to calibrate again 
	#${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 0/' ${MSBASDIR}/header.txt
	## Not the case here, hence chose calibration pixel(s)
	#${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 1, 45, 197, 5, 5/' ${MSBASDIR}/header.txt
	## BEWARE: For 3D, one must calibrate with DEM, that is option 10, which is already performed by Add_NS_comp_msbas.sh 

	# Crop the region to invert
	${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = ${XMIN}, ${XMAX}, ${YMIN}, ${YMAX}/" ${MSBASDIR}/header.txt

	# Check again that files are OK
		# ensure that format is ok, that is with 4 columns 
		mv ${DEFOMODE}1.txt ${DEFOMODE}1_all4col.txt
		mv ${DEFOMODE}2.txt ${DEFOMODE}2_all4col.txt
		mv ${DEFOMODE}3.txt ${DEFOMODE}3_all4col.txt
		mv ${DEFOMODE}4.txt ${DEFOMODE}4_all4col.txt
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}3_all4col.txt > ${DEFOMODE}3.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}4_all4col.txt > ${DEFOMODE}4.txt 
		# keep track of prblms
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}3_all4col.txt > ${DEFOMODE}3_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}4_all4col.txt > ${DEFOMODE}4_MissingCol.txt 
		rm -f ${DEFOMODE}1_all4col.txt ${DEFOMODE}2_all4col.txt ${DEFOMODE}3_all4col.txt ${DEFOMODE}4_all4col.txt
		
		# Need again to check for duplicated lines with different Bp in Col 2 resulting from orbit update 
		if [ ${IFCOH} == "YES" ] ; then 
			echo "Remove lines in newly created MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1 ${PATH_3601}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2 ${PATH_3601}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}3 ${PATH_3601}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}4 ${PATH_3601}/SAR_MASSPROCESS &

			wait
			echo "All lines in new ${DEFOMODE}i.txt should be ok"
			echo ""	
		fi

# Let's go
##########
	cd ${MSBASDIR}
	cp -f header.txt header_back.txt 

	# EW-UD without coh threshold restriction 
	#----------------------------------------
# 		case ${FIRSTRUN} in 
# 			"YES") 
# 				# one have only the newly created MODEi dir and MODEi.txt
# 				cp -R ${MSBASDIR}/DefoInterpolx2Detrend1 ${MSBASDIR}/DefoInterpolx2Detrend1_Full
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
# 				
# 				cp -R ${MSBASDIR}/DefoInterpolx2Detrend2 ${MSBASDIR}/DefoInterpolx2Detrend2_Full
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend2.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend2.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt
# 				;;
# 			"NO")
# 				# one must merge the newly created MODEi dir and MODEi.txt with former _Full ones
# 				sort ${MSBASDIR}/DefoInterpolx2Detrend1.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt
# 				sort ${MSBASDIR}/DefoInterpolx2Detrend2.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt
# 				
# 				sort ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt
# 				sort ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt
# 				
# 				cat ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
# 				cat ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt
# 				
# 				cp -R -n ${MSBASDIR}/DefoInterpolx2Detrend1 ${MSBASDIR}/DefoInterpolx2Detrend1_Full
# 				cp -R -n ${MSBASDIR}/DefoInterpolx2Detrend2 ${MSBASDIR}/DefoInterpolx2Detrend2_Full
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
# 				
# 				rm -f ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt 
# 				rm -f ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt
# 				;;	
# 		esac
# 		# trick the header file						
# 		${PATHGNU}/gsed -i 's/DefoInterpolx2Detrend1.txt/DefoInterpolx2Detrend1_Full.txt/' ${MSBASDIR}/header.txt
# 		${PATHGNU}/gsed -i 's/DefoInterpolx2Detrend2.txt/DefoInterpolx2Detrend2_Full.txt/' ${MSBASDIR}/header.txt
# 
# 		${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${TIMESERIESPTS} --msbasv4
# 
# 		# Make baseline plot 
# 		PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
# 		PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
# 
# 		# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
# 		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
# 		# remove header line to avoid error message 
# 		#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
# 		while read -r DESCR X Y RX RY
# 			do	
# 				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
# 				mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
# 				mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
# 		done < ${TIMESERIESPTSDESCRNOHEADER}
# 
# 		# Why not some double difference plotting
# 		while read -r X1 Y1 X2 Y2 DESCR
# 			do	
# 				PlotAllNoCoh ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
# 		done < ${DOUBLEDIFFPAIRSEWUD}
# 			
#  		# move all plots in same dir 
#  		mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
#  
#  		# move all time series in dir 
# 		mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series/

	# EW-UD with coh threshold restriction 
 	#--------------------------------------
         cd ${MSBASDIR}
         cp -f header_back.txt header.txt

        # run restrict_msbas_to_Coh.sh         
#         restrict_msbas_to_Coh.sh DefoInterpolx2Detrend1 ${COHRESTRICT} ${KMLCOH} ${S1ASC}/Geocoded/Coh
 #        restrict_msbas_to_Coh.sh DefoInterpolx2Detrend2 ${COHRESTRICT} ${KMLCOH} ${S1DESC}/Geocoded/Coh
		
#		# Force pair exclusion 
#			if [ ${EXCLUDE1} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend1
#			fi 
#			if [ ${EXCLUDE2} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend2
#			fi 
#			if [ ${EXCLUDE3} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend3
#			fi 
#			if [ ${EXCLUDE4} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend4
#			fi 
#		cd ${MSBASDIR}
		${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS} --msbasv4

		# test if MSBAS_log.txt contains "completed 100%" ; if not log error 
#		if ${PATHGNU}/grep -q "writing results to a disk" ${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LOG.txt
#	 		then 
# 				echo "MSBAS ok" 
# 			else 
# 				# try again after cleaning DefoInterpolx2Detrendi.txt
# 				_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATH_3601}/SAR_MASSPROCESS &
# 				_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATH_3601}/SAR_MASSPROCESS &
# 				wait 
# 				
# 				${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS} --msbasv4
# 				if ${PATHGNU}/grep -q "writing results to a disk" ${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LOG.txt ; then echo "Solved after cleaning DefoInterpolx2Detrend's txt"; else  echo "!! MSBAS crashed on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt ; fi
# 		fi

		# Make baseline plot 
		PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${DEFOMODE}1.txt
		PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${DEFOMODE}2.txt
		PlotBaselineGeocMSBASmodeTXT.sh ${SET3} ${MSBASDIR}/${DEFOMODE}3.txt
		PlotBaselineGeocMSBASmodeTXT.sh ${SET4} ${MSBASDIR}/${DEFOMODE}4.txt
		
		# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/

		while read -r DESCR X Y RX RY
			do	
				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
 				mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt 2>/dev/null
 				mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf 2>/dev/null
		done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header

		# Why not some double difference plotting
		while read -r X1 Y1 X2 Y2 DESCR
			do	
				PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
		done < ${DOUBLEDIFFPAIRSEWUD}	
						
 		# move all plots in same dir 
 		rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/__Combi/*.jpg
 		mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/*_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/__Combi/

		# move all time series in dir 
		mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/_Time_series/

		
 	# Compute Asc and Desc even if they may exist from 2D inversion because order and lambda may differ
  	#--------------------------------------------------------------------------------------------------
 		# Prepare header files
		#   backup header
		cp -f ${MSBASDIR}/header.txt ${MSBASDIR}/header_${ALLCOMP}.txt 

		# remove line with NS in ${MSBASDIR}/header.txt
		cat ${MSBASDIR}/header.txt | grep -v "DD_NSEW_FILES" >  ${MSBASDIR}/header_2Modes.txt


		#   search for line nr of each SET mode definition
 		LINENRSMASC=$(cat ${MSBASDIR}/header_2Modes.txt | ${PATHGNU}/grep -n "SET =" | head -1 | cut -d: -f1)
 		LINENRSMDESC=$(cat ${MSBASDIR}/header_2Modes.txt | ${PATHGNU}/grep -n "SET =" | head -2 | tail -1 | cut -d: -f1)
 		LINENRIWASC=$(cat ${MSBASDIR}/header_2Modes.txt | ${PATHGNU}/grep -n "SET =" | head -3 | tail -1 | cut -d: -f1)
 		LINENRIWDESC=$(cat ${MSBASDIR}/header_2Modes.txt | ${PATHGNU}/grep -n "SET =" | tail -1 | cut -d: -f1)

 		#   Change "SET = " with "#SET = " in each line of header
		cat ${MSBASDIR}/header_2Modes.txt | ${PATHGNU}/gsed "s/SET = /#SET = /g" > ${MSBASDIR}/header_none.txt

		#   Change "#SET = " with "SET = " for only the mode one wants to keep 
 		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENRSMASC}' s/#SET = /SET = /' > ${MSBASDIR}/header_SMAsc.txt
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENRSMDESC}' s/#SET = /SET = /' > ${MSBASDIR}/header_SMDesc.txt
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENRIWASC}' s/#SET = /SET = /' > ${MSBASDIR}/header_IWAsc.txt
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENRIWDESC}' s/#SET = /SET = /' > ${MSBASDIR}/header_IWDesc.txt

		cat ${MSBASDIR}/header_SMasc.txt | ${PATHGNU}/gsed ${LINENRIWASC}' s/#SET = /SET = /' > ${MSBASDIR}/header_SMIWAsc.txt
		cat ${MSBASDIR}/header_SMdesc.txt | ${PATHGNU}/gsed ${LINENRIWDESC}' s/#SET = /SET = /' > ${MSBASDIR}/header_SMIWDesc.txt

		rm -f ${MSBASDIR}/header_none.txt

		# SM & IW ASC
 				FILEPAIRS=${DOUBLEDIFFPAIRSASCSMIW}
 				MSBASmode SMIWasc
  		
		# SM @ IW DESC
 				FILEPAIRS=${DOUBLEDIFFPAIRSDESCSMIW}
				MSBASmode SMIWdesc

 		# SM ASC
				FILEPAIRS=${DOUBLEDIFFPAIRSASCSM}
				MSBASmode SMAsc
 		
 
 		# SM DESC
				FILEPAIRS=${DOUBLEDIFFPAIRSDESCSM}
				MSBASmode SMDesc

 		# IW ASC
				FILEPAIRS=${DOUBLEDIFFPAIRSASCIW}
				MSBASmode IWAsc
 		
 
 		# IW DESC
				FILEPAIRS=${DOUBLEDIFFPAIRSDESCIW}
				MSBASmode IWDesc

 		# Back to normal for next run and get out
 				cp -f ${MSBASDIR}/header_${ALLCOMP}.txt ${MSBASDIR}/header.txt 		 				

				TODAY=`date`
				echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt

				echo "${LASTASCTIMESM}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LASTDESCTIMESM}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LASTASCTIMEIW}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LASTDESCTIMEIW}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt

# 			${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Desc_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS} --msbasv4
# 
# 			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/
# 			while read -r DESCR X Y RX RY
# 				do	
# 					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
# 					mv ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
# 					# there is no automatic plotting by msbas when only in LOS 
# 			done < ${TIMESERIESPTSDESCRNOHEADER}
# 
# 			# Why not some double difference plotting			
# 			while read -r X1 Y1 X2 Y2 DESCR
# 				do	
# 					PlotAllLOSdesc ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
# 			done < ${DOUBLEDIFFPAIRSDESC}		
# 	
# 			# move all plots in same dir 
#  			mv ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi*.jpg ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
#  			# move all time series in dir 
# 			mv ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
# 
# 	# Back to normal for next run and get out
# 		cp -f ${MSBASDIR}/header_back.txt ${MSBASDIR}/header.txt 		 				
# 
# 		TODAY=`date`
# 		echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt
# 
# 		echo "${LASTASCTIME}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
# 		echo "${LASTDESCTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
		
		#mv -f ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp ${MSBASDIR}/${TIMESERIESPTSDESCR}

# All done...

# Keep track of last successful run
	cp -f "${PATH_DIR_FOR_FLAG}"/"Running_crons_${TARGET}_${RUNDATE}_${RNDM}.txt" "${PATH_DIR_FOR_FLAG}"/"Last_Sucessful_Crons_${TARGET}.txt" 	
	cp -f "${PATH_DIR_FOR_FLAG_SM}"/"Running_crons_${TARGET}_${RUNDATE}_${RNDM}.txt" "${PATH_DIR_FOR_FLAG_SM}"/"Last_Sucessful_Crons_${TARGET}_SM.txt" 	
