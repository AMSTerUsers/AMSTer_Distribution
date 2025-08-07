#!/bin/bash
# Script to run in cronjob for processing NEPAL images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
# NOTE: because NEPAL_S1_Step1_Read_SMCoreg_Pairs.sh uses RadAll_Img.sh, which also move updated prelim orbit images at all levels in _CLN dir,
#       and coregister images on Global Primaries (SuperMasters), one check that it is not running anymore before starting.
#
# Because NEPAL processing is aiming at looking for landslides, we use tables with max 3 shortest connections 
#
# New in Distro V 2.0 202
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

## Max  baseline (for buliding msbas files) - not needed here because use shortest connections
#BP=30
#BP2=70
#BT=400
#DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC1=20240328		# Asc 85
SMASC2=20180401		# Asc 158

SMDESC1=20180928		# Desc 19
SMDESC2=20220714		# Desc 92
SMDESC3=20170904		# Desc 121

# DO NOT FORGET TO ADJUST ALSO THE SET BELOWS IN SCRIPT

# Nr of shortests connections for Baseline plot
NR=3

STEP1="NEPAL_S1_Step1_Read_SMCoreg_Pairs.sh"

# some files and PATH
#####################

#SETi DIR
DIRSET=$PATH_1660/SAR_SM/MSBAS/NEPAL

TABLEASC1=${DIRSET}/set1/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt
TABLEASC2=${DIRSET}/set2/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt

TABLEDESC1=${DIRSET}/set3/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt
TABLEDESC2=${DIRSET}/set4/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt
TABLEDESC3=${DIRSET}/set5/table_0_0_MaxShortest_${NR}_Without_Quanrantained_Data.txt


#Launch param files
PARAMPROCESSASC1=$PATH_1650/Param_files/S1/Nepal_A_85/LaunchMTparam_S1_Nepal_A_85_Zoom1_ML2_MassProc_0keep.txt 
PARAMPROCESSASC2=$PATH_1650/Param_files/S1/Nepal_A_158/LaunchMTparam_S1_Nepal_A_158_Zoom1_ML2_MassProc_0keep.txt 

PARAMPROCESSDESC1=$PATH_1650/Param_files/S1/Nepal_D_19/LaunchMTparam_S1_Nepal_D_19_Zoom1_ML2_MassProc_0keep.txt
PARAMPROCESSDESC2=$PATH_1650/Param_files/S1/Nepal_D_92/LaunchMTparam_S1_Nepal_D_92_Zoom1_ML2_MassProc_0keep.txt
PARAMPROCESSDESC3=$PATH_1650/Param_files/S1/Nepal_D_121/LaunchMTparam_S1_Nepal_D_121_Zoom1_ML2_MassProc_0keep.txt


MASSPROCESSASCDIR1=$PATH_3611/SAR_MASSPROCESS/S1/NEPAL_A_85
MASSPROCESSASCDIR2=$PATH_3611/SAR_MASSPROCESS/S1/NEPAL_A_158

MASSPROCESSDESCDIR1=$PATH_3611/SAR_MASSPROCESS/S1/NEPAL_D_19
MASSPROCESSDESCDIR2=$PATH_3611/SAR_MASSPROCESS/S1/NEPAL_D_92
MASSPROCESSDESCDIR3=$PATH_3611/SAR_MASSPROCESS/S1/NEPAL_D_121

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
PARAMASCNAME2=`basename ${PARAMPROCESSASC2}`

PARAMDESCNAME1=`basename ${PARAMPROCESSDESC1}`
PARAMDESCNAME2=`basename ${PARAMPROCESSDESC2}`
PARAMDESCNAME3=`basename ${PARAMPROCESSDESC3}`


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
		CHECKASC1=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMASCNAME1} | wc -l`
		CHECKASC2=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMASCNAME2} | wc -l`

		CHECKDESC1=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMDESCNAME1} | wc -l`
		CHECKDESC2=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMDESCNAME2} | wc -l`
		CHECKDESC3=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMDESCNAME3} | wc -l`
		if [ ${CHECKASC1} -lt 1 ] 
			then 
				# No process running yet
				echo "Asc 85 run on ${TODAY}"  >>  ${MASSPROCESSASCDIR1}/_Asc_85_last_MassRun.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC1} ${PARAMPROCESSASC1} > /dev/null 2>&1 &
			else 
				echo "Asc 85 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${PARAMPROCESSASC1}/_Asc_85_last_aborted.txt
		fi
		if [ ${CHECKASC2} -lt 1 ] 
			then 
				# No process running yet
				echo "Asc 158 run on ${TODAY}"  >>  ${MASSPROCESSASCDIR2}/_Asc_158_last_MassRun.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC2} ${PARAMPROCESSASC2} > /dev/null 2>&1 &
			else 
				echo "Asc 158 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSASCDIR2}/_Asc_158_last_aborted.txt
		fi

		# if running yet we will try again tomorrow
		if [ ${CHECKDESC1} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc 19 run on ${TODAY}"  >>  ${MASSPROCESSDESCDIR1}/_Desc_19_last_Mass.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC1} ${PARAMPROCESSDESC1} > /dev/null 2>&1 &
			else 
				echo "Desc 19 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSDESCDIR1}/_Desc_19_last_aborted.txt
		fi
		if [ ${CHECKDESC2} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc 92 run on ${TODAY}"  >>  ${MASSPROCESSDESCDIR2}/_Desc_92_last_Mass.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC2} ${PARAMPROCESSDESC2} > /dev/null 2>&1 &
			else 
				echo "Desc 92 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSDESCDIR2}/_Desc_92_last_aborted.txt
		fi
		if [ ${CHECKDESC3} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc 121 run on ${TODAY}"  >>  ${MASSPROCESSDESCDIR3}/_Desc_121_last_Mass.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC3} ${PARAMPROCESSDESC3} > /dev/null 2>&1 &
			else 
				echo "Desc 121 attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCESSDESCDIR3}/_Desc_121_last_aborted.txt
		fi
	else 
		# Step1 is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSASCDIR1}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSASCDIR2}/_aborted_because_Read_inProgress.txt

		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSDESCDIR1}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSDESCDIR2}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because ${STEP1} is still running: wait for tomorrow"  >>  ${MASSPROCESSDESCDIR3}/_aborted_because_Read_inProgress.txt

		exit 0
fi

