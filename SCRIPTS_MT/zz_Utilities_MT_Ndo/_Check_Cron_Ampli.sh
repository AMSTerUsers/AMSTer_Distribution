#!/bin/bash
######################################################################################
# This script list the X last scheduled AMPLITUDE processes and check what was performed. 
# Note that because there is no revisiting time defined for CSK, it takes into account
# all the X last existing raw images
#
# Dependencies:	- color terminal
#				- gnu sed
#
# A lot is hard coded for each mode
# 
# New in V 1.1:	- stop searching for CSK files when all files in Auto_Curl are checked to avoid infinite loop when less than OLDCSK images are present in dir 
# New in V 1.2 (Aug 11, 2021):	- improve display in column
#				- take into account the loss of Sentinel 1B on 23 December 2021, ultimately announced as decommissioned on August 3 2022
#				- loop search CSK images till k+15 because of long delay between acq and delivery and only keep limited nr of images in raw dir
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# How many iumages to check from now 
OLD=8		#  X last expected S1 images
OLDCSK=8 	#  X last existing raw CSK images

# Hard coded : Length of interval between images (in days)
DELTAS1=12 		# Nr of days expected between 2 S1 images acquired in that mode (e.g. 12 daysfor S1)
DELTACSK=1
# See more hard coded before checking each mode

# basics
TODAY=`date '+%Y%m%d'`
TODAYSEC=`date -d"${TODAY} 12:00:00" +%s`

# Color code for ouput
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
bold=$(tput bold)
underline=$(tput smul)
reverse=$(tput smso)
normal=$(tput sgr0)

# BLACK=$(tput setaf 0)
# RED=$(tput setaf 1)
# GREEN=$(tput setaf 2)
# YELLOW=$(tput setaf 3)
# LIME_YELLOW=$(tput setaf 190)
# POWDER_BLUE=$(tput setaf 153)
# BLUE=$(tput setaf 4)
# MAGENTA=$(tput setaf 5)
# CYAN=$(tput setaf 6)
# WHITE=$(tput setaf 7)
# BRIGHT=$(tput bold)
# NORMAL=$(tput sgr0)
# BLINK=$(tput blink)
# REVERSE=$(tput smso)
# UNDERLINE=$(tput smul)



# functions
############
# Output date of Xth image since today, provided that following param are rovided: DELTAimg DATE1stImg XthImgeBeforeNow
# Call it eg like 
	#GetXthFormerImg ${DELTAS1} ${FIRSTS1ASC174} 1 
	function GetXthFormerImg()
		{
		unset DELTA 		#  Interval in days of image acquisition in that mode
		unset FIRSTIMG		#  Date of first image YYYYMMDD acquired in that mode 
		unset X 			#  (X=1 means last image before Today; 2 = previous one etc)

		DELTA=$1
		FIRSTIMG=$2
		X=$3

		FIRSTIMGSEC=`date -d"${FIRSTIMG} 12:00:00" +%s`  		# Date if first img in sec
		DELTASEC=`echo "( ${DELTA} * 86400 ) " | bc`	# Interval in sec of image acquisition in that mode
		NROFIMG=`echo "( ${TODAYSEC} - ${FIRSTIMGSEC} ) / ${DELTASEC}" | bc`  # Nr of images acquired in that mode since first image (bc answers only integer part which is what we want)
		LASTIMGSEC=`echo "(( (${NROFIMG} - ${X} + 1 ) * ${DELTASEC} ) + ${FIRSTIMGSEC} )  " | bc`

		LASTSIMG=`date -d @${LASTIMGSEC} +"%Y%m%d"`		# Date of Xth image from now

		#echo "Date of ${X}th image from Today is: ${LASTSIMG} "
		}

	function GetXthFormerImgCSK()
		{
		unset DELTA 		#  Interval in days of image acquisition in that mode
		unset FIRSTIMG		#  Date of first image YYYYMMDD acquired in that mode 
		unset EXPECTEDTIME	#  hh time of acquisition (written in file name); required to assess if asc or desc

		DELTA=$1
		FIRSTIMG=$2
		EXPECTEDTIME=$3

		k=0

		while [ "${TST}" == "OFF" ]
		do
				j=($j+1)
				k=`echo "(${k}) + 1" | bc`
				
				FIRSTIMGSEC=`date -d"${FIRSTIMG} 12:00:00" +%s`  		# Date if first img in sec
				DELTASEC=`echo "( ${DELTA} * 86400 ) " | bc`	# Interval in sec of image acquisition in that mode
				NROFIMG=`echo "( ${TODAYSEC} - ${FIRSTIMGSEC} ) / ${DELTASEC}" | bc`  # Nr of images acquired in that mode since first image (bc answers only integer part which is what we want)
				LASTIMGSEC=`echo "(( (${NROFIMG} - (${j}) + 1 ) * ${DELTASEC} ) + ${FIRSTIMGSEC} )  " | bc`
				LASTSIMG=`date -d @${LASTIMGSEC} +"%Y%m%d"`		# Date of Xth image from now

				# check raw:
				LAST1=`find ${PATHRAW}/ -maxdepth 1 -type f -name "CSK*${LASTSIMG}${EXPECTEDTIME}*.zip" | wc -l | ${PATHGNU}/gsed "s/ //g"`
#				echo "find ${PATHRAW}/ -maxdepth 1 -type f -name "CSK*${LASTSIMG}${EXPECTEDTIME}*.zip" | wc -l"
#				echo "${LAST1}"
				if [ "${LAST1}" == "0" ] 
					then 
						#Because there is no predefnied revisiting time with CSK, to avoid displaying missing at every day that we are obliged to test, let's skip that i when there is no data
						TST="OFF"
					else 
						TST="ON"
				fi 
				if [ `echo "(${k}) + 5" | bc` -eq ${MAXNRFILES} ] # because of long delay between acq and delivery and only keep limited nr of images in raw dir, must for security check on longer span (e.g k + 15)
					then 
						CONSISTENCY="Probably too old and hence not anymore in temporary download dir"
						break 
				fi
		done

		#echo "Date of ${X}th image from Today is: ${LASTSIMG} "
		}

function PrintHeaderShadows()
	{
	HD1="From Now"
	HD2="Expected"
	HD3="Raw"
	HD4="CSL"
	HD6="AMPLI"
	HD9="Remark"

	echo ""	
	printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-50s\n"  "${underline}${bold} ${HD1}" "${HD2}" "${HD3}" "${HD4}" "${HD6}" "${HD9}${normal}"
	}	

function PrintHeaderShadowsCSK()
	{
	HD1="From Now"
	HD2="Last Raw"
	HD3="Raw"
	HD4="CSL"
	HD6="AMPLI"
	HD9="Remark"

	echo ""
	printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-50s\n"  "${underline}${bold} ${HD1}" "${HD2}" "${HD3}" "${HD4}" "${HD6}" "${HD9}${normal}"
	}	


function CheckS1Shadows()
		{
			# Provide date of expected ith last imag as LASTSIMG
			GetXthFormerImg ${DELTAS1} ${FIRSTIMG} $i 

			# check raw:
			LAST1=`find ${PATHRAW}/ -maxdepth 1 -type d -name "S1${SENSOR}*${LASTSIMG}T*" | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ "${LAST1}" == "0" ] ; then LASTRAW="${reverse} missing       ${normal}" ; else LASTRAW="OK, ${LAST1} dirs "	; fi

			# check CSL:
			LAST2=`find ${PATHCSL}/ -maxdepth 1 -type d -name "S1${SENSOR}*${LASTSIMG}*.csl" | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ "${LAST2}" == "0" ] ; then LASTCSL="${reverse} missing       ${normal}" ; else LASTCSL="OK, ${LAST2} dir " ; fi

			#LAST2=`find ${PATHCSL}/S1${SENSOR}*${LASTSIMG}*.csl/Info/ -maxdepth 1 -type f -name "SLCImageInfo.txt*" | wc -l`
			#if [ ${LAST2} -lt 1 ] ; then LASTCSL="${reverse} miss SLC.txt  ${normal}" ; else LASTCSL="OK, ${LAST21} SLC.txt " ; fi 



			# check AMPLI:
			LAST4=`find ${PATHAMPLI}/_AMPLI/ -maxdepth 1 -type f -name "*${LASTSIMG}*.jpg" | wc -l | ${PATHGNU}/gsed "s/ //g"`
			# and dir in AMPLI
			LAST5=`find ${PATHAMPLI}/ -maxdepth 1 -type d -name "*_${LASTSIMG}_*" | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ "${LAST4}" == "0" ]  
				then 
					LASTAMP="${reverse} missing       ${normal}" 
					if [ "${LAST5}" != "0" ] ; then CONSISTENCY="No Dir neither in AMPLI, hence not processed" ; fi
				else 
					LASTAMP="OK, ${LAST5} file " 
					if [ "${LAST5}" == "0" ] ; then  CONSISTENCY="Thought no Dir in AMPLI. Check why (Normal for Nyam S1 D21)." ; fi
			fi

			# Check if S1B after failure on December 23 2021
			if [ ${LASTIMGSEC} -gt 1640257200 ] && [ "${SENSOR}" == "B" ] # 1640257200 is 2021 12 23 in sec
				then 
					CONSISTENCY="${reverse}Sentinel 1B not operationnal since December 23 2021.${normal}"
			fi


			# Print line
			printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-50s\n" "$i" "${LASTSIMG}" "${LASTRAW}" "${LASTCSL}" "${LASTAMP}" "${CONSISTENCY}" 
			
			CONSISTENCY=""
		}
		
function CheckCSKShadows()
		{
			# Provide date of expected ith last imag as LASTSIMG
			GetXthFormerImgCSK ${DELTACSK} ${FIRSTIMG} ${EXPECTEDTIME}

			# check raw:
			LAST1=`find ${PATHRAW}/ -maxdepth 1 -type f -name "CSK*${LASTSIMG}*.zip" | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ "${LAST1}" == "0" ] ; then LASTRAW="${reverse} missing       ${normal}" ; else LASTRAW="OK, ${LAST1} dirs "	; fi

			# check CSL:
			LAST2=`find ${PATHCSL}/*${LASTSIMG}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ "${LAST2}" == "0" ] ; then LASTCSL="${reverse} missing       ${normal}" ; else LASTCSL="OK, ${LAST2} file " ; fi

			# check AMPLI:
			LAST4=`find ${PATHAMPLI}/_AMPLI/ -maxdepth 1 -type f -name "*${LASTSIMG}*.jpg" | wc -l | ${PATHGNU}/gsed "s/ //g"`
			# and dir in AMPLI
			LAST5=`find ${PATHAMPLI}/ -maxdepth 1 -type d -name "*_${LASTSIMG}_*" | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ "${LAST4}" == "0" ]  
				then 
					LASTAMP="${reverse} missing       ${normal}" 
					if [ "${LAST5}" != "0" ] ; then CONSISTENCY="No Dir neither in AMPLI, hence not processed" ; fi
				else 
					LASTAMP="OK, ${LAST5} file " 
					if [ "${LAST5}" == "0" ] ; then  CONSISTENCY="Thought no Dir in AMPLI. Check why (Normal for Nyam S1 D21)." ; fi
			fi

			# Print line
			printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-50s\n" "$i" "${LASTSIMG}" "${LASTRAW}" "${LASTCSL}" "${LASTAMP}" "${CONSISTENCY}" 
			
			CONSISTENCY=""
		}	
	
# Let's go...
clear 
echo
echo "############################"
echo "# Shadows S1 NYIGO"
echo "############################"
PrintHeaderShadows
	PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP

	PATHCSL=$PATH_1650/SAR_CSL/S1/DRC_NyigoCrater_A_174/NoCrop
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/S1/DRC_NyigoCrater_A_174/Nyigo_crater_originalForm
echo "${bold}Nyigo Shadows Sentinel-1 Asc 174; satellite A${normal}"
	FIRSTIMG=20141017  # YYYYMMDD
	SENSOR=A
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done
echo "${bold}Nyigo Shadows Sentinel-1 Asc 174; satellite B${normal}"
	FIRSTIMG=20180616  # YYYYMMDD
	SENSOR=B
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done

echo ""
PrintHeaderShadows
	PATHCSL=$PATH_1650/SAR_CSL/S1/DRC_NyigoCrater_D_21/NoCrop
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/S1/DRC_NyigoCrater_D_21/Nyigo_Nyam_crater_originalForm

echo "${bold}Nyigo Shadows Sentinel-1 Desc 21; satellite A${normal}"
	FIRSTIMG=20141007  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done
echo "${bold}Nyigo Shadows Sentinel-1 Desc 21; satellite B${normal}"
	FIRSTIMG=20170307  # YYYYMMDD
	SENSOR=B
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done
	
echo	
echo "############################"
echo "# Shadows CSK NYIGO"
echo "############################"
PrintHeaderShadowsCSK
	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/CSK/SuperSite/Auto_Curl
	MAXNRFILES=`ls ${PATHRAW} | wc -l | ${PATHGNU}/gsed "s/ //g"`

	PATHCSL=$PATH_1650/SAR_CSL/CSK/Virunga_Asc/Crop_Nyigo2_-1.454--1.575_29.245-29.250
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/CSK/Virunga_Asc/Nyigo2
echo "${bold}Nyigo Shadows CSK Asc${normal}"
	FIRSTIMG=20110415  # YYYYMMDD
	EXPECTEDTIME=04		# hh time of acquisition (written in file name); required to assess if asc or desc

	j=0
	# Check the last images
	for i in $(seq 1 ${OLDCSK})			
		do 
			TST="OFF"
			CheckCSKShadows
	done

PrintHeaderShadowsCSK
	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/CSK/SuperSite/Auto_Curl

	PATHCSL=$PATH_1650/SAR_CSL/CSK/Virunga_Desc/Crop_NyigoCrater2_-1.500--1.560_29.280-29.281
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/CSK/Virunga_Desc/NyigoCrater2
echo "${bold}Nyigo Shadows CSK Desc${normal}"
	FIRSTIMG=20110413  # YYYYMMDD
	EXPECTEDTIME=15		# hh time of acquisition (written in file name); required to assess if asc or desc

	j=0
	# Check the last images
	for i in $(seq 1 ${OLDCSK})			
		do 
			TST="OFF"
			CheckCSKShadows
	done

echo	
echo "############################"
echo "# Shadows S1 NYAM"
echo "############################"
PrintHeaderShadows
	PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP

	PATHCSL=$PATH_1650/SAR_CSL/S1/DRC_NyamCrater_A_174/NoCrop
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/S1/DRC_NyamCrater_A_174/Nyam_crater_originalForm
echo "${bold}Nyam Shadows Sentinel-1 Asc 174; satellite A${normal}"
	FIRSTIMG=20141017  # YYYYMMDD
	SENSOR=A
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done
echo "${bold}Nyam Shadows Sentinel-1 Asc 174; satellite B${normal}"
	FIRSTIMG=20180616  # YYYYMMDD
	SENSOR=B
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done

PrintHeaderShadows
	PATHCSL=$PATH_1650/SAR_CSL/S1/DRC_NyamCrater_D_21/NoCrop
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/S1/DRC_NyamCrater_D_21/

echo "${bold}Nyam Shadows Sentinel-1 Desc 21; satellite A${normal}"
	FIRSTIMG=20141007  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done
echo "${bold}Nyam Shadows Sentinel-1 Desc 21; satellite B${normal}"
	FIRSTIMG=20170307  # YYYYMMDD
	SENSOR=B
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done

echo	
echo "############################"	
echo "# Shadows CSK NYAM"
echo "############################"
PrintHeaderShadows
	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/CSK/SuperSite/Auto_Curl

	PATHCSL=$PATH_1650/SAR_CSL/CSK/Virunga_Asc/Crop_NyamCrater2_-1.327--1.485_29.145-29.250
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/CSK/Virunga_Asc/NyamCrater2
echo "${bold}Nyam Shadows CSK Asc${normal}"
	FIRSTIMG=20110415  # YYYYMMDD
	EXPECTEDTIME=04		# hh time of acquisition (written in file name); required to assess if asc or desc
	# Check the last images
	
	j=0
	for i in $(seq 1 ${OLDCSK})			
		do 
			TST="OFF"
			CheckCSKShadows
	done

PrintHeaderShadows
	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/CSK/SuperSite/Auto_Curl

	PATHCSL=$PATH_1650/SAR_CSL/CSK/Virunga_Desc/Crop_NyamCrater2_-1.327--1.480_29.160-29.220
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/CSK/Virunga_Desc/NyamCrater2
echo "${bold}Nyam Shadows CSK Desc${normal}"
	FIRSTIMG=20110413  # YYYYMMDD
	EXPECTEDTIME=15		# hh time of acquisition (written in file name); required to assess if asc or desc
	j=0
	# Check the last images
	for i in $(seq 1 ${OLDCSK})			
		do 
			TST="OFF"
			CheckCSKShadows
	done

echo
echo "############################"
echo "# Shadows Hawaii"
echo "############################"
PrintHeaderShadows
	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/S1/S1-DATA-HAWAII-SLC.UNZIP

	PATHCSL=$PATH_3601/SAR_CSL_Other_Zones/S1/Hawaii_LL_A_124/NoCrop
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/S1/Hawaii_LL_A_124/Hawaii_LL_Crater_originalForm
echo "${bold}Hawaii Shadows Sentinel-1 Asc 124; satellite A${normal}"
	FIRSTIMG=20141213  # YYYYMMDD
	SENSOR=A
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done
echo "${bold}Hawaii Shadows Sentinel-1 Asc 124; satellite B${normal}"
	FIRSTIMG=20161021  # YYYYMMDD
	SENSOR=B
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done

PrintHeaderShadows
	PATHCSL=$PATH_3601/SAR_CSL_Other_Zones/S1/Hawaii_LL_D_87/NoCrop
	PATHAMPLI=$PATH_1650/SAR_SM/AMPLITUDES/S1/Hawaii_LL_D_87/Hawaii_LL_Crater_originalForm

echo "${bold}Hawaii Shadows Sentinel-1 Desc 21; satellite A${normal}"
	FIRSTIMG=20141116  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done
echo "${bold}Hawaii Shadows Sentinel-1 Desc 21; satellite B${normal}"
	FIRSTIMG=20161030  # YYYYMMDD
	SENSOR=B
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1Shadows
	done
