#!/bin/bash
# Script to run in cronjob for processing VVP images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
# NOTE: usualy by running the reading and coregistration at 1 am, it is finished around 1am30
#       hence this script should be safely launched around 2 am for instance.
#       Nevertheless because VVP_S1_Step1_Read_SMCoreg_Pairs.sh uses RadAll_Img.sh, which also move updated prelim orbit images at all levels in _CLN dir,
#       and coregister images on Global Primaries (SuperMasters), one check that it is not running anymore before starting.
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_MT directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

cd
source $HOME/.bashrc



# Some variables
#################

BP=150
BTASC=200
BTDESC=200


# some files
############
TABLEASC=$PATH_1650/SAR_SM/MSBAS/VVP/set1/table_0_${BP}_0_${BTASC}.txt
TABLEDESC=$PATH_1650/SAR_SM/MSBAS/VVP/set2/table_0_${BP}_0_${BTDESC}.txt

PARAMPROCESSASC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Asc/LaunchMTparam_SuperMaster_CSK_Virunga_Asc_Full_Zoom1_ML23_KEEP_MassPro.txt
PARAMPROCESSDESC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Desc/LaunchMTparam_SuperMaster_CSK_Virunga_Desc_Full_Zoom1_ML23_MassPro.txt

TODAY=`date`

# Check that VVP_S1_Step1_Read_SMCoreg_Pairs.sh is finished
CHECKREAD=`ps -eaf | ${PATHGNU}/grep VVP_CSK_Step1_Read_SMCoreg_Pairs.sh | ${PATHGNU}/grep -v "grep " | wc -l`

if [ ${CHECKREAD} -eq 0 ] 
	then 
		# OK, no more VVP_S1_Step1_Read_SMCoreg_Pairs.sh is running: 
		# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
		CHECKASC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep LaunchMTparam_SuperMaster_CSK_Virunga_Asc_Full_Zoom1_ML23_KEEP_MassPro.txt | wc -l`
		CHECKDESC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep LaunchMTparam_SuperMaster_CSK_Virunga_Desc_Full_Zoom1_ML23_MassPro.txt | wc -l`

		if [ ${CHECKASC} -lt 1 ] 
			then 
				# No process running yet
				echo "Asc run on ${TODAY}"  >>  $PATH_3602/SAR_MASSPROCESS_2/CSK/Virunga_Asc/SMNoCrop_SM_20160627_Zoom1_ML23/_Asc_last_MassRun.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC} ${PARAMPROCESSASC} > /dev/null 2>&1  &
			else 
				echo "Asc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  $PATH_3602/SAR_MASSPROCESS_2/CSK/Virunga_Asc/SMNoCrop_SM_20160627_Zoom1_ML23/_Asc_last_aborted.txt
		fi
		# if riunning yet we will try egain tomorrow

		if [ ${CHECKDESC} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc run on ${TODAY}"  >>  $PATH_3602/SAR_MASSPROCESS_2/CSK/Virunga_Desc/SMNoCrop_SM_20160105_Zoom1_ML23/_Desc_last_Mass.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC} ${PARAMPROCESSDESC} > /dev/null 2>&1  &
			else 
				echo "Desc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  $PATH_3602/SAR_MASSPROCESS_2/CSK/Virunga_Desc/SMNoCrop_SM_20160105_Zoom1_ML23/_Desc_last_aborted.txt
		fi
	else 
		# VVP_S1_Step1_Read_SMCoreg_Pairs.sh is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because VVP_CSK_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_3602/SAR_MASSPROCESS_2/CSK/Virunga_Asc/SMNoCrop_SM_20160627_Zoom1_ML23/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because VVP_CSK_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_3602/SAR_MASSPROCESS_2/CSK/Virunga_Desc/SMNoCrop_SM_20160105_Zoom1_ML23/_aborted_because_Read_inProgress.txt

		exit 0
fi

