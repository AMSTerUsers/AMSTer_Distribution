#!/bin/bash
# Script to run in cronjob for processing Nyamulagira Crater amplitude images though with 
# jumps because the frame does not always cover the whole crater. 
# updated on Aug. 12 2021 by NdO to account for the new way of cropping the images with the most recent version of AMSTer Engine. 
#                                Also takes the new Global Primary (SuperMaster) for Nyam  
# updated on Jan. 16 2023 by NdO to account for the new DEM etc

# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


source $HOME/.bashrc

# Suppose that images were downloaded from super site using secp and then read and sorted manually using 
# ReadDateCSK.sh then Prepa_CSK_SuperSite.sh

PARAMASC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Asc/



# ALL2GIFF
# Asc Nyam - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20160627 ${PARAMASC}LaunchMTparam_CSK_Virunga_Asc_NyamCrater2_Zoom1_ML1_snaphu_Shadows_WithJumps.txt 1100 900 & 

