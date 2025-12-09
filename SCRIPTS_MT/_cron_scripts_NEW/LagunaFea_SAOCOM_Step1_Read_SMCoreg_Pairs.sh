#!/bin/bash
# Script to run in cronjob for processing SAOCOM LagunaFea images:
# Read images, 
# corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for ascending and descending modes. 
#
# NOTE:	This script requires several adjustments in script body if transferred to another target. 
#		See all infos about Tracks and Sets
#
# New in Distro V 1.0.0 20231110 :	- init
# New in Distro V 1.0.1 20231219 :	- debug typo in desc path 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=600
#BP2=
BT=400
#DATECHG=

POL=HH

# If wants Delaunay Table
DELAUNAY=YES
RATIO1=30
RATIO2=30

# If wants Shortest connections Table
SHORTESTS=YES
NR1=3	# How amny shortest connections for mode 1
NR2=3	# How amny shortest connections for mode 2

# Global Primaries (SuperMasters)
SMASC1=20231010		# Asc 042_A
SMDESC1=20231105	# Desc 152_D
# DO NOT FORGET TO ADJUST ALSO THE SET BELOWS IN SCRIPT

# some files and PATH
#####################
#SAR_DATA
DIRSARDATA=$PATH_3610/SAR_DATA/SAOCOM/LagunaFea-UNZIP

#SAR_CSL
DIRSARCSL=$PATH_1650/SAR_CSL/SAOCOM/LagunaFea

#SETi DIR
DIRSET=$PATH_1650/SAR_SM/MSBAS/LagunaFea

# Dir to clean clean when orbits are updated
RESAMDIR=${PATH_1650}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_3601}/SAR_MASSPROCESS/

#kml file
KMLFILE=$PATH_1650/SAR_CSL/SAOCOM/LagunaFea/LagunaFea.kml		# also in $PATH_1650/kml/ARGENTINA/LagunaFea.kml

#Launch param files
PARAMCOREGASC1=$PATH_1650/Param_files/SAOCOM/LagunaFea_042_A/LaunchMTparam_SAOCOM_LagunaFea_Asc_Zoom1_ML8_Coreg.txt
PARAMCOREGDESC1=$PATH_1650/Param_files/SAOCOM/LagunaFea_152_D/LaunchMTparam_SAOCOM_LagunaFea_Desc_Zoom1_ML8_Coreg.txt

NEWASCPATH=$PATH_1650/SAR_SM/RESAMPLED/SAOCOM/LagunaFea_042_A/SMNoCrop_SM_${SMASC1}
NEWDESCPATH=$PATH_1650/SAR_SM/RESAMPLED/SAOCOM/LagunaFea_152_D/SMNoCrop_SM_${SMDESC1}

#Color table 
COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt	# for 2 data sets

# Prepare stuffs
################
echo "Starting $0" > ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt

# Let's go
##########

# Read all images for that footprint
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATA} ${DIRSARCSL}/NoCrop SAOCOM ${KMLFILE} ${POL} ${RESAMDIR} ${MASSPRODIR}  > /dev/null 2>&1

# Coregister all images on the super master 
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC1} &	# Asc 42 - Full cover 

# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC1} &	# Desc 152 - Full cover 

# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_042_A/NoCrop ${DIRSET}/set1 SAOCOM > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_152_D/NoCrop ${DIRSET}/set2 SAOCOM > /dev/null 2>&1  &

wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set1 ${BP} ${BT} ${SMASC1} 	> /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set2 ${BP} ${BT} ${SMDESC1}  > /dev/null 2>&1  &
fi
wait

if [ "${DELAUNAY}" == "YES" ] ; then 
	cd ${DIRSET}/set1 
	DelaunayTable.sh -Ratio=${RATIO1}
	
	cd ${DIRSET}/set2 
	DelaunayTable.sh -Ratio=${RATIO2}
fi

if [ "${SHORTESTS}" == "YES" ] ; then 
	cd ${DIRSET}/set1 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set1/allPairsListing.txt ${NR1}
	
	cd ${DIRSET}/set2 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set2/allPairsListing.txt ${NR2}
fi

# Plot baseline plot with all modes 
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 

	if [ `baselinePlot | wc -l` -eq 0 ] 
		then
			# use AMSTer Engine before May 2022
			mkdir -p ${DIRSET}/BaselinePlots_SAOCOM_set_12
			cd ${DIRSET}/BaselinePlots_SAOCOM_set_12

			echo "${DIRSET}/set1" > ModeList.txt
			echo "${DIRSET}/set2" >> ModeList.txt

			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 ${BT} ${COLORTABLE}
		else
			# use AMSTer Engine > May 2022
			mkdir -p ${DIRSET}/BaselinePlots_SAOCOM_set_12
			cd ${DIRSET}/BaselinePlots_SAOCOM_set_12
 
			echo "${DIRSET}/set1" > ModeList.txt
			echo "${DIRSET}/set2" >> ModeList.txt
 			
			plot_Multi_BaselinePlot.sh ${DIRSET}/BaselinePlots_SAOCOM_set_12/ModeList.txt
			
	fi	
fi

echo "Ending $0" >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt




