#!/bin/bash
# Script to run in cronjob for processing Comores island images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
# NOTE: usualy by running the reading and coregistration at 1 am, it is finished around 1am30
#       hence this script should be safely launched around 2 am for instance.
#       Nevertheless because VVP_S1_Step1_Read_SMCoreg_Pairs.sh uses RadAll_Img.sh, which also move updated prelim orbit images at all levels in _CLN dir,
#       and coregister images on Global Primaries (SuperMasters), one check that it is not running anymore before starting.
#
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 6.0 20241112:	- add descending orbit (available since request in October)
# New in Distro V 6.1 20241210:	- Desc orbit only with BT2 and BT2 because acquisition in that mode started after DATECHG
# New in Distro V 7.0 20251208:	- Add IW (Asc)
# New in Distro V 7.1 20260115:	- in check running process, do not take into account Crons_1_2_3.sh 
#								- add wait at the end
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

echo "Starting $0"
cd

# SM mode
BP=50
BT=150

BP2=150
BT2=150
DATECHG=20220501

SMASC=20220713
SMDESC=20241027

# IW mode
BPIW=50
BTIW=150

IWASC=20250727
#IWDESC=

# some files
############

# mode SM #
###########
TABLEASC=$PATH_1650/SAR_SM/MSBAS/KARTHALA/set1/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt
#TABLEDESC=$PATH_1650/SAR_SM/MSBAS/KARTHALA/set2/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt
TABLEDESC=$PATH_1650/SAR_SM/MSBAS/KARTHALA/set2/table_0_${BP2}_0_${BT2}.txt

# mode IW # 
###########
TABLEASCIW=$PATH_1650/SAR_SM/MSBAS/KARTHALA/set5/table_0_${BPIW}_0_${BTIW}.txt
#TABLEDESC=$PATH_1650/SAR_SM/MSBAS/KARTHALA/set6/table_0_${BPIW}_0_${BTIW}.txt

# mode SM #
###########
PARAMPROCESSASC=$PATH_1650/Param_files/S1/KARTHALA_SM_A_86/LaunchMTparam_S1_SM_Karthala_Asc_Zoom1_ML5_MassProc.txt
PARAMPROCESSDESC=$PATH_1650/Param_files/S1/KARTHALA_SM_D_35/LaunchMTparam_S1_SM_Karthala_Desc_Zoom1_ML5_MassProc.txt
# mode IW # 
###########
PARAMPROCESSASCIW=$PATH_1650/Param_files/S1/KARTHALA_A_86/LaunchMTparam_S1_Karthala_Asc_Zoom1_ML2_MassProc.txt
#PARAMPROCESSDESCIW=$PATH_1650/Param_files/S1/KARTHALA__D_35/LaunchMTparam_S1_Karthala_Desc_Zoom1_ML2_MassProc.txt


PARAMASCNAME=`basename ${PARAMPROCESSASC}`
PARAMDESCNAME=`basename ${PARAMPROCESSDESC}`

PARAMASCNAMEIW=`basename ${PARAMPROCESSASCIW}`
#PARAMDESCNAMEIW=`basename ${PARAMPROCESSDESCIW}`


TODAY=`date`

## first restric pair table to last data  
#RemovePairsFromFlist_WithImagesBefore.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1/table_0_20_0_450.txt 20190425
#RemovePairsFromFlist_WithImagesBefore.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2/table_0_20_0_450.txt 20190430
#TABLEASC=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1/table_0_20_0_450.txt_Below20190425_NoBaselines_${TODAY}.txt
#TABLEDESC=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2/table_0_20_0_450.txt_Below20190430_NoBaselines_${TODAY}.txt


# Check that Step1 is finished
CHECKREAD=`ps -eaf | ${PATHGNU}/grep KARTHALA_S1_Step1_Read_SMCoreg_Pairs_SM.sh | ${PATHGNU}/grep -v "grep " | grep -v "Crons_1_2_3.sh" | wc -l` 	# process both SM and IW

if [ ${CHECKREAD} -eq 0 ] 
	then 
		# OK, no more KARTHALA_S1_Step1_Read_SMCoreg_Pairs.sh is running: 
		# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
		CHECKASC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMASCNAME}  | grep -v "Crons_1_2_3.sh" | wc -l`
		CHECKDESC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMDESCNAME}  | grep -v "Crons_1_2_3.sh" | wc -l`
		
		CHECKASCIW=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMASCNAMEIW}  | grep -v "Crons_1_2_3.sh" | wc -l`
#		CHECKDESCIW=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMDESCNAMEIW}  | grep -v "Crons_1_2_3.sh" | wc -l`


		# mode SM #
		###########
		if [ ${CHECKASC} -lt 1 ] 
			then 
				# No process running yet
				echo "Asc SM run on ${TODAY}"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_A_86/SMCrop_SM_${SMASC}_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5/_Asc_last_MassRun.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC} ${PARAMPROCESSASC} > /dev/null 2>&1 &
			else 
				echo "Asc SM attempt aborted on ${TODAY} because other Mass Process in progress"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_A_86/SMCrop_SM_${SMASC}_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5/_Asc_last_aborted.txt
		fi
		# if riunning yet we will try egain tomorrow

 		if [ ${CHECKDESC} -lt 1 ] 
 			then 
 				# No process running yet
 				# if first run, it may crash because $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_D_35/SMCrop_SM_${SMDESC}_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5 does not exist yet, hence create it
 				mkdir -p $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_D_35/SMCrop_SM_${SMDESC}_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5
 				echo "Desc SM run on ${TODAY}"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_D_35/SMCrop_SM_${SMDESC}_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5/_Desc_last_MassRun.txt
 				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC} ${PARAMPROCESSDESC} > /dev/null 2>&1 &
 			else 
 				echo "Desc SM attempt aborted on ${TODAY} because other Mass Process in progress"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_D_35/SMCrop_SM_${SMDESC}_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5/_Desc_last_aborted.txt
 		fi

		# mode IW #
		###########
		if [ ${CHECKASCIW} -lt 1 ] 
			then 
				# No process running yet
 				# if first run, it may crash because $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_A_86/SMNoCrop_${SMASCIW}_Zoom1_ML2 does not exist yet, hence create it
 				mkdir -p $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_A_86/SMNoCrop_${SMASCIW}_Zoom1_ML2
				echo "Asc IW run on ${TODAY}"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_A_86/SMNoCrop_${SMASCIW}_Zoom1_ML2/_Asc_last_MassRun.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASCIW} ${PARAMPROCESSASCIW} > /dev/null 2>&1 &
			else 
				echo "Asc IW attempt aborted on ${TODAY} because other Mass Process in progress"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_A_86/SMNoCrop_${SMASCIW}_Zoom1_ML2/_Asc_last_aborted.txt
		fi
		# if riunning yet we will try egain tomorrow

#		if [ ${CHECKDESCIW} -lt 1 ] 
#			then 
#				# No process running yet
#				# if first run, it may crash because $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_D_35/SMNoCrop_${SMDESCIW}_Zoom1_ML2 does not exist yet, hence create it
#				mkdir -p $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_35/SMNoCrop_${SMDESCIW}_Zoom1_ML2
#				echo "Desc run on ${TODAY}"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_D_35/SMNoCrop_${SMDESCIW}_Zoom1_ML2/_Desc_last_MassRun.txt
#				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESCIW} ${PARAMPROCESSDESCIW} > /dev/null 2>&1 &
#			else 
#				echo "Desc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_D_35/SMNoCrop_${SMDESC}_Zoom1_ML2/_Desc_last_aborted.txt
#		fi


	else 
		# VVP_S1_Step1_Read_SMCoreg_Pairs.sh is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because KATHALA_S1_Step1_Read_SMCoreg_Pairs_SM.sh is still running: wait for tomorrow"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_A_86/SMCrop_SM_${SMASC}_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because KATHALA_S1_Step1_Read_SMCoreg_Pairs_SM.sh is still running: wait for tomorrow"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_D_35/SMCrop_SM_${SMDESC}_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5/_aborted_because_Read_inProgress.txt

		echo "Step2 aborted on ${TODAY} because KATHALA_S1_Step1_Read_SMCoreg_Pairs_SM.sh is still running: wait for tomorrow"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_A_86/SMNoCrop_SM_${SMASCIW}_Zoom1_ML2/_aborted_because_Read_inProgress.txt
#		echo "Step2 aborted on ${TODAY} because KATHALA_S1_Step1_Read_SMCoreg_Pairs_SM.sh is still running: wait for tomorrow"  >>  $PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_D_35/SMNoCrop_SM_${SMDESCIW}_Zoom1_ML2/_aborted_because_Read_inProgress.txt


		exit 0
fi

#beware: the wait is mandatory to allow waiting for the end of cron2 before launching cron 3
wait
