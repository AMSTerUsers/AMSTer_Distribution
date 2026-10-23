#!/bin/bash
# Script to run in cronjob for processing Nyiragongo and Nyamulagira Crater amplitude images
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
# New in Distro V 3.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 



source $HOME/.bashrc

# Read all RS images for these footprints
# Asc UF
/$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh $PATH_3600/SAR_DATA/RADARSAT/RS2_UF_Asc $PATH_1650/SAR_CSL/RADARSAT/RS2_UF_Asc/NoCrop RADARSAT > /dev/null 2>&1
# Desc F2F 
/$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh $PATH_3600/SAR_DATA/RADARSAT/RS2_F2F_Desc $PATH_1650/SAR_CSL/RADARSAT/RS2_F2F_Desc/NoCrop RADARSAT > /dev/null 2>&1


# ALL2GIFF
# Asc UF Nyigo Crater - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20151201 /$PATH_SCRIPTS/SCRIPTS_MT/Param_files/RS/RS2_UH_Asc36deg/LaunchMTparam_RS_UH_NyigoCrater_Zoom1_ML1_snaphu_ORIGINAL.txt 280 400 & 
# Asc UF Nyam - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20151201 /$PATH_SCRIPTS/SCRIPTS_MT/Param_files/RS/RS2_UH_Asc36deg/LaunchMTparam_RS_UH_Nyam_Zoom1_ML1_snaphu.txt 530 1300 & 
# Desc F2F Nyigo Crater - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20100328 /$PATH_SCRIPTS/SCRIPTS_MT/Param_files/RS/RS2_F2F_Desc40deg/LaunchMTparam_RS_F2F_NyigoCrater_Zoom1_ML1_snaphu.txt 260 200 &
# Desc F2F Nyam - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20100328 /$PATH_SCRIPTS/SCRIPTS_MT/Param_files/RS/RS2_F2F_Desc40deg/LaunchMTparam_RS_F2F_Nyam_Zoom1_ML1_snaphu.txt 800 1220 & 

