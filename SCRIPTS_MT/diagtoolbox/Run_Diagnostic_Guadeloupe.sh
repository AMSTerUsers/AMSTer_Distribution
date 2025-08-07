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
#
# New in Distro V 1.0 20250114  set up
# New in Distro V 1.1 20250128  Configure for Guadeloupe TSX data
# New in Distro V 1.2 20250213  Cosmetic
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Feb 13, 2025" 
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo " "

CURRENTDIR=$(pwd)

STARTDATE=$1
ENDDATE=$2

#################### HARD CODED  #########################################
REGION="GUADELOUPE"

## DataPATHs

# SAR_CSL
PATH_CSL_S1='/Volumes/hp-1650-Data_Share1/SAR_CSL/S1'
PATH_CSL_TSX='/Volumes/hp-1650-Data_Share1/SAR_CSL/TSX'

#SAR_SM
PATH_SM='/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/GUADELOUPE'

# SAR_MASSPROCESS
PATH_MASSPROCESS_MODE1='/Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/GUADELOUPE_A_164/SMNoCrop_SM_20190622_Zoom1_ML2/'
PATH_MASSPROCESS_MODE2='/Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/GUADELOUPE_D_54/SMNoCrop_SM_20200410_Zoom1_ML2/'
PATH_MASSPROCESS_MODE3='/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_A104/SMNoCrop_SM_20240204_Zoom1_ML5'
PATH_MASSPROCESS_MODE4='/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_D20/SMNoCrop_SM_20240724_Zoom1_ML5'
#PATH_MASSPROCESS_MODE3='/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_A104/SMNoCrop_SM_20240204_Zoom1_ML24'
#PATH_MASSPROCESS_MODE4='/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_D20/SMNoCrop_SM_20240724_Zoom1_ML24'
#PATH_MASSPROCESS_MODE3='/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_A104/SMNoCrop_SM_20240204_Zoom1_ML2'
#PATH_MASSPROCESS_MODE4='/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_D20/SMNoCrop_SM_20240724_Zoom1_ML2'


# MSBAS
PATH_MSBAS_S1='/Volumes/hp-D3602-Data_RAID5/MSBAS/_Guadeloupe_S1_Auto_90m_150days'
#PATH_MSBAS_TSX_defo='/Volumes/hp-D3602-Data_RAID5/MSBAS/_Guadeloupe_TSX_Auto_300m_150days_DefoInterpolx2Detrend_restrict20231201_restrictcoh0325_NEW'
PATH_MSBAS_TSX_defo='_Guadeloupe_TSX_Auto_90m_150days_DefoInterpolx2Detrend_restrict20231201_restrictcoh0325_5m'
#PATH_MSBAS_TSX_cor='/Volumes/hp-D3602-Data_RAID5/MSBAS/_Guadeloupe_TSX_Auto_300m_150days_COR_Defo_Dem_restrict20231201_restrictcoh0325_NEW'
PATH_MSBAS_TSX_cor='_Guadeloupe_TSX_Auto_90m_150days_COR_Defo_Dem_restrict20231201_restrictcoh0325_5m'
PATH_MSBAS_Combi='/Volumes/hp-D3602-Data_RAID5/MSBAS/_Guadeloupe_S1_TSX_Auto_300m_150days'
PATH_MSBAS_TSX_defo_30m='/Volumes/hp-D3602-Data_RAID5/MSBAS/_Guadeloupe_TSX_Auto_300m_150days_DefoInterpolx2Detrend_restrict20231201_restrictcoh015_NEW_30m'

# Label MSBAS
Label_1="_Auto_3_0.04_Guadeloupe"
Label_1b="_Auto_3_0.04_Guadeloupe_NoCohThresh"
#Label_2="_Auto_3_0.04_Guadeloupe"
#Label_2b="_Auto_3_0.04_Guadeloupe_NoCohThresh"
Label_2="_Auto_2_0.04_Guadeloupe"
Label_2b="_Auto_2_0.04_Guadeloupe_NoCohThresh"
Label_3="_Auto_2_0.04_Guadeloupe"
Label_3b="_Auto_2_0.04_Guadeloupe_NoCohThresh"
Label_4="_Auto_3_0.04_Guadeloupe"
Label_4b="_Auto_3_0.04_Guadeloupe_NoCohThresh"

## DEM 
DEM_SRTM="/Users/delphine/Documents/Guadeloupe/Data/DEM/SRTM/Guadeloupe"
DEM_HR="/Users/delphine/Documents/Guadeloupe/Data/DEM/Lidar/ENVI/Guadeloupe_SRTM_Lidar"
DEM_HR_CSL="/Users/delphine/Documents/Guadeloupe/Data/DEM/Lidar/CSL/Guadeloupe_SRTM_Lidar_flip0.bil"
DEM_HR_CSL_1m="/Users/delphine/Documents/Guadeloupe/Data/DEM/Lidar/CSL/Litto3D_SHOM_Guadeloupe_2016_Lidar_MNT1m_LonLat.dem_flip0.bil"

## Other File infos
ALL_MODESLIST="/Users/delphine/Documents/Guadeloupe/test/All_modes_list.txt"

REJECT_MODE_TSX="/Users/delphine/Documents/Guadeloupe/test/reject_TSX_modes_list.txt"
REJECT_MODE_S1="/Users/delphine/Documents/Guadeloupe/test/reject_S1_modes_list.txt"

BTBP="/Users/delphine/Documents/Guadeloupe/test/BTBP_Infos.txt"

KML_listfile="/Users/delphine/Documents/Guadeloupe/test/kml_list.txt"

CohTh_dir="/Users/delphine/Documents/Guadeloupe/test/"

PointListTSX="/Users/delphine/Documents/Guadeloupe/test/List_DoubleDiff_EW_UD_Guadeloupe_TSX.txt"  
PointListS1="/Users/delphine/Documents/Guadeloupe/test/List_DoubleDiff_EW_UD_Guadeloupe.txt"  

EVENTSDummy='/Users/delphine/Documents/Guadeloupe/Data/database_coerupt.txt'

## Result writing
RESULT_DIR="/Users/delphine/Documents/Guadeloupe/test/DIAGNOSTIC_3"

RESULT_MSBAS_COMP=${RESULT_DIR}/MSBAS/_COMP
RESULT_S1="${RESULT_DIR}/MSBAS/S1"
RESULT_TSX_cor="${RESULT_DIR}/MSBAS/TSX_cor"
RESULT_TSX_defo="${RESULT_DIR}/MSBAS/TSX_defo"
RESULT_Combi="${RESULT_DIR}/MSBAS/Combi"

RESULTDIR_1="${RESULT_MSBAS_COMP}/01_S1_cohth"
RESULTDIR_2="${RESULT_MSBAS_COMP}/02_TSXdefo_cohth"
RESULTDIR_3="${RESULT_MSBAS_COMP}/03_TSXcor_cohth"
RESULTDIR_4="${RESULT_MSBAS_COMP}/04_S1TSXdefo_cohth"
RESULTDIR_5="${RESULT_MSBAS_COMP}/05_S1_S1TSXdefo"
RESULTDIR_6="${RESULT_MSBAS_COMP}/06_TSXdefo_TSXcor"
RESULTDIR_7="${RESULT_MSBAS_COMP}/07_TSXdefo_S1TSXdefo"
RESULTDIR_8="${RESULT_MSBAS_COMP}/08_S1_S1TSXdefo_cohth"
RESULTDIR_9="${RESULT_MSBAS_COMP}/09_TSXdefo_TSXcor_cohth"
RESULTDIR_10="${RESULT_MSBAS_COMP}/10_TSXdefo_S1TSXdefo_cohth"



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
mkdir -p ${RESULT_TSX_cor}
mkdir -p ${RESULT_TSX_defo}
mkdir -p ${RESULT_Combi}
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
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_TSX_cor}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_TSX_defo}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_Combi}"
echo " "

cp ${PATH_MSBAS_S1}/restrictedPairSelection_DefoInterpolx2Detrend*.txt  ${RESULT_S1}
#cp ${PATH_MSBAS_S1}/DefoInterpolx2Detrend*/restrictedPairSelection_DefoInterpolx2Detrend*.txt  ${RESULT_S1}
cp ${PATH_MSBAS_TSX_cor}/restrictedPairSelection_COR_Defo_Dem1.txt  ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem3.txt 
cp ${PATH_MSBAS_TSX_cor}/restrictedPairSelection_COR_Defo_Dem2.txt  ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem4.txt 
cp ${PATH_MSBAS_TSX_cor}/COR_Defo_Dem1_Full/restrictedPairSelection_COR_Defo_Dem1_Full.txt  ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem3_Full.txt 
cp ${PATH_MSBAS_TSX_cor}/COR_Defo_Dem2_Full/restrictedPairSelection_COR_Defo_Dem2_Full.txt  ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem4_Full.txt 
cp ${PATH_MSBAS_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend3.txt 
cp ${PATH_MSBAS_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend4.txt 
cp ${PATH_MSBAS_TSX_defo}/DefoInterpolx2Detrend1_Full/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt 
cp ${PATH_MSBAS_TSX_defo}/DefoInterpolx2Detrend2_Full/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt 
cp ${PATH_MSBAS_Combi}/restrictedPairSelection_DefoInterpolx2Detrend*.txt  ${RESULT_Combi}
cp ${PATH_MSBAS_Combi}/DefoInterpolx2Detrend*_Full/restrictedPairSelection_DefoInterpolx2Detrend*_Full.txt  ${RESULT_Combi}

echo " "
echo "Compare CSL and MSBAS databases"
echo " "

#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_S1} ${STARTDATE} ${ENDDATE} ${RESULT_S1} ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_TSX} > ${RESULT_S1}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_TSX_cor} ${STARTDATE} ${ENDDATE} ${RESULT_TSX_cor}  ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1}> ${RESULT_TSX_cor}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_TSX_defo} ${STARTDATE} ${ENDDATE} ${RESULT_TSX_defo}  ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1}> ${RESULT_TSX_defo}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_Combi} ${STARTDATE} ${ENDDATE} ${RESULT_Combi}  ${ALL_MODESLIST}-event ${EVENTSDummy}> ${RESULT_Combi}/logfile_checkimage.txt #2>&1


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
    Analyse_AllPairslisting_data.py --input_file ${destination_file} --BPmax ${BPmax} --BTmax ${BTmax} --startdate ${STARTDATEANALYSE} --enddate ${ENDDATEANALYSE} --gap ${GAPINDAYS} --nbr ${nbr} --BP2 ${BPmax2} --BT2 ${BTmax2} --datechange ${Datechange} > ${RESULT_DIR}/SM/logfile_${k}.txt 2>&1

##COH    
 	source_cohfile="${PATH_MSBAS_Combi}/DefoInterpolx2Detrend${k}_Full/Coh_Table_DefoInterpolx2Detrend${k}.txt" 
 	destination_cohfile="${RESULT_Combi}/"
 	cp "${source_cohfile}" "${destination_cohfile}"
    echo "File ${source_cohfile} copied to: ${destination_cohfile}"

done

exit

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
		eval "path=\$PATH_MASSPROCESS_MODE$k"  # Récupère la valeur de PATH_MASSPROCESS_MODE2 si k=2
		cd ${path}/Geocoded/Coh 
		echo $(pwd)
		echo "Compute Coh on kml ${filenamekml}.kml"
		Baseline_Coh_Table.sh "$ligne"
		cd ${CURRENTDIR}
		if [ -f "${path}/Geocoded/Coh/${filenamesource_Baselinecohtable}" ]; then
			## Utiliser la référence indirecte pour accéder à la variable dynamique
			eval "path=\$PATH_MASSPROCESS_MODE$k"  # Récupère la valeur de PATH_MASSPROCESS_MODE2 si k=2
			cp "${path}/Geocoded/Coh/${filenamesource_Baselinecohtable}" "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}"
			echo "copy file :${path}/Geocoded/Coh/${filenamesource_Baselinecohtable} to ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" 
		fi
		if [ -f "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" ]; then
			Cohth_file=${CohTh_dir}"Coh_th_Info_"${filenamekml}".txt"
			if [ -f "${Cohth_file}" ]; then
    			CohTh=$(awk -v k="$k" '$1==k {print $2}' ${Cohth_file})
    			echo "Coherence Threshold : ${CohTh}"
				Analyse_BaselineCoh_data.py ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable} ${CohTh} > ${RESULT_DIR}/Coh/logfile_${filenamekml}_${k}.txt 2>&1
				echo "Analyse BSC done"
			fi
		fi
	done < "${KML_listfile}"

done

exit

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
Compute_Stats_graph "${RESULT_S1}"
Compute_Stats_graph "${RESULT_TSX_cor}"
Compute_Stats_graph "${RESULT_TSX_defo}"
Compute_Stats_graph "${RESULT_Combi}"

echo " "
echo "Comparison of Baseline Plots"
echo " "

AllPairsListing1="${RESULT_DIR}/SM/allPairsListing_1.txt"
AllPairsListing2="${RESULT_DIR}/SM/allPairsListing_2.txt"
AllPairsListing3="${RESULT_DIR}/SM/allPairsListing_3.txt"
AllPairsListing4="${RESULT_DIR}/SM/allPairsListing_4.txt"


#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "S1A164Full" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt "S1A164cohth" ${AllPairsListing1} ${RESULTDIR_1}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "S1D54Full" ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt "S1D54cohth" ${AllPairsListing2} ${RESULTDIR_1}

CompareBS_MSBAS.sh ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full" ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend3.txt "TSXA104cohth" ${AllPairsListing3} ${RESULTDIR_2}
CompareBS_MSBAS.sh ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full" ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend4.txt "TSXD20cohth" ${AllPairsListing4} ${RESULTDIR_2}

CompareBS_MSBAS.sh ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem3_Full.txt  "TSX104Full" ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem3.txt "TSXA104cohth" ${AllPairsListing3} ${RESULTDIR_3}
CompareBS_MSBAS.sh ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem4_Full.txt  "TSXD20Full" ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem4.txt "TSXD20cohth" ${AllPairsListing4} ${RESULTDIR_3}

#CompareBS_MSBAS.sh ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "S1A164Full" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend1.txt "S1A164cohth" ${AllPairsListing1} ${RESULTDIR_4}
#CompareBS_MSBAS.sh ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "S1D54Full" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend2.txt "S1D54cohth" ${AllPairsListing2} ${RESULTDIR_4}
#CompareBS_MSBAS.sh ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend3.txt "TSXA104cohth" ${AllPairsListing3} ${RESULTDIR_4}
#CompareBS_MSBAS.sh ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend4.txt "TSXD20cohth" ${AllPairsListing4} ${RESULTDIR_4}

#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "S1S1A164Full" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend1_Full.txt  "combiS1A164Full" ${AllPairsListing1} ${RESULTDIR_5}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "S1S1D54Full"  ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend2_Full.txt  "combiS1D54Full"  ${AllPairsListing2} ${RESULTDIR_5}

CompareBS_MSBAS.sh ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104Full" ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem3_Full.txt "TSX104Full" ${AllPairsListing3} ${RESULTDIR_6}
CompareBS_MSBAS.sh ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20Full" ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem4_Full.txt "TSXD20Full" ${AllPairsListing4} ${RESULTDIR_6}

#CompareBS_MSBAS.sh ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt  "TSX104combiFull" ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend3_Full.txt "TSXA104defoFull" ${AllPairsListing3} ${RESULTDIR_7}
#CompareBS_MSBAS.sh ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt  "TSXD20combiFull" ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend4_Full.txt "TSXD20defoFull" ${AllPairsListing4} ${RESULTDIR_7}

#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1S1A164" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "combiS1A164" ${AllPairsListing1} ${RESULTDIR_8}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "S1S1D54" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend2.txt  "combiS1D54" ${AllPairsListing2} ${RESULTDIR_8}

CompareBS_MSBAS.sh ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend3.txt  "TSX104defocohth" ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem3.txt "TSX104corcohth" ${AllPairsListing3} ${RESULTDIR_9}
CompareBS_MSBAS.sh ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "TSXD20defocohth" ${RESULT_TSX_cor}/restrictedPairSelection_COR_Defo_Dem4.txt "TSXD20corcohth" ${AllPairsListing4} ${RESULTDIR_9}

#CompareBS_MSBAS.sh ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend3.txt  "TSX104combicohth" ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend3.txt "TSXA104defocohth" ${AllPairsListing3} ${RESULTDIR_10}
#CompareBS_MSBAS.sh ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "TSXD20combicohth" ${RESULT_TSX_defo}/restrictedPairSelection_DefoInterpolx2Detrend4.txt "TSXD20defocohth" ${AllPairsListing4} ${RESULTDIR_10}


echo " "
echo "Comparison of Maps and computation of the residuals"
echo " "
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_1} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_S1} ${Label_1b} 
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_2} ${PATH_MSBAS_TSX_defo} ${Label_2} ${PATH_MSBAS_TSX_defo} ${Label_2b} 
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_3} ${PATH_MSBAS_TSX_cor}  ${Label_3} ${PATH_MSBAS_TSX_cor} ${Label_3b} 
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_4} ${PATH_MSBAS_Combi}  ${Label_4} ${PATH_MSBAS_Combi} ${Label_4b} 
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_5} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_Combi} ${Label_4} 
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_6} ${PATH_MSBAS_TSX_defo} ${Label_2} ${PATH_MSBAS_TSX_cor} ${Label_3} 
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_7} ${PATH_MSBAS_TSX_defo}  ${Label_2} ${PATH_MSBAS_Combi} ${Label_4} 
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_8} ${PATH_MSBAS_S1}  ${Label_4b} ${PATH_MSBAS_Combi} ${Label_4b} 
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_9} ${PATH_MSBAS_TSX_defo} ${Label_2b} ${PATH_MSBAS_TSX_cor} ${Label_3b}
Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_10} ${PATH_MSBAS_TSX_defo}  ${Label_2b} ${PATH_MSBAS_Combi} ${Label_4b}

echo " "
echo "Comparison of Time Series"
echo " "
CompareTS_EWUD.sh ${RESULTDIR_1} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_S1} ${Label_1b}  ${PointListS1}
CompareTS_EWUD.sh ${RESULTDIR_2} ${PATH_MSBAS_TSX_defo} ${Label_2} ${PATH_MSBAS_TSX_defo} ${Label_2b} ${PointListTSX}
CompareTS_EWUD.sh ${RESULTDIR_3} ${PATH_MSBAS_TSX_cor}  ${Label_3} ${PATH_MSBAS_TSX_cor} ${Label_3b}  ${PointListTSX}
CompareTS_EWUD.sh ${RESULTDIR_4} ${PATH_MSBAS_Combi}  ${Label_4} ${PATH_MSBAS_Combi} ${Label_4b}  ${PointListTSX}
CompareTS_EWUD.sh ${RESULTDIR_5} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_Combi} ${Label_4}  ${PointListS1}
CompareTS_EWUD.sh ${RESULTDIR_6} ${PATH_MSBAS_TSX_defo} ${Label_2} ${PATH_MSBAS_TSX_cor} ${Label_3}  ${PointListTSX}
CompareTS_EWUD.sh ${RESULTDIR_7} ${PATH_MSBAS_TSX_defo}  ${Label_2} ${PATH_MSBAS_Combi} ${Label_4}  ${PointListTSX}
CompareTS_EWUD.sh ${RESULTDIR_8} ${PATH_MSBAS_S1}  ${Label_4b} ${PATH_MSBAS_Combi} ${Label_4b}  ${PointListS1}
CompareTS_EWUD.sh ${RESULTDIR_9} ${PATH_MSBAS_TSX_defo} ${Label_2b} ${PATH_MSBAS_TSX_cor} ${Label_3b} ${PointListTSX}
CompareTS_EWUD.sh ${RESULTDIR_10} ${PATH_MSBAS_TSX_defo}  ${Label_2b} ${PATH_MSBAS_Combi} ${Label_4b} ${PointListTSX}
