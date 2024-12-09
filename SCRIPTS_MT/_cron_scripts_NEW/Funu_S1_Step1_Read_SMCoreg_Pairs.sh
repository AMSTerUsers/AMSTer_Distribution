#!/bin/bash
# Script to run in cronjob for processing Funu images:
# Read images, check if nr of bursts and corners coordinates are OK, 
# corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 
#
# New in Distro V 2.0.0 20240903 : - do not compute Delaunay baseline plot because 
#										dealing here with a rapid landslide (hence must keep short Bt) 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


source $HOME/.bashrc

# Some variables
#################

# If want max Bp and Bt
BP=50
BT=30

# If wants Delaunay Table
DELAUNAY=YES
RATIO1=30
RATIO2=30

# If wants Shortest connections Table
SHORTESTS=YES
NR1=3	# How amny shortest connections for mode 1
NR2=3	# How amny shortest connections for mode 2


SMASC=20160608
SMDESC=20160517

POL=VV

# If wants Delaunay Table
DELAUNAY=NO
RATIO1=30
RATIO2=30

# If wants Shortest connections Table
SHORTESTS=YES
NR1=3	# How amny shortest connections for mode 1
NR2=3	# How amny shortest connections for mode 2

# some files and PATH
#####################
# SAR_DATA - RAW data
PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP

# Path to SAR_CSL data
PATHCSL=$PATH_1660/SAR_CSL/S1

# Path to RESAMPLED data
NEWASCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_Funu_A_174/SMNoCrop_SM_${SMASC}
NEWDESCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_Funu_D_21/SMNoCrop_SM_${SMDESC}

# Path to Seti
PATHSETI=$PATH_1660/SAR_SM/MSBAS
#SETi DIR
DIRSET=$PATHSETI/Funu

# Dir to clean clean when orbits are updated
RESAMDIR=${PATH_3610}/SAR_SM/RESAMPLED/
MASSPRODIR=${PATH_1660}/SAR_MASSPROCESS/

#kml file
KMLFILE=$PATH_1650/kml/VVP/Funu_2.kml		

#Launch param files
PARAMASC=$PATH_1650/Param_files/S1/DRC_Funu_A_174/LaunchMTparam_S1_Funu_Asc_Zoom1_ML2_snaphu_square_Coreg.txt
PARAMDESC=$PATH_1650/Param_files/S1/DRC_Funu_D_21/LaunchMTparam_S1_Funu_Desc_Zoom1_ML2_snaphu_square_Coreg.txt

# Read all S1 images for that footprint
#######################################
 $PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${PATHRAW} ${PATHCSL}/DRC_Funu/NoCrop S1 ${KMLFILE} ${POL} ${RESAMDIR} ${MASSPRODIR}  > /dev/null 2>&1

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
# Asc ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/DRC_VVP_A_174/NoCrop/S1B_174_20210928_A.csl Dummy
_Check_ALL_S1_SizeAndCoord_InDir.sh ${PATHCSL}/DRC_Funu_A_174/NoCrop 1 28.7996222390135 -2.64593707861363 29.5627593105704 -2.47967094443114 28.7603501591374 -2.46099386253002 29.5233244545248 -2.29491509744918 

# Desc ; bursts size and coordinates are obtained by running e.g.: _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/DRC_VVP_D_21/NoCrop/S1B_21_20211105_D.csl Dummy
_Check_ALL_S1_SizeAndCoord_InDir.sh ${PATHCSL}/DRC_Funu_D_21/NoCrop 2 29.4174619000493 -2.46124820603928 28.6149426515749 -2.28596311670678 29.342033718734 -2.81423443279396 28.539252039859 -2.63851875402176
	
# Coregister all images on the super master 
###########################################
# in Ascending mode 
 $PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMASC} &
# in Descending mode 
 $PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMDESC} &



# Search for pairs
##################
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${PATHCSL}/DRC_Funu_A_174/NoCrop ${PATHSETI}/Funu/set1 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${PATHCSL}/DRC_Funu_D_21/NoCrop ${PATHSETI}/Funu/set2 S1 > /dev/null 2>&1 &
wait

# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${PATHSETI}/Funu/set1 ${BP} ${BT} ${SMASC} > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${PATHSETI}/Funu/set2 ${BP} ${BT} ${SMDESC} > /dev/null 2>&1  &
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

	
# Plot baseline plot with both modes 
#if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
#
#	if [ `baselinePlot | wc -l` -eq 0 ] 
#		then
#			# use AMSTer Engine before May 2022	
#			mkdir -p ${PATHSETI}/VVP/BaselinePlots_set6_set7
#			cd ${PATHSETI}/VVP/BaselinePlots_set6_set7
#
#			echo "${PATHSETI}/VVP/set6" > ModeList.txt
#			echo "${PATHSETI}/VVP/set7" >> ModeList.txt
#
#			#plot_Multi_BaselinePlot.sh ${PATHSETI}/VVP/BaselinePlots_set6_set7/ModeList.txt
# 			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 {BT}   $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt
#
#		else
#			# use AMSTer Engine > May 2022
#			mkdir -p ${PATHSETI}/VVP/BaselinePlots_set6_set7
#			cd ${PATHSETI}/VVP/BaselinePlots_set6_set7
# 
#			echo "${PATHSETI}/VVP/set6" > ModeList.txt
#			echo "${PATHSETI}/VVP/set7" >> ModeList.txt
# 
#			plot_Multi_BaselinePlot.sh ${PATHSETI}/VVP/BaselinePlots_set6_set7/ModeList.txt
# 	fi
#
#fi

