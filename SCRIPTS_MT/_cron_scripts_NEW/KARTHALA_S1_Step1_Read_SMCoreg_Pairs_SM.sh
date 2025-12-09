#!/bin/bash
# Script to run in cronjob for processing COMRES island images:
# Read images, corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 

# New in Distro V 2.0.0 20220602 :	- use new Prepa_MSBAS.sh compatible with D Derauw and L. Libert tools for Baseline Ploting
# New in Distro V 3.0.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 3.1.0 20230626 :	- Color tables are now in TemplatesForPlots
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 6.0 20241112:	- add descending orbit (available since request in October)
# New in Distro V 6.1 20241210:	- Desc orbit only with BT2 and BT2 because acquisition in that mode started after DATECHG
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

echo "Starting $0" > $PATH_1650/SAR_CSL/S1/KARTHALA_SM/Last_Run_Cron_Step1.txt
date >> $PATH_1650/SAR_CSL/S1/KARTHALA_SM/Last_Run_Cron_Step1.txt

# SM mode

BP=50
BT=150

BP2=150
BT2=150
DATECHG=20220501

SMASC=20220713
SMDESC=20241027

NEWASCPATH=$PATH_1650/SAR_SM/RESAMPLED/S1/KARTHALA_SM_A_86/SMCrop_SM_${SMASC}_ComoresIsland_-11.94--11.34_43.22-43.53
NEWDESCPATH=$PATH_1650/SAR_SM/RESAMPLED/S1/KARTHALA_SM_D_35/SMNoCrop_SM_${SMDESC}_ComoresIsland_-11.94--11.34_43.22-43.53

# Read all S1 images for that footprint
#######################################
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh $PATH_3600/SAR_DATA/S1/S1-DATA-KARTHALA_SM-SLC.UNZIP $PATH_1650/SAR_CSL/S1/KARTHALA_SM/NoCrop S1 ${PATH_1650}/kml/Karthala/Karthala_crop.kml VV ${PATH_1650}/SAR_SM/RESAMPLED/ ${PATH_3601}/SAR_MASSPROCESS/   > /dev/null 2>&1

# Coregister all images on the super master 
###########################################
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/S1/KARTHALA_SM_A_86/LaunchMTparam_S1_SM_Karthala_Asc_Zoom1_ML5_Coreg.txt &
# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/S1/KARTHALA_SM_D_35/LaunchMTparam_S1_SM_Karthala_Desc_Zoom1_ML5_Coreg.txt &

# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh $PATH_1650/SAR_CSL/S1/KARTHALA_SM_A_86/NoCrop $PATH_1650/SAR_SM/MSBAS/KARTHALA/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh $PATH_1650/SAR_CSL/S1/KARTHALA_SM_D_35/NoCrop $PATH_1650/SAR_SM/MSBAS/KARTHALA/set2 S1 > /dev/null 2>&1 &
wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh $PATH_1650/SAR_SM/MSBAS/KARTHALA/set1 ${BP} ${BT} ${SMASC} ${BP2} ${BT2} ${DATECHG} > /dev/null 2>&1  &
fi

if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh $PATH_1650/SAR_SM/MSBAS/KARTHALA/set2 ${BP2} ${BT2} ${SMDESC} > /dev/null 2>&1  &
fi
wait

# Plot baseline plot with both modes 
# if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
# 
# 	if [ `baselinePlot | wc -l` -eq 0 ] 
# 		then
# 			# use AMSTer Engine before May 2022
# 			mkdir -p $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_S1_set_1_2
# 			cd $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_S1_set_1_2
# 
# 			echo "$PATH_1650/SAR_SM/MSBAS/PF/set1" > ModeList.txt
# 			echo "$PATH_1650/SAR_SM/MSBAS/PF/set2" >> ModeList.txt
# 
# 			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 50   $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt
# 		else
# 			# use AMSTer Engine > May 2022
# 			mkdir -p $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_set1_set2
# 			cd $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_set1_set2
#  
# 			echo "$PATH_1650/SAR_SM/MSBAS/PF/set1" > ModeList.txt
# 			echo "$PATH_1650/SAR_SM/MSBAS/PF/set2" >> ModeList.txt
#  
# 			plot_Multi_BaselinePlot.sh $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_set1_set2/ModeList.txt
#  	fi
# 
# fi

echo "Ending $0" >> $PATH_1650/SAR_CSL/S1/KARTHALA_SM/Last_Run_Cron_Step1.txt
date >> $PATH_1650/SAR_CSL/S1/KARTHALA_SM/Last_Run_Cron_Step1.txt
