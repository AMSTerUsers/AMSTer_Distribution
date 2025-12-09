#!/bin/bash
# Script intends to run in a cronjob an automatic systematic (re)processing of msbas time 
# series when new images were made available. If orbits were updated, corresponding products 
# will be taken into account at the time of processing with new images. 
#
# THIS VERSION IS PERFORMED IN TWO PARTS AND MERGED ARTIFICALLY TO SPARE TIME
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
# Parameters: - none 
#
# Hardcoded: - a lot... se below paragraph named HARD CODED but also adapt below depending on the number of modes 
#			 - suppose everywhere that modes are DefoInterpolx2Detrend
#
# Dependencies:	- awk 
#				- several scripts from SCRIPTS_MT
#				- Add_DefoMap_ToAllMapsInDir.py and Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py for splitting processing
#				- Replot_EW_UD_DoubleDiff_TS_From_Cron_Step3.sh and Replot_LoS_DoubleDiff_TS_From_Cron_Step3.sh for splitting processing
#				- Envi2ras.sh for splitting processing
#
# New in Distro V 2.0:	- based on beta version used for VVP, Domuyo, Lux and PF processing at ECGS
# New in Distro V 2.1:	- updated to use new PlotTS_all_comp.sh that computes as well the location and explanation tags etc...
# New in Distro V 2.2:	- correct syntax bug in testing EXCLUDEi
# New in Distro V 2.3:	- rm jpg images before moving to __Combi
# New in Distro V 2.4:  - change all _combi as _Combi for uniformisation
# New in Distro V 2.5:  - search for latest deg file using find instead of ls, which crashes when too many files 
# New in Distro V 2.6:  - correct bug in searching for latest deg file 
# New in Distro V 2.7: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20231110:	- Revised paths
# New in Distro V 4.2 20231228:	- Remove images before June 1st 2015 to avoid stripes in images
# New in Distro V 4.3 20240702:	- enlarge Bp2 from 30 to 70m to account for orbital drift
# New in Distro V 5.0.0 20240801:	- split in two parts
# New in Distro V 5.1.0 20240802:	- debug search for MSBAS_[0-9]\{8\}T[0-9]\{6\}_UD/EW/LOS\.bin') files in for do loops 
#									- typo /dev/null ;  link hdr files to merged dirs
#									- force POSIX regex syntax in find cmd
# New in Distro V 5.1.1 20240805:	- change name of pair files After and Before to avoid possible double renaming
#									- debug target dir name when split in MSBASMode and ln files
#									- remove part of path in LAUNCHPARAMASC and DESC as it is only used to check what is running based on the name, not path
#									- some cosmetic, closer to example from Domuyo
# New in Distro V 5.1.1 20240806:	- mv defo maps results in merged dir and keep links in parts
#									- create rasters of merged LINEAR_RATE products
# New in Distro V 5.1.2 20240807:	- mv _recomputed maps to standard name
#									- debug list of pairs in part 2 LOS 
#									- make baseline plot of part1 only when part1 is computed
#									- some cosmetic cleaning ; run Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py in background to spare time
# New in Distro V 5.1.3 20250424:	- restrict usage of CPU to 128 threads because that is the max possible with OPENBLAS pre-compiled for Ubuntu
# New in Distro V 5.2.0 20251125 :	- always limited to 128 threads (see MAXTHREADS) to prevent problems with openblas, which is compiled by default for 128 threads 
#									- cp instead of link results in COMMON
#									- rename recomputed R2 files and create rasters 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.2 AMSTer script utilities"
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

	# Max number of threads (to avoid problem with openmp which is by default compiled for max 128)
		MAXTHREADS=128

	# Dates for split
	#################
		SPLIT="YES"
		
		# full time series goes from 20151103 to today, that is > 20240328, that is about 9 yrs
		# Since BT is 400, let's take part 1 = 7 yrs and part 2 = 8 years growing 
		PART1END=20220408		# i.e. 670 images	 
		PART2START=20181225		# must be DATEPART1END - 3 Bt (i.e. 1200 days); 490 and growing nr of images
		MIDOVERLAPASC=20200816	# must be DATEPART1END - 1.5 Bt
		MIDOVERLAPDESC=20200814	# must be DATEPART1END - 1.5 Bt
		
	# some parameters
	#################
		# Max baselines (used for all the mode in present case but you can change)
		# Mode 1 (cfr DefoInterpolx2Detrend1) is expected to be Ascending
		SET1BP1=20
		SET1BP2=70
		SET1BT1=400
		SET1BT2=400
		DATECHG1=20220501

		# Mode 2 (cfr DefoInterpolx2Detrend2) is expected to be Descending
		SET2BP1=20
		SET2BP2=70
		SET2BT1=400
		SET2BT2=400
		DATECHG2=20220501

		# To take into account the whole set of data with both sets 
		# of baseline criteria, one must take here the largest of each Bp and Bt 
		# See warning below
		BP=$(echo "$SET1BP1 $SET1BP2 $SET2BP1 $SET2BP2" | awk '{BP=$1; for(i=2;i<=NF;i++) if($i>BP) BP=$i; print BP}')	# max perpendicular baseline 
		BT=$(echo "$SET1BT1 $SET1BT2 $SET2BT1 $SET2BT2" | awk '{BT=$1; for(i=2;i<=NF;i++) if($i>BT) BT=$i; print BT}')	# max temporal baseline
		
		LABEL=LUX		# Label for file naming (used for naming zz_ dirs with results and figs etc)

		#R_FLAG
		# Order
		ORDER=2
		# Lambda
		LAMBDA=0.04
		
	# some files and PATH for each mode
	###################################

		# Path to mass processed pairs
		PATHTOMASPROCESSDIR=${PATH_3610}/SAR_MASSPROCESS

		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
		S1ASC=${PATHTOMASPROCESSDIR}/S1/LUX_A_88/SMNoCrop_SM_20190406_Zoom1_ML2
		S1DESC=${PATHTOMASPROCESSDIR}/S1/LUX_D_139/SMNoCrop_SM_20210920_Zoom1_ML2

		# Path to dir where list of compatible pairs files are computed (need one for each mode)
		SET1=${PATH_1660}/SAR_SM/MSBAS/LUX/set2
		SET2=${PATH_1660}/SAR_SM/MSBAS/LUX/set6

		# Path to LaunchParameters.txt files for each mode (need one for each mode)
		LAUNCHPARAMPATH=${PATH_DataSAR}/SAR_AUX_FILES/Param_files_SuperMaster/S1 # Reminer; not used here 
		LAUNCHPARAMASC=LaunchMTparam_S1_LUX_A_88_Zoom1_ML2_MassProc_0keep.txt
		LAUNCHPARAMDESC=LaunchMTparam_S1_LUX_D_139_Zoom1_ML2_MassProc_0keep.txt
		

	# Events tables
	###############
		EVENTS=${PATH_1650}/EVENTS_TABLES/${LABEL}

	# Path to dir where MSBAS will be computed
	###########################################
		MSBASDIR=${PATH_3602}/MSBAS/_${LABEL}_S1_Auto_${BP}m_${BT}days


	# Date Restriction
	##################

	DATERESTRIC1="YES"	# If YES, will remove dates from Mode 1 based on parma here after
	DATERESTRIC2="YES"	# If YES, will remove dates from Mode 2 based on parma here after

		REMOVEBEFORE1="20150601"	# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEAFTER1="NONE"			# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
		REMOVEBEFORE2="20150601"	# If not date is needed (i.e. if you do not want to restrict dates), write NONE !
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
		DOUBLEDIFFPAIRSEWUD=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_Lux.txt
		DOUBLEDIFFPAIRSASC=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_Lux.txt
		DOUBLEDIFFPAIRSDESC=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_Lux.txt
		
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	PATHCRONJOB=${PATH_SCRIPTS}/SCRIPTS_MT/_cron_scripts_NEW	# Reminder ; not used in this script
	CRONJOB2=LUX_S1_Step2_MassProc.sh

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
	function MoveAndLinkBack()
		{
		unset FILEPATH 		#  path and file name of orgin file
		unset TARGETDIR		#  path to target dir, i.e. where to move file and from where to create link up to where file was  
	
		local FILEPATH=$1	# e.g. $file
		local TARGETDIR=$2	# e.g. ${COMMONLOS}
		
		FILENAMEONLY=$(basename $FILEPATH)
		
		rm -f "${TARGETDIR}/${FILENAMEONLY}"
		rm -f "${TARGETDIR}/${FILENAMEONLY}.hdr"
		
		cp -f "$FILEPATH" "${TARGETDIR}/${FILENAMEONLY}"
		cp -f "$FILEPATH.hdr" "${TARGETDIR}/${FILENAMEONLY}.hdr"
		###mv -f "$FILEPATH" "${TARGETDIR}/${FILENAMEONLY}"
		###mv -f "$FILEPATH.hdr" "${TARGETDIR}/${FILENAMEONLY}.hdr"
		###
		#### Create a symbolic link in the target directory
		###ln -sf "${TARGETDIR}/${FILENAMEONLY}" "$FILEPATH" 
		###ln -sf "${TARGETDIR}/${FILENAMEONLY}.hdr" "$FILEPATH.hdr" 
		}

	function CreateRasAndMv()
		{
		unset COMMONDIR 	#  path to origin dir, ie. $COMMONUD, $COMMONEW or $COMMONLOS
		unset COMPOCODE		#  composante, ie. LOS, EW or UD  
	
		local COMMONDIR=$1	# e.g. $COMMONLOS
		local COMPOCODE=$2	# e.g. LOS
		
		# create rasters 
		Envi2ras.sh "${COMMONDIR}/MSBAS_LINEAR_RATE_${COMPOCODE}_recomputed.bin" 1 defo
		Envi2ras.sh "${COMMONDIR}/MSBAS_LINEAR_RATE_R2_${COMPOCODE}_recomputed.bin" 1 defo
		Envi2ras.sh "${COMMONDIR}/MSBAS_LINEAR_RATE_STD_${COMPOCODE}_recomputed.bin" 1 defo

		# mv maps for usage with PlotTS(_all_comp).sh
		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_${COMPOCODE}_recomputed.bin" "${COMMONDIR}/MSBAS_LINEAR_RATE_${COMPOCODE}.bin"
		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_STD_${COMPOCODE}_recomputed.bin" "${COMMONDIR}/MSBAS_LINEAR_RATE_STD_${COMPOCODE}.bin"
		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_R2_${COMPOCODE}_recomputed.bin" "${COMMONDIR}/MSBAS_LINEAR_RATE_R2_${COMPOCODE}.bin"

		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_${COMPOCODE}_recomputed.bin.hdr" "${COMMONDIR}/MSBAS_LINEAR_RATE_${COMPOCODE}.bin.hdr"
		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_STD_${COMPOCODE}_recomputed.bin.hdr" "${COMMONDIR}/MSBAS_LINEAR_RATE_STD_${COMPOCODE}.bin.hdr"
		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_R2_${COMPOCODE}_recomputed.bin.hdr" "${COMMONDIR}/MSBAS_LINEAR_RATE_R2_${COMPOCODE}.bin.hdr"

		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_${COMPOCODE}_recomputed.bin.ras" "${COMMONDIR}/MSBAS_LINEAR_RATE_${COMPOCODE}.bin.ras"
		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_STD_${COMPOCODE}_recomputed.bin.ras" "${COMMONDIR}/MSBAS_LINEAR_RATE_STD_${COMPOCODE}.bin.ras"
		mv -f "${COMMONDIR}/MSBAS_LINEAR_RATE_R2_${COMPOCODE}_recomputed.bin.ras" "${COMMONDIR}/MSBAS_LINEAR_RATE_R2_${COMPOCODE}.bin.ras"
		
		# Keep corresponding recomputed.bin.ras.sh to remember that it comes from recomputed   
		
		}
				
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
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt_After${REMOVEBEFORE}_${MM}_${DD}_${YYYY}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt
				fi
				if [ "${REMOVEAFTER}" != "NONE" ] ; then 
					echo "  // Shall remove all pairs with an image after ${REMOVEAFTER} from mode ${MODENR}."
					# Remove after given date	
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}_WithoutRemoveDatesAfter${REMOVEAFTER}.txt
					RemovePairsFromModeList_WithImagesAfter.sh ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt ${REMOVEAFTER} 
					# Creates a file named e.g. DefoInterpolx2Detrend1.txt_Below20150601_12_28_2023.txt
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt_Below${REMOVEAFTER}_${MM}_${DD}_${YYYY}.txt ${MSBASDIR}/DefoInterpolx2Detrend${MODENR}.txt
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
	
		rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg
		mv ${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg
		
		mv ${MSBASDIR}/timeLine_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
		mv ${MSBASDIR}/timeLine_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
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
		#rm plotTS*.gnu timeLines_*.png 
	
		if [ -f "${MSBASDIR}/timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] ; then 
			mv ${MSBASDIR}/timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps
		fi
		if [ -f "${MSBASDIR}/timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps
		fi 
		if [ -f "${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps

			rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_Combi.jpg
			mv ${MSBASDIR}/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_Combi.jpg

			mv ${MSBASDIR}/timeLine_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.txt
			mv ${MSBASDIR}/timeLine_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.txt
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
		#rm plotTS*.gnu timeLine*.png 

		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}_${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps

		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}_${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
	
		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_${MODE}.jpg
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_${MODE}.jpg
		}

	function MSBASmode()
		{
		unset MODE # e.g. Asc or Desc
		local MODE=$1
		cd ${MSBASDIR}
		cp -f ${MSBASDIR}/header_${MODE}.txt header.txt 
		# ${MSBASDIR}/header.txt makes use of only one DefoInterpolx2Detrendi.txt dataset WITH or WITHOUT coh threshold applied in these lists depending if IFCOH = YES or NO

		if [ ${SPLIT} == "YES" ] 
			then 
				if [ "${MODE}" == "Asc" ]
					then 
						MODENR=1
						MIDOVERLAP=${MIDOVERLAPASC}
						DEFOTXT=DefoInterpolx2Detrend1.txt
					else 
						MODENR=2
						MIDOVERLAP=${MIDOVERLAPDESC}
						DEFOTXT=DefoInterpolx2Detrend2.txt
				fi

				# the following will be created by MSBAS.sh hereafter
				LOSTARGETDIR1="${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART1_OVERLAP_${MIDOVERLAP}"
				LOSTARGETDIR2="${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART2_OVERLAP_${MIDOVERLAP}"

				# Dir where part 1 and 2 will be merged
				COMMONLOS=${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}
				mkdir -p ${COMMONLOS}

			
				# MSBSA part 1 - IF DIR LOSTARGETDIR1 DOES NOT EXIST YET OR IS EMPTY, 
				# then process part 1. If already done, skip 
					if [ ! -d "${LOSTARGETDIR1}" ] || [ -z "$(ls -A "${LOSTARGETDIR1}")" ] 
						then 
							echo "******************************************************"
							echo "MSBAS for ${MODE} part 1 not process yet; run it now. "
							echo "  See ${LOSTARGETDIR1} "
							echo "******************************************************"
							echo 
							
							RemovePairsFromModeList_WithImagesAfter.sh ${DEFOTXT} ${PART1END}	# will create a DefoInterpolx2Detrendi.txt_Below${PART1END}_$RNDM.txt
			
							PART1MODELIST=$(ls -t ${DEFOTXT}_Below${PART1END}_* | head -n 1)
							cp -f ${PART1MODELIST} DefoInterpolx2Detrend${MODENR}_Below${PART1END}.txt
							PART1MODELIST=DefoInterpolx2Detrend${MODENR}_Below${PART1END}.txt
			
							# trick the header file						
							${PATHGNU}/gsed -i "s/${DEFOTXT}/${PART1MODELIST}/" ${MSBASDIR}/header.txt
							# ${MSBASDIR}/header.txt makes use of only one DefoInterpolx2Detrend${MODENR}_Below${PART1END}.txt dataset for part 1 WITH or WITHOUT coh threshold applied in these lists depending if IFCOH = YES or NO
			
							NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART1_OVERLAP_${MIDOVERLAP} #${TIMESERIESPTS} # Do not compute TS
							cp -f ${MSBASDIR}/header_${MODE}.txt header.txt
							# back to ${MSBASDIR}/header.txt that makes use of only one DefoInterpolx2Detrendi.txt dataset WITH or WITHOUT coh threshold applied in these lists depending if IFCOH = YES or NO
						
							# link (or move ?) all defo maps in common part till MIDOVERLAP (included)
							MIDOVERLAPSEC=$(date -d "${MIDOVERLAP:0:4}-${MIDOVERLAP:4:2}-${MIDOVERLAP:6:2}" +%s) # Convert to timestamp
							#for file in "${LOSTARGETDIR1}"/MSBAS_*T*_LOS.bin; do	# would grab LINEAR_RATE file
							for file in $(find "${LOSTARGETDIR1}" -name "MSBAS_*T*.bin"); do
							  # Extract the date from the filename
							  filename=$(basename "$file")
							  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_LOS\.bin/\1/')
							  
  							  if [ "${file_date_str}" != "" ] ; then 
							  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
							  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
							  	
							  	# Compare the file date with the cutoff date
							  	if [ "$file_date_ts" -le "$MIDOVERLAPSEC" ]; then
							  	  MoveAndLinkBack "$file" "${COMMONLOS}"
							  	fi
							  fi
							done

						else 
							echo "****************************************************"
							echo "MSBAS for ${MODE} part 1 already process ; skip it. "
							echo "  See e.g. ${LOSTARGETDIR1} "
							echo "****************************************************"
							echo 
	
					fi 
				
				# MSBSA part 2
					echo "********************************************"
					echo "Processing MSBAS for ${MODE} part 2. "
					echo "  See ${LOSTARGETDIR2} "
					echo "********************************************"
					echo 
	

					RemovePairsFromModeList_WithImagesBefore.sh ${DEFOTXT} ${PART2START}	# will create a DefoInterpolx2Detrendi.txt_After${PART2START}_$RNDM.txt
	
					PART2MODELIST=$(ls -t ${DEFOTXT}_After${PART2START}_* | head -n 1)
					cp -f ${PART2MODELIST} DefoInterpolx2Detrend${MODENR}_After${PART2START}.txt
					PART2MODELIST=DefoInterpolx2Detrend${MODENR}_After${PART2START}.txt

					# trick the header file	
					${PATHGNU}/gsed -i "s/${DEFOTXT}/${PART2MODELIST}/" ${MSBASDIR}/header.txt			
					# ${MSBASDIR}/header.txt makes use of only one DefoInterpolx2Detrend${MODENR}_After${PART2START}.txt dataset for part 2 WITH or WITHOUT coh threshold applied in these lists depending if IFCOH = YES or NO
	
					NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART2_OVERLAP_${MIDOVERLAP} #${TIMESERIESPTS} # Do not compute TS
					cp -f ${MSBASDIR}/header_${MODE}.txt header.txt
					# back to ${MSBASDIR}/header.txt that makes use of only one DefoInterpolx2Detrendi.txt dataset WITH or WITHOUT coh threshold applied in these lists depending if IFCOH = YES or NO

					# Now that fresh msbas was computed, remove tag file attesting of offset applied to defo maps 
					rm -f ${LOSTARGETDIR2}/_Offset_applied.txt  2>/dev/null
						
				# Merge Part1 and 2
					echo "********************************************"
					echo " Apply offset to ${MODE} part 2. "
					echo "********************************************"
					echo 

					# Apply offset to defo maps in Part2 
						LOSOVERLAPMAP1=$(ls ${LOSTARGETDIR1}/MSBAS_${MIDOVERLAP}T*_LOS.bin)
						LOSOVERLAPMAP2=$(ls ${LOSTARGETDIR2}/MSBAS_${MIDOVERLAP}T*_LOS.bin)
							
						cd  ${LOSTARGETDIR2}
							# If the file _Offset_applied.txt does not exist then remove offset between part1 and 2
							if [ ! -f "_Offset_applied.txt" ] 
								then 
									Add_DefoMap_ToAllMapsInDir.py ${LOSOVERLAPMAP1} ${LOSOVERLAPMAP2}			
									echo "Offset applied on all part 2 maps in ${LOSTARGETDIR2} on ${TODAY}" > _Offset_applied.txt
								else 
									echo "Offset already applied ? please check. "
							fi
							
					cd ${MSBASDIR} 
					# link (or move ?) all defo maps part2 in common part from  MIDOVERLAP (not included)
					#ln -s ${LOSTARGETDIR2}/MSBAS_*T*_LOS.bin ${COMMONLOS}
					MIDOVERLAPSEC=$(date -d "${MIDOVERLAP:0:4}-${MIDOVERLAP:4:2}-${MIDOVERLAP:6:2}" +%s) # Convert to timestamp
					#for file in "${LOSTARGETDIR2}"/MSBAS_*T*_LOS.bin; do
					for file in $(find "${LOSTARGETDIR2}" -name "MSBAS_*T*.bin"); do
						# Extract the date from the filename
						filename=$(basename "$file")
						file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_LOS\.bin/\1/')
						
						if [ "${file_date_str}" != "" ] ; then 
							# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
							file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
							
							# Compare the file date with the cutoff date
							if [ "$file_date_ts" -gt "$MIDOVERLAPSEC" ]; then
							  	  MoveAndLinkBack "$file" "${COMMONLOS}"
							fi
						fi
					done

					echo "***************************************************************"
					echo " Rebuild LINEAR_RATE, STD and R2 maps of ${MODE} merged parts. "
					echo "***************************************************************"
					echo 
						
					# recompute mean velocity, stdv and R2 maps from merged defo maps 
					cd ${COMMONLOS}
					Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py

					CreateRasAndMv ${COMMONLOS} LOS

					cd ${MSBASDIR}	

					# Prepare for plots
					# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
	 				cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
						
				else 		
					NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
					
					cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
					# remove header line to avoid error message 
					#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
					while read -r DESCR X Y RX RY
						do	
							echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
							mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
							# there is no automatic plotting by msbas when only in LOS 
					done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 			fi
 			
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


# Check that there is no other cron (Step 2 or 3) or manual SuperMaster_MassProc.sh running
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
			# Check that no other SuperMaster_MassProc.sh automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
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
	#LASTASC=`ls -lt ${S1ASC}/Geocoded/DefoInterpolx2Detrend | head -n 2 | tail -n 1 | sed 's/.* //'` # may be messing up if txt files are created for any other purpose in the dir... 
	#LASTDESC=`ls -lt ${S1DESC}/Geocoded/DefoInterpolx2Detrend | head -n 2 | tail -n 1 | sed 's/.* //'`
	LASTASC=`find ${S1ASC}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LASTDESC=`find ${S1DESC}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

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
	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
		cd ${MSBASDIR}
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATHTOMASPROCESSDIR} &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATHTOMASPROCESSDIR} &
		wait
		echo "All lines in former existing MODEi.txt are ok"
		echo ""
	
		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1_Full ${PATHTOMASPROCESSDIR} &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2_Full ${PATHTOMASPROCESSDIR} &
			wait
			echo "All lines in former existing MODEi_Full.txt are ok"
			echo ""	
		fi
	
	fi

# Prepare MSBAS
###############
	${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_criteria.sh DefoInterpolx2Detrend 2 ${BP} ${BT} ${S1ASC} ${S1DESC} 

	# update here the R_FLAG if needed
	${PATHGNU}/gsed -i "s/R_FLAG = 2, 0.02/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt
	# because interferos are detreneded, i.e. averaged to zero, there is no need to calibrate again 
	${PATHGNU}/gsed -i 's/C_FLAG = 10/C_FLAG = 0/' ${MSBASDIR}/header.txt
	# Here, ${MSBASDIR}/header.txt makes use of DefoInterpolx2Detrendi.txt datasets

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
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATHTOMASPROCESSDIR} &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATHTOMASPROCESSDIR} &
			wait
			echo "All lines in new MODEi.txt should be ok"
			echo ""	
		fi
		
	# Remove some dates if needed
	if [ "${DATERESTRIC1}" == "YES" ] ; then 
		RemoveDates	"1"	"${REMOVEBETWEEN1}" "${REMOVEBEFORE1}" "${REMOVEAFTER1}"
		# that is ; mode 1, NO remove between dates, remove before 20150601, do not remove after a given date
	fi
	if [ "${DATERESTRIC2}" == "YES" ] ; then
		RemoveDates "2"	"${REMOVEBETWEEN2}" "${REMOVEBEFORE2}" "${REMOVEAFTER2}"
		# that is ; mode 1, NO remove between dates, remove before 20150601, do not remove after a given date
	fi


# Let's go
##########
	cd ${MSBASDIR}
	cp -f header.txt header_back.txt 
	# ${MSBASDIR}/header.txt and header_back.txt make use of DefoInterpolx2Detrendi.txt datasets and there is No coh threshold applied in these lists

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
					mkdir -p ${MSBASDIR}/DefoInterpolx2Detrend1_Full
					cp -R ${MSBASDIR}/DefoInterpolx2Detrend1/* ${MSBASDIR}/DefoInterpolx2Detrend1_Full/
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
				
					mkdir -p ${MSBASDIR}/DefoInterpolx2Detrend2_Full
					cp -R ${MSBASDIR}/DefoInterpolx2Detrend2/* ${MSBASDIR}/DefoInterpolx2Detrend2_Full/
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
				
					cp -R -n ${MSBASDIR}/DefoInterpolx2Detrend1/* ${MSBASDIR}/DefoInterpolx2Detrend1_Full/
					cp -R -n ${MSBASDIR}/DefoInterpolx2Detrend2/* ${MSBASDIR}/DefoInterpolx2Detrend2_Full/
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
					cp -f ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
				
					rm -f ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt 
					rm -f ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt
					
					# because ${MSBASDIR}/DefoInterpolx2Detrendi_Full.txt was built with unclneaned ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt, let's clean it again
					echo "Remove again lines in MSBAS/MODEi_Full.txt file associated to possible broken links or duplicated lines"
					_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1_Full ${PATHTOMASPROCESSDIR} &
					_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2_Full ${PATHTOMASPROCESSDIR} &
					wait
					echo "All lines in new MODEi_Full.txt should be ok"
					;;	
			esac
	
			# SPLIT HERE (without coh threshold but coh threshold will be done later)
			if [ ${SPLIT} == "YES" ] 
				then 
					# the following will be created by MSBAS.sh hereafter
					UDTARGETDIR1="${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_PART1_OVERLAP_${MIDOVERLAPASC}"
					EWTARGETDIR1="${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_PART1_OVERLAP_${MIDOVERLAPASC}"

					UDTARGETDIR2="${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_PART2_OVERLAP_${MIDOVERLAPASC}"
					EWTARGETDIR2="${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_PART2_OVERLAP_${MIDOVERLAPASC}"

					# Dir where part 1 and 2 will be merged
					COMMONUD=${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh
					COMMONEW=${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh
					mkdir -p ${COMMONUD}
					mkdir -p ${COMMONEW}

			
					# MSBSA part 1 - IF DIR UDTARGETDIR1 and EWTARGETDIR1 DO NOT EXIST YET OR ARE EMPTY, 
					# then process part 1. If already done, skip 
						if [ ! -d "${UDTARGETDIR1}" ] || [ -z "$(ls -A "${UDTARGETDIR1}")" ] || [ ! -d "${EWTARGETDIR1}" ] || [ -z "$(ls -A "${EWTARGETDIR1}")" ]
							then 
								echo "********************************************************************"
								echo "MSBAS without Coh Threshold for part 1 not process yet; run it now. "
								echo "  See ${UDTARGETDIR1} "
								echo " Processing with Coh Threshold will be performed after. "
								echo "********************************************************************"
								echo 

								RemovePairsFromModeList_WithImagesAfter.sh DefoInterpolx2Detrend1_Full.txt ${PART1END}	# will create a DefoInterpolx2Detrend1_Full.txt_Below${PART1END}_$RNDM.txt
								RemovePairsFromModeList_WithImagesAfter.sh DefoInterpolx2Detrend2_Full.txt ${PART1END}	# will create a DefoInterpolx2Detrend1_Full.txt_Below${PART1END}_$RNDM.txt
			
								PART1MODE1LIST=$(ls -t DefoInterpolx2Detrend1_Full.txt_Below${PART1END}_* | head -n 1)
								PART1MODE2LIST=$(ls -t DefoInterpolx2Detrend2_Full.txt_Below${PART1END}_* | head -n 1)
								cp -f ${PART1MODE1LIST} DefoInterpolx2Detrend1_Full_Below${PART1END}.txt
								cp -f ${PART1MODE2LIST} DefoInterpolx2Detrend2_Full_Below${PART1END}.txt
								PART1MODE1LIST=DefoInterpolx2Detrend1_Full_Below${PART1END}.txt
								PART1MODE2LIST=DefoInterpolx2Detrend2_Full_Below${PART1END}.txt
			
								# trick the header file						
								${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend1.txt/${PART1MODE1LIST}/" ${MSBASDIR}/header.txt
								${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend2.txt/${PART1MODE2LIST}/" ${MSBASDIR}/header.txt
								# ${MSBASDIR}/header.txt makes use of DefoInterpolx2Detrendi_Full_Below${PART1END}.txt dataset, ie. part 1 with No coh threshold applied in these lists

			
								NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_PART1_OVERLAP_${MIDOVERLAPASC}	#${TIMESERIESPTS} # Do not compute TS
								cp -f header_back.txt header.txt 
								# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets with No coh threshold applied in these lists

								# link (or move ?) all defo maps in common part  till MIDOVERLAPASC (included)
								#ln -s ${UDTARGETDIR1}/MSBAS_*T*_UD.bin ${COMMONUD}
								#ln -s ${EWTARGETDIR1}/MSBAS_*T*_EW.bin ${COMMONEW}
								MIDOVERLAPSEC=$(date -d "${MIDOVERLAPASC:0:4}-${MIDOVERLAPASC:4:2}-${MIDOVERLAPASC:6:2}" +%s) # Convert to timestamp
								#for file in "${UDTARGETDIR1}"/MSBAS_*T*_UD.bin; do
								for file in $(find "${UDTARGETDIR1}" -name "MSBAS_*T*.bin"); do
								  # Extract the date from the filename
								  filename=$(basename "$file")
								  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_UD\.bin/\1/')
								  
								  if [ "${file_date_str}" != "" ] ; then 
								  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
								  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
									
								  	# Compare the file date with the cutoff date
								  	if [ "$file_date_ts" -le "$MIDOVERLAPSEC" ]; then
								  		MoveAndLinkBack "$file" "${COMMONUD}"
								  	fi
								  fi
								done
								#for file in "${EWTARGETDIR1}"/MSBAS_*T*_EW.bin; do
								for file in $(find "${EWTARGETDIR1}" -name "MSBAS_*T*.bin"); do
								  # Extract the date from the filename
								  filename=$(basename "$file")
								  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_EW\.bin/\1/')
								  
								  if [ "${file_date_str}" != "" ] ; then 
								  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
								  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
									
								  	# Compare the file date with the cutoff date
								  	if [ "$file_date_ts" -le "$MIDOVERLAPSEC" ]; then
							  	       MoveAndLinkBack "$file" "${COMMONEW}"
								  	fi
								  fi
								done

								# Make baseline plot 
	 							PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${PART1MODE1LIST}
	 							PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${PART1MODE2LIST}


							else 
								echo "********************************************"
								echo "MSBAS for part 1 already process ; skip it. "
								echo "  See e.g. ${UDTARGETDIR1} and same for EW"
								echo "********************************************"
	
						fi 
					
					# MSBSA part 2
						echo "********************************************************"
						echo "MSBAS for part 2 without Coh Threshold. "
						echo "  See eg ${UDTARGETDIR2} "
						echo " Processing with Coh Threshold will be performed after. "
						echo "********************************************************"
						echo 
	
						RemovePairsFromModeList_WithImagesBefore.sh DefoInterpolx2Detrend1_Full.txt ${PART2START}	# will create a DefoInterpolx2Detrend1_Full.txt_After${PART2START}_$RNDM.txt
						RemovePairsFromModeList_WithImagesBefore.sh DefoInterpolx2Detrend2_Full.txt ${PART2START}	# will create a DefoInterpolx2Detrend1_Full.txt_After${PART2START}_$RNDM.txt
	
						PART2MODE1LIST=$(ls -t DefoInterpolx2Detrend1_Full.txt_After${PART2START}_* | head -n 1)
						PART2MODE2LIST=$(ls -t DefoInterpolx2Detrend2_Full.txt_After${PART2START}_* | head -n 1)
						cp -f ${PART2MODE1LIST} DefoInterpolx2Detrend1_Full_After${PART2START}.txt
						cp -f ${PART2MODE2LIST} DefoInterpolx2Detrend2_Full_After${PART2START}.txt
						PART2MODE1LIST=DefoInterpolx2Detrend1_Full_After${PART2START}.txt
						PART2MODE2LIST=DefoInterpolx2Detrend2_Full_After${PART2START}.txt
					
	
						# trick the header file						
						${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend1.txt/${PART2MODE1LIST}/" ${MSBASDIR}/header.txt
						${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend2.txt/${PART2MODE2LIST}/" ${MSBASDIR}/header.txt
						# ${MSBASDIR}/header.txt makes use of DefoInterpolx2Detrendi_Full_After${PART2START}.txt dataset, ie. part 2 with No coh threshold applied in these lists
	
						NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh_PART2_OVERLAP_${MIDOVERLAPASC}  #${TIMESERIESPTS} # Do not compute TS
						# Now that fresh msbas was computed, remove tag file attesting of offset applied to defo maps 
						rm -f ${UDTARGETDIR2}/_Offset_applied.txt  2>/dev/null
						rm -f ${EWTARGETDIR2}/_Offset_applied.txt  2>/dev/null
						
						cp -f header_back.txt header.txt 
						# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets with No coh threshold applied in these lists
	
						# Make baseline plot 
	 					PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${PART2MODE1LIST}
	 					PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${PART2MODE2LIST}
	 					
						# also baselineplot of combined parts
						PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
						PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt

					# Merge Part1 and 2
						echo "*******************************************************"
						echo " Apply offset to UD/EW part 2 (without Coh Threshold). "
						echo " Processing with Coh Threshold will be performed after. "
						echo "*******************************************************"
						echo 

						# Apply offset to defo maps in Part2 
							#UD
								# Defo map at date ${MIDOVERLAPASC} in both parts used to compute offset map
								UDOVERLAPMAP1=$(ls ${UDTARGETDIR1}/MSBAS_${MIDOVERLAPASC}T*_UD.bin)
								UDOVERLAPMAP2=$(ls ${UDTARGETDIR2}/MSBAS_${MIDOVERLAPASC}T*_UD.bin)
							
								cd  ${UDTARGETDIR2}
									# If the file _Offset_applied.txt does not exist then remove offset between part1 and 2
									if [ ! -f "_Offset_applied.txt" ] 
										then 
											Add_DefoMap_ToAllMapsInDir.py ${UDOVERLAPMAP1} ${UDOVERLAPMAP2}			
											echo "Offset applied on all UD part 2 maps in ${UDTARGETDIR2} on ${TODAY}" > _Offset_applied.txt
										else 
											echo "Offset already applied ? please check. "
									fi
							# EW
								# Defo map at date ${MIDOVERLAPASC} in both parts used to compute offset map
								EWOVERLAPMAP1=$(ls ${EWTARGETDIR1}/MSBAS_${MIDOVERLAPASC}T*_EW.bin)
								EWOVERLAPMAP2=$(ls ${EWTARGETDIR2}/MSBAS_${MIDOVERLAPASC}T*_EW.bin)
							
								cd  ${EWTARGETDIR2}
									# If the file _Offset_applied.txt does not exist then remove offset between part1 and 2
									if [ ! -f "_Offset_applied.txt" ] 
										then 
											Add_DefoMap_ToAllMapsInDir.py ${EWOVERLAPMAP1} ${EWOVERLAPMAP2}			
											echo "Offset applied on all EW part 2 maps in ${EWTARGETDIR2} on ${TODAY}" > _Offset_applied.txt
										else 
											echo "Offset already applied ? please check. "
									fi

						cd ${MSBASDIR} 
						# link (or move ?) all defo maps part2 in common part from MIDOVERLAPASC (excluded)
							#ln -s ${UDTARGETDIR2}/MSBAS_*T*_UD.bin ${COMMONUD}
							#ln -s ${EWTARGETDIR2}/MSBAS_*T*_EW.bin ${COMMONEW}
							MIDOVERLAPSEC=$(date -d "${MIDOVERLAPASC:0:4}-${MIDOVERLAPASC:4:2}-${MIDOVERLAPASC:6:2}" +%s) # Convert to timestamp
							#for file in "${UDTARGETDIR2}"/MSBAS_*T*_UD.bin; do
							for file in $(find "${UDTARGETDIR2}" -name "MSBAS_*T*.bin"); do
							  # Extract the date from the filename
							  filename=$(basename "$file")
							  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_UD\.bin/\1/')
							  
  							  if [ "${file_date_str}" != "" ] ; then 
							  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
							  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
								
							  	# Compare the file date with the cutoff date
							  	if [ "$file_date_ts" -gt "$MIDOVERLAPSEC" ]; then
							  		MoveAndLinkBack "$file" "${COMMONUD}"
							  	fi
							  fi
							done
							#for file in "${EWTARGETDIR2}"/MSBAS_*T*_EW.bin; do
							for file in $(find "${EWTARGETDIR2}" -name "MSBAS_*T*.bin"); do
							  # Extract the date from the filename
							  filename=$(basename "$file")
							  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_EW\.bin/\1/')
							  
							  if [ "${file_date_str}" != "" ] ; then 
							  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
							  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
								
							  	# Compare the file date with the cutoff date
							  	if [ "$file_date_ts" -gt "$MIDOVERLAPSEC" ]; then
							  		MoveAndLinkBack "$file" "${COMMONEW}"
							  	fi
							  fi
							done

						echo "***************************************************************"
						echo " Rebuild LINEAR_RATE, STD and R2 maps of EW/UD merged parts. "
						echo "    without Coh Threshold. "
						echo " Processing with Coh Threshold will be performed after. "
						echo "***************************************************************"
						echo 

						# recompute mean velocity, stdv and R2 maps from merged defo maps 
							cd ${COMMONUD}
							Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py &
							cd ${COMMONEW}
							Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py &
							
							wait

							cd ${COMMONUD}
							CreateRasAndMv ${COMMONUD} UD
							
							cd ${COMMONEW}
							CreateRasAndMv ${COMMONEW} EW
							
						cd ${MSBASDIR}	

						# Prepare for plots
						# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
	 					cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
						
				else # i.e if no split
					# trick the header file						
					${PATHGNU}/gsed -i 's/DefoInterpolx2Detrend1.txt/DefoInterpolx2Detrend1_Full.txt/' ${MSBASDIR}/header.txt
					${PATHGNU}/gsed -i 's/DefoInterpolx2Detrend2.txt/DefoInterpolx2Detrend2_Full.txt/' ${MSBASDIR}/header.txt
					# ${MSBASDIR}/header.txt makes use of DefoInterpolx2Detrendi_Full.txt datasets and there is No coh threshold applied in these lists

		 			NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${TIMESERIESPTS}

					cp -f header_back.txt header.txt
					# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets with No coh threshold applied in these lists
					
					# Make baseline plot 
	 				PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
	 				PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt

					# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
	 				cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
			
					while read -r DESCR X Y RX RY
	 				do	
	 						echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
	 						mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
	 						mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
	 				done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header

			fi
		 

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
			# SPLIT HERE (without coh threshold)
			if [ ${SPLIT} == "YES" ] 
				then 
					# the following will be created by MSBAS.sh hereafter
					UDTARGETDIR1="${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART1_OVERLAP_${MIDOVERLAPASC}"
					EWTARGETDIR1="${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART1_OVERLAP_${MIDOVERLAPASC}"

					UDTARGETDIR2="${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART2_OVERLAP_${MIDOVERLAPASC}"
					EWTARGETDIR2="${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART2_OVERLAP_${MIDOVERLAPASC}"

					# Dir where part 1 and 2 will be merged
					COMMONUD=${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}
					COMMONEW=${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}
					mkdir -p ${COMMONUD}
					mkdir -p ${COMMONEW}
					
					# MSBSA part 1 - IF DIR UDTARGETDIR1 and EWTARGETDIR1 DO NOT EXIST YET OR ARE EMPTY, 
					# then process part 1. If already done, skip 
						if [ ! -d "${UDTARGETDIR1}" ] || [ -z "$(ls -A "${UDTARGETDIR1}")" ] || [ ! -d "${EWTARGETDIR1}" ] || [ -z "$(ls -A "${EWTARGETDIR1}")" ]
							then 
								echo "********************************************************************"
								echo "MSBAS without Coh Threshold for part 1 not process yet; run it now. "
								echo "  See ${UDTARGETDIR1} "
								echo "********************************************************************"
								echo 

								RemovePairsFromModeList_WithImagesAfter.sh DefoInterpolx2Detrend1.txt ${PART1END}	# will create a DefoInterpolx2Detrend1.txt_Below${PART1END}_$RNDM.txt
								RemovePairsFromModeList_WithImagesAfter.sh DefoInterpolx2Detrend2.txt ${PART1END}	# will create a DefoInterpolx2Detrend1.txt_Below${PART1END}_$RNDM.txt
			
								PART1MODE1LIST=$(ls -t DefoInterpolx2Detrend1.txt_Below${PART1END}_* | head -n 1)
								PART1MODE2LIST=$(ls -t DefoInterpolx2Detrend2.txt_Below${PART1END}_* | head -n 1)
								cp -f ${PART1MODE1LIST} DefoInterpolx2Detrend1_Below${PART1END}.txt
								cp -f ${PART1MODE2LIST} DefoInterpolx2Detrend2_Below${PART1END}.txt
								PART1MODE1LIST=DefoInterpolx2Detrend1_Below${PART1END}.txt
								PART1MODE2LIST=DefoInterpolx2Detrend2_Below${PART1END}.txt
			
								# trick the header file						
								${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend1.txt/${PART1MODE1LIST}/" ${MSBASDIR}/header.txt
								${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend2.txt/${PART1MODE2LIST}/" ${MSBASDIR}/header.txt
								# ${MSBASDIR}/header.txt makes use of DefoInterpolx2Detrendi_Below${PART1END}.txt datasets and there is No coh threshold applied in these lists
			
								NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_PART1_OVERLAP_${MIDOVERLAPASC}	#${TIMESERIESPTS} # Do not compute TS
								cp -f header_back.txt header.txt 
								# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets with No coh threshold applied in these lists

								# link (or move ?) all defo maps in common part till MIDOVERLAP (included)
								#ln -s ${UDTARGETDIR1}/MSBAS_*T*_UD.bin ${COMMONUD}
								#ln -s ${EWTARGETDIR1}/MSBAS_*T*_EW.bin ${COMMONEW}
								MIDOVERLAPSEC=$(date -d "${MIDOVERLAPASC:0:4}-${MIDOVERLAPASC:4:2}-${MIDOVERLAPASC:6:2}" +%s) # Convert to timestamp
								#for file in "${UDTARGETDIR1}"/MSBAS_*T*_UD.bin; do
								for file in $(find "${UDTARGETDIR1}" -name "MSBAS_*T*.bin"); do
								  # Extract the date from the filename
								  filename=$(basename "$file")
								  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_UD\.bin/\1/')
								  
								  if [ "${file_date_str}" != "" ] ; then 
								  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
								  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
									
								  	# Compare the file date with the cutoff date
								  	if [ "$file_date_ts" -le "$MIDOVERLAPSEC" ]; then
							  	       MoveAndLinkBack "$file" "${COMMONUD}"
								  	fi
								  fi
								done
								#for file in "${EWTARGETDIR1}"/MSBAS_*T*_EW.bin; do
								for file in $(find "${EWTARGETDIR1}" -name "MSBAS_*T*.bin"); do
								  # Extract the date from the filename
								  filename=$(basename "$file")
								  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_EW\.bin/\1/')
								  
								  if [ "${file_date_str}" != "" ] ; then 
								  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
								  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
									
								  	# Compare the file date with the cutoff date
								  	if [ "$file_date_ts" -le "$MIDOVERLAPSEC" ]; then
							  	       MoveAndLinkBack "$file" "${COMMONEW}"
								  	fi
								  fi
								done
	
								# Make baseline plot 
	 							PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${PART1MODE1LIST}
	 							PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${PART1MODE2LIST}

							else 
								echo "********************************************"
								echo "MSBAS for part 1 already process ; skip it. "
								echo "  See e.g. ${UDTARGETDIR1} and same for EW"
								echo "********************************************"
	
						fi 
					
					# MSBSA part 2
						echo "********************************************************"
						echo "MSBAS for part 2 without Coh Threshold. "
						echo "  See eg ${UDTARGETDIR2} "
						echo "********************************************************"
						echo 

						RemovePairsFromModeList_WithImagesBefore.sh DefoInterpolx2Detrend1.txt ${PART2START}	# will create a DefoInterpolx2Detrend1.txt_After${PART2START}_$RNDM.txt
						RemovePairsFromModeList_WithImagesBefore.sh DefoInterpolx2Detrend2.txt ${PART2START}	# will create a DefoInterpolx2Detrend1.txt_After${PART2START}_$RNDM.txt
	
						PART2MODE1LIST=$(ls -t DefoInterpolx2Detrend1.txt_After${PART2START}_* | head -n 1)
						PART2MODE2LIST=$(ls -t DefoInterpolx2Detrend2.txt_After${PART2START}_* | head -n 1)
						cp -f ${PART2MODE1LIST} DefoInterpolx2Detrend1_After${PART2START}.txt
						cp -f ${PART2MODE2LIST} DefoInterpolx2Detrend2_After${PART2START}.txt
						PART2MODE1LIST=DefoInterpolx2Detrend1_After${PART2START}.txt
						PART2MODE2LIST=DefoInterpolx2Detrend2_After${PART2START}.txt
	
						# trick the header file						
						${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend1.txt/${PART2MODE1LIST}/" ${MSBASDIR}/header.txt
						${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend2.txt/${PART2MODE2LIST}/" ${MSBASDIR}/header.txt
						# ${MSBASDIR}/header.txt makes use of DefoInterpolx2Detrendi_After${PART2START}.txt datasets and there is No coh threshold applied in these lists
	
						NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_PART2_OVERLAP_${MIDOVERLAPASC}  #${TIMESERIESPTS} # Do not compute TS
						# Now that fresh msbas was computed, remove tag file attesting of offset applied to defo maps 
						rm -f ${UDTARGETDIR2}/_Offset_applied.txt  2>/dev/null
						rm -f ${EWTARGETDIR2}/_Offset_applied.txt  2>/dev/null
						
						cp -f header_back.txt header.txt 
						# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets with No coh threshold applied in these lists
	
						# Make baseline plot
	 					PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${PART2MODE1LIST}
	 					PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${PART2MODE2LIST}

						# also baselineplot of combined parts
						PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1.txt
						PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2.txt


					# Merge Part1 and 2
						echo "*******************************************************"
						echo " Apply offset to UD/EW part 2 (without Coh Threshold). "
						echo "*******************************************************"
						echo 
						# Apply offset to defo maps in Part2 
							#UD
								# Defo map at date ${MIDOVERLAPASC} in both parts used to compute offset map
								UDOVERLAPMAP1=$(ls ${UDTARGETDIR1}/MSBAS_${MIDOVERLAPASC}T*_UD.bin)
								UDOVERLAPMAP2=$(ls ${UDTARGETDIR2}/MSBAS_${MIDOVERLAPASC}T*_UD.bin)
							
								cd  ${UDTARGETDIR2}
									# If the file _Offset_applied.txt does not exist then remove offset between part1 and 2
									if [ ! -f "_Offset_applied.txt" ] 
										then 
											Add_DefoMap_ToAllMapsInDir.py ${UDOVERLAPMAP1} ${UDOVERLAPMAP2}			
											echo "Offset applied on all UD part 2 maps in ${UDTARGETDIR2} on ${TODAY}" > _Offset_applied.txt
										else 
											echo "Offset already applied ? please check. "
									fi
							# EW
								# Defo map at date ${MIDOVERLAPASC} in both parts used to compute offset map
								EWOVERLAPMAP1=$(ls ${EWTARGETDIR1}/MSBAS_${MIDOVERLAPASC}T*_EW.bin)
								EWOVERLAPMAP2=$(ls ${EWTARGETDIR2}/MSBAS_${MIDOVERLAPASC}T*_EW.bin)
							
								cd  ${EWTARGETDIR2}
									# If the file _Offset_applied.txt does not exist then remove offset between part1 and 2
									if [ ! -f "_Offset_applied.txt" ] 
										then 
											Add_DefoMap_ToAllMapsInDir.py ${EWOVERLAPMAP1} ${EWOVERLAPMAP2}			
											echo "Offset applied on all EW part 2 maps in ${EWTARGETDIR2} on ${TODAY}" > _Offset_applied.txt
										else 
											echo "Offset already applied ? please check. "
									fi

						cd ${MSBASDIR} 
						# link (or move ?) all defo maps part2 in common part from MIDOVERLAP (excluded)
							#ln -s ${UDTARGETDIR2}/MSBAS_*T*_UD.bin ${COMMONUD}
							#ln -s ${EWTARGETDIR2}/MSBAS_*T*_EW.bin ${COMMONEW}
							MIDOVERLAPSEC=$(date -d "${MIDOVERLAPASC:0:4}-${MIDOVERLAPASC:4:2}-${MIDOVERLAPASC:6:2}" +%s) # Convert to timestamp
							#for file in "${UDTARGETDIR2}"/MSBAS_*T*_UD.bin; do # wrong because it will take the LINEAR_RATE files as well
							for file in $(find "${UDTARGETDIR2}" -name "MSBAS_*T*.bin"); do
							  # Extract the date from the filename
							  filename=$(basename "$file")
							  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_UD\.bin/\1/')
							  
							  if [ "${file_date_str}" != "" ] ; then
							  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
							  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
								
							  	# Compare the file date with the cutoff date
							  	if [ "$file_date_ts" -gt "$MIDOVERLAPSEC" ]; then
							  		MoveAndLinkBack "$file" "${COMMONUD}"
							  	fi
							  fi
							done
							#for file in "${EWTARGETDIR2}"/MSBAS_*T*_EW.bin; do
							for file in $(find "${EWTARGETDIR2}" -name "MSBAS_*T*.bin"); do
							  # Extract the date from the filename
							  filename=$(basename "$file")
							  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_EW\.bin/\1/')
							  
							  if [ "${file_date_str}" != "" ] ; then
							  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
							  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
								
							  	# Compare the file date with the cutoff date
							  	if [ "$file_date_ts" -gt "$MIDOVERLAPSEC" ]; then
							  		MoveAndLinkBack "$file" "${COMMONEW}"
							  	fi
							  fi
							done

						echo "***************************************************************"
						echo " Rebuild LINEAR_RATE, STD and R2 maps of EW/UD merged parts. "
						echo "    without Coh Threshold. "
						echo "***************************************************************"
						echo 

						# recompute mean velocity, stdv and R2 maps from merged defo maps 
							cd ${COMMONUD}
							Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py &
							cd ${COMMONEW}
							Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py &
	
							wait

							cd ${COMMONUD}
							CreateRasAndMv ${COMMONUD} UD

							cd ${COMMONEW}
							CreateRasAndMv ${COMMONEW} EW
							
						cd ${MSBASDIR}	

						# Prepare for plots
						# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
	 					cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
				else # i. no split
					NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}

					# Make baseline plot 
					PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1.txt
					PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2.txt
		
					# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
					cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		
					while read -r DESCR X Y RX RY
						do	
							echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
							mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
							mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
					done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
						
			fi

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
			# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets with No coh threshold applied in these lists

			# run restrict_msbas_to_Coh.sh         
			restrict_msbas_to_Coh.sh DefoInterpolx2Detrend1 ${COHRESTRICT} ${KMLCOH} ${S1ASC}/Geocoded/Coh
			restrict_msbas_to_Coh.sh DefoInterpolx2Detrend2 ${COHRESTRICT} ${KMLCOH} ${S1DESC}/Geocoded/Coh
			# Now ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets WITH coh threshold applied in these lists
			
			# Force additional pairs exclusion 
			if [ ${EXCLUDE1} == "YES" ] ; then 
				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend1
			fi 
			if [ ${EXCLUDE2} == "YES" ] ; then 
				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend2
			fi 

			if [ ${SPLIT} == "YES" ] 
				then 
					# the following will be created by MSBAS.sh hereafter
					UDTARGETDIR1="${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART1_OVERLAP_${MIDOVERLAPASC}"
					EWTARGETDIR1="${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART1_OVERLAP_${MIDOVERLAPASC}"

					UDTARGETDIR2="${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART2_OVERLAP_${MIDOVERLAPASC}"
					EWTARGETDIR2="${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}_PART2_OVERLAP_${MIDOVERLAPASC}"

					# Dir where part 1 and 2 will be merged
					COMMONUD=${MSBASDIR}/zz_UD_Auto_${ORDER}_${LAMBDA}_${LABEL}
					COMMONEW=${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}
					mkdir -p ${COMMONUD}
					mkdir -p ${COMMONEW}

			
					# MSBSA part 1 - IF DIR UDTARGETDIR1 and EWTARGETDIR1 DO NOT EXIST YET OR ARE EMPTY, 
					# then process part 1. If already done, skip 
						if [ ! -d "${UDTARGETDIR1}" ] || [ -z "$(ls -A "${UDTARGETDIR1}")" ] || [ ! -d "${EWTARGETDIR1}" ] || [ -z "$(ls -A "${EWTARGETDIR1}")" ]
							then 
								echo "********************************************************************"
								echo "MSBAS with Coh Threshold for part 1 not process yet; run it now. "
								echo "  See ${UDTARGETDIR1} "
								echo "********************************************************************"
								echo 


								RemovePairsFromModeList_WithImagesAfter.sh DefoInterpolx2Detrend1.txt ${PART1END}	# will create a DefoInterpolx2Detrend1.txt_Below${PART1END}_$RNDM.txt
								RemovePairsFromModeList_WithImagesAfter.sh DefoInterpolx2Detrend2.txt ${PART1END}	# will create a DefoInterpolx2Detrend1.txt_Below${PART1END}_$RNDM.txt
			
								PART1MODE1LIST=$(ls -t DefoInterpolx2Detrend1.txt_Below${PART1END}_* | head -n 1)
								PART1MODE2LIST=$(ls -t DefoInterpolx2Detrend2.txt_Below${PART1END}_* | head -n 1)
								cp -f ${PART1MODE1LIST} DefoInterpolx2Detrend1_Below${PART1END}.txt
								cp -f ${PART1MODE2LIST} DefoInterpolx2Detrend2_Below${PART1END}.txt
								PART1MODE1LIST=DefoInterpolx2Detrend1_Below${PART1END}.txt
								PART1MODE2LIST=DefoInterpolx2Detrend2_Below${PART1END}.txt
			
								# trick the header file						
								${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend1.txt/${PART1MODE1LIST}/" ${MSBASDIR}/header.txt
								${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend2.txt/${PART1MODE2LIST}/" ${MSBASDIR}/header.txt
								# Now ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi_Below${PART1END}.txt datasets WITH coh threshold applied in these lists
			
								NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_PART1_OVERLAP_${MIDOVERLAPASC}	#${TIMESERIESPTS} # Do not compute TS
								cp -f header_back.txt header.txt 
								# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets WITH coh threshold applied in these lists

								# link (or move ?) all defo maps in common part till MIDOVERLAP (included)
								#ln -s ${UDTARGETDIR1}/MSBAS_*T*_UD.bin ${COMMONUD}
								#ln -s ${EWTARGETDIR1}/MSBAS_*T*_EW.bin ${COMMONEW}
								MIDOVERLAPSEC=$(date -d "${MIDOVERLAPASC:0:4}-${MIDOVERLAPASC:4:2}-${MIDOVERLAPASC:6:2}" +%s) # Convert to timestamp
								#for file in "${UDTARGETDIR1}"/MSBAS_*T*_UD.bin; do
								for file in $(find "${UDTARGETDIR1}" -name "MSBAS_*T*.bin"); do
								  # Extract the date from the filename
								  filename=$(basename "$file")
								  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_UD\.bin/\1/')
								  
								  if [ "${file_date_str}" != "" ] ; then 
								  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
								  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
									
								  	# Compare the file date with the cutoff date
								  	if [ "$file_date_ts" -le "$MIDOVERLAPSEC" ]; then
							  	       MoveAndLinkBack "$file" "${COMMONUD}"
								  	fi
								  fi
								done
								#for file in "${EWTARGETDIR1}"/MSBAS_*T*_EW.bin; do
								for file in $(find "${EWTARGETDIR1}" -name "MSBAS_*T*.bin"); do
								  # Extract the date from the filename
								  filename=$(basename "$file")
								  file_date_str=$(echo "$filename" | grep -v LINEAR | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_EW\.bin/\1/')
								  
								  if [ "${file_date_str}" != "" ] ; then 
								  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
								  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
									
								  	# Compare the file date with the cutoff date
								  	if [ "$file_date_ts" -le "$MIDOVERLAPSEC" ]; then
							  	       MoveAndLinkBack "$file" "${COMMONEW}"
								  	fi
								  fi
								done
								# Make baseline plot 
	 							PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${PART1MODE1LIST}
	 							PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${PART1MODE2LIST}

							else 
								echo "********************************************"
								echo "MSBAS for part 1 already process ; skip it. "
								echo "  See e.g. ${UDTARGETDIR1} and same for EW"
								echo "********************************************"
	
						fi 
					
					# MSBSA part 2
						echo "********************************************************"
						echo "MSBAS for part 2 with Coh Threshold. "
						echo "  See eg ${UDTARGETDIR2} "
						echo "********************************************************"
						echo 

						RemovePairsFromModeList_WithImagesBefore.sh DefoInterpolx2Detrend1.txt ${PART2START}	# will create a DefoInterpolx2Detrend1.txt_After${PART2START}_$RNDM.txt
						RemovePairsFromModeList_WithImagesBefore.sh DefoInterpolx2Detrend2.txt ${PART2START}	# will create a DefoInterpolx2Detrend1.txt_After${PART2START}_$RNDM.txt
	
						PART2MODE1LIST=$(ls -t DefoInterpolx2Detrend1.txt_After${PART2START}_* | head -n 1)
						PART2MODE2LIST=$(ls -t DefoInterpolx2Detrend2.txt_After${PART2START}_* | head -n 1)
						cp -f ${PART2MODE1LIST} DefoInterpolx2Detrend1_After${PART2START}.txt
						cp -f ${PART2MODE2LIST} DefoInterpolx2Detrend2_After${PART2START}.txt
						PART2MODE1LIST=DefoInterpolx2Detrend1_After${PART2START}.txt
						PART2MODE2LIST=DefoInterpolx2Detrend2_After${PART2START}.txt
	
						# trick the header file						
						${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend1.txt/${PART2MODE1LIST}/" ${MSBASDIR}/header.txt
						${PATHGNU}/gsed -i "s/DefoInterpolx2Detrend2.txt/${PART2MODE2LIST}/" ${MSBASDIR}/header.txt
						# Now ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi_After${PART2START}.txt datasets WITH coh threshold applied in these lists
	
						NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_PART2_OVERLAP_${MIDOVERLAPASC}  #${TIMESERIESPTS} # Do not compute TS
						# Now that fresh msbas was computed, remove tag file attesting of offset applied to defo maps 
						rm -f ${UDTARGETDIR2}/_Offset_applied.txt  2>/dev/null
						rm -f ${EWTARGETDIR2}/_Offset_applied.txt  2>/dev/null
						
						cp -f header_back.txt header.txt 
						# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets WITH coh threshold applied in these lists

						# Make baseline plot 
	 					PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/${PART2MODE1LIST}
	 					PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/${PART2MODE2LIST}

						# also baselineplot of combined parts
						PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1.txt
						PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2.txt


					# Merge Part1 and 2
						echo "*******************************************************"
						echo " Apply offset to UD/EW part 2 (with Coh Threshold). "
						echo "*******************************************************"
						echo 

						# Apply offset to defo maps in Part2 
							#UD
								# Defo map at date ${MIDOVERLAPASC} in both parts used to compute offset map
								UDOVERLAPMAP1=$(ls ${UDTARGETDIR1}/MSBAS_${MIDOVERLAPASC}T*_UD.bin)
								UDOVERLAPMAP2=$(ls ${UDTARGETDIR2}/MSBAS_${MIDOVERLAPASC}T*_UD.bin)
							
								cd  ${UDTARGETDIR2}
									# If the file _Offset_applied.txt does not exist then remove offset between part1 and 2
									if [ ! -f "_Offset_applied.txt" ] 
										then 
											Add_DefoMap_ToAllMapsInDir.py ${UDOVERLAPMAP1} ${UDOVERLAPMAP2}			
											echo "Offset applied on all UD part 2 maps in ${UDTARGETDIR2} on ${TODAY}" > _Offset_applied.txt
										else 
											echo "Offset already applied ? please check. "
									fi
							# EW
								# Defo map at date ${MIDOVERLAPASC} in both parts used to compute offset map
								EWOVERLAPMAP1=$(ls ${EWTARGETDIR1}/MSBAS_${MIDOVERLAPASC}T*_EW.bin)
								EWOVERLAPMAP2=$(ls ${EWTARGETDIR2}/MSBAS_${MIDOVERLAPASC}T*_EW.bin)
							
								cd  ${EWTARGETDIR2}
									# If the file _Offset_applied.txt does not exist then remove offset between part1 and 2
									if [ ! -f "_Offset_applied.txt" ] 
										then 
											Add_DefoMap_ToAllMapsInDir.py ${EWOVERLAPMAP1} ${EWOVERLAPMAP2}			
											echo "Offset applied on all EW part 2 maps in ${EWTARGETDIR2} on ${TODAY}" > _Offset_applied.txt
										else 
											echo "Offset already applied ? please check. "
									fi

						cd ${MSBASDIR} 
						# link (or move ?) all defo maps part2 in common part from MIDOVERLAP (excluded)
							#ln -s ${UDTARGETDIR2}/MSBAS_*T*_UD.bin ${COMMONUD}
							#ln -s ${EWTARGETDIR2}/MSBAS_*T*_EW.bin ${COMMONEW}
							MIDOVERLAPSEC=$(date -d "${MIDOVERLAPASC:0:4}-${MIDOVERLAPASC:4:2}-${MIDOVERLAPASC:6:2}" +%s) # Convert to timestamp
							#for file in "${UDTARGETDIR2}"/MSBAS_*T*_UD.bin; do
							for file in $(find "${UDTARGETDIR2}" -name "MSBAS_*T*.bin"); do
							  # Extract the date from the filename
							  filename=$(basename "$file")
							  file_date_str=$(echo "$filename" | grep -v LINEAR  | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_UD\.bin/\1/')
							  
							  if [ "${file_date_str}" != "" ] ; then
							  	# Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
							  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
								
							  	# Compare the file date with the cutoff date
							  	if [ "$file_date_ts" -gt "$MIDOVERLAPSEC" ]; then
							  		MoveAndLinkBack "$file" "${COMMONUD}"
							  	fi
							  fi
							done
							#for file in "${EWTARGETDIR2}"/MSBAS_*T*_EW.bin; do
							for file in $(find "${EWTARGETDIR2}" -name "MSBAS_*T*.bin"); do
							  # Extract the date from the filename
							  filename=$(basename "$file")
							  file_date_str=$(echo "$filename" | grep -v LINEAR  | ${PATHGNU}/gsed -E 's/MSBAS_([0-9]{8})T[0-9]{6}_EW\.bin/\1/')
							  
							  if [ "${file_date_str}" != "" ] ; then
							  # Convert file date from yyyymmdd to YYYY-MM-DD format and then to timestamp
							  	file_date_ts=$(date -d "${file_date_str:0:4}-${file_date_str:4:2}-${file_date_str:6:2}" +%s)
								
							  	# Compare the file date with the cutoff date
							  	if [ "$file_date_ts" -gt "$MIDOVERLAPSEC" ]; then
							  		MoveAndLinkBack "$file" "${COMMONEW}"
							  	fi
							  fi
							done					

						echo "***************************************************************"
						echo " Rebuild LINEAR_RATE, STD and R2 maps of EW/UD merged parts. "
						echo "    with Coh Threshold. "
						echo "***************************************************************"
						echo 


						# recompute mean velocity, stdv and R2 maps from merged defo maps 
						# recompute mean velocity, stdv and R2 maps from merged defo maps 
							cd ${COMMONUD}
							Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py &
							cd ${COMMONEW}
							Compute_Velocity_Stdv_R2_maps_From_AllDefoMaps.py &
	
							wait

							cd ${COMMONUD}
							CreateRasAndMv ${COMMONUD} UD

							cd ${COMMONEW}
							CreateRasAndMv ${COMMONEW} EW

						cd ${MSBASDIR}	

						# Prepare for plots
						# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
	 					cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
				else 
					cd ${MSBASDIR}
					NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
		
					# Make baseline plot 
					PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1.txt
					PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2.txt
				
					# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
					cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		
					while read -r DESCR X Y RX RY
						do	
							echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
							mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
							mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
					done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
			fi 
			
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
		cp -f header_back.txt header.txt
		# back to ${MSBASDIR}/header.txt which makes use of DefoInterpolx2Detrendi.txt datasets WITH or WITHOUT coh threshold applied in these lists depending if IFCOH = YES or NO
		
		cp -f ${MSBASDIR}/header.txt ${MSBASDIR}/header_UD_EW.txt 

		# Change  second occurrence of "SET = " with "#SET = "
		${PATHGNU}/gsed  '0,/SET = /! {0,/SET = / s/SET = /#SET = /}' ${MSBASDIR}/header.txt > ${MSBASDIR}/header_Asc.txt 
		# Change  first occurrence of "SET = " with "#SET = "
		${PATHGNU}/gsed '0,/SET =/{s/SET =/#SET =/}' ${MSBASDIR}/header.txt > ${MSBASDIR}/header_Desc.txt 
		# ${MSBASDIR}/header_MODE.txt makes use of only one DefoInterpolx2Detrendi.txt dataset each WITH or WITHOUT coh threshold applied in these lists depending if IFCOH = YES or NO

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
