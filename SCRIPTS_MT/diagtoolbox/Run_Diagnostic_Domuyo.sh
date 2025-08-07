#!/bin/bash
######################################################################################
# This script will run some scripts to run a full diagnostic of the AMSTer processing.	
#
# Parameters: 
# Hardcoded:  
#			  -	SAR_CSL directory_full_path
# 			  - SAR_SM directory_full_path
# 			  - SAR_MASSPROCESS directory_full_path
# 			  - MSBAS directory_full_path
#
#
# Dependencies:	- 
#
# WARNING All path hardcoded should have "" and not ''
#
# New in Distro V 1.0 20250305  set up based on Run_Diagnostic_PF

#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Mar 05, 2025" 
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo " "

CURRENTDIR=$(pwd)
cd
source .bashrc
cd ${CURRENTDIR}

STARTDATE=$1
ENDDATE=$2

#################### HARD CODED  #########################################
REGION="Domuyo"
REGIONCSL="ARG_DOMU_LAGUNA_DEMGeoid"
## DataPATHs

# SAR_CSL
PATH_CSL="${PATH_1650}/SAR_CSL/S1"

#SAR_SM
PATH_SM="${PATH_1650}/SAR_SM/MSBAS/ARGENTINE"

# SAR_MASSPROCESS
PATH_MASSPROCESS_MODE1="${PATH_3602}/SAR_MASSPROCESS_2/S1/ARG_DOMU_LAGUNA_DEMGeoid_A_18/SMNoCrop_SM_20180512_Zoom1_ML4"
PATH_MASSPROCESS_MODE2="${PATH_3602}/SAR_MASSPROCESS_2/S1/ARG_DOMU_LAGUNA_DEMGeoid_D_83/SMNoCrop_SM_20180222_Zoom1_ML4"


# MSBAS
PATH_MSBAS_S1="${PATH_3602}/MSBAS/_Domuyo_S1_Auto_80m_450days"

# Label MSBAS
Label_1="_Auto_3_0.04_Domuyo" # S1restrict
Label_1b="_Auto_3_0.04_Domuyo_PART1_OVERLAP_20210327" # S1restrictP1
Label_1c="_Auto_3_0.04_Domuyo_PART2_OVERLAP_20210327" # S1restrictP2
Label_2="_Auto_3_0.04_Domuyo_NoCohThresh" #S1Full
Label_2b="_Auto_3_0.04_Domuyo_NoCohThresh_PART1_OVERLAP_20210327" #S1FullP1
Label_2c="_Auto_3_0.04_Domuyo_NoCohThresh_PART2_OVERLAP_20210327" #S1FullP2


## DEM 
DEM_SRTM="${PATH_DataSAR}/SAR_AUX_FILES/DEM/SRTM30/ALL/NQNyMas_Geoid"

## Other File infos
ALL_MODESLIST="${PATH_1650}/DIAGNOFILES/Domuyo/All_modes_list.txt"

REJECT_MODE=""

BTBP="${PATH_1650}/DIAGNOFILES/Domuyo/BTBP_Infos.txt"

KML_listfile_all="${PATH_1650}/DIAGNOFILES/Domuyo/KML_list.txt"
KML_listfile="${PATH_1650}/DIAGNOFILES/Domuyo/KML_list_coh.txt"

CohTh_dir="${PATH_1650}/DIAGNOFILES/Domuyo"

PointList="${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_Domuyo_AdjustedOnMask.txt"  

EVENTSDummy="${PATH_1650}/DIAGNOFILES/Domuyo/events.txt"

## Result writing
RESULT_DIR="${PATH_3611}/DIAG_RESULTS/Domuyo"

RESULT_MSBAS_COMP=${RESULT_DIR}/MSBAS/_COMP
RESULT_S1="${RESULT_DIR}/MSBAS/S1"

RESULTDIR_1="${RESULT_MSBAS_COMP}/01_Cohrestict_NoCohTH"
RESULTDIR_2="${RESULT_MSBAS_COMP}/02_Cohrestict_Part1"
RESULTDIR_3="${RESULT_MSBAS_COMP}/03_Cohrestict_Part2"
RESULTDIR_4="${RESULT_MSBAS_COMP}/04_NoCohTH_Part1"
RESULTDIR_5="${RESULT_MSBAS_COMP}/05_NoCohTH_Part2"
RESULTDIR_6="${RESULT_MSBAS_COMP}/06_Cohrestict_Part1_Part2"
RESULTDIR_7="${RESULT_MSBAS_COMP}/07_NoCohTH_Part1_Part2"




#################### START SCRIPT #########################################
## Preparation
echo "Run_Diagnostic " 

mkdir -p ${RESULT_DIR}
mkdir -p ${RESULT_DIR}/CSL
mkdir -p ${RESULT_DIR}/SM
mkdir -p ${RESULT_DIR}/COH
mkdir -p ${RESULT_DIR}/DEM
mkdir -p ${RESULT_DIR}/MSBAS


mkdir -p ${RESULT_S1}
mkdir -p ${RESULT_MSBAS_COMP}

mkdir -p ${RESULTDIR_1}
mkdir -p ${RESULTDIR_2}
mkdir -p ${RESULTDIR_3}
mkdir -p ${RESULTDIR_4}
mkdir -p ${RESULTDIR_5}
mkdir -p ${RESULTDIR_6}
mkdir -p ${RESULTDIR_7}


## Plot kml extent over dem
echo " "
echo "Make plot of DEMs and KML"
echo " "
#Plot_cslDEM_and_KMLs.py ${DEM_SRTM} ${KML_listfile_all} ${RESULT_DIR}/DEM/
#Plot_cslDEM_and_KMLs.py ${DEM_SRTM} ${KML_listfile} ${RESULT_DIR}/DEM/


## Listing of CSL images
echo " "
echo "Path where CSL data are stored : ${PATH_CSL}" 
echo " "

cd ${RESULT_DIR}/CSL
#List_All_Modes_and_All_Images.sh "${PATH_CSL}"  "${REGIONCSL}"  ${STARTDATE} ${ENDDATE}
cd ..

echo " "
echo "CSL_Lists are written in ${RESULT_DIR}/CSL/*_mode_list.txt"
echo " "

## Updating local listing of MSBAS infos
echo " "
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_S1}"
echo " "

#cp ${PATH_MSBAS_S1}/restrictedPairSelection_DefoInterpolx2Detrend*.txt ${RESULT_S1}

# Compare CSL and MSBAS databases
echo " "
echo "Compare CSL and MSBAS databases"
echo " "

#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_S1}    ${STARTDATE} ${ENDDATE}  ${RESULT_S1}   ${ALL_MODESLIST} -event ${EVENTSDummy} > ${RESULT_S1}/logfile_checkimage.txt #2>&1

# Info SAR_SM: allPairsListing
echo " "
echo "Copy allPairsListing.txt files from ${PATH_SM} and analyse BP/BT infos"
echo " "

# Boucle sur k
for k in {1..2}; do
    # Construction des chemins source et destination
    source_file="${PATH_SM}/set${k}/allPairsListing.txt"
    destination_file="${RESULT_DIR}/SM/allPairsListing_${k}.txt"
    
    # Copier le fichier
#    cp "$source_file" "$destination_file"
    # Afficher une confirmation
    echo "File "$source_file" copied to: $destination_file"

    BPmax=$(awk -v k="$k" '$1==k {print $2}' ${BTBP})
    BTmax=$(awk -v k="$k" '$1==k {print $3}' ${BTBP})
    BPmax2=$(awk -v k="$k" '$1==k {print $5}' ${BTBP})
    BTmax2=$(awk -v k="$k" '$1==k {print $6}' ${BTBP})
    Datechange=$(awk -v k="$k" '$1==k {print $7}' ${BTBP})
    STARTDATEANALYSE=$(awk -v k="$k" '$1==k {print $8}' ${BTBP})
    ENDDATEANALYSE=$(awk -v k="$k" '$1==k {print $9}' ${BTBP})
    GAPINDAYS=12
    nbr=1.5 # factor criteria to restrict the display of possible additional pairs    
#    Analyse_AllPairslisting_data.py --input_file ${destination_file} --BPmax ${BPmax} --BTmax ${BTmax} --startdate ${STARTDATEANALYSE} --enddate ${ENDDATEANALYSE} --gap ${GAPINDAYS} --nbr ${nbr} --BP2 ${BPmax2} --BT2 ${BTmax2} --datechange ${Datechange} > ${RESULT_DIR}/SM/logfile_${k}.txt 2>&1

##COH  
 	source_cohfile="${PATH_MSBAS_S1}/DefoInterpolx2Detrend${k}_Full/Coh_Table_DefoInterpolx2Detrend${k}.txt" 
 	destination_cohfile="${RESULT_S1}/"
# 	cp "${source_cohfile}" "${destination_cohfile}"
 	echo "File ${source_cohfile} copied to: ${destination_cohfile}"
##
done


echo " "
echo "Compute and copy Baseline_Coh_Table files from SAR_MASSPROCESS and kml and analyse results"
echo " "

CohTh_dir="${CohTh_dir%/}/" 
##COH Baseline_Coh_Table_KMLNAME.kml.txt
k_values=(1 2)  # Par exemple, 1, 2, 3, 4
for k in "${k_values[@]}"; do
	while IFS= read -r ligne; do
		filenamekml=$(basename "$ligne" .kml)
		filenamesource_Baselinecohtable=$(echo "Baseline_Coh_Table_"${filenamekml}".kml.txt")
		filenamedesti_Baselinecohtable=$(echo "Baseline_Coh_Table_"${filenamekml}"_"${k}".kml.txt")
		eval "path=\$PATH_MASSPROCESS_MODE$k"  # Récupère la valeur de PATH_MASSPROCESS_MODE2 si k=2
		cd ${path}/Geocoded/Coh 
		echo $(pwd)
		echo "Compute Coh on kml ${filenamekml}.kml"
		echo Baseline_Coh_Table.sh "$ligne"
		cd ${CURRENTDIR}
		if [ -f "${path}/Geocoded/Coh/${filenamesource_Baselinecohtable}" ]; then
			## Utiliser la référence indirecte pour accéder à la variable dynamique
			eval "path=\$PATH_MASSPROCESS_MODE$k"  # Récupère la valeur de PATH_MASSPROCESS_MODE2 si k=2
			#cp "${path}/Geocoded/Coh/${filenamesource_Baselinecohtable}" "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}"
			echo "copy file :${path}/Geocoded/Coh/${filenamesource_Baselinecohtable} to ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" 
		fi
		echo "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}"
		if [ -f "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" ]; then
			Cohth_file=${CohTh_dir}"Coh_th_Info_"${filenamekml}".txt"
			echo ${Cohth_file}
			if [ -f "${Cohth_file}" ]; then
    			CohTh=$(awk -v k="$k" '$1==k {print $2}' ${Cohth_file})
    			echo "Coherence Threshold : ${CohTh}"
				#Analyse_BaselineCoh_data.py ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable} ${CohTh} > ${RESULT_DIR}/Coh/logfile_${filenamekml}_${k}.txt #2>&1
				echo "Analyse BSC done"
			fi
		fi
	done < "${KML_listfile}"

done

echo " "
echo "Compute stats on graphs from MSBAS networks"
echo " "

# MSBAS Stats 
Compute_Stats_graph() {
    local result_path=$1
    local pairs_file="${result_path}/pairs.pkl"
    local graphs_file="${result_path}/graphs.pkl"
    local images_file="${result_path}/images.pkl"
    local result_stats_file="${result_path}/result_stats.pkl"

    Import_RestrictedPairSelectionFiles_as_DF.py "${result_path}" "${pairs_file}"
    Compute_Graphs_From_dfpkl.py "${pairs_file}" "${graphs_file}"
    Graph2StatsImagesDF.py "${graphs_file}" "${images_file}"
    Extract_Stats_All_Modes.py "${images_file}" "${result_stats_file}"
}

# Process for each dataset
#Compute_Stats_graph "${RESULT_S1}"

echo " "
echo "Comparison of Baseline Plots"
echo " "

AllPairsListing1="${RESULT_DIR}/SM/allPairsListing_1.txt"
AllPairsListing2="${RESULT_DIR}/SM/allPairsListing_2.txt"

#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "S1AFull" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt "S1Arestrict" ${AllPairsListing1} ${RESULTDIR_1}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "S1DFull" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt "S1Drestrict" ${AllPairsListing2} ${RESULTDIR_1}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1Arestrict" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Below20230104.txt "S1ArestrictP1" ${AllPairsListing1} ${RESULTDIR_2}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1Drestrict" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Below20230104.txt "S1DrestrictP1" ${AllPairsListing2} ${RESULTDIR_2}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1Arestrict" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_After20190525.txt "S1ArestrictP2" ${AllPairsListing1} ${RESULTDIR_3}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1Drestrict" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_After20190525.txt "S1DrestrictP2" ${AllPairsListing2} ${RESULTDIR_3}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "S1AFull" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full_Below20230104.txt "S1AFullP1" ${AllPairsListing1} ${RESULTDIR_4}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "S1DFull" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full_Below20230104.txt "S1DFullP1" ${AllPairsListing2} ${RESULTDIR_4}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "S1AFull" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full_After20190525.txt "S1AFullP2" ${AllPairsListing1} ${RESULTDIR_5}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "S1DFull" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full_After20190525.txt "S1DFullP2" ${AllPairsListing2} ${RESULTDIR_5}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Below20230104.txt  "S1ArestrictP1" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_After20190525.txt "S1ArestrictP2" ${AllPairsListing1} ${RESULTDIR_6}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Below20230104.txt  "S1DrestrictP1" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_After20190525.txt "S1DrestrictP2" ${AllPairsListing2} ${RESULTDIR_6}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full_Below20230104.txt  "S1AFullP1" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full_After20190525.txt "S1AFullP2" ${AllPairsListing1} ${RESULTDIR_7}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full_Below20230104.txt  "S1DFullP1" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full_After20190525.txt "S1DFullP2" ${AllPairsListing2} ${RESULTDIR_7}

#			
#echo " "
#echo "Comparison of Maps and computation of the residuals"
#echo " "
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_1} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_S1} ${Label_2} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_2} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_S1} ${Label_1b} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_3} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_S1} ${Label_1c} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_4} ${PATH_MSBAS_S1}  ${Label_2} ${PATH_MSBAS_S1} ${Label_2b} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_5} ${PATH_MSBAS_S1}  ${Label_2} ${PATH_MSBAS_S1} ${Label_2c} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_6} ${PATH_MSBAS_S1}  ${Label_1b} ${PATH_MSBAS_S1} ${Label_1c} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_7} ${PATH_MSBAS_S1}  ${Label_2b} ${PATH_MSBAS_S1} ${Label_2c} 
#

#
echo " "
echo "Comparison of Time Series"
echo " "
CompareTS_EWUD.sh ${RESULTDIR_1} ${PATH_MSBAS_S1}  ${Label_1}  ${PATH_MSBAS_S1} ${Label_2}  ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_2} ${PATH_MSBAS_S1}  ${Label_1}  ${PATH_MSBAS_S1} ${Label_1b} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_3} ${PATH_MSBAS_S1}  ${Label_1}  ${PATH_MSBAS_S1} ${Label_1c} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_4} ${PATH_MSBAS_S1}  ${Label_2}  ${PATH_MSBAS_S1} ${Label_2b} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_5} ${PATH_MSBAS_S1}  ${Label_2}  ${PATH_MSBAS_S1} ${Label_2c} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_6} ${PATH_MSBAS_S1}  ${Label_1b} ${PATH_MSBAS_S1} ${Label_1c} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_7} ${PATH_MSBAS_S1}  ${Label_2b} ${PATH_MSBAS_S1} ${Label_2c} ${PointList}
