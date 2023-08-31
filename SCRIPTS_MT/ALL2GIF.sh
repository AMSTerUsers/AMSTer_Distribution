#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at running the SinglePairNoUnwrap up to generation of the amplitude 
#   gif
#
# MUST BE LAUNCHED FROM DIR WHERE DATA ARE PROCESSED THAT IS  SATDIR/TRKDIR
#
#   !!!  Because mv search for only master_slave, do not run two of this script for the same data set e.g. with different crop !!
#   !!!  Or take care to do it from two different PROROOTPATH (cfr Parameters file) 
#
# Parameters :  - Super Master date
#				- file with the processing parameters (incl path) 
#				- X and Y position of date label to be added in the jpg of mod
#
# Dependencies:	 
#    	- The FUNCTIONS_FOR_MT.sh file with the function used by the script. Will be called automatically by the script
#    	- gnu sed and awk for more compatibility. 
#    	- convert (to create/crop jpg images)
# 		- scripts:
#			+ MultiLaunch.sh (which needs SinglePairNoUnwrap.sh)
#			+ Cp_Ampli.sh
#			+ CheckAreaOfInterest_InAmplitudesDir.sh
#			+ jpg2movie_gif.sh
#		- __HardCodedLines.sh for 
#				+ Path to directory where amplitude data will be stored 
#				     e.g. ...Your_Path.../SAR_SM/AMPLITUDES
#				+ some pre-defined crops depending on the routine processings:
#					 see case at the end  
#
# Hard coded:	- Path to .bashrc (sourced for safe use in cronjob)
#
# New in Distro V 1.0:	- Based on developpement version 2.7 and Beta V1.1.3
#               V 1.0.1: - remove log files older than 30 days
#               V 1.0.2: - crop for Nyigo & Nyam Craters with CSK were updated to account for the new way of cropping the images with the most recent version of MT Master Engine   
#               V 1.0.3: - check if new images were processed before running Cp_Ampli.sh, CheckAreaOfInterest_InAmplitudesDir.sh and jpg2movie_gif.sh...
# New in Distro V 2.0: - Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2017/12/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

SUPERMASTERINPUT=$1			# Date of SuperMaster
PARAMFILE=$2				# parmaters file
LABELX=$3					# position of the date label in jpg fig of mod
LABELY=$4					# position of the date label in jpg fig of mod

# vvv ----- Hard coded lines to check --- vvv 
source $HOME/.bashrc 

source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Setup disk paths for processing in Luxembourg. Adjust accordingly if you run several
	ALL2GIFWhereAreAmpli
	# See also below: 
	# - ALL2GIFCrop to define the crop region in amplitude images depending on the sat/trk/target
# ^^^ ----- Hard coded lines to check -- ^^^ 


# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"

if [ $# -lt 4 ] ; then echo “\n Usage $0 SUPERMASTER PARAMFILE LABELx LABBELy \n”; exit; fi

# Functions to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

function GetDateCSL()
	{
	unset DIRNAM
	local DIRNAM=$1
	# Following will be obsolate when S1 image stitching will be available at reading
	if [ ${SAT} == "S1" ] 
		then 
			echo "${DIRNAM}" | cut -d _ -f 3
		else
			echo "${DIRNAM}" | cut -d . -f1   # just in case...
		
	fi
	}
	
SAT=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
TRK=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming

PROROOTPATH=`GetParam PROROOTPATH`			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name. 
DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 

RUNDIR=${PROROOTPATH}/${SAT}/${TRK}/   				# Where process will be run on doris-Pro before being moved to TARGETDIR
ALLDATADIR=${DATAPATH}/${SAT}/${TRK}/NoCrop 		# where all data are store (for list of avaialble data)
TARGETDIR=${ROOTTARGETDIR}/${SAT}/${TRK}/${REGION} 	# where to store the results

echo "  // ALLDATADIR is ${ALLDATADIR} "
echo "  // TARGETDIR is ${TARGETDIR} "

mkdir -p ${TARGETDIR}
mkdir -p ${RUNDIR}

SUPERMASTER=`GetDateCSL ${SUPERMASTERINPUT}`    # i.e. if S1 is given in the form of name, MAS is now only the date anyway

cd ${RUNDIR} 
MultiLaunch.sh ${SUPERMASTER} ${ALLDATADIR} ${TARGETDIR} ${PARAMFILE} ${LABELX} ${LABELY}
cp ${RUNDIR}/All_Slaves_* ${TARGETDIR}/
cp ${RUNDIR}/New_Slaves_to_process_* ${TARGETDIR}/
cp ${RUNDIR}/Processed_slaves_* ${TARGETDIR}/ 

#test if new img were processed 
TSTNEW=`cat New_Slaves_to_process_*.txt  | ${PATHGNU}/grep -Eo "[0-9]" | wc -l`  # test if one (or more) file of slaves to process contains numbers, which should be date of image and hence numbers

rm All_Slaves_* New_Slaves_to_process_* Processed_slaves_*

if [ ${TSTNEW} -gt 0 ] 
	then
		# then new images were processed, let's go further

		cd ${TARGETDIR} 

		# remove files older than 30 days
		find . -maxdepth 1 -name "All_Slaves_*.txt" -type f -mtime +30 -exec rm -f {} \;
		find . -maxdepth 1 -name "New_Slaves_to_process_*.txt" -type f -mtime +30 -exec rm -f {} \;
		find . -maxdepth 1 -name "Processed_slaves_*.txt" -type f -mtime +30 -exec rm -f {} \;

		Cp_Ampli.sh ${TARGETDIR} 
		CheckAreaOfInterest_InAmplitudesDir.sh

		cd _AMPLI
		jpg2movie_gif.sh ${SAT} ${TRK} ${REGION}

		# some crops as XxY size+X+Y offset (i.e. offset = upper left corner coord as displayed e.g. with Fiji)
		# Adjust crop e.g. by testing on a jpg file as follow: convert 20160105.HH.mod.flop.jpg -crop 450x450+1435+1010 +repage 20160105.HH.mod.flopCROP.jpg 
		ALL2GIFCrop
		
# 		case "${SAT}_${TRK}_${REGION}" in 
# 			"S1_DRC_NyigoCrater_A_174_Nyigo_crater_originalForm")  
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 270x270+4175+130 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif  
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 			"S1_DRC_NyigoCrater_D_21_Nyigo_Nyam_crater_originalForm")
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 200x200+3580+950 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif 
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 			"S1_DRC_NyamCrater_A_174_Nyam_crater_originalForm")
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 260x280+4030+560 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 
# 			"RADARSAT_RS2_F2F_Desc_Nyam")
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 260x280+4030+560 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 			"RADARSAT_RS2_UF_Asc_Nyam")
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 550x550+480+1130 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 
# 			"CSK_Virunga_Asc_Nyigo2")
# 		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 500x500+770+2020 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_Nyigo.gif
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 550x550+785+1570 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_Nyigo.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 			"CSK_Virunga_Desc_NyigoCrater2")
# 		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 1000x750+900+780 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif
# 		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 570x500+550+440 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 850x500+300+420 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 			"CSK_Virunga_Asc_NyamCrater2")
# 		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 400x320+630+0 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 450x250+1080+0 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 			"CSK_Virunga_Desc_NyamCrater2")
# 		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 400x420+1590+1350 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 450x450+1435+1010 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 
# 			"S1_Hawaii_LL_A_124_Hawaii_LL_Crater_originalForm")
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 550x380+4800+1 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_Crater.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 			"S1_Hawaii_LL_D_87_Hawaii_LL_Crater_originalForm")
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 350x400+450+80 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_Crater.gif
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 				
# 			"S1_PF_SM_A_144_PitonFournaise")  
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 2400x1600+1800+1800 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_PDF.gif  
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 			"S1_PF_SM_D_151_tstampli_PitonFournaise")  
# 				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 2500x1600+1800+1400 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_PDF.gif  
# 				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
# 
# 			*)
# 				echo "No predefined crop for gif. Please do manually if required." ;;
# 		esac
	else 
		echo "No new image"
fi
