#!/bin/bash
# Script intends to run in a cronjob an automatic systematic (re)processing of 2D msbas time 
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
# NOTE: - Use modes are DefoInterpol instead of DefoInterpolx2Detrend because small crop on landsliding region
#		- MSBAS Calibration is disabled because deformation maps are detrended at processing. though may want to set it outside of one of the landslide
#		
#
# Parameters: - none 
#
# Hardcoded: - a lot... se below paragraph named HARD CODED but also adapt below depending on the number of modes 
#
# Dependencies:	- awk 
#				- several scripts from SCRIPTS_MT
#
# New in Distro V 1.0:	- based on Funu step 3
# New in Distro V 1.1:	- typos and pause after creation of header.txt for debug (by M. Jaspard and D. Smittarello)
# New in Distro V 1.2:	- crop msbas windows depending on modes combinations
# New in Distro V 1.3:  - typos in crop msbas
# New in Distro V 1.4:  - typos in crop defo mode 158 92 and get proper lambda change in header.txt
# New in Distro V 1.5 20250424:	- restrict usage of CPU to 128 threads because that is the max possible with OPENBLAS pre-compiled for Ubuntu
# New in Distro V 1.7 20251118: - Corr based on Version without max 128 threads, i.e. 
#									- Debug dir naming for TS combination of modes 
# 						  			- Remove 3 modes combinations covering only a small triangle to the NW and already covered by 4 other combinations  
# 						  			- debug path to TS dirs
#									- Allows List of points per LOS and per combination  
#									- Replace "< ${} | tail -n +2" with "< <(tail -n +2 "${}}")" for more stability
# New in Distro V 1.8.0 20251125 :	- always limited to 128 threads (see MAXTHREADS) to prevent problems with openblas, which is compiled by default for 128 threads 

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.8 AMSTer script utilities"
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

		# Max baselines (used for all the mode in present case but you can change)

		MODE01A="A_85"
		MODE02A="A_158"

		MODE01D="D_19"
		MODE02D="D_92"
		MODE03D="D_121"

		# Combinations of modes with sufficient overlap
		COMBI01="${MODE02A}_${MODE01D}"				#A_158_D_19
		COMBI02="${MODE02A}_${MODE02D}"				#A_158_D_92
		COMBI03="${MODE01A}_${MODE02A}_${MODE01D}"	#A_85_A_158_D_19
		COMBI04="${MODE01A}_${MODE01D}"				#A_85_D_19
		COMBI05="${MODE01A}_${MODE03D}"				#A_85_D_121
		COMBI06="${MODE01A}_${MODE01D}_${MODE03D}"	#A_85_D_19_D_121


		# max perpendicular baseline - Not used becasue use table (Delaunay or shortests) instead
		# max temporal baseline - Not used becasue use table (Delaunay or shortests) instead
# 		SET1BP1=30
# 		SET1BP2=70
# 		SET1BT1=400
# 		SET1BT2=400
# 		DATECHG1=20220501
# 
# 		SET2BP1=30
# 		SET2BP2=70
# 		SET2BT1=400
# 		SET2BT2=400
# 		DATECHG2=20220501
# 
# 		SET3BP1=30
# 		SET3BP2=70
# 		SET3BT1=400
# 		SET3BT2=400
# 		DATECHG3=20220501
# 
# 		# To take into account the whole set of data with both sets 
# 		# of baseline criteria, one must take here the largest of each Bp and Bt 
# 		# See warning below
# 		BP=$(echo "$SET1BP1 $SET1BP2 $SET2BP1 $SET2BP2" | awk '{BP=$1; for(i=2;i<=NF;i++) if($i>BP) BP=$i; print BP}')	# max perpendicular baseline 
# 		BT=$(echo "$SET1BT1 $SET1BT2 $SET2BT1 $SET2BT2" | awk '{BT=$1; for(i=2;i<=NF;i++) if($i>BT) BT=$i; print BT}')	# max temporal baseline
		
		LABEL=NEPAL		# Label for file naming (used for naming zz_ dirs with results and figs etc)


		# Global Primaries (SuperMasters)
		SMASC1=20240328
		SMASC2=20180410

		SMDESC1=20180928
		SMDESC2=20220714
		SMDESC3=20170904

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
		PATHMASSPROCESS=${PATH_3611}/SAR_MASSPROCESS

		# Path to Seti
		PATHSETI=$PATH_1660/SAR_SM/MSBAS

		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
		S1ASC1=${PATHMASSPROCESS}/S1/Nepal_${MODE01A}/SMNoCrop_SM_${SMASC1}_Zoom1_ML2
		S1ASC2=${PATHMASSPROCESS}/S1/Nepal_${MODE02A}/SMNoCrop_SM_${SMASC2}_Zoom1_ML2
		
		S1DESC1=${PATHMASSPROCESS}/S1/Nepal_${MODE01D}/SMNoCrop_SM_${SMDESC1}_Zoom1_ML2
		S1DESC2=${PATHMASSPROCESS}/S1/Nepal_${MODE02D}/SMNoCrop_SM_${SMDESC2}_Zoom1_ML2
		S1DESC3=${PATHMASSPROCESS}/S1/Nepal_${MODE03D}/SMNoCrop_SM_${SMDESC3}_Zoom1_ML2
		
		# Path to dir where list of compatible pairs files are computed (need one for each mode)
		SET1=${PATHSETI}/NEPAL/set1
		SET2=${PATHSETI}/NEPAL/set2
		SET3=${PATHSETI}/NEPAL/set3
		SET4=${PATHSETI}/NEPAL/set4
		SET5=${PATHSETI}/NEPAL/set5

		TABLESET1=${SET1}/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt
		TABLESET2=${SET2}/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt
		TABLESET3=${SET3}/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt
		TABLESET4=${SET4}/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt
		TABLESET5=${SET5}/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt


		# Path to LaunchParameters.txt files for each mode (need one for each mode)
		LAUNCHPARAMPATH=${PATH_1650}/Param_files/S1/

		LAUNCHPARAMASC1=${LAUNCHPARAMPATH}/Nepal_A_85/LaunchMTparam_S1_Nepal_A_85_Zoom1_ML2_MassProc_0keep_MassProc.txt
		LAUNCHPARAMASC2=${LAUNCHPARAMPATH}/Nepal_A_158/LaunchMTparam_S1_Nepal_A_158_Zoom1_ML2_MassProc_0keep_MassProc.txt
		LAUNCHPARAMDESC1=${LAUNCHPARAMPATH}/Nepal_D_19/LaunchMTparam_S1_Nepal_D_19_Zoom1_ML2_MassProc_0keep_MassProc.txt
		LAUNCHPARAMDESC2=${LAUNCHPARAMPATH}/Nepal_D_92/LaunchMTparam_S1_Nepal_D_92_Zoom1_ML2_MassProc_0keep_MassProc.txt
		LAUNCHPARAMDESC3=${LAUNCHPARAMPATH}/Nepal_D_121/LaunchMTparam_S1_Nepal_D_121_Zoom1_ML2_MassProc_0keep_MassProc.txt

	# Events tables
	###############
		EVENTS=${PATH_1650}/EVENTS_TABLES/${LABEL}

	# Path to dir where MSBAS will be computed
	###########################################
		#MSBASDIR=${PATH_3602}/MSBAS/_${LABEL}_S1_Auto_${BP}m_${BT}days
		MSBASDIRCRITERIA=Max3Shortests
		MSBASDIR=${PATH_3610}/MSBAS/_${LABEL}_S1_Auto_${MSBASDIRCRITERIA}


	# Date Restriction
	##################

	DATERESTRIC1="NO"	# If YES, will remove dates from Mode 1 based on parma here after
	DATERESTRIC2="NO"	# If YES, will remove dates from Mode 2 based on parma here after
	DATERESTRIC3="NO"	# If YES, will remove dates from Mode 2 based on parma here after
	DATERESTRIC4="NO"	# If YES, will remove dates from Mode 2 based on parma here after
	DATERESTRIC5="NO"	# If YES, will remove dates from Mode 2 based on parma here after

		REMOVEBEFORE1="20181231"	# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEAFTER1="NONE"			# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEBEFORE2="20181231"	# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEAFTER2="NONE"			# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEBEFORE3="20181231"	# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEAFTER3="NONE"			# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
	
		REMOVEBETWEEN1="NO"	# If YES, it will remove all and only pairs with one of the dates between dates REMOVEBEFORE and REMOVEAFTER, providing that these two dates are not empty
		REMOVEBETWEEN2="NO"	# If YES, it will remove all and only pairs with one of the dates between dates REMOVEBEFORE and REMOVEAFTER, providing that these two dates are not empty
		REMOVEBETWEEN3="NO"	# If YES, it will remove all and only pairs with one of the dates between dates REMOVEBEFORE and REMOVEAFTER, providing that these two dates are not empty

	
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
		# unused
		TIMESERIESPTSDESCR=${PATH_1650}/Data_Points/Points_TS_${LABEL}.txt

		TIMESERIESPTSDESCRASC1=${PATH_1650}/Data_Points/Points_TS_${LABEL}_A_85.txt
		TIMESERIESPTSDESCRASC2=${PATH_1650}/Data_Points/Points_TS_${LABEL}_A_158.txt
		
		TIMESERIESPTSDESCRDESC1=${PATH_1650}/Data_Points/Points_TS_${LABEL}_D_19.txt
		TIMESERIESPTSDESCRDESC2=${PATH_1650}/Data_Points/Points_TS_${LABEL}_D_92.txt
		TIMESERIESPTSDESCRDESC3=${PATH_1650}/Data_Points/Points_TS_${LABEL}_D_121.txt

		TIMESERIESPTSDESCRCOMBI1=${PATH_1650}/Data_Points/Points_TS_${LABEL}_${COMBI01}.txt	# A_158_D_19
		TIMESERIESPTSDESCRCOMBI2=${PATH_1650}/Data_Points/Points_TS_${LABEL}_${COMBI02}.txt	# A_158_D_92
		TIMESERIESPTSDESCRCOMBI3=${PATH_1650}/Data_Points/Points_TS_${LABEL}_${COMBI03}.txt	# A_85_A_158_D_19
		TIMESERIESPTSDESCRCOMBI4=${PATH_1650}/Data_Points/Points_TS_${LABEL}_${COMBI04}.txt	# A_85_D_19
		TIMESERIESPTSDESCRCOMBI5=${PATH_1650}/Data_Points/Points_TS_${LABEL}_${COMBI05}.txt	# A_85_D_121
		TIMESERIESPTSDESCRCOMBI6=${PATH_1650}/Data_Points/Points_TS_${LABEL}_${COMBI06}.txt	# A_85_D_121

		# List of PAIRS of points for plotting double difference (i.e. without error bar) in EW and UD, ASC and Desc... 
		# 	Note: if pixels are coherent in all modes, these can be the same list
		# unused
		DOUBLEDIFFPAIRSEWUD=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
		
		DOUBLEDIFFPAIRSASC1=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_A_85.txt
		DOUBLEDIFFPAIRSASC2=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_A_158.txt
		
		DOUBLEDIFFPAIRSDESC1=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_D_19.txt
		DOUBLEDIFFPAIRSDESC2=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_D_92.txt
		DOUBLEDIFFPAIRSDESC3=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_D_121.txt

		DOUBLEDIFFPAIRSCOMBI1=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_${COMBI01}.txt	# A_158_D_19
		DOUBLEDIFFPAIRSCOMBI2=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_${COMBI02}.txt	# A_158_D_92
		DOUBLEDIFFPAIRSCOMBI3=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_${COMBI03}.txt	# A_85_A_158_D_19
		DOUBLEDIFFPAIRSCOMBI4=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_${COMBI04}.txt	# A_85_D_19
		DOUBLEDIFFPAIRSCOMBI5=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_${COMBI05}.txt	# A_85_D_121
		DOUBLEDIFFPAIRSCOMBI6=${PATH_1650}/Data_Points/List_DoubleDiff_${LABEL}_${COMBI06}.txt	# A_85_D_19_D_121
		
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	PATHCRONJOB=${PATH_SCRIPTS}/SCRIPTS_MT/_cron_scripts_NEW
	CRONJOB2=${PATHCRONJOB}/NEPAL_S1_Step2_MassProc.sh

	# All components
	ALLCOMP=UD_EW

	# Crop for msbas inversions - Full = 8807, 5376
	###############################################
	
		# A85
		CROP_A85="1070, 8806, 0, 5375"
		
		# A158
		CROP_A158="0, 3650, 0, 5375"
		
		# D19
		CROP_D19="0, 8080, 0, 5375"
		
		# D92
		CROP_D92="0, 1670, 0, 3577"
		
		# D121
		CROP_D121="5940, 8806, 1670, 5375"

		# specific to NEPAL: 9 combinations:
		####################################
		# COMBI 1: A158_D19 i.e. 2A 1D 
		CROP_A158_D19="0, 3676, 0, 4520"

		# COMBI 2: A158_D92 		i.e. 2A 2D
		CROP_A158_D92="0, 1650, 0, 3600"

		# COMBI 3: A85_A158_D19 	i.e. 1A 2A 1D
		CROP_A85_A158_D19="1050, 3676, 0, 4532"

		# COMBI 4: A85_D19 		i.e. 1A 1D
		CROP_A85_D19="1077, 8104, 0, 5252"

		# COMBI 5: A85_D121		i.e. 1A 3D
		CROP_A85_D121="5930, 8806, 1630, 5200"

		# COMBI 6: A85_D19_D121	i.e. 1A 1D 3D
		CROP_A85_D19_D121="5936, 7980, 1644, 5075"

		## Unused CROP because too small overlap
		########################################
		# A85_A158_D92 	i.e. 1A 2A 2D
		CROP_A85_A158_D92="1050, 1600, 0, 1213"

		# A85_D92		i.e. 1A 2D
		CROP_A85_D92="1090, 1630, 0, 1140"

		# A85_D19_D92	i.e. 1A 1D 2D
		CROP_A85_D19_D92="1040, 1660, 0, 1200"



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

	# specific to NEPAL: 9 combinations of EW_UD:
	#############################################
		# A158_D19 i.e. 2A 1D 
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE02A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE02A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE02A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	
		# A158_D92 		i.e. 2A 2D
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE02A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE02A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE02A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

		# A85_A158_D19 	i.e. 1A 2A 1D
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

		# A85_D19 		i.e. 1A 1D
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

		# A85_D121		i.e. 1A 3D
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

		# A85_D19_D121	i.e. 1A 1D 3D
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

		## Unused CROP because too small overlap
		########################################
		## A85_A158_D92 	i.e. 1A 2A 2D
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
#
		## A85_D92		i.e. 1A 2D
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
#
		## A85_D19_D92	i.e. 1A 1D 2D
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
		#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODE01A}_${MODE01D}_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	# All Comp
	#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}
	#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	#mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	# Per mode
	mkdir -p ${MSBASDIR}/zz_LOS_TS_A_85_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_A_85_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	mkdir -p ${MSBASDIR}/zz_LOS_TS_A_158_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_A_158_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	mkdir -p ${MSBASDIR}/zz_LOS_TS_D_19_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_D_19_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	mkdir -p ${MSBASDIR}/zz_LOS_TS_D_92_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_D_92_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	mkdir -p ${MSBASDIR}/zz_LOS_TS_D_121_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_D_121_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	## All Asc and Desc
	#mkdir -p ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	#mkdir -p ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
#
	#mkdir -p ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}
	#mkdir -p ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/


	## in Coh threshold restriction
	#if [ ${IFCOH} == "YES" ] ; then 
	#	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
	#	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
	#	mkdir -p ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series
	#fi
	
	cd ${MSBASDIR}

# prepare points lists
######################
	## unused
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCR}")
		cp -f ${TIMESERIESPTSDESCR}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCR=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCR}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTS=${MSBASDIR}/Cln_${TIMESERIESPTNAME}

	# Asc
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRASC1}")
		cp -f ${TIMESERIESPTSDESCRASC1}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRASC1=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRASC1}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSASC1=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRASC2}")
		cp -f ${TIMESERIESPTSDESCRASC2}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRASC2=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRASC2}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSASC2=${MSBASDIR}/Cln_${TIMESERIESPTNAME}

	# Desc
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRDESC1}")
		cp -f ${TIMESERIESPTSDESCRDESC1}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRDESC1=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRDESC1}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSDESC1=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRDESC2}")
		cp -f ${TIMESERIESPTSDESCRDESC2}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRDESC2=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRDESC2}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSDESC2=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRDESC3}")
		cp -f ${TIMESERIESPTSDESCRDESC3}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRDESC3=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRDESC3}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSDESC3=${MSBASDIR}/Cln_${TIMESERIESPTNAME}

	# Combis
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRCOMBI1}")
		cp -f ${TIMESERIESPTSDESCRCOMBI1}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRCOMBI1=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRCOMBI1}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSCOMBI1=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRCOMBI2}")
		cp -f ${TIMESERIESPTSDESCRCOMBI2}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRCOMBI2=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRCOMBI2}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSCOMBI2=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRCOMBI3}")
		cp -f ${TIMESERIESPTSDESCRCOMBI3}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRCOMBI3=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRCOMBI3}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSCOMBI3=${MSBASDIR}/Cln_${TIMESERIESPTNAME}

		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRCOMBI4}")
		cp -f ${TIMESERIESPTSDESCRCOMBI4}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRCOMBI4=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRCOMBI4}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSCOMBI4=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRCOMBI5}")
		cp -f ${TIMESERIESPTSDESCRCOMBI5}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRCOMBI5=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRCOMBI5}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSCOMBI5=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
		TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCRCOMBI6}")
		cp -f ${TIMESERIESPTSDESCRCOMBI6}  ${MSBASDIR}/${TIMESERIESPTNAME}
		TIMESERIESPTSDESCRCOMBI6=${MSBASDIR}/${TIMESERIESPTNAME}
		# Remove header and naming in 1st col from Pts list
		${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCRCOMBI6}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
		TIMESERIESPTSCOMBI6=${MSBASDIR}/Cln_${TIMESERIESPTNAME}

# functions
###########

#function RemoveDates()
#		{
#		unset MODENR 		#  Mode Nr
#		unset REMOVEBETWEEN	#  Remove or not between dates 
#		unset REMOVEBEFORE	#  Remove or not before date
#		unset REMOVEAFTER	#  Remove or not after date
#
#		MODENR=$1
#		REMOVEBETWEEN=$2
#		REMOVEBEFORE=$3
#		REMOVEAFTER=$4
#		echo ""
#		if [ "${REMOVEBETWEEN}" == "YES" ]  ; 
#			then
#				if [ "${REMOVEBEFORE}" == "NONE" ] || [ "${REMOVEAFTER}" == "NONE" ] 
#					then
#						echo "  // You requested to remove all pairs from mode ${MODENR} with an image between provided dates but at least one date is missing. Check parameters REMOVEBEFORE and REMOVEAFTER in the present cron script. "
#						exit
#					else 	
#						if [ "${REMOVEAFTER}" -lt "${REMOVEBEFORE}" ]
#							then
#								MINDATE=${REMOVEAFTER}
#								MAXDATE=${REMOVEBEFORE}
#							else
#								MINDATE=${REMOVEBEFORE}
#								MAXDATE=${REMOVEAFTER}
#						fi
#						echo "  // Shall remove all pairs with an image between ${MINDATE} and ${MAXDATE} (included) in mode ${MODENR}."
#				fi
#
#				# Remove between dates
#				cp -f ${MSBASDIR}/${DEFOMODE}${MODENR}.txt ${MSBASDIR}/${DEFOMODE}${MODENR}_WITHdatesBetween${MINDATE}and${MAXDATE}.txt
#				# Remove pairs with images before MAXDATE	
#				RemovePairsFromModeList_WithImagesBefore.sh ${MSBASDIR}/${DEFOMODE}${MODENR}.txt ${MAXDATE} 
#				# Creates a file named e.g. ${MSBASDIR}/DefoInterpolx2Detrend1After_${MAXDATE}_${MM}_${DD}_${YYYY}.txt
#				# Remove pairs with images after MINDATE
#				RemovePairsFromModeList_WithImagesAfter.sh ${MSBASDIR}/${DEFOMODE}${MODENR}.txt ${MINDATE} 
#				# Creates a file named e.g. ${MSBASDIR}/DefoInterpolx2Detrend1Below_${MINDATE}_${MM}_${DD}_${YYYY}.txt
#				cat ${MSBASDIR}/${DEFOMODE}${MODENR}.txt_Below${MINDATE}_${MM}_${DD}_${YYYY}.txt ${MSBASDIR}/${DEFOMODE}${MODENR}.txt_After${MAXDATE}_${MM}_${DD}_${YYYY}.txt > ${MSBASDIR}/${DEFOMODE}${MODENR}_WithoutDatesBetween${MINDATE}and${MAXDATE}.txt
#				cp -f ${MSBASDIR}/${DEFOMODE}${MODENR}_WithoutDatesBetween${MINDATE}and${MAXDATE}.txt ${MSBASDIR}/${DEFOMODE}${MODENR}.txt
#			else 
#				if [ "${REMOVEBEFORE}" != "NONE" ] && [ "${REMOVEAFTER}" != "NONE" ] ; then 
#					echo "  // You requested to remove all pairs from mode ${MODENR} with an image before ${REMOVEBEFORE} and after ${REMOVEAFTER}. " 
#					echo "  // This is not possible unless you wanted to remove only the pairs between these dates. In that case you must set the parameter REMOVEBETWEEN${MODENR} to YES in the present cron script."
#					echo "  // Otherwise, simply set in the present cron script REMOVEBEFORE${MODENR} or REMOVEAFTER${MODENR} to NONE, depending on your needs."
#					exit
#				fi
#				if [ "${REMOVEBEFORE}" != "NONE" ] ; then
#					echo "  // Shall remove all pairs with an image before ${REMOVEBEFORE} from mode ${MODENR}."
#					# Remove before given date	
#					cp -f ${MSBASDIR}/${DEFOMODE}${MODENR}.txt ${MSBASDIR}/${DEFOMODE}${MODENR}_WithoutRemoveDatesBefore${REMOVEBEFORE}.txt
#					RemovePairsFromModeList_WithImagesBefore.sh ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${REMOVEBEFORE} 
#					# Creates a file named e.g. DefoInterpolx2Detrend1.txt_After20150601_12_28_2023.txt
#					cp ${MSBASDIR}/${DEFOMODE}${MODENR}.txt_After${REMOVEBEFORE}_${MM}_${DD}_${YYYY}.txt ${MSBASDIR}/${DEFOMODE}${MODENR}.txt
#				fi
#				if [ "${REMOVEAFTER}" != "NONE" ] ; then 
#					echo "  // Shall remove all pairs with an image after ${REMOVEAFTER} from mode ${MODENR}."
#					# Remove after given date	
#					cp -f ${MSBASDIR}/${DEFOMODE}${MODENR}.txt ${MSBASDIR}/${DEFOMODE}${MODENR}_WithoutRemoveDatesAfter${REMOVEAFTER}.txt
#					RemovePairsFromModeList_WithImagesAfter.sh ${MSBASDIR}/${DEFOMODE}${MODENR}.txt ${REMOVEAFTER} 
#					# Creates a file named e.g. DefoInterpolx2Detrend1.txt_Below20150601_12_28_2023.txt
#					cp ${MSBASDIR}/${DEFOMODE}${MODENR}.txt_Below${REMOVEAFTER}_${MM}_${DD}_${YYYY}.txt ${MSBASDIR}/${DEFOMODE}${MODENR}.txt
#				fi
#		fi
#		echo ""
#	}

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
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL} "${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit			
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
	cd ${S1ASC1}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${S1ASC2}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &

	cd ${S1DESC1}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${S1DESC2}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	cd ${S1DESC3}
	Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh &
	wait
	
# Get date (in sec) of last available processed pairs in each MODE
##################################################################
	# get the name of last available processed pair in each MODE

    # ls crashes when too many files 
	#LASTASC=`ls -lt ${S1ASC}/Geocoded/${DEFOMODE} | head -n 2 | tail -n 1 | sed 's/.* //'` # may be messing up if txt files are created for any other purpose in the dir... 
	#LASTDESC=`ls -lt ${S1DESC}/Geocoded/${DEFOMODE} | head -n 2 | tail -n 1 | sed 's/.* //'`
	LASTASC1=`find ${S1ASC1}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTASC2=`find ${S1ASC2}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	LASTDESC1=`find ${S1DESC1}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTDESC2=`find ${S1DESC2}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTDESC3=`find ${S1DESC3}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	# get date in sec of last available processed pairs in each MODE
	LASTASCTIME1=`stat -c %Y ${LASTASC1}`
	LASTASCTIME2=`stat -c %Y ${LASTASC2}`
	LASTDESCTIME1=`stat -c %Y ${LASTDESC1}`
	LASTDESCTIME2=`stat -c %Y ${LASTDESC2}`
	LASTDESCTIME3=`stat -c %Y ${LASTDESC3}`

# Check if first run and if  appropriate, get time of last images in time series
################################################################################
	if [ -f "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] && [ -s "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] 
		then   
			echo "Existing ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence not the first run"
			FIRSTRUN=NO
			FORMERLASTASCTIME1=`head -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`
			FORMERLASTASCTIME2=`head -2 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1` # tail -1 ok also but this is ready for case where more than 2 lines are present in _Last_MassProcessed_Pairs_Time.txt
			FORMERLASTDESCTIME1=`head -3 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1` # tail -1 ok also but this is ready for case where more than 2 lines are present in _Last_MassProcessed_Pairs_Time.txt
			FORMERLASTDESCTIME2=`head -4 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1` # tail -1 ok also but this is ready for case where more than 2 lines are present in _Last_MassProcessed_Pairs_Time.txt
			FORMERLASTDESCTIME3=`head -5 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1` # tail -1 ok also but this is ready for case where more than 2 lines are present in _Last_MassProcessed_Pairs_Time.txt
			
			if [ ${FORMERLASTASCTIME1} -eq ${LASTASCTIME1} ] && [ ${FORMERLASTASCTIME2} -eq ${LASTASCTIME2} ] && [ ${FORMERLASTDESCTIME1} -eq ${LASTDESCTIME1} ] && [ ${FORMERLASTDESCTIME2} -eq ${LASTDESCTIME2} ] && [ ${FORMERLASTDESCTIME3} -eq ${LASTDESCTIME3} ] # if no more recent file is available since the last cron processing
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
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}2 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}3 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}4 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}5 &

		wait
		echo "Possible broken links in former existing MODEi dir are cleaned"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)	
		if [ ${IFCOH} == "YES" ] ; then 
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}1_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}2_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}3_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}4_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/${DEFOMODE}5_Full &
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
		mv ${DEFOMODE}5.txt ${DEFOMODE}5_all4col.txt
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}3_all4col.txt > ${DEFOMODE}3.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}4_all4col.txt > ${DEFOMODE}4.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}5_all4col.txt > ${DEFOMODE}5.txt 
		rm -f ${DEFOMODE}1_all4col.txt ${DEFOMODE}2_all4col.txt ${DEFOMODE}3_all4col.txt ${DEFOMODE}4_all4col.txt ${DEFOMODE}5_all4col.txt
		echo "All lines in former existing MODEi.txt have 4 columns"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			mv ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt
			mv ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt
			mv ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full.txt ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full_all4col.txt
			mv ${MSBASDIR}/${DEFOMODE}4_Full/${DEFOMODE}3_Full.txt ${MSBASDIR}/${DEFOMODE}4_Full/${DEFOMODE}4_Full_all4col.txt
			mv ${MSBASDIR}/${DEFOMODE}5_Full/${DEFOMODE}3_Full.txt ${MSBASDIR}/${DEFOMODE}5_Full/${DEFOMODE}5_Full_all4col.txt

			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}4_Full/${DEFOMODE}4_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}4_Full/${DEFOMODE}4_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/${DEFOMODE}5_Full/${DEFOMODE}5_Full_all4col.txt > ${MSBASDIR}/${DEFOMODE}5_Full/${DEFOMODE}5_Full.txt 

			rm -f ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full_all4col.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full_all4col.txt ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full_all4col.txt
			echo "All lines in former existing MODEi_Full.txt have 4 columns"
			echo ""
		fi
	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
		cd ${MSBASDIR}
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1 ${PATHMASSPROCESS} &
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2 ${PATHMASSPROCESS} &
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}3 ${PATHMASSPROCESS} &
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}4 ${PATHMASSPROCESS} &
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}5 ${PATHMASSPROCESS} &
		wait
		echo "All lines in former existing MODEi.txt are ok"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1_Full ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2_Full ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}3_Full ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}4_Full ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}5_Full ${PATHMASSPROCESS} &
			wait
			echo "All lines in former existing MODEi_Full.txt are ok"
			echo ""	
		fi
	
	fi

# Prepare MSBAS
###############
#	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_criteria.sh DefoInterpolx2Detrend 3 ${BP} ${BT} ${S1ASC} ${S1DESC1} ${S1DESC2}
	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh ${DEFOMODE} 5 ${TABLESET1} ${TABLESET2} ${TABLESET3} ${TABLESET4} ${TABLESET5} ${S1ASC1} ${S1ASC2} ${S1DESC1} ${S1DESC2}  ${S1DESC3}

	# For debug:
	#read -p "build header finished, click to continue"

	# update here the R_FLAG if needed
	#${PATHGNU}/gsed -i "s/R_FLAG = 2, 0.02/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt
	${PATHGNU}/gsed -i "s/^R_FLAG.*/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt

	# If interferos are detreneded, i.e. averaged to zero, there is no need to calibrate again 
	${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 0/' ${MSBASDIR}/header.txt
	# Not the case here, hence chose calibration pixel(s)
	#${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 1, 45, 197, 5, 5/' ${MSBASDIR}/header.txt

	cp header.txt header_all_modes.txt # to be kept all time

	# Check again that files are OK
		# ensure that format is ok, that is with 4 columns 
		mv ${DEFOMODE}1.txt ${DEFOMODE}1_all4col.txt
		mv ${DEFOMODE}2.txt ${DEFOMODE}2_all4col.txt
		mv ${DEFOMODE}3.txt ${DEFOMODE}3_all4col.txt
		mv ${DEFOMODE}4.txt ${DEFOMODE}4_all4col.txt
		mv ${DEFOMODE}5.txt ${DEFOMODE}5_all4col.txt
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}3_all4col.txt > ${DEFOMODE}3.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}4_all4col.txt > ${DEFOMODE}4.txt 
		${PATHGNU}/gawk 'NF>=4' ${DEFOMODE}5_all4col.txt > ${DEFOMODE}5.txt 
		# keep track of prblms
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}1_all4col.txt > ${DEFOMODE}1_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}2_all4col.txt > ${DEFOMODE}2_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}3_all4col.txt > ${DEFOMODE}3_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}4_all4col.txt > ${DEFOMODE}4_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' ${DEFOMODE}5_all4col.txt > ${DEFOMODE}5_MissingCol.txt 
		rm -f ${DEFOMODE}1_all4col.txt ${DEFOMODE}2_all4col.txt ${DEFOMODE}3_all4col.txt ${DEFOMODE}4_all4col.txt ${DEFOMODE}5_all4col.txt
		
		# Need again to check for duplicated lines with different Bp in Col 2 resulting from orbit update 
		if [ ${IFCOH} == "YES" ] ; then 
			echo "Remove lines in newly created MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}1 ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}2 ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}3 ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}4 ${PATHMASSPROCESS} &
			_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}5 ${PATHMASSPROCESS} &
			wait
			echo "All lines in new MODEi.txt should be ok"
			echo ""	
		fi
		
#	# Remove some dates if needed
#	if [ "${DATERESTRIC1}" == "YES" ] ; then 
#		RemoveDates	"1"	"${REMOVEBETWEEN1}" "${REMOVEBEFORE1}" "${REMOVEAFTER1}"
#		# that is ; mode 1, NO remove between dates, remove before 20150601, do not remove after a given date
#	fi
#	if [ "${DATERESTRIC2}" == "YES" ] ; then
#		RemoveDates "2"	"${REMOVEBETWEEN2}" "${REMOVEBEFORE2}" "${REMOVEAFTER2}"
#		# that is ; mode 1, NO remove between dates, remove before 20150601, do not remove after a given date
#	fi
#	if [ "${DATERESTRIC3}" == "YES" ] ; then
#		RemoveDates "3"	"${REMOVEBETWEEN3}" "${REMOVEBEFORE3}" "${REMOVEAFTER3}"
#		# that is ; mode 1, NO remove between dates, remove before 20150601, do not remove after a given date
#	fi
#	if [ "${DATERESTRIC4}" == "YES" ] ; then
#		RemoveDates "4"	"${REMOVEBETWEEN4}" "${REMOVEBEFORE4}" "${REMOVEAFTER4}"
#		# that is ; mode 1, NO remove between dates, remove before 20150601, do not remove after a given date
#	fi
#	if [ "${DATERESTRIC5}" == "YES" ] ; then
#		RemoveDates "5"	"${REMOVEBETWEEN5}" "${REMOVEBEFORE5}" "${REMOVEAFTER5}"
#		# that is ; mode 1, NO remove between dates, remove before 20150601, do not remove after a given date
#	fi


# Let's go
##########
	cd ${MSBASDIR}
	cp -f header.txt header_back.txt 

# Prepare header files 

		#  keep all comp header
		cp -f ${MSBASDIR}/header.txt ${MSBASDIR}/header_${ALLCOMP}.txt 

		#   search for line nr of each SET mode definition - needed also later for computing SBAS of each LoS
 		LINENR01A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -1 | cut -d: -f1)
		LINENR02A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -2 | tail -1 | cut -d: -f1)	

 		LINENR01D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -3 | tail -1 | cut -d: -f1)
 		LINENR02D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -4 | tail -1 | cut -d: -f1)
 		LINENR03D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -5 | tail -1 | cut -d: -f1)

 		#   Change "SET = " with "#SET = " in each line of header
		cat ${MSBASDIR}/header_all_modes.txt | ${PATHGNU}/gsed "s/SET = /#SET = /g" > ${MSBASDIR}/header_none.txt	# This allows computing LoS of rejected modes as well
		
		#   Change "#SET = " with "SET = " for only the mode one wants to keep 
		# 	and change crop of msbas window
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE01A}.txt	# A85
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A85}'/" ${MSBASDIR}/header_${MODE01A}.txt
		
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR02A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE02A}.txt	# A158
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A158}'/" ${MSBASDIR}/header_${MODE02A}.txt
		
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE01D}.txt	# D19
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_D19}'/" ${MSBASDIR}/header_${MODE01D}.txt
		
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR02D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE02D}.txt	# D92
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_D92}'/" ${MSBASDIR}/header_${MODE02D}.txt
		
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR03D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE03D}.txt	# D121
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_D121}'/" ${MSBASDIR}/header_${MODE03D}.txt

		# specific to NEPAL: 9 combinations:
		####################################
		# A158_D19 i.e. 2A 1D 
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR02A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE02A}_${MODE01D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = ${CROP_A158_D19}/" ${MSBASDIR}/header_${MODE02A}_${MODE01D}.txt

		# A158_D92 		i.e. 2A 2D
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR02A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR02D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE02A}_${MODE02D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A158_D92}'/" ${MSBASDIR}/header_${MODE02A}_${MODE02D}.txt

		# A85_A158_D19 	i.e. 1A 2A 1D
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /' | ${PATHGNU}/gsed ${LINENR02A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE01A}_${MODE02A}_${MODE01D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A85_A158_D19}'/" ${MSBASDIR}/header_${MODE01A}_${MODE02A}_${MODE01D}.txt

		# A85_D19 		i.e. 1A 1D
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE01A}_${MODE01D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A85_D19}'/" ${MSBASDIR}/header_${MODE01A}_${MODE01D}.txt

		# A85_D121		i.e. 1A 3D
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR03D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE01A}_${MODE03D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A85_D121}'/" ${MSBASDIR}/header_${MODE01A}_${MODE03D}.txt

		# A85_D19_D121	i.e. 1A 1D 3D
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /' | ${PATHGNU}/gsed ${LINENR03D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE01A}_${MODE01D}_${MODE03D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A85_D19_D121}'/" ${MSBASDIR}/header_${MODE01A}_${MODE01D}_${MODE03D}.txt

		# unused because not enough overlap
		###################################
		# A85_A158_D92 	i.e. 1A 2A 2D
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /' | ${PATHGNU}/gsed ${LINENR02A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR02D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE01A}_${MODE02A}_${MODE02D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A85_A158_D92}'/" ${MSBASDIR}/header_${MODE01A}_${MODE02A}_${MODE02D}.txt

		# A85_D92		i.e. 1A 2D
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR02D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE01A}_${MODE02D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A85_D92}'/" ${MSBASDIR}/header_${MODE01A}_${MODE02D}.txt

		# A85_D19_D92	i.e. 1A 1D 2D
		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /'  | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /' | ${PATHGNU}/gsed ${LINENR02D}' s/#SET = /SET = /'> ${MSBASDIR}/header_${MODE01A}_${MODE01D}_${MODE02D}.txt
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = '${CROP_A85_D19_D92}'/" ${MSBASDIR}/header_${MODE01A}_${MODE01D}_${MODE02D}.txt

 		# Prepare header files


#	# EW-UD without coh threshold restriction 
#	#-----------------------------------------
#		if [ ${IFCOH} == "YES" ] 
#		then 
#			# This is the run without coh restriction from dual run where a coh restriction will be requested after
#			# Prepare stuff from possible former run with coh restriction
#			#------------------------------------------------------------
#			case ${FIRSTRUN} in 
#				"YES") 
#					# one have only the newly created MODEi dir and MODEi.txt
#					cp -R ${MSBASDIR}/${DEFOMODE}1 ${MSBASDIR}/${DEFOMODE}1_Full
#					cp -f ${MSBASDIR}/${DEFOMODE}1.txt ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}1.txt ${MSBASDIR}/${DEFOMODE}1_Full.txt
#				
#					cp -R ${MSBASDIR}/${DEFOMODE}2 ${MSBASDIR}/${DEFOMODE}2_Full
#					cp -f ${MSBASDIR}/${DEFOMODE}2.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}2.txt ${MSBASDIR}/${DEFOMODE}2_Full.txt
#
#					cp -R ${MSBASDIR}/${DEFOMODE}3 ${MSBASDIR}/${DEFOMODE}3_Full
#					cp -f ${MSBASDIR}/${DEFOMODE}3.txt ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}3.txt ${MSBASDIR}/${DEFOMODE}3_Full.txt
#
#					cp -R ${MSBASDIR}/${DEFOMODE}4 ${MSBASDIR}/${DEFOMODE}4_Full
#					cp -f ${MSBASDIR}/${DEFOMODE}4.txt ${MSBASDIR}/${DEFOMODE}4_Full/${DEFOMODE}4_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}4.txt ${MSBASDIR}/${DEFOMODE}4_Full.txt
#
#					cp -R ${MSBASDIR}/${DEFOMODE}5 ${MSBASDIR}/${DEFOMODE}5_Full
#					cp -f ${MSBASDIR}/${DEFOMODE}5.txt ${MSBASDIR}/${DEFOMODE}5_Full/${DEFOMODE}5_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}5.txt ${MSBASDIR}/${DEFOMODE}5_Full.txt
#
#
#					;;
#				"NO")
#					# one must merge the newly created MODEi dir and MODEi.txt with former _Full ones
#					sort ${MSBASDIR}/${DEFOMODE}1.txt | uniq > ${MSBASDIR}/${DEFOMODE}1_tmp.txt
#					sort ${MSBASDIR}/${DEFOMODE}2.txt | uniq > ${MSBASDIR}/${DEFOMODE}2_tmp.txt
#					sort ${MSBASDIR}/${DEFOMODE}3.txt | uniq > ${MSBASDIR}/${DEFOMODE}3_tmp.txt
#					sort ${MSBASDIR}/${DEFOMODE}4.txt | uniq > ${MSBASDIR}/${DEFOMODE}4_tmp.txt
#					sort ${MSBASDIR}/${DEFOMODE}5.txt | uniq > ${MSBASDIR}/${DEFOMODE}5_tmp.txt
#				
#					sort ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt | uniq > ${MSBASDIR}/${DEFOMODE}1_Full_tmp.txt
#					sort ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt | uniq > ${MSBASDIR}/${DEFOMODE}2_Full_tmp.txt
#					sort ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full.txt | uniq > ${MSBASDIR}/${DEFOMODE}3_Full_tmp.txt
#					sort ${MSBASDIR}/${DEFOMODE}4_Full/${DEFOMODE}4_Full.txt | uniq > ${MSBASDIR}/${DEFOMODE}4_Full_tmp.txt
#					sort ${MSBASDIR}/${DEFOMODE}5_Full/${DEFOMODE}5_Full.txt | uniq > ${MSBASDIR}/${DEFOMODE}5_Full_tmp.txt
#				
#					cat ${MSBASDIR}/${DEFOMODE}1_tmp.txt ${MSBASDIR}/${DEFOMODE}1_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/${DEFOMODE}1_Full.txt
#					cat ${MSBASDIR}/${DEFOMODE}2_tmp.txt ${MSBASDIR}/${DEFOMODE}2_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/${DEFOMODE}2_Full.txt
#					cat ${MSBASDIR}/${DEFOMODE}3_tmp.txt ${MSBASDIR}/${DEFOMODE}3_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/${DEFOMODE}3_Full.txt
#					cat ${MSBASDIR}/${DEFOMODE}4_tmp.txt ${MSBASDIR}/${DEFOMODE}4_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/${DEFOMODE}4_Full.txt
#					cat ${MSBASDIR}/${DEFOMODE}5_tmp.txt ${MSBASDIR}/${DEFOMODE}5_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/${DEFOMODE}5_Full.txt
#				
#					cp -R -n ${MSBASDIR}/${DEFOMODE}1 ${MSBASDIR}/${DEFOMODE}1_Full
#					cp -R -n ${MSBASDIR}/${DEFOMODE}2 ${MSBASDIR}/${DEFOMODE}2_Full
#					cp -R -n ${MSBASDIR}/${DEFOMODE}3 ${MSBASDIR}/${DEFOMODE}3_Full
#					cp -R -n ${MSBASDIR}/${DEFOMODE}4 ${MSBASDIR}/${DEFOMODE}4_Full
#					cp -R -n ${MSBASDIR}/${DEFOMODE}5 ${MSBASDIR}/${DEFOMODE}5_Full
#					cp -f ${MSBASDIR}/${DEFOMODE}1_Full.txt ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}2_Full.txt ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}3_Full.txt ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}4_Full.txt ${MSBASDIR}/${DEFOMODE}4_Full/${DEFOMODE}4_Full.txt
#					cp -f ${MSBASDIR}/${DEFOMODE}5_Full.txt ${MSBASDIR}/${DEFOMODE}5_Full/${DEFOMODE}5_Full.txt
#				
#					rm -f ${MSBASDIR}/${DEFOMODE}1_tmp.txt ${MSBASDIR}/${DEFOMODE}1_Full_tmp.txt 
#					rm -f ${MSBASDIR}/${DEFOMODE}2_tmp.txt ${MSBASDIR}/${DEFOMODE}2_Full_tmp.txt
#					rm -f ${MSBASDIR}/${DEFOMODE}3_tmp.txt ${MSBASDIR}/${DEFOMODE}3_Full_tmp.txt
#					rm -f ${MSBASDIR}/${DEFOMODE}4_tmp.txt ${MSBASDIR}/${DEFOMODE}4_Full_tmp.txt
#					rm -f ${MSBASDIR}/${DEFOMODE}5_tmp.txt ${MSBASDIR}/${DEFOMODE}5_Full_tmp.txt
#					;;	
#			esac
#			# trick the header file						
#			${PATHGNU}/gsed -i 's/${DEFOMODE}1.txt/${DEFOMODE}1_Full.txt/' ${MSBASDIR}/header.txt
#			${PATHGNU}/gsed -i 's/${DEFOMODE}2.txt/${DEFOMODE}2_Full.txt/' ${MSBASDIR}/header.txt
#			${PATHGNU}/gsed -i 's/${DEFOMODE}3.txt/${DEFOMODE}3_Full.txt/' ${MSBASDIR}/header.txt
#			${PATHGNU}/gsed -i 's/${DEFOMODE}4.txt/${DEFOMODE}4_Full.txt/' ${MSBASDIR}/header.txt
#			${PATHGNU}/gsed -i 's/${DEFOMODE}5.txt/${DEFOMODE}5_Full.txt/' ${MSBASDIR}/header.txt
#		 
#		 	NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${TIMESERIESPTS}
#		
#			# Make baseline plot 
#	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${DEFOMODE}1_Full/${DEFOMODE}1_Full.txt
#	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${DEFOMODE}2_Full/${DEFOMODE}2_Full.txt
#	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET3} ${MSBASDIR}/${DEFOMODE}3_Full/${DEFOMODE}3_Full.txt
#	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET4} ${MSBASDIR}/${DEFOMODE}4_Full/${DEFOMODE}4_Full.txt
#	 		PlotBaselineGeocMSBASmodeTXT.sh ${SET5} ${MSBASDIR}/${DEFOMODE}5_Full/${DEFOMODE}5_Full.txt
#
#			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
#	 		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
#	
#			while read -r DESCR X Y RX RY
#	 		do	
#	 				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
#	 				mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
#	 				mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
#	 		done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
#
#			# Why not some double difference plotting
#			while read -r X1 Y1 X2 Y2 DESCR
#				do	
#					PlotAllNoCoh ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
#			done < ${DOUBLEDIFFPAIRSEWUD}
#
#	  		# move all plots in same dir 
#			rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/*.jpg
#	  		mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
#	  
#	  		# move all time series in dir 
#	 		mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series/
#
#		 else
#			# i.e. without any coh threshold restriction
#			# -------------------------------------------
#			
			# Make baseline plot 
			PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${DEFOMODE}1.txt
			PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${DEFOMODE}2.txt
			PlotBaselineGeocMSBASmodeTXT.sh ${SET3} ${MSBASDIR}/${DEFOMODE}3.txt
			PlotBaselineGeocMSBASmodeTXT.sh ${SET4} ${MSBASDIR}/${DEFOMODE}4.txt
			PlotBaselineGeocMSBASmodeTXT.sh ${SET5} ${MSBASDIR}/${DEFOMODE}5.txt
			
			function RunCombiEWUD()
					{
					unset MODES
					MODES=$1 		#  Modes, eg ${COMBI01}, that is ${MODE02A}_${MODE01D}
					TSDESCRFILE=$2 	#  TIMESERIESPTSDESCR file, e.g. ${TIMESERIESPTSDESCRASC1}
					DOUBLEDIFF=$3	#  DOUBLEDIFFPAIRSEWUD file, e.g. ${DOUBLEDIFFPAIRSASC1}
					echo ""
					echo "// Processing EW_UD mode ${MODES}"
					echo "/////////////////////////////////////////////"

					cd ${MSBASDIR}
					cp -f  ${MSBASDIR}/header_${MODES}.txt  ${MSBASDIR}/header.txt
					NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}

					# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
					cp ${TSDESCRFILE} ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		
					while read -r DESCR X Y RX RY
						do	
							echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
							mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
							mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
					done < <(tail -n +2 "${TSDESCRFILE}")		# ignore header
					
					# Why not some double difference plotting
					while read -r X1 Y1 X2 Y2 DESCR
						do	
							PlotAllCombiModes ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
					done < ${DOUBLEDIFF}	
		
					# move all plots in same dir 
					rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/*.jpg
					mv ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
		
					# move all time series in dir 
					mv ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_${MODES}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
					}

			
			#cp -f  ${MSBASDIR}/header_${MODE02A}_${MODE01D}.txt  ${MSBASDIR}/header.txt
			#NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE02A}_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}

			# A158_D19 i.e. 2A 1D 
			RunCombiEWUD ${COMBI01} ${TIMESERIESPTSDESCRCOMBI1} ${DOUBLEDIFFPAIRSCOMBI1}
			
			# A158_D92 		i.e. 2A 2D
			RunCombiEWUD ${COMBI02} ${TIMESERIESPTSDESCRCOMBI2} ${DOUBLEDIFFPAIRSCOMBI2}
	
			# A85_A158_D19 	i.e. 1A 2A 1D
			RunCombiEWUD ${COMBI03} ${TIMESERIESPTSDESCRCOMBI3} ${DOUBLEDIFFPAIRSCOMBI3}
	
			# A85_D19 		i.e. 1A 1D
			RunCombiEWUD ${COMBI04} ${TIMESERIESPTSDESCRCOMBI4} ${DOUBLEDIFFPAIRSCOMBI4}
	
			# A85_D121		i.e. 1A 3D
			RunCombiEWUD ${COMBI05} ${TIMESERIESPTSDESCRCOMBI5} ${DOUBLEDIFFPAIRSCOMBI5}
			
			# A85_D19_D121	i.e. 1A 1D 3D
			RunCombiEWUD ${COMBI06} ${TIMESERIESPTSDESCRCOMBI6} ${DOUBLEDIFFPAIRSCOMBI6}

			# MODES NOT COMPUTED BECAUSE ONLY SMALL TRIANGLE TO THE NW OF THE AREA AND ALREADY COVERED BY 4 OTHER COMBINATIONS 
			## A85_D19_D92	i.e. 1A 1D 2D
			#RunCombiEWUD ${MODE01A}_${MODE01D}_${MODE02D}
			#
			## A85_A158_D92 	i.e. 1A 2A 2D
			#RunCombiEWUD ${MODE01A}_${MODE02A}_${MODE02D}
			#
			## A85_D92		i.e. 1A 2D
			#RunCombiEWUD ${MODE01A}_${MODE02D}
			


#			
#			NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
#
#			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
#			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
#
#			while read -r DESCR X Y RX RY
#				do	
#					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
#					mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
#					mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
#			done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
#
#			# Why not some double difference plotting
#			while read -r X1 Y1 X2 Y2 DESCR
#				do	
#					PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
#			done < ${DOUBLEDIFFPAIRSEWUD}	
#
#			# move all plots in same dir 
#			rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/*.jpg
#			mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
#
#			# move all time series in dir 
#			mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
#		fi 
#
#	# EW-UD with coh threshold restriction 
#	#--------------------------------------
#		if [ ${IFCOH} == "YES" ] ; then
#			cd ${MSBASDIR}
#			cp -f header_back.txt header.txt
#
#			# run restrict_msbas_to_Coh.sh         
#			restrict_msbas_to_Coh.sh ${DEFOMODE}1 ${COHRESTRICT} ${KMLCOH} ${S1ASC1}/Geocoded/Coh
#			restrict_msbas_to_Coh.sh ${DEFOMODE}2 ${COHRESTRICT} ${KMLCOH} ${S1ASC2}/Geocoded/Coh
#			restrict_msbas_to_Coh.sh ${DEFOMODE}3 ${COHRESTRICT} ${KMLCOH} ${S1DESC1}/Geocoded/Coh
#			restrict_msbas_to_Coh.sh ${DEFOMODE}4 ${COHRESTRICT} ${KMLCOH} ${S1DESC2}/Geocoded/Coh
#			restrict_msbas_to_Coh.sh ${DEFOMODE}5 ${COHRESTRICT} ${KMLCOH} ${S1DESC3}/Geocoded/Coh
#		
#			# Force pair exclusion 
#			if [ ${EXCLUDE1} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/${DEFOMODE}1
#			fi 
#			if [ ${EXCLUDE2} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/${DEFOMODE}2
#			fi 
#			if [ ${EXCLUDE3} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/${DEFOMODE}3
#			fi 
#			if [ ${EXCLUDE4} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/${DEFOMODE}4
#			fi 
#			if [ ${EXCLUDE5} == "YES" ] ; then 
#				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/${DEFOMODE}5
#			fi 
#			
#			cd ${MSBASDIR}
#			NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
#
#			# Make baseline plot 
#			PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${DEFOMODE}1.txt
#			PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${DEFOMODE}2.txt
#			PlotBaselineGeocMSBASmodeTXT.sh ${SET3} ${MSBASDIR}/${DEFOMODE}3.txt
#			PlotBaselineGeocMSBASmodeTXT.sh ${SET4} ${MSBASDIR}/${DEFOMODE}4.txt
#			PlotBaselineGeocMSBASmodeTXT.sh ${SET5} ${MSBASDIR}/${DEFOMODE}5.txt
#		
#			# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
#			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
#
#			while read -r DESCR X Y RX RY
#				do	
#					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
#					mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
#					mv ${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
#			done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
#
#			# Why not some double difference plotting
#			while read -r X1 Y1 X2 Y2 DESCR
#				do	
#					PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
#			done < ${DOUBLEDIFFPAIRSEWUD}	
#						
#			# move all plots in same dir 
#			rm -f ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/*.jpg
#			mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi.jpg ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
#
#			# move all time series in dir 
#			mv ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
#		fi
	
	# Asc and Desc (with coh restriction if one is requested)
 	#--------------------------------------------------------

		# ASC
 			FILEPAIRS=${DOUBLEDIFFPAIRSASC1}
			MSBASmode ${MODE01A} ${FORMERLASTASCTIME1} ${LASTASCTIME1}

 			FILEPAIRS=${DOUBLEDIFFPAIRSASC2}
			MSBASmode ${MODE02A} ${FORMERLASTASCTIME2} ${LASTASCTIME2}

  		
		# DESC
 			FILEPAIRS=${DOUBLEDIFFPAIRSDESC1}
 			MSBASmode  ${MODE01D} ${FORMERLASTDESCTIME1} ${LASTDESCTIME1}

 			FILEPAIRS=${DOUBLEDIFFPAIRSDESC2}
   			MSBASmode  ${MODE02D} ${FORMERLASTDESCTIME2} ${LASTDESCTIME2}

 			FILEPAIRS=${DOUBLEDIFFPAIRSDESC3}
   			MSBASmode  ${MODE03D} ${FORMERLASTDESCTIME3} ${LASTDESCTIME3}

		###		MSBASmode AllDesc 				



 		# Back to normal for next run and get out
 			cp -f ${MSBASDIR}/header_${ALLCOMP}.txt ${MSBASDIR}/header.txt 		 				

			TODAY=`date`
			echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt

			echo "${LASTASCTIME1}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
			echo "${LASTASCTIME2}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt

			echo "${LASTDESCTIME1}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
			echo "${LASTDESCTIME2}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
			echo "${LASTDESCTIME3}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
		
	#mv -f ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp ${MSBASDIR}/${TIMESERIESPTSDESCR}

# All done...
