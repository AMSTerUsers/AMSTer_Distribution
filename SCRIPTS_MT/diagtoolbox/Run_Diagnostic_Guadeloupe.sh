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
# New in Distro V 1.0 20250114  set up
# New in Distro V 1.1 20250128  Configure for Guadeloupe TSX data
# New in Distro V 1.2 20250213  Cosmetic
# New in Distro V 1.2 20250312  Run on disk 3600 and change location of input files to 1650 _only ML5
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Mar 11, 2025" 
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo " "

CURRENTDIR=$(pwd)

STARTDATE=20140101
STARTDATE_S1=20180601
STARTDATE_TSX=20231206
ENDDATE=20250531

#################### HARD CODED  #########################################
REGION="GUADELOUPE"

## DataPATHs

# SAR_CSL
PATH_CSL_S1="${PATH_1650}/SAR_CSL/S1"
PATH_CSL_TSX="${PATH_1650}/SAR_CSL/TSX"

#SAR_SM
PATH_SM="${PATH_1650}/SAR_SM/MSBAS/GUADELOUPE"

# SAR_MASSPROCESS
PATH_MASSPROCESS_MODE1="${PATH_3601}/SAR_MASSPROCESS/S1/GUADELOUPE_A_164/SMNoCrop_SM_20190622_Zoom1_ML2/"
PATH_MASSPROCESS_MODE2="${PATH_3601}/SAR_MASSPROCESS/S1/GUADELOUPE_D_54/SMNoCrop_SM_20200410_Zoom1_ML2/"

PATH_MASSPROCESS_MODE3="${PATH_3610}/SAR_MASSPROCESS/TSX/GUADELOUPE_A104/SMNoCrop_SM_20240204_Zoom1_ML5"
PATH_MASSPROCESS_MODE4="${PATH_3610}/SAR_MASSPROCESS/TSX/GUADELOUPE_D20/SMNoCrop_SM_20240724_Zoom1_ML5"


# MSBAS
PATH_MSBAS_S1="${PATH_3602}/MSBAS/_Guadeloupe_S1_Auto_90m_150days_restrict20180601_restrictcoh037"
PATH_MSBAS_TSX_defo300="${PATH_3602}/MSBAS/_Guadeloupe_TSX_Auto_300m_150days_DefoInterpolx2Detrend_restrict20231201_restrictcoh0325_NEW"
PATH_MSBAS_TSX_defo90="${PATH_3602}/MSBAS/_Guadeloupe_TSX_Auto_90m_150days_DefoInterpolx2Detrend_restrict20231201_restrictcoh0325_5m"
PATH_MSBAS_TSX_cor300="${PATH_3602}/MSBAS/_Guadeloupe_TSX_Auto_300m_150days_COR_Defo_Dem_restrict20231201_restrictcoh0325_NEW"
PATH_MSBAS_TSX_cor90="${PATH_3602}/MSBAS/_Guadeloupe_TSX_Auto_90m_150days_COR_Defo_Dem_restrict20231201_restrictcoh0325_5m"
PATH_MSBAS_TSX_FullTime="${PATH_3602}/MSBAS/_Guadeloupe_TSX_Auto_300m_150days_COR_Defo_Dem_restrict20210310_restrictcoh0325_5m"

# Label MSBAS
Label_1="_Auto_2_0.04_Guadeloupe"
Label_1b="_Auto_2_0.04_Guadeloupe_NoCohThresh"
Label_2="_Auto_2_0.04_Guadeloupe"
Label_2b="_Auto_2_0.04_Guadeloupe_NoCohThresh"
Label_3="_Auto_2_0.04_Guadeloupe"
Label_3b="_Auto_2_0.04_Guadeloupe_NoCohThresh"
Label_4="_Auto_2_0.04_Guadeloupe"
Label_4b="_Auto_2_0.04_Guadeloupe_NoCohThresh"
Label_5="_Auto_2_0.04_Guadeloupe"
Label_5b="_Auto_2_0.04_Guadeloupe_NoCohThresh"
Label_6="_Auto_2_0.04_Guadeloupe"
Label_6b="_Auto_2_0.04_Guadeloupe_NoCohThresh"

## DEM 
DEM_SRTM="${PATH_DataSAR}/SAR_AUX_FILES/DEM/SRTM30/Guadeloupe/Guadeloupe"
DEM_HR_CSL="${PATH_DataSAR}/SAR_AUX_FILES/DEM/Lidar/Guadeloupe/DEM_Guadeloupe_5m/CSL/Guadeloupe_SRTM_Lidar_flip0.bil"

## Other File infos
ALL_MODESLIST="${PATH_1650}/DIAGNOFILES/Guadeloupe/All_modes_list.txt"

REJECT_MODE_TSX="${PATH_1650}/DIAGNOFILES/Guadeloupe/reject_TSX_modes_list.txt"
REJECT_MODE_S1="${PATH_1650}/DIAGNOFILES/Guadeloupe/reject_S1_modes_list.txt"

BTBP="${PATH_1650}/DIAGNOFILES/Guadeloupe/BTBP_Infos2.txt"

KML_listfile="${PATH_1650}/DIAGNOFILES/Guadeloupe/kml_list.txt"
KML_listfile_coh="${PATH_1650}/DIAGNOFILES/Guadeloupe/kml_list_coh.txt"

CohTh_dir="${PATH_1650}/DIAGNOFILES/Guadeloupe/ML5/"

PointListTSX="${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_Guadeloupe_5mfrom30m.txt"  
PointListS1="${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_Guadeloupe.txt"  

EVENTSDummy="${PATH_1650}/DIAGNOFILES/Guadeloupe/events.txt"

## Result writing
RESULT_DIR="${PATH_3600}/DIAG_RESULTS/Guadeloupe/ML5"

RESULT_MSBAS_COMP=${RESULT_DIR}/MSBAS/_COMP
RESULT_S1="${RESULT_DIR}/MSBAS/S1"
RESULT_TSX_cor90="${RESULT_DIR}/MSBAS/TSX_cor90"
RESULT_TSX_defo90="${RESULT_DIR}/MSBAS/TSX_defo90"
RESULT_TSX_cor300="${RESULT_DIR}/MSBAS/TSX_cor300"
RESULT_TSX_defo300="${RESULT_DIR}/MSBAS/TSX_defo300"
RESULT_TSX_FullTime="${RESULT_DIR}/MSBAS/TSX_FullTime"

RESULTDIR_1="${RESULT_MSBAS_COMP}/01_S1_cohth"

RESULTDIR_2="${RESULT_MSBAS_COMP}/02_TSXdefo90_cohth"
RESULTDIR_3="${RESULT_MSBAS_COMP}/03_TSXcor90_cohth"
RESULTDIR_4="${RESULT_MSBAS_COMP}/04_TSXdefo300_cohth"
RESULTDIR_5="${RESULT_MSBAS_COMP}/05_TSXcor300_cohth"

RESULTDIR_6="${RESULT_MSBAS_COMP}/06_TSXdefo90_TSXcor90"
RESULTDIR_7="${RESULT_MSBAS_COMP}/07_TSXdefo300_TSXcor300"
RESULTDIR_8="${RESULT_MSBAS_COMP}/08_TSXdefo90_TSXdefo300"
RESULTDIR_9="${RESULT_MSBAS_COMP}/09_TSXcor90_TSXcor300"

RESULTDIR_10="${RESULT_MSBAS_COMP}/10_TSXdefo90_TSXcor90_cohth"
RESULTDIR_11="${RESULT_MSBAS_COMP}/11_TSXdefo300_TSXcor300_cohth"
RESULTDIR_12="${RESULT_MSBAS_COMP}/12_TSXdefo90_TSXdefo300_cohth"
RESULTDIR_13="${RESULT_MSBAS_COMP}/13_TSXcor90_TSXcor300_cohth"

RESULTDIR_14="${RESULT_MSBAS_COMP}/14_S1_TSXdefo90"
RESULTDIR_15="${RESULT_MSBAS_COMP}/15_S1_TSXdefo300"
RESULTDIR_16="${RESULT_MSBAS_COMP}/16_S1_TSXcor90"
RESULTDIR_17="${RESULT_MSBAS_COMP}/17_S1_TSXcor300"

RESULTDIR_18="${RESULT_MSBAS_COMP}/18_S1_TSXdefo90cohth"
RESULTDIR_19="${RESULT_MSBAS_COMP}/19_S1_TSXdefo300cohth"
RESULTDIR_20="${RESULT_MSBAS_COMP}/20_S1_TSXcor90cohth"
RESULTDIR_21="${RESULT_MSBAS_COMP}/21_S1_TSXcor300cohth"


# CROP
xmin=641000
ymin=1772000
xmax=645000
ymax=1776000

# PROFILE
x1=642000
y1=1774200
x2=644000
y2=1774200

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
mkdir -p ${RESULT_TSX_cor90}
mkdir -p ${RESULT_TSX_defo90}
mkdir -p ${RESULT_TSX_cor300}
mkdir -p ${RESULT_TSX_defo300}
mkdir -p ${RESULT_TSX_FullTime}
mkdir -p ${RESULT_MSBAS_COMP}

mkdir -p ${RESULTDIR_1}
mkdir -p ${RESULTDIR_2}
mkdir -p ${RESULTDIR_3}
mkdir -p ${RESULTDIR_4}
mkdir -p ${RESULTDIR_5}
mkdir -p ${RESULTDIR_6}
mkdir -p ${RESULTDIR_7}
mkdir -p ${RESULTDIR_8}
mkdir -p ${RESULTDIR_9}
mkdir -p ${RESULTDIR_10}
mkdir -p ${RESULTDIR_11}
mkdir -p ${RESULTDIR_12}
mkdir -p ${RESULTDIR_13}
mkdir -p ${RESULTDIR_14}
mkdir -p ${RESULTDIR_15}
mkdir -p ${RESULTDIR_16}
mkdir -p ${RESULTDIR_17}
mkdir -p ${RESULTDIR_18}
mkdir -p ${RESULTDIR_19}
mkdir -p ${RESULTDIR_20}
mkdir -p ${RESULTDIR_21}


## Plot kml extent over dem
echo " "
echo "Make plot of DEMs and KML"
echo " "
#Plot_cslDEM_and_KMLs.py ${DEM_SRTM} ${KML_listfile} ${RESULT_DIR}/DEM/
#Plot_cslDEM_and_KMLs.py ${DEM_HR_CSL} ${KML_listfile} ${RESULT_DIR}/DEM/


## Listing of CSL images
echo " "
echo "Path where CSL data are stored : ${PATH_CSL_TSX}" 
echo "Path where CSL data are stored : ${PATH_CSL_S1}" 
echo " "

cd ${RESULT_DIR}/CSL
#List_All_Modes_and_All_Images.sh "${PATH_CSL_TSX}" "${REGION}" ${STARTDATE} ${ENDDATE}
#List_All_Modes_and_All_Images.sh "${PATH_CSL_S1}" "${REGION}" ${STARTDATE} ${ENDDATE}
cd ..

echo " "
echo "CSL_Lists are written in ${RESULT_DIR}/CSL/*_mode_list.txt"
echo " "

## Updating local listing of MSBAS infos
echo " "
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_S1}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_TSX_cor90}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_TSX_defo90}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_TSX_cor300}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_TSX_defo300}"
echo " "

#cp ${PATH_MSBAS_S1}/restrictedPairSelection_DefoInterpolx2Detrend*.txt  ${RESULT_S1}
#cp ${PATH_MSBAS_S1}/DefoInterpolx2Detrend*/restrictedPairSelection_DefoInterpolx2Detrend*.txt  ${RESULT_S1}
#cp ${PATH_MSBAS_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem1.txt  ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3.txt 
#cp ${PATH_MSBAS_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem2.txt  ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4.txt 
#cp ${PATH_MSBAS_TSX_cor90}/COR_Defo_Dem1_Full/restrictedPairSelection_COR_Defo_Dem1_Full.txt  ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3_Full.txt 
#cp ${PATH_MSBAS_TSX_cor90}/COR_Defo_Dem2_Full/restrictedPairSelection_COR_Defo_Dem2_Full.txt  ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4_Full.txt 
#
#cp ${PATH_MSBAS_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem1.txt  ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3.txt 
#cp ${PATH_MSBAS_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem2.txt  ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4.txt 
#cp ${PATH_MSBAS_TSX_cor300}/COR_Defo_Dem1_Full/restrictedPairSelection_COR_Defo_Dem1_Full.txt  ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3_Full.txt 
#cp ${PATH_MSBAS_TSX_cor300}/COR_Defo_Dem2_Full/restrictedPairSelection_COR_Defo_Dem2_Full.txt  ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4_Full.txt 
#
#cp ${PATH_MSBAS_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3.txt 
#cp ${PATH_MSBAS_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4.txt 
#cp ${PATH_MSBAS_TSX_defo90}/DefoInterpolx2Detrend1_Full/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt 
#cp ${PATH_MSBAS_TSX_defo90}/DefoInterpolx2Detrend2_Full/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt 
#
#cp ${PATH_MSBAS_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3.txt 
#cp ${PATH_MSBAS_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4.txt 
#cp ${PATH_MSBAS_TSX_defo300}/DefoInterpolx2Detrend1_Full/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt 
#cp ${PATH_MSBAS_TSX_defo300}/DefoInterpolx2Detrend2_Full/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt 

#cp ${PATH_MSBAS_TSX_FullTime}/restrictedPairSelection_COR_Defo_Dem1.txt  ${RESULT_TSX_FullTime}/restrictedPairSelection_COR_Defo_Dem3.txt 
#cp ${PATH_MSBAS_TSX_FullTime}/restrictedPairSelection_COR_Defo_Dem2.txt  ${RESULT_TSX_FullTime}/restrictedPairSelection_COR_Defo_Dem4.txt 
#cp ${PATH_MSBAS_TSX_FullTime}/COR_Defo_Dem1_Full/restrictedPairSelection_COR_Defo_Dem1_Full.txt  ${RESULT_TSX_FullTime}/restrictedPairSelection_COR_Defo_Dem3_Full.txt 
#cp ${PATH_MSBAS_TSX_FullTime}/COR_Defo_Dem2_Full/restrictedPairSelection_COR_Defo_Dem2_Full.txt  ${RESULT_TSX_FullTime}/restrictedPairSelection_COR_Defo_Dem4_Full.txt 

echo " "
echo "Compare CSL and MSBAS databases"
echo " "

#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_S1} ${STARTDATE_S1} ${ENDDATE} ${RESULT_S1} ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_TSX} > ${RESULT_S1}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_TSX_cor90} ${STARTDATE_TSX} ${ENDDATE} ${RESULT_TSX_cor90}  ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1}> ${RESULT_TSX_cor90}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_TSX_defo90} ${STARTDATE_TSX} ${ENDDATE} ${RESULT_TSX_defo90}  ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1}> ${RESULT_TSX_defo90}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_TSX_cor300} ${STARTDATE_TSX} ${ENDDATE} ${RESULT_TSX_cor300}  ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1}> ${RESULT_TSX_cor300}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_TSX_defo300} ${STARTDATE_TSX} ${ENDDATE} ${RESULT_TSX_defo300}  ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1}> ${RESULT_TSX_defo300}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_TSX_FullTime} 20210101 ${ENDDATE} ${RESULT_TSX_FullTime}  ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1}> ${RESULT_TSX_FullTime}/logfile_checkimage.txt #2>&1



# Info SAR_SM: allPairsListing
echo " "
echo "Copy allPairsListing.txt files from ${PATH_SM} and analyse BP/BT infos"
echo " "

# Boucle sur k
for k in {1..4}; do
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
    GAPINDAYS=11
    nbr=1.5 # factor criteria to restrict the display of possible additional pairs    
    #Analyse_AllPairslisting_data.py --input_file ${destination_file} --BPmax ${BPmax} --BTmax ${BTmax} --startdate ${STARTDATEANALYSE} --enddate ${ENDDATEANALYSE} --gap ${GAPINDAYS} --nbr ${nbr} --BP2 ${BPmax2} --BT2 ${BTmax2} --datechange ${Datechange} > ${RESULT_DIR}/SM/logfile_${k}.txt 2>&1

##COH    
# 	source_cohfile="${PATH_MSBAS_Combi}/DefoInterpolx2Detrend${k}_Full/Coh_Table_DefoInterpolx2Detrend${k}.txt" 
# 	destination_cohfile="${RESULT_Combi}/"
# 	cp "${source_cohfile}" "${destination_cohfile}"
#    echo "File ${source_cohfile} copied to: ${destination_cohfile}"

done



echo " "
echo "Compute and copy Baseline_Coh_Table files from SAR_MASSPROCESS and kml and analyse results"
echo " "
##COH Baseline_Coh_Table_KMLNAME.kml.txt
k_values=(1 2 3 4)  # Par exemple, 1, 2, 3, 4
for k in "${k_values[@]}"; do
	while IFS= read -r ligne; do
		filenamekml=$(basename "$ligne" .kml)
		filenamesource_Baselinecohtable=$(echo "Baseline_Coh_Table_"${filenamekml}".kml.txt")
		filenamedesti_Baselinecohtable=$(echo "Baseline_Coh_Table_"${filenamekml}"_"${k}".kml.txt")
		eval "path=\$PATH_MASSPROCESS_MODE$k"  # RXcupXre la valeur de PATH_MASSPROCESS_MODE2 si k=2
		cd ${path}/Geocoded/Coh 
		echo $(pwd)
		echo "Compute Coh on kml ${filenamekml}.kml"
		echo Baseline_Coh_Table.sh "$ligne"
		cd ${CURRENTDIR}
		if [ -f "${path}/Geocoded/Coh/${filenamesource_Baselinecohtable}" ]; then
			## Utiliser la rXfXrence indirecte pour accXder X la variable dynamique
			eval "path=\$PATH_MASSPROCESS_MODE$k"  # RXcupXre la valeur de PATH_MASSPROCESS_MODE2 si k=2
			cp "${path}/Geocoded/Coh/${filenamesource_Baselinecohtable}" "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}"
			echo "copy file :${path}/Geocoded/Coh/${filenamesource_Baselinecohtable} to ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" 
		fi
		if [ -f "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" ]; then
			Cohth_file=${CohTh_dir}"Coh_th_Info_"${filenamekml}".txt"
			if [ -f "${Cohth_file}" ]; then
    			CohTh=$(awk -v k="$k" '$1==k {print $2}' ${Cohth_file})
    			echo "Coherence Threshold : ${CohTh}"
				#Analyse_BaselineCoh_data.py ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable} ${CohTh} > ${RESULT_DIR}/Coh/logfile_${filenamekml}_${k}.txt #2>&1
				echo "Analyse BSC done"
			fi
		fi
	done < "${KML_listfile_coh}"

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
#Compute_Stats_graph "${RESULT_TSX_cor90}"
#Compute_Stats_graph "${RESULT_TSX_defo90}"
#Compute_Stats_graph "${RESULT_TSX_cor300}"
#Compute_Stats_graph "${RESULT_TSX_defo300}"
#Compute_Stats_graph "${RESULT_TSX_FullTime}"
#

## MSBAS Results

#cp ${PATH_MSBAS_S1}/baselinePlot_DefoInterpolx2Detrend*.txt.png  ${RESULT_S1}/
#cp ${PATH_MSBAS_S1}/DefoInterpolx2Detrend*_Full/baselinePlot_DefoInterpolx2Detrend*_Full.txt.png  ${RESULT_S1}/
#cp ${PATH_MSBAS_TSX_defo90}/baselinePlot_DefoInterpolx2Detrend*.txt.png  ${RESULT_TSX_defo90}/
#cp ${PATH_MSBAS_TSX_defo90}/DefoInterpolx2Detrend*_Full/baselinePlot_DefoInterpolx2Detrend*_Full.txt.png  ${RESULT_TSX_defo90}/
#cp ${PATH_MSBAS_TSX_defo300}/baselinePlot_DefoInterpolx2Detrend*.txt.png  ${RESULT_TSX_defo300}/
#cp ${PATH_MSBAS_TSX_defo300}/DefoInterpolx2Detrend*_Full/baselinePlot_DefoInterpolx2Detrend*_Full.txt.png  ${RESULT_TSX_defo300}/
#cp ${PATH_MSBAS_TSX_cor90}/baselinePlot_COR_Defo_Dem*.txt.png  ${RESULT_TSX_cor90}/
#cp ${PATH_MSBAS_TSX_cor90}/COR_Defo_Dem*_Full/baselinePlot_COR_Defo_Dem*_Full.txt.png  ${RESULT_TSX_cor90}/
#cp ${PATH_MSBAS_TSX_cor300}/baselinePlot_COR_Defo_Dem*.txt.png  ${RESULT_TSX_cor300}/
#cp ${PATH_MSBAS_TSX_cor300}/COR_Defo_Dem*_Full/baselinePlot_COR_Defo_Dem*_Full.txt.png  ${RESULT_TSX_cor300}/
#cp ${PATH_MSBAS_TSX_FullTime}/baselinePlot_COR_Defo_Dem*.txt.png  ${RESULT_TSX_FullTime}/
#cp ${PATH_MSBAS_TSX_FullTime}/COR_Defo_Dem*_Full/baselinePlot_COR_Defo_Dem*_Full.txt.png  ${RESULT_TSX_FullTime}/


#cd ${RESULT_S1}
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_S1} ${Label_1} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_S1} ${Label_1b} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#ExtractMSBAS_profiles.py "${PATH_MSBAS_S1},${PATH_MSBAS_S1}" "${Label_1b},${Label_1}" --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_allML5" --align --utm 
#ExtractMSBAS_profiles.py "${PATH_MSBAS_S1},${PATH_MSBAS_S1}" "${Label_1b},${Label_1}" --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_allML5" --align --utm 
#cd ${CURRENTDIR}

#cd ${RESULT_TSX_defo90}
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_defo90} ${Label_2} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_defo90} ${Label_2b} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#cd ${RESULT_TSX_defo300}
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_defo300} ${Label_3} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_defo300} ${Label_3b} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#cd ${RESULT_TSX_cor90}
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_cor90} ${Label_4} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_cor90} ${Label_4b} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#cd ${RESULT_TSX_cor300}
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_cor300} ${Label_5} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_cor300} ${Label_5b} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#cd ${RESULT_TSX_FullTime}
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_FullTime} ${Label_6} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm
#Plot_Quicklookcompar_MSBAS.py ${PATH_MSBAS_TSX_FullTime} ${Label_6b} --profile $x1 $y1 $x2 $y2 --crop $xmin $xmax $ymin $ymax --utm

cd ${CURRENTDIR}

listmsbasdir="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor300},${PATH_MSBAS_TSX_cor300}"
listmsbaslabel="${Label_1b},${Label_1},${Label_2},${Label_2b},${Label_3},${Label_3b},${Label_4},${Label_4b},${Label_5},${Label_5b}"

listmsbasdircor="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor300},${PATH_MSBAS_TSX_cor300}"
listmsbaslabelcor="${Label_1b},${Label_1},${Label_4},${Label_4b},${Label_5},${Label_5b}"
listmsbasdirdefo="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_defo300}"
listmsbaslabeldefo="${Label_1b},${Label_1},${Label_2},${Label_2b},${Label_3},${Label_3b}"

listmsbasdir90="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor90}"
listmsbaslabel90="${Label_1b},${Label_1},${Label_2},${Label_2b},${Label_4},${Label_4b}"
listmsbasdir90bis="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor90}"
listmsbaslabel90bis="${Label_1b},${Label_1},${Label_2b},${Label_4},${Label_4b}"

listmsbasdir300="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_cor300},${PATH_MSBAS_TSX_cor300}"
listmsbaslabel300="${Label_1b},${Label_1},${Label_3},${Label_3b},${Label_5},${Label_5b}"

listmsbasdirnocoh="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor300}"
listmsbaslabelnocoh="${Label_1b},${Label_1},${Label_2b},${Label_3b},${Label_4b},${Label_5b}"
listmsbasdircohrestr="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor300}"
listmsbaslabelcohrestr="${Label_1b},${Label_1},${Label_2},${Label_3},${Label_4},${Label_5}"

listmsbasdirTSXFull="${PATH_MSBAS_S1},${PATH_MSBAS_S1},${PATH_MSBAS_TSX_FullTime}"
listmsbaslabelTSXFull="${Label_1b},${Label_1},${Label_6b}"


mkdir -p "${RESULT_DIR}/MSBAS"        
mkdir -p "${RESULT_DIR}/MSBAS/cor"    
mkdir -p "${RESULT_DIR}/MSBAS/defo"   
mkdir -p "${RESULT_DIR}/MSBAS/BP90bis"   
mkdir -p "${RESULT_DIR}/MSBAS/BP300"  
mkdir -p "${RESULT_DIR}/MSBAS/nocoh"  
mkdir -p "${RESULT_DIR}/MSBAS/cohrest"
mkdir -p "${RESULT_DIR}/MSBAS/TSXFull"

#cd "${RESULT_DIR}/MSBAS/"
#ExtractMSBAS_profiles.py ${listmsbasdir} ${listmsbaslabel} --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_allML5" --align --utm 
#ExtractMSBAS_profiles.py ${listmsbasdir} ${listmsbaslabel} --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_allML5" --align --utm 
#cd ${CURRENTDIR}
#cd "${RESULT_DIR}/MSBAS/cor"
#ExtractMSBAS_profiles.py ${listmsbasdircor} ${listmsbaslabelcor} --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_corML5" --align --utm 
#ExtractMSBAS_profiles.py ${listmsbasdircor} ${listmsbaslabelcor} --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_corML5" --align --utm 
#cd ${CURRENTDIR}
#cd "${RESULT_DIR}/MSBAS/defo"
#ExtractMSBAS_profiles.py ${listmsbasdirdefo} ${listmsbaslabeldefo} --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_defoML5" --align --utm 
#ExtractMSBAS_profiles.py ${listmsbasdirdefo} ${listmsbaslabeldefo} --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_defoML5" --align --utm 
#cd ${CURRENTDIR}
cd "${RESULT_DIR}/MSBAS/BP90bis"
ExtractMSBAS_profiles.py ${listmsbasdir90bis} ${listmsbaslabel90bis} --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_90ML5_bis" --align --utm 
ExtractMSBAS_profiles.py ${listmsbasdir90bis} ${listmsbaslabel90bis} --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_90ML5_bis" --align --utm 

cd ${CURRENTDIR}
#cd "${RESULT_DIR}/MSBAS/BP300"
#ExtractMSBAS_profiles.py ${listmsbasdir300} ${listmsbaslabel300} --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_300ML5" --align --utm 
#ExtractMSBAS_profiles.py ${listmsbasdir300} ${listmsbaslabel300} --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_300ML5" --align --utm 
#cd ${CURRENTDIR}
#cd "${RESULT_DIR}/MSBAS/nocoh"
#ExtractMSBAS_profiles.py ${listmsbasdirnocoh} ${listmsbaslabelnocoh} --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_nocohML5" --align --utm 
#ExtractMSBAS_profiles.py ${listmsbasdirnocoh} ${listmsbaslabelnocoh} --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_nocohML5" --align --utm 
#cd ${CURRENTDIR}
#cd "${RESULT_DIR}/MSBAS/cohrest"
#ExtractMSBAS_profiles.py ${listmsbasdircohrestr} ${listmsbaslabelcohrestr} --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_cohrestrML5" --align --utm 
#ExtractMSBAS_profiles.py ${listmsbasdircohrestr} ${listmsbaslabelcohrestr} --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_cohrestrML5" --align --utm 
#cd ${CURRENTDIR}
#cd "${RESULT_DIR}/MSBAS/TSXFull"
#ExtractMSBAS_profiles.py ${listmsbasdirTSXFull} ${listmsbaslabelTSXFull} --profile $x1 $y1 $x2 $y2 --mode "UD" --figname "UD_TSXFull" --align --utm 
#ExtractMSBAS_profiles.py ${listmsbasdirTSXFull} ${listmsbaslabelTSXFull} --profile $x1 $y1 $x2 $y2 --mode "EW" --figname "EW_TSXfull" --align --utm 
#cd ${CURRENTDIR}

echo " "
echo "Comparison of Baseline Plots"
echo " "

AllPairsListing1="${RESULT_DIR}/SM/allPairsListing_1.txt"
AllPairsListing2="${RESULT_DIR}/SM/allPairsListing_2.txt"
AllPairsListing3="${RESULT_DIR}/SM/allPairsListing_3.txt"
AllPairsListing4="${RESULT_DIR}/SM/allPairsListing_4.txt"


#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "S1A164Full" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt "S1A164cohth" ${AllPairsListing1} ${RESULTDIR_1}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "S1D54Full" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt "S1D54cohth" ${AllPairsListing2} ${RESULTDIR_1}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full_90D" ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3.txt "TSXA104cohth_90D" ${AllPairsListing3} ${RESULTDIR_2}
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full_90D" ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4.txt "TSXD20cohth_90D" ${AllPairsListing4} ${RESULTDIR_2}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104Full_90C" ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3.txt "TSXA104cohth_90C" ${AllPairsListing3} ${RESULTDIR_3}
#CompareBS_MSBAS.sh ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20Full_90C" ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4.txt "TSXD20cohth_90C" ${AllPairsListing4} ${RESULTDIR_3}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full_300D" ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3.txt "TSXA104cohth_300D" ${AllPairsListing3} ${RESULTDIR_4}
#CompareBS_MSBAS.sh ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full_300D" ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4.txt "TSXD20cohth_300D" ${AllPairsListing4} ${RESULTDIR_4}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104Full_300C" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3.txt "TSXA104cohth_300C" ${AllPairsListing3} ${RESULTDIR_5}
#CompareBS_MSBAS.sh ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20Full_300C" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4.txt "TSXD20cohth_300C"  ${AllPairsListing4} ${RESULTDIR_5}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full_90D" ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104Full_90C" ${AllPairsListing3} ${RESULTDIR_6}
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full_90D" ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20Full_90C" ${AllPairsListing4} ${RESULTDIR_6}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full_300D" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104Full_300C" ${AllPairsListing3} ${RESULTDIR_7}
#CompareBS_MSBAS.sh ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full_300D" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20Full_300C" ${AllPairsListing4} ${RESULTDIR_7}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full_90D" ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full_300D" ${AllPairsListing3} ${RESULTDIR_8}
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full_90D" ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full_300D" ${AllPairsListing4} ${RESULTDIR_8}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3_Full.txt "TSXA104Full_90C" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104Full_300C" ${AllPairsListing3} ${RESULTDIR_9}
#CompareBS_MSBAS.sh ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4_Full.txt "TSXD20Full_90C"  ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20Full_300C" ${AllPairsListing4} ${RESULTDIR_9}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3.txt  "TSX104cohth_90D" ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3.txt  "TSX104coth_90C" ${AllPairsListing3} ${RESULTDIR_10}
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "TSXD20cohth_90D" ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4.txt  "TSXD20coth_90C" ${AllPairsListing4} ${RESULTDIR_10}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3.txt  "TSX104coth_300D" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3.txt  "TSX104coth_300C" ${AllPairsListing3} ${RESULTDIR_11}
#CompareBS_MSBAS.sh ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "TSXD20coth_300D" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4.txt  "TSXD20coth_300C" ${AllPairsListing4} ${RESULTDIR_11}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3.txt  "TSX104coth_90D" ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3.txt  "TSX104coth_300D" ${AllPairsListing3} ${RESULTDIR_12}
#CompareBS_MSBAS.sh ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "TSXD20coth_90D" ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "TSXD20coth_300D" ${AllPairsListing4} ${RESULTDIR_12}
#
#CompareBS_MSBAS.sh ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3.txt "TSXA104cohth_90C" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3.txt  "TSX104coth_300C" ${AllPairsListing3} ${RESULTDIR_13}
#CompareBS_MSBAS.sh ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4.txt "TSXD20cohth_90C"  ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4.txt  "TSXD20coth_300C" ${AllPairsListing4} ${RESULTDIR_13}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1A164Full" ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full_90D" ${AllPairsListing3} ${RESULTDIR_14}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1D54Full"  ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full_90D" ${AllPairsListing4} ${RESULTDIR_14}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1A164Full" ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full_300D" ${AllPairsListing3} ${RESULTDIR_15}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1D54Full"  ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full_300D" ${AllPairsListing4} ${RESULTDIR_15}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1A164Full" ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104Full_90C" ${AllPairsListing3} ${RESULTDIR_16}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1D54Full"  ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20Full_90C" ${AllPairsListing4} ${RESULTDIR_16}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1A164Full" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104Full_300C" ${AllPairsListing3} ${RESULTDIR_17}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1D54Full"  ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20Full_300C" ${AllPairsListing4} ${RESULTDIR_17}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1A164Full" ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend3.txt  "TSX104coth_90D"  ${AllPairsListing3} ${RESULTDIR_18}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1D54Full"  ${RESULT_TSX_defo90}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "TSXD20coth_90D"  ${AllPairsListing4} ${RESULTDIR_18}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1A164Full" ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend3.txt  "TSX104coth_300D" ${AllPairsListing3} ${RESULTDIR_19}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1D54Full"  ${RESULT_TSX_defo300}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "TSXD20coth_300D" ${AllPairsListing4} ${RESULTDIR_19}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1A164Full" ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104coth_90C" ${AllPairsListing3} ${RESULTDIR_20}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1D54Full"  ${RESULT_TSX_cor90}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20coth_90C" ${AllPairsListing4} ${RESULTDIR_20}
#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1A164Full" ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem3_Full.txt "TSX104coth_300C" ${AllPairsListing3} ${RESULTDIR_21}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1D54Full"  ${RESULT_TSX_cor300}/restrictedPairSelection_COR_Defo_Dem4_Full.txt "TSXD20coth_300C" ${AllPairsListing4} ${RESULTDIR_21}
#


echo " "
echo "Comparison of Maps and computation of the residuals"
echo " "
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_1} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_S1} ${Label_1b}
#
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_2} ${PATH_MSBAS_TSX_defo90} ${Label_2} ${PATH_MSBAS_TSX_defo90} ${Label_2b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_3} ${PATH_MSBAS_TSX_cor90}  ${Label_3} ${PATH_MSBAS_TSX_cor90}  ${Label_3b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_4} ${PATH_MSBAS_TSX_defo300} ${Label_4} ${PATH_MSBAS_TSX_defo300} ${Label_4b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_5} ${PATH_MSBAS_TSX_cor300}  ${Label_5} ${PATH_MSBAS_TSX_cor300}  ${Label_5b}
#
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_6} ${PATH_MSBAS_TSX_defo90} ${Label_2}  ${PATH_MSBAS_TSX_cor90}  ${Label_3}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_7} ${PATH_MSBAS_TSX_defo300} ${Label_4} ${PATH_MSBAS_TSX_cor300}  ${Label_5}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_8} ${PATH_MSBAS_TSX_defo90} ${Label_2} ${PATH_MSBAS_TSX_defo300} ${Label_4}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_9} ${PATH_MSBAS_TSX_cor90}  ${Label_3} ${PATH_MSBAS_TSX_cor300}  ${Label_5}
#
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_10} ${PATH_MSBAS_TSX_defo90} ${Label_2b}  ${PATH_MSBAS_TSX_cor90}  ${Label_3b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_11} ${PATH_MSBAS_TSX_defo300} ${Label_4b} ${PATH_MSBAS_TSX_cor300}  ${Label_5b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_12} ${PATH_MSBAS_TSX_defo90} ${Label_2b} ${PATH_MSBAS_TSX_defo300} ${Label_4b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_13} ${PATH_MSBAS_TSX_cor90}  ${Label_3b} ${PATH_MSBAS_TSX_cor300}  ${Label_5b}
#
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_14} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_TSX_defo90} ${Label_2} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_15} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_TSX_cor90}  ${Label_3} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_16} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_TSX_defo300} ${Label_4}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_17} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_TSX_cor300}  ${Label_5}
#
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_18} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_TSX_defo90} ${Label_2b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_19} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_TSX_cor90}  ${Label_3b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_20} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_TSX_defo300} ${Label_4b}
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_21} ${PATH_MSBAS_S1} ${Label_1} ${PATH_MSBAS_TSX_cor300}  ${Label_5b}
#
#echo " "
#echo "Comparison of Time Series"
#echo " "
#
#CompareTS_EWUD.sh ${RESULTDIR_1}  "${PATH_MSBAS_S1},${PATH_MSBAS_S1}" "${Label_1},${Label_1b}" ${PointListS1} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_2}  "${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo90}"   "${Label_2},${Label_2b}"  ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_3}  "${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor90}"     "${Label_3},${Label_3b}"  ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_4}  "${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_defo300}" "${Label_4},${Label_4b}"  ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_5}  "${PATH_MSBAS_TSX_cor300},${PATH_MSBAS_TSX_cor300}"   "${Label_5},${Label_5b}"  ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_6}  "${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_cor90}"    "${Label_2},${Label_3}"   ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_7}  "${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_cor300}"  "${Label_4},${Label_5}"   ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_8}  "${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo300}"  "${Label_2},${Label_4}"   ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_9}  "${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor300}"    "${Label_3},${Label_5}"   ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_10} "${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_cor90}"    "${Label_2b},${Label_3b}" ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_11} "${PATH_MSBAS_TSX_defo300},${PATH_MSBAS_TSX_cor300}"  "${Label_4b},${Label_5b}" ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_12} "${PATH_MSBAS_TSX_defo90},${PATH_MSBAS_TSX_defo300}"  "${Label_2b},${Label_4b}" ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_13} "${PATH_MSBAS_TSX_cor90},${PATH_MSBAS_TSX_cor300}"    "${Label_3b},${Label_5b}" ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_14} "${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo90}"  "${Label_1},${Label_2}"  ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_15} "${PATH_MSBAS_S1},${PATH_MSBAS_TSX_cor90}"   "${Label_1},${Label_3}"  ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_16} "${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo300}" "${Label_1},${Label_4}"  ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_17} "${PATH_MSBAS_S1},${PATH_MSBAS_TSX_cor300}"  "${Label_1},${Label_5}"  ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_18} "${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo90}"  "${Label_1},${Label_2b}" ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_19} "${PATH_MSBAS_S1},${PATH_MSBAS_TSX_cor90}"   "${Label_1},${Label_3b}" ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_20} "${PATH_MSBAS_S1},${PATH_MSBAS_TSX_defo300}" "${Label_1},${Label_4b}" ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh ${RESULTDIR_21} "${PATH_MSBAS_S1},${PATH_MSBAS_TSX_cor300}"  "${Label_1},${Label_5b}" ${PointListTSX} ${EVENTSDummy}
#
#
#
#CompareTS_EWUD.sh "${RESULT_DIR}/MSBAS"         ${listmsbasdir} ${listmsbaslabel} ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh "${RESULT_DIR}/MSBAS/cor"     ${listmsbasdircor} ${listmsbaslabelcor} ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh "${RESULT_DIR}/MSBAS/defo"    ${listmsbasdirdefo} ${listmsbaslabeldefo} ${PointListTSX} ${EVENTSDummy}
CompareTS_EWUD.sh "${RESULT_DIR}/MSBAS/BP90_bis"    ${listmsbasdir90bis} ${listmsbaslabel90bis} ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh "${RESULT_DIR}/MSBAS/BP300"   ${listmsbasdir300} ${listmsbaslabel300} ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh "${RESULT_DIR}/MSBAS/nocoh"   ${listmsbasdirnocoh} ${listmsbaslabelnocoh} ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh "${RESULT_DIR}/MSBAS/cohrest" ${listmsbasdircohrestr} ${listmsbaslabelcohrestr} ${PointListTSX} ${EVENTSDummy}
#CompareTS_EWUD.sh "${RESULT_DIR}/MSBAS/TSXFull" ${listmsbasdirTSXFull} ${listmsbaslabelTSXFull} ${PointListTSX} ${EVENTSDummy}
#
#