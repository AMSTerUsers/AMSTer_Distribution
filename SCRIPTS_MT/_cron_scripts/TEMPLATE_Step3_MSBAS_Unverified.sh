#!/bin/bash
# -----------------------------------------------------------------------------------------
# TEMPLATE for cron STEP 3 of the AMSTer automatic mass processing chain of a target.
#
# It (re)computes the MSBAS time series when new deformation maps were produced at step 2 
# (or if the orbits were updated and products recomputed): 
#	- checks that no step 2, no other step 3 and no SuperMaster_MassProc.sh using the same 
#	  LaunchMTparam files is running, 
#	- removes duplicated pairs (e.g. after orbit update) and cleans the existing MSBAS lists,
#	- builds the msbas header from the tables of pairs of each mode (build_header_msbas_Tables.sh), 
#	  hence each mode may use a different pair selection (criteria, shortest, Delaunay...),
#	- (optional) adds the NS component for a 3D (surface parallel flow) inversion, 
#	- (optional) restricts dates of each mode, 
#	- (optional) runs a first inversion without, then with, a coherence threshold restriction, 
#	- runs the EW-UD(-NS) decomposition when there are at least 2 modes,
#	- (optional) runs the LOS inversion of each mode separately and/or of chosen combinations of modes,
#	- plots time series of points and double differences between pairs of points. 
#
# Notes: 	- Deformation maps are supposed detrended at processing, hence C_FLAG is set to 0 by default.
#			- The order of the modes defines the numbering of the msbas lists (DefoInterpolx2Detrendi). 
#			  Do not reorder or remove modes for an existing MSBASDIR; start a new MSBASDIR instead.
#
# HOW TO USE: 
#	Copy this file as e.g. MYTARGET_S1_Step3_MSBAS.sh and adapt ONLY the section 
#	"USER PARAMETERS" below. Use the same table definitions (MODE_TABLE, MODE_EXCLWIN) 
#	as in the cron step 2 of the target.
#
# Parameters: none
#
# Dependencies:	- AMSTer scripts: MSBAS.sh, build_header_msbas_Tables.sh, Add_NS_comp_msbas.sh, 
#				  Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh, Remove_BrokenLinks_and_Clean_txt_file.sh,
#				  _Check_bad_DefoInterpolx2Detrend.sh, restrict_msbas_to_Coh.sh, Exclude_Pairs_From_Mode.txt.sh,
#				  PlotBaselineGeocMSBASmodeTXT.sh, PlotTS_all_comp.sh, PlotTS.sh, Plot_vectorDispl_DEM.py
#				- GNU tools through ${PATHGNU} (gsed, gawk, grep, gfind)
#	For an up to date list, run: Search_Dependencies /Path/to/This/script
#
# New in Distro V 1.0 20261013:	- template built by AI from all the former target-specific cron scripts 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2026, Last modified on Oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

source $HOME/.bashrc

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
#                                    USER PARAMETERS 
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

# MSBAS inversion 
#################
	LABEL=MYTARGET				# label used in the names of the results (zz_ dirs, figures...)
	DEFOMODE=DefoInterpolx2Detrend	# type of deformation maps (name of the subdir in .../Geocoded/)
	ORDER=2						# R_FLAG: regularisation order
	LAMBDA=0.04					# R_FLAG: Tikhonov regularisation weight
	CFLAG=0						# C_FLAG (0 = no calibration because maps are detrended). Empty = keep header value
	WINDOWSIZE=""				# WINDOW_SIZE for a crop, e.g. "950, 1250, 1000, 1350". Empty = full frame
	MSBASVERSION="--msbasv4"	# msbas version for the decomposition (e.g. --msbasv4_3D for 3D if needed)
	MSBASVERSION_LOS="--msbasv4"	# msbas version for the LOS inversions and the 2D combinations
	MAXTHREADS=128				# max nr of threads (OpenBLAS often compiled for max 128)
	FORCEMSBAS=NO				# YES to run msbas even if no new deformation map is available

	MSBASDIR=${PATH_3602}/MSBAS/_${LABEL}_S1_Auto_${ORDER}_${LAMBDA}	# where msbas is run 

# 3D inversion (EW, UD and NS along the steepest slope) - only with at least 2 modes
##############
	THREED=NO					# YES to add the NS component
	FG=75						# width (in m) of the Gaussian filter applied to the DEM 
	LINESTOSKIP=""				# optional 3rd param of Add_NS_comp_msbas.sh. Empty = none
	VECTORPLOT_ARGS=""			# parameters of Plot_vectorDispl_DEM.py, e.g. "--scalevalue 0.5 --dwsple 15". Empty = no vector plot

# Coherence restriction (first inversion without, then with, a coherence threshold)
#######################
	IFCOH=NO					# YES or NO
	KMLCOH=${PATH_1650}/kml/MyTarget/CohZone.kml	# zone where the mean coherence is computed
	COHRESTRICT=0.235			# coherence threshold

# Points for time series
########################
	# List of single points (with a header line): DESCRIPTION X Y RefX RefY. Empty = no time series
	TIMESERIESPTSDESCR=${PATH_1650}/Data_Points/Points_TS_${LABEL}.txt
	# List of pairs of points for double differences (no header): X1 Y1 X2 Y2 DESCRIPTION. Empty = no plot
	DOUBLEDIFFPAIRSEWUD=${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt
	EVENTS=""					# optional events table for the plots (e.g. ${PATH_1650}/EVENTS_TABLES/${LABEL})

# Additional inversions
#######################
	LOSRUNS=YES					# YES to also invert each mode separately in LOS (always done if only one mode)
	# Optional combinations of modes (use the mode indices as defined below). A combination 
	# with one mode is a LOS inversion; with two or more modes, an EW-UD decomposition. 
	#COMBI[1]="1 3"				# e.g. Asc 1 with Desc 3
	#COMBI_WINDOW[1]=""			# optional WINDOW_SIZE for that combination 

# Other cron jobs that must not run at the same time (names without path, space separated)
#####################################################
	STEP2_SCRIPTS="MYTARGET_S1_Step2_MassProc.sh"
	OTHER_STEP3_SCRIPTS=""		# e.g. a 2D and a 3D step 3 of the same target. Do not list the present script

# Modes 
#######
	# One block per mode (track). Variables:
	#	MODE_NAME			label used in names of LOS results (e.g. Asc, Desc...)
	#	MODE_MASSPROCDIR	dir with the mass processing results (.../SAR_MASSPROCESS/SAT/TRK/SMNoCrop_SM_date_Zoomx_MLy)
	#	MODE_SET			seti dir where the table of pairs is
	#	MODE_TABLE, MODE_EXCLWIN	SAME as in cron step 2 (see there for the syntax)
	#	MODE_PARAMMASSPROC	LaunchMTparam file used at step 2 (to check that no mass processing is running)
	#	MODE_REMOVEBEFORE	remove pairs with an image before (or on) this date, or NONE
	#	MODE_REMOVEAFTER	remove pairs with an image after (or on) this date, or NONE
	#	MODE_REMOVEBETWEEN	YES to remove only pairs with an image between REMOVEBEFORE and REMOVEAFTER
	#	MODE_COHEXCLUDE		YES to also exclude pairs listed in DefoInterpolx2Detrendi/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt 
	#						(only with IFCOH=YES). If that file exists in MODE_SET, it is copied there at each run.
	#	MODE_DDLIST			list of pairs of points for double differences in LOS. Empty = no plot

	# ---- Mode 1 ----
	MODE_NAME[1]="Asc"
	MODE_MASSPROCDIR[1]=${PATH_3601}/SAR_MASSPROCESS/S1/MYTARGET_A_88/SMNoCrop_SM_20190406_Zoom1_ML2
	MODE_SET[1]=${PATH_1650}/SAR_SM/MSBAS/MYTARGET/set1
	MODE_TABLE[1]="CRITERIA 20 400 70 400 20220501"
	MODE_EXCLWIN[1]=""
	MODE_PARAMMASSPROC[1]=LaunchMTparam_S1_MYTARGET_A_88_Zoom1_ML2_MassProc.txt
	MODE_REMOVEBEFORE[1]=NONE
	MODE_REMOVEAFTER[1]=NONE
	MODE_REMOVEBETWEEN[1]=NO
	MODE_COHEXCLUDE[1]=NO
	MODE_DDLIST[1]=${DOUBLEDIFFPAIRSEWUD}

	# ---- Mode 2 ----
	MODE_NAME[2]="Desc"
	MODE_MASSPROCDIR[2]=${PATH_3601}/SAR_MASSPROCESS/S1/MYTARGET_D_139/SMNoCrop_SM_20210920_Zoom1_ML2
	MODE_SET[2]=${PATH_1650}/SAR_SM/MSBAS/MYTARGET/set2
	MODE_TABLE[2]="CRITERIA 20 400 70 400 20220501"
	MODE_EXCLWIN[2]=""
	MODE_PARAMMASSPROC[2]=LaunchMTparam_S1_MYTARGET_D_139_Zoom1_ML2_MassProc.txt
	MODE_REMOVEBEFORE[2]=NONE
	MODE_REMOVEAFTER[2]=NONE
	MODE_REMOVEBETWEEN[2]=NO
	MODE_COHEXCLUDE[2]=NO
	MODE_DDLIST[2]=${DOUBLEDIFFPAIRSEWUD}

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                       END OF USER PARAMETERS - do not edit below 
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

TODAY=`date`
MODES="${!MODE_NAME[@]}"
LOGFILE=${MSBASDIR}/_last_MSBAS_process.txt
LOCKDIR=${MSBASDIR}/.lock_${PRG}
TIMEFILE=${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
OLL=${ORDER}_${LAMBDA}_${LABEL}
SUFFIX=_Auto_${OLL}

# Position k (1..N) of each mode index i in the msbas header: msbas list k is ${DEFOMODE}k.txt
NRMODES=0
for i in ${MODES} ; do NRMODES=$((NRMODES + 1)) ; POS[$i]=${NRMODES} ; done

if [ "${THREED}" == "YES" ] ; then ALLCOMP=UD_EW_NS ; else ALLCOMP=UD_EW ; fi

# Functions
###########
function Log()
	{
	echo "$*"
	echo "$*" >> "${LOGFILE}"
	}

function AcquireLock()
	{
	# Atomic lock (mkdir) holding the PID; a lock left by a dead process is ignored.  
	if ! mkdir "${LOCKDIR}" 2>/dev/null 
		then
			OLDPID=$(cat "${LOCKDIR}/pid" 2>/dev/null)
			if [ "${OLDPID}" != "" ] && kill -0 "${OLDPID}" 2>/dev/null ; then return 1 ; fi
			rm -rf "${LOCKDIR}"
			mkdir "${LOCKDIR}" || return 1
	fi
	echo $$ > "${LOCKDIR}/pid"
	trap 'rm -rf "${LOCKDIR}"' EXIT
	return 0
	}

function IsRunning()
	{
	# True (0) if a process command line contains all the given strings. 
	# Ignores grep itself, Crons_1_2_3.sh (its command line contains the names of the cron scripts) and the present shell.
	local LIST=$(ps -eo pid=,args= | ${PATHGNU}/grep -v -e "grep" -e "Crons_1_2_3.sh" | ${PATHGNU}/gawk -v ME=$$ '$1 != ME')
	local STR
	for STR in "$@" ; do LIST=$(echo "${LIST}" | ${PATHGNU}/grep -F -- "${STR}") ; done
	[ "${LIST}" != "" ]
	}

function TableName()
	{
	# Path of the table of pairs for a seti dir ($1) and a table definition (next params). Same as in step 2.
	local SETDIR=$1
	local TYPE=$2
	shift 2
	case "${TYPE}" in
		CRITERIA)
			if [ $# -eq 5 ] 
				then echo "${SETDIR}/table_0_$1_0_$2_Till_$5_0_$3_0_$4_After.txt"
				else echo "${SETDIR}/table_0_$1_0_$2.txt"
			fi ;;
		SHORTEST)
			echo "${SETDIR}/table_0_0_MaxShortest_$1_Without_Quanrantained_Data.txt" ;;
		DELAUNAY)
			if [ "$1" == "NONE" ] ; then echo "${SETDIR}/table_0_0_DelaunayNoRatio_0.txt" ; return ; fi
			case "$1" in 
				*.*) echo "${SETDIR}/table_0_0_DelaunayRatio$1_0.txt" ;;
				*)   echo "${SETDIR}/table_0_0_DelaunayRatio$1.0_0.txt" ;;
			esac ;;
		FILE)
			echo "$1" ;;
		*)
			echo "" ;;
	esac
	}

function TableToProcess()
	{
	local i=$1
	local TABLE=$(TableName "${MODE_SET[$i]}" ${MODE_TABLE[$i]})
	if [ "${MODE_EXCLWIN[$i]}" != "" ] 
		then
			set -- ${MODE_EXCLWIN[$i]}
			echo "${TABLE}_Without_$1_$2.txt"
		else 
			echo "${TABLE}"
	fi
	}

function MassProcRoot()
	{
	# .../SAR_MASSPROCESS from .../SAR_MASSPROCESS/SAT/TRK/SMNoCrop_SM_date_ZoomX_MLY
	dirname "$(dirname "$(dirname "$1")")"
	}

function LastProductTime()
	{
	# Time (in sec) of the most recent deformation map of a mass processing dir (0 if none)
	local T=$(${PATHGNU}/gfind "$1/Geocoded/${DEFOMODE}/" -maxdepth 1 -type f -name "*deg" -printf "%T@\n" 2>/dev/null | sort -n | tail -1 | cut -d. -f1)
	echo "${T:-0}"
	}

function Keep4Col()
	{
	# Keep only lines with at least 4 columns in msbas list $1; other lines are saved in $2 if given
	if [ ! -f "$1" ] ; then return ; fi
	if [ "$2" != "" ] ; then ${PATHGNU}/gawk 'NF<4' "$1" > "$2" ; fi
	${PATHGNU}/gawk 'NF>=4' "$1" > "$1.tmp" && mv -f "$1.tmp" "$1"
	}

function RestrictDates()
	{
	# Remove pairs from msbas list of mode index $1 according to MODE_REMOVExxx (cols 3 and 4 are the dates)
	local i=$1
	local LIST=${MSBASDIR}/${DEFOMODE}${POS[$i]}.txt
	local BEFORE=${MODE_REMOVEBEFORE[$i]:-NONE}
	local AFTER=${MODE_REMOVEAFTER[$i]:-NONE}
	if [ "${MODE_REMOVEBETWEEN[$i]}" == "YES" ] 
		then 
			local MIN=${BEFORE} MAX=${AFTER}
			if [ "${AFTER}" -lt "${BEFORE}" ] ; then MIN=${AFTER} ; MAX=${BEFORE} ; fi
			Log "  // Remove pairs with an image between ${MIN} and ${MAX} from mode ${MODE_NAME[$i]}"
			cp -f "${LIST}" "${LIST%.txt}_WITHdatesBetween${MIN}and${MAX}.txt"
			${PATHGNU}/gawk -v a=${MIN} -v b=${MAX} '($3 < a && $4 < a) || ($3 > b && $4 > b)' "${LIST%.txt}_WITHdatesBetween${MIN}and${MAX}.txt" > "${LIST}"
		else
			if [ "${BEFORE}" != "NONE" ] ; then 
				Log "  // Remove pairs with an image before ${BEFORE} from mode ${MODE_NAME[$i]}"
				cp -f "${LIST}" "${LIST%.txt}_WithoutRemoveDatesBefore${BEFORE}.txt"
				${PATHGNU}/gawk -v d=${BEFORE} '$3 > d && $4 > d' "${LIST%.txt}_WithoutRemoveDatesBefore${BEFORE}.txt" > "${LIST}"
			fi
			if [ "${AFTER}" != "NONE" ] ; then 
				Log "  // Remove pairs with an image after ${AFTER} from mode ${MODE_NAME[$i]}"
				cp -f "${LIST}" "${LIST%.txt}_WithoutRemoveDatesAfter${AFTER}.txt"
				${PATHGNU}/gawk -v d=${AFTER} '$3 < d && $4 < d' "${LIST%.txt}_WithoutRemoveDatesAfter${AFTER}.txt" > "${LIST}"
			fi
	fi
	}

function MoveIfExists()
	{
	if [ -f "$1" ] ; then mv -f "$1" "$2" ; fi
	}

function RenamePointsTS()
	{
	# Add the description of each point to the names of its time series (found in $1 or in MSBASDIR) 
	local OUT=$1
	if [ "${TIMESERIESPTSDESCR}" == "" ] ; then return ; fi
	cp -f "${TIMESERIESPTSDESCR}" "${OUT}/"
	tail -n +2 "${TIMESERIESPTSDESCR}" | while read -r DESCR X Y RX RY 
		do	
			if [ "${X}" == "" ] ; then continue ; fi
			for EXT in txt pdf ; do 
				F=MSBAS_${X}_${Y}_${RX}_${RY}
				if [ -f "${OUT}/${F}.${EXT}" ] 
					then mv -f "${OUT}/${F}.${EXT}" "${OUT}/${F}_${DESCR}.${EXT}"
					else MoveIfExists "${MSBASDIR}/${F}.${EXT}" "${OUT}/${F}_${DESCR}.${EXT}"
				fi
			done
	done
	}

function PlotOptions()
	{
	if [ "${EVENTS}" == "" ] ; then echo "-f -r -t -g" ; else echo "-f -r -t -g -events=${EVENTS}" ; fi
	}

function PlotDoubleDiffDecomp()
	{
	# Double difference plots of a decomposition. $1 = msbas suffix, $2 = output dir, then X1 Y1 X2 Y2 DESCR
	local SUF=$1 OUT=$2 X1=$3 Y1=$4 X2=$5 Y2=$6 DESCR=$7
	cd "${MSBASDIR}"
	${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh ${SUF} ${X1} ${Y1} ${X2} ${Y2} $(PlotOptions)
	local F
	for F in timeLines_${X1}_${Y1}${SUF}.eps timeLines_${X2}_${Y2}${SUF}.eps timeLines_${X1}_${Y1}_${X2}_${Y2}${SUF}.eps timeLines_${X1}_${Y1}_${X2}_${Y2}${SUF}_Combi.jpg ; do
		MoveIfExists "${MSBASDIR}/${F}" "${OUT}/${DESCR}_${F}"
	done
	local C
	for C in UD EW NS ; do
		MoveIfExists "${MSBASDIR}/timeLine_${C}_${X1}_${Y1}_${X2}_${Y2}${SUF}.txt" "${OUT}/${DESCR}_timeLines_${C}_${X1}_${Y1}_${X2}_${Y2}${SUF}.txt"
	done
	}

function PlotDoubleDiffLOS()
	{
	# Double difference plots of a LOS inversion. $1 = msbas suffix (_NAME_Auto_...), $2 = name, then X1 Y1 X2 Y2 DESCR
	local SUF=$1 NAME=$2 X1=$3 Y1=$4 X2=$5 Y2=$6 DESCR=$7
	local RES=${MSBASDIR}/zz_LOS${SUF}
	local OUT=${MSBASDIR}/zz_LOS_TS${SUF}
	cd "${RES}" || return
	${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} $(PlotOptions)
	MoveIfExists "${RES}/timeLine${X1}_${Y1}.eps" "${OUT}/${DESCR}_timeLine_${X1}_${Y1}${SUFFIX}.eps"
	MoveIfExists "${RES}/timeLine${X2}_${Y2}.eps" "${OUT}/${DESCR}_timeLine_${X2}_${Y2}${SUFFIX}.eps"
	MoveIfExists "${RES}/timeLine${X1}_${Y1}_${X2}_${Y2}.eps" "${OUT}/${DESCR}_timeLine_${X1}_${Y1}_${X2}_${Y2}${SUFFIX}.eps"
	MoveIfExists "${RES}/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg" "${OUT}/${DESCR}_timeLine_${X1}_${Y1}_${X2}_${Y2}${SUFFIX}_Combi_${NAME}.jpg"
	MoveIfExists "${RES}/timeLine${X1}_${Y1}.txt" "${OUT}/_Time_series/"
	MoveIfExists "${RES}/timeLine${X2}_${Y2}.txt" "${OUT}/_Time_series/"
	MoveIfExists "${RES}/timeLine${X1}_${Y1}_${X2}_${Y2}.txt" "${OUT}/_Time_series/"
	cd "${MSBASDIR}"
	}

function ReadPairsOfPoints()
	{
	# Print the valid lines of a list of pairs of points (skip empty and commented lines)
	if [ "$1" == "" ] || [ ! -f "$1" ] ; then return ; fi
	${PATHGNU}/grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$1"
	}

function TidyResults()
	{
	# Move combined figures and time series in their own sub dirs
	local OUT=$1
	mkdir -p "${OUT}/__Combi" "${OUT}/_Time_series"
	rm -f "${OUT}"/__Combi/*.jpg
	mv -f "${OUT}"/*_Combi*.jpg "${OUT}/__Combi/" 2>/dev/null
	mv -f "${OUT}"/*.txt "${OUT}/_Time_series/" 2>/dev/null
	}

function RunDecomposition()
	{
	# EW-UD(-NS) inversion with the current header.txt
	#	$1 = msbas suffix ; $2 = components (UD_EW or UD_EW_NS) ; $3 = msbas version ; 
	#	$4 = "_Full" to plot baselines of the lists without coh restriction, "NOPLOT" for no baseline plot, or empty
	local SUF=$1 COMP=$2 VERSION=$3 LISTS=$4
	local OUT=${MSBASDIR}/zz_${COMP}_TS${SUF}
	local i k
	cd "${MSBASDIR}"
	NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh ${SUF} ${TIMESERIESPTS} ${VERSION}
	mkdir -p "${OUT}"
	if [ "${LISTS}" != "NOPLOT" ] ; then 
		for i in ${MODES} ; do
			k=${POS[$i]}
			if [ "${LISTS}" == "_Full" ] 
				then PlotBaselineGeocMSBASmodeTXT.sh "${MODE_SET[$i]}" "${MSBASDIR}/${DEFOMODE}${k}_Full/${DEFOMODE}${k}_Full.txt"
				else PlotBaselineGeocMSBASmodeTXT.sh "${MODE_SET[$i]}" "${MSBASDIR}/${DEFOMODE}${k}.txt"
			fi
		done
	fi
	RenamePointsTS "${OUT}"
	ReadPairsOfPoints "${DOUBLEDIFFPAIRSEWUD}" | while read -r X1 Y1 X2 Y2 DESCR ; do
		PlotDoubleDiffDecomp ${SUF} "${OUT}" ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
	done
	TidyResults "${OUT}"
	}

function RunLOS()
	{
	# LOS inversion with the current header.txt. $1 = msbas suffix ; $2 = name ; $3 = list of pairs of points
	local SUF=$1 NAME=$2 DDLIST=$3
	local OUT=${MSBASDIR}/zz_LOS_TS${SUF}
	cd "${MSBASDIR}"
	NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh ${SUF} ${TIMESERIESPTS} ${MSBASVERSION_LOS}
	mkdir -p "${OUT}/_Time_series"
	RenamePointsTS "${OUT}"
	ReadPairsOfPoints "${DDLIST}" | while read -r X1 Y1 X2 Y2 DESCR ; do
		PlotDoubleDiffLOS ${SUF} ${NAME} ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
	done
	TidyResults "${OUT}"
	}

function SubHeader()
	{
	# Write header_$1.txt keeping only the SET lines of the given positions (next params), 
	# without the 3D lines, and with an optional WINDOW_SIZE given in variable SUBWINDOW
	local NAMEH=$1
	shift
	${PATHGNU}/grep -v "DD_NSEW_FILES" "${MSBASDIR}/header_main.txt" \
		| ${PATHGNU}/gawk -v keep=" $* " '/^[[:space:]]*SET = /{ n++ ; if (index(keep, " " n " ") == 0) $0 = "#" $0 } { print }' \
		> "${MSBASDIR}/header_${NAMEH}.txt"
	if [ "${SUBWINDOW}" != "" ] ; then 
		${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = ${SUBWINDOW}/" "${MSBASDIR}/header_${NAMEH}.txt"
	fi
	}

# Checks 
########
mkdir -p "${MSBASDIR}"
if [ "${MODES}" == "" ] ; then Log "ERROR: no mode defined" ; exit 1 ; fi
if [ "${THREED}" == "YES" ] && [ ${NRMODES} -lt 2 ] ; then Log "ERROR: 3D inversion requires at least 2 modes" ; exit 1 ; fi
if [ "${IFCOH}" == "YES" ] && [ ! -s "${KMLCOH}" ] ; then Log "ERROR: missing kml for coherence estimation ${KMLCOH}" ; exit 1 ; fi
if [ "${TIMESERIESPTSDESCR}" != "" ] && [ ! -f "${TIMESERIESPTSDESCR}" ] ; then Log "ERROR: missing ${TIMESERIESPTSDESCR}" ; exit 1 ; fi
for i in ${MODES} ; do
	if [ ! -d "${MODE_MASSPROCDIR[$i]}" ] ; then Log "ERROR: missing ${MODE_MASSPROCDIR[$i]}" ; exit 1 ; fi
	if [ "$(TableName "${MODE_SET[$i]}" ${MODE_TABLE[$i]})" == "" ] ; then Log "ERROR: unknown MODE_TABLE[$i] ${MODE_TABLE[$i]}" ; exit 1 ; fi
	if [ "${MODE_REMOVEBETWEEN[$i]}" == "YES" ] ; then 
		if [ "${MODE_REMOVEBEFORE[$i]:-NONE}" == "NONE" ] || [ "${MODE_REMOVEAFTER[$i]:-NONE}" == "NONE" ] ; then 
			Log "ERROR: MODE_REMOVEBETWEEN[$i]=YES requires both MODE_REMOVEBEFORE[$i] and MODE_REMOVEAFTER[$i]" ; exit 1
		fi
	elif [ "${MODE_REMOVEBEFORE[$i]:-NONE}" != "NONE" ] && [ "${MODE_REMOVEAFTER[$i]:-NONE}" != "NONE" ] ; then 
		Log "ERROR: mode ${MODE_NAME[$i]}: removing before AND after dates would keep nothing; set MODE_REMOVEBETWEEN[$i]=YES if you want to remove the pairs between these dates" ; exit 1
	fi
done
for k in "${!COMBI[@]}" ; do
	for i in ${COMBI[$k]} ; do 
		if [ "${POS[$i]}" == "" ] ; then Log "ERROR: COMBI[$k] refers to undefined mode $i" ; exit 1 ; fi
	done
done

# No other step 2 or 3 nor mass processing of the same modes may run 
#####################################################################
if ! AcquireLock ; then Log "MSBAS attempt aborted on ${TODAY} because another ${PRG} is running" ; exit 0 ; fi
for S in ${STEP2_SCRIPTS} ${OTHER_STEP3_SCRIPTS} ; do
	if [ "${S}" != "${PRG}" ] && IsRunning "${S}" ; then Log "MSBAS attempt aborted on ${TODAY} because ${S} is running" ; exit 0 ; fi
done
for i in ${MODES} ; do
	if IsRunning "SuperMaster_MassProc.sh" "$(basename "${MODE_PARAMMASSPROC[$i]}")" ; then 
		Log "MSBAS attempt aborted on ${TODAY} because SuperMaster_MassProc.sh is in progress for mode ${MODE_NAME[$i]}" ; exit 0
	fi
done

# Max nr of threads
###################
case $(uname -s) in 
	"Linux")  NTHR=$(nproc --all) ;;
	"Darwin") NTHR=$(sysctl -n hw.ncpu) ;;
	*)        NTHR=1 ;;
esac
if [ ${NTHR} -gt ${MAXTHREADS} ] ; then NTHR=${MAXTHREADS} ; fi

# Points list without header and description (as required by msbas)
####################################################################
cd "${MSBASDIR}"
if [ "${TIMESERIESPTSDESCR}" != "" ] 
	then 
		TIMESERIESPTS=${MSBASDIR}/Cln_$(basename "${TIMESERIESPTSDESCR}")
		tail -n +2 "${TIMESERIESPTSDESCR}" | ${PATHGNU}/gawk 'NF >= 3 { $1 = "" ; sub(/^[[:space:]]+/, "") ; print }' > "${TIMESERIESPTS}"
	else 
		TIMESERIESPTS=""
fi

# Remove possible duplicated products in SAR_MASSPROCESS (e.g. same pair recomputed after orbit update; keep the most recent)
#########################################################
for i in ${MODES} ; do
	( cd "${MODE_MASSPROCDIR[$i]}" && Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh ) &
done
wait

# Anything new since last run ?
###############################
rm -f "${TIMEFILE}.new"
for i in ${MODES} ; do LastProductTime "${MODE_MASSPROCDIR[$i]}" >> "${TIMEFILE}.new" ; done
if [ -s "${TIMEFILE}" ] 
	then 
		FIRSTRUN=NO
		if cmp -s "${TIMEFILE}" "${TIMEFILE}.new" ; then 
			if [ "${FORCEMSBAS}" == "YES" ] 
				then 
					Log "No new pairs on ${TODAY} but msbas is forced (FORCEMSBAS=YES)"
				else 
					Log "MSBAS finished on ${TODAY} without new pairs to process"
					rm -f "${TIMEFILE}.new"
					exit 0
			fi
		fi
	else 
		FIRSTRUN=YES
fi

# Clean existing msbas lists (broken links, lines with missing columns, bad or duplicated lines)
##############################################################################################
cd "${MSBASDIR}"
if [ "${FIRSTRUN}" == "NO" ] ; then 
	for i in ${MODES} ; do
		k=${POS[$i]}
		Remove_BrokenLinks_and_Clean_txt_file.sh "${MSBASDIR}/${DEFOMODE}${k}" &
		if [ -d "${MSBASDIR}/${DEFOMODE}${k}_Full" ] ; then Remove_BrokenLinks_and_Clean_txt_file.sh "${MSBASDIR}/${DEFOMODE}${k}_Full" & fi
	done
	wait
	for i in ${MODES} ; do
		k=${POS[$i]}
		Keep4Col "${MSBASDIR}/${DEFOMODE}${k}.txt"
		Keep4Col "${MSBASDIR}/${DEFOMODE}${k}_Full/${DEFOMODE}${k}_Full.txt"
	done
	for i in ${MODES} ; do
		k=${POS[$i]}
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}${k} "$(MassProcRoot "${MODE_MASSPROCDIR[$i]}")" &
		if [ -d "${MSBASDIR}/${DEFOMODE}${k}_Full" ] ; then _Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}${k}_Full "$(MassProcRoot "${MODE_MASSPROCDIR[$i]}")" & fi
	done
	wait
fi

# Prepare msbas: lists of pairs and header 
##########################################
TABLES=""
PATHS=""
for i in ${MODES} ; do
	k=${POS[$i]}
	TABLE=$(TableToProcess $i)
	if [ ! -s "${TABLE}" ] ; then Log "MSBAS aborted on ${TODAY}: missing table ${TABLE} for mode ${MODE_NAME[$i]}" ; exit 1 ; fi
	TABLES="${TABLES} ${TABLE}"
	PATHS="${PATHS} ${MODE_MASSPROCDIR[$i]}"
	mkdir -p "${MSBASDIR}/${DEFOMODE}${k}"
	if [ -f "${MODE_SET[$i]}/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt" ] ; then 
		cp -f "${MODE_SET[$i]}/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt" "${MSBASDIR}/${DEFOMODE}${k}/"
	fi
done
cd "${MSBASDIR}"
${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh ${DEFOMODE} ${NRMODES} ${TABLES} ${PATHS}

if [ "${THREED}" == "YES" ] ; then 
	# Force recomputing the DEM filtering in case FG was changed. It is fast anyway. 
	Add_NS_comp_msbas.sh "${FG}" Force ${LINESTOSKIP}
fi

${PATHGNU}/gsed -i "s/^R_FLAG.*/R_FLAG = ${ORDER}, ${LAMBDA}/" header.txt
if [ "${CFLAG}" != "" ] ; then ${PATHGNU}/gsed -i "s/^C_FLAG.*/C_FLAG = ${CFLAG}/" header.txt ; fi
if [ "${WINDOWSIZE}" != "" ] ; then ${PATHGNU}/gsed -i "s/^WINDOW_SIZE.*/WINDOW_SIZE = ${WINDOWSIZE}/" header.txt ; fi

# Check again the new lists 
for i in ${MODES} ; do
	k=${POS[$i]}
	Keep4Col "${MSBASDIR}/${DEFOMODE}${k}.txt" "${MSBASDIR}/${DEFOMODE}${k}_MissingCol.txt"
done
if [ "${IFCOH}" == "YES" ] ; then 
	# duplicated lines with different Bp may result from orbit update
	for i in ${MODES} ; do
		_Check_bad_DefoInterpolx2Detrend.sh ${DEFOMODE}${POS[$i]} "$(MassProcRoot "${MODE_MASSPROCDIR[$i]}")" &
	done
	wait
fi

# Date restrictions
for i in ${MODES} ; do RestrictDates $i ; done

cp -f header.txt header_back.txt

# EW-UD(-NS) decomposition 
##########################
if [ ${NRMODES} -ge 2 ] ; then 
	if [ "${IFCOH}" == "YES" ] ; then 
		# First without coherence restriction: merge new lists with the former full lists
		for i in ${MODES} ; do
			k=${POS[$i]}
			D=${DEFOMODE}${k}
			if [ ! -d "${MSBASDIR}/${D}_Full" ] 
				then 
					cp -R "${MSBASDIR}/${D}" "${MSBASDIR}/${D}_Full"
					cp -f "${MSBASDIR}/${D}.txt" "${MSBASDIR}/${D}_Full/${D}_Full.txt"
				else 
					cat "${MSBASDIR}/${D}.txt" "${MSBASDIR}/${D}_Full/${D}_Full.txt" | sort | uniq > "${MSBASDIR}/${D}_Full.tmp"
					cp -R -n "${MSBASDIR}/${D}/." "${MSBASDIR}/${D}_Full/"
					mv -f "${MSBASDIR}/${D}_Full.tmp" "${MSBASDIR}/${D}_Full/${D}_Full.txt"
			fi
			cp -f "${MSBASDIR}/${D}_Full/${D}_Full.txt" "${MSBASDIR}/${D}_Full.txt"
			${PATHGNU}/gsed -i "s/\b${D}\.txt/${D}_Full.txt/" header.txt
		done
		RunDecomposition "${SUFFIX}_NoCohThresh" ${ALLCOMP} "${MSBASVERSION}" "_Full"

		# Then with coherence restriction
		cd "${MSBASDIR}"
		cp -f header_back.txt header.txt
		for i in ${MODES} ; do
			k=${POS[$i]}
			restrict_msbas_to_Coh.sh ${DEFOMODE}${k} ${COHRESTRICT} "${KMLCOH}" "${MODE_MASSPROCDIR[$i]}/Geocoded/Coh"
			if [ "${MODE_COHEXCLUDE[$i]}" == "YES" ] ; then 
				${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}${k}"
			fi
		done
	fi
	RunDecomposition "${SUFFIX}" ${ALLCOMP} "${MSBASVERSION}" ""

	if [ "${THREED}" == "YES" ] && [ "${VECTORPLOT_ARGS}" != "" ] ; then 
		cd "${MSBASDIR}"
		WHEREDEM=$(${PATHGNU}/gfind "${MSBASDIR}/DEM/" -maxdepth 1 -type f -name "externalSlantRangeDEM.UTM.*.bil" | head -1)
		NSDISPL=${MSBASDIR}/zz_NS${SUFFIX}/MSBAS_LINEAR_RATE_NS.bin
		EWDISPL=${MSBASDIR}/zz_EW${SUFFIX}/MSBAS_LINEAR_RATE_EW.bin
		Plot_vectorDispl_DEM.py "${WHEREDEM}" "${NSDISPL}" "${EWDISPL}" ${VECTORPLOT_ARGS}
		Plot_vectorDispl_DEM.py "${WHEREDEM}" "${NSDISPL}" "${EWDISPL}" ${VECTORPLOT_ARGS} --contour
		mkdir -p "${MSBASDIR}/zz_VectorPlot"
		mv -f EW_NS_Vector_Displ*.jpg "${MSBASDIR}/zz_VectorPlot/" 2>/dev/null
	fi
fi

# LOS inversions of each mode and combinations of modes (with the same lists as above)
#######################################################
cd "${MSBASDIR}"
cp -f header.txt header_main.txt
if [ "${LOSRUNS}" == "YES" ] || [ ${NRMODES} -eq 1 ] ; then 
	for i in ${MODES} ; do
		SUBWINDOW=""
		SubHeader "${MODE_NAME[$i]}" ${POS[$i]}
		cp -f "header_${MODE_NAME[$i]}.txt" header.txt
		RunLOS "_${MODE_NAME[$i]}${SUFFIX}" "${MODE_NAME[$i]}" "${MODE_DDLIST[$i]}"
	done
fi
for c in "${!COMBI[@]}" ; do
	CNAME=""
	CPOS=""
	for i in ${COMBI[$c]} ; do CNAME="${CNAME}_${MODE_NAME[$i]}" ; CPOS="${CPOS} ${POS[$i]}" ; done
	CNAME=${CNAME#_}
	SUBWINDOW=${COMBI_WINDOW[$c]}
	SubHeader "${CNAME}" ${CPOS}
	cd "${MSBASDIR}"
	cp -f "header_${CNAME}.txt" header.txt
	set -- ${COMBI[$c]}
	if [ $# -eq 1 ] 
		then RunLOS "_${CNAME}${SUFFIX}" "${CNAME}" "${MODE_DDLIST[$1]}"
		else RunDecomposition "_${CNAME}${SUFFIX}" UD_EW "${MSBASVERSION_LOS}" "NOPLOT"
	fi
done

# Back to normal for next run 
#############################
cd "${MSBASDIR}"
cp -f header_main.txt header.txt
mv -f "${TIMEFILE}.new" "${TIMEFILE}"
Log "MSBAS finished on $(date)"
