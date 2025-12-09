#!/bin/bash
# Script to run in cronjob for processing VVP images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
# NOTE: usualy by running the reading and coregistration at 1 am, it is finished around 1am30
#       hence this script should be safely launched around 2 am for instance.
#       Nevertheless because VVP_S1_Step1_Read_SMCoreg_Pairs.sh uses RadAll_Img.sh, which also move updated prelim orbit images at all levels in _CLN dir,
#       and coregister images on Global Primaries (SuperMasters), one check that it is not running anymore before starting.
#
# New in Distro V 2.0.0 20221215 :	- restart from scratch, using new Copernicus DEM (2014) referenced to Ellipsoid
#									- more path and variable in param at the beginning of the script
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_MT directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20240701:	- enlarge orbital tube to 70m instead of 20 after 20220501
#								- (set correct list of co-eruptive pairs computed manually and set them in ...AdditionaPairs.txt)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

cd
source $HOME/.bashrc


# Some variables
#################

BP=20
BT=400

BP2=70
BT2=400
DATECHG=20220501

STARTEXCLU=20210522 	# Because Nyiragongo 2021 eruption created defo too large for classical unwrapping, co-eruptive pairs must have been unwrapped with recursive snaphu and put in mass processing results instead of the automated results.
STOPEXCLU=20210530		# For that reason, all pairs spanning the eruption, i.e. between [STARTEXCLU , STOPEXCLU] are excluded from the automatic procedure. They are replaced by pairs in table_0_20_0_400._AdditionalPairs.txt    

SMASC=20150310
SMDESC=20151014

# Path to RAW data
#PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP

# Path to SAR_CSL data
#PATHCSL=$PATH_1660/SAR_CSL/S1

# Path to RESAMPLED data
#NEWASCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310
#NEWDESCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_VVP_D_21/SMNoCrop_SM_20151014

# Path to Seti
PATHSETI=$PATH_1660/SAR_SM/MSBAS

# Path to SAR_MASSPROCESS
PATHMASSPROCESS=$PATH_HOMEDATA/SAR_MASSPROCESS

# Parameters files for Coregistration
#PARAMASC=$PATH_DataSAR/Param_files/S1/DRC_VVP_A_174/LaunchMTparam_S1_VVP_Asc_Zoom1_ML4_snaphu_square_Coreg.txt
#PARAMDESC=$PATH_DataSAR/Param_files/S1/DRC_VVP_D_21/LaunchMTparam_S1_VVP_Desc21_Zoom1_ML4_snaphu_square_Coreg.txt


# some files
############
TABLEASC=${PATHSETI}/VVP/set6/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt_Without_${STARTEXCLU}_${STOPEXCLU}.txt
TABLEDESC=${PATHSETI}/VVP/set7/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt_Without_${STARTEXCLU}_${STOPEXCLU}.txt
# Note that there are more co-eruptive pairs = computed manually with recurrent unwrapping (cfr _AdditionaPairs.txt files)
# The baseline plots list them as well (as they are stored in e.g. restrictedAcquisitionsRepartition.txt_Dummy_table_0_20_0_400_Till_20220501_0_70_0_400_After.txt_Without_20210522_20210530_WithAdditionalPairs.txt )


# Parameters files for Mass Processing
PARAMPROCESSASC=$PATH_DataSAR/SAR_AUX_FILES/Param_files/S1/DRC_VVP_A_174/LaunchMTparam_S1_VVP_Asc_Zoom1_ML4_snaphu_square_MassPro.txt
PARAMPROCESSDESC=$PATH_DataSAR/SAR_AUX_FILES/Param_files/S1/DRC_VVP_D_21/LaunchMTparam_S1_VVP_Desc21_Zoom1_ML4_snaphu_square_MassPro.txt

PARAMPROCESSASCFILE=`basename ${PARAMPROCESSASC}`
PARAMPROCESSDESCFILE=`basename ${PARAMPROCESSDESC}`

# Go...
#######
TODAY=`date`


# Check that VVP_S1_Step1_Read_SMCoreg_Pairs.sh is finished
CHECKREAD=`ps -eaf | ${PATHGNU}/grep VVP_S1_Step1_Read_SMCoreg_Pairs.sh | ${PATHGNU}/grep -v "grep " | wc -l`

if [ ${CHECKREAD} -eq 0 ] 
	then 
		# OK, no more VVP_S1_Step1_Read_SMCoreg_Pairs.sh is running: 
		# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
		CHECKASC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMPROCESSASCFILE} | wc -l`
		CHECKDESC=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${PARAMPROCESSDESCFILE} | wc -l`

		if [ ${CHECKASC} -lt 1 ] 
			then 
				# No process running yet
				echo "Asc run on ${TODAY}"  >>  ${PATHMASSPROCESS}/S1/DRC_VVP_A_174/SMNoCrop_SM_${SMASC}_Zoom1_ML4/_Asc_last_MassRun.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEASC} ${PARAMPROCESSASC} > /dev/null 2>&1  &
			else 
				echo "Asc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${PATHMASSPROCESS}/S1/DRC_VVP_A_174/SMNoCrop_SM_${SMASC}_Zoom1_ML4/_Asc_last_aborted.txt
		fi
		# if riunning yet we will try egain tomorrow

		if [ ${CHECKDESC} -lt 1 ] 
			then 
				# No process running yet
				echo "Desc run on ${TODAY}"  >>  ${PATHMASSPROCESS}/S1/DRC_VVP_D_21/SMNoCrop_SM_${SMDESC}_Zoom1_ML4/_Desc_last_Mass.txt
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLEDESC} ${PARAMPROCESSDESC} > /dev/null 2>&1  &
			else 
				echo "Desc attempt aborted on ${TODAY} because other Mass Process in progress"  >>  ${PATHMASSPROCESS}/S1/DRC_VVP_D_21/SMNoCrop_SM_${SMDESC}_Zoom1_ML4/_Desc_last_aborted.txt
		fi
	else 
		# VVP_S1_Step1_Read_SMCoreg_Pairs.sh is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because VVP_S1_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  ${PATHMASSPROCESS}/S1/DRC_VVP_A_174/SMNoCrop_SM_${SMASC}_Zoom1_ML4/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because VVP_S1_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  ${PATHMASSPROCESS}/S1/DRC_VVP_D_21/SMNoCrop_SM_${SMDESC}_Zoom1_ML4/_aborted_because_Read_inProgress.txt

		exit 0
fi

