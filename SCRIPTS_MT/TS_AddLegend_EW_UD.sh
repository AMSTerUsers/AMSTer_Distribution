#!/bin/bash
# -----------------------------------------------------------------------------------------
#
# Mandatory: Script must be launched in "MSBAS/Region/Mode" directory 
# (ex: /Volumes/D3602/MSBAS/_LUX_S1_Auto_20m_400days/zz_LOS_Asc_Auto_2_0.04_LUX)
#
# Script to generate a jpg file including:
#						-  	time series 
#						- 	crop from deformation file with pair of point locator
#						- 	Legend of deformation file (cm/year)
#						- 	Legend to explain deformation direction
# based on envi files. Size of the images are taken form header file. 
#
# Parameters:	 - Time serie file (eps file))
#				 - REMARKDIR (Complement to the zzfolder after direction to know in which pool of deformation folder we want to use)
#
# Dependencies:	- Fiji (ImageJ). 
#				- gnu sed for more compatibility. 
#				- Python + Numpy + script: CreateColorFrame.py, AmpDefo_map.sh, TimeSerieInfo_HP.sh, AmpTif_map.sh
#  
#
# Action:
# - Create a mask with deformation file
# - Find the corresponding Amplitude file
# - Create the image (Amplitude-coherence-deformation) + creating a legend (AmpDefo_map.sh)
# - Create the combi file including time serie, + all legend (TimeSerieInfo_HP.sh)
#  
#
# New in Distro V 1.1:	- some cosmetic 
#						- get interpretation of the sense of displacement drawings and
#						  TS_parameters.txt file (if does not exist in current dir) from 
#						  ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/
#						- delete files found with find using -exec rm -f {} \; instead of -delete to avoid ghost smb files
#						  (By Nicolas d'Oreye) 
# New in Distro V 1.2:	- get date  of last modif (y) insteaf of creation (w) with gstat 
# New in Distro V 1.3:	- avoid eror message when first run and no file exist in /_images
# 						- improve path update if broken link (By Nicolas d'Oreye) 
#                       - Keep the error output in terminal when calling dependencies scripts
#                       - Work with alias instead of copy (from ${region} to _images folder)
# New in Distro V 1.4:	- files were not copied anymore from ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/* to ${RegionFolder}/_CombiFiles/
#                       - quote name of file to check with if [ -s ${variable} ] 
# New in Distro V 1.5:  - change all _combi as _Combi for uniformisation
# New in Distro V 1.6:  - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20240305:	- Works for other defo mode than only DefoInterpolx2Detrend
# New in Distro V 3.2 20240702:	- from V3.1 modifications, add mode DefoInterpol2
# New in Distro V 3.3 20250227:	- replace cp -n with if [ ! -e DEST ] ; then cp SRC DEST ; fi 
# New in Distro V 3.3 20250428:	- DS: Add defo mode COR_Defo
# New in Distro V 3.4 20250813:	- Selection of appropriate amplitude file if combi mode to create AmpCohDefo map
# New in Distro V 3.5 20250916:	- Force to cp instead of link images
# New in Distro V 3.6 20251105:	- if does not find LinkedFile in all dirs down to Defo1 dir, search for Defo*1. 
#									This should allows coping with all type of exotic processings... 
# New in Distro V 3.7 20260211:	- change  way to compare if file is older than another (only use mtime for display)
# New in Distro V 3.8 20260323:	- create a dummy file to compare with cmp if no file exist yet
# New in Distro V 4.0 20260731:	- works with msbasv10 (and tif files)
# New in Distro V 4.1 20260803:	- copy only missing files in CombiFiles if needed
#								- clean all dummy.tmp and minor improvements (for sake of robustness)
# New in Distro V 4.2 20260804:	- restore satview.jpg (and AMSTer.png) in ${RUNDIR_EW}/_images just 
#								  before calling TimeSeriesInfo_HP.sh. The cleaning "find ... ! -name 
#								  TS_* ! -name AMSTer.png -exec rm -f" of both the ENVI and the tif 
#								  branch deletes it, and the only copy from _CombiFiles happens 
#								  before them, so on every run that rebuilt the velocity maps there 
#								  was no satview.jpg left and the Google Earth crop was skipped. 
#								  TS_AddLegend_LOS.sh has always restored it; this script did not 
#								- read RateResoSatView and pass it as 3rd argument to 
#								  TimeSeriesInfo_HP.sh, as TS_AddLegend_LOS.sh does 
#								- some cleaning
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro 4.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 03, 2026"


echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${HOME}/.bashrc
# ^^^ ----- Hard coded lines to check --- ^^^ 

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

REMARKDIR=$1
eps_file=$2

if [[ ${eps_file} != *".eps" ]]
	then 
		echo "!!!!!!!!!!!  Error:  No eps file valid   !!!!!!!!!"
		echo ""
		exit 1
fi

RegionFolder=$(pwd)
echo "Let's start creating EW and UD time series in the $RegionFolder folder'"

#ParamFile=${RegionFolder}/_CombiFiles/TS_parameters.txt
# NdO Jan 25 2021
mkdir -p ${RegionFolder}/_CombiFiles
# ONLY COPY PARAM FILE IF IT DOES NOT EXIST TO PRESERVE POSSIBLE ADJUSTMENTS ALREADY PERFORMED TO PARAM FILE   
#cp -n ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/* ${RegionFolder}/_CombiFiles/
#if [ ! -e "${RegionFolder}/_CombiFiles/" ] ; then cp "${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/*" "${RegionFolder}/_CombiFiles/" ; fi 
for FILE in "${PATH_SCRIPTS}"/SCRIPTS_MT/TSCombiFiles/* ; do
	[ -e "${FILE}" ] || continue
	DEST="${RegionFolder}/_CombiFiles/$(basename "${FILE}")"
	if [ ! -e "${DEST}" ] ; then cp -p "${FILE}" "${DEST}" ; fi
done


ParamFile=${RegionFolder}/_CombiFiles/TS_parameters.txt

function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${ParamFile} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

# NdO Aug 04 2026: needed to pass it to TimeSeriesInfo_HP.sh as TS_AddLegend_LOS.sh does, so that 
# the Google Earth crop can be built (and its resolution rate checked against satview.jpg). 
RateResoSatView=$(GetParam RateResoSatView)

echo "eps file to be decorated = ${eps_file}"
echo "Sub folder to be used:"
RUNDIR_EW=$(find ${RegionFolder} -maxdepth 1 -type d -name "zz_EW${REMARKDIR}")
RUNDIR_UD=$(find ${RegionFolder} -maxdepth 1  -type d -name "zz_UD${REMARKDIR}")
echo "RUNDIR_EW = ${RUNDIR_EW}"
echo "RUNDIR_UD = ${RUNDIR_UD}"
echo ""

# test if msbasv10 results in tif format
if [ -f "${RUNDIR_UD}/MSBAS_LINEAR_RATE_UD.tif" ] || [ -f "${RUNDIR_EW}/MSBAS_LINEAR_RATE_EW.tif" ]
	then
		EXTIMG="tif"
	else
		EXTIMG="bin"
	
fi 

# if [ ! -e ${RUNDIR_EW}/_images ]
# 	then 
# 		mkdir -p ${RUNDIR_EW}/_images
# 		ln -s ${RegionFolder}/_CombiFiles/* ${RUNDIR_EW}/_images 2>/dev/null
# fi
# if [ ! -e ${RUNDIR_UD}/_images ]
# 	then 
# 		mkdir -p ${RUNDIR_UD}/_images
# 		ln -s ${RegionFolder}/_CombiFiles/* ${RUNDIR_UD}/_images 2>/dev/null
# fi
# NdO Jan 25 2021
mkdir -p ${RUNDIR_EW}/_images
mkdir -p ${RUNDIR_UD}/_images

#ln -s -f ${RegionFolder}/_CombiFiles/* ${RUNDIR_EW}/_images 2>/dev/null
#ln -s -f ${RegionFolder}/_CombiFiles/* ${RUNDIR_UD}/_images 2>/dev/null
cp -f ${RegionFolder}/_CombiFiles/* ${RUNDIR_EW}/_images 2>/dev/null
cp -f ${RegionFolder}/_CombiFiles/* ${RUNDIR_UD}/_images 2>/dev/null

if [ "${EXTIMG}" != "tif" ]
	then
		# NORMAL PROCESSING WITH ENVI FORMAT
		# Create the velocity map for EW and UP deformation
		# ---------------------------------------------------
		for RUNDIR in ${RUNDIR_UD} ${RUNDIR_EW} 
			do 
					EW_UD=$(echo $(basename ${RUNDIR}) | cut -d '_' -f 2)
					echo ""
					echo "Let's check what already exist in  zz_${EW_UD}${REMARKDIR}"
					echo ""
		
		
					# find deformation speed file in this directory
					#-----------------------------------------------
					PATHFILEDEFO=$(find ${RUNDIR} -maxdepth 1 -type f -name "MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}")  
					
					[ -f "${PATHFILEDEFO}" ] || { echo "No MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG} in ${RUNDIR}" ; continue ; }
					
					mtime=$(${PATHGNU}/gstat -c %y ${PATHFILEDEFO})
					mtime=${mtime:8:2}	#extract creation day
					echo "PATHFILEDEFO = $PATHFILEDEFO"
					echo "Last modification day of \"MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}\" file in MSBAS directory is ${mtime}"
		
					PATHFILEDEFO_done=$(find ${RUNDIR}/_images -type f -name "MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}")  
					if [ -f "${PATHFILEDEFO_done}" ] && [ -s "${PATHFILEDEFO_done}" ]
						then 
							mtime2=$(${PATHGNU}/gstat -c %y ${PATHFILEDEFO_done})
							mtime2=${mtime2:8:2}	#extract creation day
						else 
							mtime2=0	
							touch "${RUNDIR}/dummy.tmp"
							PATHFILEDEFO_done="${RUNDIR}/dummy.tmp"
					fi
					echo "Last modification day of \"MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}\" file in our \"_images\" directory is ${mtime2}"
		
					# Creation of new Velocity map only if a new one is available
					#---------------------------------------------------------------
		# 			if [[ ${mtime} != ${mtime2} ]] || [ ! -e $RUNDIR/_images/AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}.jpg ] 
					if ! cmp -s ${PATHFILEDEFO} ${PATHFILEDEFO_done} || [ ! -e ${RUNDIR}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}.jpg ] 
						then 
								echo ""
								echo "----------->   Prepare file for creating new Ampli-Defo-Coh jpeg file for ${EW_UD}:"
								echo ""
								sleep 2
		
								#find $RUNDIR/_images -type f ! -name "TS_*" -delete
								find ${RUNDIR}/_images -type f ! -name "TS_*" ! -name "AMSTer.png" -exec rm -f {} \;
								DEFO="MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}"
								cp -p ${PATHFILEDEFO} ${RUNDIR}/_images
								#ln -s -f ${PATHFILEDEFO}.hdr $RUNDIR/_images
								cp -f ${PATHFILEDEFO}.hdr ${RUNDIR}/_images
								PATHFILEDEFO=${RUNDIR}/_images/${DEFO}
		
								PATHFILECOH=$(echo "${PATHFILEDEFO//MSBAS_LINEAR_RATE/MSBAS_MASK}")
								#echo "PATHFILEDEFO = $PATHFILEDEFO"
								#echo "PATHFILECOH = $PATHFILECOH"
		
		
								# Creation of the mask (from Ampli/Ampli)
								#---------------------
								${PATH_SCRIPTS}/SCRIPTS_MT/Mask_Builder.py ${PATHFILEDEFO} ${PATHFILECOH}   >> /dev/null 2>&1
		
								# find the corresponding amplitude file
								#-----------------------------------------------
								# Check if REMARKDIR content Orbit info 
								orbit=""
								if [[ ! ${REMARKDIR} == _Auto* ]]; then
									# 2. Split into part1 and part2 around the first occurrence of "_Auto"
									if [[ ${REMARKDIR} == *"_Auto"* ]]; then
										part1="${REMARKDIR%%_Auto*}"
										part2="${REMARKDIR#"$part1"}"
									else
										part1="${REMARKDIR}"
										part2=""
										echo "...part1 = $part1"
									fi
				
								
									# 3. Extract "A_[0-9]+" from part1 if it exists
									if [[ $part1 =~ (A_[0-9]+) ]]; then
										match="${BASH_REMATCH[1]}"
										echo "Found pattern: $match"
										orbit=${match}
									else
										echo "No A_[0-9]+ pattern found in part1"
									fi
								else
									echo "String starts with _Auto — skipping."
								fi

								LinkedFile=$(find ${RegionFolder}/DefoInterpolx2Detrend1/ -name "defo*${orbit}*deg" 2>/dev/null | head -1)
								if [ "${LinkedFile}" == "" ] 
									then 
										LinkedFile=$(find ${RegionFolder}/DefoInterpolx2Detrend2/ -name "defo*${orbit}*deg" 2>/dev/null | head -1)
								fi
								
								if [ "${LinkedFile}" == "" ] 
									then 
										# There is no file in DefoInterpolx2Detrend1, search in DefoInterpolDetrend1
										LinkedFile=$(find ${RegionFolder}/DefoInterpolDetrend1/ -name "defo*deg" 2>/dev/null | head -1) 
										if [ "${LinkedFile}" == "" ] 
											then 
												# There is no file in DefoInterpolDetrend1, search in DefoInterpol1
												LinkedFile=$(find ${RegionFolder}/DefoInterpol1/ -name "defo*deg" 2>/dev/null | head -1) 
											if [ "${LinkedFile}" == "" ] 
												then 
													# There is no file in DefoInterpolDetrend1, search in DefoInterpol1
													LinkedFile=$(find ${RegionFolder}/DefoInterpol2/ -name "defo*deg" 2>/dev/null | head -1) 
													if [ "${LinkedFile}" == "" ] 
														then 
															# There is no file in DefoInterpol1, search in Defo1
															LinkedFile=$(find ${RegionFolder}/Defo1/ -name "defo*deg" 2>/dev/null | head -1) 
															if [ "${LinkedFile}" == "" ] 
																then 
																	#### There is no file in Defo1, search in DefoInterpolx2DetrendRmCo1										
																	###LinkedFile=$(find ${RegionFolder}/DefoInterpolx2DetrendRmCo1/ -name "defo*deg" 2>/dev/null | head -1) 
																	
																	# There is no file in Defo1, search in first of Defo*1		
																	FirstDir=$(ls -d "${RegionFolder}"/Defo*1/ 2>/dev/null | head -1)
																	echo "  // This is a fancy deformation Dir. Please check yourself if evrything is OK... "
																	LinkedFile=$(find "$FirstDir" -type f -name "defo*deg" 2>/dev/null | head -1)
																	# for really exotic and fancy processings.... be carefull.... 
																	if [ "${LinkedFile}" == "" ] 
																		then 
																			echo "  // This is a very fancy deformation file. Please check yourself if evrything is OK... "
																			LinkedFile=$(find "$FirstDir" -type f -name "*defo*deg" 2>/dev/null | head -1)
																	fi
							
																	if [ "${LinkedFile}" == "" ] 
																		then 
																			# There is no file at all - can't make the fig with amplitude background
																			echo "  // I can't find a deformation file in ${RegionFolder}/Defo[Interpol][x2][Detrend][*]1. "
																			echo "  // Hence I can't find an Ampli dir where to find what I need to make an amplitude background" 
																	fi
															fi
													fi
											fi
										fi
								fi					
			
								# Because the script may be launched on a computer with another OS than the one used to build ampli
								# let's change beginning of path by the corresponding state variable if target file does not exists
								AmpliPath=$(readlink ${LinkedFile})
								#echo "AmpliPath = ${AmpliPath}"
							
								if [ ! -s ${AmpliPath} ] ; then 
									AmpliDir=$(dirname ${AmpliPath})
									# Disk nr
									Server=$(echo ${AmpliPath} | cut -d "/" -f 3 | ${PATHGNU}/grep -o [0-9][0-9][0-9][0-9])
									PathServer="PATH_${Server}"
									# delete verythinh till disk server nr
									AmpliRelPath=$(echo ${AmpliPath} | sed "s/^.*${Server}//")
									# need also to delete trailing string from server name, i.e. till /
									AmpliPathTmp=$(echo ${AmpliRelPath} | cut -d "/" -f2- )	
									# replace by server state variable
									AmpliPath=${!PathServer}/${AmpliPathTmp}
								fi
									
								#echo "AmpliPath = ${AmpliPath}"
								AmpliFolder=$(dirname $(dirname ${AmpliPath}))/Ampli
								AmpliFile=$(ls -t ${AmpliFolder} | ${PATHGNU}/grep deg$ | head -n 1)
							
								#echo "AmpliPath = ${AmpliPath}"
								#echo "LinkedFile = ${LinkedFile}"
								#echo "AmpliPath = ${AmpliPath}"
								#echo ${Server}
								#echo ${AmpliRelPath}
								#echo ${AmpliPath}
				
								#echo "Ampli file = ${AmpliFile}"
								#ln -s -f ${AmpliFolder}/${AmpliFile} $RUNDIR/_images/${AmpliFile}
								#ln -s -f ${AmpliFolder}/${AmpliFile}.hdr $RUNDIR/_images/${AmpliFile}.hdr
								cp -f ${AmpliFolder}/${AmpliFile} $RUNDIR/_images/${AmpliFile}
								cp -f ${AmpliFolder}/${AmpliFile}.hdr $RUNDIR/_images/${AmpliFile}.hdr
				
								PATHFILEAMPLI=$RUNDIR/_images/${AmpliFile}
								echo "PATHFILEAMPLI = $PATHFILEAMPLI"
								echo "PATHFILEDEFO = $PATHFILEDEFO"
								echo "PATHFILECOH = $PATHFILECOH"
									
								# Create the image (Amplitude-coherence-deformation) + creating a legend (AmpDefo_map.sh)
								#----------------------------------------------------------------------------------------
								echo ""
								echo "----------->  Start script to create Ampli-Coherence-Deformation jpeg image for ${EW_UD}:"
							
								#echo "${PATH_SCRIPTS}/SCRIPTS_MT/AmpDefo_map.sh ${PATHFILEAMPLI} ${PATHFILECOH} ${PATHFILEDEFO} AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD} "
								${PATH_SCRIPTS}/SCRIPTS_MT/AmpDefo_map.sh ${PATHFILEAMPLI} ${PATHFILECOH} ${PATHFILEDEFO} AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}  >> /dev/null  
	
								if [ -e $RUNDIR/_images/AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}.jpg ]
									then 
										echo "----------->  Succeeded "
										echo ""
									else
										echo "----------->  failed "
										echo ""
								fi
						else
							echo ""
							echo "----------->  No need to rebuild Amplitude-Coherence-Deformation image for ${EW_UD} "
							echo ""
					fi
		done
	else 
	
		# PROCESSING WITH TIF FORMAT; no ampli and coh masks
		# if msbasv10 and possible pixel tracking, hence no classical defo files and maybe no ampli files
		
		for RUNDIR in ${RUNDIR_UD} ${RUNDIR_EW} 
			do 
					EW_UD=$(echo $(basename ${RUNDIR}) | cut -d '_' -f 2)
					echo ""
					echo "Let's check what already exist in  zz_${EW_UD}${REMARKDIR}"
					echo ""
		
		
					# find deformation speed file in this directory
					#-----------------------------------------------
					PATHFILEDEFO=$(find ${RUNDIR} -maxdepth 1 -type f -name "MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}")  
					mtime=$(${PATHGNU}/gstat -c %y ${PATHFILEDEFO})
					mtime=${mtime:8:2}	#extract creation day
					echo "PATHFILEDEFO = $PATHFILEDEFO"
					echo "Last modification day of \"MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}\" file in MSBAS directory is ${mtime}"
		
					PATHFILEDEFO_done=$(find ${RUNDIR}/_images -type f -name "MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}")  
					if [ -f "${PATHFILEDEFO_done}" ] && [ -s "${PATHFILEDEFO_done}" ]
						then 
							mtime2=$(${PATHGNU}/gstat -c %y ${PATHFILEDEFO_done})
							mtime2=${mtime2:8:2}	#extract creation day
						else 
							mtime2=0	
							touch "${RUNDIR}/dummy.tmp"
							PATHFILEDEFO_done="${RUNDIR}/dummy.tmp"
					fi
					echo "Last modification day of \"MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}\" file in our \"_images\" directory is ${mtime2}"
		
					# Creation of new Velocity map only if a new one is available
					#---------------------------------------------------------------
		 			#if [[ ${mtime} != ${mtime2} ]] || [ ! -e $RUNDIR/_images/AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}.jpg ] 
					if ! cmp -s ${PATHFILEDEFO} ${PATHFILEDEFO_done} || [ ! -e $RUNDIR/_images/AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}.jpg ] 
						then 
								echo ""
								echo "----------->   Prepare file for creating new Defo-only (no ampli and coh) jpeg file for ${EW_UD}:"
								echo ""
								sleep 2
		
								#find $RUNDIR/_images -type f ! -name "TS_*" -delete
								find $RUNDIR/_images -type f ! -name "TS_*" ! -name "AMSTer.png" -exec rm -f {} \;
								DEFO="MSBAS_LINEAR_RATE_${EW_UD}.${EXTIMG}"
								cp -p $PATHFILEDEFO $RUNDIR/_images
								#ln -s -f ${PATHFILEDEFO}.hdr $RUNDIR/_images
								###cp -f ${PATHFILEDEFO}.hdr $RUNDIR/_images
								PATHFILEDEFO=$RUNDIR/_images/${DEFO}
								echo "PATHFILEDEFO = $PATHFILEDEFO"

									
								# Create the image (Amplitude-coherence-deformation) + creating a legend (AmpDefo_map.sh)
								#----------------------------------------------------------------------------------------
								echo ""
								echo "----------->  Start script to create Deformation jpeg image for ${EW_UD}:"
							
								#echo "${PATH_SCRIPTS}/SCRIPTS_MT/AmpDefo_map.sh ${PATHFILEAMPLI} ${PATHFILECOH} ${PATHFILEDEFO} AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD} "
								${PATH_SCRIPTS}/SCRIPTS_MT/AmpTif_map.sh ${PATHFILEDEFO} AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}  >> /dev/null  
		
								if [ -e $RUNDIR/_images/AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}.jpg ]
									then 
										echo "----------->  Succeeded "
										echo ""
									else
										echo "----------->  failed "
										echo ""
								fi
						else
							echo ""
							echo "----------->  No need to rebuild Deformation image for ${EW_UD} "
							echo ""
					fi
		done

fi

rm -f "${RUNDIR_UD}/dummy.tmp" "${RUNDIR_EW}/dummy.tmp" 2>/dev/null

# Creation of time series illustrated with velocity legend + displacement interpretation
#-----------------------------------------------------------------------------------------


cp -f ${RUNDIR_UD}/_images/*.jpg ${RUNDIR_EW}/_images/  2>/dev/null

# NdO Aug 04 2026: the two "find ... ! -name TS_* ! -name AMSTer.png -exec rm -f" above (one in the 
# ENVI branch, one in the tif branch) wipe satview.jpg out of _images, and the only copy from 
# _CombiFiles happens BEFORE them, at the top of this script. TS_AddLegend_LOS.sh restores it just 
# before calling TimeSeriesInfo_HP.sh; this script never did, so the Google Earth crop could not be 
# built on any run that rebuilt the velocity maps. Restore it here, exactly as the LOS script does. 
rm -f ${RUNDIR_EW}/_images/satview.jpg  	# allows to operate from different computers
cp -f ${RegionFolder}/_CombiFiles/satview.jpg ${RUNDIR_EW}/_images  >> /dev/null 2>&1
cp -f ${RegionFolder}/_CombiFiles/AMSTer.png ${RUNDIR_EW}/_images  >> /dev/null 2>&1

echo ""
echo "----------->  Start script to convert eps to jpeg file with crop, legend and interpretation of deformation: "
#echo "${PATH_SCRIPTS}/SCRIPTS_MT/TimeSeriesInfo_HP.sh ${eps_file} $RUNDIR/_images/AMPLI_COH_MSBAS_LINEAR_RATE_${EW_UD}.jpg "

# NdO Aug 04 2026: pass RateResoSatView as 3rd argument, as TS_AddLegend_LOS.sh does 
${PATH_SCRIPTS}/SCRIPTS_MT/TimeSeriesInfo_HP.sh ${eps_file} ${RUNDIR_EW}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_EW.jpg ${RateResoSatView}   # >> /dev/null 

combi=$(echo "${eps_file//.eps/_Combi.jpg}")
if [ -e ${combi} ]
	then 
		echo "----------->  Succeeded "
		echo ""
	else
		echo "----------->  failed "
		echo ""
	fi


echo ""
echo "delete extra files"
#find ${RUNDIR_UD}/_images -type f ! \( -name "*.jpg" -o -name "MSBAS_LINEAR_RATE_*.bin" \) -delete
#find ${RUNDIR_EW}/_images -type f ! \( -name "*.jpg" -o -name "MSBAS_LINEAR_RATE_*.bin" \) -delete
#find ${RUNDIR_UD}/_images -type f ! \( -name "*.jpg" -o -name "MSBAS_LINEAR_RATE_*.bin" \) -exec rm -f {} \;
#find ${RUNDIR_EW}/_images -type f ! \( -name "*.jpg" -o -name "MSBAS_LINEAR_RATE_*.bin" \) -exec rm -f {} \;

echo ""
echo "------------- end ------------"
echo ""