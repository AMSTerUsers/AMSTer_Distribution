#!/bin/bash
# Script to run cronjobs 1, 2 and optionally 3 in a row for a given target. 
# However, this is performed only if no other crons are running for that target, which 
# is evaluated by checking the presence of a flag file in a dedicated dir. 
# If successful, it saves the flag file as Last_Sucessful_Crons_${TARGET}.txt for archive
# 
# Parameters: - path to cron1, cron2 [and cron3]
#			  - path to where to store a flag file prompting for the running processes
#				(advise: take the path to SAR_MASSPROCESS)
#
# Hardcoded: - 
#
# Dependencies:	- trap fct
#
# New in Distro V 1.0.0 202560115 :	- 
# New in Distro V 1.1.0 202560129 :	- keep track of all successful run in Last_Sucessful_Crons_${TARGET}.txt
									
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jan 29, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

CRON1=$1		# cron for reading and coreg on SM
CRON2=$2		# cron for mass processing

if [ $# -lt 3 ]  || [ $# -gt 4 ] ; then echo "Usage $0 CRON1 CRON2 [CRON3] PATH_DIR_FOR_FLAG"; exit; fi


if [ -f "$3" ]; then
    CRON3="$3"	# cron for msbas inversion
    PATH_DIR_FOR_FLAG="$4"
     [ -d "$PATH_DIR_FOR_FLAG" ] || { echo "Flag dir does not exist"; exit 1; }
     
elif [ -d "$3" ]; then
    PATH_DIR_FOR_FLAG="$3"
    CRON3=""	# no cron for msbas inversion
else
    echo "Error: third argument must be a file (cron3) or a directory (flag dir)"
    exit 1
fi

RUNDATE=$(date "+%m_%d_%Y_%Hh%Mm")
RNDM=$(( $RANDOM % 10000 ))

# Create a Flag file that warns that crons are running for the target and make a trap to delete it when script ends or is stopped by ctrl-C (not if terminated by reboot or kill -9)
	TARGET=$(basename "${CRON1}" | cut -d _ -f 1) # usually TARGET name is the first part of the cron name 
	FLAGFILE="${PATH_DIR_FOR_FLAG}"/"Running_crons_${TARGET}_${RUNDATE}_${RNDM}.txt"

	cleanup() {
	  rm -f "${FLAGFILE}"
	}
	
	trap cleanup EXIT INT TERM

# run the scripts
if ! find "${PATH_DIR_FOR_FLAG}" -maxdepth 1 -name "Running_crons_${TARGET}*" -print -quit | grep -q .
	then
    	echo "No running crons for ${TARGET} ; can run now"
   		touch "${FLAGFILE}"
   		
    	# start cron 1 
    	echo "start cron 1 at $(date '+%Y-%m-%d %H:%M:%S')" >> "${FLAGFILE}"
		"${CRON1}"
    	echo "end of cron 1 at $(date '+%Y-%m-%d %H:%M:%S')" >> "${FLAGFILE}"
    	echo "" >> "${FLAGFILE}"
    	
		# start cron 2 
    	echo "start cron 2 at $(date '+%Y-%m-%d %H:%M:%S')" >> "${FLAGFILE}"
		"${CRON2}"
    	echo "end of cron 2 at $(date '+%Y-%m-%d %H:%M:%S')" >> "${FLAGFILE}"
    	echo "" >> "${FLAGFILE}"
		
    	if [ -n "${CRON3}" ]; then
    	    # start cron 3 
    		echo "start cron 3 at $(date '+%Y-%m-%d %H:%M:%S')" >> "${FLAGFILE}"
			"${CRON3}"
    		echo "end of cron 3 at $(date '+%Y-%m-%d %H:%M:%S')" >> "${FLAGFILE}"
    		echo "" >> "${FLAGFILE}"
    	fi
    	
    	cat "${PATH_DIR_FOR_FLAG}"/"Running_crons_${TARGET}_${RUNDATE}_${RNDM}.txt" >> "${PATH_DIR_FOR_FLAG}"/"Last_Sucessful_Crons_${TARGET}.txt" 	
	else
	    echo "Crons for ${TARGET} seems to be already running; can't run now"
fi	




