#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script launches the MasTer Toolbox Organizer. 
#
# Parameters : - none
#
# Dependencies:
#	- a config file config.txt located in the SCRIPTS_MT/MasTerOrganizer directory
#	- python 3 
#	- python prgms  main_window.py, start_app.py and Ui_main_window_man.py
#
# New in Distro V 1.0:		-
#				V 2.0: Add display number as argument to start_app.py because cmd who will not work in backround
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "


# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS} ; Use config file accordingly"
echo

case ${OS} in 
	"Linux") 
		cp -f $PATH_SCRIPTS/SCRIPTS_MT/MasTerOrganizer/config_Linux.txt  $PATH_SCRIPTS/SCRIPTS_MT/MasTerOrganizer/config.txt 
		;;
	"Darwin")
		cp -f $PATH_SCRIPTS/SCRIPTS_MT/MasTerOrganizer/config_Mac.txt  $PATH_SCRIPTS/SCRIPTS_MT/MasTerOrganizer/config.txt 
		;;
esac			

# record the display number because python script will launch in background without terminal reference
display_number=$(who -m | grep -o '(.*)')
start_app.py ${display_number} &

echo "You can now close the Terminal. When done with the Organizer, simply close it... Enjoy"

# All done 
