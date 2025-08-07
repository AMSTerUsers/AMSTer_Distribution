#!/bin/bash
# Script to run in cronjob for processing Nepal ANVISAT amplitude images
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


source $HOME/.bashrc

# Suppose that images were downloaded manually 

PATHRAW=$PATH_3602/SAR_DATA_Other_Zones_2/ENVISAT 	# where there are NEPAL_A427, NEPAL_D33 and NEPAL_D305

# Path to SAR_CSL data
PATHCSL=$PATH_1650/SAR_CSL/ENVISAT 					# where there are NEPAL_A427, NEPAL_D33 and NEPAL_D305

# Parameters files for Coregistration
PARAMASC427=/$PATH_1650/Param_files/ENVISAT/NEPAL_A427/LaunchMTparam_Envi_Asc427_Full_Zoom1_ML2_Coreg.txt
PARAMDESC33=/$PATH_1650/Param_files/ENVISAT/NEPAL_D33/LaunchMTparam_Envi_Desc33_Full_Zoom1_ML2_Coreg.txt
PARAMDESC305=/$PATH_1650/Param_files/ENVISAT/NEPAL_D305/LaunchMTparam_Envi_Desc305_Full_Zoom1_ML2_Coreg.txt

# READING MUST BE DONE ONCE
#		# Read all ENVISAT images 
#		##########################
#		 echo "//Reading RAW images (Asc adn Desc) as .csl in ${PATHCSL}/mode"
#		 $PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${PATHRAW}/NEPAL_A427 ${PATHCSL}/NEPAL_A427 ENVISAT > /dev/null 2>&1
#		 $PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${PATHRAW}/NEPAL_D33  ${PATHCSL}/NEPAL_D33  ENVISAT > /dev/null 2>&1
#		 $PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${PATHRAW}/NEPAL_D305 ${PATHCSL}/NEPAL_D305 ENVISAT > /dev/null 2>&1

# LET'S START NORMAL AMPLI PROCESSING

#PARAMASC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Asc/
#PARAMDESC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Desc/

# ALL2GIFF
# Asc - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20040929 ${PARAMASC427} 100 100 & 
# Desc 33 - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20100708 ${PARAMDESC33} 100 100 &
# Desc - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20080826 ${PARAMDESC305} 100 100 & 
