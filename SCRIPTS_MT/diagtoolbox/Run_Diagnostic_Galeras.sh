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

STARTDATE=20140101
ENDDATE=20250601

#################### HARD CODED  #########################################
REGION="GALERAS"
REGIONCSL="GALERAS"
## DataPATHs

# SAR_CSL
PATH_CSL="${PATH_3610}/SAR_CSL/S1"

#SAR_SM
PATH_SM="${PATH_1650}/SAR_SM/MSBAS/GALERAS"

# SAR_MASSPROCESS
PATH_MASSPROCESS_MODE1="${PATH_3601}/SAR_MASSPROCESS/S1/GALERAS_A_120/SMNoCrop_SM_20190126_Zoom1_ML2"
PATH_MASSPROCESS_MODE2="${PATH_3601}/SAR_MASSPROCESS/S1/GALERAS_D_142/SMNoCrop_SM_20180906_Zoom1_ML2"


# MSBAS
PATH_MSBAS_S1="${PATH_3601}/MSBAS/_Galeras_S1_Auto_50m_150days"

# Label MSBAS
Label_1="_Auto_3_0.04_Galeras_NoCohThresh" # S1
Label_1b="_Auto_3_0.04_Galeras_Part1_NoCohThresh" # S1_P1
Label_1c="_Auto_3_0.04_Galeras_Part2_NoCohThresh" # S1_P2
Label_1d="_Auto_3_0.04_Galeras" # S1
Label_1e="_Auto_3_0.04_Galeras_Part1_CohThreshold" # S1_P1
Label_1f="_Auto_3_0.04_Galeras_Part2_CohThreshold" # S1_P2


## DEM 
DEM_SRTM="${PATH_DataSAR}/SAR_AUX_FILES/DEM/SRTM30/ALL/AMSTer_Galeras"

## Other File infos
ALL_MODESLIST="${PATH_1650}/DIAGNOFILES/Galeras/All_modes_list.txt"

REJECT_MODE=""

BTBP="${PATH_1650}/DIAGNOFILES/Galeras/BTBP_Infos.txt"

KML_listfile_all="${PATH_1650}/DIAGNOFILES/Galeras/KML_list.txt"
KML_listfile="${PATH_1650}/DIAGNOFILES/Galeras/KML_list_coh.txt"

CohTh_dir="${PATH_1650}/DIAGNOFILES/Galeras"

PointList="${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_Galeras.txt"  

EVENTSDummy="${PATH_1650}/DIAGNOFILES/Galeras/events.txt"

## Result writing
RESULT_DIR="${PATH_3600}/DIAG_RESULTS/Galeras"

RESULT_MSBAS_COMP=${RESULT_DIR}/MSBAS/_COMP
RESULT_S1="${RESULT_DIR}/MSBAS/S1"

RESULTDIR_1="${RESULT_MSBAS_COMP}/01_NoCoh_CohTh031"
RESULTDIR_2="${RESULT_MSBAS_COMP}/02_NoCoh_CohTh031_P1"
RESULTDIR_3="${RESULT_MSBAS_COMP}/03_NoCoh_CohTh031_P2"
RESULTDIR_4="${RESULT_MSBAS_COMP}/04_NoCoh_NoSplit_P1"
RESULTDIR_5="${RESULT_MSBAS_COMP}/05_CohTh031_NoSplit_P1"
RESULTDIR_6="${RESULT_MSBAS_COMP}/06_NoCoh_NoSplit_P2"
RESULTDIR_7="${RESULT_MSBAS_COMP}/07_CohTh031_NoSplit_P2"




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

cp ${PATH_MSBAS_S1}/restrictedPairSelection_DefoInterpolx2Detrend*.txt ${RESULT_S1}

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
    cp "$source_file" "$destination_file"
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
    Analyse_AllPairslisting_data.py --input_file ${destination_file} --BPmax ${BPmax} --BTmax ${BTmax} --startdate ${STARTDATEANALYSE} --enddate ${ENDDATEANALYSE} --gap ${GAPINDAYS} --nbr ${nbr} --BP2 ${BPmax2} --BT2 ${BTmax2} --datechange ${Datechange} > ${RESULT_DIR}/SM/logfile_${k}.txt 2>&1

##COH  
# 	source_cohfile="${PATH_MSBAS_S1}/DefoInterpolx2Detrend${k}_Full/Coh_Table_DefoInterpolx2Detrend${k}.txt" 
# 	destination_cohfile="${RESULT_S1}/"
# 	cp "${source_cohfile}" "${destination_cohfile}"
# 	echo "File ${source_cohfile} copied to: ${destination_cohfile}"
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
		echo ${filenamekml}
		filenamesource_Baselinecohtable=$(echo "Baseline_Coh_Table_"${filenamekml}".kml.txt")
		echo ${filenamesource_Baselinecohtable}
		filenamedesti_Baselinecohtable=$(echo "Baseline_Coh_Table_"${filenamekml}"_"${k}".kml.txt")
		echo ${filenamedesti_Baselinecohtable}
		eval "path=\$PATH_MASSPROCESS_MODE$k"  # Récupère la valeur de PATH_MASSPROCESS_MODE2 si k=2
		cd ${path}/Geocoded/Coh 
		echo $(pwd)
		echo "Compute Coh on kml ${filenamekml}.kml"
		echo Baseline_Coh_Table.sh "$ligne"
		cd ${CURRENTDIR}
		if [ -f "${path}/Geocoded/Coh/${filenamesource_Baselinecohtable}" ]; then
			## Utiliser la référence indirecte pour accéder à la variable dynamique
			eval "path=\$PATH_MASSPROCESS_MODE$k"  # Récupère la valeur de PATH_MASSPROCESS_MODE2 si k=2
			cp "${path}/Geocoded/Coh/${filenamesource_Baselinecohtable}" "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}"
			echo "copy file :${path}/Geocoded/Coh/${filenamesource_Baselinecohtable} to ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" 
		fi
		echo "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}"
		if [ -f "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" ]; then
			Cohth_file=${CohTh_dir}"Coh_th_Info_"${filenamekml}".txt"
			echo ${Cohth_file}
			if [ -f "${Cohth_file}" ]; then
    			CohTh=$(awk -v k="$k" '$1==k {print $2}' ${Cohth_file})
    			echo "Coherence Threshold : ${CohTh}"
				Analyse_BaselineCoh_data.py ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable} ${CohTh} > ${RESULT_DIR}/Coh/logfile_${filenamekml}_${k}.txt #2>&1
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
Compute_Stats_graph "${RESULT_S1}" > ${RESULT_S1}/logstatgraph.txt

echo " "
echo "Comparison of Baseline Plots"
echo " "

AllPairsListing1="${RESULT_DIR}/SM/allPairsListing_1.txt"
AllPairsListing2="${RESULT_DIR}/SM/allPairsListing_2.txt"



#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "Full_A" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt "Coh031_A" ${AllPairsListing1} ${RESULTDIR_1}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "Full_D" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt "Coh031_D" ${AllPairsListing2} ${RESULTDIR_1}



#			
#echo " "
#echo "Comparison of Maps and computation of the residuals"
echo " "#
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_1} ${PATH_MSBAS_S1}  ${Label_1}   ${PATH_MSBAS_S1}   ${Label_1d} #01_NoCoh_CohTh031
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_2} ${PATH_MSBAS_S1}  ${Label_1b}  ${PATH_MSBAS_S1}   ${Label_1e} #02_NoCoh_CohTh031_P1
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_3} ${PATH_MSBAS_S1}  ${Label_1c}  ${PATH_MSBAS_S1}   ${Label_1f} #03_NoCoh_CohTh031_P2
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_4} ${PATH_MSBAS_S1}  ${Label_1}   ${PATH_MSBAS_S1}   ${Label_1b} #04_NoCoh_NoSplit_P1
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_5} ${PATH_MSBAS_S1}  ${Label_1d}  ${PATH_MSBAS_S1}   ${Label_1e} #05_CohTh031_NoSplit_P1
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_6} ${PATH_MSBAS_S1}  ${Label_1}   ${PATH_MSBAS_S1}   ${Label_1c} #06_NoCoh_NoSplit_P2
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_7} ${PATH_MSBAS_S1}  ${Label_1d}  ${PATH_MSBAS_S1}   ${Label_1f} #07_CohTh031_NoSplit_P2


##
#echo " "
#echo "Comparison of Time Series"
#echo " "
#CompareTS_EWUD.sh ${RESULTDIR_1} "${PATH_MSBAS_S1},${PATH_MSBAS_S1}"	"${Label_1},${Label_1d}"  ${PointList} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_2} "${PATH_MSBAS_S1},${PATH_MSBAS_S1}"	"${Label_1b},${Label_1e}" ${PointList} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_3} "${PATH_MSBAS_S1},${PATH_MSBAS_S1}"	"${Label_1c},${Label_1f}" ${PointList} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_4} "${PATH_MSBAS_S1},${PATH_MSBAS_S1}"	"${Label_1},${Label_1b}" ${PointList} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_5} "${PATH_MSBAS_S1},${PATH_MSBAS_S1}"	"${Label_1d},${Label_1e}" ${PointList} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_6} "${PATH_MSBAS_S1},${PATH_MSBAS_S1}"	"${Label_1},${Label_1c}" ${PointList} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_7} "${PATH_MSBAS_S1},${PATH_MSBAS_S1}"	"${Label_1d},${Label_1f}" ${PointList} ${EVENTSDummy}
