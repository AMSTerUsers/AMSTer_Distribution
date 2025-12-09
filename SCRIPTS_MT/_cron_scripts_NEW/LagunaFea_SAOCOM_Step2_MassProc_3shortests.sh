#!/bin/bash
# Script to run in cronjob for processing SAOCOM LagunaFea images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
# NOTE: because LagunaFea_SACOM_Step1_Read_SMCoreg_Pairs.sh uses RadAll_Img.sh, which also move updated images at all levels in _CLN dir,
#       and coregister images on Global Primaries (SuperMasters), one check that it is not running anymore before starting.
#
#
# New in Distro V 1.0 20231110:	- init
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
source $HOME/.bashrc

cd
TODAY=`date`

echo "Starting $0"

# Some variables 
################

# Max  baseline (for buliding msbas files)
#BP=600
#BT=400
#
#BP2=
#BT2=
#DATECHG=

STEP1="LagunaFea_SAOCOM_Step1_Read_SMCoreg_Pairs.sh"

SMASC1=20231010		# Asc 042_A
SMDESC1=20231105	# Desc 152_D

# some files and PATH
#####################
SET1=${PATH_1650}/SAR_SM/MSBAS/LagunaFea/set1
SET2=${PATH_1650}/SAR_SM/MSBAS/LagunaFea/set2

# Tables names
TABLEASC=${SET1}/table_0_0_MaxShortest_3.txt
TABLEDESC=${SET2}/table_0_0_MaxShortest_3.txt

PARAMPROCESSASC=$PATH_1650/Param_files/SAOCOM/LagunaFea_042_A/LaunchMTparam_SAOCOM_LagunaFea_Asc_Zoom1_ML8_SM.txt
PARAMPROCESSDESC=$PATH_1650/Param_files/SAOCOM/LagunaFea_152_D/LaunchMTparam_SAOCOM_LagunaFea_Desc_Zoom1_ML8_SM.txt

MASSPROCESSASCDIR=${PATH_3601}/SAR_MASSPROCESS/SAOCOM/LagunaFea_042_A/SMNoCrop_SM_${SMASC1}_Zoom1_ML8
MASSPROCESSDESCDIR=${PATH_3601}/SAR_MASSPROCESS/SAOCOM/LagunaFea_152_D/SMNoCrop_SM_${SMDESC1}_Zoom1_ML8

# Prepare stuffs
################
PARAMASCNAME=`basename ${PARAMPROCESSASC}`
PARAMDESCNAME=`basename ${PARAMPROCESSDESC}`

# Check that no other processes are running
###########################################

# Check that Step 1 (Read and Coreg) is finished
CHECKREAD=`ps -eaf | ${PATHGNU}/grep ${STEP1} | ${PATHGNU}/grep -v "grep " | wc -l`

# Let's go
##########
if [ ${CHECKREAD} -eq 0 ] 
	then 
		# OK, no more Step1 is running: 
		# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
		CHECKASC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMASCNAME} | wc -l`
		CHECKDESC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMDESCNAME} | wc -l`
		if [ ${CHECKASC} -lt 1 ] 
			then 
				# No process running yet
				echo "Asc run on ${TODAY}"  >>  ${MASSPROCESSASCDIR}/_Asc_last_MassRun.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC} ${PARAMPROCESSASC} > /dev/null 2>&1 &
			else 
				echo "Asc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSASCDIR}/_Asc_last_aborted.txt
		fi
		# if running yet we will try again tomorrow

		if [ ${CHECKDESC} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc run on ${TODAY}"  >>  ${MASSPROCESSDESCDIR}/_Desc_last_Mass.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC} ${PARAMPROCESSDESC} > /dev/null 2>&1 &
			else 
				echo "Desc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSDESCDIR}/_Desc_last_aborted.txt
		fi
	else 
		# Step1 is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSASCDIR}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSDESCDIR}/_aborted_because_Read_inProgress.txt

		exit 0
fi

