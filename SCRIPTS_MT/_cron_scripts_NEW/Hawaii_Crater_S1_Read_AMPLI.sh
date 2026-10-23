#!/bin/bash
# Script to run in cronjob for processing Hawaii Kilauea Crater amplitude images
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
#
# New in Distro V 3.0.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.0 20250409:	- no need RESAMPLED dir in Read_All_Img.sh 
# New in Distro V 5.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


source $HOME/.bashrc

# Read all S1 images for these footprints
# Kilauea
# NO SAR_MASSPROCESS provided because only for shadows
#/$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh /$PATH_3601/SAR_DATA_Other_Zones/S1/S1-DATA-HAWAII-SLC.UNZIP /$PATH_3601/SAR_CSL_Other_Zones/S1/Hawaii_LL/NoCrop S1 /$PATH_3601/SAR_CSL_Other_Zones/S1/Hawaii_LL/Hawaii_LL.kml VV ${PATH_3602}/SAR_SM_Other_Zones/RESAMPLED/   > /dev/null 2>&1
/$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh /$PATH_3601/SAR_DATA_Other_Zones/S1/S1-DATA-HAWAII-SLC.UNZIP /$PATH_3601/SAR_CSL_Other_Zones/S1/Hawaii_LL/NoCrop S1 /$PATH_3601/SAR_CSL_Other_Zones/S1/Hawaii_LL/Hawaii_LL.kml VV > /dev/null 2>&1


# ALL2GIFF
# Asc - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20170706 /$PATH_1650/Param_files/S1/Hawaii_LL_A_124/LaunchMTparam_S1_HawaiiLLAsc_Zoom1_ML1_original_FOR_SHADOWS.txt 4860 1050 & 
# Desc - in background so that it can startNyam ascending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20170428 /$PATH_1650/Param_files/S1/Hawaii_LL_D_87/LaunchMTparam_S1_Hawaii_LLDesc_Zoom1_ML1_original_FOR_SHADOWS.txt 480 930 &

# need to wait for both to be done before going further
wait 
