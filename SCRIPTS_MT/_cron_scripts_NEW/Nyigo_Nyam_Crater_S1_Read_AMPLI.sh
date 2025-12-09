#!/bin/bash
# Script to run in cronjob for processing Nyiragongo and Nyamulagira Crater amplitude images

# New in Distro V 3.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.1 20230913:	- moved param files in PATH_DataSAR like the other scripts for S1 VVP
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.1 20250311:	- corr bug in path to param files
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

# Read all S1 images for these footprints
# Do not provide ${PATH_1650}/SAR_SM/RESAMPLED/ ${PATH_3601}/SAR_MASSPROCESS/ because no Coreg nor MassProcess applied
# Nyigo
/$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh /$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP /$PATH_1650/SAR_CSL/S1/DRC_NyigoCrater/NoCrop S1 /$PATH_1650/SAR_CSL/S1/DRC_NyigoCrater/NyigoCrater.kml  VV  > /dev/null 2>&1
# Nyam 
/$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh /$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP /$PATH_1650/SAR_CSL/S1/DRC_NyamCrater/NoCrop S1 /$PATH_1650/SAR_CSL/S1/DRC_NyamCrater/NyamCrater.kml VV  > /dev/null 2>&1


# ALL2GIFF
# Asc Nyigo - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20141017 /${PATH_DataSAR}/SAR_AUX_FILES/Param_files/S1/DRC_NyigoCrater_Asc174/LaunchMTparam_S1_NyigoCraterAsc_Zoom1_ML1_original_FOR_SHADOWS.txt 4200 1000 & 
# Desc Nyigo and Nyam - in background so that it can startNyam ascending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20141007 /${PATH_DataSAR}/SAR_AUX_FILES/Param_files/S1/DRC_Nyigo_Nyam_Crater_Desc21/LaunchMTparam_S1_Nyigo_Nyam_CraterDesc_Zoom1_ML1_snaphu_original.txt 3600 250 &
# Asc Nyam - in background 
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20141017 /${PATH_DataSAR}/SAR_AUX_FILES/Param_files/S1/DRC_Nyam_Crater_Asc174/LaunchMTparam_S1_NyamCraterAsc_Zoom1_ML1_original_FOR_SHADOWS.txt 4050 560 &


# need to wait for both to be done before going further
wait 

# Nyam descending is finished, it can actually make it for Nyam as well
/$PATH_SCRIPTS/SCRIPTS_MT/zz_Utilities_MT_Ndo/Shadows_S1_Nyam_Desc.sh




