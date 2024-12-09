#!/bin/bash
# Script to run in cronjob for processing Funu images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
#
# New in Distro V 2.0.0 2024xxxx :	- 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
source $HOME/.bashrc

cd
TODAY=`date`

echo "Starting $0"

# Some variables
#################

SMASC1=20160608
SMDESC1=20160517

STEP1="Funu_S1_Step1_Read_SMCoreg_Pairs.sh"

# some files and PATH
#####################
SET1=${PATH_1660}/SAR_SM/MSBAS/Funu/set1
SET2=${PATH_1660}/SAR_SM/MSBAS/Funu/set2

# Tables names
TABLEASC=${SET1}/table_0_0_MaxShortest_3.txt
TABLEDESC=${SET2}/table_0_0_MaxShortest_3.txt

PARAMPROCESSASC=$PATH_1650/Param_files/S1/DRC_Funu_A_174/LaunchMTparam_S1_Funu_Asc_Zoom1_ML2_snaphu_square_MassPro.txt
PARAMPROCESSDESC=$PATH_1650/Param_files/S1/DRC_Funu_D_21/LaunchMTparam_S1_Funu_Desc_Zoom1_ML2_snaphu_square_MassPro.txt

MASSPROCESSASCDIR=${PATH_1660}/SAR_MASSPROCESS/S1/DRC_Funu_A_174/SMNoCrop_SM_${SMASC1}_Zoom1_ML2
MASSPROCESSDESCDIR=${PATH_1660}/SAR_MASSPROCESS/S1/DRC_Funu_D_21/SMNoCrop_SM_${SMDESC1}_Zoom1_ML2

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
				echo "Asc attempt aborted on ${TODAY} because other Mass Process in progress"  >>   ${MASSPROCESSASCDIR}/_Asc_last_aborted.txt
		fi
		# if riunning yet we will try egain tomorrow

		if [ ${CHECKDESC} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc run on ${TODAY}"  >>  ${MASSPROCESSDESCDIR}/_Desc_last_Mass.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC} ${PARAMPROCESSDESC} > /dev/null 2>&1 &
			else 
				echo "Desc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSDESCDIR}/_Desc_last_aborted.txt
		fi
	else 
		# VVP_S1_Step1_Read_SMCoreg_Pairs.sh is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >> ${MASSPROCESSASCDIR}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >> ${MASSPROCESSDESCDIR}/_aborted_because_Read_inProgress.txt

		exit 0
fi

