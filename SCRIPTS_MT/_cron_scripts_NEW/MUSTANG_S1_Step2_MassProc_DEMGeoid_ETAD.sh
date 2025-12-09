#!/bin/bash
# Script to run in cronjob for processing MUSTANG images with EATD data:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#

# New in Distro V 1.0 20251031:	- based on Domuyo step 2 ETAD
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
BP=30
BT=400
BP2=70 
BT2=400
DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC=20241116		# Asc 158
SMDESC=20190830		# Desc 19


# some files and PATH
#####################

# table files

TABLEASC=$PATH_1660/SAR_SM/MSBAS/MUSTANG/set11/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt	# exist anyway even if first ETAD is after DATECHG because copied at cron step 1
TABLEDESC=$PATH_1660/SAR_SM/MSBAS/MUSTANG/set12/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt	# exist anyway even if first ETAD is after DATECHG because copied at cron step 1
# if table duplicated and rename at cron step 1:
#TABLEASC=$PATH_1660/SAR_SM/MSBAS/MUSTANG/set11/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt	# exist anyway even if first ETAD is after DATECHG because copied at cron step 1
#TABLEDESC=$PATH_1660/SAR_SM/MSBAS/MUSTANG/set12/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After_WITHHEADER.txt	# exist anyway even if first ETAD is after DATECHG because copied at cron step 1
#TABLEASC=$PATH_1660/SAR_SM/MSBAS/MUSTANG/set11/table_0_${BP2}_0_${BT2}.txt	# exist anyway even if first ETAD is after DATECHG because copied at cron step 1
#TABLEDESC=$PATH_1660/SAR_SM/MSBAS/MUSTANG/set12/table_0_${BP2}_0_${BT2}.txt	# exist anyway even if first ETAD is after DATECHG because copied at cron step 1

#Launch param files
PARAMPROCESSASC=$PATH_1650/Param_files/S1/MUSTANG_A_158/LaunchMTparam_S1_Mustang_A_158_Zoom1_ML2_MassProc_0keep_ETAD.txt
PARAMPROCESSDESC=$PATH_1650/Param_files/S1/MUSTANG_D_19/LaunchMTparam_S1_Mustang_D_19_Zoom1_ML2_MassProc_0keep_ETAD.txt

PARAMASCNAME=`basename ${PARAMPROCESSASC}`
PARAMDESCNAME=`basename ${PARAMPROCESSDESC}`

#mass Process dir
MASSPROCESSASCDIR=$PATH_3611/SAR_MASSPROCESS_ETAD/S1/MUSTANG_A_158/SMNoCrop_SM_${SMASC}_Zoom1_ML2
MASSPROCESSDESCDIR=$PATH_3611/SAR_MASSPROCESS_ETAD/S1/MUSTANG_D_19/SMNoCrop_SM_${SMDESC}_Zoom1_ML2


# Name of step 1 cron script
CRONSTEP1="MUSTANG_S1_Step1_Read_SMCoreg_Pairs_DEMGeoid_ETAD.sh"


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

