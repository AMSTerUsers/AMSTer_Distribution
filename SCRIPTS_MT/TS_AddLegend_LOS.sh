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
# Parameters: - Time serie file (eps file))
#
# Dependencies:	- Fiji (ImageJ). 
#				- gnu sed for more compatibility. 
#				- Python + Numpy + script: CreateColorFrame.py, AmpDefo_map.sh, TimeSerieInfo_HP.sh
#               - Parameter file must be present in "MSBAS/Region/_CombiFiles" to extract 'RateResoSatView' from it
#               
#
# Action:
# - Create a mask with deformation file
# - Find the corresponding Amplitude file
# - Create the image (Amplitude-coherence-deformation) + creating a legend (AmpDefo_map.sh)
# - Create the combi file including time serie, + all legend (TimeSerieInfo_HP.sh)
#  
#
# New in Distro V 1.1:	- allows plotting Vertical or EW only
#						- some cosmetic 
#						- get interpretation of the sense of displacement drawings and
#						  TS_parameters.txt file (if does not exist in current dir) from 
#						  ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/
#						- delete files found with find using -exec rm -f {} \; instead of -delete to avoid ghost smb files
#						  (By Nicolas d'Oreye) 
# New in Distro V 1.2:	- improve path update if broken link (By Nicolas d'Oreye) 
# New in Distro V 1.3:	- get date  of last modif (y) insteaf of creation (w) with gstat 
# New in Distro V 1.4:  - Add parameter "RateResoSatView" as argument when calling 'TimeSeriesInfo_HP.sh' at line 232
#                       - Keep the error output in terminal when calling dependencies scripts
#                       - Work with alias instead of copy (from ${region} to _images folder)
#                       - Small bug correction at line 100 to extract orbit from RUNDIR (old style still here commented)
# New in Distro V 1.4.1: - Small correction to allow orbit number in MSBAS folder's name "ex: zz_LOS_Asc88_Auto_2_0.04_Einstein"
# New in Distro V 1.5:	- if LOS is not named Asc_Auto or Desc_Auto, Orbit variable can't be named Asc or Desc. It is hence names LineOfSight 
# New in Distro V 1.6:  - change all _combi as _Combi for uniformisation
# 						- remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V 1.7:  - remove link to satview.jpg and recreate it in order to be able to operate from different computers.
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

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

eps_file=$1

if [[ ${eps_file} != *".eps" ]]
	then 
		echo "!!!!!!!!!!!  Error:  No eps file valid   !!!!!!!!!"
		exit
fi

RUNDIR=$(pwd)
echo "Let's start creating LOS time series in the ${RUNDIR} folder'"

RegionFolder=$(dirname ${RUNDIR})
#ParamFile=${RegionFolder}/_CombiFiles/TS_parameters.txt
#cp ${RegionFolder}/_CombiFiles/* ${RUNDIR}/_images
# NdO Jan 25 2021
mkdir -p ${RegionFolder}/_CombiFiles
# ONLY COPY PARAM FILE IF IT DOES NOT EXIST TO PRESERVE POSSIBLE ADJUSTMENTS ALREADY PERFORMED TO PARAM FILE   
cp -n ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/* ${RegionFolder}/_CombiFiles/

#if [ ! -e ${RUNDIR}/_images ]; then mkdir ${RUNDIR}/_images; fi
# NdO Jan 25 2021
mkdir -p ${RUNDIR}/_images
#cp ${RegionFolder}/_CombiFiles/* ${RUNDIR}/_images/

ParamFile=${RegionFolder}/_CombiFiles/TS_parameters.txt


function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${ParamFile} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

RateResoSatView=$(GetParam RateResoSatView)

#Orbit=$(echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -o .[Ae]sc | cut -d '_' -f 2)	# Asc or Desc
# NdO Jan 25 2021
#if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "\_LOS\_"| wc -c` -gt 0 ] ; then Orbit=$(echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -o .[Ae]sc | cut -d '_' -f 2) ; OrbitMode="LOS" ; fi	 # Asc or Desc
if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "_LOS_"| wc -c` -gt 0 ] 
	then 
		Orbit=$(echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -o _.*sc.*_Auto | cut -d '_' -f 3) 
		OrbitMode="LOS" 
		if [ "${Orbit}" == "" ] ; then Orbit=LineOfSight ; fi
fi	 # ${Mode}Asc or ${Mode}Desc
if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "_UD_" | wc -c` -gt 0 ] ; then Orbit="UD" ; fi	 # UD
if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "_EW_" | wc -c` -gt 0 ] ; then Orbit="EW" ; fi	 # EW

if [ "${OrbitMode}" == "LOS" ] ; then TagOrbit="LOS" ; else TagOrbit="${Orbit}" ; fi
	
echo "eps file to be decorated = ${eps_file}"
echo "Orbit type: ${Orbit}"

ln -s ${RegionFolder}/_CombiFiles/* ${RUNDIR}/_images  >> /dev/null 2>&1


# find deformation speed file in this directory
#-----------------------------------------------
#PATHFILEDEFO=$(find ${RUNDIR} -type f -name "MSBAS_LINEAR_RATE_LOS.bin")  # !!! remove * !!!
# NdO Jan 25 2021 
PATHFILEDEFO=$(find ${RUNDIR} -maxdepth 1 -type f -name "MSBAS_LINEAR_RATE_${TagOrbit}.bin")  # !!! remove * !!!	

mtime=$(${PATHGNU}/gstat -c %y ${PATHFILEDEFO})
mtime=${mtime:8:2}	#extract creation day
echo "PATHFILEDEFO = $PATHFILEDEFO"
# NdO Jan 25 2021
echo "Last modification day of \"MSBAS_LINEAR_RATE_${TagOrbit}.bin\" file in MSBAS directory is ${mtime}"

#PATHFILEDEFO_done=$(find ${RUNDIR}/_images -type f -name "MSBAS_LINEAR_RATE_LOS_${Orbit}.bin")  # !!! remove * !!!
# NdO Jan 25 2021 - and replace everywhere here after LOS_${Orbit} with GEOM_${Orbit}
PATHFILEDEFO_done=$(find ${RUNDIR}/_images -type f -name "MSBAS_LINEAR_RATE_GEOM_${Orbit}.bin")  # !!! remove * !!!
echo "test max: ${PATHFILEDEFO_done}"
if [ `echo ${PATHFILEDEFO_done} | wc -c` -gt 1 ] 
	then 
		mtime2=$(${PATHGNU}/gstat -c %y ${PATHFILEDEFO_done}) 
		mtime2=${mtime2:8:2}	#extract creation day
		echo "Last modification day of \"MSBAS_LINEAR_RATE_${TagOrbit}.bin\" file in our \"_images\" directory is ${mtime2}"
	else 
		echo "First time decoration of MSBAS_LINEAR_RATE_${TagOrbit}.bin"
		mtime2=0
fi

# Creation of new Velocity map only if a new one is available
#---------------------------------------------------------------
if [[ ${mtime} != ${mtime2} ]] || [ ! -e ${RUNDIR}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit}.jpg ] 
	then 
			echo ""
			echo "----------->   Prepare file for creating new Ampli-Defo-Coh jpeg file for GEOM_${Orbit}:"
			echo ""
			sleep 2
			
			find ${RUNDIR}/_images -type f ! -name "TS_*" -delete
			DEFO="MSBAS_LINEAR_RATE_GEOM_${Orbit}.bin"
			cp -p $PATHFILEDEFO ${RUNDIR}/_images/${DEFO}
			ln -s ${PATHFILEDEFO}.hdr ${RUNDIR}/_images/${DEFO}.hdr
			PATHFILEDEFO=${RUNDIR}/_images/${DEFO}

			PATHFILECOH=$(echo "${PATHFILEDEFO//MSBAS_LINEAR_RATE/MSBAS_MASK}")
			#echo "PATHFILEDEFO = $PATHFILEDEFO"
			#echo "PATHFILECOH = $PATHFILECOH"


			# Creation of the mask
			#---------------------
			${PATH_SCRIPTS}/SCRIPTS_MT/Mask_Builder.py ${PATHFILEDEFO} ${PATHFILECOH}   >> /dev/null 2>&1

			# find the corresponding amplitude file
			#-----------------------------------------------

			#echo "RegionFolder = ${RegionFolder}"
			LinkedFile=$(find ${RegionFolder}/DefoInterpolx2Detrend1/ -name "defo*deg" | head -1)

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
			ln -s ${AmpliFolder}/${AmpliFile} ${RUNDIR}/_images/${AmpliFile}
			ln -s ${AmpliFolder}/${AmpliFile}.hdr ${RUNDIR}/_images/${AmpliFile}.hdr
 			PATHFILEAMPLI=${RUNDIR}/_images/${AmpliFile}
			echo "PATHFILEAMPLI = $PATHFILEAMPLI"
			echo "PATHFILEDEFO = $PATHFILEDEFO"
			echo "PATHFILECOH = $PATHFILECOH"
			# Create the image (Amplitude-coherence-deformation) + creating a legend (AmpDefo_map.sh)
			#----------------------------------------------------------------------------------------
			echo ""
			echo "-----------> Start script to create Ampli-Coherence-Deformation jpeg image "
			#echo "${PATH_SCRIPTS}/SCRIPTS_MT/AmpDefo_map.sh ${PATHFILEAMPLI} ${PATHFILECOH} ${PATHFILEDEFO} AMPLI_COH_MSBAS_LINEAR_RATE_LOS_${Orbit}"
			${PATH_SCRIPTS}/SCRIPTS_MT/AmpDefo_map.sh ${PATHFILEAMPLI} ${PATHFILECOH} ${PATHFILEDEFO} AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit} >> /dev/null 
			#find ${RUNDIR}/_images -type f -name "*_2.0" -delete
			#find ${RUNDIR}/_images -type f -name "*.hdr" -delete
			find ${RUNDIR}/_images -type f -name "*_2.0" -exec rm -f {} \; 	# prefer this way to delete to avoid ghost smb files 
			find ${RUNDIR}/_images -type f -name "*.hdr" -exec rm -f {} \;

			if [ -e ${RUNDIR}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit}.jpg ]
							then 
								echo "----------->  Succeeded "
								echo ""
							else
								echo "----------->  failed "
								echo ""
							fi

		else
			echo ""
			echo "----------->  No need to rebuild Amplitude-Coherence-Deformation image "
			echo ""
	fi

# Creation of time series illustrated with velocity legend + displacement interpretation
#-----------------------------------------------------------------------------------------
echo ""
echo "-----------> Start script to convert eps to jpeg file with crop, legend and interpretation of deformation: "

rm -f ${RUNDIR}/_images/satview.jpg  	# allows to operate from different computers
ln -s ${RegionFolder}/_CombiFiles/satview.jpg ${RUNDIR}/_images  >> /dev/null 2>&1
${PATH_SCRIPTS}/SCRIPTS_MT/TimeSeriesInfo_HP.sh ${eps_file} ${RUNDIR}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit}.jpg ${RateResoSatView}  >> /dev/null 




combi=$(echo "${eps_file//.eps/_Combi.jpg}")
if [ -e ${combi} ]
	then 
		echo "----------->  _Combi.jpg file well created "
		echo ""
	else
		echo "----------->  _Combi.jpg creation failed "
		echo ""
	fi
echo ""
echo "delete extra files"
#find ${RUNDIR}/_images -type f ! \( -name "*.jpg" -o -name "MSBAS_LINEAR_RATE_GEOM_${Orbit}.bin" \) -delete
#find ${RUNDIR}/_images -type l ! \( -name "*.jpg" -o -name "MSBAS_LINEAR_RATE_GEOM_${Orbit}.bin" \) -delete
find ${RUNDIR}/_images -type f ! \( -name "*.jpg" -o -name "MSBAS_LINEAR_RATE_GEOM_${Orbit}.bin" \) -exec rm -f {} \;
find ${RUNDIR}/_images -type l ! \( -name "*.jpg" -o -name "MSBAS_LINEAR_RATE_GEOM_${Orbit}.bin" \) -exec rm -f {} \;

echo ""
echo "------------- end ------------"
echo ""

