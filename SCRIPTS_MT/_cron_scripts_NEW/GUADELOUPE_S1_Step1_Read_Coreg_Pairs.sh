#!/bin/bash
# Script to run in cronjob for processing GUADELOUPE island images:
# Read images, corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 

# New in Distro V 2.0.0 20220602 :	- use new Prepa_MSBAS.sh compatible with D Derauw and L. Libert tools for Baseline Ploting
# New in Distro V 3.0.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 3.1.0 20230626 :	- Color tables are now in TemplatesForPlots
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.1 20240415:	- increase Bp to 90m
# New in Distro V 5.2 20240826:	- read S1 images with option EXACTKML (that is read only brusts exactly overlapping the kml rather than the circumscribed rectangle)
#								- set variables at the beginning for more clarity
# New in Distro V 5.2 20240829:	- Add double bursts testing to cope with Desc 20190703, 0715 and 0727
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

echo "Starting $0" > $PATH_1650/SAR_CSL/S1/GUADELOUPE/Last_Run_Cron_Step1.txt
date >> $PATH_1650/SAR_CSL/S1/GUADELOUPE/Last_Run_Cron_Step1.txt

# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=50
BT=150

BP2=90 
DATECHG=20240201

# Global Primaries (SuperMasters)
SMASC1=20190622		# Asc 164
SMDESC1=20200410		# Desc 54

NEWASCPATH=$PATH_1650/SAR_SM/RESAMPLED/S1/GUADELOUPE_A_164/SMCrop_SM_
NEWDESCPATH=$PATH_1650/SAR_SM/RESAMPLED/S1/GUADELOUPE_D_54/SMCrop_SM_

# some files and PATH
#####################
#SAR_DATA
DIRSARDATA=$PATH_3600/SAR_DATA/S1/S1-DATA-GUADELOUPE-SLC.UNZIP

#SAR_CSL
DIRSARCSL=$PATH_1650/SAR_CSL/S1/GUADELOUPE		# do not put tailing / in name here

#SETi DIR
DIRSET=$PATH_1650/SAR_SM/MSBAS/GUADELOUPE

# Dir to clean clean when orbits are updated
RESAMDIR=$PATH_1650/SAR_SM/RESAMPLED/
MASSPRODIR=$PATH_3601/SAR_MASSPROCESS/

#kml file
#KMLFILE=${PATH_1650}/kml/Guadeloupe/Guadeloupe_Asc_Download.kml
KMLFILE=$PATH_1650/kml/Guadeloupe/Guadeloupe_Contour.kml			# also in /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/GUADELOUPE

#Launch param files
PARAMCOREGASC=$PATH_1650/Param_files/S1/GUADELOUPE_A_164/LaunchMTparam_S1_IW_Guadeloupe_A_Zoom1_ML2_Coreg.txt 
PARAMCOREGDESC=$PATH_1650/Param_files/S1/GUADELOUPE_D_54/LaunchMTparam_S1_IW_Guadeloupe_D_Zoom1_ML2_Coreg.txt 


# Read all S1 images for that footprint
#######################################
#$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh $PATH_3600/SAR_DATA/S1/S1-DATA-GUADELOUPE-SLC.UNZIP $PATH_1650/SAR_CSL/S1/GUADELOUPE/NoCrop S1 ${PATH_1650}/kml/Guadeloupe/Guadeloupe.kml  VV ${PATH_1650}/SAR_SM/RESAMPLED/ ${PATH_3601}/SAR_MASSPROCESS/  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATA} ${DIRSARCSL}/NoCrop S1 ${KMLFILE} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
## Asc 164 ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/Region_Mode/NoCrop/S1A_an_image_A.csl Dummy
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_164/NoCrop 5 -61.82 -61.16 15.83 16.517 &

## Desc D_54; 
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_54/NoCrop 9 -61.82 -61.16 15.83 16.517 &
wait
## Beware D_54 are (rarely) using 8 bursts instead of 9 when the southern one is not needed. 
##  The extra burst should be useless, hence check on range from 8 bursts in __TMP_QUARANTINE. 
##        If OK, put them back in NoCrop dir. If not, keep them in original __TMP_QUARANTINE
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_54/NoCrop/__TMP_QUARANTINE 8 -61.82 -61.16 15.83 16.517
	mv ${DIRSARCSL}_D_54/NoCrop/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_D_54/NoCrop/ 2>/dev/null
	mv ${DIRSARCSL}_D_54/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_D_54/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
	mv ${DIRSARCSL}_D_54/NoCrop/__TMP_QUARANTINE/*.txt ${DIRSARCSL}_D_54/NoCrop/ 2>/dev/null
	rm -R ${DIRSARCSL}_D_54/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null



# Coregister all images on the super master 
###########################################
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC} &
# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC} &

# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_164/NoCrop ${DIRSET}/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_54/NoCrop ${DIRSET}/set2 S1 > /dev/null 2>&1  &
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

## Plot baseline plot with both modes 
#if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
#
#	if [ `baselinePlot | wc -l` -eq 0 ] 
#		then
#			# use AMSTer Engine before May 2022
#			mkdir -p $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_S1_set_1_2
#			cd $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_S1_set_1_2
#
#			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set1" > ModeList.txt
#			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set2" >> ModeList.txt
#
#			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 {BT}   $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt
#		else
#			# use AMSTer Engine > May 2022
#			mkdir -p $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2
#			cd $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2
# 
#			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set1" > ModeList.txt
#			echo "$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set2" >> ModeList.txt
# 
#			plot_Multi_BaselinePlot.sh $PATH_1650/SAR_SM/MSBAS/GUADELOUPE/BaselinePlots_set1_set2/ModeList.txt
# 	fi
#
#fi

echo "Ending $0" >> $PATH_1650/SAR_CSL/S1/GUADELOUPE/Last_Run_Cron_Step1.txt
date >> $PATH_1650/SAR_CSL/S1/GUADELOUPE/Last_Run_Cron_Step1.txt
