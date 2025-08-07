#!/bin/bash
# Script to run in cronjob for processing GALERAS images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
# NOTE: text not updated yet below 
#		usually by running the reading and coregistration at 1 am, it is finished around 1am30
#       hence this script should be safely launched around 2 am for instance.
#       Nevertheless because VVP_S1_Step1_Read_SMCoreg_Pairs.sh uses RadAll_Img.sh, which also move updated prelim orbit images at all levels in _CLN dir,
#       and coregister images on Global Primaries (SuperMasters), one check that it is not running anymore before starting.
#
#
# New in Distro V 1.0.0 20250411 :	- based on Guadeloupe processing
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

echo "Starting $0"
cd

BP=40
BT=150
BP2=50 
BT2=150
DATECHG=20240201



# some files
############

#mode SM
TABLEASC=$PATH_1650/SAR_SM/MSBAS/GALERAS/set1/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt	# do not take _WITHHEADER.txt because it does not contains the AddirionbalPairs
TABLEDESC=$PATH_1650/SAR_SM/MSBAS/GALERAS/set2/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt	# do not take _WITHHEADER.txt because it does not contains the AddirionbalPairs


PARAMPROCESSASC=$PATH_1650/Param_files/S1/GALERAS_A_120/LaunchMTparam_S1_IW_Galeras_A_Zoom1_ML2_MassProc.txt
PARAMPROCESSDESC=$PATH_1650/Param_files/S1/GALERAS_D_142/LaunchMTparam_S1_IW_Galeras_D_Zoom1_ML2_MassProc.txt

PARAMASCNAME=`basename ${PARAMPROCESSASC}`
PARAMDESCNAME=`basename ${PARAMPROCESSDESC}`

STEP1="GALERAS_S1_Step1_Read_Coreg_Pairs.sh"

SMASC=20190126
SMDESC=20180906

MASSPROCDIRASC=$PATH_3601/SAR_MASSPROCESS/S1/GALERAS_A_120/SMNoCrop_SM_${SMASC}_Zoom1_ML2
MASSPROCDIRDESC=$PATH_3601/SAR_MASSPROCESS/S1/GALERAS_D_142/SMNoCrop_SM_${SMDESC}_Zoom1_ML2

TODAY=`date`

## first restric pair table to last data  
#RemovePairsFromFlist_WithImagesBefore.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1/table_0_20_0_450.txt 20190425
#RemovePairsFromFlist_WithImagesBefore.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2/table_0_20_0_450.txt 20190430
#TABLEASC=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1/table_0_20_0_450.txt_Below20190425_NoBaselines_${TODAY}.txt
#TABLEDESC=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2/table_0_20_0_450.txt_Below20190430_NoBaselines_${TODAY}.txt


# Check that GUADELOUPE_S1_Step1_Read_Coreg_Pairs.sh is finished
CHECKREAD=`ps -eaf | ${PATHGNU}/grep "${STEP1}" | ${PATHGNU}/grep -v "grep " | wc -l`

if [ ${CHECKREAD} -eq 0 ] 
	then 
		# OK, no more GUADELOUPE_S1_Step1_Read_SMCoreg_Pairs.sh is running: 
		# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet

		CHECKASC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMASCNAME} | wc -l`
		CHECKDESC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMDESCNAME} | wc -l`

 		if [ ${CHECKASC} -lt 1 ] 
 			then 
 				# No process running yet
 				echo "Asc run on ${TODAY}"  >>  ${MASSPROCDIRASC}/_Desc_last_MassRun.txt
 				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC} ${PARAMPROCESSASC} > /dev/null 2>&1 &
 			else 
 				echo "Asc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCDIRASC}/_Asc_last_aborted.txt
 		fi
		# if riunning yet we will try egain tomorrow

 		if [ ${CHECKDESC} -lt 1 ] 
 			then 
 				# No process running yet
				echo "Desc run on ${TODAY}"  >>  ${MASSPROCDIRDESC}/_Desc_last_MassRun.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC} ${PARAMPROCESSDESC} > /dev/null 2>&1 &
 			else 
 				echo "Desc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${MASSPROCDIRDESC}/_Desc_last_aborted.txt
 		fi
	else 
		# VVP_S1_Step1_Read_SMCoreg_Pairs.sh is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because GALERAS_S1_Step1_Read_Coreg_Pairs.sh is still running: wait for tomorrow"  >>  ${MASSPROCDIRASC}/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because GALERAS_S1_Step1_Read_Coreg_Pairs.sh is still running: wait for tomorrow"  >> ${MASSPROCDIRDESC}/_aborted_because_Read_inProgress.txt

		exit 0
fi

