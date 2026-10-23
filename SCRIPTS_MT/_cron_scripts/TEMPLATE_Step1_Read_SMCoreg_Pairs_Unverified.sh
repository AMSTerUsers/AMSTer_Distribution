#!/bin/bash
# -----------------------------------------------------------------------------------------
# TEMPLATE for cron STEP 1 of the AMSTer automatic mass processing chain of a target.
#
# It performs, for every mode (track) of the target:
#	- read the new raw images as .csl (Read_All_Img.sh)
#	- (optional, S1 only) check the nr of bursts and the footprint of the images
#	  (_Check_ALL_S1_SizeAndCoord_InDir.sh) and re-check the temporarily quarantined images
#	- (optional, S1 only) download/read ETAD products and keep only images with ETAD 
#	- coregister all images on the Global Primary (SuperMasterCoreg.sh)
#	- link the images in the seti dir (lns_All_Img.sh)
#	- if new images were coregistered, compute the compatible pairs (Prepa_MSBAS.sh)
#	  with one or two sets of baseline criteria 
#	- (optional) extract the x shortest connections and/or a Delaunay triangulation table
#	- (optional) plot a common baseline plot for several modes
#
# HOW TO USE: 
#	Copy this file as e.g. MYTARGET_S1_Step1_Read_SMCoreg_Pairs.sh and adapt ONLY the 
#	section "USER PARAMETERS" below (and the optional hook functions if needed). 
#	Each mode is described in its own block MODE_xxx[i]. Add or remove blocks as needed. 
#	Indices do not need to be contiguous: comment a whole block to disable a mode. 
#
# Parameters: none
#
# Dependencies:	- AMSTer scripts: Read_All_Img.sh, SuperMasterCoreg.sh, lns_All_Img.sh, 
#				  Prepa_MSBAS.sh, Extract_x_Shortest_Connections.sh, DelaunayTable.sh, 
#				  _Check_ALL_S1_SizeAndCoord_InDir.sh, plot_Multi_BaselinePlot.sh, 
#				  (ETAD: Download_ETAD_UNZIP_Add2CSL.sh, ReadETAD.sh, CheckETAD.sh)
#				- GNU tools through ${PATHGNU} (gsed, ggrep, gfind, gdate)
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

# General
#########
	SAT=S1					# S1, ALOS2, CSK, TSX, SAOCOM, NISAR, BIOMASS ... as expected by lns_All_Img.sh
	LOGDIR=${PATH_1650}/SAR_CSL/S1/MYTARGET		# where Last_Run_Cron_Step1.txt is written (usually the SAR_CSL dir of the target)
	MAXPARALLEL=0			# max nr of coregistrations running at the same time (0 = no limit)

# Steps to perform (YES or NO)
#################################
	DO_READ=YES				# read new images 
	DO_COREG=YES			# coregister on Global Primary (set NO e.g. for an ETAD run sharing the images of a normal run)

# Reading 
#########
	# Dirs where Read_All_Img.sh may clean products of images with updated orbits (S1 or SAOCOM). 
	RESAMDIR=${PATH_1650}/SAR_SM/RESAMPLED/
	MASSPRODIR=${PATH_3601}/SAR_MASSPROCESS/

	# One entry per directory of raw data to read. Entries are read one after the other (safer). 
	#	READ_RAW:  dir with the raw (unzipped for S1) images
	#	READ_CSL:  dir where images will be stored as .csl (usually ending with /NoCrop)
	#	READ_OPTS: optional parameters of Read_All_Img.sh, in any order: 
	#			   kml, polarisation, RESAMDIR, MASSPRODIR, EXACTKML, FreqA, ForceAllYears, -n ...
	READ_RAW[1]=${PATH_3600}/SAR_DATA/S1/S1-DATA-MYTARGET-SLC.UNZIP
	READ_CSL[1]=${PATH_1650}/SAR_CSL/S1/MYTARGET/NoCrop
	READ_OPTS[1]="${PATH_1650}/kml/MyTarget/MyTarget.kml VV ${RESAMDIR} ${MASSPRODIR} EXACTKML"

	#READ_RAW[2]=...		# e.g. a second raw dir for another track (S1 sorted per track), or one per mode (ALOS2...)
	#READ_CSL[2]=...
	#READ_OPTS[2]="..."

# Modes 
#######
	# One block per mode (track). Variables:
	#	MODE_NAME		short label used in logs only (e.g. A_88)
	#	MODE_CSL		dir where the .csl images of that mode are stored (usually .../SAR_CSL/SAT/REGION_TRK/NoCrop)
	#	MODE_SET		seti dir where compatible pairs are computed
	#	MODE_SM			Global Primary (SuperMaster) date. Must be the same as SUPERMASTER in MODE_PARAMCOREG
	#	MODE_PARAMCOREG	LaunchMTparam file used by SuperMasterCoreg.sh 
	#	MODE_RESAMPLED	dir where SuperMasterCoreg.sh resamples the images (contains _No_New_Data_Today.txt)
	#	MODE_BPBT		baseline criteria for Prepa_MSBAS.sh, either "BP BT" (one criterion) 
	#					or "BP1 BT1 BP2 BT2 DATECHG" (BP1/BT1 until DATECHG, then BP2/BT2). 
	#					If all images are after DATECHG, the second criterion is used alone and 
	#					the result is copied with the double-criterion name for steps 2 and 3.
	#	MODE_SHORTEST	optional: nr(s) of shortest connections to extract, e.g. "3" or "3 2" (empty = no)
	#	MODE_DELAUNAY	optional: Delaunay ratio(s), e.g. "30" or "NONE" for no ratio (empty = no)
	#	MODE_BURSTCHECK	optional, S1 only: parameters given to _Check_ALL_S1_SizeAndCoord_InDir.sh after 
	#					the dir, i.e. "NrBursts KML" or "NrBursts LongMin LongMax LatMin LatMax" 
	#					or "NrBursts 8 corners coordinates" (empty = no check)
	#	MODE_RECHECKQUAR optional, S1 only: same type of parameters to re-check the images placed in 
	#					__TMP_QUARANTINE; those that pass are moved back in MODE_CSL (empty = no re-check)
	#	MODE_ETAD_ZIP, MODE_ETAD_UNZIP, MODE_ETAD_ORB: only if ETAD=YES (see below)

	# ---- Mode 1 ----
	MODE_NAME[1]="A_88"
	MODE_CSL[1]=${PATH_1650}/SAR_CSL/S1/MYTARGET_A_88/NoCrop
	MODE_SET[1]=${PATH_1650}/SAR_SM/MSBAS/MYTARGET/set1
	MODE_SM[1]=20190406
	MODE_PARAMCOREG[1]=${PATH_1650}/Param_files/S1/MYTARGET_A_88/LaunchMTparam_S1_MYTARGET_A_88_Zoom1_ML2_Coreg.txt
	MODE_RESAMPLED[1]=${PATH_1650}/SAR_SM/RESAMPLED/S1/MYTARGET_A_88/SMNoCrop_SM_${MODE_SM[1]}
	MODE_BPBT[1]="20 400 70 400 20220501"
	MODE_SHORTEST[1]=""
	MODE_DELAUNAY[1]=""
	MODE_BURSTCHECK[1]="10 ${PATH_1650}/kml/MyTarget/MyTarget.kml"
	MODE_RECHECKQUAR[1]=""
	MODE_ETAD_ZIP[1]=""
	MODE_ETAD_UNZIP[1]=""
	MODE_ETAD_ORB[1]=""

	# ---- Mode 2 ----
	MODE_NAME[2]="D_139"
	MODE_CSL[2]=${PATH_1650}/SAR_CSL/S1/MYTARGET_D_139/NoCrop
	MODE_SET[2]=${PATH_1650}/SAR_SM/MSBAS/MYTARGET/set2
	MODE_SM[2]=20210920
	MODE_PARAMCOREG[2]=${PATH_1650}/Param_files/S1/MYTARGET_D_139/LaunchMTparam_S1_MYTARGET_D_139_Zoom1_ML2_Coreg.txt
	MODE_RESAMPLED[2]=${PATH_1650}/SAR_SM/RESAMPLED/S1/MYTARGET_D_139/SMNoCrop_SM_${MODE_SM[2]}
	MODE_BPBT[2]="20 400 70 400 20220501"
	MODE_SHORTEST[2]=""
	MODE_DELAUNAY[2]=""
	MODE_BURSTCHECK[2]="6 ${PATH_1650}/kml/MyTarget/MyTarget.kml"
	MODE_RECHECKQUAR[2]=""
	MODE_ETAD_ZIP[2]=""
	MODE_ETAD_UNZIP[2]=""
	MODE_ETAD_ORB[2]=""

# Common baseline plot 
######################
	MULTIPLOT="1 2"			# indices of the modes to plot together (empty = no common plot)
	COLORTABLE=${PATH_SCRIPTS}/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt	# only for AMSTer Engine before May 2022

# ETAD (S1 only) 
################
	ETAD=NO					# YES to link (and coregister) only the images with complete ETAD products
	ETAD_FIRSTDATE=20230701	# date of the first ETAD product made available by ESA 
	ETAD_REREAD_DAYS=100	# (re)read the ETAD products of the last x days, in case some were missing 
	ETAD_DOWNLOAD=NO		# YES to download the new ETAD products (requires MODE_ETAD_ZIP and MODE_ETAD_ORB)
	ETAD_KML=${PATH_1650}/kml/MyTarget/MyTarget.kml	# footprint used for ETAD download
	ETAD_KEEPLOGS=30		# remove _ETAD_All_OK_* and _ETAD_Missing_* files older than x days

# Optional hooks for target-specific operations. Keep the ":" if nothing to do.
###############################################
	PreRead() {
		:	# e.g. unzip and sort raw data (CSK curl download, ALOS2_UNZIP_Check_Sort.sh ...)
	}
	PostRead() {
		:	# e.g. cd ${PATH_1650}/SAR_CSL/CSK/Virunga ; ReadModeCSK.sh Virunga 
	}
	PostPairs() {
		:	# called once per mode with $1 = mode index, after the pair selection; e.g.
			# cd ${MODE_SET[$1]} ; Select_xDays_MaxBp_Pairs.py allPairsListing.txt +MinDays=80 +MaxDays=120 +MaxBp=30
	}

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                       END OF USER PARAMETERS - do not edit below 
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

MODES="${!MODE_NAME[@]}"		# list of active mode indices
LOGFILE=${LOGDIR}/Last_Run_Cron_Step1.txt
LOCKDIR=${LOGDIR}/.lock_${PRG}

# Functions
###########
function Log()
	{
	echo "$(date) - $*"
	echo "$(date) - $*" >> "${LOGFILE}"
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

function Throttle()
	{
	# Wait until less than MAXPARALLEL background jobs are running (no limit if 0)
	if [ "${MAXPARALLEL}" -gt 0 ] 2>/dev/null ; then 
		while [ "$(jobs -pr | wc -l)" -ge "${MAXPARALLEL}" ] ; do sleep 30 ; done
	fi
	}

function GetParam()
	{
	# Get value of a key in a LaunchMTparam file (same convention as SuperMasterCoreg.sh)
	${PATHGNU}/grep -m 1 "$1" "$2" | cut -f1 -d \# | ${PATHGNU}/gsed "s/[[:space:]]//g"
	}

function NewData()
	{
	# Return true (0) if SuperMasterCoreg.sh did not flag the mode as having no new data
	[ ! -s "${MODE_RESAMPLED[$1]}/_No_New_Data_Today.txt" ]
	}

function FirstImageDate()
	{
	# Oldest acquisition date (yyyymmdd) among the images linked in a seti dir
	ls "$1" 2>/dev/null | ${PATHGNU}/grep '\.csl$' | ${PATHGNU}/grep -oE '[12][0-9]{3}[01][0-9][0-3][0-9]' | sort | head -1
	}

function RunPrepa()
	{
	# Compute pairs for mode $1 with one or two baseline criteria
	local i=$1
	local SET=${MODE_SET[$i]}
	local SM=${MODE_SM[$i]}
	local PREPALOG=${SET}/_Last_Prepa_MSBAS_From_Cron.log
	set -- ${MODE_BPBT[$i]}
	if [ $# -eq 5 ] 
		then 
			local FIRST=$(FirstImageDate "${SET}")
			if [ "${FIRST}" != "" ] && [ "${FIRST}" -ge "$5" ] 
				then 
					# all images are after the date of change: only the second criterion applies 
					echo "n" | Prepa_MSBAS.sh "${SET}" "$3" "$4" "${SM}" > "${PREPALOG}" 2>&1
					# keep the double-criterion name expected at steps 2 and 3
					cp -f "${SET}/table_0_$3_0_$4.txt" "${SET}/table_0_$1_0_$2_Till_$5_0_$3_0_$4_After.txt"
					cp -f "${SET}/table_0_$3_0_$4.txt" "${SET}/table_0_$1_0_$2_Till_$5_0_$3_0_$4_After_WITHHEADER.txt"
				else 
					echo "n" | Prepa_MSBAS.sh "${SET}" "$1" "$2" "${SM}" "$3" "$4" "$5" > "${PREPALOG}" 2>&1
			fi
		else 
			echo "n" | Prepa_MSBAS.sh "${SET}" "$1" "$2" "${SM}" > "${PREPALOG}" 2>&1
	fi
	}

function RecheckQuarantine()
	{
	# Re-check images in __TMP_QUARANTINE of mode $1 and move the good ones back
	local i=$1
	local QUAR=${MODE_CSL[$i]}/__TMP_QUARANTINE
	if [ ! -d "${QUAR}" ] ; then return ; fi
	_Check_ALL_S1_SizeAndCoord_InDir.sh "${QUAR}" ${MODE_RECHECKQUAR[$i]}
	# images still not compliant are now in __TMP_QUARANTINE/__TMP_QUARANTINE
	mv "${QUAR}"/*.csl "${MODE_CSL[$i]}/" 2>/dev/null
	mv "${QUAR}"/__TMP_QUARANTINE/*.csl "${QUAR}/" 2>/dev/null
	mv "${QUAR}"/*.txt "${MODE_CSL[$i]}/" 2>/dev/null
	rm -rf "${QUAR}/__TMP_QUARANTINE" 2>/dev/null
	}

function EtadLists()
	{
	# Create in MODE_CSL the lists of images having complete ETAD products since ETAD_FIRSTDATE
	local i=$1
	cd "${MODE_CSL[$i]}" || return 1
	CheckETAD.sh
	local LAST=$(${PATHGNU}/gfind . -maxdepth 1 -type f -name "_ETAD_All_OK_*_FROM_${ETAD_FIRSTDATE}.txt" -printf "%T@ %f\n" | sort -n | tail -n 1 | cut -d' ' -f2-)
	if [ "${LAST}" == "" ] ; then Log "No _ETAD_All_OK_*_FROM_${ETAD_FIRSTDATE}.txt in ${MODE_CSL[$i]}" ; return 1 ; fi
	${PATHGNU}/ggrep -oE '[0-9]{8}' "${LAST}" > List_ImgDate_All_ETAD.txt			# used to link images
	${PATHGNU}/gsed -E 's/.*\.\.\///g' "${LAST}" > List_ImgName_All_ETAD.txt		# used for coregistration
	cd - > /dev/null
	}

# Check parameters (errors stop the run; warnings are only logged)
##################
mkdir -p "${LOGDIR}"
echo "Starting $0" > "${LOGFILE}"
date >> "${LOGFILE}"

if ! AcquireLock ; then Log "Another ${PRG} is still running: exit" ; exit 0 ; fi

if [ "${MODES}" == "" ] ; then Log "ERROR: no mode defined" ; exit 1 ; fi
for i in ${MODES} ; do
	for VAR in MODE_CSL MODE_SET MODE_SM MODE_PARAMCOREG MODE_RESAMPLED MODE_BPBT ; do
		eval "VAL=\${${VAR}[$i]}"
		if [ "${VAL}" == "" ] ; then Log "ERROR: ${VAR}[$i] is empty" ; exit 1 ; fi
	done
	set -- ${MODE_BPBT[$i]}
	if [ $# -ne 2 ] && [ $# -ne 5 ] ; then Log "ERROR: MODE_BPBT[$i] must contain 2 or 5 values" ; exit 1 ; fi
	if [ "${DO_COREG}" == "YES" ] ; then 
		if [ ! -f "${MODE_PARAMCOREG[$i]}" ] ; then Log "ERROR: missing ${MODE_PARAMCOREG[$i]}" ; exit 1 ; fi
		PARAMSM=$(GetParam SUPERMASTER "${MODE_PARAMCOREG[$i]}")
		if [ "${PARAMSM}" != "${MODE_SM[$i]}" ] ; then 
			Log "WARNING: mode ${MODE_NAME[$i]}: MODE_SM=${MODE_SM[$i]} but SUPERMASTER=${PARAMSM} in $(basename ${MODE_PARAMCOREG[$i]})"
		fi
	fi
	case "$(basename "${MODE_RESAMPLED[$i]}")" in 
		*"${MODE_SM[$i]}"*) ;; 
		*) Log "WARNING: mode ${MODE_NAME[$i]}: MODE_RESAMPLED does not contain the Global Primary date ${MODE_SM[$i]}" ;;
	esac
	if [ ! -d "${MODE_RESAMPLED[$i]}" ] ; then 
		Log "WARNING: mode ${MODE_NAME[$i]}: ${MODE_RESAMPLED[$i]} does not exist (yet); pairs will be recomputed at each run"
	fi
	if [ "${ETAD}" == "YES" ] && [ "${MODE_ETAD_UNZIP[$i]}" == "" ] ; then Log "ERROR: ETAD=YES but MODE_ETAD_UNZIP[$i] is empty" ; exit 1 ; fi
	mkdir -p "${MODE_SET[$i]}"
done

# Read images 
#############
if [ "${DO_READ}" == "YES" ] ; then 
	PreRead
	for k in "${!READ_RAW[@]}" ; do
		Log "Read ${READ_RAW[$k]} in ${READ_CSL[$k]}"
		${PATH_SCRIPTS}/SCRIPTS_MT/Read_All_Img.sh "${READ_RAW[$k]}" "${READ_CSL[$k]}" ${SAT} ${READ_OPTS[$k]} > /dev/null 2>&1
	done
	PostRead
fi

# Get ETAD products 
###################
if [ "${ETAD}" == "YES" ] ; then 
	TODAY=$(${PATHGNU}/gdate "+%Y%m%d")
	if [ "${ETAD_DOWNLOAD}" == "YES" ] ; then 
		for i in ${MODES} ; do
			# download from the last product already available
			LASTETAD=$(printf "%s\n" "${MODE_ETAD_ZIP[$i]}"/*.zip | ${PATHGNU}/grep -oE '[0-9]{8}T[0-9]{6}' | cut -dT -f1 | sort -u | tail -n 1)
			if [ "${LASTETAD}" == "" ] ; then LASTETAD=${ETAD_FIRSTDATE} ; fi
			Download_ETAD_UNZIP_Add2CSL.sh ${LASTETAD} ${TODAY} "${ETAD_KML}" "${MODE_ETAD_ZIP[$i]}" ${MODE_ETAD_ORB[$i]} "${MODE_CSL[$i]}/" &
		done
		wait
	fi
	DATEMINUSX=$(${PATHGNU}/gdate -d "-${ETAD_REREAD_DAYS} days" "+%Y%m%d")
	for i in ${MODES} ; do
		ReadETAD.sh "${MODE_CSL[$i]}/" "${MODE_ETAD_UNZIP[$i]}" ${DATEMINUSX} &
	done
	wait
fi

# Check nr of bursts and footprint (S1). Non compliant images go in __TMP_QUARANTINE. 
#######################################################################################
# If an image stays there for days, it is probably bad or its zip was not correctly downloaded.
for i in ${MODES} ; do
	if [ "${MODE_BURSTCHECK[$i]}" != "" ] ; then 
		_Check_ALL_S1_SizeAndCoord_InDir.sh "${MODE_CSL[$i]}" ${MODE_BURSTCHECK[$i]} &
	fi
done
wait
for i in ${MODES} ; do
	if [ "${MODE_RECHECKQUAR[$i]}" != "" ] ; then RecheckQuarantine $i & fi
done
wait

# Lists of images with ETAD products
####################################
if [ "${ETAD}" == "YES" ] ; then 
	for i in ${MODES} ; do EtadLists $i ; done
fi

# Coregister on Global Primary and link images in seti dirs
###########################################################
for i in ${MODES} ; do
	if [ "${ETAD}" == "YES" ] 
		then 
			LSTDATES="${MODE_CSL[$i]}/List_ImgDate_All_ETAD.txt"
			LSTNAMES="${MODE_CSL[$i]}/List_ImgName_All_ETAD.txt"
		else 
			LSTDATES=""
			LSTNAMES=""
	fi
	if [ "${DO_COREG}" == "YES" ] ; then 
		Throttle
		Log "Coregister mode ${MODE_NAME[$i]} on ${MODE_SM[$i]}"
		if [ "${LSTNAMES}" == "" ] 
			then 
				${PATH_SCRIPTS}/SCRIPTS_MT/SuperMasterCoreg.sh "${MODE_PARAMCOREG[$i]}" &
			else 
				${PATH_SCRIPTS}/SCRIPTS_MT/SuperMasterCoreg.sh "${MODE_PARAMCOREG[$i]}" NoForce "${LSTNAMES}" &
		fi
	fi
	${PATH_SCRIPTS}/SCRIPTS_MT/lns_All_Img.sh "${MODE_CSL[$i]}" "${MODE_SET[$i]}" ${SAT} ${LSTDATES} > /dev/null 2>&1 &
done
# Mandatory: _No_New_Data_Today.txt is only valid once all coregistrations are finished
wait

# Compute pairs only for modes with new data
############################################
NEWDATA=NO
for i in ${MODES} ; do
	if NewData $i 
		then 
			Log "New data in mode ${MODE_NAME[$i]}: compute pairs"
			NEWDATA=YES
			RunPrepa $i &
		else 
			Log "No new data in mode ${MODE_NAME[$i]}"
	fi
done
wait

# Additional pair selections (always run: cheap and accounts for possible newly quarantined images)
############################
for i in ${MODES} ; do
	cd "${MODE_SET[$i]}" || continue
	for NR in ${MODE_SHORTEST[$i]} ; do
		Extract_x_Shortest_Connections.sh "${MODE_SET[$i]}/allPairsListing.txt" ${NR}
	done
	for RATIO in ${MODE_DELAUNAY[$i]} ; do
		if [ "${RATIO}" == "NONE" ] ; then DelaunayTable.sh ; else DelaunayTable.sh -Ratio=${RATIO} ; fi
	done
	PostPairs $i
done

# Common baseline plot
######################
if [ "${MULTIPLOT}" != "" ] && [ "${NEWDATA}" == "YES" ] ; then 
	PLOTNAME="BaselinePlots"
	for i in ${MULTIPLOT} ; do PLOTNAME="${PLOTNAME}_$(basename "${MODE_SET[$i]}")" ; done
	FIRSTMODE=$(echo ${MULTIPLOT} | cut -d " " -f 1)
	PLOTDIR=$(dirname "${MODE_SET[${FIRSTMODE}]}")/${PLOTNAME}
	mkdir -p "${PLOTDIR}"
	cd "${PLOTDIR}"
	rm -f ModeList.txt
	for i in ${MULTIPLOT} ; do echo "${MODE_SET[$i]}" >> ModeList.txt ; done
	if command -v baselinePlot > /dev/null 2>&1 
		then
			# AMSTer Engine since May 2022
			plot_Multi_BaselinePlot.sh "${PLOTDIR}/ModeList.txt"
		else
			# AMSTer Engine before May 2022
			set -- ${MODE_BPBT[${FIRSTMODE}]}
			${PATH_SCRIPTS}/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 $1 0 $2 "${COLORTABLE}"
	fi
fi

# Clean old ETAD check files
############################
if [ "${ETAD}" == "YES" ] ; then 
	for i in ${MODES} ; do
		${PATHGNU}/gfind "${MODE_CSL[$i]}" -maxdepth 1 -type f \( -name "_ETAD_All_OK_*.txt" -o -name "_ETAD_Missing_*.txt" \) -mtime +${ETAD_KEEPLOGS} -exec rm -f {} \;
	done
fi

echo "Ending $0" >> "${LOGFILE}"
date >> "${LOGFILE}"
