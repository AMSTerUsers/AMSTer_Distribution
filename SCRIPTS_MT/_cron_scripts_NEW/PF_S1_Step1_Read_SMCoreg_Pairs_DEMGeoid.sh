#!/bin/bash
# Script to run in cronjob for processing PITON DE LA FOURNAISE images:
# Read images, check if nr of bursts and corners coordinates are OK (for IW), 
# corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 

# New in Distro V 2.0.0 20220602 :	- use new Prepa_MSBAS.sh compatible with D Derauw and L. Libert tools for Baseline Ploting
# New in Distro V 3.0.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 3.1.0 20230316 :	- Set double criteria 
#									- remove S1B and multiple baseline plot since only one is available
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.1 20230901:	- Check size of image based on min max lat long instead of coorners coordinates
#								- check D151 fior 8 bursts firsts (hence it should not need to check for 9 bursts)
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.1 20240617:	- Reprocessed with DEM corrected from Geoid height
# New in Distro V 5.2 20240902:	- change kml, force to EXACTKML and verification of bursts nr to cope with AMSTer Engine V Aug 2024
# 								- set path and variables at beginning 
# New in Distro V 5.2 20240916:	- was missing definition of DIRSET
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

mkdir -p $PATH_1660/SAR_CSL/S1/PF_IW
mkdir -p ${PATH_1660}/SAR_SM/RESAMPLED/S1

echo "Starting $0" > $PATH_1660/SAR_CSL/S1/PF_IW/Last_Run_Cron_Step1.txt
date >> $PATH_1660/SAR_CSL/S1/PF_IW/Last_Run_Cron_Step1.txt

# IW mode

BP=70
BT=70

BP2=90
BT2=70
DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC1=20180831			# Asc 144
SMDESC1=20200622		# Desc 151


#####NEWASCPATH=$PATH_1660/SAR_SM/RESAMPLED/S1/PF_IW_A_144/SMNoCrop_SM_20180831
NEWDESCPATH=$PATH_1660/SAR_SM/RESAMPLED/S1/PF_IW_D_151/SMNoCrop_SM_20200622

# some files and PATH
#####################
#SAR_DATA
DIRSARDATA=$PATH_3601/SAR_DATA_Other_Zones/S1/S1-DATA-REUNION-SLC.UNZIP

#SAR_CSL
DIRSARCSL=$PATH_1660/SAR_CSL/S1/PF_IW		# do not put tailing / in name here

# Seti
DIRSET=$PATH_1650/SAR_SM/MSBAS/PF

#kml file
#KMLFILE=${PATH_1650}/kml/Reunion/Reunion_Island.kml			
KMLFILE=${PATH_1650}/kml/Reunion/Reunion_Island_contour.kml			# also in /Volumes/hp1660/SAR_CSL/S1/PF_IW

# Dir to clean clean when orbits are updated
RESAMDIR=${PATH_1660}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_3610}/SAR_MASSPROCESS/

#Launch param files
PARAMCOREGASC=$PATH_1650/Param_files/S1/PF_IW_A_144/LaunchMTparam_S1_IW_Reunion_Asc_Zoom1_ML2_Coreg_DEMGeoid.txt
PARAMCOREGDESC=$PATH_1650/Param_files/S1/PF_IW_D_151/LaunchMTparam_S1_IW_Reunion_Desc_Zoom1_ML2_Coreg_DEMGeoid.txt


# Read all S1 images for that footprint
#######################################
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATA} ${DIRSARCSL}/NoCrop S1 ${KMLFILE} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
# Asc ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/PF_IW_A_144/NoCrop/S1A_144_20211225_A.csl Dummy
#####_Check_ALL_S1_SizeAndCoord_InDir.sh $PATH_1650/SAR_CSL/S1/PF_IW_A_144/NoCrop 10 54.6377 -21.8412 56.2373 -21.4598 54.3887 -20.8858 55.9777 -20.50789

# Desc ; bursts size and coordinates are obtained by running e.g.: _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/PF_IW_D_151/NoCrop/S1A_151_20211214_D.csl Dummy
# Beware D151 needs 5 burst, though one is useless (ocean to the East). However, this useless burst is hard to avoid because of overlap with needed burst. 
# Since most of teh time the 5th useless burst is there, we test with 5 bursts. If only 4 are present in the range of coordinates, the image is 
# moved to __TMP_QUARANTINE, then  checked from there with 4 bursts. 
#        If OK, put them back in NoCrop dir. If not, keep them in original __TMP_QUARANTINE
#_Check_ALL_S1_SizeAndCoord_InDir.sh $PATH_1650/SAR_CSL/S1/PF_IW_D_151/NoCrop 9 56.7687 -20.9831 55.1337 -20.6023 56.5533 -21.8321 54.9081 -21.4484
_Check_ALL_S1_SizeAndCoord_InDir.sh $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop 5 55.20 55.85 -21.40 -20.86

_Check_ALL_S1_SizeAndCoord_InDir.sh $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop/__TMP_QUARANTINE 4 55.20 55.85 -21.40 -20.86
	mv $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop/__TMP_QUARANTINE/*.csl $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop/ 2>/dev/null
	mv $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
	mv $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop/__TMP_QUARANTINE/*.txt $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop/ 2>/dev/null
	rm -R $PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null

# Coregister all images on the super master 
###########################################
# in Ascending mode 
#####$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC} &
# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC} &

# Search for pairs
##################
# Link all images to corresponding set dir
#$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh  ${DIRSARCSL}_A_144/NoCrop ${DIRSET}/set3 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_151/NoCrop ${DIRSET}/set4 S1 > /dev/null 2>&1 &
wait

# Compute pairs 
# Compute pairs only if new data is identified
#####if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
#####	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set3 ${BP} ${BT} ${SMASC1} > /dev/null 2>&1  &
#####fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set4 ${BP} ${BT} ${SMDESC1} ${BP2} ${BT2} ${DATECHG} > /dev/null 2>&1  &
fi
wait

# Plot baseline plot with both modes 
#####if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
#####
#####	if [ `baselinePlot | wc -l` -eq 0 ] 
#####		then
#####			# use AMSTer Engine before May 2022
#####			mkdir -p $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_S1_set_3_4
#####			cd $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_S1_set_3_4
#####
#####			echo "$PATH_1650/SAR_SM/MSBAS/PF/set3" > ModeList.txt
#####			echo "/$PATH_1650/SAR_SM/MSBAS/PF/set4" >> ModeList.txt
#####
#####			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 ${BT}   $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt
#####		else
#####			# use AMSTer Engine > May 2022
#####			mkdir -p $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_set3_set4
#####			cd $PATH_1650/SAR_SM/MSBAS/PF/BaselinePlots_set3_set4
##### 
#####			echo "$PATH_1650/SAR_SM/MSBAS/PF/set3" > ModeList.txt
#####			echo "/$PATH_1650/SAR_SM/MSBAS/PF/set4" >> ModeList.txt
##### 
#####			plot_Multi_BaselinePlot.sh $PATH_1650/SAR_SM/MSBAS/VPFVP/BaselinePlots_set3_set4/ModeList.txt
##### 	fi
#####fi

echo "Ending $0" >> $PATH_1660/SAR_CSL/S1/PF_IW/Last_Run_Cron_Step1.txt
date >> $PATH_1660/SAR_CSL/S1/PF_IW/Last_Run_Cron_Step1.txt
