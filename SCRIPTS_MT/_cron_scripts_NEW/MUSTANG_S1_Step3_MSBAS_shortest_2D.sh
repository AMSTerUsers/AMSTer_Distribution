#!/bin/bash
# Script to run in cronjob for processing MUSTANG images:
# series when new images were made available. If orbits were updated, corresponding products 
# will be taken into account at the time of processing with new images. 
# 
# It will prepare and run MSBAS only if no other mass process is in progress.
# It also plots several time series and double differences based on provided list of points. 
#
# NOTE: - MSBAS Calibration is disabled because deformation maps are detrended at processing. 
#
# Parameters: - none 
#
# Hardcoded: - a lot... se below paragraph named HARD CODED but also adapt below depending on the number of modes 
#			 - suppose everywhere that modes are DefoInterpolx2Detrend
#
# Dependencies:	- awk 
#				- several scripts from SCRIPTS_MT
#
# New in Distro V 1.0.0 20250804 :	- based on Galeras processing
# New in Distro V 2.0.0 20251029 :	- restrict to 128 Threads
# New in Distro V 2.1.0 20251125 :	- always limited to 128 threads (see MAXTHREADS) to prevent problems with OPENBLAS, which is compiled by default for 128 threads 
									
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Nov 25, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

cd

TODAY=`date`

# vvvvvvvvv Hard coded lines vvvvvvvvvvvvvv
	# some parameters
	#################
		# Max number of threads (to avoid problem with openmp which is by default compiled for max 128)
		MAXTHREADS=128

		# MAX Shortests connections
		MAXSHORT=3
		
		# Max baselines (used for all the mode in present case but you can change)
		SET1BP1=30
		SET1BP2=70
		SET1BT1=400
		SET1BT2=400
		DATECHG1=20220501

		SET2BP1=30
		SET2BP2=70
		SET2BT1=400
		SET2BT2=400
		DATECHG2=20220501

		## Path to dir where list of compatible pairs files are computed (need one for each mode)
		SET1=${PATH_1660}/SAR_SM/MSBAS/MUSTANG/set1
		SET2=${PATH_1660}/SAR_SM/MSBAS/MUSTANG/set2

		#TABLESET1=${SET1}/table_0_${SET1BP1}_0_${SET1BT1}_Till_${DATECHG1}_0_${SET1BP2}_0_${SET1BT2}_After.txt #DO not take _WITHHEADER.txt as it does not contains AdditionalPairs
		#TABLESET2=${SET2}/table_0_${SET2BP1}_0_${SET2BT1}_Till_${DATECHG2}_0_${SET2BP2}_0_${SET2BT2}_After.txt #DO not take _WITHHEADER.txt as it does not contains AdditionalPairs 
		TABLESET1=${SET1}/table_0_0_MaxShortest_${MAXSHORT}.txt
		TABLESET2=${SET2}/table_0_0_MaxShortest_${MAXSHORT}.txt

		# WARNING: 	build_header_msbas_criteria.sh requires all table files with the same Bp and Bt names, hence one MUST link 
		#			SM tables as tables named with max baselines ; if they exist yet, rename them first as _Real an then link the final table to new name with max baselines 
		# Solution changing all the tables with the same name:
		# Max baselines (used for all the mode in present case but you can change)
		   	#BP=50			# max perpendicular baseline 
		   	#BT=150			# max temporal baseline

#		# If several criteria are used, or if Tables are used, select max 
#			## To take into account the whole set of data with both sets 
#			## of baseline criteria, one must take here the largest of each Bp and Bt 
#			## See warning below
#			BP=$(echo "$SET1BP1 $SET1BP2 $SET2BP1 $SET2BP2" | awk '{BP=$1; for(i=2;i<=NF;i++) if($i>BP) BP=$i; print BP}')	# max perpendicular baseline 
#			BT=$(echo "$SET1BT1 $SET1BT2 $SET2BT1 $SET2BT2" | awk '{BT=$1; for(i=2;i<=NF;i++) if($i>BT) BT=$i; print BT}')	# max temporal baseline
#			# Just in case a table would exist with the same values as the max Bp and Bt among all the modes, let's keep it with the name table_0_${BP}_0_${BT}_RealBaselinesVal.txt
#			# then link the dual table as a table with the common name table_0_${BP}_0_${BT}.txt for each mode 
#			if [ -f ${SET1}/table_0_${BP}_0_${BT}.txt ] && [ `diff ${SET1}/table_0_${BP}_0_${BT}.txt ${TABLESET1} | wc -l ` -gt 0 ]
#				then 
#					mv ${SET1}/table_0_${BP}_0_${BT}.txt ${SET1}/table_0_${BP}_0_${BT}_RealBaselinesVal.txt
#					ln -s ${TABLESET1} ${SET1}/table_0_${BP}_0_${BT}.txt  2>/dev/null
#			fi
#			
#			if [ -f ${SET2}/table_0_${BP}_0_${BT}.txt ] && [ `diff ${SET2}/table_0_${BP}_0_${BT}.txt ${TABLESET2} | wc -l ` -gt 0 ]
#				then 
#					mv ${SET2}/table_0_${BP}_0_${BT}.txt ${SET2}/table_0_${BP}_0_${BT}_RealBaselinesVal.txt
#					ln -s ${TABLESET2} ${SET2}/table_0_${BP}_0_${BT}.txt  2>/dev/null
#			fi
#
		# This can be improved by using e.g. build_header_msbas_Tables.sh to cope with several criteria... 
		# If AdditionalPairs were selected, YOU MUST use tables 

		LABEL=Mustang 				# Label for file naming (used for naming zz_ dirs with results and figs etc)
		eval LABELORIG=${LABEL}		# for later usage
		
		#R_FLAG
		# Order
		ORDER=3
		# Lambda
		LAMBDA=0.04
		
	# some files and PATH for each mode
	###################################

		SMASC=20241116		# Asc 158
		SMDESC=20190830		# Desc 19

		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
		# IW
		S1ASCIW=$PATH_3611/SAR_MASSPROCESS/S1/MUSTANG_A_158/SMNoCrop_SM_${SMASC}_Zoom1_ML2
		S1DESCIW=$PATH_3611/SAR_MASSPROCESS/S1/MUSTANG_D_19/SMNoCrop_SM_${SMDESC}_Zoom1_ML2

		# Path to LaunchParameters.txt files for each mode (need one for each mode)
		LAUNCHPARAMASCIW=LaunchMTparam_S1_Mustang_A_158_Zoom1_ML2_MassProc_0keep.txt
		LAUNCHPARAMDESCIW=LaunchMTparam_S1_Mustang_D_19_Zoom1_ML2_MassProc_0keep.txt


		
	# Events tables
	###############
		EVENTS=${PATH_1650}/EVENTS_TABLES/${LABEL}

	# Path to dir where MSBAS will be computed
	###########################################
		#MSBASDIR=${PATH_3610}/MSBAS/_${LABEL}_S1_Auto_Max${MAXSHORT}Shortests	
		MSBASDIR="${PATH_3610}/MSBAS/_${LABEL}_S1_Auto_Max${MAXSHORT}Shortests_ExcludePairs0.015"	
		#MSBASDIR=${PATH_3610}/MSBAS/_${LABEL}_S1_Auto_${BP}m_${BT}days	#_Till${DATECHG1}_${SET1BP2}m_After
		# NOTE HERE UNUSUAL NAMING TO REMEMBER THAT IT WAS PREPRARED WITH DATA SETS WITH DIFFERENT MAX BT
		
	# Coherence restriction
	########################		
		IFCOH="NO"		# YES or NO  BEWARE: DO NOT RUN YES after NO or NO after YES without cleaning all the MSBAS dir before  

		if [ ${IFCOH} == "YES" ] 
			then 

				# Path to kml zone used to check coherence
				KMLCOH=${PATH_1650}/kml/Colombia/Galeras_Summit.kml	

				# Coherence restriction threshold (to be compared to mean coh computed on KMLCOH)
				COHRESTRICT=0.31

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
		TIMESERIESPTSDESCR=${PATH_1650}/Data_Points/Points_TS_${LABEL}_TST.txt

		# List of PAIRS of points for plotting double difference (i.e. without error bar) in EW and UD, ASC and Desc... 
		# 	Note: if pixels are coherent in all modes, these can be the same list
		DOUBLEDIFFPAIRSEWUD=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}_TST.txt
 		DOUBLEDIFFPAIRSASCIW=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}_TST.txt
 		DOUBLEDIFFPAIRSDESCIW=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}_TST.txt
		
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	CRONJOB2=MUSTANG_S1_Step2_MassProc.sh
	
# ^^^^^^^^^^ Hard coded lines ^^^^^^^^^^^^

# set the max number of threads to be used by MSBAS. 
####################################################
#Remember that OPENBLAS is pre-compiled for Ubuntu with max 128 threads
	# Check OS
	OS=`uname -a | cut -d " " -f 1 `

	case ${OS} in 
		"Linux") 
			NTHR=$(nproc --all)	 ;;
		"Darwin")
			NTHR=$(sysctl -n hw.ncpu) 	;;
		*)
			echo "${MESSAGE}" 	;;
	esac			

	# get the number frm your hardware 
	if [ ${NTHR} -gt ${MAXTHREADS} ] ; then NTHR=${MAXTHREADS} ; fi

# Prepare directories
#####################
	mkdir -p ${MSBASDIR}

 	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}
 	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
 	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
 
 	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}
 	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
 	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

 	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}
 	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
 	mkdir -p ${MSBASDIR}/zz_LOS_TS_IWDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

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
		
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME1}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME1}.eps
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME2}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME2}.eps

		mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}.eps
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg

        rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg
		
		mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}.txt
		mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}.txt
	
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
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME1=${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME2=${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}
        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
	
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] ; then 
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME1}_NoCohThresh.eps
		fi
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME2}_NoCohThresh.eps
		fi 
 
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh.eps

#			# add map tag in fig
#			convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg
#			# get location from dir with coh threshold (where it was added manually)
#			convert ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_NoCohThresh.jpg

            rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg

			mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}_NoCohThresh.txt
			mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}_NoCohThresh.txt
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
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_${MODE}.jpg

        rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg

		#mv ${MSBASDIR}/timeLine_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
		#mv ${MSBASDIR}/timeLine_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
	
#		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg

		}

	function MSBASmode()
		{
		unset MODE # e.g. SMIWasc or IWdesc
		local MODE=$1
		cd ${MSBASDIR}
		cp -f ${MSBASDIR}/header_${MODE}.txt  header.txt 
		NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}

		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		# remove header line to avoid error message 
		#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
		while read -r DESCR X Y RX RY
			do	
				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
				mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
				mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf

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

		# move all time series in dir 
		#mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
		}


# Check that there is no other cron (Step 2 or 3) or manual SuperMaster_MassProc.sh running
###########################################################################################
	# Check that no other cron job step 3 (MSBAS) or manual SuperMaster_MassProc.sh is running
	CHECKMB=`ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null"  | wc -l`
		#### For Debugging
		# echo "ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v ${PATHGNU}/grep | ${PATHGNU}/grep -v /dev/null | wc -l" > CheckRun.txt
		# echo ${CHECKMB} >> CheckRun.txt
		# ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" >> CheckRun.txt

	if [ ${CHECKMB} -gt 3 ] ; then # use ${PATHGNU}/grep -v "grep "  instead of ${PATHGNU}/grep -v "grep ${PRG}" because depending on environment, it may miss the second version
			REASON=" another ${PRG} is running" 
			STOPRUN="YES"
		else
			# Check that no other SuperMaster_MassProc.sh automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
			CHECKASCIW=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${LAUNCHPARAMASCIW} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
			CHECKDESCIW=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${LAUNCHPARAMDESCIW} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
	
	
			# For unknown reason it counts 1 even when no process is running
			if [ ${CHECKDESCIW} -ne 0 ]  || [ ${CHECKASCIW} -ne 0 ] ; then REASON="  SuperMaster_MassProc.sh in progress (probably manual)" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi  	

	fi 

	# Check that no other cron job step 2 (SuperMaster_MassProc.sh) is running
	CHECKMPIW=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l`

	if [ ${CHECKMPIW} -ne 0 ] ; then REASON=" SuperMaster_MassProc.sh in progress (from ${CRONJOB2})" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi 

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

 	cd ${S1ASCIW}
 	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
 	cd ${S1DESCIW}
 	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	wait
	
# Get date (in sec) of last available processed pairs in each MODE
##################################################################
	# get the name of last available processed pair in each MODE
    # ls crashes when too many files
	#LASTASCIW=`ls -lt ${S1ASCIW}/Geocoded/DefoInterpolx2Detrend | head -n 2 | tail -n 1 | sed 's/.* //'` # may be messing up if txt files are created for any other purpose in the dir... 
	#LASTDESCIW=`ls -lt ${S1DESCIW}/Geocoded/DefoInterpolx2Detrend | head -n 2 | tail -n 1 | sed 's/.* //'`
	LASTASCIW=`find ${S1ASCIW}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTDESCIW=`find ${S1DESCIW}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	# get date in sec of last available processed pairs in each MODE
	LASTASCTIMEIW=`stat -c %Y ${LASTASCIW}`
	LASTDESCTIMEIW=`stat -c %Y ${LASTDESCIW}`


# Check if first run and if  appropriate, get time of last images in time series
################################################################################
	if [ -f  "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] && [ -s  "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ]
		then   
			echo "Existing ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence not the first run"
			FIRSTRUN=NO
			FORMERLASTASCTIMEIW=`head -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`
			FORMERLASTDESCTIMEIW=`tail -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`

			# if no more recent file is available since the last cron processing
			if [ ${FORMERLASTASCTIMEIW} -eq ${LASTASCTIMEIW} ] && [ ${FORMERLASTDESCTIMEIW} -eq ${LASTDESCTIMEIW} ]  
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
	
		rm -f DefoInterpolx2Detrend1_all4col.txt DefoInterpolx2Detrend2_all4col.txt 2>/dev/null
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
	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
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
	## Solution with criteria:
	#	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_criteria.sh DefoInterpolx2Detrend 2 ${BP} ${BT} ${S1ASCIW} ${S1DESCIW} 
	## Solution with TABLES (needed e.g. when using AdditionalPairs):
		cd ${MSBASDIR}
		${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh DefoInterpolx2Detrend 2 ${TABLESET1} ${TABLESET2} ${S1ASCIW} ${S1DESCIW} 

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

# Let's go
##########
	cd ${MSBASDIR}
	cp -f header.txt header_back.txt 

	if [ ${IFCOH} == "YES" ] 
		then 
			# EW-UD without coh threshold restriction 
			#----------------------------------------
				case ${FIRSTRUN} in 
					"YES") 
						# one have only the newly created MODEi dir and MODEi.txt
						cp -R ${MSBASDIR}/DefoInterpolx2Detrend1 ${MSBASDIR}/DefoInterpolx2Detrend1_Full
						cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
						cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
						
						cp -R ${MSBASDIR}/DefoInterpolx2Detrend2 ${MSBASDIR}/DefoInterpolx2Detrend2_Full
						cp -f ${MSBASDIR}/DefoInterpolx2Detrend2.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
						cp -f ${MSBASDIR}/DefoInterpolx2Detrend2.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt

						# Make baseline plot 
						PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
						PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt
						mv ${MSBASDIR}/baselinePlot_DefoInterpolx2Detrend1.txt.png ${MSBASDIR}/baselinePlot_DefoInterpolx2Detrend1_Full.txt.png 
						mv ${MSBASDIR}/baselinePlot_DefoInterpolx2Detrend2.txt.png ${MSBASDIR}/baselinePlot_DefoInterpolx2Detrend2_Full.txt.png 
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

						# Make baseline plot 
						PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
						PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
						;;	
				esac
				# trick the header file						
				${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend1.txt/DefoInterpolx2Detrend1_Full.txt/" ${MSBASDIR}/header.txt
				${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend2.txt/DefoInterpolx2Detrend2_Full.txt/" ${MSBASDIR}/header.txt
	
				echo "###################################################################"
				echo "# Run MSBAS Without Coh Threshold. With Coh threshold will follow #"
				echo "###################################################################"
		 
				NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${TIMESERIESPTS}
		 
				# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
				cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
				# remove header line to avoid error message 
				#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
				while read -r DESCR X Y RX RY
					do	
						echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
						mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
						mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
				done < ${TIMESERIESPTSDESCRNOHEADER}
		 
				# Why not some double difference plotting
				while read -r X1 Y1 X2 Y2 DESCR
					do	
						PlotAllNoCoh ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
				done < ${DOUBLEDIFFPAIRSEWUD}
					
				# move all plots in same dir 
				mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
		  
				# move all time series in dir 
				mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series/
		 
			# EW-UD with coh threshold restriction 
			#--------------------------------------
				  cd ${MSBASDIR}
				  cp -f header_back.txt header.txt
		 
				 # run restrict_msbas_to_Coh.sh         
		          restrict_msbas_to_Coh.sh DefoInterpolx2Detrend1 ${COHRESTRICT} ${KMLCOH} ${S1ASCIW}/Geocoded/Coh
		          restrict_msbas_to_Coh.sh DefoInterpolx2Detrend2 ${COHRESTRICT} ${KMLCOH} ${S1DESCIW}/Geocoded/Coh
		          
		        # MSBAS is run here after with coh restriction with the same name as regular processing in case of no Coh restriction 
 	fi				
 	
 	# Force pair exclusion - if you want to remove some pairs although they are satisfying the criteria 
 		if [ ${EXCLUDE1} == "YES" ] ; then 
 			${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend1
 		fi 
 		if [ ${EXCLUDE2} == "YES" ] ; then 
 			${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend2
 		fi 

 	cd ${MSBASDIR}	

	if [ ${IFCOH} == "YES" ] 
		then 
 			echo "#####################################"
			echo "# Run MSBAS now with Coh threshold  #"
			echo "#####################################"
 		else 
 			echo "####################################"
			echo "# Run MSBAS without Coh threshold  #"
			echo "####################################"
 	fi

	NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
	
	# test if MSBAS_log.txt contains "completed 100%" ; if not log error 
 	if ${PATHGNU}/grep -q "writing results to a disk" ${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LOG.txt
 		then 
  			echo "MSBAS ok" 
  		else 
  			# try again after cleaning DefoInterpolx2Detrendi.txt
  			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATH_3601}/SAR_MASSPROCESS &
  			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATH_3601}/SAR_MASSPROCESS &
  			wait 
  			
  			NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
  			if ${PATHGNU}/grep -q "writing results to a disk" ${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LOG.txt ; then echo "Solved after cleaning DefoInterpolx2Detrend's txt"; else  echo "!! MSBAS crashed on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt ; fi
  	fi
	
	# Make baseline plot 
	PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1.txt
	PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2.txt
	
	# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
	cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
	
	while read -r DESCR X Y RX RY
		do	
			echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
			
			OLL=${ORDER}_${LAMBDA}_${LABEL}
			mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
			mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
	done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
	
 	# Why not some double difference plotting
 	#WhichPlots
 	while read -r X1 Y1 X2 Y2 DESCR
 		do	
 			PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
 	done < ${DOUBLEDIFFPAIRSEWUD}	
 					
  	# move all plots in same dir 
  	rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/__Combi/*.jpg
  	mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/*_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/__Combi/
 	
 	# move all time series in dir 
 	mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/*.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/_Time_series/
 		
		
	# Asc and Desc 
	#--------------
		# Prepare header files
		#   backup header
		cp -f ${MSBASDIR}/header.txt ${MSBASDIR}/header_UD_EW.txt 
		#   search for line nr of each SET mode definition
		LINENRIWASC=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -1 | cut -d: -f1)
		LINENRIWDESC=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | tail -1 | cut -d: -f1)
		#   Change "SET = " with "#SET = " in each line of header
		cat ${MSBASDIR}/header.txt | ${PATHGNU}/gsed "s/SET = /#SET = /g" > ${MSBASDIR}/header_none.txt
		#   Change "#SET = " with "SET = " for only the mode one wants to keep 

		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENRIWASC}' s/#SET = /SET = /' > ${MSBASDIR}/header_IWAsc.txt
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENRIWDESC}' s/#SET = /SET = /' > ${MSBASDIR}/header_IWDesc.txt

		rm -f ${MSBASDIR}/header_none.txt 2> /dev/null

		# IW ASC
				echo "#######################"
				echo "# Run SBAS Ascending  #"
				echo "#######################"

				FILEPAIRS=${DOUBLEDIFFPAIRSASCIW}
				MSBASmode IWAsc

		# IW DESC
			# Remember that Desc is restricted to images before 20180601 and hence the EW-UD decomposition was restricted as well. 
			# Get it back to full Desc now 
		
			# rename files accordingly
			 mv -f DefoInterpolx2Detrend2_Full.txt DefoInterpolx2Detrend2.txt
				echo "########################"
				echo "# Run SBAS Descending  #"
				echo "########################"

				FILEPAIRS=${DOUBLEDIFFPAIRSDESCIW}
				MSBASmode IWDesc


# Back to normal for next run and get out
		cp -f ${MSBASDIR}/header_UD_EW.txt ${MSBASDIR}/header.txt 		 				

		TODAY=`date`
		echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt

		echo "${LASTASCTIMEIW}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
		echo "${LASTDESCTIMEIW}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
