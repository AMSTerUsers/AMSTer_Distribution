#!/bin/bash
# Script to run in cronjob for processing NEPAL NISAR images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
#
# Because NEPAL processing is aiming at looking for landslides, we use tables with max 3 shortest connections 
#
# New in Distro V 2.0 20260115:	- in check running process, do not take into account Crons_1_2_3.sh 
#								- add wait at the end

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
SMASC1=20251128			# Asc98 FreqA LL Frame16 40Mhz 41deg
SMDESC1=20260112		# Desc48 FreqA LL Frame74 20Mhz 41deg
SMDESC2=20251207				# Desc48 FreqA LL Frame74 40Mhz 41deg -> unused because only one img as on march 2026

# DO NOT FORGET TO ADJUST ALSO THE SET BELOWS IN SCRIPT

# Nr of shortests connections for Baseline plot
NR=3

STEP1="NEPAL_NISAR_Step1_Read_SMCoreg_Pairs.sh"

# some files and PATH
#####################

#SETi DIR
DIRSET=$PATH_1660/SAR_SM/MSBAS/NEPAL

TABLEASC1=${DIRSET}/set11/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt

TABLEDESC1=${DIRSET}/set13/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt
TABLEDESC2=${DIRSET}/set15/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt	



#Launch param files
PARAMPROCESSASC1=$PATH_1650/Param_files/NISAR/NEPAL_FreqA_A98_LL_Frame16_40Mhz_41deg/LaunchMTparam_NISAR_A98_FreqA_Zoom1_ML4_MassProc.txt 

PARAMPROCESSDESC1=$PATH_1650/Param_files/NISAR/NEPAL_FreqA_D48_LL_Frame74_20Mhz_41deg/LaunchMTparam_NISAR_D48_FreqA_Zoom1_ML4_MassProc.txt
PARAMPROCESSDESC2=$PATH_1650/Param_files/NISAR/NEPAL_FreqA_D48_LL_Frame74_40Mhz_41deg/LaunchMTparam_NISAR_D48_FreqA_Zoom1_ML4_MassProc.txt

MASSPROCESSASCDIR1=$PATH_3612/SAR_MASSPROCESS/NISAR/NEPAL_FreqA_A98_LL_Frame16_40Mhz_41deg

MASSPROCESSDESCDIR1=$PATH_3612/SAR_MASSPROCESS/NISAR/NEPAL_FreqA_D48_LL_Frame74_20Mhz_41deg
MASSPROCESSDESCDIR2=$PATH_3612/SAR_MASSPROCESS/NISAR/NEPAL_FreqA_D48_LL_Frame74_40Mhz_41deg


# resampled dir
#NEWASCPATH1=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_A_85/SMNoCrop_SM_${SMASC2}
#NEWASCPATH2=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_A_158/SMNoCrop_SM_${SMASC2}
#
#NEWDESCPATH1=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_D_19/SMNoCrop_SM_${SMDESC3}
#NEWDESCPATH2=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_D_92/SMNoCrop_SM_${SMDESC3}
#NEWDESCPATH3=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_D_121/SMNoCrop_SM_${SMDESC3}

# Prepare stuffs
################
PARAMASCNAME1=`basename ${PARAMPROCESSASC1}`

PARAMDESCNAME1=`basename ${PARAMPROCESSDESC1}`
PARAMDESCNAME2=`basename ${PARAMPROCESSDESC2}`	



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
	
		CHECKDESC1=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMDESCNAME1} | grep -v "Crons_1_2_3.sh"  | wc -l`
		CHECKDESC2=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMDESCNAME2} | grep -v "Crons_1_2_3.sh"  | wc -l`

		if [ ${CHECKASC1} -lt 1 ] 
			then 
				# No process running yet
				echo "Asc 98 run on ${TODAY}"  >>  ${MASSPROCESSASCDIR1}/_Asc_98_last_MassRun.txt 2>/dev/null
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC1} ${PARAMPROCESSASC1} > /dev/null 2>&1 &
			else 
				echo "Asc 98 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${PARAMPROCESSASC1}/_Asc_98_last_aborted.txt
		fi

		# if running yet we will try again tomorrow
		if [ ${CHECKDESC1} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc 48 run on ${TODAY}"  >>  ${MASSPROCESSDESCDIR1}/_Desc_48_last_Mass.txt	2>/dev/null
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC1} ${PARAMPROCESSDESC1} > /dev/null 2>&1 &
			else 
				echo "Desc 48 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSDESCDIR1}/_Desc_48_last_aborted.txt
		fi
		
		## if running yet we will try again tomorrow
		if [ ${CHECKDESC2} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc 48 run on ${TODAY}"  >>  ${MASSPROCESSDESCDIR2}/_Desc_48_last_Mass.txt	2>/dev/null
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC2} ${PARAMPROCESSDESC2} > /dev/null 2>&1 &
			else 
				echo "Desc 48 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSDESCDIR2}/_Desc_48_last_aborted.txt
		fi

	else 
		# Step1 is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSASCDIR1}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSDESCDIR1}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSDESCDIR2}/_aborted_because_Read_inProgress.txt

		exit 0
fi


#beware: the wait is mandatory to allow waiting for the end of cron2 before launching cron 3
wait