#!/bin/bash
# Script to run in cronjob for processing VVP images:
# Read images, corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 

# New in Distro V 2.0.0 20220602 :	- use new Prepa_MSBAS.sh compatible with D Derauw and L. Libert tools for Baseline Ploting
# New in Distro V 2.0.1 20221229 :	- do not exit if no new data to unzip; just break
# New in Distro V 2.1.0 20230116 :	- Renaming RAW files in unzip loop 
#									- new Param files, i.e. with dem, masks 
#									- some relooking
# New in Distro V 2.2.0 20230626 :	- Color tables are now in TemplatesForPlots
# New in Distro V 2.3.0 20230712 :	- take into account new CSK zip format
# New in Distro V 2.4.0 20230719 :  - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_MT directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
source $HOME/.bashrc


# Some variables
#################

BP=150
BTASC=200
BTDESC=200

SMASC=20160627
SMDESC=20160105

# Path to RAW data
DWNLOADDIR=Auto_Curl
PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/CSK/SuperSite/${DWNLOADDIR}

# Path to SAR_CSL data
PATHCSL=$PATH_1650/SAR_CSL/CSK

# Path to RESAMPLED data
NEWASCPATH=$PATH_1650/SAR_SM/RESAMPLED/CSK/Virunga_Asc/SMNoCrop_SM_${SMASC}
NEWDESCPATH=$PATH_1650/SAR_SM/RESAMPLED/CSK/Virunga_Desc/SMNoCrop_SM_${SMDESC}

# Path to Seti
PATHSETI=$PATH_1650/SAR_SM/MSBAS


# Parameters files for Coregistration
PARAMASC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Asc/LaunchMTparam_SuperMaster_CSK_Virunga_Asc_Full_Zoom1_ML23_KEEP_Coreg.txt
PARAMDESC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Desc/LaunchMTparam_SuperMaster_CSK_Virunga_Desc_Full_Zoom1_ML23_Coreg.txt


mkdir -p ${PATHRAW}_DATED

echo "//Unzipping files in ${PATHRAW}/tmp"
# Unzip and Rename 
cd ${PATHRAW}
ls *.zip >> All_zip.txt

if [ ! -s Already_Unzip.txt ] ; then touch Already_Unzip.txt ; fi

#Remove from All_files.txt each line that contains what is in lines of Already_Unzip.txt
#---------------------------------------------------------------------------------------
grep -Fv -f Already_Unzip.txt All_zip.txt > To_Unzip.txt 

cat To_Unzip.txt  >> Already_Unzip.txt

mkdir -p ${PATHRAW}/tmp

if [ -f "To_Unzip.txt" ] && [ -s "To_Unzip.txt" ] 
	then 
		for FILESTOUNZIP in `cat To_Unzip.txt` 
			do 
				unzip ${FILESTOUNZIP} 
				echo "//  Files unzipped"
				echo
				echo "//Renaming RAW files with date in ${PATHRAW}_DATED"
				FILENAMENOEXT="${FILESTOUNZIP%.*}"
				if [ -f "${FILENAMENOEXT}.h5" ] 
					then 
						echo "// New zip format" 
						DATE=`echo ${FILENAMENOEXT}.h5 | ${PATHGNU}/grep -Eo "[0-9]{14}_[0-9]{14}" | cut -c 1-8 `
						echo "File ${FILENAMENOEXT}.h5 has been moved in ${DATE}" > ${FILENAMENOEXT}.txt
						mkdir -p ${PATHRAW}_DATED/${DATE}
						mv ${FILENAMENOEXT}.h5 ${PATHRAW}_DATED/${DATE}/
						mv ${FILENAMENOEXT}.txt ${PATHRAW}_DATED/${DATE}/
					else 
						cd ${PATHRAW}/tmp
						# All files are one level too high in a dir named workspace-blabla. ghet them one level below
						for WORKSPACEFILES in `find . -maxdepth 1 -type d -name "workspace*"` 
							do 
								cd ${WORKSPACEFILES}
								IMGDIR=`ls -d *.h5`
								cd ${IMGDIR}
								DATE=`echo *.h5 | cut -d _ -f 9 | cut -c 1-8`
								echo "Dir ${WORKSPACEFILES} has been renamed ${DATE}" > ${WORKSPACEFILES}.txt
								cd ..
								mv ${IMGDIR} ${DATE}
								mv ./${DATE} ${PATHRAW}_DATED
								cd ..
								rm -Rf ${WORKSPACEFILES}
						done

						cd ..
						rm -R ./tmp
						rm -f To_Unzip.txt All_zip.txt
						echo "//  RAW files renamed with date in ${PATHRAW}_DATED"
				fi
		done
	else 
		#echo "No new data ; exit" 
		echo "No new data to unzip" 
		rm -f To_Unzip.txt All_zip.txt
		#exit 0
fi

rm -Rf ${PATHRAW}/tmp

# Read all CSK images for that footprint
#######################################
 echo "//Reading RAW images (Asc adn Desc) as .csl in ${PATHCSL}/Virunga"
 $PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh ${PATHRAW}_DATED ${PATHCSL}/Virunga CSK > /dev/null 2>&1

 echo "//Sorting images.csl in Asc and Desc directories"
 cd ${PATHCSL}/Virunga
 ReadModeCSK.sh Virunga

 echo "//Coregistering images..."
# Coregister all images on the super master 
###########################################
# in Ascending mode 
 $PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMASC} &
# in Descending mode 
 $PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh ${PARAMDESC} &


 echo "//Searching pairs and plotting baselines graphs"
# Search for pairs
##################
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${PATHCSL}/Virunga_Asc/NoCrop ${PATHSETI}/VVP/set1 CSK > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh ${PATHCSL}/Virunga_Desc/NoCrop ${PATHSETI}/VVP/set2 CSK > /dev/null 2>&1 &
wait

# Compute pairs only if new data is identified
if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${PATHSETI}/VVP/set1 ${BP} ${BTASC} ${SMASC} > /dev/null 2>&1  &
fi
if [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${PATHSETI}/VVP/set2 ${BP} ${BTDESC} ${SMDESC} > /dev/null 2>&1  &
fi
wait

# Plot baseline plot with both modes 
 if [ ! -s ${NEWASCPATH}/_No_New_Data_Today.txt ] || [ ! -s ${NEWDESCPATH}/_No_New_Data_Today.txt ] ; then 

	if [ `baselinePlot | wc -l` -eq 0 ] 
		then
			# use AMSTer Engine before May 2022
			mkdir -p ${PATHSETI}/VVP/BaselinePlots_set1_set2
			cd ${PATHSETI}/VVP/BaselinePlots_set1_set2

			echo "${PATHSETI}/VVP/set1" > ModeList.txt
			echo "${PATHSETI}/VVP/set2" >> ModeList.txt

			# huggly trick
			#cp /${PATHSETI}/VVP/set2/table_0_150_0_200.txt /${PATHSETI}/VVP/set2/table_0_150_0_150.txt
			#$PATH_SCRIPTS/SCRIPTS_MT/plot_Multi_span.sh ModeList.txt 0 ${BP} 0 150 $PATH_SCRIPTS/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt			

			${PATH_SCRIPTS}/SCRIPTS_MT/plot_Multi_span_multi_Baselines.sh ModeList.txt 0 ${BP} 0 ${BTASC} ${PATH_SCRIPTS}/SCRIPTS_MT/TemplatesForPlots/ColorTable_AD.txt 0 ${BP} 0 ${BTDESC}

		else
			# use AMSTer Engine > May 2022
			mkdir -p ${PATHSETI}/VVP/BaselinePlots_set1_set2
			cd ${PATHSETI}/VVP/BaselinePlots_set1_set2
 
			echo "${PATHSETI}/VVP/set1" > ModeList.txt
			echo "/${PATHSETI}/VVP/set2" >> ModeList.txt
 
			plot_Multi_BaselinePlot.sh ${PATHSETI}/VVP/BaselinePlots_set1_set2/ModeList.txt
 	fi
 fi

