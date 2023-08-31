#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at coregistrating all modes of LUX
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0 Beta CIS script utilities"
AUT="Nicolas d'Oreye, (c)2016-18, Last modified on May 08, 2018"
echo " "
echo "${PRG} ${VER}, ${AUT}"
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

