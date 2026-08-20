#!/bin/bash
# Script to run in cronjob for processing Central Nepal NISAR images:
# Read images (will sort all type of possible acq mode incl Rg bandwidth), 
# corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
#
# NOTE:	This script requires several adjustments in script body if transferred to another target. 
#		See all infos about Tracks and Sets
#
# New in Distro V 2.0.0 20260316 :	- 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

# Some variables 
################
# Max  baseline (for buliding msbas files)
BP=100
BT=150


# Global Primaries (SuperMasters)
SMASC1=20251128			# Asc98 FreqA LL Frame16 40Mhz 41deg
SMDESC1=20260112		# Desc48 FreqA LL Frame74 20Mhz 41deg
SMDESC2=20251207		# Desc48 FreqA LL Frame74 40Mhz 41deg 

# DO NOT FORGET TO ADJUST ALSO THE SET BELOWS IN SCRIPT

# Nr of shortests connections for Baseline plot
SHORTESTS="YES"
NR=3

# some files and PATH
#####################
#SAR_DATA
PATHDIRSARDATA=$PATH_3612/SAR_DATA/NISAR

DIRSARDATAA98=${PATHDIRSARDATA}/NEPAL/Asc_98
DIRSARDATAD48=${PATHDIRSARDATA}/NEPAL/Desc_48

#SAR_CSL
DIRSARCSL=$PATH_3611/SAR_CSL/NISAR/NEPAL

#SETi DIR
DIRSET=$PATH_1660/SAR_SM/MSBAS/NEPAL

# Dir to clean clean when orbits are updated
RESAMDIR=${PATH_3611}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_3612}/SAR_MASSPROCESS/

#kml file for geocoding whole zone 
KMLFILE=$PATH_1650/kml/Nepal/CentralNepal.kml		

#Launch param files
PARAMCOREGASC1=$PATH_1650/Param_files/NISAR/NEPAL_FreqA_A98_LL_Frame16_40Mhz_41deg/LaunchMTparam_NISAR_A98_FreqA_Zoom1_ML4_Coreg.txt 

PARAMCOREGDESC1=$PATH_1650/Param_files/NISAR/NEPAL_FreqA_D48_LL_Frame74_20Mhz_41deg/LaunchMTparam_NISAR_D48_FreqA_Zoom1_ML4_Coreg.txt
PARAMCOREGDESC2=$PATH_1650/Param_files/NISAR/NEPAL_FreqA_D48_LL_Frame74_40Mhz_41deg/LaunchMTparam_NISAR_D48_FreqA_Zoom1_ML4_Coreg.txt	# Desc48 FreqA LL Frame74 40Mhz 41deg 
# resampled dir
NEWASCPATH1=$PATH_3611/SAR_SM/RESAMPLED/NISAR/NEPAL_FreqA_A98_LL_Frame16_40Mhz_41deg/SMNoCrop_SM_${SMASC1}

NEWDESCPATH1=$PATH_3611/SAR_SM/RESAMPLED/NISAR/NEPAL_FreqA_D48_LL_Frame74_20Mhz_41deg/SMNoCrop_SM_${SMDESC1}
NEWDESCPATH2=$PATH_3611/SAR_SM/RESAMPLED/NISAR/NEPAL_FreqA_D48_LL_Frame74_40Mhz_41deg/SMNoCrop_SM_${SMDESC2}	# Desc48 FreqA LL Frame74 40Mhz 41deg 


# Prepare stuffs
################
mkdir -p ${DIRSARCSL}
echo "Starting $0" > ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt

# Let's go
##########

# DO THIS AT REGULAR UPDATE RUN
###############################
# Do not run in bkgd because it may conflict while creating links for one mode during processing of the other mode
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAA98} ${DIRSARCSL}/NoCrop NISAR HH FreqA > /dev/null 2>&1 
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${DIRSARDATAD48} ${DIRSARCSL}/NoCrop NISAR HH FreqA > /dev/null 2>&1 


# Coregister all images on the super master 
# in Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGASC1} &	# Asc98 FreqA LL Frame16 40Mhz 41deg

# in Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC1} &	#  Desc48 FreqA LL Frame74 20Mhz 41deg 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMCOREGDESC2} &	 # Desc48 FreqA LL Frame74 40Mhz 41deg 


# Search for pairs
##################
# Link all images to corresponding set dir
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_FreqA_A98_LL_Frame16_40Mhz_41deg/NoCrop ${DIRSET}/set11 NISAR > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_FreqA_D48_LL_Frame74_20Mhz_41deg/NoCrop ${DIRSET}/set13 NISAR > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${DIRSARCSL}_FreqA_D48_LL_Frame74_40Mhz_41deg/NoCrop ${DIRSET}/set15 NISAR > /dev/null 2>&1  &		

wait

# Compute pairs 
# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH1}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set11 ${BP} ${BT} ${SMASC2}   > /dev/null 2>&1  &
fi

if [ ! -s ${NEWDESCPATH1}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set13 ${BP} ${BT} ${SMDESC1}   > /dev/null 2>&1  &
fi

if [ ! -s ${NEWDESCPATH2}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${DIRSET}/set15 ${BP} ${BT} ${SMDESC2}   > /dev/null 2>&1  &
fi


wait

if [ "${SHORTESTS}" == "YES" ] ; then 
	cd ${DIRSET}/set11 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set11/allPairsListing.txt ${NR}
	
	cd ${DIRSET}/set13 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set13/allPairsListing.txt ${NR}

	cd ${DIRSET}/set15 
	Extract_x_Shortest_Connections.sh ${DIRSET}/set15/allPairsListing.txt ${NR}
	
fi

echo "Ending $0" >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt
date >> ${DIRSARCSL}/Last_Run_Cron_Step1.txt




