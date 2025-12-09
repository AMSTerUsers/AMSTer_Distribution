#!/bin/bash
# Script to run in cronjob for processing MUSTANG images with ETAD data:
# Read images already processed in Normal run (i.e. without ETAD), hence these steps are commented below. 
# Check if nr of bursts and corners coordinates are OK, 
# add the ETAD products, 
# No need to corigister them on a Global Primary (super master) because ETAD plays no role here, hence these steps are commented below. 
# Compute the compatible pairs for only the images with full ETAD data.
#
# BEWARE, if it is the first run, you must compute the baseline plot (to get the Global Primary) before starting the coregistration
#
# New in Distro V 1.0.0 20251031 :	- based on Domuyo with ETAD

#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/25 - could make better... when time.
# -----------------------------------------------------------------------------------------
source $HOME/.bashrc

# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=30
BT=400

BP2=70 
DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC=20241116		# Asc 158
SMDESC=20190830		# Desc 19

# Nr of shortests connections for Baseline plot
SHORTESTS="YES"
NR=3
NR2=2	# to try two sets...

# FIRST ETAD PROD
FIRSTETAD=20230701		# atleast in Sept 2025, ESA did not provided with ETAD data before end of July 2023

# Main olarisation 
POL=VV

# some files and PATH
#####################
#SAR_DATA
PATHDIRSARDATA=$PATH_3610/SAR_DATA/S1/

DIRSARDATA=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC.UNZIP 

DIRSARDATAA158=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_A158.UNZIP 
DIRSARDATAD19=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_D19.UNZIP 

#SAR_CSL
DIRSARCSL=${PATH_3611}/SAR_CSL/S1/MUSTANG

# ETAD DIR
ETADASCDIR=${PATH_3611}/SAR_ETAD.UNZIP/NEPAL_A_158 
ETADDESCDIR=${PATH_3611}/SAR_ETAD.UNZIP/NEPAL_D_19 


#kml file
KMLFILE=${PATH_1650}/kml/Nepal/Mustang_area.kml								
KMLDOWNLOADFILE=${PATH_1650}/kml/Nepal/Mustang_area.kml

#Launch param files
# NOT USED HERE BECAUSE COREG DONE IN USUAL PROCESSING
#PARAMCOREGASC=${PATH_1650}/Param_files/S1/MUSTANG_A_158/LaunchMTparam_S1_Mustang_A_158_Zoom1_ML2_Coreg_0keep_ETAD.txt 
#PARAMCOREGDESC=${PATH_1650}/Param_files/S1/MUSTANG_D_19/LaunchMTparam_S1_Mustang_D_19_Zoom1_ML2_Coreg_0keep_ETAD.txt 

#SETi DIR
DIRSET=$PATH_1660/SAR_SM/MSBAS/MUSTANG

# Tracks (end of dir name where S1 images.csl are stored)
TRKASC=A_158
TRKDESC=D_19

# Where data will be resampled (on the Global Primary)
NEWASCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/MUSTANG_A_158/SMNoCrop_SM_${SMASC}
NEWDESCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/MUSTANG_D_119/SMNoCrop_SM_${SMDESC}

# Dir to clean  when orbits are updated (Reminder: latency of precise orbits = 20 days and ETAD = 14 days and maybe less in future) 
RESAMDIR=${PATH_3610}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_3611}/SAR_MASSPROCESS/

#Color table 
#COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AAADDD.txt	# for 6 data sets
COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt	# for 2 data sets


# Let's Go
##########
echo "Starting $0" > ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt

# Read all S1 images for that footprint
#######################################
#### THIS IS PERFORMED FOR NORMAL PROCESSING 
####$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATA} ${DIRSARCSL}/NoCrop S1 ${KMLFILE} ${POL} ${RESAMDIR} ${MASSPRODIR} > /dev/null 2>&1

# Read ETAD products
####################
# Get last ETAD Data in each mode 
	RUNDATE=$(${PATHGNU}/gdate "+%Y%m%d")
	X=100 # days
	DATEMINUSX=$(${PATHGNU}/gdate -d "-${X} days" "+%Y%m%d") # ie. Today minus X days, here take about 3 months, i.e. 100 days  

ReadETAD.sh ${DIRSARCSL}_${TRKASC}/NoCrop/ ${ETADASCDIR} ${DATEMINUSX} &
ReadETAD.sh ${DIRSARCSL}_${TRKDESC}/NoCrop/ ${ETADDESCDIR} ${DATEMINUSX} &
wait 

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
# Asc ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/ARG_DOMU_LAGUNA_A_18/NoCrop/S1B_18_20211210_A.csl Dummy
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_18/NoCrop 14 -71.1264 -37.3038 -69.1902 -36.8461 -71.5447 -36.0797 -69.6394 -35.6292 &
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_158/NoCrop 5 ${KMLDOWNLOADFILE} &

# Desc ; bursts size and coordinates are obtained by running e.g.: _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop/S1B_83_20211109_D.csl Dummy
# Beware D83 with S1B after Jan 2020 are shorter on the Western side, hence check first with large coordinate, then check the images in __TMP_QUARANTINE with smaller coordinates. 
#        If OK, put them back in NoCrop dir. If not, keep them in original __TMP_QUARANTINE

# consistent with S1B before Jan 2020 
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_83/NoCrop 14 -69.0318 -36.1361 -70.9962 -35.6524 -69.4497 -37.3619 -71.4464 -36.8704 &
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_19/NoCrop 4 ${KMLDOWNLOADFILE} &

wait 

#### Temp quarantined files 
###_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_${TRKASC}/NoCrop/__TMP_QUARANTINE 14 ${KMLDOWNLOADFILE}
###	mv ${DIRSARCSL}_${TRKASC}/NoCrop/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_${TRKASC}/NoCrop/ 2>/dev/null
###	mv ${DIRSARCSL}_${TRKASC}/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_${TRKASC}/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
###	mv ${DIRSARCSL}_${TRKASC}/NoCrop/__TMP_QUARANTINE/*.txt ${DIRSARCSL}_${TRKASC}/NoCrop 2>/dev/null
###	rm -R ${DIRSARCSL}_${TRKASC}/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null
###
###_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_${TRKDESC}/NoCrop/__TMP_QUARANTINE 14 ${KMLDOWNLOADFILE}
###	mv ${DIRSARCSL}_${TRKDESC}/NoCrop/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_${TRKDESC}/NoCrop/ 2>/dev/null
###	mv ${DIRSARCSL}_${TRKDESC}/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_${TRKDESC}/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
###	mv ${DIRSARCSL}_${TRKDESC}/NoCrop/__TMP_QUARANTINE/*.txt ${DIRSARCSL}_${TRKDESC}/NoCrop 2>/dev/null
###	rm -R ${DIRSARCSL}_${TRKDESC}/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null

## consistent with S1B after Jan 2020 
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_${TRKDESC}/NoCrop/__TMP_QUARANTINE 14 -68.9461 -36.1361 -70.9962 -35.6524 -69.3630 -37.3619 -71.4464 -36.8704
#	mv ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_D_83/NoCrop/ 2>/dev/null
#	mv ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
#	mv ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/*.txt ${DIRSARCSL}_D_83/NoCrop 2>/dev/null
#	rm -R ${DIRSARCSL}_D_83/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null
#

# Check ETAD Data and list only images with ETADDATA from the beginning to get the list of images to coreg (and mass process)
cd ${DIRSARCSL}_${TRKASC}/NoCrop/
CheckETAD.sh 
# take the most recent file
CHECKETADASC=$(find . -maxdepth 1 -type f -name "_ETAD_All_OK_*_FROM_${FIRSTETAD}.txt" -printf "%T@ %f\n" | sort -n | tail -n 1 | cut -d' ' -f2-) 		# cfr _ETAD_All_OK_...
# get only the list of dates - used to search images to link
${PATHGNU}/ggrep -oE '[0-9]{8}' ${CHECKETADASC} > List_ImgDate_All_ETAD.txt 
# get only the list of names, that is S1x....cl - used for coregsitration
${PATHGNU}/gsed -E 's/.*\.\.\///g' ${CHECKETADASC} > List_ImgName_All_ETAD.txt 
LISTETADASC="${DIRSARCSL}_${TRKASC}/NoCrop/List_ImgName_All_ETAD.txt" 

cd ${DIRSARCSL}_${TRKDESC}/NoCrop/
CheckETAD.sh 
# take the most recent file
CHECKETADDESC=$(find . -maxdepth 1 -type f -name "_ETAD_All_OK_*_FROM_${FIRSTETAD}.txt" -printf "%T@ %f\n" | sort -n | tail -n 1 | cut -d' ' -f2-) 		# cfr _ETAD_All_OK_...
# get only the list of dates - used to search images to link
${PATHGNU}/ggrep -oE '[0-9]{8}' ${CHECKETADDESC} > List_ImgDate_All_ETAD.txt 
# get only the list of names, that is S1x....cl - used for coregsitration
${PATHGNU}/gsed -E 's/.*\.\.\///g' ${CHECKETADDESC} > List_ImgName_All_ETAD.txt 
LISTETADDESC="${DIRSARCSL}_${TRKDESC}/NoCrop/List_ImgName_All_ETAD.txt"
cd 

# Coregister all images on the Global Primary (Super Master) 
############################################################
#### THIS IS PERFORMED FOR NORMAL PROCESSING 
##### in Ascending mode 
####$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC} NoForce ${LISTETADASC} &
##### in Descending mode 
####$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC} NoForce ${LISTETADDESC} &

# Search for pairs
##################
# Link all images to corresponding set dir - same as without ETAD data +10
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${DIRSARCSL}_${TRKASC}/NoCrop" ${DIRSET}/set11 S1 ${DIRSARCSL}_${TRKASC}/NoCrop/List_ImgDate_All_ETAD.txt  > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${DIRSARCSL}_${TRKDESC}/NoCrop" ${DIRSET}/set12 S1 ${DIRSARCSL}_${TRKDESC}/NoCrop/List_ImgDate_All_ETAD.txt  > /dev/null 2>&1 &
wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	#get first image haveing an ETAD product in Asc mode
	FIRSTETADASC=$(head -1 ${DIRSARCSL}_${TRKASC}/NoCrop/List_ImgDate_All_ETAD.txt)
	if [ "${DATECHG}" -gt "${FIRSTETADASC}" ] 
		then 
			echo "n" | Prepa_MSBAS.sh ${DIRSET}/set11 ${BP} ${BT} ${SMASC} ${BP2} ${BT} ${DATECHG}  > /dev/null 2>&1  &		
		else 
			echo "n" | Prepa_MSBAS.sh ${DIRSET}/set11 ${BP2} ${BT} ${SMASC} > /dev/null 2>&1  
			# rename pair dir as in case of "${DATECHG}" -st "${FIRSTETADASC}" for compatibility at step 2
			cp -f ${DIRSET}/set11/table_0_${BP2}_0_${BT}.txt ${DIRSET}/set11/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT}_After_WITHHEADER.txt		
	fi

fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	#get first image haveing an ETAD product in Desc mode
	FIRSTETADDESC=$(head -1 ${DIRSARCSL}_${TRKDESC}/NoCrop/List_ImgDate_All_ETAD.txt)
	if [ "${DATECHG}" -gt "${FIRSTETADDESC}" ] 
		then 
			echo "n" | Prepa_MSBAS.sh ${DIRSET}/set12 ${BP} ${BT} ${SMDESC} ${BP2} ${BT} ${DATECHG}  > /dev/null 2>&1  &
		else 
			echo "n" | Prepa_MSBAS.sh ${DIRSET}/set12 ${BP2} ${BT} ${SMDESC} > /dev/null 2>&1  		
			# rename pair dir as in case of "${DATECHG}" -st "${FIRSTETADASC}" for compatibility at step 2
			cp -f ${DIRSET}/set12/table_0_${BP2}_0_${BT}.txt ${DIRSET}/set12/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT}_After_WITHHEADER.txt		

	fi
fi
wait

if [ "${SHORTESTS}" == "YES" ] ; then 
	cd ${DIRSET}/set11 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set11/allPairsListing.txt ${NR}
	Extract_x_Shortest_Connections.sh ${DIRSET}/set11/allPairsListing.txt ${NR2}
	
	cd ${DIRSET}/set12 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set12/allPairsListing.txt ${NR}
	Extract_x_Shortest_Connections.sh ${DIRSET}/set12/allPairsListing.txt ${NR2}
fi


## Plot baseline plot with both modes - TAKING ONLY INTO ACCOUNT THE FIRST OF THE TWO BASELINE CRITERIA, THAT IS THE ONE USED BEFORE DATECHG 
#if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
#		if [ `baselinePlot | wc -l` -eq 0 ] 
#			then
#				# use AMSTer Engine before May 2022
#				mkdir -p ${DIRSET}/BaselinePlots_S1_set_1_2
#				cd ${DIRSET}/BaselinePlots_S1_set_1_2
#
#				echo "${DIRSET}/set1" > ModeList.txt
#				echo "${DIRSET}/set2" >> ModeList.txt
#
#				$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 ${BT} ${COLORTABLE}
#			else
#				# use AMSTer Engine > May 2022
#				mkdir -p ${DIRSET}/BaselinePlots_set1_set2
#				cd ${DIRSET}/BaselinePlots_set1_set2
# 
#				echo "${DIRSET}/set1" > ModeList.txt
#				echo "${DIRSET}/set2" >> ModeList.txt
# 
#				plot_Multi_BaselinePlot.sh ${DIRSET}/BaselinePlots_set1_set2/ModeList.txt
#			
#		fi
#fi

# Remove check etad data older than x days month
OLDNESS=30
cd ${DIRSARCSL}_${TRKASC}/NoCrop/
find . -maxdepth 1 -name "_ETAD_All_OK_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "_ETAD_Missing_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;

cd ${DIRSARCSL}_${TRKDESC}/NoCrop/
find . -maxdepth 1 -name "_ETAD_All_OK_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "_ETAD_Missing_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;


echo "Ending $0" >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
