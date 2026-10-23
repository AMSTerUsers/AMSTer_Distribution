#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at coregistrating all modes of LUX
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# make mass process when coreg finished
for i in `seq 1 6`
do
	
	case $i in
		1) 
			osascript -e 'tell app "Terminal"
			do script "SuperMaster_MassProc.sh '"/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/LUX/set1/table_0_80_0_90.txt /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_15/LaunchMTparam_S1_LUX_A_15_Zoom1_ML4_MassProc.txt "'"
			end tell' ;;
		2) 
			osascript -e 'tell app "Terminal"
			do script "SuperMaster_MassProc.sh '"/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/LUX/set2/table_0_80_0_90.txt /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_88/LaunchMTparam_S1_LUX_A_88_Zoom1_ML4_MassProc.txt "'" 
			end tell' ;;
		3) 
			osascript -e 'tell app "Terminal"
			do script "SuperMaster_MassProc.sh '"/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/LUX/set3/table_0_80_0_90.txt /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_161/LaunchMTparam_S1_LUX_A_161_Zoom1_ML4_MassProc.txt "'"
			end tell' ;;
		4) 
			osascript -e 'tell app "Terminal"
			do script "SuperMaster_MassProc.sh '"/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/LUX/set4/table_0_80_0_90.txt /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_37/LaunchMTparam_S1_LUX_D_37_Zoom1_ML4_MassProc.txt "'"
			end tell' ;;
		5) 
			osascript -e 'tell app "Terminal"
			do script "SuperMaster_MassProc.sh '"/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/LUX/set5/table_0_80_0_90.txt /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_66/LaunchMTparam_S1_LUX_D_66_Zoom1_ML4_MassProc.txt "'"
			end tell' ;;
		6) 
			#osascript -e 'tell app "Terminal"
			#do script "SuperMaster_MassProc.sh '"/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/LUX/set6/table_0_80_0_90.txt /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_139/LaunchMTparam_S1_LUX_D_139_Zoom1_ML4_MassProc.txt"'"
			#end tell' 
			echo "Done";;
	esac		
done

