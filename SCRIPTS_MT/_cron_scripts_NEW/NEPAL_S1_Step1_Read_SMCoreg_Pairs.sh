#!/bin/bash
# Script to run in cronjob for processing Central Nepal images:
# Read images, check if nr of bursts and corners coordinates are OK, 
# corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 
#
# NOTE:	This script requires several adjustments in script body if transferred to another target. 
#		See all infos about Tracks and Sets
#
# New in Distro V 2.0.0 20241111 :	- based on Lux cron script
# New in Distro V 2.1.0 20250225 :	- adapt kml for reading to avoid extra bursts 
#									- add kml with overlap area of interest to check bursts nr of each mode
# New in Distro V 3.0.0 20251111 :	- Since new download and unzip from Mac doris5m4, no need to Sort_UNZIP_S1.sh
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=30
BP2=70
BT=400
DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC1=20240328		# Asc 85
SMASC2=20180401		# Asc 158

SMDESC1=20180928		# Desc 19
SMDESC2=20220714		# Desc 92
SMDESC3=20170904		# Desc 121

# DO NOT FORGET TO ADJUST ALSO THE SET BELOWS IN SCRIPT

# Nr of shortests connections for Baseline plot
SHORTESTS="YES"
NR=3

# some files and PATH
#####################
#SAR_DATA
PATHDIRSARDATA=$PATH_3610/SAR_DATA/S1/

# Not needed anymore since download and unzip from doris5m4
#DIRSARDATA=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC.UNZIP 

DIRSARDATAA85=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_A85.UNZIP 
DIRSARDATAA158=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_A158.UNZIP 
DIRSARDATAD19=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_D19.UNZIP 
DIRSARDATAD92=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_D92.UNZIP 
DIRSARDATAD121=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_D121.UNZIP 


#SAR_CSL
DIRSARCSL=$PATH_3611/SAR_CSL/S1/NEPAL
#SETi DIR
DIRSET=$PATH_1660/SAR_SM/MSBAS/NEPAL
# Dir to clean clean when orbits are updated
RESAMDIR=${PATH_3610}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_3611}/SAR_MASSPROCESS/

#kml file for geocoding whole zone 
KMLFILE=$PATH_1650/kml/Nepal/CentralNepal.kml		

#kml file for reading download per mode
KMLFILEREADINGA85=$PATH_1650/kml/Nepal/Download_CentralNepalBursts_A85.kml		# also in $PATH_3611/SAR_CSL/S1/NEPAL/
KMLFILEREADINGA158=$PATH_1650/kml/Nepal/Download_CentralNepalBursts_A158.kml		# also in $PATH_3611/SAR_CSL/S1/NEPAL/
KMLFILEREADINGD19=$PATH_1650/kml/Nepal/Download_CentralNepalBursts_D19.kml		# also in $PATH_3611/SAR_CSL/S1/NEPAL/
KMLFILEREADINGD92=$PATH_1650/kml/Nepal/Download_CentralNepalBursts_D92.kml		# also in $PATH_3611/SAR_CSL/S1/NEPAL/
KMLFILEREADINGD121=$PATH_1650/kml/Nepal/Download_CentralNepalBursts_D121.kml		# also in $PATH_3611/SAR_CSL/S1/NEPAL/


#kml file for testing overlap between whole CentralNepal zone and each S1 mode
KMLFILEA85=$PATH_1650/kml/Nepal/KML_GOOGLEEARTH/Overlap_CentralNepal_A85.kml
KMLFILEA158=$PATH_1650/kml/Nepal/KML_GOOGLEEARTH/Overlap_CentralNepal_A158.kml	
KMLFILED19=$PATH_1650/kml/Nepal/KML_GOOGLEEARTH/Overlap_CentralNepal_D19.kml	
KMLFILED92=$PATH_1650/kml/Nepal/KML_GOOGLEEARTH/Overlap_CentralNepal_D92.kml
KMLFILED121=$PATH_1650/kml/Nepal/KML_GOOGLEEARTH/Overlap_CentralNepal_D121.kml

#Launch param files
PARAMCOREGASC1=$PATH_1650/Param_files/S1/Nepal_A_85/LaunchMTparam_S1_Nepal_A_85_Zoom1_ML2_Coreg_0keep.txt 
PARAMCOREGASC2=$PATH_1650/Param_files/S1/Nepal_A_158/LaunchMTparam_S1_Nepal_A_158_Zoom1_ML2_Coreg_0keep.txt 

PARAMCOREGDESC1=$PATH_1650/Param_files/S1/Nepal_D_19/LaunchMTparam_S1_Nepal_D_19_Zoom1_ML2_Coreg_0keep.txt
PARAMCOREGDESC2=$PATH_1650/Param_files/S1/Nepal_D_92/LaunchMTparam_S1_Nepal_D_92_Zoom1_ML2_Coreg_0keep.txt
PARAMCOREGDESC3=$PATH_1650/Param_files/S1/Nepal_D_121/LaunchMTparam_S1_Nepal_D_121_Zoom1_ML2_Coreg_0keep.txt

# resampled dir
NEWASCPATH1=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_A_85/SMNoCrop_SM_${SMASC2}
NEWASCPATH2=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_A_158/SMNoCrop_SM_${SMASC2}

NEWDESCPATH1=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_D_19/SMNoCrop_SM_${SMDESC3}
NEWDESCPATH2=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_D_92/SMNoCrop_SM_${SMDESC3}
NEWDESCPATH3=$PATH_3610/SAR_SM/RESAMPLED/S1/Nepal_D_121/SMNoCrop_SM_${SMDESC3}

#Color table 
#COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AAADDD.txt	# for 6 data sets
	COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt	# for 2 data sets

# Prepare stuffs
################
mkdir -p ${DIRSARCSL}
echo "Starting $0" > ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt

# Let's go
##########

# Because of Central Nepal large area, a single kml can't be used for all the modes without 
# loosing some bursts once for a while because of slightly changing footprints. To overcome 
# that problem, raw images are sorted before reading with a dedicated kml. The global kml is 
# however used for the final geocoding (CentralNepal.kml)

# Not needed anymore since download and unzip from doris5m4
#Sort_UNZIP_S1.sh ${DIRSARDATA}

# Read all S1 images for that footprint by modes - DO NOT RUN IN BACKGROUND BECAUSE IT WOULD CRASH AT SORTING SOME MODES WHILE OTHER ARE STILL RUNNING
## $PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATA} ${DIRSARCSL}/NoCrop S1 ${KMLFILEREADING} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1

# DO THIS AT REGULAR UPDATE RUN
###############################
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAA85} ${DIRSARCSL}/NoCrop S1 ${KMLFILEREADINGA85} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1 
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAA158} ${DIRSARCSL}/NoCrop S1 ${KMLFILEREADINGA158} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1 
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAD19} ${DIRSARCSL}/NoCrop S1 ${KMLFILEREADINGD19} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1 
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAD92} ${DIRSARCSL}/NoCrop S1 ${KMLFILEREADINGD92} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1 
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAD121} ${DIRSARCSL}/NoCrop S1 ${KMLFILEREADINGD121} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1 


# DO THIS AT FIRST MASS RUN
############################
#echo "Method below is optimized for first mass process run; not optimized for later update run, a.o. because of managment of Quarantained data"
#
#$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAA85} ${DIRSARCSL}_A85TMP/NoCrop S1 ${KMLFILEREADINGA85} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML ForceAllYears > /dev/null 2>&1 &
#$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAA158} ${DIRSARCSL}_A158TMP/NoCrop S1 ${KMLFILEREADINGA158} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML ForceAllYears > /dev/null 2>&1 &
#$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAD19} ${DIRSARCSL}_D19TMP/NoCrop S1 ${KMLFILEREADINGD19} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML ForceAllYears > /dev/null 2>&1 &
#$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAD92} ${DIRSARCSL}_D92TMP/NoCrop S1 ${KMLFILEREADINGD92} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML ForceAllYears > /dev/null 2>&1 &
#$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAD121} ${DIRSARCSL}_D121TMP/NoCrop S1 ${KMLFILEREADINGD121} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML ForceAllYears > /dev/null 2>&1 &
#
#wait
#
##echo "Move images in mode dir"
#
#echo "not tested yet - echo and exit"
#
#
#echo "mkdir -p ${DIRSARCSL}_A_85/NoCrop"
#echo "mkdir -p ${DIRSARCSL}_A_158/NoCrop"
#echo "mkdir -p ${DIRSARCSL}_D_19/NoCrop"
#echo "mkdir -p ${DIRSARCSL}_D_92/NoCrop"
#echo "mkdir -p ${DIRSARCSL}_D_121/NoCrop"
#echo ""
#echo "mv ${DIRSARCSL}_A85TMP_A_85/NoCrop/* ${DIRSARCSL}_A_85/NoCrop/"
#echo "mv ${DIRSARCSL}_A158TMP_A_158/NoCrop/* ${DIRSARCSL}_A_158/NoCrop/"
#echo "mv ${DIRSARCSL}_D19TMP_D_19/NoCrop/* ${DIRSARCSL}_D_19/NoCrop/"
#echo "mv ${DIRSARCSL}_D92TMP_D_92/NoCrop/* ${DIRSARCSL}_D_92/NoCrop/"
#echo "mv ${DIRSARCSL}_D121TMP_D_121/NoCrop/* ${DIRSARCSL}_D_121/NoCrop/"
#echo ""
#echo "rm -rf ${DIRSARCSL}_A85TMP_A_85"
#echo "rm -rf ${DIRSARCSL}_A158TMP_A_158"
#echo "rm -rf ${DIRSARCSL}_D19TMP_D_19"
#echo "rm -rf ${DIRSARCSL}_D92TMP_D_92"
#echo "rm -rf ${DIRSARCSL}_D121TMP_D_121"
#echo " "
#echo "echo "Move and rebuild links""
#echo "mv ${DIRSARCSL}_A85TMP/NoCrop/* ${DIRSARCSL}/NoCrop/"
#echo "mv ${DIRSARCSL}_A158TMP/NoCrop/* ${DIRSARCSL}/NoCrop/"
#echo "mv ${DIRSARCSL}_D19TMP/NoCrop/* ${DIRSARCSL}/NoCrop/"
#echo "mv ${DIRSARCSL}_D92TMP/NoCrop/* ${DIRSARCSL}/NoCrop/"
#echo "mv ${DIRSARCSL}_D121TMP/NoCrop/* ${DIRSARCSL}/NoCrop/"
#echo ""
#echo "cd ${DIRSARCSL}/NoCrop/"
#echo "Rebuild_lns.sh "_85_*" ${DIRSARCSL}_A_85/NoCrop/ &"
#echo "Rebuild_lns.sh "_158_*" ${DIRSARCSL}_A_158/NoCrop/ &"
#echo "Rebuild_lns.sh "_19_*" ${DIRSARCSL}_D_19/NoCrop/ &"
#echo "Rebuild_lns.sh "_92_*" ${DIRSARCSL}_D_92/NoCrop/ &"
#echo "Rebuild_lns.sh "_121_*" ${DIRSARCSL}_D_121/NoCrop/ &"
#
#wait
# exit


# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
## Asc ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/Nepal_A_15/NoCrop/S1B_15_20211011_A.csl Dummy
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_85/NoCrop 23 84.16 86.27 27.75 29.13 &	# beware the image does not cover the whole kml
_Check_ALL_S1_SizeAndCoord_InDir.sh "${DIRSARCSL}_A_85/NoCrop" 23 "${KMLFILEA85}" &
_Check_ALL_S1_SizeAndCoord_InDir.sh "${DIRSARCSL}_A_158/NoCrop" 12 "${KMLFILEA158}" &

## Desc
_Check_ALL_S1_SizeAndCoord_InDir.sh "${DIRSARCSL}_D_19/NoCrop" 18 "${KMLFILED19}" &
_Check_ALL_S1_SizeAndCoord_InDir.sh "${DIRSARCSL}_D_92/NoCrop" 5 "${KMLFILED92}" &
_Check_ALL_S1_SizeAndCoord_InDir.sh "${DIRSARCSL}_D_121/NoCrop" 6 "${KMLFILED121}" &

wait

# Coregister all images on the super master 
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC1} &	# Asc 85 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC2} &	# Asc 158 

# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC1} &	# Desc 19  
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC2} &	# Desc 92 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC3} &	# Desc 121 

# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_85/NoCrop ${DIRSET}/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_158/NoCrop ${DIRSET}/set2 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_19/NoCrop ${DIRSET}/set3 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_92/NoCrop ${DIRSET}/set4 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_121/NoCrop ${DIRSET}/set5 S1 > /dev/null 2>&1  &

wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH1}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set1 ${BP} ${BT} ${SMASC2} ${BP2} ${BT} ${DATECHG}  > /dev/null 2>&1  &
fi
if [ ! -s ${NEWASCPATH2}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set2 ${BP} ${BT} ${SMASC2} ${BP2} ${BT} ${DATECHG}  > /dev/null 2>&1  &
fi

if [ ! -s ${NEWDESCPATH1}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set3 ${BP} ${BT} ${SMDESC3} ${BP2} ${BT} ${DATECHG} > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH2}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set4 ${BP} ${BT} ${SMDESC3} ${BP2} ${BT} ${DATECHG} > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH3}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set5 ${BP} ${BT} ${SMDESC3} ${BP2} ${BT} ${DATECHG} > /dev/null 2>&1  &
fi
wait

if [ "${SHORTESTS}" == "YES" ] ; then 
	cd ${DIRSET}/set1 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set1/allPairsListing.txt ${NR}
	
	cd ${DIRSET}/set2 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set2/allPairsListing.txt ${NR}
	
	cd ${DIRSET}/set3
	Extract_x_Shortest_Connections.sh ${DIRSET}/set3/allPairsListing.txt ${NR}
	
	cd ${DIRSET}/set4 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set4/allPairsListing.txt ${NR}
	
	cd ${DIRSET}/set5 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set5/allPairsListing.txt ${NR}
fi

## Plot baseline plot with all modes 
#if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
#
#	if [ `baselinePlot | wc -l` -eq 0 ] 
#		then
#			# use AMSTer Engine before May 2022
#			mkdir -p ${DIRSET}/BaselinePlots_S1_set_1to6
#			cd ${DIRSET}/BaselinePlots_S1_set_1to6
#
#			#echo "${DIRSET}/set1" > ModeList.txt
#			echo "${DIRSET}/set2" > ModeList.txt
#			#echo "${DIRSET}/set3" >> ModeList.txt
#			#echo "${DIRSET}/set4" >> ModeList.txt
#			#echo "${DIRSET}/set5" >> ModeList.txt
#			echo "${DIRSET}/set6" >> ModeList.txt
#			#echo "${DIRSET}/set7" >> ModeList.txt
#
#			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 ${BT} ${COLORTABLE}
#		else
#			# use AMSTer Engine > May 2022
#			mkdir -p ${DIRSET}/BaselinePlots_set1_to_set6
#			cd ${DIRSET}/BaselinePlots_set1_to_set6
# 
#			#echo "${DIRSET}/set1" > ModeList.txt
#			echo "${DIRSET}/set2" > ModeList.txt
#			#echo "${DIRSET}/set3" >> ModeList.txt
#			#echo "${DIRSET}/set4" >> ModeList.txt
#			#echo "${DIRSET}/set5" >> ModeList.txt
#			echo "${DIRSET}/set6" >> ModeList.txt
# 			#echo "${DIRSET}/set7" >> ModeList.txt
#			
#			#plot_Multi_BaselinePlot.sh ${DIRSET}/BaselinePlots_set1_to_set6/ModeList.txt	
#			plot_Multi_BaselinePlot.sh ${DIRSET}/BaselinePlots_set2_set6/ModeList.txt
#			
#	fi	
#fi

echo "Ending $0" >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt




