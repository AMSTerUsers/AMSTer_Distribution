#!/bin/bash
# -----------------------------------------------------------------------------------------
# TEMPLATE for cron STEP 2 of the AMSTer automatic mass processing chain of a target.
#
# For every mode (track) of the target, it runs SuperMaster_MassProc.sh on the table of 
# pairs selected at step 1, provided that:
#	- the cron step 1 of the target is not running anymore (it reads images, may move 
#	  images with updated orbits and coregisters them on the Global Primaries), 
#	- no other SuperMaster_MassProc.sh is already using the same LaunchMTparam file.
# If a mode is skipped, it will be tried again at the next run. 
#
# The script waits for the end of all the mass processings before exiting. This is 
# mandatory when it is chained with step 3 (e.g. by Crons_1_2_3.sh).
#
# HOW TO USE: 
#	Copy this file as e.g. MYTARGET_S1_Step2_MassProc.sh and adapt ONLY the section 
#	"USER PARAMETERS" below. Use the same table definitions (MODE_TABLE, MODE_EXCLWIN) 
#	in the cron step 3 of the target.
#
# Parameters: none
#
# Dependencies:	- AMSTer scripts: SuperMaster_MassProc.sh, RemovePairsFromTableList_Between_dates.sh
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

	STEP1_SCRIPT=MYTARGET_S1_Step1_Read_SMCoreg_Pairs.sh	# name (without path) of the cron step 1 of that target
	MAXPARALLEL=0			# max nr of mass processings launched at the same time (0 = no limit)

# Modes 
#######
	# One block per mode (track). Variables:
	#	MODE_NAME			label used in the names of the log files (e.g. Asc, Desc, A_88...)
	#	MODE_SET			seti dir where the table of pairs is
	#	MODE_TABLE			table of pairs to process, as one of:
	#							"CRITERIA BP BT"						-> table_0_BP_0_BT.txt
	#							"CRITERIA BP1 BT1 BP2 BT2 DATECHG"		-> table_0_BP1_0_BT1_Till_DATECHG_0_BP2_0_BT2_After.txt
	#							"SHORTEST NR"							-> table_0_0_MaxShortest_NR_Without_Quanrantained_Data.txt
	#							"DELAUNAY RATIO" (or "DELAUNAY NONE")	-> table_0_0_DelaunayRatioRATIO_0.txt
	#							"FILE /full/path/to/any/table.txt"
	#	MODE_EXCLWIN		optional "START STOP": remove pairs with an image between these dates 
	#						(e.g. co-eruptive pairs processed manually). Empty = none.
	#	MODE_PARAMMASSPROC	LaunchMTparam file for SuperMaster_MassProc.sh
	#	MODE_MASSPROCDIR	dir where the mass processing results are (used for log files only)

	# ---- Mode 1 ----
	MODE_NAME[1]="Asc"
	MODE_SET[1]=${PATH_1650}/SAR_SM/MSBAS/MYTARGET/set1
	MODE_TABLE[1]="CRITERIA 20 400 70 400 20220501"
	MODE_EXCLWIN[1]=""
	MODE_PARAMMASSPROC[1]=${PATH_1650}/Param_files/S1/MYTARGET_A_88/LaunchMTparam_S1_MYTARGET_A_88_Zoom1_ML2_MassProc.txt
	MODE_MASSPROCDIR[1]=${PATH_3601}/SAR_MASSPROCESS/S1/MYTARGET_A_88/SMNoCrop_SM_20190406_Zoom1_ML2

	# ---- Mode 2 ----
	MODE_NAME[2]="Desc"
	MODE_SET[2]=${PATH_1650}/SAR_SM/MSBAS/MYTARGET/set2
	MODE_TABLE[2]="CRITERIA 20 400 70 400 20220501"
	MODE_EXCLWIN[2]=""
	MODE_PARAMMASSPROC[2]=${PATH_1650}/Param_files/S1/MYTARGET_D_139/LaunchMTparam_S1_MYTARGET_D_139_Zoom1_ML2_MassProc.txt
	MODE_MASSPROCDIR[2]=${PATH_3601}/SAR_MASSPROCESS/S1/MYTARGET_D_139/SMNoCrop_SM_20210920_Zoom1_ML2

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                       END OF USER PARAMETERS - do not edit below 
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

MODES="${!MODE_NAME[@]}"
TODAY=`date`

# Functions
###########
function TableName()
	{
	# Path of the table of pairs for a seti dir ($1) and a table definition (next params)
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
			# DelaunayTable.py writes the ratio as a python float (30 -> 30.0)
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
	# Table for mode $1, with the optional exclusion window applied 
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

function IsRunning()
	{
	# True (0) if a process command line contains all the given strings. 
	# Ignores grep itself, Crons_1_2_3.sh (its command line contains the names of the cron scripts) and the present shell.
	local LIST=$(ps -eo pid=,args= | ${PATHGNU}/grep -v -e "grep" -e "Crons_1_2_3.sh" | ${PATHGNU}/gawk -v ME=$$ '$1 != ME')
	local STR
	for STR in "$@" ; do LIST=$(echo "${LIST}" | ${PATHGNU}/grep -F -- "${STR}") ; done
	[ "${LIST}" != "" ]
	}

function Throttle()
	{
	if [ "${MAXPARALLEL}" -gt 0 ] 2>/dev/null ; then 
		while [ "$(jobs -pr | wc -l)" -ge "${MAXPARALLEL}" ] ; do sleep 60 ; done
	fi
	}

# Checks 
########
if [ "${MODES}" == "" ] ; then echo "ERROR: no mode defined" ; exit 1 ; fi
for i in ${MODES} ; do
	mkdir -p "${MODE_MASSPROCDIR[$i]}"
	if [ ! -f "${MODE_PARAMMASSPROC[$i]}" ] ; then 
		echo "Step2 of mode ${MODE_NAME[$i]} impossible on ${TODAY}: missing ${MODE_PARAMMASSPROC[$i]}" | tee -a "${MODE_MASSPROCDIR[$i]}/_${MODE_NAME[$i]}_last_aborted.txt"
		exit 1
	fi
	if [ "$(TableName "${MODE_SET[$i]}" ${MODE_TABLE[$i]})" == "" ] ; then 
		echo "Step2 of mode ${MODE_NAME[$i]} impossible on ${TODAY}: unknown MODE_TABLE ${MODE_TABLE[$i]}" | tee -a "${MODE_MASSPROCDIR[$i]}/_${MODE_NAME[$i]}_last_aborted.txt"
		exit 1
	fi
done

# Step 1 must be finished
#########################
if IsRunning "${STEP1_SCRIPT}" ; then 
	for i in ${MODES} ; do
		echo "Step2 aborted on ${TODAY} because ${STEP1_SCRIPT} is still running: wait for next run" >> "${MODE_MASSPROCDIR[$i]}/_aborted_because_Read_inProgress.txt"
	done
	echo "Step2 aborted because ${STEP1_SCRIPT} is still running"
	exit 0
fi

# Launch mass processing of each mode 
#####################################
for i in ${MODES} ; do
	NAME=${MODE_NAME[$i]}
	BASETABLE=$(TableName "${MODE_SET[$i]}" ${MODE_TABLE[$i]})
	TABLE=$(TableToProcess $i)
	PARAMNAME=$(basename "${MODE_PARAMMASSPROC[$i]}")

	if [ ! -s "${BASETABLE}" ] ; then 
		echo "${NAME} attempt aborted on ${TODAY} because table ${BASETABLE} does not exist (check MODE_TABLE and step 1)" >> "${MODE_MASSPROCDIR[$i]}/_${NAME}_last_aborted.txt"
		continue
	fi
	# (re)create the table without the pairs in the exclusion window
	if [ "${MODE_EXCLWIN[$i]}" != "" ] ; then 
		cd "${MODE_SET[$i]}"
		RemovePairsFromTableList_Between_dates.sh "${BASETABLE}" ${MODE_EXCLWIN[$i]}
		cd - > /dev/null
	fi

	if IsRunning "SuperMaster_MassProc.sh" "${PARAMNAME}" 
		then 
			# will be tried again at next run 
			echo "${NAME} attempt aborted on ${TODAY} because other Mass Process in progress" >> "${MODE_MASSPROCDIR[$i]}/_${NAME}_last_aborted.txt"
		else
			Throttle
			echo "${NAME} run on ${TODAY} with $(basename "${TABLE}")" >> "${MODE_MASSPROCDIR[$i]}/_${NAME}_last_MassRun.txt"
			# launched from the present shell so that "wait" below really waits for it
			${PATH_SCRIPTS}/SCRIPTS_MT/SuperMaster_MassProc.sh "${TABLE}" "${MODE_PARAMMASSPROC[$i]}" > /dev/null 2>&1 &
	fi
done

# Mandatory: wait for the end of all mass processings before step 3 can start
wait
echo "Step2 ended on $(date)"
