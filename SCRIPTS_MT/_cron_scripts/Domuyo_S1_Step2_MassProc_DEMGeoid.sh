#!/bin/bash
# Script to run in cronjob for processing Domuyo images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
# NOTE: usualy by running the reading and coregistration at 1 am, it is finished around 1am30
#       hence this script should be safely launched around 2 am for instance.
#       Nevertheless because VVP_S1_Step1_Read_SMCoreg_Pairs.sh uses RadAll_Img.sh, which also move updated prelim orbit images at all levels in _CLN dir,
#       and coregister images on Global Primary (super masters), one check that it is not running anymore before starting.
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20231116:	- Reshape with variables
#								- double criteria to compute baseline plot in order to account for the loss of S1B
# New in Distro V 4.0.0 20240530:	- reprocessing with DEM referred to Geoid 
# New in Distro V 4.1.0 20240624:	- enlarge BP2 (from back to 20220501) to cope with new S1 orbital tube from 05 2024

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/25 - could make better... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

echo "Starting $0"
cd


# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=20
BP2=80
BT=450
BT2=450
DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC=20180512		# Asc 18
SMDESC=20180222		# Desc 83


# some files and PATH
#####################

# table files
TABLEASC=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt
TABLEDESC=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt

#Launch param files
PARAMPROCESSASC=$PATH_1650/Param_files/S1/ARG_DOMU_LAGUNA_A_18/LaunchMTparam_S1_Arg_Domu_Laguna_A_18_Zoom1_ML4_MassProc_MaskCohWater_DEMGeoid.txt
PARAMPROCESSDESC=$PATH_1650/Param_files/S1/ARG_DOMU_LAGUNA_D_83/LaunchMTparam_S1_Arg_Domu_Laguna_D_83_Zoom1_ML4_MassProc_Snaphu_WaterCohMask_DEMGeoid.txt

PARAMASCNAME=`basename ${PARAMPROCESSASC}`
PARAMDESCNAME=`basename ${PARAMPROCESSDESC}`

#mass Process dir
MASSPROCESSASCDIR=$PATH_3602/SAR_MASSPROCESS_2/S1/ARG_DOMU_LAGUNA_DEMGeoid_A_18/SMNoCrop_SM_20180512_Zoom1_ML4
MASSPROCESSDESCDIR=$PATH_3602/SAR_MASSPROCESS_2/S1/ARG_DOMU_LAGUNA_DEMGeoid_D_83/SMNoCrop_SM_20180222_Zoom1_ML4


# Name of step 1 cron script
CRONSTEP1="Domuyo_S1_Step1_Read_SMCoreg_Pairs_DEMGeoid.sh"


#
# Let's Go
##########


TODAY=`date`

## first restric pair table to last data  
#RemovePairsFromFlist_WithImagesBefore.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1/table_0_20_0_450.txt 20190425
#RemovePairsFromFlist_WithImagesBefore.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2/table_0_20_0_450.txt 20190430


# Check that Domuyo_S1_Step1_Read_SMCoreg_Pairs.sh is finished
#CHECKREAD=`ps -eaf | ${PATHGNU}/grep Domuyo_S1_Step1_Read_SMCoreg_Pairs.sh | ${PATHGNU}/grep -v "grep " | wc -l`
# below will be 0 if no run and 2 if script is running (3 if two runs are in preogress etc...) 
CHECKREAD=`ps -eaf | ${PATHGNU}/grep ${CRONSTEP1} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "dev/null" | wc -l`

if [ ${CHECKREAD} -eq 0 ] 
	then 
		# OK, no more Domuyo_S1_Step1_Read_SMCoreg_Pairs.sh is running: 
		# Check that no other Global Primary (SuperMaster) automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
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
		echo "Step2 aborted on ${TODAY} because DOMUYO_S1_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  ${MASSPROCESSASCDIR}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because DOMUYO_S1_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  ${MASSPROCESSDESCDIR}/_aborted_because_Read_inProgress.txt

		exit 0
fi

