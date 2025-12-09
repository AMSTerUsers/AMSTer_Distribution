#!/bin/bash
# Script intends to run in a cronjob an automatic systematic (re)processinf of 3D msbas time 
# series when new images were made available. If orbits were updated, corresponding products 
# will be taken into account at the time of processing with new images. It ias based on Funu 
# cron step3. 
#
# LIMITED TO 128 THREADS
# 
# It will prepare and run MSBAS only if no other 2D or 3D mass process is in progress.
# It also plots several time series and double differences based on provided list of points. 
#
# Optional : perform a selection of pairs based on a mean coh computed on a provided footprint.
#			This might be useful for regions known to be affected by strong seasonal decorrelation. 
#			For instance, ensuring a mean coh of at least 0.235 on the Laguna_Maule area (Chile) 
#			ensured a proper estimation of the deformation. Not performing that selection based 
#			on the coh underestimated the defo up to 60%.
#
# NOTE: - Not obliged to use DefoInterpol instead of DefoInterpolx2Detrend because we perform 
#			a small crop on landsliding region, but the Detrend was compute on the whole image. 
#		
#
# Parameters: - none 
#
# Hardcoded: - a lot... se below paragraph named HARD CODED but also adapt below depending on the number of modes 
#			 - suppose everywhere that modes are DefoInterpol !!
#
# Dependencies:	- awk 
#				- several scripts from SCRIPTS_MT
#
# New in Distro V 2.0 20250911:	- Use DefoInterpolx2Detrend
# New in Distro V 2.1 20251029 :	- restrict to 128 Threads
# New in Distro V 2.2 20251104:	- more detailed MSBAS dir naming 
#								- offer option to force inversion even if no new data
# New in Distro V 2.3.0 20251125 :	- always limited to 128 threads (see MAXTHREADS) to prevent problems with OPENBLAS, which is compiled by default for 128 threads 

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Nov 25, 2025"
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
		
		# Max number of threads (to avoid problem with openmp which is by default compiled for max 128)
		MAXTHREADS=128

		# Force recompute MSBAS inversion even if no new Data_Points
		FORCEMSBAS="Yes"		# Anything else than yes would skip forcing

		# MAX Shortests connections
		MAXSHORT=3

		# Max baselines (used for all the mode in present case but you can change)
		#BP=20			# max perpendicular baseline - Not used becasue use table (Delaunay or shortests) instead
		#BT=400			# max temporal baseline - Not used becasue use table (Delaunay or shortests) instead

		# Global Primaries (SuperMasters)
		SMASC=20241116		# Asc 158
		SMDESC=20190830		# Desc 19

		#R_FLAG
		# Order
		ORDER=1
		# Lambda
		LAMBDA=0.05
		
		# Mode
		DEFOMODE=DefoInterpolx2Detrend
		#DEFOMODE=DefoInterpol
	
		# 3D
		####
		FG=75 	# size of the filtering window in m (e.g. 10000, that is 10 km)
		
		LABEL=Mustang3D_${DEFOMODE}_FiltDEM${FG}m 	# Label for file naming (used for naming zz_ dirs with results and figs etc)
		LABELDIR=Mustang3D 	# Label for Points time series and main MSBAS dir 

		
	# some files and PATH for each mode
	###################################
		# Path to SAR_MASSPROCESS
		PATHMASSPROCESS=$PATH_3611/SAR_MASSPROCESS

		# Path to Seti
		PATHSETI=$PATH_1660/SAR_SM/MSBAS

		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
		S1ASC=${PATHMASSPROCESS}/S1/MUSTANG_A_158/SMNoCrop_SM_${SMASC}_Zoom1_ML2
		S1DESC=${PATHMASSPROCESS}/S1/MUSTANG_D_19/SMNoCrop_SM_${SMDESC}_Zoom1_ML2

		# Path to dir where list of compatible pairs files are computed (need one for each mode)
		SET1=${PATHSETI}/MUSTANG/set1
		SET2=${PATHSETI}/MUSTANG/set2

		# Path to LaunchParameters.txt files for each mode (need one for each mode) for Mass Processing
		LAUNCHPARAMASC=LaunchMTparam_S1_Mustang_A_158_Zoom1_ML2_MassProc_0keep.txt
		LAUNCHPARAMDESC=LaunchMTparam_S1_Mustang_D_19_Zoom1_ML2_MassProc_0keep.txt

		# Tables names
		TABLESET1=${SET1}/table_0_0_MaxShortest_${MAXSHORT}.txt
		TABLESET2=${SET2}/table_0_0_MaxShortest_${MAXSHORT}.txt
		
		#tables to exclude pairs from processing
		# These tables are prepared in SETi with 
		# 	RemovePairsFromTableList_Outside_dates.sh seti/table_0_20_0_400.txt 20210521 20210530 
		# as _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt as DATEMAS_DATESLV 
		# They will be copied here below in ${DEFOMODE}i
		PAIRSTOIGNORE1=${SET1}/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
		PAIRSTOIGNORE2=${SET2}/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
		
	# Events tables
	###############
		EVENTS=${PATH_1650}/EVENTS_TABLES/${LABELDIR}

	# Path to dir where MSBAS will be computed
	###########################################
		MSBASDIRCRITERIA=Max${MAXSHORT}Shortests_${DEFOMODE}_FiltDEM${FG}m
		MSBASDIR=${PATH_3610}/MSBAS/_${LABELDIR}_S1_Auto_${MSBASDIRCRITERIA}

		mkdir -p ${MSBASDIR}/${DEFOMODE}1
		mkdir -p ${MSBASDIR}/${DEFOMODE}2
		
		cp ${PAIRSTOIGNORE1} ${MSBASDIR}/${DEFOMODE}1 2>/dev/null
		cp ${PAIRSTOIGNORE2} ${MSBASDIR}/${DEFOMODE}2 2>/dev/null

		
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
				# ${MSBASDIR}/${DEFOMODE}i/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
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
		TIMESERIESPTSDESCR=${PATH_1650}/Data_Points/Points_TS_${LABELDIR}_TST.txt

		# List of PAIRS of points for plotting double difference (i.e. without error bar) in EW and UD, ASC and Desc... 
		# 	Note: if pixels are coherent in all modes, these can be the same list
		DOUBLEDIFFPAIRSEWUD=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABELDIR}_TST.txt
		DOUBLEDIFFPAIRSASC=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABELDIR}_TST.txt
		DOUBLEDIFFPAIRSDESC=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABELDIR}_TST.txt
		
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	CRONJOB2=MUSTANG_S1_Step2_MassProc_shortest.sh
	CRONJOB2D=MUSTANG_S1_Step3_MSBAS_shortest_2D.sh
	
	# All components
	ALLCOMP=UD_EW_NS


	# LINESTOSKIP=100 # Specific to Bukavu: because Lake Kivu occupies a large part of the 
		# image to the North, it may induce a bias in the NS gradient. Hence the first 
		# 100 lines are skipped at computing the dem gradients
	
# ^^^^^^^^^^ Hard coded lines ^^^^^^^^^^^^

# set the max number of threads to be used by MSBAS. 
####################################################
#Remember that OPENBLAS is pre-compiled for Ubuntu with max 128 threads
	# Check OS
	OS=`uname -a | cut -d " " -f 1 `

	case ${OS} in 
		"Linux") 
			NTHR=$(nproc --all)	 
			echo " // Linux computer with ${NTHR} cpu's";;
		"Darwin")
			NTHR=$(sysctl -n hw.ncpu) 	
			echo " // Mac computer with ${NTHR} cpu's";;
		*)
			echo "${MESSAGE}" 	;;
	esac			

	# get the number frm your hardware 
	if [ ${NTHR} -gt ${MAXTHREADS} ] ; then NTHR=${MAXTHREADS} ; fi

# Prepare directories
#####################
	mkdir -p ${MSBASDIR}

	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	mkdir -p ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

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
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg
 
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
	
#		rm plotTS*.gnu timeLines_*.png 
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

#			# add map tag in fig
#			convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg
#			# get location from dir with coh threshold (where it was added manually)
#			convert ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_NoCohThresh.jpg

            rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg

			mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}_NoCohThresh.txt
			mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}_NoCohThresh.txt

			if [ "${ALLCOMP}" == "UD_EW_NS" ] ; then 
				mv ${MSBASDIR}/timeLine_NS_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_NS_${COORDLABELNAME12}_NoCohThresh.txt
			fi

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
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_${MODE}.jpg

        rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg

		#mv ${MSBASDIR}/timeLine_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
		#mv ${MSBASDIR}/timeLine_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
	
#		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg

		}

	function MSBASmode()
		{
		unset MODE # e.g. Asc or Desc
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
			CHECKASC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${LAUNCHPARAMASC} | ${PATHGNU}/grep -v "kate"  | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
			CHECKDESC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${LAUNCHPARAMDESC} | ${PATHGNU}/grep -v "kate"  | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
			# For unknown reason it counts 1 even when no process is running
			if [ ${CHECKASC} -ne 0 ] || [ ${CHECKDESC} -ne 0 ] ; then REASON="  SuperMaster_MassProc.sh in progress (probably manual)" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi  	
	fi 

	# Check that no other cron job step 2 (SuperMaster_MassProc.sh) is running
	CHECKMP=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l`
	if [ ${CHECKMP} -ne 0 ] ; then REASON=" SuperMaster_MassProc.sh in progress (from ${CRONJOB2})" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi 

	# Check that no other cron job step 3 2D (SuperMaster_MassProc.sh) is running
	CHECKMP=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2D} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l`
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
	cd ${S1ASC}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${S1DESC}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	wait
	
# Get date (in sec) of last available processed pairs in each MODE
##################################################################
	# get the name of last available processed pair in each MODE
    # ls crashes when too many files 
	#LASTASC=`ls -lt ${S1ASC}/Geocoded/${DEFOMODE} | ${PATHGNU}/grep -v ".txt" | head -n 2 | tail -n 1 | sed 's/.* //'` # may be messing up if txt files are created for any other purpose in the dir... 
	#LASTDESC=`ls -lt ${S1DESC}/Geocoded/${DEFOMODE} | ${PATHGNU}/grep -v ".txt" | head -n 2 | tail -n 1 | sed 's/.* //'`
	LASTASC=`find ${S1ASC}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTDESC=`find ${S1DESC}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	
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
					if [ "${FORCEMSBAS}" == "Yes" ]
						then 
							echo "No new pairs to process but you asked to force new MSBAS inversion; see param FORCEMSBAS"
						
						else 
							echo "MSBAS finished on ${TODAY} without new pairs to process"  >>  ${MSBASDIR}/_last_MSBAS_process.txt
							echo "MSBAS finished on ${TODAY} without new pairs to process"
							#mv -f  ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp  ${MSBASDIR}/${TIMESERIESPTSDESCR}
							exit
					fi
			fi
		else  
			echo "No ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence first run"
			FIRSTRUN=YES
	fi

# Remove possible broken links in MSBAS/.../MODEi and clean corresponding files 
################################################################################
# (clean if required MODEi.txt and Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt if any)
	if [ "${FIRSTRUN}" == "NO" ] ; then 
		echo "Remove Broken Links and Clean txt file in existing ${MSBASDIR}/${DEFOMODE}"
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}1 &
 		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}2 &
		wait
		echo "Possible broken links in former existing MODEi dir are cleaned"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)	
		if [ ${IFCOH} == "YES" ] ; then 
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}1_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}2_Full &
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

		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1.txt 
 		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2.txt 
	
		rm -f ${DEFOMODE}1_all4col.txt ${DEFOMODE}2_all4col.txt 2>/dev/null
		echo "All lines in former existing MODEi.txt have 4 columns"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			mv ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt
			mv ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt 
			rm -f ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt
			echo "All lines in former existing MODEi_Full.txt have 4 columns"
			echo ""
		fi
	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
		cd ${MSBASDIR}
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1 ${PATHMASSPROCESS} &
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2 ${PATHMASSPROCESS} &
		wait
		echo "All lines in former existing MODEi.txt are ok"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1_Full ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2_Full ${PATHMASSPROCESS} &
			wait
			echo "All lines in former existing MODEi_Full.txt are ok"
			echo ""	
		fi
	
	fi

# Prepare MSBAS
###############
#	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_criteria.sh ${DEFOMODE} 2 ${BP} ${BT} ${S1ASC} ${S1DESC}
	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh ${DEFOMODE} 2 ${TABLESET1} ${TABLESET2} ${S1ASC} ${S1DESC} 

	# if 3D, add NS component for msbas inversion 
	Add_NS_comp_msbas.sh "${FG}" Force ${LINESTOSKIP}		# Force forces to recompute the filtering just in case one would have change FG value. It should be fast anyway. 

	# update here the R_FLAG if needed
	#${PATHGNU}/gsed -i "s/R_FLAG = 2, 0.02/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt
	${PATHGNU}/gsed -i "s/^R_FLAG.*/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt

	# If interferos are detreneded, i.e. averaged to zero, there is no need to calibrate again 
	#${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 0/' ${MSBASDIR}/header.txt
	# Not the case here, hence chose calibration pixel(s)
	#${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 1, 45, 197, 5, 5/' ${MSBASDIR}/header.txt
	# For 3D, one must calibrate with DEM, that is option 10, which is already performed by Add_NS_comp_msbas.sh 

	# Crop the region to invert
	${PATHGNU}/gsed -i 's/WINDOW_SIZE = 0, 1534, 0, 2144/WINDOW_SIZE = 950, 1250, 1000, 1350/' ${MSBASDIR}/header.txt

	# Check again that files are OK
		# ensure that format is ok, that is with 4 columns 
		mv ${DEFOMODE}1.txt ${DEFOMODE}1_all4col.txt
 		mv ${DEFOMODE}2.txt ${DEFOMODE}2_all4col.txt

		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1.txt 
 		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2.txt 

		# keep track of prblms
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1_MissingCol.txt 
 		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2_MissingCol.txt 

		rm -f ${DEFOMODE}1_all4col.txt ${DEFOMODE}2_all4col.txt 
		
		# Need again to check for duplicated lines with different Bp in Col 2 resulting from orbit update 
		if [ ${IFCOH} == "YES" ] ; then 
			echo "Remove lines in newly created MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1 ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2 ${PATHMASSPROCESS} &
			wait
			echo "All lines in new MODEi.txt should be ok"
			echo ""	
		fi


# Let's go
##########
	cd ${MSBASDIR}
	cp -f header.txt header_back.txt 

	# EW-UD without coh threshold restriction 
	#----------------------------------------
 		if [ ${IFCOH} == "YES" ] 
 		then 
 			# This is the run without coh restriction from dual run where a coh restriction will be requested after
 			# Prepare stuff from possible former run with coh restriction
 			#------------------------------------------------------------
 			case ${FIRSTRUN} in 
 				"YES") 
 					# one have only the newly created MODEi dir and MODEi.txt
 					cp -R ${MSBASDIR}/${DEFOMODE}1 ${MSBASDIR}/${DEFOMODE}1_Full
 					cp -f ${MSBASDIR}/${DEFOMODE}1.txt ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt
 					cp -f ${MSBASDIR}/${DEFOMODE}1.txt ${MSBASDIR}/${DEFOMODE}1_Full.txt
 				
 					cp -R ${MSBASDIR}/${DEFOMODE}2 ${MSBASDIR}/${DEFOMODE}2_Full
 					cp -f ${MSBASDIR}/${DEFOMODE}2.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt
 					cp -f ${MSBASDIR}/${DEFOMODE}2.txt ${MSBASDIR}/${DEFOMODE}2_Full.txt
 					;;
 				"NO")
 					# one must merge the newly created MODEi dir and MODEi.txt with former _Full ones
 					sort ${MSBASDIR}/${DEFOMODE}1.txt | uniq > ${MSBASDIR}/${DEFOMODE}1_tmp.txt
 					sort ${MSBASDIR}/${DEFOMODE}2.txt | uniq > ${MSBASDIR}/${DEFOMODE}2_tmp.txt
 				
 					sort ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt | uniq > ${MSBASDIR}/${DEFOMODE}1_Full_tmp.txt
 					sort ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt | uniq > ${MSBASDIR}/${DEFOMODE}2_Full_tmp.txt
 				
 					cat ${MSBASDIR}/${DEFOMODE}1_tmp.txt ${MSBASDIR}/${DEFOMODE}1_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/${DEFOMODE}1_Full.txt
 					cat ${MSBASDIR}/${DEFOMODE}2_tmp.txt ${MSBASDIR}/${DEFOMODE}2_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/${DEFOMODE}2_Full.txt
 				
 					cp -R -n ${MSBASDIR}/${DEFOMODE}1 ${MSBASDIR}/${DEFOMODE}1_Full
 					cp -R -n ${MSBASDIR}/${DEFOMODE}2 ${MSBASDIR}/${DEFOMODE}2_Full
 					cp -f ${MSBASDIR}/${DEFOMODE}1_Full.txt ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt
 					cp -f ${MSBASDIR}/${DEFOMODE}2_Full.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt
 				
 					rm -f ${MSBASDIR}/${DEFOMODE}1_tmp.txt ${MSBASDIR}/${DEFOMODE}1_Full_tmp.txt 
 					rm -f ${MSBASDIR}/${DEFOMODE}2_tmp.txt ${MSBASDIR}/${DEFOMODE}2_Full_tmp.txt
 					;;	
 			esac
 			# trick the header file						
 			${PATHGNU}/gsed -i 's/${DEFOMODE}1.txt/${DEFOMODE}1_Full.txt/' ${MSBASDIR}/header.txt
 			${PATHGNU}/gsed -i 's/${DEFOMODE}2.txt/${DEFOMODE}2_Full.txt/' ${MSBASDIR}/header.txt
 		 
 		 	NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${TIMESERIESPTS}
 		
 			# Make baseline plot 
 	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt
 	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt
 
 			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
 	 		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
 	
 			while read -r DESCR X Y RX RY
 	 		do	
 	 				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR} (may not be computed when 3D)"
 	 				mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt 2>/dev/null
 	 				mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf 2>/dev/null
 	 		done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
 			# Why not some double difference plotting
 			while read -r X1 Y1 X2 Y2 DESCR
 				do	
 					PlotAllNoCoh ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
 			done < ${DOUBLEDIFFPAIRSEWUD}
 
 	  		# move all plots in same dir 
 			rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/*.jpg
 	  		mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
 	  
 	  		# move all time series in dir 
 	 		mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series/
 
 		 else
 			# i.e. without any coh threshold restriction
 			# -------------------------------------------
 			NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
 
 			# Make baseline plot 
 			PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${DEFOMODE}1.txt
 			PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${DEFOMODE}2.txt
 
 			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
 			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
 
 			while read -r DESCR X Y RX RY
 				do	
 					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR} (may not be computed when 3D)"
 					mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt 2>/dev/null
 					mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf 2>/dev/null
 			done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
 			# Why not some double difference plotting
 			while read -r X1 Y1 X2 Y2 DESCR
 				do	
 					PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
 			done < ${DOUBLEDIFFPAIRSEWUD}	
 
 			# move all plots in same dir 
 			rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/*.jpg
 			mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
 
 			# move all time series in dir 
 			mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
 			
			# Vector Plot of EW-NS components
			
			WHEREDEM=$(find ${MSBASDIR}/DEM/ -maxdepth 1 -type f -name "externalSlantRangeDEM.UTM.*.bil")
			NSDISPL="${MSBASDIR}/zz_NS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LINEAR_RATE_NS.bin"
			EWDISPL="${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LINEAR_RATE_EW.bin"
			
			# Create vector plot without crop if clipped in header.txt
			Plot_vectorDispl_DEM.py ${WHEREDEM} ${NSDISPL} ${EWDISPL} --scalevalue 0.5 --dwsple 15 --x_min 955 --x_max 1249 --y_min 1005 --y_max 1349
			Plot_vectorDispl_DEM.py ${WHEREDEM} ${NSDISPL} ${EWDISPL} --scalevalue 0.5 --dwsple 15 --x_min 955 --x_max 1249 --y_min 1005 --y_max 1349 --contour
			
			# where options are number of lines and col to crop from original image 
			# as follow: --x_min 50 --x_max 115 --y_min 100 --y_max 240 means keep from 50 to 115 col and from 100 to 240 lines)
						
			# Full vector plt
			Plot_vectorDispl_DEM.py ${WHEREDEM} ${NSDISPL} ${EWDISPL} --scalevalue 0.5 --dwsple 15
			Plot_vectorDispl_DEM.py ${WHEREDEM} ${NSDISPL} ${EWDISPL} --scalevalue 0.5 --dwsple 15 --contour
						
			mkdir -p ${MSBASDIR}/zz_VectorPlot
			mv -f EW_NS_Vector_Displ*.jpg ${MSBASDIR}/zz_VectorPlot/
 			
 		fi 
 
 	# EW-UD with coh threshold restriction 
 	#--------------------------------------
 		if [ ${IFCOH} == "YES" ] ; then
 			cd ${MSBASDIR}
 			cp -f header_back.txt header.txt
 
 			# run restrict_msbas_to_Coh.sh         
 			restrict_msbas_to_Coh.sh ${DEFOMODE}1 ${COHRESTRICT} ${KMLCOH} ${SAOCOMASC}/Geocoded/Coh
 			restrict_msbas_to_Coh.sh ${DEFOMODE}2 ${COHRESTRICT} ${KMLCOH} ${SAOCOMDESC}/Geocoded/Coh
 		
 			# Force pair exclusion 
 			if [ ${EXCLUDE1} == "YES" ] ; then 
 				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/${DEFOMODE}1
 			fi 
 			if [ ${EXCLUDE2} == "YES" ] ; then 
 				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/${DEFOMODE}2
 			fi 
 			
 			cd ${MSBASDIR}
 			NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
 
 			# Make baseline plot 
 			PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${DEFOMODE}1.txt
 			PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${DEFOMODE}2.txt
 		
 			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
 			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
 
 			while read -r DESCR X Y RX RY
 				do	
 					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
 					mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
 					mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
 			done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
 			# Why not some double difference plotting
 			while read -r X1 Y1 X2 Y2 DESCR
 				do	
 					PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
 			done < ${DOUBLEDIFFPAIRSEWUD}	
 						
 			# move all plots in same dir 
 			rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/*.jpg
 			mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
 
 			# move all time series in dir 
 			mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
 		fi

 	# Recompute Asc and Desc even if it exist from 2D inversion because order and lambda may differ
  	#----------------------------------------------------------------------------------------------
		# Prepare header files
		#   backup header
		cp -f ${MSBASDIR}/header.txt ${MSBASDIR}/header_${ALLCOMP}.txt 

		# remove line with NS in ${MSBASDIR}/header.txt
		cat ${MSBASDIR}/header.txt | grep -v "DD_NSEW_FILES" >  ${MSBASDIR}/header_2Modes.txt
 

		#   search for line nr of each SET mode definition
 		LINENRASC=$(cat ${MSBASDIR}/header_2Modes.txt | ${PATHGNU}/grep -n "SET =" | head -1 | cut -d: -f1)
 		LINENRDESC=$(cat ${MSBASDIR}/header_2Modes.txt | ${PATHGNU}/grep -n "SET =" | tail -1 | cut -d: -f1)

 		#   Change "SET = " with "#SET = " in each line of header
		cat ${MSBASDIR}/header_2Modes.txt | ${PATHGNU}/gsed "s/SET = /#SET = /g" > ${MSBASDIR}/header_none.txt
		#   Change "#SET = " with "SET = " for only the mode one wants to keep 

		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENRASC}' s/#SET = /SET = /' > ${MSBASDIR}/header_Asc.txt
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENRDESC}' s/#SET = /SET = /' > ${MSBASDIR}/header_Desc.txt

		rm -f ${MSBASDIR}/header_none.txt 2> /dev/null

 		# ASC
				FILEPAIRS=${DOUBLEDIFFPAIRSASC}
				MSBASmode Asc

 		# DESC
				FILEPAIRS=${DOUBLEDIFFPAIRSDESC}
				MSBASmode Desc
 

 		# Back to normal for next run and get out
 				cp -f ${MSBASDIR}/header_${ALLCOMP}.txt ${MSBASDIR}/header.txt 		 				

				TODAY=`date`
				echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt

				echo "${LASTASCTIME}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LASTDESCTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt

# All done...

