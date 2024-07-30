#!/bin/bash
######################################################################################
# This script list the X last scheduled mass processes and check what was performed. 
# Note that because there is no revisiting time defined for CSK, it takes into account
# all the X last existing raw images
#
# Dependencies:	- color terminal
#				- gnu sed and awk	
#				- python script _Check_kml_in_kml 		
#
# A lot is hard coded for each mode
# 
# New in V 1.1:	- Check if images are in __TMP_QUARANTINE
# New in V 1.2:	- correct testsing -eq, mute possible error in find commands and define LAST21 when LSAT2 is not 0
#				- check if data is in /Quarantained
# New in V 2.0:	- work with more fct 
#				- OK with D Derauw or L Libert tools used to list the pairs
# New in V 2.1:	- if both DD and LL tools were used, search for more recent file where to check if pair could be if no in table, 
#				  that is allPairsListing.txt or approximateBaselinesTable.txt 
# New in V 2.2:	- Fill more info (and correct) for PF
# New in V 2.3:	- get date with PATHGNU path
# New in V 3.0: - take into account the loss of Sentinel 1B on 23 December 2021, ultimately announced as decommissioned on August 3 2022
#				- improve search for the nr of days in DD tables when BP is negative
#				- improve display in column
# New in V 3.1: - Update PATH
#				- comment everything about S1B
#				- add Karthala and Guadeloupe
# New in V 3.2: - Skip VVP CSK by searching for 0 last images 
# New in V 3.3: - update table for Karthala with dual criteria
# New in V 3.4: - if nr of MASS_PROCESS & geocoded = 0 but image is in MSBAS, check that it is indeed in S1_CLN
#				- get back search on VVP CSK
# New in V 3.5 (Aug 9, 2023): - Search the acq time in RAW CSK naming compatible with new format
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20231219:	- Add check LagunaFea SAOCOM
# New in Distro V 4.2 20240104:	- Add comment when image can't be resampled on Global Primary though can be used as Slave
#								- Display message when image is Global Primary
#								- Display only the shortest Bp from + and - value obtained for a given Bt and display message on 2 more lines
# New in Distro V 4.3 20240208:	- if SAOCOM not read, check if it related to not overlapping kml
# New in Distro V 4.4 20240307:	- debug unzip kml of SAOCOM image for checking AOI
# New in Distro V 4.5 20240423:	- update tables
#								- add Funu
# New in Distro V 4.6 20240717:	- update baselines for some targets (VVP, Domuyo, LUX, PF)
#								- check VVP CSK at the end 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.6 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 17, 2024"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "


# How many iumages to check from now 
OLD=5		#  X last expected S1 images
OLDCSK=2 	#  X last existing raw CSK images
OLDSAOCOM=5 #  X last existing raw Saocom images

# Hard coded : Length of interval between images (in days)
DELTAS1=12 		# Nr of days expected between 2 S1 images acquired in that mode (e.g. 12 daysfor S1)
DELTACSK=1 		# Nr of days expected between 2 CSK images acquired in that mode (for a constellation)
DELTASAOCOM=8 	# Nr of days expected between 2 SAOCOM images acquired in that mode (for a constellation)

# See more hard coded before checking each mode

# basics
TODAY=`${PATHGNU}/gdate '+%Y%m%d'`
TODAYSEC=`${PATHGNU}/gdate -d"${TODAY} 12:00:00" +%s`

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

# Check OS
OS=`uname -a | cut -d " " -f 1 `
case ${OS} in 
	"Linux") 
		MOUNTPT=/mnt ;;
	"Darwin")
		MOUNTPT=/Volumes ;;
esac
	
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

		FIRSTIMGSEC=`${PATHGNU}/gdate -d"${FIRSTIMG} 12:00:00" +%s`  		# Date if first img in sec
		DELTASEC=`echo "( ${DELTA} * 86400 ) " | bc`	# Interval in sec of image acquisition in that mode
		NROFIMG=`echo "( ${TODAYSEC} - ${FIRSTIMGSEC} ) / ${DELTASEC}" | bc`  # Nr of images acquired in that mode since first image (bc answers only integer part which is what we want)
		LASTIMGSEC=`echo "(( (${NROFIMG} - ${X} + 1 ) * ${DELTASEC} ) + ${FIRSTIMGSEC} )  " | bc`

		LASTSIMG=`${PATHGNU}/gdate -d @${LASTIMGSEC} +"%Y%m%d"`		# Date of Xth image from now

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

		while [ "${TST}" == "OFF" ]
		do
			j=($j+1)
			
			FIRSTIMGSEC=`${PATHGNU}/gdate -d"${FIRSTIMG} 12:00:00" +%s`  		# Date if first img in sec
			DELTASEC=`echo "( ${DELTA} * 86400 ) " | bc`	# Interval in sec of image acquisition in that mode
			NROFIMG=`echo "( ${TODAYSEC} - ${FIRSTIMGSEC} ) / ${DELTASEC}" | bc`  # Nr of images acquired in that mode since first image (bc answers only integer part which is what we want)
			LASTIMGSEC=`echo "(( (${NROFIMG} - (${j}) + 1 ) * ${DELTASEC} ) + ${FIRSTIMGSEC} )  " | bc`
			LASTSIMG=`${PATHGNU}/gdate -d @${LASTIMGSEC} +"%Y%m%d"`		# Date of Xth image from now

			# check raw:
			#LAST1=`find ${PATHRAW}/ -maxdepth 1 -type f -name "CSK*${LASTSIMG}${EXPECTEDTIME}*.zip" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			LAST1=`find ${PATHRAW}/ -maxdepth 1 -type f -name "C*${LASTSIMG}${EXPECTEDTIME}*.zip" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST1} -eq 0 ] 
				then 
					#Because there is no predefnied revisiting time with CSK, to avoid displaying missing at every day that we are obliged to test, let's skip that i when there is no data
					TST="OFF"
				else 
					TST="ON"
			fi 
		done

		#echo "Date of ${X}th image from Today is: ${LASTSIMG} "
		}

	function GetXthFormerImgSAOCOM()
		{
		unset DELTA 		#  Interval in days of image acquisition in that mode
		unset FIRSTIMG		#  Date of first image YYYYMMDD acquired in that mode 
		unset EXPECTEDTIME	#  hh time of acquisition (written in file name); required to assess if asc or desc

		DELTA=$1
		FIRSTIMG=$2
		EXPECTEDTIME=$3

		while [ "${TST}" == "OFF" ]
		do
			j=($j+1)
			
			FIRSTIMGSEC=`${PATHGNU}/gdate -d"${FIRSTIMG} 12:00:00" +%s`  		# Date if first img in sec
			DELTASEC=`echo "( ${DELTA} * 86400 ) " | bc`	# Interval in sec of image acquisition in that mode
			NROFIMG=`echo "( ${TODAYSEC} - ${FIRSTIMGSEC} ) / ${DELTASEC}" | bc`  # Nr of images acquired in that mode since first image (bc answers only integer part which is what we want)
			LASTIMGSEC=`echo "(( (${NROFIMG} - (${j}) + 1 ) * ${DELTASEC} ) + ${FIRSTIMGSEC} )  " | bc`
			LASTSIMG=`${PATHGNU}/gdate -d @${LASTIMGSEC} +"%Y%m%d"`		# Date of Xth image from now

			# check raw:
			EXPECTEDYYYY=`echo ${LASTSIMG} | cut -c 1-4 `
			EXPECTEDMM=`echo ${LASTSIMG} | cut -c 5-6 `
			EXPECTEDDD=`echo ${LASTSIMG} | cut -c 7-8 `
			#LAST1=`find ${PATHRAW}/ -maxdepth 2 -mindepth 1 -type f -name "*.xemt" -exec grep -m 1 startTime {} \; | sed -n '/<startTime>${EXPECTEDYYYY}-${EXPECTEDMM}-${EXPECTEDDD}T${EXPECTEDTIME}:/p' 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			eval LAST1=`find ${PATHRAW}/ -maxdepth 2 -mindepth 1 -type f -name "*.xemt" -exec grep -m 1 startTime {} \; | sed -n '/<startTime>'${EXPECTEDYYYY}'-'${EXPECTEDMM}'-'${EXPECTEDDD}'T'${EXPECTEDTIME}'/p' 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`

			
			if [ ${LAST1} -eq 0 ] 
				then 
					#Because there is no predefnied revisiting time with SAOCOM, to avoid displaying missing at every day that we are obliged to test, let's skip that i when there is no data
					TST="OFF"
				else 
					TST="ON"
			fi 
		done

		#echo "Date of ${X}th image from Today is: ${LASTSIMG} "
		}

# Check if img is in baseline plot table or in approximateBaselinesTable.txt
	function ImgInPlotTable()
		{
		INBP=`grep ${LASTSIMG} ${PATHBASELINE} | wc -l | ${PATHGNU}/gsed "s/ //g"`
		if [ ${INBP} -eq 0 ] 
			then 
				# not in baseline plot table; check in approximateBaselinesTable.txt or allPairsListing.txt
				DATEBP=`${PATHGNU}/gdate -r ${PATHBASELINE} +%F`
				PATHTABLE=`dirname ${PATHBASELINE}`

				if [ -f ${PATHTABLE}/allPairsListing.txt ]  # i.e. DD tools were used
					then 
						if [ -f ${PATHTABLE}/approximateBaselinesTable.txt ] # i.e. LL tools were used
							then 
								# search for the most recent tools used	
								if [ `ls -t ${PATHTABLE}/approximateBaselinesTable.txt ${PATHTABLE}/allPairsListing.txt | head -1` == "${PATHTABLE}/allPairsListing.txt" ] ; then TOOLS="DD" ; else TOOLS="LL" ; fi
							else 
								# only DD tools used
								TOOLS="DD"
						fi
					else 
						if [ -f ${PATHTABLE}/approximateBaselinesTable.txt ] 
							then
								# only LL tools used
								TOOLS="LL"
							else
								echo "Can't find  approximateBaselinesTable.txt nor allPairsListing.txt; exit"
								exit 0 			
						fi
				fi

				case ${TOOLS} in 
							"LL")    
								#echo "Tools by L Libert were probably used to compute the list of compatible pairs; Search pairs in ${PATHTABLE}/approximateBaselinesTable.txt"  
								# 
								INTABLE=`grep ${LASTSIMG} ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | wc -l | ${PATHGNU}/gsed "s/ //g"`
								DATETABLE=`${PATHGNU}/gdate -r ${PATHTABLE}/approximateBaselinesTable.txt +%F`
								if [ ${INTABLE} -eq 0 ] 
									then
										# not baseline plot table nor in approximateBaselinesTable.txt ; probably prblm at prepa msbas
										CONSISTENCY="${red}Data not in MassProcess nor in baseline table (from ${DATEBP}) nor approximateBaselinesTable.txt (from ${DATETABLE}).${normal}"
										CONSISTENCY2="${red}Probably crash at prepa msbas during reading ?${normal}"
									else 
										# not baseline plot table but in approximateBaselinesTable.txt 
										MINBP=`cat ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | ${PATHGNU}/grep ${LASTSIMG} | cut -d _ -f3 | ${PATHGNU}/gsed "s/-//g" |  sort -n | uniq | head -1`
										#search all Bt with that min Bp
										BTWITHMINBPPOS=`cat ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep  _${MINBP}_  | cut -d _ -f4 |  sort -n | uniq | head -1 `
										if [ "${BTWITHMINBPPOS}" == "" ] ; then BTWITHMINBPPOS=999999 ; fi
										BTWITHMINBPNEG=`cat ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep  _-${MINBP}_  | cut -d _ -f4 |  sort -n | uniq | head -1 ` 
										if [ "${BTWITHMINBPNEG}" == "" ] ; then BTWITHMINBPNEG=999999 ; fi
										if [ ${BTWITHMINBPPOS} -gt ${BTWITHMINBPNEG} ] ; then BTWITHMINBP=${BTWITHMINBPNEG} ; else BTWITHMINBP=${BTWITHMINBPPOS} ; fi
						
						
										MINBT=`cat ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | ${PATHGNU}/grep ${LASTSIMG} | cut -d _ -f4 | ${PATHGNU}/gsed "s/-//g" |  sort -n | uniq | head -1`
										#search all Bt with that min Bp
										#BPWITHMINBTPOS=`cat ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep -v _${MINBT}_  | ${PATHGNU}/grep  _${MINBT} | cut -d _ -f3 |  sort -n | uniq | head -1 `
										BPWITHMINBTPOS=`cat ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | ${PATHGNU}/grep ${LASTSIMG} | rev |  ${PATHGNU}/gsed -n -e "/^${MINBT}_/p" | cut -d _ -f2 | rev | ${PATHGNU}/gsed "s/-//g" |  sort -n | uniq | head -1`
										if [ "${BPWITHMINBTPOS}" == "" ] ; then BPWITHMINBTPOS=999999 ; fi
										#BPWITHMINBTNEG=`cat ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep -v _-${MINBT}_  | ${PATHGNU}/grep  _-${MINBT} | cut -d _ -f3 |  sort -n | uniq | head -1 ` 
										BPWITHMINBTNEG=`cat ${PATHTABLE}/approximateBaselinesTable.txt | ${PATHGNU}/gsed "s/\t/\n/g" | ${PATHGNU}/grep ${LASTSIMG} | rev |  ${PATHGNU}/gsed -n -e "/^${MINBT}-_/p" | cut -d _ -f2 | rev | ${PATHGNU}/gsed "s/-//g" |  sort -n | uniq | head -1` 
										if [ "${BPWITHMINBTNEG}" == "" ] ; then BPWITHMINBTNEG=999999 ; fi
										if [ ${BPWITHMINBTPOS} -gt ${BPWITHMINBTNEG} ] ; then BPWITHMINBT=${BPWITHMINBTNEG} ; else BPWITHMINBT=${BPWITHMINBTPOS} ; fi
						
										EXTRATABLE=`basename ${PATHBASELINE} | cut -d . -f 1`

										CONSISTENCY="${yellow}Data not in MassProcess nor in baseline table (from ${DATEBP}) but image is ${INTABLE} times in approximateBaselinesTable.txt (from ${DATETABLE}).${normal}" 
										CONSISTENCY2="${yellow}Min Bp (here: [-]${MINBP}m with [-]${BTWITHMINBP}days) or Bt (here: [-]${MINBT}days with [-]${BPWITHMINBT}m) larger than criteria ? ${normal}"
										CONSISTENCY3="${yellow} May want to add some pairs in ${EXTRATABLE}_AdditionalPairs.txt ?${normal}"
										
								fi
								;;
							"DD")   	
								#echo "Tools by D Derauw were probably used to compute the list of compatible pairs; Search pairs in ${PATHTABLE}/allPairsListing.txt " 
								# 
								INTABLE=`grep ${LASTSIMG} ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/gsed "s/\t/\n/g" | wc -l | ${PATHGNU}/gsed "s/ //g"`
								DATETABLE=`${PATHGNU}/gdate -r ${PATHTABLE}/allPairsListing.txt +%F`
								if [ ${INTABLE} -eq 0 ] 
									then
										# not baseline plot table nor in allPairsListing.txt ; probably prblm at prepa msbas
										CONSISTENCY="${red}Data not in MassProcess nor in baseline table (from ${DATEBP}) nor allPairsListing.txt (from ${DATETABLE}).${normal}"
										CONSISTENCY2="${red}Probably crash at prepa msbas during reading ?${normal}"
									else 
										# not baseline plot table but in allPairsListing.txt 
										# take min Bp from col 8
										MINBP=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/gawk  '{if (min == "") min=sqrt($8*$8) ; else if (sqrt($8*$8) < min) min=$8}END{print min}'`
										# test if negative
										if [ `echo "${MINBP}" | ${PATHGNU}/grep "-" | wc -l` -gt 0 ] 
											then 
												#SIGNMINBP="\${MINBP}" 
												#search Bt with that min Bp
												BTWITHMINBP=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep \\\"${MINBP} " | ${PATHGNU}/gawk '{ print $9 }' `
											else 
												#SIGNMINBP="${MINBP}" 
												#search Bt with that min Bp
												BTWITHMINBP=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep " ${MINBP} " | ${PATHGNU}/gawk '{ print $9 }' `
										fi
										#search Bt with that min Bp
										#BTWITHMINBP=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep " ${SIGNMINBP} " | ${PATHGNU}/gawk '{ print $9 }' `
						
										MINBT=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/gawk  '{if (min == "") min=sqrt($9*$9) ; else if (sqrt($9*$9) < min) min=$9}END{print min}'`
										#search all Bt with that min Bp
										# test if negative
										if [ `echo "${MINBT}" | ${PATHGNU}/grep "-" | wc -l` -gt 0 ] 
											then 
												#SIGNMINBT="\${MINBT}" 
												#search Bp with that min Bt
												#BPWITHMINBT=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep \\\"${MINBT} " | ${PATHGNU}/gawk '{ print $8 }' `	# need these 3 backslashes to get grep to ignore the negative signe before MINBT...
												BPWITHMINBT=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep \\\"${MINBT} " | ${PATHGNU}/gawk '{ print $8, $8 < 0 ? -$8 : $8 }' | sort -g -k2 | ${PATHGNU}/gawk '{ print $1 }'| head -n 1`
													# need these 3 backslashes to get grep to ignore the negative signe before MINBT...
													# gawk '{ print $8, $8 < 0 ? -$8 : $8 }' prints both the original value from column 8 and its absolute value as a second column. If the value is negative, it prints the positive version; otherwise, it prints the value unchanged.
													# sort -g -k2 sorts the lines based on the absolute values (second column).
													# gawk '{ print $1 }' prints the original values from column 8 after the sorting
													# head -1 takes the first, that is the smallest, value
												
											else 
												#SIGNMINBT="${MINBT}" 
												#search Bp with that min Bt
												#BPWITHMINBT=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep " ${MINBT} " | ${PATHGNU}/gawk '{ print $8 }' `
												BPWITHMINBT=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep " ${MINBT} " | ${PATHGNU}/gawk '{ print $8, $8 < 0 ? -$8 : $8 }' | sort -g -k2 | ${PATHGNU}/gawk '{ print $1 }'| head -n 1`
													# need these 3 backslashes to get grep to ignore the negative signe before MINBT...
													# gawk '{ print $8, $8 < 0 ? -$8 : $8 }' prints both the original value from column 8 and its absolute value as a second column. If the value is negative, it prints the positive version; otherwise, it prints the value unchanged.
													# sort -g -k2 sorts the lines based on the absolute values (second column).
													# gawk '{ print $1 }' prints the original values from column 8 after the sorting
													# head -1 takes the first, that is the smallest, value
										fi
										#search Bp with that min Bt
										#BPWITHMINBT=`cat ${PATHTABLE}/allPairsListing.txt | ${PATHGNU}/grep ${LASTSIMG} | ${PATHGNU}/grep " ${SIGNMINBT} " | ${PATHGNU}/gawk '{ print $8 }' `
						
										EXTRATABLE=`basename ${PATHBASELINE} | cut -d . -f 1`
		
										CONSISTENCY="${yellow}Data not in MassProcess nor in baseline table (from ${DATEBP}) but image is ${INTABLE} times in allPairsListing.txt (from ${DATETABLE}).${normal}" 
										CONSISTENCY2="${yellow}Min Bp (here: ${MINBP}m with ${BTWITHMINBP}days) or Bt (here: ${MINBT}days with ${BPWITHMINBT}m) larger than criteria ? ${normal}"
										CONSISTENCY3="${yellow} May want to add some pairs in ${EXTRATABLE}_AdditionalPairs.txt ?${normal}"
								fi
								;;		
				esac

			else
				# in baseline plot table; probably need to wait
				CONSISTENCY="${cyan}Data not mass processed yet though image is ${INBP} times in Baseline Plot table (from ${DATEBP}). May need to wait tomorrow ?${normal}"
				CONSISTENCY2=""
		fi		
		}
			
# Check S1
	function CheckS1()
		{
			# Provide date of expected ith last imag as LASTSIMG
			GetXthFormerImg ${DELTAS1} ${FIRSTIMG} $i 

			# check raw:
			LAST1=`find ${PATHRAW}/ -maxdepth 1 -type d -name "S1${SENSOR}*${LASTSIMG}T*" 2>/dev/null  | wc -l  | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST1} -eq 0 ] ; then LASTRAW="${reverse} missing       ${normal}" ; else LASTRAW="OK, ${LAST1} dirs "	; fi

			# check CSL:
			LAST2=`find ${PATHCSL}/*${LASTSIMG}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST2} -eq 0 ] 
				then 
					# check if not in __TMP_QUARANTINE (see _Check_ALL_S1_SizeAndCoord_InDir.sh)
					LAST21=`find ${PATHCSL}/__TMP_QUARANTINE/*${LASTSIMG}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
					if [ ${LAST21} -eq 0 ]
						then
							# check if not in /Quarantained 
							PATHCSLSHORT=`dirname ${PATHCSL}`
							LAST211=`find ${PATHCSLSHORT}/Quarantained/*${LASTSIMG}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
							if [ ${LAST211} -eq 0 ]
								then
									LASTCSL="${reverse} missing       ${normal}" 
								else
									LASTCSL="${yellow} Quarantained  ${normal}" 						
							fi
						else
							LASTCSL="${yellow} tmp qrtined   ${normal}" 
					fi
				else 
					LASTCSL="OK, ${LAST2} file "
					LAST21=2	# dummy value to avoid error in test further down
					LAST211=2 	# dummy value to avoid error in test further down
			fi

			# check RESAMPLED:
			LAST3=`find ${PATHRESAMP}/ -maxdepth 1 -type d -name "*S1${SENSOR}*${LASTSIMG}*" 2>/dev/null  | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST3} -eq 0 ] 
				then 
					LASTRESAMPL="${reverse} missing       ${normal}" 
				else 
					LAST31=`find ${PATHRESAMP}/*S1${SENSOR}*${LASTSIMG}*/ -type d -name "*" | wc -l | ${PATHGNU}/gsed "s/ //g"`
					if [ ${LAST31} -lt 9 ] ; then LASTRESAMPL="${reverse} miss sub dirs ${normal}" ; else	LASTRESAMPL="OK, ${LAST31} dirs " ; fi 
			fi

			# check MASS_PROCESS:
			LAST4=`find ${PATHMASSPROCESS}/ -maxdepth 1 -type d -name "*S1${SENSOR}*${LASTSIMG}*" 2>/dev/null  | wc -l | ${PATHGNU}/gsed "s/ //g"`
			# and Geocoded
			LAST5=`find ${PATHMASSPROCESS}/Geocoded/DefoInterpolx2Detrend -maxdepth 1 -type f -name "*${LASTSIMG}*deg" 2>/dev/null  | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST4} -eq 0 ]  
				then 
					LASTMP="${reverse} missing       ${normal}" 
					if [ ${LAST5} -eq 0 ] ; then LASTGEOC="${reverse} missing          ${normal}" ; else LASTGEOC="& ${LAST5} files" ; fi
				else 
					LASTMP="OK, ${LAST4} dirs " 
					if [ ${LAST5} -eq 0 ] ; then LASTGEOC="${red}but not in Geoc${normal}" ; else LASTGEOC="& ${LAST5} files" ; fi
			fi
	
			if [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] ; then 
				# LAST S1_CLN
				PATHMASSPROCESSLCN=`echo ${PATHMASSPROCESS} | ${PATHGNU}/gsed "s%\/S1\/%\/S1\_CLN\/CLEANED_ORB\/%"`
				LASTCLN=`find ${PATHMASSPROCESSLCN}/ -maxdepth 1 -type d -name "*S1${SENSOR}*${LASTSIMG}*" 2>/dev/null  | wc -l | ${PATHGNU}/gsed "s/ //g"`
			fi
			
			# check MSBAS:
			LAST6=`find ${PATHMSBAS}/${MSBASMODE} -maxdepth 1 -type f -name "*${LASTSIMG}*deg" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST6} -eq 0 ] ; then LASTMSBAS="${reverse} missing       ${normal}" ; else LASTMSBAS="OK, ${LAST6} links " ; fi
			
			# For Debug
			#echo "                  LAST1=${LAST1}; LAST2=${LAST2}; LAST3=${LAST3}; LAST4=${LAST4}; LAST5=${LAST5}; LAST6=${LAST6}"
			#echo "                  LAST21=${LAST21}; LAST211=${LAST211}; LAST31=${LAST31}"
		
			# check consistency:
			if [ ${LAST1} -eq 0 ] && [ ${LAST2} -eq 0 ] && [ ${LAST21} -eq 0 ] && [ ${LAST211} -eq 0 ] && [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] 
				then
					CONSISTENCY="No data acquired (check maybe with space agency; wait for tomorrow if img is Today)"
					CONSISTENCY2=""
				elif [ ${LAST211} -eq 1 ] ; then 
					CONSISTENCY="${red}Data read but manually stored in /Quarantained${normal}"
					CONSISTENCY2=""
				elif [ ${LAST21} -eq 1 ] ; then 
					CONSISTENCY="${red}Data read but with abnormal size and hence stored in __TMP_QUARANTINE; check raw zip files${normal}"
					CONSISTENCY2=""
				elif [ ${LAST2} -eq 0 ] && [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					CONSISTENCY="${red}Data not read ; check raw zip files${normal}"
					CONSISTENCY2=""
				elif [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					CONSISTENCY="${green}Data not resampled yet (may need to wait tomorrow ?)${normal}"
					CONSISTENCY2=""
				elif [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					# check if img is in baseline plot table or in approximateBaselinesTable.txt
					ImgInPlotTable
				elif [ ${LAST6} -eq 0 ] && [ ${LAST4} -ne 0 ]  && [ ${LAST5} -ne 0 ] ; then 
					CONSISTENCY="${blue}No MSBAS invertion yet (may need to wait tomorrow or check empty defo map in data base)${normal}"
					CONSISTENCY2=""
				elif [ ${LAST4} -ne ${LAST5} ] ; then 
					CONSISTENCY="${red}Not same number of dir and geocoded files. Please check Mass Processing${normal}"
					CONSISTENCY2=""

				elif [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -ne 0 ] && [ ${LASTCLN} -ne 0 ] ; then 
					CONSISTENCY="${magenta}No dir in MassProcess nor geocoded files though image is in MSBAS dir and S1_CLN; wait for orbit updated reprocessing.${normal}"
					CONSISTENCY2=""

				elif [ ${LAST5} -ne ${LAST6} ] ; then 
					CONSISTENCY="Not same number of geocoded files and files in msbas. May be not a problem if msbas is performed with a more restrictive criteria."
					CONSISTENCY2=""
				elif [ ${LAST4} -eq 0 ] && [ ${LAST5} -ne 0 ] ; then 
					CONSISTENCY="${magenta}No dir in MassProcess; check copy from processing dir or wait for orbit updated reprocessing.${normal}"
					CONSISTENCY2=""
				else 
					CONSISTENCY="Everything seems OK"
					CONSISTENCY2=""
			fi

			# Check if S1B after failure on December 23 2021
			if [ ${LASTIMGSEC} -gt 1640257200 ] && [ "${SENSOR}" == "B" ] # 1640257200 is 2021 12 23 in sec
				then 
					CONSISTENCY="${reverse}Sentinel 1B not operationnal since December 23 2021.${normal}"
			fi

			# Print line
			if [ "${CONSISTENCY2}" == "" ]
				then
					# print on one line
					printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-15s %-18s | %-15s | %-50s\n" "$i" "${LASTSIMG}" "${LASTRAW}" "${LASTCSL}" "${LASTRESAMPL}" "${LASTMP}" "${LASTGEOC}" "${LASTMSBAS}" "${CONSISTENCY}" 
				else
					# print second line for long CONSISTENCY message
					printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-15s %-18s | %-15s | %-50s\n " "$i" "${LASTSIMG}" "${LASTRAW}" "${LASTCSL}" "${LASTRESAMPL}" "${LASTMP}" "${LASTGEOC}" "${LASTMSBAS}" "${CONSISTENCY}" 
					printf "%-132s %-50s\n" " " "${CONSISTENCY2}" 
					if [ "${CONSISTENCY3}" != "" ]
						then
							printf "%-132s %-50s\n" " " "${CONSISTENCY3}" 
					fi
			fi
		}

function CheckCSK()
		{
			# Provide date of expected ith last imag as LASTSIMG
			GetXthFormerImgCSK ${DELTACSK} ${FIRSTIMG} ${EXPECTEDTIME}

			# check raw:
			LAST1=`find ${PATHRAW}/ -maxdepth 1 -type f -name "C*${LASTSIMG}*.zip" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST1} -eq 0 ] ; then LASTRAW="${reverse} missing       ${normal}" ; else LASTRAW="OK, ${LAST1} dirs "	; fi

			# check CSL:
			LAST2=`find ${PATHCSL}/*${LASTSIMG}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST2} -eq 0 ] ; then LASTCSL="${reverse} missing       ${normal}" ; else LASTCSL="OK, ${LAST2} file " ; fi

			# check RESAMPLED
			# search for Global Primary as the first date of the first subdir named yyyymmdd_yyyymmdd
			GLOBPRIM=`find ${PATHRESAMP}/ -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]_[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]' | head -n 1 | ${PATHGNU}/gawk -F/ '{print $NF}' | ${PATHGNU}/gawk -F_ '{print $1}'`
			if [ "${GLOBPRIM}" == "${LASTSIMG}" ] 
				then 
					LAST3=0
					LASTRESAMPL="${green}Global Primary ${normal}"
				else 
					LAST3=`find ${PATHRESAMP}/ -maxdepth 1 -type d -name "*_${LASTSIMG}*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
					if [ ${LAST3} -eq 0 ] 
						then 
							LASTRESAMPL="${reverse} missing       ${normal}" 
						else 
							LAST31=`find ${PATHRESAMP}/*_${LASTSIMG}/ -type d -name "*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
							if [ ${LAST31} -lt 9 ] ; then LASTRESAMPL="${reverse} miss sub dirs ${normal}" ; else	LASTRESAMPL="OK, ${LAST31} dirs " ; fi 
					fi
			fi

			# check MASS_PROCESS 
			LAST4=`find ${PATHMASSPROCESS}/ -maxdepth 1 -type d -name "*${LASTSIMG}*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`

			# and Geocoded
			LAST5=`find ${PATHMASSPROCESS}/Geocoded/DefoInterpolx2Detrend -maxdepth 1 -type f -name "*${LASTSIMG}*deg" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST4} -eq 0 ]  
				then 
					LASTMP="${reverse} missing       ${normal}" 
					if [ ${LAST5} -eq 0 ] ; then LASTGEOC="${reverse} missing          ${normal}" ; else LASTGEOC="& ${LAST5} files" ; fi
				else 
					LASTMP="OK, ${LAST5} dirs " 
					if [ ${LAST5} -eq 0 ] ; then LASTGEOC="${red}but not in Geoc${normal}" ; else LASTGEOC="& ${LAST5} files" ; fi
			fi
			
			# check MSBAS:
			LAST6=`find ${PATHMSBAS}/${MSBASMODE} -maxdepth 1 -type f -name "*${LASTSIMG}*deg" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST6} -eq 0 ] ; then LASTMSBAS="${reverse} missing       ${normal}" ; else LASTMSBAS="OK, ${LAST6} links " ; fi

			# check consistency:
			if [ ${LAST1} -eq 0 ] && [ ${LAST2} -eq 0 ] && [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] 
				then
					CONSISTENCY="No data acquired (check maybe with space agency)"
					CONSISTENCY2=""
				elif [ ${LAST2} -eq 0 ] && [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					CONSISTENCY="${red}Data not read ; check raw zip files${normal}"
					CONSISTENCY2=""
				elif [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					CONSISTENCY="${green}Data not resampled yet (may need to wait tomorrow ?)${normal}"
					CONSISTENCY2=""
				elif [ ${LAST3} -eq 0 ] && [ ${LAST4} -ne 0 ] && [ ${LAST5} -ne 0 ] && [ ${LAST6} -ne 0 ] ; then 
					if  [ "${GLOBPRIM}" == "${LASTSIMG}" ] 
						then 
							CONSISTENCY="Everything seems OK"
							CONSISTENCY2=""
						else 
							CONSISTENCY="${green}Everything seems OK, though image can't be resampled on Global Primary (CSK-CSG pair?) => used as Secondary only${normal}"
							CONSISTENCY2=""
					fi
				elif [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					# check if img is in baseline plot table or in approximateBaselinesTable.txt
					ImgInPlotTable
				elif [ ${LAST6} -eq 0 ] && [ ${LAST4} -ne 0 ]  && [ ${LAST5} -ne 0 ] ; then 
					CONSISTENCY="${blue}No MSBAS invertion yet (may need to wait tomorrow or check empty defo map in data base)${normal}"
					CONSISTENCY2=""
				elif [ ${LAST4} -ne ${LAST5} ] ; then 
					CONSISTENCY="${red}Not same number of dir and geocoded files. Please check Mass Processing${normal}"
					CONSISTENCY2=""
				elif [ ${LAST5} -ne ${LAST6} ] ; then 
					CONSISTENCY="Not same number of geocoded files and files in msbas. May be not a problem if msbas is performed with a more restrictive criteria."
					CONSISTENCY2=""
				elif [ ${LAST4} -eq 0 ] && [ ${LAST5} -ne 0 ] ; then 
					CONSISTENCY="${magenta}No dir in MassProcess; check copy from processing dir or wait for orbit updated reprocessing.${normal}"
					CONSISTENCY2=""
				else 
					CONSISTENCY="Everything seems OK"
					CONSISTENCY2=""
			fi
			# Print line
			if [ "${CONSISTENCY2}" == "" ]
				then
					# print on one line
					printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-15s %-18s | %-15s | %-50s\n" "$i" "${LASTSIMG}" "${LASTRAW}" "${LASTCSL}" "${LASTRESAMPL}" "${LASTMP}" "${LASTGEOC}" "${LASTMSBAS}" "${CONSISTENCY}" 
				else
					# print second line for long CONSISTENCY message
					printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-15s %-18s | %-15s | %-50s\n " "$i" "${LASTSIMG}" "${LASTRAW}" "${LASTCSL}" "${LASTRESAMPL}" "${LASTMP}" "${LASTGEOC}" "${LASTMSBAS}" "${CONSISTENCY}" 
					printf "%-132s %-50s\n" " " "${CONSISTENCY2}" 
					if [ "${CONSISTENCY3}" != "" ]
						then
							printf "%-132s %-50s\n" " " "${CONSISTENCY3}" 
					fi
			fi
		}
		
function CheckSAOCOM()
		{
			# Provide date of expected ith last imag as LASTSIMG
			GetXthFormerImgSAOCOM ${DELTASAOCOM} ${FIRSTIMG} ${EXPECTEDTIME}

			# check raw:
			LAST1=`find ${PATHRAW}/ -maxdepth 2 -mindepth 1 -type f -name "*.xemt" -exec grep -m 1 startTime {} \; | sed -n '/<startTime>'${EXPECTEDYYYY}'-'${EXPECTEDMM}'-'${EXPECTEDDD}'T'${EXPECTEDTIME}'/p' 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST1} -eq 0 ] ; then LASTRAW="${reverse} missing       ${normal}" ; else LASTRAW="OK, ${LAST1} dirs "	; fi

			# check CSL:
			LAST2=`find ${PATHCSL}/*${LASTSIMG}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST2} -eq 0 ] 
				then 
					# Check if kml for reading is included in kml from raw image
					KMLFORREAD="${PATH_1650}/SAR_CSL/SAOCOM/LagunaFea/LagunaFea.kml"	
					
					KMLFROMIMGPATH=$(find "${PATHRAW}" -mindepth 2 -maxdepth 2 -type f -name "*.xemt" -exec grep -q '<startTime>'"${EXPECTEDYYYY}"'-'"${EXPECTEDMM}"'-'"${EXPECTEDDD}"'T'"${EXPECTEDTIME}" {} \; -exec dirname {} \;)
					# that is e.g /Volumes/D3610/SAR_DATA/SAOCOM/LagunaFea-UNZIP/EOL1ASARSAO1B8849848
					
					KMLFROMIMGFILE=`find ${KMLFROMIMGPATH} -maxdepth 1 -mindepth 1 -type f -name "*.xemt" | sed "s/.xemt//"` 
					# that is e.g /Volumes/D3610/SAR_DATA/SAOCOM/LagunaFea-UNZIP/EOL1ASARSAO1B8849848/S1B_OPER_SAR_EOSSP__CORE_L1A_OLF_20240204T153150

					if [ -d "${KMLFROMIMGFILE}" ]
						then
    						# image is unzipped. Lets get its kml that must be in Images
    						KMLFROMIMG=`find ${KMLFROMIMGFILE}/Images/ -type f -name "*.kml" `
						else
							# image is not unzipped. Lets unzip only the kml in ${KMLFROMIMGPATH} 
							unzip -j "${KMLFROMIMGFILE}.zip" "*.kml" -d ${KMLFROMIMGPATH} >/dev/null 2>&1
							KMLFROMIMG=`find ${KMLFROMIMGPATH}/ -type f -name "*.kml" `
					fi
					
					TESTKML=`_Check_kml_in_kml.py ${KMLFORREAD} ${KMLFROMIMG} 2>/dev/null | grep "True" | wc -l`
					LASTCSL="${reverse} missing       ${normal}"
					rm -f ${KMLFROMIMG} 
				else 
					LASTCSL="OK, ${LAST2} file "		
			fi

			# check RESAMPLED
			# search for Global Primary as the first date of the first subdir named yyyymmdd_yyyymmdd
			GLOBPRIM=`find ${PATHRESAMP}/ -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]_[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]' | head -n 1 | ${PATHGNU}/gawk -F/ '{print $NF}' | ${PATHGNU}/gawk -F_ '{print $1}'`
			if [ "${GLOBPRIM}" == "${LASTSIMG}" ] 
				then 
					LAST3=0
					LASTRESAMPL="${green}Global Primary ${normal}"
				else 
					LAST3=`find ${PATHRESAMP}/ -maxdepth 1 -type d -name "*_${LASTSIMG}*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
					if [ ${LAST3} -eq 0 ] 
						then 
							LASTRESAMPL="${reverse} missing       ${normal}" 
						else 
							LAST31=`find ${PATHRESAMP}/*_${LASTSIMG}/ -type d -name "*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
							if [ ${LAST31} -lt 9 ] ; then LASTRESAMPL="${reverse} miss sub dirs ${normal}" ; else	LASTRESAMPL="OK, ${LAST31} dirs " ; fi 
					fi
			fi
			
			# check MASS_PROCESS:
			LAST4=`find ${PATHMASSPROCESS}/ -maxdepth 1 -type d -name "*${LASTSIMG}*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			
			# and Geocoded
			LAST5=`find ${PATHMASSPROCESS}/Geocoded/DefoInterpolx2Detrend -maxdepth 1 -type f -name "*${LASTSIMG}*deg" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST4} -eq 0 ]  
				then 
					LASTMP="${reverse} missing       ${normal}" 
					if [ ${LAST5} -eq 0 ] ; then LASTGEOC="${reverse} missing          ${normal}" ; else LASTGEOC="& ${LAST5} files" ; fi
				else 
					LASTMP="OK, ${LAST5} dirs " 
					if [ ${LAST5} -eq 0 ] ; then LASTGEOC="${red}but not in Geoc${normal}" ; else LASTGEOC="& ${LAST5} files" ; fi
			fi
			
			# check MSBAS:
			LAST6=`find ${PATHMSBAS}/${MSBASMODE} -maxdepth 1 -type f -name "*${LASTSIMG}*deg" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${LAST6} -eq 0 ] ; then LASTMSBAS="${reverse} missing       ${normal}" ; else LASTMSBAS="OK, ${LAST6} links " ; fi

			# check consistency:
			if [ ${LAST1} -eq 0 ] && [ ${LAST2} -eq 0 ] && [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] 
				then
					CONSISTENCY="No data acquired (check maybe with space agency)"
					CONSISTENCY2=""
				elif [ ${LAST2} -eq 0 ] && [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					if [ ${TESTKML} -eq 0 ] 
						then 
							CONSISTENCY="${red}Img outside kml${normal}"
						else
							CONSISTENCY="${red}Data not read ; check raw zip files${normal}"
					fi
					CONSISTENCY2=""
				elif [ ${LAST3} -eq 0 ] && [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					CONSISTENCY="${green}Data not resampled yet (may need to wait tomorrow ?)${normal}"
					CONSISTENCY2=""
				elif [ ${LAST3} -eq 0 ] && [ ${LAST4} -ne 0 ] && [ ${LAST5} -ne 0 ] && [ ${LAST6} -ne 0 ] ; then 
					if  [ "${GLOBPRIM}" == "${LASTSIMG}" ] 
						then 
							CONSISTENCY="Everything seems OK"
							CONSISTENCY2=""
						else 
							CONSISTENCY="${green}Everything seems OK, though image can't be resampled on Global Primary => used as Secondary only${normal}"
							CONSISTENCY2=""
					fi
				elif [ ${LAST4} -eq 0 ] && [ ${LAST5} -eq 0 ] && [ ${LAST6} -eq 0 ] ; then 
					# check if img is in baseline plot table or in approximateBaselinesTable.txt
					ImgInPlotTable
				elif [ ${LAST6} -eq 0 ] && [ ${LAST4} -ne 0 ]  && [ ${LAST5} -ne 0 ] ; then 
					CONSISTENCY="${blue}No MSBAS invertion yet (may need to wait tomorrow or check empty defo map in data base)${normal}"
					CONSISTENCY2=""
				elif [ ${LAST4} -ne ${LAST5} ] ; then 
					CONSISTENCY="${red}Not same number of dir and geocoded files. Please check Mass Processing${normal}"
					CONSISTENCY2=""
				elif [ ${LAST5} -ne ${LAST6} ] ; then 
					CONSISTENCY="Not same number of geocoded files and files in msbas. May be not a problem if msbas is performed with a more restrictive criteria."
					CONSISTENCY2=""
				elif [ ${LAST4} -eq 0 ] && [ ${LAST5} -ne 0 ] ; then 
					CONSISTENCY="${magenta}No dir in MassProcess; check copy from processing dir or wait for orbit updated reprocessing.${normal}"
					CONSISTENCY2=""
				else 
					CONSISTENCY="Everything seems OK"
					CONSISTENCY2=""
			fi
			# Print line
			if [ "${CONSISTENCY2}" == "" ]
				then
					# print on one line
					printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-15s %-18s | %-15s | %-50s\n" "$i" "${LASTSIMG}" "${LASTRAW}" "${LASTCSL}" "${LASTRESAMPL}" "${LASTMP}" "${LASTGEOC}" "${LASTMSBAS}" "${CONSISTENCY}" 
				else
					# print second line for long CONSISTENCY message
					printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-15s %-18s | %-15s | %-50s\n " "$i" "${LASTSIMG}" "${LASTRAW}" "${LASTCSL}" "${LASTRESAMPL}" "${LASTMP}" "${LASTGEOC}" "${LASTMSBAS}" "${CONSISTENCY}" 
					printf "%-132s %-50s\n" " " "${CONSISTENCY2}" 
					if [ "${CONSISTENCY3}" != "" ]
						then
							printf "%-132s %-50s\n" " " "${CONSISTENCY3}" 
					fi
			fi
		}
		
function PrintHeader()
	{
	HD1="From Now"
	HD2="Expected"
	HD3="Raw"
	HD4="CSL"
	HD5="RESAMPLED"
	HD6="MASS_PROCESS"
	HD7="& in Geocoded/"
	HD8="MSBAS"
	HD9="Remark"

	echo ""
	printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-15s %-18s | %-15s | %-50s\n"  "${underline}${bold} ${HD1}" "${HD2}" "${HD3}" "${HD4}" "${HD5}" "${HD6}" "${HD7}" "${HD8}" "${HD9}${normal}"
	}	
	
function PrintHeaderCSK()
	{
	HD1="From Now"
	HD2="Last raw"
	HD3="Raw"
	HD4="CSL"
	HD5="RESAMPLED"
	HD6="MASS_PROCESS"
	HD7="& in Geocoded/"
	HD8="MSBAS"
	HD9="Remark"

	echo ""
	printf "%-9s | %-10s | %-15s | %-15s | %-15s | %-15s %-18s | %-15s | %-50s\n"  "${underline}${bold} ${HD1}" "${HD2}" "${HD3}" "${HD4}" "${HD5}" "${HD6}" "${HD7}" "${HD8}" "${HD9}${normal}"
	}	
	
# Let's go...
clear 

echo
echo "############################"
echo "# VVP"
echo "# Sentinel-1 "
echo "############################"
PrintHeader
	PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP
	PATHMSBAS=$PATH_3602/MSBAS/_VVP_S1_Auto_70m_400days/

echo "${bold}DRC VVP Sentinel-1 Asc 174; satellite A${normal}"
	PATHCSL=$PATH_1660/SAR_CSL/S1/DRC_VVP_A_174/NoCrop
	PATHRESAMP=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310
	PATHMASSPROCESS=$MOUNTPT/dell3raid5/SAR_MASSPROCESS/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310_Zoom1_ML4
	PATHBASELINE=$PATH_1660/SAR_SM/MSBAS/VVP/set6/table_0_20_0_400_Till_20220501_0_70_0_400_After.txt
	MSBASMODE=DefoInterpolx2Detrend1
	FIRSTIMG=20141017  # YYYYMMDD
	SENSOR=A
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
# echo "${bold}DRC VVP Sentinel-1 Asc 174; satellite B${normal}"
# 	PATHCSL=$PATH_1660/SAR_CSL/S1/DRC_VVP_A_174/NoCrop
# 	PATHRESAMP=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310
# 	PATHMASSPROCESS=$MOUNTPT/dell3raid5/SAR_MASSPROCESS/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310_Zoom1_ML4
# 	PATHBASELINE=$PATH_1660/SAR_SM/MSBAS/VVP/set6/table_0_20_0_400.txt  
# 	MSBASMODE=DefoInterpolx2Detrend1
# 	FIRSTIMG=20180616  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done

PrintHeader
echo "${bold}DRC VVP Sentinel-1 Desc 21; satellite A${normal}"
	PATHCSL=$PATH_1660/SAR_CSL/S1/DRC_VVP_D_21/NoCrop
	PATHRESAMP=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_VVP_D_21/SMNoCrop_SM_20151014
	PATHMASSPROCESS=$MOUNTPT/dell3raid5/SAR_MASSPROCESS/S1/DRC_VVP_D_21/SMNoCrop_SM_20151014_Zoom1_ML4
	PATHBASELINE=$PATH_1660/SAR_SM/MSBAS/VVP/set7/table_0_20_0_400_Till_20220501_0_70_0_400_After.txt
	MSBASMODE=DefoInterpolx2Detrend2
	FIRSTIMG=20141007  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
# echo "${bold}DRC VVP Sentinel-1 Desc 21; satellite B${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/DRC_VVP_D_21/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/DRC_VVP_D_21/SMNoCrop_SM_20151014
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/DRC_VVP_D_21/SMNoCrop_SM_20151014_Zoom1_ML8
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/VVP/set7/table_0_20_0_400.txt  
# 	MSBASMODE=DefoInterpolx2Detrend2
# 	FIRSTIMG=20170307  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done

echo
echo "############################"
echo "# Domuyo"
echo "############################"
PrintHeader
	PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-DOMUYO-SLC.UNZIP
	MSBASMODE=DefoInterpolx2Detrend1_Full

echo "${bold}Domuyo Sentinel-1 Asc 18; satellite A${normal}"
	PATHCSL=$PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_DEMGeoid_A_18/NoCrop
	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/ARG_DOMU_LAGUNA_DEMGeoid_A_18/SMNoCrop_SM_20180512
	PATHMASSPROCESS=$PATH_3602/SAR_MASSPROCESS_2/S1/ARG_DOMU_LAGUNA_DEMGeoid_A_18/SMNoCrop_SM_20180512_Zoom1_ML4
	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1/table_0_20_0_450_Till_20220501_0_80_0_450_After.txt
	PATHMSBAS=$PATH_3602/MSBAS/_Domuyo_S1_Auto_80m_450days/
	FIRSTIMG=20141030  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
# echo "${bold}Domuyo Sentinel-1 Asc 18; satellite B${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_A_18/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_20180512
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_20180512_Zoom1_ML4
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set1/table_0_20_0_450.txt 
# 	MSBASMODE=DefoInterpolx2Detrend1_Full
# 	FIRSTIMG=20170505  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images 
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done

PrintHeader
echo "${bold}Domuyo Sentinel-1 Desc 83; satellite A${normal}"
	PATHCSL=$PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_DEMGeoid_D_83/NoCrop
	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/ARG_DOMU_LAGUNA_DEMGeoid_D_83/SMNoCrop_SM_20180222
	PATHMASSPROCESS=$PATH_3602/SAR_MASSPROCESS_2/S1/ARG_DOMU_LAGUNA_DEMGeoid_D_83/SMNoCrop_SM_20180222_Zoom1_ML4
	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2/table_0_20_0_450_Till_20220501_0_80_0_450_After.txt
	MSBASMODE=DefoInterpolx2Detrend2_Full
	FIRSTIMG=20141023  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
# echo "${bold}Domuyo Sentinel-1 Desc 83; satellite B${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/ARG_DOMU_LAGUNA_D_83/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_20180222
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_20180222_Zoom1_ML4
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/ARGENTINE/set2/table_0_20_0_450.txt 
# 	MSBASMODE=DefoInterpolx2Detrend2_Full
# 	FIRSTIMG=20161006  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images 
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done


echo
echo "############################"
echo "# PF"
echo "############################"
PrintHeader
	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/S1/S1-DATA-REUNION-SLC.UNZIP
	PATHMSBAS=$PATH_3610/MSBAS/_PF_S1_Auto_90m_70_50days/

# echo "${bold}Piton de la Fournaise Sentinel-1 Asc 144 IW; satellite A${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/PF_IW_A_144/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/PF_IW_A_144/SMNoCrop_SM_20180831
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/PF_IW_A_144/SMNoCrop_SM_20180831_Zoom1_ML2
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/PF/set3/table_0_70_0_70.txt 
# 	MSBASMODE=DefoInterpolx2Detrend3
# 	FIRSTIMG=20161004  # YYYYMMDD
# 	SENSOR=A
# 	# Check the last images 
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done
# echo "${bold}Piton de la Fournaise Sentinel-1 Asc 144 IW; satellite B${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/PF_IW_A_144/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/PF_IW_A_144/SMNoCrop_SM_20180831
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/PF_IW_A_144/SMNoCrop_SM_20180831_Zoom1_ML2
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/PF/set3/table_0_70_0_70.txt 
# 	MSBASMODE=DefoInterpolx2Detrend3
# 	FIRSTIMG=20161004  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images 
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done

PrintHeader
echo "${bold}Piton de la Fournaise Sentinel-1 Desc 151 IW; satellite A${normal}"
	PATHCSL=$PATH_1660/SAR_CSL/S1/PF_IW_D_151/NoCrop
	PATHRESAMP=$PATH_1660/SAR_SM/RESAMPLED/S1/PF_IW_D_151/SMNoCrop_SM_20200622
	PATHMASSPROCESS=$PATH_3610/SAR_MASSPROCESS/S1/PF_IW_D_151/SMNoCrop_SM_20200622_Zoom1_ML2
	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/PF/set4/table_0_70_0_70_Till_20220501_0_90_0_70_After.txt 
	MSBASMODE=DefoInterpolx2Detrend4
	FIRSTIMG=20161005  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
# echo "${bold}Piton de la Fournaise  Sentinel-1  Desc 151 SM; satellite B${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/PF_SM_D_151/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/PF_SM_D_151/SMCrop_SM_20181013_Reunion_-21.41--20.85_55.2-55.85
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/PF_SM_D_151/SMCrop_SM_20181013_Reunion_-21.41--20.85_55.2-55.85_Zoom1_ML8
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/PF/set4/table_0_70_0_70.txt 
# 	MSBASMODE=DefoInterpolx2Detrend4
# 	FIRSTIMG=20161011  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images 
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done


PrintHeader
	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/S1/S1-DATA-REUNION_SM-SLC.UNZIP
echo "${bold}Piton de la Fournaise Sentinel-1 Asc 144 SM; satellite A ${normal}"
	PATHCSL=$PATH_1660/SAR_CSL/S1/PF_SM_A_144/NoCrop
	PATHRESAMP=$PATH_1660/SAR_SM/RESAMPLED/S1/PF_SM_A_144/SMCrop_SM_20190808_Reunion_-21.41--20.85_55.2-55.85
	PATHMASSPROCESS=$PATH_3610/SAR_MASSPROCESS/S1/PF_SM_A_144/SMCrop_SM_20190808_Reunion_-21.41--20.85_55.2-55.85_Zoom1_ML8
	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/PF/set1/table_0_50_0_50_Till_20220501_0_90_0_50_After.txt
	MSBASMODE=DefoInterpolx2Detrend1
	FIRSTIMG=20220518  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
# echo "${bold}Piton de la Fournaise Sentinel-1 Asc 144 SM; satellite B ${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/PF_SM_A_144/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/PF_SM_A_144/SMCrop_SM_20190808_Reunion_-21.41--20.85_55.2-55.85
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/PF_SM_A_144/SMCrop_SM_20190808_Reunion_-21.41--20.85_55.2-55.85_Zoom1_ML8
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/PF/set1/table_0_50_0_50.txt 
# 	MSBASMODE=DefoInterpolx2Detrend1
# 	FIRSTIMG=20161010  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images 
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done

#PrintHeader
#	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/S1/S1-DATA-REUNION_SM-SLC.UNZIP
# echo "${bold}Piton de la Fournaise Sentinel-1 Desc 151 SM; satellite A ${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/PF_SM_D_151/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/PF_SM_D_151/SMCrop_SM_20181013_Reunion_-21.41--20.85_55.2-55.85
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/PF_SM_D_151/SMCrop_SM_20181013_Reunion_-21.41--20.85_55.2-55.85
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/PF/set2/table_0_50_0_50.txt 
# 	MSBASMODE=DefoInterpolx2Detrend2
# 	FIRSTIMG=20161017  # YYYYMMDD
# 	SENSOR=A
# 	# Check the last images 
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done
# echo "${bold}Piton de la Fournaise Sentinel-1 Desc 151 SM; satellite B ${normal}"
# 	PATHCSL=$PATH_1650/SAR_CSL/S1/PF_SM_D_151/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/PF_SM_D_151/SMCrop_SM_20181013_Reunion_-21.41--20.85_55.2-55.85
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/PF_SM_D_151/SMCrop_SM_20181013_Reunion_-21.41--20.85_55.2-55.85
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/PF/set2/table_0_50_0_50.txt 
# 	MSBASMODE=DefoInterpolx2Detrend2
# 	FIRSTIMG=20161011  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images 
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done


echo
echo "############################"
echo "# LUX"
echo "############################"
PrintHeader
	PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC.UNZIP
	PATHMSBAS=$PATH_3602/MSBAS/_LUX_S1_Auto_70m_400days/

echo "${bold}LUXEMBOURG Sentinel-1 Asc 88; satellite A${normal}"
	PATHCSL=$PATH_1660/SAR_CSL/S1/LUX_A_88/NoCrop
	PATHRESAMP=$PATH_3610/SAR_SM/RESAMPLED/S1/LUX_A_88/SMNoCrop_SM_20190406
	PATHMASSPROCESS=$PATH_3610/SAR_MASSPROCESS/S1/LUX_A_88/SMNoCrop_SM_20190406_Zoom1_ML2
	PATHBASELINE=$PATH_1660/SAR_SM/MSBAS/LUX/set2/table_0_20_0_400_Till_20220501_0_70_0_400_After.txt
	MSBASMODE=DefoInterpolx2Detrend1
	FIRSTIMG=20141104  # YYYYMMDD ancien 20160203
	SENSOR=A
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
# echo "${bold}LUXEMBOURG Sentinel-1 Asc 88; satellite B${normal}"
# 	PATHCSL=$PATH_3602/SAR_CSL_Other_Zones_2/S1/LUX_A_88/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/LUX_A_88/SMNoCrop_SM_20170627
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/LUX_A_88/SMNoCrop_SM_20170627_Zoom1_ML4
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/LUX/set2/table_0_20_0_400.txt  
# 	MSBASMODE=DefoInterpolx2Detrend1
# 	FIRSTIMG=20161006  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done

PrintHeader
echo "${bold}LUXEMBOURG Sentinel-1 Desc 139; satellite A${normal}"
	PATHCSL=$PATH_1660/SAR_CSL/S1/LUX_D_139/NoCrop
	PATHRESAMP=$PATH_3610/SAR_SM/RESAMPLED/S1/LUX_D_139/SMNoCrop_SM_20210920
	PATHMASSPROCESS=$PATH_3610/SAR_MASSPROCESS/S1/LUX_D_139/SMNoCrop_SM_20210920_Zoom1_ML2
	PATHBASELINE=$PATH_1660/SAR_SM/MSBAS/LUX/set6/table_0_20_0_400_Till_20220501_0_70_0_400_After.txt 
	MSBASMODE=DefoInterpolx2Detrend2
	FIRSTIMG=20141015  # YYYYMMDD ancien 20160326
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
# echo "${bold}LUXEMBOURG Sentinel-1 Desc 139; satellite B${normal}"
# 	PATHCSL=$PATH_3602/SAR_CSL_Other_Zones_2/S1/LUX_D_139/NoCrop
# 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/LUX_D_139/SMNoCrop_SM_20161109
# 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/LUX_D_139/SMNoCrop_SM_20161109_Zoom1_ML4
# 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/LUX/set6/table_0_20_0_400.txt  
# 	MSBASMODE=DefoInterpolx2Detrend2
# 	FIRSTIMG=20160928  # YYYYMMDD
# 	SENSOR=B
# 	# Check the last images
# 	for i in $(seq 1 ${OLD})			
# 		do 
# 			CheckS1
# 	done


echo
echo "############################"
echo "# Karthala"
echo "############################"
PrintHeader
	PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-KARTHALA_SM-SLC.UNZIP
	PATHMSBAS=$PATH_3602/MSBAS/_Karthala_S1_Auto_150m_150days/

echo "${bold}KARTHALA Sentinel-1 Asc 86; satellite A${normal}"
	PATHCSL=$PATH_1650/SAR_CSL/S1/KARTHALA_SM_A_86/NoCrop
	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/KARTHALA_SM_A_86/SMCrop_SM_20220713_ComoresIsland_-11.94--11.34_43.22-43.53
	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/KARTHALA_SM_A_86/SMCrop_SM_20220713_ComoresIsland_-11.94--11.34_43.22-43.53_Zoom1_ML5
	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/KARTHALA/set1/table_0_50_0_150_Till_20220501_0_150_0_150_After.txt
	MSBASMODE=DefoInterpolx2Detrend1
	FIRSTIMG=20170504  # YYYYMMDD
	SENSOR=A
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
	

	
echo
echo "############################"
echo "# Guadeloupe"
echo "############################"
PrintHeader
	PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-GUADELOUPE-SLC.UNZIP
	PATHMSBAS=$PATH_3602/MSBAS/_Guadeloupe_S1_Auto_90m_150days/

echo "${bold}GUADELOUPE Sentinel-1 Asc 164; satellite A${normal}"
	PATHCSL=$PATH_1650/SAR_CSL/S1/GUADELOUPE_A_164/NoCrop
	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/GUADELOUPE_A_164/SMNoCrop_SM_20190622
	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/GUADELOUPE_A_164/SMNoCrop_SM_20190622_Zoom1_ML2
	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set1/table_0_50_0_150_Till_20240201_0_90_0_150_After_WITHHEADER.txt
	MSBASMODE=DefoInterpolx2Detrend1
	FIRSTIMG=20141203  # YYYYMMDD
	SENSOR=A
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
	
	PrintHeader
echo "${bold}GUADELOUPE Sentinel-1 Desc 54; satellite A${normal}"
	PATHCSL=$PATH_1650/SAR_CSL/S1/GUADELOUPE_D_54/NoCrop
	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/S1/GUADELOUPE_D_54/SMNoCrop_SM_20200410
	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/S1/GUADELOUPE_D_54/SMNoCrop_SM_20200410_Zoom1_ML2
	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/GUADELOUPE/set2/table_0_50_0_150_Till_20240201_0_90_0_150_After_WITHHEADER.txt
	MSBASMODE=DefoInterpolx2Detrend2
	FIRSTIMG=20150206  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
	
	echo
	
	
echo
echo "############################"
echo "# Funu"
echo "############################"
PrintHeader
	PATHRAW=$PATH_3600/SAR_DATA/S1/S1-DATA-DRCONGO-SLC.UNZIP
	PATHMSBAS=${PATH_3602}/MSBAS/_Funu_S1_Auto_Max3Shortests

echo "${bold}Funu Sentinel-1 Asc 174; satellite A${normal}"
	PATHCSL=$PATH_1660/SAR_CSL/S1/DRC_Funu/NoCrop
	PATHRESAMP=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_Funu_A_174/SMNoCrop_SM_20160608
	PATHMASSPROCESS=${PATH_1660}/SAR_MASSPROCESS/S1/DRC_Funu_A_174/SMNoCrop_SM_20160608_Zoom1_ML2
	PATHBASELINE=${PATH_1660}/SAR_SM/MSBAS/Funu/set1/table_0_0_MaxShortest_3.txt
	MSBASMODE=DefoInterpolx2Detrend1
	FIRSTIMG=20141017  # YYYYMMDD
	SENSOR=A
	# Check the last images
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
	
	PrintHeader
echo "${bold}Funu Sentinel-1 Desc 21; satellite A${normal}"
	PATHCSL=$PATH_1660/SAR_CSL/S1/DRC_Funu/NoCrop
	PATHRESAMP=$PATH_3610/SAR_SM/RESAMPLED/S1/DRC_Funu_D_21/SMNoCrop_SM_20160517
	PATHMASSPROCESS=${PATH_1660}/SAR_MASSPROCESS/S1/DRC_Funu_D_21/SMNoCrop_SM_20160517_Zoom1_ML2
	PATHBASELINE=${PATH_1660}/SAR_SM/MSBAS/Funu/set2/table_0_0_MaxShortest_3.txt
	MSBASMODE=DefoInterpolx2Detrend2
	FIRSTIMG=20141007  # YYYYMMDD
	SENSOR=A
	# Check the last images 
	for i in $(seq 1 ${OLD})			
		do 
			CheckS1
	done
	
	echo

	
 echo ""
 echo "############################"
 echo "# VVP"
 echo "# CSK "
 echo "############################"
 PrintHeaderCSK
 	PATHRAW=$PATH_3601/SAR_DATA_Other_Zones/CSK/SuperSite/Auto_Curl
 	PATHMSBAS=$PATH_3602/MSBAS/_VVP_CSK_Auto_151m_200days/
 echo "${bold}DRC VVP CSK Asc ${normal}"
 	PATHCSL=$PATH_1650/SAR_CSL/CSK/Virunga_Asc/NoCrop
 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/CSK/Virunga_Asc/SMNoCrop_SM_20160627
 	PATHMASSPROCESS=$PATH_3602/SAR_MASSPROCESS_2/CSK/Virunga_Asc/SMNoCrop_SM_20160627_Zoom1_ML23
 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/VVP/set1/table_0_150_0_200.txt
 	MSBASMODE=DefoInterpolx2Detrend1
 	FIRSTIMG=20230105  	# YYYYMMDD
 	EXPECTEDTIME=04		# hh time of acquisition (written in file name); required to assess if asc or desc
 
 	j=0
 	# Check the last images
 	for i in $(seq 1 ${OLDCSK})			
 		do 
 			TST="OFF"
 			CheckCSK
 	done
 echo "${bold}DRC VVP CSK Desc ${normal}"
 	PATHCSL=$PATH_1650/SAR_CSL/CSK/Virunga_Desc/NoCrop
 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/CSK/Virunga_Desc/SMNoCrop_SM_20160105
 	PATHMASSPROCESS=$PATH_3602/SAR_MASSPROCESS_2/CSK/Virunga_Desc/SMNoCrop_SM_20160105_Zoom1_ML23
 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/VVP/set2/table_0_150_0_200.txt
 	MSBASMODE=DefoInterpolx2Detrend2
 	FIRSTIMG=20230128  	# YYYYMMDD
 	EXPECTEDTIME=15		# hh time of acquisition (written in file name); required to assess if asc or desc
 	j=0
 	# Check the last images
 	for i in $(seq 1 ${OLDCSK})			
 		do 
 			TST="OFF"
 			CheckCSK
 	done


	
echo "#####################################"
echo "# LagunaFea SAOCOM - Delaunay Ratio30"
echo "#####################################"
 PrintHeader
 	PATHRAW=$PATH_3610/SAR_DATA/SAOCOM/LagunaFea-UNZIP
 	MSBASMODE=DefoInterpolx2Detrend1
 
 echo "${bold}LagunaFea SAOCOM Asc 42; satellite A${normal}"
 	PATHCSL=$PATH_1650/SAR_CSL/SAOCOM/LagunaFea_042_A/NoCrop
 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/SAOCOM/LagunaFea_042_A/SMNoCrop_SM_20231010
 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/SAOCOM/LagunaFea_042_A/SMNoCrop_SM_20231010_Zoom1_ML8
 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/LagunaFea/set1/table_0_0_DelaunayRatio30.0_0.txt
 	PATHMSBAS=$PATH_3602/MSBAS/_LagunaFea_SAOCOM_Auto_DelaunayRatio30
 	FIRSTIMG=20230401  # YYYYMMDD
  	EXPECTEDTIME=11		# hh time of acquisition (written in file name); required to assess if asc or desc
 
 	j=0
 	# Check the last images 
 	for i in $(seq 1 ${OLDSAOCOM})			
 		do 
  			TST="OFF"
  			CheckSAOCOM
 	done
 
 PrintHeader
 echo "${bold}LagunaFea SAOCOM Desc 152; satellite A${normal}"
 	PATHCSL=$PATH_1650/SAR_CSL/SAOCOM/LagunaFea_152_D/NoCrop
 	PATHRESAMP=$PATH_1650/SAR_SM/RESAMPLED/SAOCOM/LagunaFea_152_D/SMNoCrop_SM_20231105
 	PATHMASSPROCESS=$PATH_3601/SAR_MASSPROCESS/SAOCOM/LagunaFea_152_D/SMNoCrop_SM_20231105_Zoom1_ML8
 	PATHBASELINE=$PATH_1650/SAR_SM/MSBAS/LagunaFea/set2/table_0_0_DelaunayRatio30.0_0.txt
 	MSBASMODE=DefoInterpolx2Detrend2
 	FIRSTIMG=20230716  # YYYYMMDD
  	EXPECTEDTIME=21		# hh time of acquisition (written in file name); required to assess if asc or desc
 
 	j=0
 	# Check the last images 
 	for i in $(seq 1 ${OLDSAOCOM})			
 		do 
  			TST="OFF"
  			CheckSAOCOM
 	done
