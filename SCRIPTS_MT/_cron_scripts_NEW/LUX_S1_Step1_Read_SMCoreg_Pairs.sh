#!/bin/bash
# Script to run in cronjob for processing Lux images:
# Read images, check if nr of bursts and corners coordinates are OK, 
# corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 
#
# NOTE:	This script requires several adjustments in script body if transferred to another target. 
#		See all infos about Tracks and Sets
#
# New in Distro V 2.0.0 20201104 :	- move most of the parameters at the beginning
# New in Distro V 2.1.0 20201104 :	- check S1 nr of bursts and corner coordinates
# New in Distro V 2.0.0 20220602 :	- use new Prepa_MSBAS.sh compatible with D Derauw and L. Libert tools for Baseline Ploting
# New in Distro V 2.0.1 20220726 :	- store SAR_CSL data from LUX in 3602 instead of 1650
# New in Distro V 3.0.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 3.1.0 20230104 :	- New processing with high resolution DEM from ACT 
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.1 20231116:	- was endlessly adding modes in  ModeList.txt
# New in Distro V 5.2 20240702:	- enlarge Bp2 from 30 to 70m to account for orbital drift
# New in Distro V 5.3 20240826:	- read S1 images with option EXACTKML (that is read only brusts exactly overlapping the kml rather than the circumscribed rectangle)
#								- adapt number of bursts in _Check_ALL_S1_SizeAndCoord_InDir.sh for desc (8 => 6)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=20
BP2=70
BT=400
DATECHG=20220501

# Global Primaries (SuperMasters)
SMASC1=20170330		# Asc 15
SMASC2=20190406		# Asc 88
SMASC3=20211009		# Asc 161
SMASC4=		# Asc 117

SMDESC1=20210919		# Desc 37
SMDESC2=		# Desc 66
SMDESC3=20210920		# Desc 139

# DO NOT FORGET TO ADJUST ALSO THE SET BELOWS IN SCRIPT

# some files and PATH
#####################
#SAR_DATA
DIRSARDATA=$PATH_3600/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC.UNZIP
#DIRSARDATA=${PATH_DataSAR}/SAR_DATA_RAW/S1-DATA-LUXEMBOURG-SLC.UNZIP

#SAR_CSL
DIRSARCSL=$PATH_1660/SAR_CSL/S1/LUX
#SETi DIR
DIRSET=$PATH_1660/SAR_SM/MSBAS/LUX
# Dir to clean clean when orbits are updated
RESAMDIR=${PATH_3610}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_3610}/SAR_MASSPROCESS/

#kml file
KMLFILE=$PATH_1660/SAR_CSL/S1/LUX/LUX.kml		# also in $PATH_1650/kml/Luxembourg/LUX.kml

#Launch param files
#PARAMCOREGASC1=$PATH_1650/Param_files/S1/LUX_A_15/LaunchMTparam_S1_LUX_A_15_Zoom1_ML4_Coreg.txt 
PARAMCOREGASC2=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/S1/LUX_A_88/LaunchMTparam_S1_LUX_A_88_Zoom1_ML2_Coreg_0keep.txt 
#PARAMCOREGASC3=$PATH_1650/Param_files/S1/LUX_A_161/LaunchMTparam_S1_LUX_A_161_Zoom1_ML4_Coreg.txt
#PARAMCOREGASC4=$PATH_1650/Param_files/S1/LUX_A_161/LaunchMTparam_S1_LUX_A_117_Zoom1_ML4_Coreg.txt

#PARAMCOREGDESC1=$PATH_1650/Param_files/S1/LUX_D_37/LaunchMTparam_S1_LUX_D_37_Zoom1_ML4_Coreg.txt
#PARAMCOREGDESC2=$PATH_1650/Param_files/S1/LUX_D_66/LaunchMTparam_S1_LUX_D_66_Zoom1_ML4_Coreg.txt
PARAMCOREGDESC3=$PATH_DataSAR/SAR_AUX_FILES/Param_files/S1/LUX_D_139/LaunchMTparam_S1_LUX_D_139_Zoom1_ML2_Coreg_0keep.txt

NEWASCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/LUX_A_88/SMNoCrop_SM_${SMASC2}
NEWDESCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/LUX_D_139/SMNoCrop_SM_${SMDESC3}

#Color table 
#COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AAADDD.txt	# for 6 data sets
COLORTABLE=$PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt	# for 2 data sets

# Prepare stuffs
################
echo "Starting $0" > ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt

# Let's go
##########

# Read all S1 images for that footprint
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATA} ${DIRSARCSL}/NoCrop S1 ${KMLFILE} VV ${RESAMDIR} ${MASSPRODIR} EXACTKML > /dev/null 2>&1

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
## Asc 15 ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/LUX_A_15/NoCrop/S1B_15_20211011_A.csl Dummy
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_15/NoCrop 9 6.8222 48.8229 8.1231 48.9859 6.3521 50.3266 7.6950 50.4909
# Asc 88 ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/LUX_A_88/NoCrop/S1B_88_20210922_A.csl Dummy
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_88/NoCrop 28 4.8726 48.4861 8.3603 48.8898 4.3200 50.2640 7.9401 50.6697
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_88/NoCrop 10 4.70446273700816 49.0788177915767 7.12862594729126 49.368386825688 4.38204320436821 50.1109910414064 6.85962472242134 50.4018919198386
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_88/NoCrop 10 4.75844271845368 49.0964585824163 7.17101430868228 49.3834870875418 4.44395173179865 50.1071888052774 6.90856076691226 50.3954714728951
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_88/NoCrop 10 4.68647026969931 49.0882499763205 7.17289590146241 49.3848178725383 4.37052227617887 50.0986426096923 6.91057932731756 50.3965344410772

_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_88/NoCrop 10 5.72 6.55 49.43 50.19 &

## Asc 161; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/LUX_A_161//NoCrop/S1B_161_20211114_A.csl Dummy
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_161/NoCrop 9 5.1415 48.8124 6.2892 48.9329 4.7493 50.3204 5.9337 50.4407
## Asc 117; bursts size and coordinates are obtained by running e.g.: 
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_A_117/NoCrop ...

## Desc D_37; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/LUX_D_37/NoCrop/S1B_37_20211106_D.csl Dummy
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_37/NoCrop 18  7.3254 50.2898 4.7552 50.5903 6.8375 48.7272 4.3505 49.0257
## Desc D_66; bursts size and coordinates are obtained by running e.g.: _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/LUX_D_66/NoCrop/S1B_66_20211120_D.csl Dummy
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_66/NoCrop 5 8.7356 49.6224 7.5958 49.7399 8.5171 48.7748 7.3971 48.8924
## Beware D_66 are using 5 or 6 burst. The extra burst might be useless (not used anyway for routine processing). Nevertheless, check on range from 5 bursts then check the images in __TMP_QUARANTINE with 6 bursts coordinates. 
##        If OK, put them back in NoCrop dir. If not, keep them in original __TMP_QUARANTINE
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_66/NoCrop/__TMP_QUARANTINE 6 8.7924 49.7862 7.6075 49.9079 8.5304 48.7728 7.3702 48.8946
#	mv ${DIRSARCSL}_D_66/NoCrop/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_D_66/NoCrop/ 2>/dev/null
#	mv ${DIRSARCSL}_D_66/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl ${DIRSARCSL}_D_66/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
#	mv ${DIRSARCSL}_D_66/NoCrop/__TMP_QUARANTINE/*.txt ${DIRSARCSL}_D_66/NoCrop/ 2>/dev/null
#	rm -R ${DIRSARCSL}_D_66/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null

# Desc D_139; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/LUX_D_139/NoCrop/S1B_139_20211125_D.csl Dummy
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_139/NoCrop 20 8.1682 50.3200 5.7136 50.5824 7.6730 48.5892 5.3056 48.8511
#_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_139/NoCrop 8 8.05952022974312 50.1140417107835 5.67621889800598 50.3695244533346 7.76284975217017 49.0768838536486 5.4308805370781 49.332036809238
_Check_ALL_S1_SizeAndCoord_InDir.sh ${DIRSARCSL}_D_139/NoCrop 6 5.72 6.55 49.43 50.19 &

wait

# Coregister all images on the super master 
# in Ascending mode 
#$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC1} &	# Asc 15 - partial
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC2} &	# Asc 88 - Full cover 
#$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC3} &	# Asc 161 - partial 
#$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC4} &	# Asc 117 - partial

# in Descending mode 
#$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC1} &	# Desc 37 - partial 
#$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC2} &	# Desc 37 - partial
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC3} &	# Desc 139 - Full cover 

# Search for pairs
##################
# Link all images to corresponding set dir
#$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_15/NoCrop ${DIRSET}/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_88/NoCrop ${DIRSET}/set2 S1 > /dev/null 2>&1  &
#$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_161/NoCrop ${DIRSET}/set3 S1 > /dev/null 2>&1  &
#$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_37/NoCrop ${DIRSET}/set4 S1 > /dev/null 2>&1  &
#$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_66/NoCrop ${DIRSET}/set5 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_D_139/NoCrop ${DIRSET}/set6 S1 > /dev/null 2>&1  &
#$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_A_117/NoCrop ${DIRSET}/set7 S1 > /dev/null 2>&1  &

wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	#echo "n" | Prepa_MSBAS.sh ${DIRSET}/set1 ${BP} ${BT} ${SMASC1} > /dev/null 2>&1  &
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set2 ${BP} ${BT} ${SMASC2} ${BP2} ${BT} ${DATECHG}  > /dev/null 2>&1  &
	#echo "n" | Prepa_MSBAS.sh ${DIRSET}/set3 ${BP} ${BT} ${SMASC3} > /dev/null 2>&1  &
	#echo "n" | Prepa_MSBAS.sh ${DIRSET}/set7 ${BP} ${BT} ${SMASC4} > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	#echo "n" | Prepa_MSBAS.sh ${DIRSET}/set4 ${BP} ${BT} ${SMDESC1} > /dev/null 2>&1  &
	#echo "n" | Prepa_MSBAS.sh ${DIRSET}/set5 ${BP} ${BT} ${SMDESC2} > /dev/null 2>&1  &
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set6 ${BP} ${BT} ${SMDESC3} ${BP2} ${BT} ${DATECHG} > /dev/null 2>&1  &
fi
wait

# Plot baseline plot with all modes 
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 

	if [ `baselinePlot | wc -l` -eq 0 ] 
		then
			# use AMSTer Engine before May 2022
			mkdir -p ${DIRSET}/BaselinePlots_S1_set_1to6
			cd ${DIRSET}/BaselinePlots_S1_set_1to6

			#echo "${DIRSET}/set1" > ModeList.txt
			echo "${DIRSET}/set2" > ModeList.txt
			#echo "${DIRSET}/set3" >> ModeList.txt
			#echo "${DIRSET}/set4" >> ModeList.txt
			#echo "${DIRSET}/set5" >> ModeList.txt
			echo "${DIRSET}/set6" >> ModeList.txt
			#echo "${DIRSET}/set7" >> ModeList.txt

			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 ${BT} ${COLORTABLE}
		else
			# use AMSTer Engine > May 2022
			mkdir -p ${DIRSET}/BaselinePlots_set1_to_set6
			cd ${DIRSET}/BaselinePlots_set1_to_set6
 
			#echo "${DIRSET}/set1" > ModeList.txt
			echo "${DIRSET}/set2" > ModeList.txt
			#echo "${DIRSET}/set3" >> ModeList.txt
			#echo "${DIRSET}/set4" >> ModeList.txt
			#echo "${DIRSET}/set5" >> ModeList.txt
			echo "${DIRSET}/set6" >> ModeList.txt
 			#echo "${DIRSET}/set7" >> ModeList.txt
			
			#plot_Multi_BaselinePlot.sh ${DIRSET}/BaselinePlots_set1_to_set6/ModeList.txt	
			plot_Multi_BaselinePlot.sh ${DIRSET}/BaselinePlots_set2_set6/ModeList.txt
			
	fi	
fi

echo "Ending $0" >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt




