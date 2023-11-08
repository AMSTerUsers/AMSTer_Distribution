#!/bin/bash
######################################################################################
# This script lists the expected S1 images since provided date until today 
# and compare to raw and read images. It performs the check first for S1A then S1B images. 
# 	Missing RAW images are listed in _Missing_Raw_S1A/B.txt in pwd
# 	Missing CSL images (when RAW exists) are listed in _Missing_CSL_S1A/B.txt in pwd
#
# Dependencies:	- gnu sed		
#
# Parameters: 	- date of expected first S1A image
#				- date of expected first S1B image
#				- path to directory where raw data are stored (e.g. $PATH_3600/SAR_DATA/S1/S1-DATA-REGION-SLC.UNZIP )
#				- path to directory where read images are stored (e.g. $PATH_1650/SAR_CSL/S1/REGION/NoCrop)
# 
# V 1.0 (Aug 8, 2023) 
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

FIRSTS1A=$1		# e.g. 20140527
FIRSTS1B=$2		# e.g. 20180527
PATHRAW=$3		# e.g. $PATH_3600/SAR_DATA/S1/S1-DATA-REGION-SLC.UNZIP
PATHCSL=$4		# e.g. $PATH_1650/SAR_CSL/S1/Region/NoCrop
 

# Hard coded : Length of interval between S1 images (in days)
DELTAS1=12 		# Nr of days expected between 2 S1 images acquired in that mode (e.g. 12 daysfor S1)
DELTASEC=`echo "( ${DELTAS1} * 86400 ) " | bc`	# Interval in sec of S1 image acquisition 

# basics
TODAY=`${PATHGNU}/gdate '+%Y%m%d'`
TODAYSEC=`${PATHGNU}/gdate -d"${TODAY} 12:00:00" +%s`


# functions
############

# YYYYMMDD to sec
function ymd2sec()
	{
	unset YMD		#  Date of first image YYYYMMDD acquired in that mode 
	unset YMDSEC 			#  (X=1 means last image before Today; 2 = previous one etc)

	YMD=$1
	
	YMDSEC=`${PATHGNU}/gdate -d"${YMD} 12:00:00" +%s`
	echo ${YMDSEC}
	}
	
# sec to YYYYMMDD  
function sec2ymd()
	{
	unset YMD		#  Date of first image YYYYMMDD acquired in that mode 
	unset YMDSEC 			#  (X=1 means last image before Today; 2 = previous one etc)

	YMDSEC=$1
	
	YMD=`${PATHGNU}/gdate -d"@${YMDSEC}" +'%Y%m%d'` 	# @ indicates that we are transforming unix time seconds, i.e. from 1970...
	echo ${YMD}
	}

# Compute the nr of images between the first date and today for a given mode and the date of the last img (as ymd or seq)
	function GetNrImg()
		{
		unset FIRSTIMG		#  Date of first image YYYYMMDD acquired in that mode 
		unset NROFIMG		
		unset LASTIMGSEC	
		unset LASTSIMG		

		FIRSTIMG=$1

		FIRSTIMGSEC=`ymd2sec ${FIRSTIMG}`  		# Date if first img in sec
		NROFIMG=`echo "( ${TODAYSEC} - ${FIRSTIMGSEC} ) / ${DELTASEC}" | bc`  # Nr of images acquired in that mode since first image (bc answers only integer part which is what we want)
		NROFIMGMINUS1=`echo "( ${NROFIMG} - 1 )" | bc`  # Nr of images -1 for seq 

		LASTIMGSEC=`echo "(( ${NROFIMG}  * ${DELTASEC} ) + ${FIRSTIMGSEC} )  " | bc`

		LASTSIMG=`sec2ymd ${LASTIMGSEC}`		# Date of Xth image from now

#		echo "Date of ${FIRSTIMG} is: ${FIRSTIMGSEC} "
#		echo "Date of last image ${LASTSIMG} is: ${LASTIMGSEC} "	
		}

			
# Check S1
	function CheckS1()
		{
			# check raw:
			RAW=`find ${PATHRAW}/ -maxdepth 1 -type d -name "S1${SENSOR}*${INGYMD}T*" 2>/dev/null  | wc -l  | ${PATHGNU}/gsed "s/ //g"`
			if [ ${RAW} -eq 0 ] 
				then 
					# check if not in _FORMER
					RAW=`find ${PATHRAW}_FORMER/ -maxdepth 2 -type d -name "S1${SENSOR}*${INGYMD}T*" 2>/dev/null  | wc -l  | ${PATHGNU}/gsed "s/ //g"`
					if [ ${RAW} -eq 0 ] 
						then 
							RAWSTATUS="missing"
							echo "${INGYMD} is not in ${PATHRAW}/ nor in _FORMER/ " >> _Missing_Raw_S1${SENSOR}.txt
						else 
							RAWSTATUS="ok in FORMER"
					fi
				else 
					RAWSTATUS="ok"
			fi 

			# check CSL:
			CSL=`find ${PATHCSL}/*${INGYMD}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
			if [ ${CSL} -eq 0 ] 
				then 
					# check if not in __TMP_QUARANTINE (see _Check_ALL_S1_SizeAndCoord_InDir.sh)
					CSL=`find ${PATHCSL}/__TMP_QUARANTINE/*${INGYMD}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
					if [ ${CSL} -eq 0 ]
						then
							# check if not in /Quarantained 
							PATHCSLSHORT=`dirname ${PATHCSL}`
							CSL=`find ${PATHCSLSHORT}/Quarantained/*${INGYMD}*/Data/ -maxdepth 1 -type f -name "SLCData*" 2>/dev/null | wc -l | ${PATHGNU}/gsed "s/ //g"`
							if [ ${CSL} -eq 0 ]
								then
									CSLSTATUS="missing" 
									if [ "${RAWSTATUS}" != "ok" ] || [ "${RAWSTATUS}" != "ok in FORMER" ] ; then 
										# No need of storing info if RAW is missing as well 
										echo "${INGYMD} is not in ${PATHCSL}/ nor in Quarantained nor in __TMP_QUARANTINE" >> _Missing_CSL_S1${SENSOR}.txt
									fi
								else
									CSLSTATUS="ok, though in /Quarantained"					
							fi
						else
							CSLSTATUS="ok, though in /__TMP_QUARANTINE"
					fi
				else 
					CSLSTATUS="ok"
			fi
		}


# Let's go...
clear 

echo
echo "###############################################"
echo "# Check Sentinel-1A since ${FIRSTS1A} up to Today"
echo "###############################################"
GetNrImg ${FIRSTS1A}
FIRSTS1ASEC=`ymd2sec ${FIRSTS1A}` 
SENSOR=A

rm -f _Missing_Raw_S1${SENSOR}.txt
rm -f _Missing_CSL_S1${SENSOR}.txt

# Check the last images
for i in $(seq 0 ${NROFIMGMINUS1})			
	do 
		IMGINSEC=`echo "(( ${i}  * ${DELTASEC} ) + ${FIRSTS1ASEC} )  " | bc`
		INGYMD=`sec2ymd ${IMGINSEC}`
		CheckS1 
		echo "Expected image S1${SENSOR} ${INGYMD}: Raw is ${RAWSTATUS}"
		echo "                           : CSL is ${CSLSTATUS}"
done

if [ -f _Missing_Raw_S1${SENSOR}.txt ] && [ ! -s _Missing_Raw_S1${SENSOR}.txt ] ; then rm -f _Missing_Raw_S1${SENSOR}.txt  ; fi
if [ -f _Missing_CSL_S1${SENSOR}.txt ] && [ ! -s _Missing_CSL_S1${SENSOR}.txt ] ; then rm -f _Missing_CSL_S1${SENSOR}.txt  ; fi

echo
echo "###############################################"
echo "# Check Sentinel-1B since ${FIRSTS1B} up to Today"
echo "###############################################"
GetNrImg ${FIRSTS1B}
FIRSTS1BSEC=`ymd2sec ${FIRSTS1B}` 
SENSOR=B

rm -f _Missing_Raw_S1${SENSOR}.txt
rm -f _Missing_CSL_S1${SENSOR}.txt

# Check the last images
for i in $(seq 0 ${NROFIMGMINUS1})			
	do 
		IMGINSEC=`echo "(( ${i}  * ${DELTASEC} ) + ${FIRSTS1BSEC} )  " | bc`
		INGYMD=`sec2ymd ${IMGINSEC}`
		CheckS1 
		echo "Expected image S1${SENSOR} ${INGYMD}: Raw is ${RAWSTATUS}"
		echo "                           : CSL is ${CSLSTATUS}"
done

if [ -f _Missing_Raw_S1${SENSOR}.txt ] && [ ! -s _Missing_Raw_S1${SENSOR}.txt ] ; then rm -f _Missing_Raw_S1${SENSOR}.txt  ; fi
if [ -f _Missing_CSL_S1${SENSOR}.txt ] && [ ! -s _Missing_CSL_S1${SENSOR}.txt ] ; then rm -f _Missing_CSL_S1${SENSOR}.txt  ; fi
