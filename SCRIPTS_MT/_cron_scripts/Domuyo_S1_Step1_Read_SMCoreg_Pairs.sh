#!/bin/bash
# Script to run in cronjob for processing DOMUYO images:
# Read images, check if nr of bursts and corners coordinates are OK, 
# corigister them on a Global Primary (super master) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 
#
# BEWARE, if it is the first run, you must compute the baseline plot (to get the Global Primary) before starting the coregistration
#
# New in Distro V 2.0.0 20220602 :	- use new Prepa_MSBAS.sh compatible with D Derauw and L. Libert tools for Baseline Ploting
# New in Distro V 3.0.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 3.1.0 20230626 :	- Color tables are now in TemplatesForPlots
# New in Distro V 4.0.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#									- Replace CIS by MT in names 
#									- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#					   				- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.1.0 20231116:	- Reshape with variables
#									- double criteria to compute baseline plot in order to account for the loss of S1B
#									- run _Check_ALL_S1_SizeAndCoord_InDir.sh in parallel
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/25 - could make better... when time.
# -----------------------------------------------------------------------------------------
source $HOME/.bashrc

# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=20
BP2=30
BT=450
DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC=20180512		# Asc 18
SMDESC=20180222		# Desc 83

POL=VV

# some files and PATH
#####################
#SAR_DATA
DIRSARDATA=${PATH_3600}/SAR_DATA/S1/S1-DATA-DOMUYO-SLC.UNZIP
#SAR_CSL
DIRSARCSL=${PATH_1650}/SAR_CSL/S1/ARG_DOMU_LAGUNA

#kml file
KMLFILE=${DIRSARCSL}/DomuyoYLagunaFea.kml		# also in $PATH_1650/kml/ARGENTINA/DomuyoYLagunaFea.kml

#Launch param files
PARAMCOREGASC=$PATH_1650/Param_files/S1/ARG_DOMU_LAGUNA_A_18/LaunchMTparam_S1_Arg_Domu_Laguna_A_18_Zoom1_ML4_MassProc_Coreg.txt 
PARAMCOREGDESC=$PATH_1650/Param_files/S1/ARG_DOMU_LAGUNA_D_83/LaunchMTparam_S1_Arg_Domu_Laguna_D_83_Zoom1_ML4_MassProc_Coreg.txt

#SETi DIR
DIRSET=$PATH_1650/SAR_SM/MSBAS/ARGENTINE


# Tracks (end of dir name where S1 images.csl are stored)
TRKASC=A_18
TRKDESC=D_83

# Where data will be resampled (on the Global Primary)
NEWASCPATH=$PATH_1650/SAR_SM/RESAMPLED/S1/ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_${SMASC}
NEWDESCPATH=$PATH_1650/SAR_SM/RESAMPLED/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_${SMDESC}

# Dir to clean  when orbits are updated
RESAMDIR=${PATH_1650}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_3601}/SAR_MASSPROCESS/

#Color table 
#COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AAADDD.txt	# for 6 data sets
COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt	# for 2 data sets


# Let's Go
##########
echo "Starting $0" > ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt

# Read all S1 images for that footprint
#######################################
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATA} ${DIRSARCSL}/NoCrop S1 ${KMLFILE} ${POL} ${RESAMDIR} ${MASSPRODIR} > /dev/null 2>&1

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
# Asc ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/ARG_DOMU_LAGUNA_A_18/NoCrop/S1B_18_20211210_A.csl Dummy
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_18/NoCrop 14 -71.1264 -37.3038 -69.1902 -36.8461 -71.5447 -36.0797 -69.6394 -35.6292 &

# Desc ; bursts size and coordinates are obtained by running e.g.: _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/S1B_83_20211109_D.csl Dummy
# Beware D83 with S1B after Jan 2020 are shorter on the Western side, hence check first with large coordinate, then check the images in __TMP_QUARANTINE with smaller coordinates. 
#        If OK, put them back in NoCrop dir. If not, keep them in original __TMP_QUARANTINE

# consistent with S1B before Jan 2020 
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_83/NoCrop 14 -69.0318 -36.1361 -70.9962 -35.6524 -69.4497 -37.3619 -71.4464 -36.8704 &

wait 

# consistent with S1B after Jan 2020 
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_${TRKDESC}/NoCrop/__TMP_QUARANTINE 14 -68.9461 -36.1361 -70.9962 -35.6524 -69.3630 -37.3619 -71.4464 -36.8704
	mv ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_D_83/NoCrop/ 2>/dev/null
	mv ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
	mv ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/*.txt ${DIRSARCSL}_D_83/NoCrop 2>/dev/null
	rm -R ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null


# Coregister all images on the Global Primary (Super Master) 
############################################################
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC} &
# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC} &

# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${DIRSARCSL}_${TRKASC}/NoCrop" ${DIRSET}/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${DIRSARCSL}_${TRKDESC}/NoCrop" ${DIRSET}/set2 S1 > /dev/null 2>&1 &
wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	#echo "n" | Prepa_MSBAS.sh ${DIRSET}/set1 ${BP} 450 20180512 > /dev/null 2>&1  &
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set1 ${BP} ${BT} ${SMASC} ${BP2} ${BT} ${DATECHG}  > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	#echo "n" | Prepa_MSBAS.sh ${DIRSET}/set2 ${BP} 450 20180222 > /dev/null 2>&1  &
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set2 ${BP} ${BT} ${SMDESC} ${BP2} ${BT} ${DATECHG}  > /dev/null 2>&1  &
fi
wait

# Plot baseline plot with both modes - TAKING ONLY INTO ACCOUNT THE FIRST OF THE TWO BASELINE CRITERIA, THAT IS THE ONE USED BEFORE DATECHG 
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
		if [ `baselinePlot | wc -l` -eq 0 ] 
			then
				# use AMSTer Engine before May 2022
				mkdir -p ${DIRSET}/BaselinePlots_S1_set_1_2
				cd ${DIRSET}/BaselinePlots_S1_set_1_2

				echo "${DIRSET}/set1" > ModeList.txt
				echo "${DIRSET}/set2" >> ModeList.txt

				$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 ${BT} ${COLORTABLE}
			else
				# use AMSTer Engine > May 2022
				mkdir -p ${DIRSET}/BaselinePlots_set1_set2
				cd ${DIRSET}/BaselinePlots_set1_set2
 
				echo "${DIRSET}/set1" > ModeList.txt
				echo "${DIRSET}/set2" >> ModeList.txt
 
				plot_Multi_BaselinePlot.sh ${DIRSET}/BaselinePlots_set1_set2/ModeList.txt
			
		fi
fi

echo "Ending $0" >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
