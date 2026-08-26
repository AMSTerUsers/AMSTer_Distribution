#!/bin/bash
# Script to run in cronjob for processing Cordoba BIOMASS images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
#
# Because not many BIOMASS data, we use tables with max 3 shortest connections for the test
#
# New in Distro V 1.0 20260826:	- 

# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
source $HOME/.bashrc

cd
TODAY=`date`

echo "Starting $0"

# Some variables 
################

## Max  baseline (for buliding msbas files) - not needed here because use shortest connections
#BP=30
#BP2=70
#BT=400
#DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC1=20251201		# Asc21

# DO NOT FORGET TO ADJUST ALSO THE SET BELOWS IN SCRIPT

# Nr of shortests connections for Baseline plot
NR=3

STEP1="Cordoba_BIOMASS_Step1_Read_SMCoreg_Pairs.sh"

# some files and PATH
#####################

#SETi DIR
DIRSET=$PATH_1650/SAR_SM/MSBAS/Cordoba

TABLEASC1=${DIRSET}/set1/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt




#Launch param files
PARAMPROCESSASC1=$PATH_1650/Param_files/BIOMASS/Cordoba/LaunchMTparam_BIOMASS_Full_Zoom1_ML2_test.txt

MASSPROCESSASCDIR1=$PATH_1660/SAR_MASSPROCESS/BIOMASS/Cordoba_Asc21


# Prepare stuffs
################
PARAMASCNAME1=`basename ${PARAMPROCESSASC1}`


# Check that no other processes are running
###########################################

# Check that Step 1 (Read and Coreg) is finished
CHECKREAD=`ps -eaf | ${PATHGNU}/grep ${STEP1} | ${PATHGNU}/grep -v "grep " | grep -v "Crons_1_2_3.sh"  | wc -l`

# Let's go
##########
if [ ${CHECKREAD} -eq 0 ] 
	then 
		# OK, no more Step1 is running: 
		# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
		CHECKASC1=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMASCNAME1} | grep -v "Crons_1_2_3.sh"  | wc -l`
	
		if [ ${CHECKASC1} -lt 1 ] 
			then 
				# No process running yet
				echo "Asc 21 run on ${TODAY}"  >>  ${MASSPROCESSASCDIR1}/_Asc_21_last_MassRun.txt 2>/dev/null
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC1} ${PARAMPROCESSASC1} > /dev/null 2>&1 &
			else 
				echo "Asc 21 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${PARAMPROCESSASC1}/_Asc_21_last_aborted.txt
		fi


	else 
		# Step1 is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSASCDIR1}/_aborted_because_Read_inProgress.txt

		exit 0
fi


#beware: the wait is mandatory to allow waiting for the end of cron2 before launching cron 3
wait