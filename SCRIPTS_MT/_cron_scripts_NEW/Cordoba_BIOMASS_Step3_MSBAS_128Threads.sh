#!/bin/bash
# Script intends to run in a cronjob an automatic systematic (re)processing of msbas time 
# series when new images were made available.
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
# NOTE: - HIGHLY SIPLIFIED VERSION FOR TEST BIOMASS 1 COMP
#		
#
# Parameters: - none 
#
# Hardcoded: - a lot... se below paragraph named HARD CODED but also adapt below depending on the number of modes 
#
# Dependencies:	- awk 
#				- several scripts from SCRIPTS_MT
#

# New in Distro V 1.0 20260826:	- set up
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 26, 2026"

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

		# Max baselines (used for all the mode in present case but you can change)

		MODE01A="Asc21"


		# max perpendicular baseline - Not used becasue use table (Delaunay or shortests) instead
		
		LABEL=Cordoba		# Label for file naming (used for naming zz_ dirs with results and figs etc)

		# Global Primaries (SuperMasters)
		SMASC1=20251201


		#R_FLAG
		# Order
		ORDER=2
		# Lambda
		LAMBDA=0.04
		
		# Mode
		DEFOMODE=DefoInterpolx2Detrend
		#DEFOMODE=DefoInterpol
	
		
	# some files and PATH for each mode
	###################################
		# Path to SAR_MASSPROCESS
		PATHMASSPROCESS=${PATH_1660}/SAR_MASSPROCESS

		# Path to Seti
		PATHSETI=$PATH_1650/SAR_SM/MSBAS

		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
		BIOASC1=${PATHMASSPROCESS}/BIOMASS/Cordoba_${MODE01A}/SMNoCrop_SM_${SMASC1}_Zoom1_ML2
		
			
		# Path to dir where list of compatible pairs files are computed (need one for each mode)
		SET1=${PATHSETI}/Cordoba/set1

		TABLESET1=${SET1}/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt


		# Path to LaunchParameters.txt files for each mode (need one for each mode)
		LAUNCHPARAMPATH=${PATH_1650}/Param_files/BIOMASS/Cordoba

		LAUNCHPARAMASC1=${LAUNCHPARAMPATH}/LaunchMTparam_BIOMASS_Full_Zoom1_ML2_test.txt

	# Events tables
	###############
		#EVENTS=${PATH_1650}/EVENTS_TABLES/${LABEL}

	# Path to dir where MSBAS will be computed
	###########################################
		#MSBASDIR=${PATH_3602}/MSBAS/_${LABEL}_NISAR_Auto_${BP}m_${BT}days
		MSBASDIRCRITERIA=Max3Shortests
		MSBASDIR=${PATH_3610}/MSBAS/_${LABEL}_BIOMASS_Auto_${MSBASDIRCRITERIA}


	# Date Restriction
	##################

	
	# Coherence restriction
	########################		
		IFCOH="NO"		# YES or NO

	# Path to list of points for plotting time series
	#################################################
	
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	PATHCRONJOB=${PATH_SCRIPTS}/SCRIPTS_MT/_cron_scripts_NEW
	CRONJOB2=${PATHCRONJOB}/CordobaL_BIOMASS_Step2_MassProc.sh


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

	# Per mode
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE01A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE01A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/


	cd ${MSBASDIR}

# prepare points lists
######################
	## unused


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
	
		}

	function PlotAllCombiModes()
		{
		unset X1 Y1 X2 Y2 DESCRIPTION
		local X1=$1
		local Y1=$2
		local X2=$3
		local Y2=$4
		local DESCRIPTION=$5
	
		if [ "${EVENTS}" == "" ]
			then
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}" ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g  # remove -f if does not want the linear fit
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}" ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit			
		fi
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME1=${X1}_${Y1}_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME2=${X2}_${Y2}_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}
        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
		
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME1}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME1}.eps
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME2}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME2}.eps

		mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}.eps
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg
 
        rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg
		
		mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${OLL}/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}.txt
		mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${OLL}/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}.txt
	
		}

#	function PlotAllNoCoh()
#		{
#		unset X1 Y1 X2 Y2 DESCRIPTION
#		local X1=$1
#		local Y1=$2
#		local X2=$3
#		local Y2=$4
#		local DESCRIPTION=$5
#
#		if [ "${EVENTS}" == "" ]
#			then
#				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g   # remove -f if does not want the linear fit etc..
#			else
#				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit etc..		
#		fi
#	
##		rm plotTS*.gnu timeLines_*.png 
#		OLL=${ORDER}_${LAMBDA}_${LABEL}
#		COORDLABELNAME1=${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}
#		COORDLABELNAME2=${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}
#        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
#	
#		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] ; then 
#			mv ${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME1}_NoCohThresh.eps
#		fi
#		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" ] ; then
#			mv ${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME2}_NoCohThresh.eps
#		fi 
# 
#		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] ; then
#			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh.eps
#
##			# add map tag in fig
##			convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg
##			# get location from dir with coh threshold (where it was added manually)
##			convert ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_NoCohThresh.jpg
#
#            rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg
#			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg
#
#			mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}_NoCohThresh.txt
#			mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}_NoCohThresh.txt
#		fi
#		}

	function PlotAllLOS()
		{
		unset X1 Y1 X2 Y2 DESCRIPTION 
		local X1=$1
		local Y1=$2
		local X2=$3
		local Y2=$4
		local DESCRIPTION=$5
		local MODE=$6
	
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
		unset MODE # e.g. 6811_L_A ...
		unset FORMERLASTTIME # e.g. FORMERLAST01ATIME
		unset LASTTIME 	# e.g. LAST01ATIME
		local MODE=$1
		local FORMERLASTTIME=$2
		local LASTTIME=$3
		
		echo ""
		echo "// Processing ${MODE}"
		echo "/////////////////////"
		
		if [ ${FORMERLASTTIME} -eq ${LASTTIME} ]
			then 
				echo "No new data for mode  ${MODE}, hence skip (m)sbas for that LoS"
			else
				cd ${MSBASDIR}
				cp -f ${MSBASDIR}/header_${MODE}.txt  header.txt 
				NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS} --msbasv4
		
				cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
				# remove header line to avoid error message 
				#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
				while read -r DESCR X Y RX RY
					do	
						echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
						mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
						mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
						# there is no automatic plotting by msbas when only in LOS 
				done < <(tail -n +2 "${TIMESERIESPTSDESCR}")  # ignore header
				
 		
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
		fi
		}

# Check that there is no other Step3 running
#############################################
	CHECKCRON3=`ps -Af | ${PATHGNU}/grep "Step3" | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" | ${PATHGNU}/grep -v "Crons_1_2_3.sh"  | wc -l`
	if [ ${CHECKCRON3} -gt 0 ] ; then 
			REASON=" another Step3 is running, which may overload the computer; pause here" 
			STOPRUN="YES"
	fi


# Check that there is no other cron (Step 2 or 3) or manual SuperMaster_MassProc.sh running
###########################################################################################
	# Check that no other cron job step 3 (MSBAS) or manual SuperMaster_MassProc.sh is running
	CHECKMB=`ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | ${PATHGNU}/grep -v "Crons_1_2_3.sh"  | wc -l`
		#### For Debugging
		# echo "ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v ${PATHGNU}/grep | ${PATHGNU}/grep -v /dev/null | wc -l" > CheckRun.txt
		# echo ${CHECKMB} >> CheckRun.txt
		# ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" >> CheckRun.txt

	if [ ${CHECKMB} -gt 3 ] ; then # use ${PATHGNU}/grep -v "grep "  instead of ${PATHGNU}/grep -v "grep ${PRG}" because depending on environment, it may miss the second version
			REASON=" another ${PRG} is running" 
			STOPRUN="YES"
		else
			# Check that no other SuperMaster_MassProc.sh automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
			CHECKASC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${LAUNCHPARAMASC} | ${PATHGNU}/grep -v "kate"  | ${PATHGNU}/grep -v "/dev/null" | ${PATHGNU}/grep -v "Crons_1_2_3.sh" | wc -l` 
			# For unknown reason it counts 1 even when no process is running
			if [ ${CHECKASC} -ne 0 ] ; then REASON="  SuperMaster_MassProc.sh in progress (probably manual)" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi  	
	fi 

	# Check that no other cron job step 2 (SuperMaster_MassProc.sh) is running
	CHECKMP=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | ${PATHGNU}/grep -v "Crons_1_2_3.sh" | wc -l`
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
# reprocessing with updated orbits. If duplicated product detected, it keeps only the most recent product.  
	cd ${BIOASC1}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &

	
# Get date (in sec) of last available processed pairs in each MODE
##################################################################
	# get the name of last available processed pair in each MODE
	LASTASC1=`find ${BIOASC1}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	# get date in sec of last available processed pairs in each MODE
	LASTASCTIME1=`stat -c %Y ${LASTASC1}`

# Check if first run and if  appropriate, get time of last images in time series
################################################################################
	if [ -f "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] && [ -s "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] 
		then   
			echo "Existing ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence not the first run"
			FIRSTRUN=NO
			FORMERLASTASCTIME1=`head -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`

			FORMERLASTDESCTIME1=`head -3 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1` # tail -1 ok also but this is ready for case where more than 2 lines are present in _Last_MassProcessed_Pairs_Time.txt

			if [ ${FORMERLASTASCTIME1} -eq ${LASTASCTIME1} ] && [ ${FORMERLASTDESCTIME1} -eq ${LASTDESCTIME1} ]  # if no more recent file is available since the last cron processing
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
		echo "Remove Broken Links and Clean txt file in existing ${MSBASDIR}/${DEFOMODE}"
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}1 &

		wait
		echo "Possible broken links in former existing MODEi dir are cleaned"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)	
		if [ ${IFCOH} == "YES" ] ; then 
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}1_Full &
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
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1.txt 
		rm -f ${DEFOMODE}1_all4col.txt 
		echo "All lines in former existing MODEi.txt have 4 columns"
		echo ""

	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
		cd ${MSBASDIR}
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1 ${PATHMASSPROCESS} &
		wait
		echo "All lines in former existing MODEi.txt are ok"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1_Full ${PATHMASSPROCESS} &
			wait
			echo "All lines in former existing MODEi_Full.txt are ok"
			echo ""	
		fi
	
	fi

# Prepare MSBAS
###############
#	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_criteria.sh DefoInterpolx2Detrend 3 ${BP} ${BT} ${NISARASC} ${NISARDESC1} ${NISARDESC2}
	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh ${DEFOMODE} 1 ${TABLESET1} ${BIOASC1} 

	# update here the R_FLAG if needed
	#${PATHGNU}/gsed -i "s/R_FLAG = 2, 0.02/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt
	${PATHGNU}/gsed -i "s/^R_FLAG.*/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt

	# If interferos are detreneded, i.e. averaged to zero, there is no need to calibrate again 
	${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 0/' ${MSBASDIR}/header.txt
	# Not the case here, hence chose calibration pixel(s)
	#${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 1, 45, 197, 5, 5/' ${MSBASDIR}/header.txt


	# Check again that files are OK
		# ensure that format is ok, that is with 4 columns 
		mv ${DEFOMODE}1.txt ${DEFOMODE}1_all4col.txt
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1.txt 
		# keep track of prblms
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1_MissingCol.txt 
		rm -f ${DEFOMODE}1_all4col.txt ${DEFOMODE}2_all4col.txt
		
		# Need again to check for duplicated lines with different Bp in Col 2 resulting from orbit update 
		if [ ${IFCOH} == "YES" ] ; then 
			echo "Remove lines in newly created MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1 ${PATHMASSPROCESS} &
			wait
			echo "All lines in new MODEi.txt should be ok"
			echo ""	
		fi



# Let's go
##########
	cd ${MSBASDIR}
	cp -f header.txt header_back.txt 


	# Asc and Desc (with coh restriction if one is requested)
 	#--------------------------------------------------------

		# ASC
 			FILEPAIRS=${DOUBLEDIFFPAIRSASC1}
			MSBASmode ${MODE01A} ${FORMERLASTASCTIME1} ${LASTASCTIME1}

 
			TODAY=`date`
			echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt

			echo "${LASTASCTIME1}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt

			echo "${LASTDESCTIME1}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
		
	#mv -f ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp ${MSBASDIR}/${TIMESERIESPTSDESCR}

# All done...
