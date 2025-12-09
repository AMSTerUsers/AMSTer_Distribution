#!/bin/bash
# Script to run in cronjob for processing Nyiragongo and Nyamulagira Crater amplitude images
# updated on Aug. 12 2021 by NdO to account for the new way of cropping the images with the most recent version of AMSTer Engine. 
#                                Also takes the new Global Primary (SuperMaster) for Nyam  
# updated on Jan. 16 2023 by NdO to account for the new DEM etc

# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.0 20250311:	- SINCE READING AND SORTING IS NOT PERFORMED ANYMORE AT THE PROCESSING OF INTERFEROMETRIC RESULTS ON VVP, LET'S DO IT HERE NOW
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


source $HOME/.bashrc

# Suppose that images were downloaded from super site using secp and then read and sorted manually using 
# ReadDateCSK.sh then Prepa_CSK_SuperSite.sh

# SINCE THIS IS NOT PERFORMED ANYMORE AT THE PROCESSING OF INTERFEROMETRIC RESULTS ON VVP, LET'S DO IT HERE NOW
		
		# Path to RAW data
		DWNLOADDIR=Auto_Curl
		PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/CSK/SuperSite/${DWNLOADDIR}
		
		# Path to SAR_CSL data
		PATHCSL=$PATH_1650/SAR_CSL/CSK
		
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



# LET'S GET BACK TO NORMAL AMPLI PROCESSING

PARAMASC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Asc/
PARAMDESC=${PATH_DataSAR}/SAR_AUX_FILES/Param_files/CSK/Virunga_Desc/

# ALL2GIFF
# Asc Nyigo Crater - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20160627 ${PARAMASC}LaunchMTparam_CSK_Virunga_Asc_Nyigo_Zoom1_ML1_snaphu_Shadows.txt 800 1150 & 
# Desc Nyigo Crater - in background so that it can start at the same time the descending
# Date label position was updated to account for the new way of cropping the images with the most recent version of AMSTer Engine   
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20160105 ${PARAMDESC}LaunchMTparam_CSK_Virunga_Desc_NyigoCrater_Zoom1_ML1_snaphu_SHADOWS.txt 600 500 &

# Asc Nyam - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20160627 ${PARAMASC}LaunchMTparam_CSK_Virunga_Asc_NyamCrater2_Zoom1_ML1_snaphu_Shadows.txt 1100 900 & 
# Desc Nyam - in background so that it can start at the same time the descending
/$PATH_SCRIPTS/SCRIPTS_MT/ALL2GIF.sh 20160105 ${PARAMDESC}LaunchMTparam_CSK_Virunga_Desc_NyamCrater2_Zoom1_ML1_snaphu_SHADOWS.txt 1450 750 & 

