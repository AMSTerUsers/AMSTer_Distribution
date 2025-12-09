#!/bin/bash
# Script to run in cronjob for processing MUSTANG  images:
# Read images, corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 

# New in Distro V 1.0.0 20250811 :	- based on Galeras and Nepal processing
# New in Distro V 1.1.0 20251027 :	- add longer segments to max 3 shortest baseline plots: 30 days - 180 days and 365 days with max 30m
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

echo "Starting $0" > $PATH_3610/SAR_CSL/S1/MUSTANG/Last_Run_Cron_Step1.txt
date >> $PATH_3610/SAR_CSL/S1/MUSTANG/Last_Run_Cron_Step1.txt

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

# some files and PATH
#####################
#SAR_DATA
PATHDIRSARDATA=$PATH_3610/SAR_DATA/S1/

DIRSARDATA=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC.UNZIP 

DIRSARDATAA158=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_A158.UNZIP 
DIRSARDATAD19=${PATHDIRSARDATA}/S1-DATA-NEPAL-SLC_D19.UNZIP 

#SAR_CSL
DIRSARCSL=$PATH_3611/SAR_CSL/S1/MUSTANG

#SETi DIR
DIRSET=$PATH_1660/SAR_SM/MSBAS/MUSTANG

# Dir to clean clean when orbits are updated
RESAMDIR=${PATH_3610}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_3611}/SAR_MASSPROCESS/


#kml file for reading download 
KMLFILEREADING=$PATH_1650/kml/Nepal/Mustang_area.kml			# that is 5 bursts in Asc and 5 in Desc
#kml file for testing overlap between zone and each S1 mode
KMLFILE=$PATH_1650/kml/Nepal/Mustang_area.kml		

#Launch param files
PARAMCOREGASC=$PATH_1650/Param_files/S1/MUSTANG_A_158/LaunchMTparam_S1_Mustang_A_158_Zoom1_ML2_Coreg_0keep.txt 
PARAMCOREGDESC=$PATH_1650/Param_files/S1/MUSTANG_D_19/LaunchMTparam_S1_Mustang_D_19_Zoom1_ML2_Coreg_0keep.txt 

# resampled dir
NEWASCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/Mustang_A_158/SMNoCrop_SM_${SMASC}
NEWDESCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/Mustang_D_19/SMNoCrop_SM_${SMDESC}

# Prepare stuffs
################
mkdir -p ${DIRSARCSL}
echo "Starting $0" > ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt

#
# Read all S1 images for that footprint
#######################################
# do not run them at the same time !
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAA158} ${DIRSARCSL}/NoCrop S1 ${KMLFILEREADING} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1 
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAD19} ${DIRSARCSL}/NoCrop S1 ${KMLFILEREADING} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1 

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
## Asc 164 ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/Region_Mode/NoCrop/S1A_an_image_A.csl Dummy
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_158/NoCrop 5 "${KMLFILE}" &


## Desc D_54; 
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_19/NoCrop 4 "${KMLFILE}" &
wait

# Coregister all images on the super master 
###########################################
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC} &
# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC} &

# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_158/NoCrop ${DIRSET}/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_19/NoCrop ${DIRSET}/set2 S1 > /dev/null 2>&1  &
wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set1 ${BP} ${BT} ${SMASC1} ${BP2} ${BT} ${DATECHG} > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set2 ${BP} ${BT} ${SMDESC1} ${BP2} ${BT} ${DATECHG} > /dev/null 2>&1  &
fi
wait


if [ "${SHORTESTS}" == "YES" ] ; then 
	cd ${DIRSET}/set1 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set1/allPairsListing.txt ${NR}
	Extract_x_Shortest_Connections.sh ${DIRSET}/set1/allPairsListing.txt ${NR2}
	
	cd ${DIRSET}/set2 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set2/allPairsListing.txt ${NR}
	Extract_x_Shortest_Connections.sh ${DIRSET}/set2/allPairsListing.txt ${NR2}
fi


## Plot baseline plot with both modes 
# if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
# 
# 	if [ `baselinePlot | wc -l` -eq 0 ] 
# 		then
# 			# use AMSTer Engine before May 2022
# 			mkdir -p $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_S1_set_1_2
# 			cd $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_S1_set_1_2
# 
# 			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set1" > ModeList.txt
# 			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set2" >> ModeList.txt
# 
# 			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 {BT}   $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt
# 		else
# 			# use AMSTer Engine > May 2022
# 			mkdir -p $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2
# 			cd $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2
#  
# 			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set1" > ModeList.txt
# 			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set2" >> ModeList.txt
#  
# 			plot_Multi_BaselinePlot.sh $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2/ModeList.txt
#  	fi
# 
# fi

# add 30, 180 and 365 days connections with may 30m

cd ${DIRSET}/set1 
##################
Select_xDays_MaxBp_Pairs.py ${DIRSET}/set1/allPairsListing.txt +MinDays=80 +MaxDays=120 +MaxBp=30 	# creates Min80_Max120daysAfterImg_Max30Bp_pairs.txt
Select_xDays_MaxBp_Pairs.py ${DIRSET}/set1/allPairsListing.txt +MinDays=170 +MaxDays=200 +MaxBp=30 	# creates Min170_Max200daysAfterImg_Max30Bp_pairs.txt
Select_xDays_MaxBp_Pairs.py ${DIRSET}/set1/allPairsListing.txt +MinDays=355 +MaxDays=385 +MaxBp=30 	# creates Min355_Max385daysAfterImg_Max30Bp_pairs.txt

Merge_PairFiles.sh ${DIRSET}/set1/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt ${DIRSET}/set1/Min80_Max120daysAfterImg_Max30Bp_pairs.txt ${DIRSET}/set1/Min170_Max200daysAfterImg_Max30Bp_pairs.txt ${DIRSET}/set1/Min355_Max385daysAfterImg_Max30Bp_pairs.txt 	# creates allPairsListing_Min80_Max120daysAfterImg_Max30Bp_pairs_Min170_Max200daysAfterImg_Max30Bp_pairs_Min355_Max385daysAfterImg_Max30Bp_pairs.txt
mv table_max_3_ForPlot_Without_Quanrantained_Data_Min80_Max120daysAfterImg_Max30Bp_pairs_Min170_Max200daysAfterImg_Max30Bp_pairs_Min355_Max385daysAfterImg_Max30Bp_pairs.txt   table_0_0_MaxShortest_3_Without_Quanrantained_3_6_12_months_Plus20Minus10days_Max30m.txt

Merge_PairFiles.sh ${DIRSET}/set1/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt ${DIRSET}/set1/Min80_Max120daysAfterImg_Max30Bp_pairs.txt
mv table_max_3_ForPlot_Without_Quanrantained_Data_Min80_Max120daysAfterImg_Max30Bp_pairs.txt table_0_0_MaxShortest_3_Without_Quanrantained_3_months_Plus20Minus10days_Max30m.txt

Merge_PairFiles.sh ${DIRSET}/set1/table_0_0_MaxShortest_2_Without_Quanrantained_Data.txt ${DIRSET}/set1/Min80_Max120daysAfterImg_Max30Bp_pairs.txt 
mv table_max_2_ForPlot_Without_Quanrantained_Data_Min80_Max120daysAfterImg_Max30Bp_pairs.txt table_0_0_MaxShortest_2_Without_Quanrantained_3_months_Plus20Minus10days_Max30m.txt


cd ${DIRSET}/set2
##################
Select_xDays_MaxBp_Pairs.py ${DIRSET}/set2/allPairsListing.txt  +MinDays=80 +MaxDays=120 +MaxBp=30 		# Min80_Max120daysAfterImg_Max30Bp_pairs.txt
Select_xDays_MaxBp_Pairs.py ${DIRSET}/set2/allPairsListing.txt  +MinDays=170 +MaxDays=200 +MaxBp=30 	# Min170_Max200daysAfterImg_Max30Bp_pairs.txt
Select_xDays_MaxBp_Pairs.py ${DIRSET}/set2/allPairsListing.txt  +MinDays=355 +MaxDays=385 +MaxBp=30 	# Min355_Max385daysAfterImg_Max30Bp_pairs.txt

Merge_PairFiles.sh ${DIRSET}/set2/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt ${DIRSET}/set2/Min80_Max120daysAfterImg_Max30Bp_pairs.txt ${DIRSET}/set2/Min170_Max200daysAfterImg_Max30Bp_pairs.txt ${DIRSET}/set2/Min355_Max385daysAfterImg_Max30Bp_pairs.txt 	# creates allPairsListing_Min80_Max120daysAfterImg_Max30Bp_pairs_Min170_Max200daysAfterImg_Max30Bp_pairs_Min355_Max385daysAfterImg_Max30Bp_pairs.txt
mv table_max_3_ForPlot_Without_Quanrantained_Data_Min80_Max120daysAfterImg_Max30Bp_pairs_Min170_Max200daysAfterImg_Max30Bp_pairs_Min355_Max385daysAfterImg_Max30Bp_pairs.txt   table_0_0_MaxShortest_3_Without_Quanrantained_3_6_12_months_Plus20Minus10days_Max30m.txt

Merge_PairFiles.sh ${DIRSET}/set2/table_0_0_MaxShortest_3_Without_Quanrantained_Data.txt ${DIRSET}/set2/Min80_Max120daysAfterImg_Max30Bp_pairs.txt
mv table_max_3_ForPlot_Without_Quanrantained_Data_Min80_Max120daysAfterImg_Max30Bp_pairs.txt table_0_0_MaxShortest_3_Without_Quanrantained_3_months_Plus20Minus10days_Max30m.txt

Merge_PairFiles.sh ${DIRSET}/set2/table_0_0_MaxShortest_2_Without_Quanrantained_Data.txt ${DIRSET}/set2/Min80_Max120daysAfterImg_Max30Bp_pairs.txt 
mv table_max_2_ForPlot_Without_Quanrantained_Data_Min80_Max120daysAfterImg_Max30Bp_pairs.txt table_0_0_MaxShortest_2_Without_Quanrantained_3_months_Plus20Minus10days_Max30m.txt


echo "Ending $0" >> $PATH_3610/SAR_CSL/S1/MUSTANG/Last_Run_Cron_Step1.txt
date >> $PATH_3610/SAR_CSL/S1/MUSTANG/Last_Run_Cron_Step1.txt
