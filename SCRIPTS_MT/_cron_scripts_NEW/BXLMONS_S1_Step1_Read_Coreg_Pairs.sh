#!/bin/bash
# Script to run in cronjob for processing BXL-MONS (Belgium) images:
# Read images, corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 

# New in Distro V 1.0.0 20250730 :	- based on Galeras processing
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

echo "Starting $0" > $PATH_3610/SAR_CSL/S1/BXLMONS/Last_Run_Cron_Step1.txt
date >> $PATH_3610/SAR_CSL/S1/BXLMONS/Last_Run_Cron_Step1.txt

# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=15
BT=400

BP2=50 
DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC1=20190405		# Asc 161
SMDESC1=20210310	# Desc 110

NEWASCPATH=$PATH_3611/SAR_SM/RESAMPLED/S1/BXLMONS_A_161/SMCrop_SM_
NEWDESCPATH=$PATH_3611/SAR_SM/RESAMPLED/S1/BXLMONS_D_110/SMCrop_SM_

# some files and PATH
#####################
#SAR_DATA
DIRSARDATA=$PATH_3611/SAR_DATA/S1/S1-DATA-BXLMONS-SLC.UNZIP

#SAR_CSL
DIRSARCSL=$PATH_3610/SAR_CSL/S1/BXLMONS		# do not put tailing / in name here

#SETi DIR
DIRSET=$PATH_1650/SAR_SM/MSBAS/BXLMONS

# Dir to clean clean when orbits are updated
RESAMDIR=$PATH_3611/SAR_SM/RESAMPLED/
MASSPRODIR=$PATH_3611/SAR_MASSPROCESS/

#kml file
KMLFILE=$PATH_1650/kml/BeLux/Dominique/Bxl_Mons.kml			# that is 6 bursts in Asc and 12 in Desc

#Launch param files
PARAMCOREGASC=$PATH_1650/Param_files/S1/BXLMONS_A_161/LaunchMTparam_S1_IW_BxlMons_A_Zoom1_ML2_Coreg.txt
PARAMCOREGDESC=$PATH_1650/Param_files/S1/BXLMONS_D_110/LaunchMTparam_S1_IW_BxlMons_D_Zoom1_ML2_Coreg.txt


# Read all S1 images for that footprint
#######################################
#$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh $PATH_3600/SAR_DATA/S1/S1-DATA-GUADELOUPE-SLC.UNZIP $PATH_1650/SAR_CSL/S1/GUADELOUPE/NoCrop S1 ${PATH_1650}/kml/Guadeloupe/Guadeloupe.kml  VV ${PATH_1650}/SAR_SM/RESAMPLED/ ${PATH_3601}/SAR_MASSPROCESS/  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATA} ${DIRSARCSL}/NoCrop S1 ${KMLFILE} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
## Asc 164 ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/Region_Mode/NoCrop/S1A_an_image_A.csl Dummy
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_161/NoCrop 6 "${KMLFILE}" &


## Desc D_54; 
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_110/NoCrop 12 "${KMLFILE}" &
wait

# Coregister all images on the super master 
###########################################
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC} &
# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC} &

# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_161/NoCrop ${DIRSET}/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_110/NoCrop ${DIRSET}/set2 S1 > /dev/null 2>&1  &
wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set1 ${BP} ${BT} ${SMASC1} ${BP2} ${BT} ${DATECHG} > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set2 ${BP} ${BT} ${SMDESC1} ${BP2} ${BT} ${DATECHG} > /dev/null 2>&1  &
fi
wait

## Plot baseline plot with both modes 
# if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
# 
# 	if [ `baselinePlot | wc -l` -eq 0 ] 
# 		then
# 			# use AMSTer Engine before May 2022
# 			mkdir -p $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_S1_set_1_2
# 			cd $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_S1_set_1_2
# 
# 			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set1" > ModeList.txt
# 			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set2" >> ModeList.txt
# 
# 			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 {BT}   $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt
# 		else
# 			# use AMSTer Engine > May 2022
# 			mkdir -p $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2
# 			cd $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2
#  
# 			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set1" > ModeList.txt
# 			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set2" >> ModeList.txt
#  
# 			plot_Multi_BaselinePlot.sh $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2/ModeList.txt
#  	fi
# 
# fi

echo "Ending $0" >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
