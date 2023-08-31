#!/bin/bash
# Script to run in cronjob for processing DOMUYO images:
# Read images, check if nr of bursts and corners coordinates are OK, 
# corigister them on a super master and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 

# New in Distro V 2.0.0 20220602 :	- use new Prepa_MSBAS.sh compatible with D Derauw and L. Libert tools for Baseline Ploting
# New in Distro V 3.0.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 3.1.0 20230626 :	- Color tables are now in TemplatesForPlots
# New in Distro V 4.0.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#									- Replace CIS by MT in names 
#									- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/25 - could make better... when time.
# -----------------------------------------------------------------------------------------
source $HOME/.bashrc

echo "Starting $0" > $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA/Last_Run_Cron_Step1.txt
date >> $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA/Last_Run_Cron_Step1.txt

BP=20
NEWASCPATH=$PATH_1650/SAR_SM/RESAMPLED/S1/ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_20180512
NEWDESCPATH=$PATH_1650/SAR_SM/RESAMPLED/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_20180222

# Read all S1 images for that footprint
#######################################
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh $PATH_3600/SAR_DATA/S1/S1-DATA-DOMUYO-SLC.UNZIP $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA/NoCrop S1 $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA/DomuyoYLagunaFea.kml VV ${PATH_1650}/SAR_SM/RESAMPLED/ ${PATH_3601}/SAR_MASSPROCESS/ > /dev/null 2>&1

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
# Asc ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/ARG_DOMU_LAGUNA_A_18/NoCrop/S1B_18_20211210_A.csl Dummy
_Check_ALL_S1_SizeAndCoord_InDir.sh $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_A_18/NoCrop 14 -71.1264 -37.3038 -69.1902 -36.8461 -71.5447 -36.0797 -69.6394 -35.6292

# Desc ; bursts size and coordinates are obtained by running e.g.: _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/S1B_83_20211109_D.csl Dummy
# Beware D83 with S1B after Jan 2020 are shorter on the Western side, hence check first with large coordinate, then check the images in __TMP_QUARANTINE with smaller coordinates. 
#        If OK, put them back in NoCrop dir. If not, keep them in original __TMP_QUARANTINE

# consistent with S1B before Jan 2020 
_Check_ALL_S1_SizeAndCoord_InDir.sh $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop 14 -69.0318 -36.1361 -70.9962 -35.6524 -69.4497 -37.3619 -71.4464 -36.8704
# consistent with S1B after Jan 2020 
_Check_ALL_S1_SizeAndCoord_InDir.sh $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/__TMP_QUARANTINE 14 -68.9461 -36.1361 -70.9962 -35.6524 -69.3630 -37.3619 -71.4464 -36.8704
	mv $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/__TMP_QUARANTINE/*.csl $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/ 2>/dev/null
	mv $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
	mv $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/__TMP_QUARANTINE/*.txt $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop 2>/dev/null
	rm -R $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null


# Coregister all images on the super master 
###########################################
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files_SuperMaster/S1/ARG_DOMU_LAGUNA_A_18/LaunchMTparam_S1_Arg_Domu_Laguna_A_18_Zoom1_ML4_MassProc_Coreg.txt &
# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files_SuperMaster/S1/ARG_DOMU_LAGUNA_D_83/LaunchMTparam_S1_Arg_Domu_Laguna_D_83_Zoom1_ML4_MassProc_Coreg.txt &

# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_A_18/NoCrop $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2 S1 > /dev/null 2>&1 &
wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1 ${BP} 450 20180512 > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2 ${BP} 450 20180222 > /dev/null 2>&1  &
fi
wait

# Plot baseline plot with both modes 
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
		if [ `baselinePlot | wc -l` -eq 0 ] 
			then
				# use MasTer Engine before May 2022

				mkdir -p $PATH_1650/SAR_SM/MSBAS/ARGENTINE/BaselinePlots_S1_set_1_2
				cd $PATH_1650/SAR_SM/MSBAS/ARGENTINE/BaselinePlots_S1_set_1_2

				echo "$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1" > ModeList.txt
				echo "/$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2" >> ModeList.txt

				$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 450   $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt
			else
				# use MasTer Engine > May 2022
				mkdir -p $PATH_1650/SAR_SM/MSBAS/ARGENTINE/BaselinePlots_set1_set2
				cd $PATH_1650/SAR_SM/MSBAS/ARGENTINE/BaselinePlots_set1_set2
 
				echo "$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1" > ModeList.txt
				echo "/$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2" >> ModeList.txt
 
				plot_Multi_BaselinePlot.sh $PATH_1650/SAR_SM/MSBAS/ARGENTINE/BaselinePlots_set1_set2/ModeList.txt
			
		fi
fi

echo "Ending $0" >> $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA/Last_Run_Cron_Step1.txt
date >> $PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA/Last_Run_Cron_Step1.txt
