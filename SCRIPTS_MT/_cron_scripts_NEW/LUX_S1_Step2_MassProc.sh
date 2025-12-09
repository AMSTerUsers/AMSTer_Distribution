#!/bin/bash
# Script to run in cronjob for processing LUX images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
# NOTE: because LUX_S1_Step1_Read_SMCoreg_Pairs.sh uses RadAll_Img.sh, which also move updated prelim orbit images at all levels in _CLN dir,
#       and coregister images on Global Primaries (SuperMasters), one check that it is not running anymore before starting.
#
#
# New in Distro V 2.0 20201104:	- move all parameters at the beginning
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20240702:	- enlarge Bp2 from 30 to 70m to account for orbital drift
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
BP=20
BT=400

BP2=70
BT2=400
DATECHG=20220501

STEP1="LUX_S1_Step1_Read_SMCoreg_Pairs.sh"

SMASC2=20190406		# Asc 88
SMDESC3=20210920		# Desc 139

# some files and PATH
#####################
TABLEASC=$PATH_1660/SAR_SM/MSBAS/LUX/set2/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt
TABLEDESC=$PATH_1660/SAR_SM/MSBAS/LUX/set6/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt

PARAMPROCESSASC=$PATH_DataSAR/SAR_AUX_FILES/Param_files/S1/LUX_A_88/LaunchMTparam_S1_LUX_A_88_Zoom1_ML2_MassProc_0keep.txt
PARAMPROCESSDESC=$PATH_DataSAR/SAR_AUX_FILES/Param_files/S1/LUX_D_139/LaunchMTparam_S1_LUX_D_139_Zoom1_ML2_MassProc_0keep.txt

MASSPROCESSASCDIR=${PATH_3610}/SAR_MASSPROCESS/S1/LUX_A_88/SMNoCrop_SM_${SMASC2}_Zoom1_ML2
MASSPROCESSDESCDIR=${PATH_3610}/SAR_MASSPROCESS/S1/LUX_D_139/SMNoCrop_SM_${SMDESC3}_Zoom1_ML2

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

