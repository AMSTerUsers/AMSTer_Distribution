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
# New in Distro V 1.1 20250211  Configure for Reunion ALOS + S1 data
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Feb 11, 2025" 
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo " "

CURRENTDIR=$(pwd)

STARTDATE=$1
ENDDATE=$2

#################### HARD CODED  #########################################
REGION="PF"

## DataPATHs

# SAR_CSL
PATH_CSL_S1='/Volumes/hp1660/SAR_CSL/S1'
PATH_CSL='/Volumes/hp1660/SAR_CSL/ALOS2'

#SAR_SM
PATH_SM='/Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/PF'

# SAR_MASSPROCESS
PATH_MASSPROCESS_MODE1='/Volumes/D3610/SAR_MASSPROCESS/S1/PF_IW_A_144/SMNoCrop_SM_20180831_Zoom1_ML2'
PATH_MASSPROCESS_MODE2='/Volumes/D3610/SAR_MASSPROCESS/S1/PF_IW_D_151/SMNoCrop_SM_20200622_Zoom1_ML2'
PATH_MASSPROCESS_MODE3='/Volumes/D3610/SAR_MASSPROCESS/S1/PF_SM_A_144/SMCrop_SM_20190808_Reunion_-21.41--20.85_55.2-55.85_Zoom1_ML8'
PATH_MASSPROCESS_MODE4='/Volumes/D3610/SAR_MASSPROCESS/S1/PF_SM_D_151/SMCrop_SM_20181013_Reunion_-21.41--20.85_55.2-55.85_Zoom1_ML8'
PATH_MASSPROCESS_MODE5='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_3987_L_D/SMNoCrop_SM_20210530_Zoom1_ML8'
PATH_MASSPROCESS_MODE6='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_3992_L_D/SMNoCrop_SM_20211026_Zoom1_ML8'
PATH_MASSPROCESS_MODE7='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_3997_L_D/SMNoCrop_SM_20150820_Zoom1_ML8'
PATH_MASSPROCESS_MODE8='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4002_L_D/SMNoCrop_SM_20221001_Zoom1_ML8'
PATH_MASSPROCESS_MODE9='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4008_L_D/SMNoCrop_SM_20220411_Zoom1_ML8'
PATH_MASSPROCESS_MODE10='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4014_L_D/SMNoCrop_SM_20221102_Zoom1_ML8'
PATH_MASSPROCESS_MODE11='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4020_L_D/SMNoCrop_SM_20210917_Zoom1_ML8'
PATH_MASSPROCESS_MODE12='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4034_R_D/SMNoCrop_SM_20220809_Zoom1_ML8'
PATH_MASSPROCESS_MODE13='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4041_R_D/SMNoCrop_SM_20211028_Zoom1_ML8'
PATH_MASSPROCESS_MODE14='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4048_R_D/SMNoCrop_SM_20190831_Zoom1_ML8'
PATH_MASSPROCESS_MODE15='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4056_R_D/SMNoCrop_SM_20211018_Zoom1_ML8'
PATH_MASSPROCESS_MODE16='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4064_R_D/SMNoCrop_SM_20230816_Zoom1_ML8'
PATH_MASSPROCESS_MODE17='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4073_R_D/SMNoCrop_SM_20230728_Zoom1_ML8'
PATH_MASSPROCESS_MODE18='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_4082_R_D/SMNoCrop_SM_20220807_Zoom1_ML8'
PATH_MASSPROCESS_MODE19='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6724_R_A/SMNoCrop_SM_20221017_Zoom1_ML8'
PATH_MASSPROCESS_MODE20='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6733_R_A/SMNoCrop_SM_20211013_Zoom1_ML8'
PATH_MASSPROCESS_MODE21='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6742_R_A/SMNoCrop_SM_20230825_Zoom1_ML8'
PATH_MASSPROCESS_MODE22='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6749_R_A/SMNoCrop_SM_20230806_Zoom1_ML8'
PATH_MASSPROCESS_MODE23='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6757_R_A/SMNoCrop_SM_20230131_Zoom1_ML8'
PATH_MASSPROCESS_MODE24='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6764_R_A/SMNoCrop_SM_20210603_Zoom1_ML8'
PATH_MASSPROCESS_MODE25='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6778_L_A/SMNoCrop_SM_20230227_Zoom1_ML8'
PATH_MASSPROCESS_MODE26='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6784_L_A/SMNoCrop_SM_20230614_Zoom1_ML8'
PATH_MASSPROCESS_MODE27='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6790_L_A/SMNoCrop_SM_20211210_Zoom1_ML8'
PATH_MASSPROCESS_MODE28='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6796_L_A/SMNoCrop_SM_20230827_Zoom1_ML8'
PATH_MASSPROCESS_MODE29='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6801_L_A/SMNoCrop_SM_20221018_Zoom1_ML8'
PATH_MASSPROCESS_MODE30='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6806_L_A/SMNoCrop_SM_20231207_Zoom1_ML8'
PATH_MASSPROCESS_MODE31='/Volumes/hp1660/SAR_MASSPROCESS/ALOS2/PF_6811_L_A/SMNoCrop_SM_20230506_Zoom1_ML8'

# MSBAS
PATH_MSBAS_S1='/Volumes/hp-D3602-Data_RAID5/MSBAS/_PF_S1_Auto_90m_70_50days'
PATH_MSBAS_ALOS='/Volumes/hp-D3602-Data_RAID5/MSBAS/_PF_ALOS2_Auto'
PATH_MSBAS_ALOSmac='/Volumes/hp-D3602-Data_RAID5/MSBAS/_PF_ALOS2_Auto_Mac'
PATH_MSBAS_Combi='/Volumes/hp-D3602-Data_RAID5/MSBAS/_PF_ALOS2_S1_Auto'

# Label MSBAS
Label_1="_Auto_2_0.04_PF"
Label_1b="_Auto_1_0.06_PF_3D"
Label_2="_Auto_2_0.04_PF"
Label_2b="_Auto_2_0.04_PF_2D"
Label_3="_Auto_2_0.04_PF"
Label_3b="_Auto_2_0.04_PF_2D"
Label_4="_Auto_2_0.04_PF"
#Label_4b=""


## DEM 
DEM_SRTM="/Users/delphine/SAR/AMSTerLocalProcessings/DATA/DEM/ReunionCorrGeoid"

## Other File infos
ALL_MODESLIST="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/All_modes_list.txt"

REJECT_MODE="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/reject_modes_list.txt"
REJECT_MODE_S1="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/reject_modes_listS1.txt"
REJECT_MODE_ALOS="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/reject_modes_listALOS.txt"

BTBP="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/BTBP_Infos.txt"

KML_listfile_all="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/kml_list_all.txt"
KML_listfile="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/kml_list_coh.txt"

CohTh_dir="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/"

PointList="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/List_DoubleDiff_EW_UD_PF.txt"  

EVENTSDummy='/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/database_coerupt.txt'

## Result writing
RESULT_DIR="/Users/delphine/Documents/Projets/2024/Projet_SPT_Piton/test/DIAGNOSTIC2"

RESULT_MSBAS_COMP=${RESULT_DIR}/MSBAS/_COMP
RESULT_S1="${RESULT_DIR}/MSBAS/S1"
RESULT_ALOS="${RESULT_DIR}/MSBAS/ALOS"
RESULT_ALOSmac="${RESULT_DIR}/MSBAS/ALOSmac"
RESULT_Combi="${RESULT_DIR}/MSBAS/Combi"

RESULTDIR_1="${RESULT_MSBAS_COMP}/01_S1_Combi"
RESULTDIR_2="${RESULT_MSBAS_COMP}/02_S1_2D_ALOS_3D"
RESULTDIR_3="${RESULT_MSBAS_COMP}/03_ALOS_ALOS"
RESULTDIR_4="${RESULT_MSBAS_COMP}/04_Combi_ALOS3D"
RESULTDIR_5="${RESULT_MSBAS_COMP}/05_S1_2D_3D"
RESULTDIR_6="${RESULT_MSBAS_COMP}/06_ALOS_2D_3D"
RESULTDIR_7="${RESULT_MSBAS_COMP}/07_S1_2D_ALOS_2D"
RESULTDIR_8="${RESULT_MSBAS_COMP}/08_ALOSmac_2D_3D"
RESULTDIR_9="${RESULT_MSBAS_COMP}/09_Combi_ALOS_2D"




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
mkdir -p ${RESULT_ALOS}
mkdir -p ${RESULT_ALOSmac}
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


## Plot kml extent over dem
echo " "
echo "Make plot of DEMs and KML"
echo " "
#Plot_cslDEM_and_KMLs.py ${DEM_SRTM} ${KML_listfile_all} ${RESULT_DIR}/DEM/
#Plot_cslDEM_and_KMLs.py ${DEM_SRTM} ${KML_listfile} ${RESULT_DIR}/DEM/


## Listing of CSL images
echo " "
echo "Path where CSL data are stored : ${PATH_CSL}" 
echo "Path where CSL data are stored : ${PATH_CSL_S1}" 
echo " "

cd ${RESULT_DIR}/CSL
#List_All_Modes_and_All_Images.sh "${PATH_CSL}"  "${REGION}"  ${STARTDATE} ${ENDDATE}
#List_All_Modes_and_All_Images.sh "${PATH_CSL_S1}"  "${REGION}"  ${STARTDATE} ${ENDDATE}
cd ..

echo " "
echo "CSL_Lists are written in ${RESULT_DIR}/CSL/*_mode_list.txt"
echo " "

## Updating local listing of MSBAS infos
echo " "
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_S1}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_ALOS}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_ALOSmac}"
echo "Copy restrictedPairSelection*.txt files from ${PATH_MSBAS_Combi}"
echo " "

cp ${PATH_MSBAS_S1}/restrictedPairSelection_DefoInterpolx2Detrend*.txt ${RESULT_S1}
for k in {1..27}; do
  cp ${PATH_MSBAS_ALOS}/restrictedPairSelection_DefoInterpolx2Detrend${k}.txt ${RESULT_ALOS}/restrictedPairSelection_DefoInterpolx2Detrend$((k+4)).txt
  cp ${PATH_MSBAS_ALOSmac}/restrictedPairSelection_DefoInterpolx2Detrend${k}.txt ${RESULT_ALOSmac}/restrictedPairSelection_DefoInterpolx2Detrend$((k+4)).txt
  cp ${PATH_MSBAS_Combi}/restrictedPairSelection_DefoInterpolx2Detrend$((k)).txt ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend$((k+4)).txt
done
  cp ${PATH_MSBAS_Combi}/restrictedPairSelection_DefoInterpolx2Detrend28.txt ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend1.txt
  cp ${PATH_MSBAS_Combi}/restrictedPairSelection_DefoInterpolx2Detrend29.txt ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend4.txt

# Compare CSL and MSBAS databases
echo " "
echo "Compare CSL and MSBAS databases"
echo " "

#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_S1}    ${STARTDATE} ${ENDDATE}  ${RESULT_S1}   ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_ALOS} > ${RESULT_S1}/logfile_checkimage.txt #2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_ALOS}  ${STARTDATE} ${ENDDATE}  ${RESULT_ALOS} ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1} > ${RESULT_ALOS}/logfile_checkimage.txt 2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_ALOSmac} ${STARTDATE} ${ENDDATE} ${RESULT_ALOSmac} ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE_S1} > ${RESULT_ALOSmac}/logfile_checkimage.txt 2>&1
#Check_images.py ${RESULT_DIR}/CSL/ ${RESULT_Combi} ${STARTDATE} ${ENDDATE} ${RESULT_Combi} ${ALL_MODESLIST} -event ${EVENTSDummy} -rejected ${REJECT_MODE} > ${RESULT_Combi}/logfile_checkimage.txt 2>&1


# Info SAR_SM: allPairsListing
echo " "
echo "Copy allPairsListing.txt files from ${PATH_SM} and analyse BP/BT infos"
echo " "

# Boucle sur k
for k in {1..31}; do
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
#    Analyse_AllPairslisting_data.py --input_file ${destination_file} --BPmax ${BPmax} --BTmax ${BTmax} --startdate ${STARTDATEANALYSE} --enddate ${ENDDATEANALYSE} --gap ${GAPINDAYS} --nbr ${nbr} --BP2 ${BPmax2} --BT2 ${BTmax2} --datechange ${Datechange} > ${RESULT_DIR}/SM/logfile_${k}.txt 2>&1

###COH  NOT USED if no process using coh thresh  
## 	source_cohfile="${PATH_MSBAS_Combi}/DefoInterpolx2Detrend${k}_Full/Coh_Table_DefoInterpolx2Detrend${k}.txt" 
## 	destination_cohfile="${RESULT_Combi}/"
## 	cp "${source_cohfile}" "${destination_cohfile}"
##  echo "File ${source_cohfile} copied to: ${destination_cohfile}"
##
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
		if [ -f "${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable}" ]; then
			Cohth_file=${CohTh_dir}"Coh_th_Info_"${filenamekml}".txt"
			if [ -f "${Cohth_file}" ]; then
    			CohTh=$(awk -v k="$k" '$1==k {print $2}' ${Cohth_file})
    			echo "Coherence Threshold : ${CohTh}"
#				Analyse_BaselineCoh_data.py ${RESULT_DIR}/COH/${filenamedesti_Baselinecohtable} ${CohTh} > ${RESULT_DIR}/Coh/logfile_${filenamekml}_${k}.txt 2>&1
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
#Compute_Stats_graph "${RESULT_ALOS}"
#Compute_Stats_graph "${RESULT_ALOSmac}"
#Compute_Stats_graph "${RESULT_Combi}"

echo " "
echo "Comparison of Baseline Plots"
echo " "

AllPairsListing1="${RESULT_DIR}/SM/allPairsListing_1.txt"
AllPairsListing2="${RESULT_DIR}/SM/allPairsListing_2.txt"
AllPairsListing3="${RESULT_DIR}/SM/allPairsListing_3.txt"
AllPairsListing4="${RESULT_DIR}/SM/allPairsListing_4.txt"

#
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend1.txt  "S1AS1" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend1.txt "S1Acombi" ${AllPairsListing1} ${RESULTDIR_1}
#CompareBS_MSBAS.sh ${RESULT_S1}/restrictedPairSelection_DefoInterpolx2Detrend4.txt  "S1DS1" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend4.txt "S1Dcombi" ${AllPairsListing4} ${RESULTDIR_1}
#
#for k in {5..31}; do
#	CompareBS_MSBAS.sh ${RESULT_ALOS}/restrictedPairSelection_DefoInterpolx2Detrend${k}.txt  "ALOS${k}new" ${RESULT_ALOSmac}/restrictedPairSelection_DefoInterpolx2Detrend${k}.txt "ALOS${k}" "${RESULT_DIR}/SM/allPairsListing_${k}.txt" ${RESULTDIR_3}
#	CompareBS_MSBAS.sh ${RESULT_ALOS}/restrictedPairSelection_DefoInterpolx2Detrend${k}.txt  "ALOS${k}new" ${RESULT_Combi}/restrictedPairSelection_DefoInterpolx2Detrend${k}.txt "ALOS${k}combi" "${RESULT_DIR}/SM/allPairsListing_${k}.txt" ${RESULTDIR_4}
#done

			
#echo " "
#echo "Comparison of Maps and computation of the residuals"
#echo " "
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_1} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_Combi} ${Label_4} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_2} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_ALOS} ${Label_2} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_3} ${PATH_MSBAS_ALOS} ${Label_2} ${PATH_MSBAS_ALOSmac} ${Label_3} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_4} ${PATH_MSBAS_Combi}  ${Label_4} ${PATH_MSBAS_ALOS} ${Label_2} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_5} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_S1} ${Label_1b} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_6} ${PATH_MSBAS_ALOS}  ${Label_2} ${PATH_MSBAS_ALOS} ${Label_2b} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_7} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_ALOS} ${Label_2b} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_8} ${PATH_MSBAS_ALOSmac}  ${Label_3} ${PATH_MSBAS_ALOSmac} ${Label_3b} 
#Compare_MSBAS_Maps_Interpolated.py ${RESULTDIR_9} ${PATH_MSBAS_Combi}  ${Label_4} ${PATH_MSBAS_ALOS} ${Label_2b} 
#
#exit
#
echo " "
echo "Comparison of Time Series"
echo " "
CompareTS_EWUD.sh ${RESULTDIR_1} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_Combi} ${Label_4} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_2} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_ALOS} ${Label_2} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_3} ${PATH_MSBAS_ALOS} ${Label_2} ${PATH_MSBAS_ALOSmac} ${Label_3} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_4} ${PATH_MSBAS_Combi}  ${Label_4} ${PATH_MSBAS_ALOS} ${Label_2} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_5} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_S1} ${Label_1b} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_6} ${PATH_MSBAS_ALOS}  ${Label_2} ${PATH_MSBAS_ALOS} ${Label_2b} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_7} ${PATH_MSBAS_S1}  ${Label_1} ${PATH_MSBAS_ALOS} ${Label_2b} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_8} ${PATH_MSBAS_ALOSmac}  ${Label_3} ${PATH_MSBAS_ALOSmac} ${Label_3b} ${PointList}
CompareTS_EWUD.sh ${RESULTDIR_9} ${PATH_MSBAS_Combi}  ${Label_4} ${PATH_MSBAS_ALOS} ${Label_2b} ${PointList}

