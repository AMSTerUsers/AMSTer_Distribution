#!/bin/bash
# Script to run in cronjob for processing VVP images:
# Read images, check if nr of bursts and corners coordinates are OK, 
# corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 

# New in Distro V 2.0.0 20220517 :	-use new Prepa_MSBAS.sh based on DD tools instead of L. Libert tools
# New in Distro V 2.1.0 20220602 :	- use new Prepa_MSBAS.sh compatible with D Derauw and L. Libert tools for Baseline Ploting
# New in Distro V 3.0.0 20221215 :	- restart from scratch, using new Copernicus DEM (2014) referenced to Ellipsoid
#									- more path and variable in param at the beginning of the script
# New in Distro V 3.0.0 20230104 :	- Use Read_All_Img.sh V3 which requires 3 more parameters (POl + paths  to RESAMPLED and to SAR_MASSPROCESS) 
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_MT directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.1 20230904:	- review baseline plots with old tools 
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.1 20240701:	- enlarge orbital tube to 70m instead of 20 after 20220501
#								- (set correct list of co-eruptive pairs computed manually and set them in ...AdditionaPairs.txt)
# New in Distro V 5.2 20240819:	- correct bug in path to TMP_QUARANTINE Desc 21
#								- adapt new coord for _Check_ALL_S1_SizeAndCoord_InDir.sh since new S1DataReader (from Aug 2024)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


source $HOME/.bashrc

# Some variables
#################

BP=20
BT=400

BP2=70
BT2=400
DATECHG=20220501


SMASC=20150310
SMDESC=20151014

STARTEXCLU=20210522 	# Because Nyiragongo 2021 eruption created defo too large for classical unwrapping, co-eruptive pairs must have been unwrapped with recursive snaphu and put in mass processing results instead of the automated results.
STOPEXCLU=20210530		# For that reason, all pairs spanning the eruption, i.e. between [STARTEXCLU , STOPEXCLU] are excluded from the automatic procedure. They are replaced by pairs in table_0_20_0_400._AdditionalPairs.txt    

# Path to RAW data
PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP

# Path to SAR_CSL data
PATHCSL=$PATH_1660/SAR_CSL/S1

# Path to RESAMPLED data
NEWASCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310
NEWDESCPATH=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_VVP_D_21/SMNoCrop_SM_20151014

# Path to Seti
PATHSETI=$PATH_1660/SAR_SM/MSBAS

# Path to Tables
TABLE1=${PATHSETI}/VVP/set6/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt
TABLE2=${PATHSETI}/VVP/set7/table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt

# Path to additional pairs 
ADDITIONALTABLE1=${PATHSETI}/VVP/set6/table_0_${BP2}_0_${BT2}_AdditionalPairs.txt 		# This is a copy of table_0_70_0_400_AddPairsComputed_RecurrUnwp.txt wich contains the list of co-eruptive pairs recomputed manually with recursive unwrapping
ADDITIONALTABLE2=${PATHSETI}/VVP/set7/table_0_${BP2}_0_${BT2}_AdditionalPairs.txt 		# This is a copy of table_0_70_0_400_AddPairsComputed_RecurrUnwp.txt wich contains the list of co-eruptive pairs recomputed manually with recursive unwrapping

# Path to Table without pairs spanning exclusion period with and without 2 lines of header 
TABLEWITHOUTEXCLUNOHDR1=${TABLE1}_Without_${STARTEXCLU}_${STOPEXCLU}_NoHeader.txt  
TABLEWITHOUTEXCLUNOHDR2=${TABLE2}_Without_${STARTEXCLU}_${STOPEXCLU}_NoHeader.txt  

# Path to Table without pairs spanning exclusion period, though with additional pairs added, with and without 2 lines of header 
TABLEWITHOUTEXCLUWITHADDNOHDR1=${PATHSETI}/VVP/set6/Dummy_table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt_Without_${STARTEXCLU}_${STOPEXCLU}_WithAdditionalPairs.txt
TABLEWITHOUTEXCLUWITHADDNOHDR2=${PATHSETI}/VVP/set7/Dummy_table_0_${BP}_0_${BT}_Till_${DATECHG}_0_${BP2}_0_${BT2}_After.txt_Without_${STARTEXCLU}_${STOPEXCLU}_WithAdditionalPairs.txt


if [ `head -1 ${ADDITIONALTABLE1} | ${PATHGNU}/grep Master | wc -l` -gt 0 ] ; then 
	#remove header
	tail -n +3 ${ADDITIONALTABLE1} > ${ADDITIONALTABLE1}_NoHeader.txt
	ADDITIONALTABLE1=${ADDITIONALTABLE1}_NoHeader.txt
fi
if [ `head -1 ${ADDITIONALTABLE2} | ${PATHGNU}/grep Master | wc -l` -gt 0 ] ; then 
	#remove header
	tail -n +3 ${ADDITIONALTABLE2} > ${ADDITIONALTABLE2}_NoHeader.txt
	ADDITIONALTABLE2=${ADDITIONALTABLE2}_NoHeader.txt
fi

# Parameters files for Coregistration
PARAMASC=$PATH_DataSAR/SAR_AUX_FILES/Param_files/S1/DRC_VVP_A_174/LaunchMTparam_S1_VVP_Asc_Zoom1_ML4_snaphu_square_Coreg.txt
PARAMDESC=$PATH_DataSAR/SAR_AUX_FILES/Param_files/S1/DRC_VVP_D_21/LaunchMTparam_S1_VVP_Desc21_Zoom1_ML4_snaphu_square_Coreg.txt


# Read all S1 images for that footprint
#######################################
 $PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${PATHRAW} ${PATHCSL}/DRC_VVP/NoCrop S1 ${PATHCSL}/DRC_VVP/VVP.kml VV ${PATH_3610}/SAR_SM/RESAMPLED/ ${PATH_HOMEDATA}/SAR_MASSPROCESS/  > /dev/null 2>&1

# Check nr of bursts and coordinates of corners. If not as expected, move img in temp quatantine and log that. Check regularily: if not updated after few days, it means that image is bad or zip file not correctly downloaded
################################################
# Asc ; bursts size and coordinates are obtained by running e.g.:  _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/DRC_VVP_A_174/NoCrop/S1B_174_20210928_A.csl Dummy
_Check_ALL_S1_SizeAndCoord_InDir.sh ${PATHCSL}/DRC_VVP_A_174/NoCrop 16 28.7532 -2.4225 30.2811 -2.0896 28.4441 -0.9607 29.9705 -0.6309 

# Desc ; bursts size and coordinates are obtained by running e.g.: _Check_S1_SizeAndCoord.sh /Volumes/hp-1650-Data_Share1/SAR_CSL/S1/DRC_VVP_D_21/NoCrop/S1B_21_20211105_D.csl Dummy
# Beware D21 are using 17 or 18 burst. The 18th to the SW is however useless, hence check on range from 17 bursts then check the images in __TMP_QUARANTINE with 18 bursts coordinates. 
#        If OK, put them back in NoCrop dir. If not, keep them in original __TMP_QUARANTINE
_Check_ALL_S1_SizeAndCoord_InDir.sh ${PATHCSL}/DRC_VVP_D_21/NoCrop 17 30.4780 -1.0622 28.2704 -0.5847 30.1797 -2.4732 27.9701 -1.9911

_Check_ALL_S1_SizeAndCoord_InDir.sh ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE 18 30.4842 -1.0624  28.2689 -0.5833 30.1857 -2.4740 27.9684 -1.9903
	mv ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/*.csl ${PATHCSL}/DRC_VVP_D_21/NoCrop/ 2>/dev/null
	mv ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
	mv ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/*.txt ${PATHCSL}/DRC_VVP_D_21/NoCrop/ 2>/dev/null
	rm -R $PATH_1660/SAR_CSL/S1/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null

# Since new S1DataReader from Aug 2024, ie. with better search of burst overlap with kml (instead of larger rectangle),
# check against less bursts as well
_Check_ALL_S1_SizeAndCoord_InDir.sh ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE 11 30.4720 -1.121  28.922 -0.7859 30.2210 -2.3086 28.6698 -1.9709
	mv ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/*.csl ${PATHCSL}/DRC_VVP_D_21/NoCrop/ 2>/dev/null
	mv ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE/*.csl ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/ 2>/dev/null
	mv ${PATHCSL}/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/*.txt ${PATHCSL}/DRC_VVP_D_21/NoCrop/ 2>/dev/null
	rm -R $PATH_1660/SAR_CSL/S1/DRC_VVP_D_21/NoCrop/__TMP_QUARANTINE/__TMP_QUARANTINE 2>/dev/null



# Coregister all images on the super master 
###########################################
# in Ascending mode 
 $PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMASC} &
# in Descending mode 
 $PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMDESC} &



# Search for pairs
##################
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${PATHCSL}/DRC_VVP_A_174/NoCrop ${PATHSETI}/VVP/set6 S1 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${PATHCSL}/DRC_VVP_D_21/NoCrop ${PATHSETI}/VVP/set7 S1 > /dev/null 2>&1 &
wait

# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${PATHSETI}/VVP/set6 ${BP} ${BT} ${SMASC} ${BP2} ${BT2} ${DATECHG}> /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${PATHSETI}/VVP/set7 ${BP} ${BT} ${SMDESC} ${BP2} ${BT2} ${DATECHG} > /dev/null 2>&1  &
fi
wait

# Specific to Nyiragongo eruption: remove here all co-eruptive pairs, that is between [STARTEXCLU , STOPEXCLU]  
	cd ${PATHSETI}/VVP/set6/
	RemovePairsFromTableList_Outside_dates.sh ${TABLE1} ${STARTEXCLU} ${STOPEXCLU}			# replace TABLE1 with ...._After.txt
	cd ${PATHSETI}/VVP/set7/
	RemovePairsFromTableList_Outside_dates.sh ${TABLE2} ${STARTEXCLU} ${STOPEXCLU}
	
	# From RemovePairsFromTableList_Outside_dates.sh,  pairs to be excluded are now in 
	# 	${PATHSETI}/VVP/seti/table_0_${BP}_0_${BT}.txt_Between_${STARTEXCLU}_${STOPEXCLU}.txt, which contains a header and 4 columns 
	# 	_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt, which contains NO header and 1 col as MASDATE_SLVDATE
	# One must now remove from _EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt all the co-eruptive pairs computed manually that were manually stored in 
	#	${PATHSETI}/VVP/seti/table_0_${BP}_0_${BT}_AdditionalPairs.txt, which contains NO header and 4 columns
	
	# keep original just in case 
	cp -f ${PATHSETI}/VVP/set6/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt ${PATHSETI}/VVP/set6/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK_FULL.txt	# with header
	cp -f ${PATHSETI}/VVP/set7/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt ${PATHSETI}/VVP/set7/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK_FULL.txt	# with header
	cp -f ${ADDITIONALTABLE1} ${ADDITIONALTABLE1}.bak.txt
	cp -f ${ADDITIONALTABLE2} ${ADDITIONALTABLE2}.bak.txt
	
	# remove what is in _AdditionalPairs.txt - do not do in place as it remove all in ADDITIONALTABLEi
	${PATHGNU}/gawk -F'[_\t ]' 'NR==FNR {dates[$1$2]=$0; next} !($1$2 in dates)' ${ADDITIONALTABLE1} ${PATHSETI}/VVP/set6/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK_FULL.txt > ${PATHSETI}/VVP/set6/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt	# without header
	${PATHGNU}/gawk -F'[_\t ]' 'NR==FNR {dates[$1$2]=$0; next} !($1$2 in dates)' ${ADDITIONALTABLE2} ${PATHSETI}/VVP/set7/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK_FULL.txt > ${PATHSETI}/VVP/set7/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt	# without header

# Make files for baseline plots:
		# Create a 4 col file with header that contains all pairs but the one with an image in ]${STARTEXCLU} , ${STOPEXCLU}[
		# Need all files without header from here
		cd ${PATHSETI}/VVP/set6/
		RemovePairsFromTableList_Between_dates.sh ${TABLE1} ${STARTEXCLU} ${STOPEXCLU}		
		
		cd ${PATHSETI}/VVP/set7/
		RemovePairsFromTableList_Between_dates.sh ${TABLE2} ${STARTEXCLU} ${STOPEXCLU}		# Provide e.g. table_0_20_0_400.txt_Without_20210522_20210530.txt and  table_0_20_0_400.txt_Without_20210522_20210530_NoHeader.txt
		
		# Add pairs, sort, delete doublons, reshape as Dummy Bp MAS SLV and delete all lines that do not contains digits
		cat ${TABLEWITHOUTEXCLUNOHDR1} ${ADDITIONALTABLE1} | sort | uniq | ${PATHGNU}/gawk ' {print "Dummy "$3" "$1" "$2 } ' | ${PATHGNU}/grep '[0-9]' > ${TABLEWITHOUTEXCLUWITHADDNOHDR1} # replace TABLEWITHOUTEXCLUNOHDR1 with ...._After_WIthout.....txt
		cat ${TABLEWITHOUTEXCLUNOHDR2} ${ADDITIONALTABLE2} | sort | uniq | ${PATHGNU}/gawk ' {print "Dummy "$3" "$1" "$2 } ' | ${PATHGNU}/grep '[0-9]'> ${TABLEWITHOUTEXCLUWITHADDNOHDR2}
	

	# Create baseline plots with pairs excluded. Need a 4 col file as DummyTxt Bp MAS SLV
	echo "Compute baselinesPlot from TableFromDirMode_${MODENAME}.txt using new tools"
	cd ${PATHSETI}/VVP/set6/
	baselinePlot -r ${PATHSETI}/VVP/set6 ${TABLEWITHOUTEXCLUWITHADDNOHDR1}
	cd ${PATHSETI}/VVP/set7/
	baselinePlot -r ${PATHSETI}/VVP/set7 ${TABLEWITHOUTEXCLUWITHADDNOHDR2}
	# finally list of pairs is in e.g. restrictedPairSelection_Dummy_table_0_20_0_400_Till_20220501_0_70_0_400_After.txt_Without_20210522_20210530_WithAdditionalPairs.txt
	# and table to process (but the ones computed manually with Recurrent Unwrapping) is e.g. table_0_20_0_400_Till_20220501_0_70_0_400_After.txt_Without_20210522_20210530
	
# Plot baseline plot with both modes 
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 

	if [ `baselinePlot | wc -l` -eq 0 ] 
		then
			# use AMSTer Engine before May 2022	
			mkdir -p ${PATHSETI}/VVP/BaselinePlots_set6_set7
			cd ${PATHSETI}/VVP/BaselinePlots_set6_set7

			echo "${PATHSETI}/VVP/set6" > ModeList.txt
			echo "${PATHSETI}/VVP/set7" >> ModeList.txt

			#plot_Multi_BaselinePlot.sh ${PATHSETI}/VVP/BaselinePlots_set6_set7/ModeList.txt
 			$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 {BT}   $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt

		else
			# use AMSTer Engine > May 2022
			mkdir -p ${PATHSETI}/VVP/BaselinePlots_set6_set7
			cd ${PATHSETI}/VVP/BaselinePlots_set6_set7
 
			echo "${PATHSETI}/VVP/set6" > ModeList.txt
			echo "${PATHSETI}/VVP/set7" >> ModeList.txt
 
			plot_Multi_BaselinePlot.sh ${PATHSETI}/VVP/BaselinePlots_set6_set7/ModeList.txt
 	fi

fi

