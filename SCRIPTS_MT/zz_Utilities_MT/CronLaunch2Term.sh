#!/bin/bash
# This script aims at launching a script in a Terminal from cron. This seems useful for some Linux which cannot 
#  easily get the .bash_profile or .SCRIPTS_MT source system-wide. Other solutions exist such as getting teh state 
#  variable in a system wide file but it would require to maintain two different files with the state variable.  
#
#
# Parameters are:
#       - script to launch
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#   			- seq
#               - Appel's osascript for opening terminal windows if OS is Mac
#               - x-termoinal-emulator for opening terminal windows if OS is Linux
#			    - say for Mac or espeak for Linux
#				- scripts LaunchTerminal.sh, MasterDEM.sh and of course SuperMaster_MassProc.sh
#
# Hard coded:	- path to x-terminal-emulator (required for linux only)
#
# New in Distro V 1.1:	- replace hard coded path to scripts with state variable 
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

# vvv ----- Hard coded lines to check --- vvv 
PATHFCTFILE=$PATH_SCRIPTS/SCRIPTS_MT/
# ^^^ ----- Hard coded lines to check -- ^^^ 

SCRIPTTOLAUNCH=$1 	# eg /Users/doris/NAS/hp-1650-Data_Share1/SAR_SM/MSBAS/Limbourg/set1/table_0_450_0_250.txt

if [ $# -lt 1 ] 
	then 
		echo “Usage $0 PATH_SCRIPT_TO_LAUNCH” 
		exit
fi

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

echo 
echo "********************************************************************"
echo "DO NOT CLOSE THIS TERMINAL BEFORE SCRIPT IS FINISHED"
echo "Launched on: " 
date
echo "********************************************************************"
case ${OS} in 
	"Linux") 
		/usr/bin/x-terminal-emulator -e ${PATHFCTFILE}/LaunchTerminal.sh ${SCRIPTTOLAUNCH} &
		;;
	"Darwin")
		osascript -e 'tell app "Terminal"
		do script "${SCRIPTTOLAUNCH}"
		end tell'		;;
	*)
		echo "I can't figure out what is you opeating system. Please check"
		exit 0
		;;
esac						

