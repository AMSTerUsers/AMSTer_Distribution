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
#				- Python + Numpy + script: CreateColorFrame.py, AmpDefo_map.sh, TimeSerieInfo_HP.sh,AmpTif_map.sh
#               - Parameter file must be present in "MSBAS/Region/_CombiFiles" to extract 'RateResoSatView' from it
#				- CreateBackgroundMaps.sh 
#				- EnviGridInfo.py
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
# New in Distro V 3.1 20240305:	- Works for other defo mode than only DefoInterpolx2Detrend
# New in Distro V 3.2 20240416:	- Search for Asc or Desc mode in dir name compatible with ALOS2 modes, that is e.g. zz_LOS_6811_L_A_Auto_2_0.04_PF 
# New in Distro V 3.3 20250203:	- Search for A_${mode}_auto... or D_${mode}_auto... in dir name compatible with Nepal
# New in Distro V 3.4 20250227:	- replace cp -n with if [ ! -e DEST ] ; then cp SRC DEST ; fi 
# New in Distro V 3.5 20250428:	- DS: Add defo mode COR_Defo
# New in Distro V 3.6 20250916:	- Force to cp instead of link images
# New in Distro V 3.7 20251105:	- if does not find LinkedFile in all dirs down to Defo1 dir, search for Defo*1. 
#									This should allows coping with all type of exotic processings... 
# New in Distro V 3.8 20260211:	- change  way to compare if file is older than another (only use mtime for display)
# New in Distro V 3.9 20260323:	- create a dummy file to compare with cmp if no file exist yet
#								- add options to define LOS mode for NISAR format, that is _LOS_Freq._x where x is A or D
# New in Distro V 4.0 20260731:	- works with msbasv10 (and tif files). In that case, decoration is made of Defo and GoogleEarth only instead of AmpliDefoCoh and Google Earth
#								- may use a second param "COMP" i.e. LOS, EW, UD or NS
# New in Distro V 4.1 20260804:	- tif case: call AmpTif_map.sh with PATHFILEDEFO (AmpTif_map.sh wants the 
#								  deformation tif; PATHFILEAMPLI only exists in the bin case) and test 
#								  the result as in the bin case 
#								- keep MSBAS_LINEAR_RATE_GEOM_*.${FILEXT} in the final cleanup, otherwise 
#								  the tif was deleted and the map rebuilt at every run 
#								- build the mask only in the bin case (AmpTif_map.sh makes its own with 
#								  CreateColorFrame.py) 
#								- limit the search of PATHFILEDEFO_done to _images itself and test it 
#								  with -f/-s instead of wc -c 
#								- delete with -exec rm -f and spare AMSTer.png, as TS_AddLegend_EW_UD.sh 
# New in Distro V 4.2 20260804:	- spare Legend_*_scale.txt when cleaning _images, so that the 
#								  colour bar limits survive the runs that reuse the velocity map 
# New in Distro V 5.0 20260904:	- automatically creates satview.jpg if missing 
#								- automatically update crop values in TS_parameters.txt to cope with possible crop from header.txt
# New in Distro V 5.1 20260904:	- DO NOT ADJUST CROP IN TS_parameters.txt because it offsets the results in the GoogleEarth figure !
#									This offset is only if images are cropped AFTER msbas processing because msbas processing output images at full frame, even if computation is only performed on a crop. 
# 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro 5.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 04, 2026"

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
COMP=$2		# optional LOS, EW, UD or NS

case "${COMP}" in
	LOS|EW|UD|NS) ;;          # valid, keep as is
	*) COMP="" ;;             # anything else (incl. empty/unset) -> empty. Most probably run for LOS; will be assigned later based on RUNDIR 
esac

if [[ ${eps_file} != *".eps" ]]
	then 
		echo "!!!!!!!!!!!  Error:  No eps file valid   !!!!!!!!!"
		echo ""
		exit 1
fi

# Some fct
##########
	function GetParam()
		{
		unset PARAM 
		PARAM=$1
		PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${ParamFile} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
		eval PARAM=${PARAM}
		echo ${PARAM}
		}
	
	
	function resolve_link() {
	    local link="$1"
	    local target
	
	    while [ -L "$link" ]; do
	        target="$(readlink "$link")"
	
	        if [[ "$target" = /* ]]; then
	            link="$target"
	        else
	            link="$(cd "$(dirname "$link")" && printf '%s/%s\n' "$PWD" "$target")"
	        fi
	    done
	
	    if [ -e "$link" ]; then
	        printf '%s\n' "$(cd "$(dirname "$link")" && printf '%s/%s\n' "$PWD" "$(basename "$link")")"
	    fi
		}
	
	# Value(s) of "KEY = ..." in header.txt, all blanks removed (copes with "V_FLAG=0")
	function HdrValue()
		{
		awk -F'=' -v key="$1" '
			{ k = $1 ; gsub(/[[:space:]]/, "", k) }
			k == key { v = $2 ; gsub(/[[:space:]]/, "", v) ; print v ; exit }
			' "$2"
		}
	 
	# Value of the TS_parameters.txt line whose comment holds the tag $1
	function PrmValue()
		{
		awk -v key="$1" '
			$1 ~ /^[-+.0-9]+$/ && $0 ~ ("#[ \t]*" key "([^A-Za-z0-9_]|$)") { print $1 ; exit }
			' "$2"
		}
	 
	# Replace the value of the TS_parameters.txt line whose comment holds the tag $1,
	# keeping the original spacing and comment untouched
	function SetPrmValue()
		{
		awk -v key="$1" -v new="$2" '
			$1 ~ /^[-+.0-9]+$/ && $0 ~ ("#[ \t]*" key "([^A-Za-z0-9_]|$)") { sub(/^[[:space:]]*[-+.0-9]+/, new) }
			{ print }
			' "$3" > "$3".new  &&  mv -f "$3".new "$3"
		}
	 


RUNDIR=$(pwd)
echo "Let's start creating single component time series in the ${RUNDIR} folder'"

eval RegionFolder=$(dirname ${RUNDIR})

#ParamFile=${RegionFolder}/_CombiFiles/TS_parameters.txt
#cp ${RegionFolder}/_CombiFiles/* ${RUNDIR}/_images
# NdO Jan 25 2021

COMBIFILESDIR="${RegionFolder}/_CombiFiles"

mkdir -p ${COMBIFILESDIR}

# ONLY COPY PARAM FILE IF IT DOES NOT EXIST TO PRESERVE POSSIBLE ADJUSTMENTS ALREADY PERFORMED TO PARAM FILE   
#cp -n ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/* ${COMBIFILESDIR}/ 2>/dev/null
#if [ ! -e "${COMBIFILESDIR}/" ] ; then cp "${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/*" "${COMBIFILESDIR}/" ; fi 
for FILE in "${PATH_SCRIPTS}"/SCRIPTS_MT/TSCombiFiles/* ; do
	[ -e "${FILE}" ] || continue
	DEST="${COMBIFILESDIR}/$(basename "${FILE}")"
	if [ ! -e "${DEST}" ] ; then cp -p "${FILE}" "${DEST}" ; fi
done

# Create the satview.jpg if it does not exist
if [ ! -s "${COMBIFILESDIR}/satview.jpg" ]
	then

		# get the reference from the first deformation map in LOS
		for BINMAP in "${RUNDIR}"/*.bin ; do
			if [ -f "${BINMAP}" ] &&  [ -s "${BINMAP}" ] ; then
				REFMAP=${BINMAP}
				break
			fi
		done

		REGIONNAME="$(basename "${RegionFolder}" | cut -d '_' -f 1)"
		CreateBackgroundMaps.sh -e ${REFMAP} -d ${COMBIFILESDIR}  -p ${COMBIFILESDIR}/TS_parameters.txt -f 2 -w "${REGIONNAME}" -v sat
		# Note that TS_parameters.txt is set here with crop size as full image. If crop is applied, it will be updated hare after. 
fi

# NEVER DO THIS (see what's new in 5.1)
# Ensure that the crop requested in TS_parameters.txt is consistent with the WINDOW_SIZE stored in a MSBAS header.txt.
#	# In header.txt :
#	#	FILE_SIZE   = ncol, nlin			(full size of the images)
#	#	WINDOW_SIZE = Cmin, Cmax, Rmin, Rmax	(crop, zero-based, bounds included)
#	#
#	# hence the crop described by the header is
#	#	Crop_X = Cmin			Crop_L = Cmax - Cmin + 1
#	#	Crop_Y = Rmin			Crop_H = Rmax - Rmin + 1
#	#
#	# In TS_parameters.txt the four values are searched by the tag written in their trailing comment (# Crop_X, # Crop_Y, # Crop_L, # Crop_H), never by line
#	# number, so the check keeps working if the file is reordered or commented.
#	
#	HDR="${RUNDIR}"/header.txt		# note for EW/UD, header.txt is in either EW or UD 
#	PRM="${COMBIFILESDIR}/TS_parameters.txt"
#	
#	FILESIZE=$(HdrValue FILE_SIZE "${HDR}")
#	WINDOW=$(HdrValue WINDOW_SIZE "${HDR}")
#	
#	if [ -z "${WINDOW}" ]
#		then
#			echo "  // No usable WINDOW_SIZE in ${HDR}: crop in ${PRM} left untouched"
#		else
#			#NCOL=$(echo "${FILESIZE}" | cut -d, -f1)	# Read from header.txt: FILE_SIZE = 1951, 2751
#			#NLIN=$(echo "${FILESIZE}" | cut -d, -f2)
#			 
#			CMIN=$(echo "${WINDOW}" | cut -d, -f1)	# Read from header.txt: WINDOW_SIZE = 0, 1950, 0, 2750
#			CMAX=$(echo "${WINDOW}" | cut -d, -f2)
#			RMIN=$(echo "${WINDOW}" | cut -d, -f3)
#			RMAX=$(echo "${WINDOW}" | cut -d, -f4)
#			
#			EXPECTED_X=${CMIN}
#			EXPECTED_Y=${RMIN}
#			EXPECTED_L=$(( CMAX - CMIN + 1 ))
#			EXPECTED_H=$(( RMAX - RMIN + 1 ))
#			 
#			# compare with TS_parameters.txt 
#			for CROP in "Crop_X ${EXPECTED_X}" "Crop_Y ${EXPECTED_Y}" "Crop_L ${EXPECTED_L}" "Crop_H ${EXPECTED_H}"
#				do
#					TAG=$(echo "${CROP}" | cut -d' ' -f1)		# from header.txt, e.g. Crop_X
#					EXPECTED=$(echo "${CROP}" | cut -d' ' -f2)	# from header.txt, e.g. ${EXPECTED_X}
#					FOUND=$(PrmValue "${TAG}" "${PRM}")			# from TS_parameters.txt, e.g. 0	from  "0  	# Crop_X (Top left X coordinate of the cropped zone) "
#			 
#					# printf tolerates values written as 1000.0 and makes the test numeric
#					if [ "$(printf "%.0f" "${FOUND}")" -ne "${EXPECTED}" ]
#						then
#							echo "${TAG} = ${FOUND} in ${PRM} while header.txt implies ${EXPECTED}"
#			
#							SetPrmValue "${TAG}" "${EXPECTED}" "${PRM}"
#							echo "	--> ${TAG} set to ${EXPECTED}"
#					fi
#				done
#	fi

#if [ ! -e ${RUNDIR}/_images ]; then mkdir ${RUNDIR}/_images; fi
# NdO Jan 25 2021
mkdir -p ${RUNDIR}/_images
#cp ${COMBIFILESDIR}/* ${RUNDIR}/_images/

ParamFile=${COMBIFILESDIR}/TS_parameters.txt


RateResoSatView=$(GetParam RateResoSatView)

#Orbit=$(echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -o .[Ae]sc | cut -d '_' -f 2)	# Asc or Desc
# NdO Jan 25 2021
#if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "\_LOS\_"| wc -c` -gt 0 ] ; then Orbit=$(echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -o .[Ae]sc | cut -d '_' -f 2) ; OrbitMode="LOS" ; fi	 # Asc or Desc
if [ "${COMP}" == "" ] 
	then 
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "_LOS_"| wc -c` -gt 0 ] 
			then 
				Orbit=$(echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -o _.*sc.*_Auto | cut -d '_' -f 3) 
				OrbitMode="LOS" 
				if [ "${Orbit}" == "" ] ; then Orbit=LineOfSight ; fi
		fi	 # ${Mode}Asc or ${Mode}Desc
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "_UD_" | wc -c` -gt 0 ] ; then Orbit="UD" ; fi	 # UD
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "_EW_" | wc -c` -gt 0 ] ; then Orbit="EW" ; fi	 # EW
		
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "_A_Auto" | wc -c` -gt 0 ] ; then Orbit="Asc" ; fi	 # Asc for ALOS2 type
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "_D_Auto" | wc -c` -gt 0 ] ; then Orbit="Desc" ; fi	 # Asc for ALOS2 type
		
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "LOS_A_" | wc -c` -gt 0 ] ; then Orbit="Asc" ; fi	 # Asc for Nepal area
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "LOS_D_" | wc -c` -gt 0 ] ; then Orbit="Desc" ; fi	 # Asc for Nepal area
		
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "LOS_Freq._A" | wc -c` -gt 0 ] ; then Orbit="Asc" ; fi	 # Asc for NISAR
		if [ `echo $(basename ${RUNDIR}) | ${PATHGNU}/grep -Eo "LOS_Freq._D" | wc -c` -gt 0 ] ; then Orbit="Desc" ; fi	 # Asc for NISAR
		
		if [ "${OrbitMode}" == "LOS" ] ; then TagOrbit="LOS" ; else TagOrbit="${Orbit}" ; fi		# for any unusual format
	else 
		case "${COMP}" in
			EW|UD|NS) 
				Orbit="${COMP}"
				OrbitMode=""
				TagOrbit="${COMP}"
				;;          # valid, keep as is
			LOS)  
				BNAME=$(basename "${RUNDIR}")
				case "${BNAME}" in
					*_Asc_*|*_A_*)  Orbit="Asc" ;;
					*_Desc_*|*_D_*) Orbit="Desc" ;;
					*)              Orbit="LineOfSight" ;;
				esac
				OrbitMode="LOS"
				TagOrbit="LOS"
				;;             # anything else (incl. empty/unset) -> empty. Most probably run for LOS; will be assigned later based on RUNDIR 
		esac

fi	
echo "eps file to be decorated = ${eps_file}"
echo "Orbit type: ${Orbit}"

#ln -s ${COMBIFILESDIR}/* ${RUNDIR}/_images  >> /dev/null 2>&1
cp -f ${COMBIFILESDIR}/* ${RUNDIR}/_images  >> /dev/null 2>&1

# find deformation velocity file in this directory
#-----------------------------------------------
#PATHFILEDEFO=$(find ${RUNDIR} -type f -name "MSBAS_LINEAR_RATE_LOS.bin")  # !!! remove * !!!
# NdO Jan 25 2021 

PATHFILEDEFO=$(find ${RUNDIR} -maxdepth 1 -type f -name "MSBAS_LINEAR_RATE_${TagOrbit}.bin")  # !!! remove * !!!	
if [ -f "${PATHFILEDEFO}" ]
	then 
		echo "msbasv4 results"
		FILEXT="bin"
		TYPEAMPLI="Ampli-Defo-Coh"
	else 
		PATHFILEDEFO=$(find ${RUNDIR} -maxdepth 1 -type f -name "MSBAS_LINEAR_RATE_${TagOrbit}.tif") 
		if [ -f "${PATHFILEDEFO}" ]
			then 
				echo "msbasv10 results"
				FILEXT="tif"
				TYPEAMPLI="Ampli"
			else 
				echo "Can't find the MSBAS_LINEAR_RATE_${TagOrbit}.bin nor .tif; exiting..."
				exit 1
		fi
fi

mtime=$(${PATHGNU}/gstat -c %y ${PATHFILEDEFO})
mtime=${mtime:8:2}	#extract creation day
echo "PATHFILEDEFO = $PATHFILEDEFO"
# NdO Jan 25 2021
echo "Last modification day of \"MSBAS_LINEAR_RATE_${TagOrbit}.${FILEXT}\" file in MSBAS directory is ${mtime}"

#PATHFILEDEFO_done=$(find ${RUNDIR}/_images -type f -name "MSBAS_LINEAR_RATE_LOS_${Orbit}.bin")  # !!! remove * !!!
# NdO Jan 25 2021 - and replace everywhere here after LOS_${Orbit} with GEOM_${Orbit}
PATHFILEDEFO_done=$(find ${RUNDIR}/_images -maxdepth 1 -type f -name "MSBAS_LINEAR_RATE_GEOM_${Orbit}.${FILEXT}")  # !!! remove * !!!
echo "test max: ${PATHFILEDEFO_done}"
if [ -f "${PATHFILEDEFO_done}" ] && [ -s "${PATHFILEDEFO_done}" ] 		# [ `echo ${PATHFILEDEFO_done} | wc -c` -gt 1 ] 
	then 
		mtime2=$(${PATHGNU}/gstat -c %y ${PATHFILEDEFO_done}) 
		mtime2=${mtime2:8:2}	#extract creation day
		echo "Last modification day of \"MSBAS_LINEAR_RATE_${TagOrbit}.${FILEXT}\" file in our \"_images\" directory is ${mtime2}"
	else 
		echo "First time decoration of MSBAS_LINEAR_RATE_${TagOrbit}.${FILEXT}"
		mtime2=0
		touch "${RUNDIR}/dummy.tmp"
		PATHFILEDEFO_done="${RUNDIR}/dummy.tmp"

fi

# Creation of new Velocity map only if a new one is available
#---------------------------------------------------------------
# if [[ ${mtime} != ${mtime2} ]] || [ ! -e ${RUNDIR}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit}.jpg ] 
if ! cmp -s ${PATHFILEDEFO} ${PATHFILEDEFO_done} || [ ! -e ${RUNDIR}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit}.jpg ] 
	then 
			echo ""
			echo "----------->   Prepare file for creating new ${TYPEAMPLI} jpeg file for GEOM_${Orbit}:"
			echo ""
			sleep 2
			
			# prefer -exec rm -f to -delete to avoid ghost smb files, and keep the logo 
			find ${RUNDIR}/_images -type f ! -name "TS_*" ! -name "AMSTer.png" -exec rm -f {} \;
			DEFO="MSBAS_LINEAR_RATE_GEOM_${Orbit}.${FILEXT}"
			cp -p $PATHFILEDEFO ${RUNDIR}/_images/${DEFO}
			#ln -s ${PATHFILEDEFO}.hdr ${RUNDIR}/_images/${DEFO}.hdr
			if [ "${FILEXT}" == "bin" ] ; then 
				cp -f ${PATHFILEDEFO}.hdr ${RUNDIR}/_images/${DEFO}.hdr
			fi
			PATHFILEDEFO=${RUNDIR}/_images/${DEFO}

			PATHFILECOH=$(echo "${PATHFILEDEFO//MSBAS_LINEAR_RATE/MSBAS_MASK}")
			#echo "PATHFILEDEFO = $PATHFILEDEFO"
			#echo "PATHFILECOH = $PATHFILECOH"


			# find the corresponding amplitude file
			#-----------------------------------------------
			if [ "${FILEXT}" == "bin" ] ; then 

				# Creation of the mask
				#---------------------
				${PATH_SCRIPTS}/SCRIPTS_MT/Mask_Builder.py ${PATHFILEDEFO} ${PATHFILECOH}   >> /dev/null 2>&1

				#echo "RegionFolder = ${RegionFolder}"
				LinkedFile=$(find ${RegionFolder}/DefoInterpolx2Detrend1/ -name "defo*deg" 2>/dev/null | head -1)
	
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
				#ln -s ${AmpliFolder}/${AmpliFile} ${RUNDIR}/_images/${AmpliFile}
				#ln -s ${AmpliFolder}/${AmpliFile}.hdr ${RUNDIR}/_images/${AmpliFile}.hdr
				cp -f ${AmpliFolder}/${AmpliFile} ${RUNDIR}/_images/${AmpliFile}
				cp -f ${AmpliFolder}/${AmpliFile}.hdr ${RUNDIR}/_images/${AmpliFile}.hdr
 				PATHFILEAMPLI=${RUNDIR}/_images/${AmpliFile}

				echo "PATHFILEAMPLI = $PATHFILEAMPLI"
				echo "PATHFILECOH = $PATHFILECOH"

			fi

			echo "PATHFILEDEFO = $PATHFILEDEFO"

			# Create the image (Amplitude-coherence-deformation) + creating a legend (AmpDefo_map.sh)
			#----------------------------------------------------------------------------------------
			echo ""
			echo "-----------> Start script to create ${TYPEAMPLI} jpeg image "
			#echo "${PATH_SCRIPTS}/SCRIPTS_MT/AmpDefo_map.sh ${PATHFILEAMPLI} ${PATHFILECOH} ${PATHFILEDEFO} AMPLI_COH_MSBAS_LINEAR_RATE_LOS_${Orbit}"

			if [ "${FILEXT}" == "bin" ]
				then
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
					${PATH_SCRIPTS}/SCRIPTS_MT/AmpTif_map.sh ${PATHFILEDEFO} AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit} >> /dev/null 
					if [ -e ${RUNDIR}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit}.jpg ]
						then echo "----------->  Succeeded " ; echo ""
						else echo "----------->  failed "    ; echo ""
					fi
			fi
	else
		echo ""
		echo "----------->  No need to rebuild Amplitude-Coherence-Deformation image "
		echo ""
fi

rm -f "${RUNDIR}/dummy.tmp" 2>/dev/null

# Creation of time series illustrated with velocity legend + displacement interpretation
#-----------------------------------------------------------------------------------------
echo ""
echo "-----------> Start script to convert eps to jpeg file with crop, legend and interpretation of deformation: "

rm -f ${RUNDIR}/_images/satview.jpg  	# allows to operate from different computers
##ln -s ${COMBIFILESDIR}/satview.jpg ${RUNDIR}/_images  >> /dev/null 2>&1
##ln -s ${COMBIFILESDIR}/AMSTer.png ${RUNDIR}/_images  >> /dev/null 2>&1
cp -f ${COMBIFILESDIR}/satview.jpg ${RUNDIR}/_images  >> /dev/null 2>&1
cp -f ${COMBIFILESDIR}/AMSTer.png ${RUNDIR}/_images  >> /dev/null 2>&1

${PATH_SCRIPTS}/SCRIPTS_MT/TimeSeriesInfo_HP.sh ${eps_file} ${RUNDIR}/_images/AMPLI_COH_MSBAS_LINEAR_RATE_GEOM_${Orbit}.jpg ${RateResoSatView}  #>> /dev/null 




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
# NdO Aug 04 2026: spare Legend_*_scale.txt as well. It holds the limits the colour bar was built 
# with and is only rewritten when AmpTif_map.sh runs, i.e. NOT on the runs that reuse the existing 
# velocity map; deleting it here would leave TimeSeriesInfo_HP.sh (SCALEFROM=LEGEND) without it. 
find ${RUNDIR}/_images -type f ! \( -name "*.jpg" -o -name "*_scale.txt" -o -name "MSBAS_LINEAR_RATE_GEOM_${Orbit}.${FILEXT}" \) -exec rm -f {} \;
find ${RUNDIR}/_images -type l ! \( -name "*.jpg" -o -name "*_scale.txt" -o -name "MSBAS_LINEAR_RATE_GEOM_${Orbit}.${FILEXT}" \) -exec rm -f {} \;

echo ""
echo "------------- end ------------"
echo ""