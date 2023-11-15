#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at reading all images from a given dir and store them in csl 
#      format where they will be used by the cis automated scripts. 
# The script will sort S1 and SAOCOM images in Asc and Desc specific dir. 
#
# It uses the bulk reading for satellites S1, SAOCOM, TDX and ICEYE
# It compares manually the images to read and those already read, then read only the new ones
#   for the other satellites, that is ERS, ENVISAT, RS1, RADARSAT, CSK, TSX, PAZ and ALOS2 
# Bulk reading has the advantage to be fast but it will stop at bad image while manual reading would carry on. 
#
# S1 and SAOCOM images of more than 6 months are moved to ${RAW}_FORMER/yyyy dirs
#
# Parameters : - path to dir with the raw archives to read.   
#              - path to dir where images in csl format will be stored (usuallu must end with /NoCrop)
#              - satellite (to know which dir naming format is used)
#			   - kml file and path of footprint of zone of interest (optional but useful eg for S1 and manatory for SAOCOM)
#			   - for S1, SAOCOM or ICEYE : force reading data in yyyy directories if this param is "ForceAllYears" 
#			   - for S1, if "-n": skip updating the orbits
#			   - for S1: if orbits are updated, one must provide a path to where the RESAMPLED data are stored 
#				  as well as the SAR_MASSPORCESS data are stored; these results will be removed and 
#				  updated at the next processings
#			   - for SAOCOM: if images are updated, one must provide a path to where the RESAMPLED data are stored 
#				  as well as the SAR_MASSPORCESS data are stored; these results will be removed and 
#				  updated at the next processings
#			   - for S1 or SAOCOM : preferred polarisation (VV, HH, VH, VV or ALLPOL) in order to read only that one to spare room on disk. 
#				 For S1, if a VV (or HH) pol is requested but does not exist, it will try read HH (or VV) to avoid gaps in time series. Quality may however be decreased.
#				 To read all the pol, use ALLPOL. 
#				 THIS IS HOWEVER NOT RECOMMANDED FOR DATA USED FOR MASS PROCESSING FOR TIME SERIES ! 		 
#				
#   NOTE: only the 3 first param must be in the right order. No matter the order of the other parameters. 
#
#
# Dependencies:	- AMSTer Engine and AMSTer Engine Tools, at least V20231108. 
#				- gnu sed and awk for more compatibility
#   			- functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#				- FUNCTIONS_FOR_MT.sh
#				- for S1 images :  	Check_All_S1_ImgReadSize.sh
#									List_All_S1_ImgSize.sh
#									List_S1_Frames_Swaths_Bursts.sh
#
# Hard coded:	- Path to .bashrc (sourced for safe use in cronjob)
#				    Path to sentinel orbits must be in that bashrc with a line such as : 
#					export S1_PRECISES_ORBITS_DIR=/...your path to .../S1_ORB/AUX_POEORB
#				  Also, it is recommended to get a cronjob to download them every day.
#
#
# New in Distro V 1.0:	- Based on developpement version 3.2 and Beta V2.4.5
#				V1.1.0: - change TDX handling...
#				V1.1.1: - TDX handling cope with several orb in same batch of read
#						- TSXfomrTDX is obsolate. Take images from TDXimages_TX for getting only the TSX masters 
#				V1.2.0: - check that no Mass processing is running before moving products that used updated Fast24 images to S1_CLN dir 
#						  or before moving products that used updated orbits images to S1_CLN dir
#				V1.3.0: - clean log files of more than 30 days
#				V1.4.0: - exit renalming of TDX when old format is encountered and let user to cope with it waiting for new version of reader
#				V1.4.1: - Clean old log files ORB_CleanRESAMPLED_*
#				V1.4.2: - discard $PATHFIND which was useless
#				V1.5.0: - When using S1, check empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt that is created 
#						  when processing SinglePair(NoUnwrap).sh or SuperMasterCoreg.sh or SuperMaster_MassProc.sh is running using S1 data of the same mode. 
#						  If such a file exists and is not older than 1440 min, it will skip the cleaning of products using updated S1 orbits and/or fast24 data, if any, 
#						  and store the date of updated orbits (or fast24 imgs) in a file so that it can clean them at next run.  
#						WARNING: empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt are cleaned at normal termination of the processes or if these processes 
#								 were terminated using CTRL-C. It is NOT deleted if processes are terminated using kill. If a file is older than one day, it must be a ghost files and wil be ignored. 
#				V1.5.1: - Skip S1 burst listing if SM mode
#				V1.5.2: - Compliant with SAOCOM images, though only in bulk reading and without polarisation selection
#				V1.5.3: - a space was missing in test for WS or SM in line 428 leading to always considering WS and hence attempting stitching bust even for S1 SM 
#						  and test was inverted
#						- update test for FAST24 to new messages logged in S1DataReaderLog.txt
#						- S1OrbitUpdater needs -u option because new S1DataReader doesn't update the orbits. Other option would be to run first updateS1PrecisesOrbits which updates the orb database 
#				V1.6.0: - Read S1 HH if INITPOL=VV not found
#				V2.0.0:	- Update S1 orb before reading and no more use of S1OrbitUpdater because now S1DataReader is doing the job. 
#						- clean empty log files with updated FAST24 and Orbits if no images were updated
#				V2.0.1:	- if, because of S1 orb update, a pair MAS_SLV was already updated for the MAS and is now updated for the SLV, the MAS_SLV dir exist already. Rename it first as MAS_SLV_1st_update
#				V2.0.2:	- improve backup of existing updated pair dir but also backup now existing updated file images 
#				V2.1.0:	- Add ALOS2
#						- ignore zip files as well while listing images
#				V2.2.0:	- change S1 orbit update function (from at least MasterEngine20210505) to cope with new ESA orbits. Note that these orbits are now taken from ASF. 
#							See procedure here: https://wiki.earthdata.nasa.gov/display/EL/How+To+Access+Data+With+cURL+And+Wget
#						  Ensure that you have now S1_ORBITS_DIR as state variable for path to dir where orbits are stored (./AUX_POEORB and ./AUX_RESORB) instead of S1_PRECISES_ORBITS_DIR  
#				V2.2.1:	- Use S1DateReader with new option -p to prevent reading S1 images without restituted or precise orbits. This is recommended since March 2021 when S1 images started to be distributed with orginal orbits of poor quality.  
#				V2.2.2:	- bug in S1 orbit dirname
#				V2.2.3:	- clean List_IMG_pol_HH_*.txt files older than threshold
#				V2.2.4:	- case insensitive searching while looking for updated S1 orbits
#				V2.2.5:	- allows skipping updating S1 orbits using parameter -n 
#						- check that basename of RAW dir is not in the form of _YYYY, which would mean that it only reads images from _FORMER dir and hence must not be moved again to _FORMER
#				V2.3.0:	- from MasterEngine V20211125, option -p is not necessary anymore
#				V2.4.0:	- Updated orbits : now  it performs the update of the local S1 orbit dir only since the last available precise orbit date.
#						  If you need to perform the update of the whole data base change line 342 (call of updateS1Orbits fct). Note that if ForceAllYears is requested, it will also update the whole local S1 orbit data base.
#						- New version (April 2022) of MasTer Engine works again with ESA S1 orbits. To use ASF orbits, add -ASF parameter at S1DataReader call in line 336  
#						- do not keep log of images with other polarisation (${CSL}/List_IMG_pol_HH_${RUNDATE}.txt) if empty
#				V2.4.1:	- Store version of MasTer Engine used to read the images using  fct GetMasTerEngineVersion. Param LASTVERSIONMT is the last created dir of MasTer Engine source 
#				V2.4.2:	- mute error while using find function (eg after updating an orbit during a first run of the script i.e. when no former RESAMPLED/ nor SAR_MASSPROCESS/ dir exist for that target) by using 2>/dev/null.  
#				V2.5.0:	- Read ICEYE images
#				V2.6.0:	- Debug usage of ForceAllYears for non ICEYE data
#				V2.7.0:	- exit if no geoid available (i.e. if no file in EARTH_GRAVITATIONAL_MODELS_DIR)
# New in Distro V2.8.0: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V3.0.0: - ensure that it can locate the RESAMPLED and SAR_MASSPROCESS dirs (when using S1 for cleaning when orbits are updated) 
#						- set preferred pol as parameter (for S1 or SAOCOM)
#						THIS WAS PERFORMED BY ADDING THESE AS PARAM INSTEAD OF HARD CODED 
# New in Distro V3.1.0: - Add/Check PAZ 
#						- Add RS1 (or RADARSAT1)
#						- Add/Check KOMPSAT (or K5)
#						- Add/Check ALOS
#						- get all grep as ${PATHGNU}/grep
#						- improve listing of image already read for all satellites that are 
#						  not read using bulk reader, that is all but S1, SAOCOM, TDX and ICEYE.
#						  Those read with the bulk reader have that managed by the bulk reader.  
# New in Distro V3.1.1: - More fancy TSX format allowed
# New in Distro V3.2.0: - For S1 IW, skip cleaning results from RESAMPLED and SAR_MASSPROCESS if no path is provided these results directories
# New in Distro V3.3.0: - parallelised some parts 
# New in Distro V3.3.1: - fix 2> /dev/null as 2>/dev/null
# New in Distro V3.3.2: - debug logging version of MasTer Engine when reading TDX images
# New in Distro V3.3.3: - wrong test if RAW dir is _YYYY
#						- avoid error message when cp {CSL}/S1DataReaderLog_Former.txt
#						- replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.1 20230912:	- Cope with possible multiple CSK acquisitions on the same day
#								- check that possible former S1, TDX, SAOCOM or ICEYE  links at reading are from the same OS
# New in Distro V 4.2 20230928:	- Add case where no link exists in new CSL folder (was otherwise failings...) (by A Dille).
# New in Distro V 4.3 20231018:	- Debug some cases of re-reading CSK images when more than one image exist on the same day 
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#								- avoid error message at cat empty MASSPROCESS dir
# New in Distro V 5.1 20231102:	- Adapt to new SAOCOM reader; needs kml for Region of Interest (mandatory because frames are not reliable)
#								- debug check previous readings for S1, SAOCOM, TDX and ICEYE 
# New in Distro V 5.2 20231109:	- Proper handling of SAOCOM images
# New in Distro V 5.3 20231114:	- remove files and dirs > 3 months in S1_CLN in RESAMPLED and MASS_PROCESS. Prepared for SAOCOM as well
#							      Beware, this cleans the _CLN products for all targets of your satellite on the same disk. 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Nov 14, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) "
echo " "

RAW=$1					# path to dir with the raw archives to read (unzipped for S1 !)
CSL=$2					# path to dir where images in csl format will be stored (usuallu must end with /NoCrop)
SAT=$3					# satellite

# vvv ----- Hard coded lines to check --- vvv
source /$HOME/.bashrc
# ^^^ ----- Hard coded lines to check --- ^^^

if [ $# -lt 3 ] ; then echo "Usage $0 PATH_TO_RAW_IMG PATH_TO_CSL_STORAGE SATELLITE [KML] [ForceAllYears] [-n] [Path_To_S1_RESAMPLED] [Path_To_S1_SAR_MASSPROCESS] [PREFERRED_POL]"; exit; fi

if [ $# -gt 3 ]
	then
		# start looping in parameters starting from 4th one
		shift 3
		while [[ $# -gt 0 ]]
		do
			case "$1" in
		    	# Process the parameter
		     	*".kml")
		     		# for S1 or recent other Datareader (eg SAOCOM)
		     		if [[ ! -f "$1" ]] ; then echo  ; echo "Your kml does not exist. Please check" ; exit ; fi
		         	KMLS1="$1"
		         	shift 1 ;;
		        "ForceAllYears")
		        	# for S1, SAOCOM or ICEYE : force reading data in yyyy directories if is "ForceAllYears"
		        	FAY=$1
		        	shift 1 ;;
		        "-n")
		        	# for S1 : -n to skip S1 orbit update
		        	NOORB=$1
		        	shift 1 ;;
		        *"RESAMPLED"*)
		     		if [[ ! -d "$1" ]] ; then echo  ; echo "Your RESAMPLED dir does not exist. Please check" ; exit ; fi
		        	RESAMPLED=$1
		        	shift 1 ;;
		        *"SAR_MASSPROCESS"*)
		     		if [[ ! -d "$1" ]] ; then echo  ; echo "Your SAR_MASSPROCESS dir does not exist. Please check" ; exit ; fi
		        	SAR_MASSPROCESS=$1
		        	shift 1 ;;
		        VV|HH|VH|HV|ALLPOL)
		        	if [[ "$1" == "ALLPOL" ]]
		        		then
		        			# keep empty var in order not to limit reader at a given pol
		        			INITPOL=""
		        		else
		        			INITPOL=$1
		        	fi

		        	shift 1 ;;
		        *)
		         # If the parameter is not recognized, print an error message and exit
		          echo "Error: unrecognized parameter:  $1  ; Please check " >&2
		         exit 1
		         ;;
		    esac
		done
fi

FCTFILE=${PATH_SCRIPTS}/SCRIPTS_MT/FUNCTIONS_FOR_MT.sh

if [[ "${SAT}" == "S1" ]] && [[ "${INITPOL}" = "" ]]
	then
		echo "Please provide a S1 polarisation to read : VV, HH, VH, HV or ALLPOL"
		exit
fi
if [[ "${SAT}" == "SAOCOM" ]] && [[ "${INITPOL}" = "" ]]
	then
		echo "Please provide a SAOCOM polarisation to read : VV, HH, VH, HV or ALLPOL"
		exit
fi


# do not run if no EARTH_GRAVITATIONAL_MODELS_DIR available
if [ `ls "${EARTH_GRAVITATIONAL_MODELS_DIR}" 2>/dev/null | wc -w ` -eq 0 ] ;  then echo "No EARTH_GRAVITATIONAL_MODELS_DIR ; can't run." ; exit ; fi

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

source ${FCTFILE}

# test nr of CPUs
	case ${OS} in
		"Linux")
			NCPU=`nproc` 	;;
		"Darwin")
			NCPU=`sysctl -n hw.ncpu`

			# must define a function because old bash on Mac does not know wait -n option
			waitn ()
			{ StartJobs="$(jobs -p)"
			  CurJobs="$(jobs -p)"
			  while diff -q  <(echo -e "$StartJobs") <(echo -e "$CurJobs") >/dev/null
			  do
				sleep 1
				CurJobs="$(jobs -p)"
			  done
			}

			;;
	esac

	CPU=$((NCPU-1))
	echo "Run max ${CPU} processes at a time "

CSLEND=`echo -n ${CSL} | tail -c 7`
if [ "${CSLEND}" != "/NoCrop" ] && [ ${SAT} != "CSK" ]; then echo "Check your CSL dir. It must end with NoCrop instead of ${CSLEND}" ; exit 0 ; fi

# Must be defined in .bashrc
ENVORB=${ENVISAT_PRECISES_ORBITS_DIR}
#SENTIORB=${S1_PRECISES_ORBITS_DIR}
SENTIORB=${S1_ORBITS_DIR}

function SpeakOut()
	{
	unset MESSAGE
	local MESSAGE
	MESSAGE=$1

	case ${OS} in
		"Linux")
			espeak "${MESSAGE}" ;;
		"Darwin")
			say "${MESSAGE}" 	;;
		*)
			echo "${MESSAGE}" 	;;
	esac
	}




RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
RNDM1=`echo $(( $RANDOM % 10000 ))`
LOGFILE=${CSL}/LogFile_ReadAll_${RUNDATE}.txt

if [ ${SAT} == "ENVISAT" ] && [ ! -d ${ENVORB} ]
		then
			echo "No precise orbit dir for ENVISAT. Continue anyway though better check !"
			SpeakOut "No precise orbit dir for ENVISAT. Continue anyway though better check !"
fi

if [ ${SAT} == "S1" ] && [ "${KMLS1}" == "" ]
		then
			echo "Probably no kml (with path!) contouring the area of interest for S1 data. You do not want to process the full images, don't you ?!"
			SpeakOut "Please provide a kml contouring the area of interest for S1 data. Do not forget the path..."
			exit
fi

if [ ${SAT} == "S1" ] && [ ! -d ${SENTIORB} ]
		then
			echo "No precise orbit directory for sentinel 1 data. Check .bashrc. Exit"
			SpeakOut "No precise orbit directory for sentinel 1 data. Check bash rc."
			exit
fi

if [ ${SAT} == "SAOCOM" ] && [ "${KMLS1}" == "" ]
		then
			echo "No kml; I can't check the area. Exit"
			SpeakOut "No kml; I can't check the area. Exit"
			exit
fi

if [ ${SAT} == "RS1" ] || [ ${SAT} == "RADARSAT1" ]
		then
			EchoTee "Remember that orbits from RADARSAT-1 can't be processed so far with AMSTer Engine. "
			EchoTee "  Hence you can read these RS1 data, compute the amplitude images in slant range or process 3 pass interferometry,"
			EchoTee "  but you will not be able to perform geocoding. "

fi

echo ""
# Check required dir:
#####################

# Path where to store data in csl format
if [ -d "${CSL}" ]
then
   echo "" > ${LOGFILE}
   EchoTee " OK: a directory exist where I can store the data in csl format." 
   EchoTee "     They will be stored in ${CSL}"
   if [ ${SAT} == "S1" ]  
   	  then 
   	  	EchoTee "     as link for each images. Data are stored in _Asc_TRK and Desc_TRK corresponding dir." 
   fi
   if [ ${SAT} == "SAOCOM" ] 
   	  then 
   	  	EchoTee "     as link for each images. Data are stored in _Asc_TRK and Desc_TRK corresponding dir." 
   fi
   if [ ${SAT} == "TDX" ]
   	  then 
   	  	EchoTee "     as link for each images. Data are stored in _TX (for transmit) and _RX (for receive) corresponding dir."
   fi
   EchoTee ""
else
   echo " "
   echo " NO expected ${CSL} directory."
   echo " I will create a new one. I guess it is the first run for that mode."
   echo ""
   mkdir -p ${CSL}
   echo "" > ${LOGFILE}
   EchoTee " NO expected ${CSL} directory. I created a new one. "

fi

EchoTee "  // Command line used and parameters:"
EchoTee "  // $(dirname $0)/${PRG} $1 $2 $3 $4 $5"
EchoTee "  // ${VER}"
EchoTee ""

# Path to original raw data
if [ -d "${RAW}/" ]
then
   EchoTee " OK: a directory exist where I guess raw data are stored."
   EchoTee "      I guess images are in ${RAW}."
   EchoTee ""
else
   EchoTee " "
   EchoTee " NO directory ${RAW}/ where I can find raw data. Can't run..."
   exit 1
fi

function GetDate()
	{
	unset DIRNAME
	local DIRNAME=$1
	echo "${DIRNAME}" | cut -d _ -f6
	}

function GetDateOnly()
	{
	unset DIRNAME
	local DIRNAME=$1
	echo "${DIRNAME}" | cut -d _ -f1
	}


function GetDateEnvisat()
	{
	unset DIRNAME
	local DIRNAME=$1
	cd ${DIRNAME}
	ls *.N1 | cut -d _ -f3 | cut -c 7-14
	}

function GetDateERS()
	{
	unset DIRNAME
	local DIRNAME=$1
	#cd ${DIRNAME}/SCENE1
	${PATHGNU}/grep -aEo "[0-9]{17}" ${RAW}/${DIRNAME}/SCENE1/LEA_01.001 | head -1 | cut -c 1-8
	}

function GetDateRS1()
	{
	unset DIRNAME
	local DIRNAME=$1
	cd ${DIRNAME}/
	${PATHGNU}/grep -aEo "[0-9]{17}" LEA_01.001 | head -1 | cut -c 1-8
	}

function GetDateALOS2()
	{
	unset DIRNAME
	local DIRNAME=$1
	# raw ALOS2 dirs are named yymmdd
	echo -n 20 ; echo "${DIRNAME}" | tail -c 7
	}

function GetDateALOS()
	{
	unset DIRNAME
	local DIRNAME=$1
	# raw ALOS dirs are named without date; it must be taken from workreport
	grep Img_SceneCenterDateTime ${DIRNAME}/workreport | head -1 | cut -d \" -f 2 | cut -d " " -f1
	}

function GetDateYyyyMmDdT()
	{
	unset DIRNAME
	local DIRNAME=$1
	echo "${DIRNAME}" | ${PATHGNU}/grep -Eo "[0-9]{8}T"  | cut -d T -f1 | head -1
	}

function GetSARL1BDate()
	{
	unset DIRNAME
	local DIRNAME=$1
	# suppose the dir contains somewhere in a lower level a dir named with something like TSX1_SAR__SSC______SL_S_SRA_20221225T002240_20221225T002242
	DIRWITHDATE=`find ${RAW}/${DIRNAME} -type d -name "T*X*_SAR__SSC*_SRA_*T*_*T*"  | xargs -I {} basename {} `
	echo "${DIRWITHDATE}" | ${PATHGNU}/grep -Eo "[0-9]{8}T"  | cut -d T -f1 | head -1
	}

function GetDateK5()
	{
	unset DIRNAME
	local DIRNAME=$1
	echo "${DIRNAME}" | cut -d _ -f2 | cut -c 1-8

	}


function ChangeInPlace()
	{
	unset ORIGINAL
	unset NEW
	unset FILE
	local ORIGINAL=$1
	local NEW=$2
	local FILE=$3
	if [ $# -lt 4 ]
		then
   			EchoTee "=> Change ${ORIGINAL}"
			EchoTee "   with ${NEW}"
			EchoTee "   in  ${FILE} "
			EchoTee ""
			${PATHGNU}/gsed -i "s%${ORIGINAL}%${NEW}%" ${FILE}
   		else
   			local OCCURENCE=$4	# If a 4th argument is provided it will change the ORIGINAL that appears on the OCCURENCEth position in the FILE
   			EchoTee "=> Change ${ORIGINAL}"
			EchoTee "   with ${NEW}"
			EchoTee "   in  ${FILE} "
			EchoTee ""
			${PATHGNU}/gsed -i "s%${ORIGINAL}%${NEW}%${OCCURENCE}" ${FILE}
    fi
	}

function TestLink()
	{
	unset LINK
	local LINK=$1
	local TARGET=$(readlink -f "${LINK}")

	EchoTee ""
	if [ -e "${TARGET}" ]
		then
   			EchoTee " No problems with links in current SAR_CSL dir."
   			EchoTee  "  ${LINK} -> ${TARGET}"		# this may trigger weird message if no link exist such as  -> (stdin)
   			EchoTee "I can securely carry on... "
   		else 
 			EchoTee "Links in SAR_CSL directory do not seem valid. At least the first link tries to point toward a ghost file: " 
   			EchoTee  "  ${LINK} -> ${TARGET}"
   			EchoTee "Either you are running this script from a computer with another type of OS (Linux vs mac), or another problem occurred. "
   			EchoTee "In any case, I must stop here to let you sort it out. " 
   			EchoTee "If you really want to read new images from a computer using a different OS, then you must first update all the existing links."
   			EchoTee " You can do that e.g. with:    ReCreateLink_S1_Read.sh (which is not only for S1). See script for usage."

	  		exit 1
    fi
	EchoTee ""
	}

# Change parameters in Parameters txt files
# function ChangeParamRead()
# 	{
# 	unset CRITERIA NEW
# 	local CRITERIA
# 	local NEW
# 	CRITERIA=$1
# 	NEW=$2
#
# 	unset KEY ORIGINAL
# 	local KEY
# 	local ORIGINAL
#
# 	KEY=`echo ${CRITERIA} | tr ' ' _`
#
# 	ORIGINAL=`updateParameterFile ${CSL}/Read_${IMG}.txt ${KEY} ${NEW}`
# 	EchoTee "=> Change in ${parameterFilePath}"
# 	EchoTee "...Key = ${CRITERIA} "
# 	EchoTee "...Former Value =  ${ORIGINAL}"
# 	EchoTee "    --> New Value =  ${NEW}  \n"
# 	}
#


# Let's Go:
###########
cd ${CSL}

# 		Use fct GetAMSTerEngineVersion to get the date of the last version of AMSTerEngine as param LASTVERSIONMT
GetAMSTerEngineVersion

case ${SAT} in
	"SAOCOM")
		# Use the bulk reader
		PARENTCSL="$(dirname "$CSL")"  # get the parent dir, one level up
		REGION=`basename ${PARENTCSL}`

 		# Check if there are any subfolders ending with ".csl"
	    if find "${CSL}" -name "*.csl" -print -quit | grep -q .; then
	      EchoTee "Subfolder links with '.csl' found in ${CSL}"
	      if [ -n "$(find ${CSL} -type l)" ]  ; then
	      	EchoTee "Check if these links are OK, that is pointing toward a valid directory (proving that these links were not made with another OS)"
          	FIRSTLINK=`find * -maxdepth 1 -type l -name "*.csl" 2>/dev/null | head -1`		
	     	 TestLink ${FIRSTLINK}
	     	fi
	    else
	      EchoTee "No subfolders with '.csl' found in ${CSL}, this is a first image reading"
	    fi
 
		# Check if links in ${PARENTCSL} points toward files (must be in ${PARENTCSL}_${TRK}/NoCrop/)
		# if not, remove broken link
		EchoTee "Remove possible broken links"
		#for LINKS in `ls -d *.csl 2>/dev/null`
		#	do
		#		find -L ${LINKS} -type l ! -exec test -e {} \; -exec rm {} \; # first part stays silent if link is ok (or is not a link but a file or dir); answer the name of the link if the link is broken. Second part removes link if broken
		#done
		for LINKS in `ls -d *.csl 2>/dev/null`
			do
				if test "$(jobs | wc -l)" -ge ${CPU}
					then
						case ${OS} in
							"Linux")
								wait -n 	;;
							"Darwin")
								waitn		;;
						esac
				fi
				# Run tests in pseudo parallelism
				{
					find -L ${LINKS} -type l ! -exec test -e {} \; -exec rm {} \; # first part stays silent if link is ok (or is not a link but a file or dir); answer the name of the link if the link is broken. Second part removes link if broken
				} &
		done
		wait

		if [ "${FAY}" == "ForceAllYears" ]
			then
				EchoTee ""
				EchoTeeYellow "Read recent images"
				if [ -n "$(find ${RAW} -mindepth 1 -type d )" ] 
					then
						if [[ "${INITPOL}" == "ALLPOL" ]]
							then
								# Read all polarisations
								SAOCOMDataReader ${RAW} ${CSL} ${KMLS1}
							else
								# Read only requested polarisation
								SAOCOMDataReader ${RAW} ${CSL} ${KMLS1} P=${INITPOL}
						fi
						cp ${CSL}/SAOCOMDataReaderLog.txt ${CSL}/SAOCOMDataReaderLog_Recent.txt
					else
						EchoTee "No recent data."
						touch ${CSL}/SAOCOMDataReaderLog.txt
				fi
				EchoTee ""
				EchoTeeYellow "Read older images"
				# Read in ${RAW}_FORMER/${YYYY}
				if [ -d ${RAW}_FORMER ]
					then
						if [[ "${INITPOL}" == "ALLPOL" ]]
							then
								# Read all polarisations
								SAOCOMDataReader ${RAW} ${CSL} ${KMLS1}
							else
								# Read only requested polarisation
								SAOCOMDataReader ${RAW} ${CSL} ${KMLS1} P=${INITPOL}
						fi
						cp ${CSL}/SAOCOMDataReaderLog.txt ${CSL}/SAOCOMDataReaderLog_Former.txt 2>/dev/null
				fi
				cat ${CSL}/SAOCOMDataReaderLog_Recent.txt ${CSL}/SAOCOMDataReaderLog_Former.txt > ${CSL}/SAOCOMDataReaderLog.txt 2>/dev/null
				rm -f ${CSL}/SAOCOMDataReaderLog_Recent.txt ${CSL}/SAOCOMDataReaderLog_Former.txt 2>/dev/null

			else
				EchoTeeYellow "Read recent images"
				if [ -n "$(find ${RAW} -mindepth 1 -type d )" ] 
					then
						if [[ "${INITPOL}" == "ALLPOL" ]]
							then
								# Read all polarisations
								SAOCOMDataReader ${RAW} ${CSL} ${KMLS1}
							else
								# Read only requested polarisation
								SAOCOMDataReader ${RAW} ${CSL} ${KMLS1} P=${INITPOL}
						fi
					else
						EchoTee "No recent data."
						touch ${CSL}/SAOCOMDataReaderLog.txt
				fi
		fi

		# Check if some data with pol != initpol ? 
		# Script here something like for S1 if one wants to check the other polarisations.. Not advised for time series though

		# move >6 month to FORMER after sorting because one must read xemt files 

		cd ${CSL}
		echo

		# sort Asc and Desc orbits
		EchoTee ""
		EchoTee "Now sorting Asc and Desc SAOCOM images  "
		EchoTee "  because mass reading copes with both orbits at the same time. "
		EchoTeeRed "Do not remove image files (links) from ${CSL} !!"
		EchoTee " Remember: image not apparently read are outside of kml zone (or better kml cover exist),"
		EchoTee "           or another (more recent) image was focused for the same date and was hence read instead."
		EchoTee ""
		
		for SAOCOMIMGPATH in ${CSL}/*.csl  # list actually the former links and the new dir if new images were read
			do
				SAOCOMIMG=`echo ${SAOCOMIMGPATH##*/}` 				# Trick to get only name without path
				SAOCOMMODE=`echo ${SAOCOMIMG} | cut -d _ -f 5 | cut -d . -f1` # Get the Asc or Desc mode
				SAOCOMORBIT=`echo ${SAOCOMIMG} | cut -d _ -f 3 ` 	# Get the orbit nr
				TRIMORBIT=$(echo ${SAOCOMORBIT} | ${PATHGNU}/gsed 's/^0*//') # orbit nr without leading zeros
				SAOCOMDATE=`echo ${SAOCOMIMG} | cut -d _ -f 2` 		# Get the date
				SAOCOMOFRAME=`echo ${SAOCOMIMG} | cut -d _ -f 4 ` # Get the frame nr
				
				# Search for Pedigree.txt if do not exist yet, ie if it is a new reading
				if [ ! -f "${SAOCOMIMGPATH}/Pedigree.txt" ] 
					then 
						echo " No ${SAOCOMIMGPATH}/Pedigree.txt"
						echo "Check image read: ${SAOCOMIMGPATH}"

						for TSTXEMT in `find ${RAW} -maxdepth 2 -mindepth 1 -type f -name "*.xemt"`
							do 
								TSTDATE=`${PATHGNU}/grep "<startTime>" ${TSTXEMT}  | head -1 | ${PATHGNU}/grep -Eo "[0-9]{4}-[0-9]{2}-[0-9]{2}" | ${PATHGNU}/gsed s"/-//g"`
								TSTORB=`${PATHGNU}/grep "<Path>" ${TSTXEMT} | cut -d ">" -f 2  | cut -d "<" -f 1 `
								TSTFRAME=`${PATHGNU}/grep "<Row>" ${TSTXEMT} | cut -d ">" -f 2  | cut -d "<" -f 1 | cut -d . -f 1` # cut before dot in case of wierd frame...
								
								echo "	In ${TSTXEMT}, I get "
								echo "	${TSTDATE} compared to ${SAOCOMDATE}" 
								echo "	${TSTORB} comapred to ${TRIMORBIT}" 
								echo "	${TSTFRAME} compared to ${SAOCOMOFRAME}"
		
								
								if [ "${TSTDATE}" == "${SAOCOMDATE}" ] && [ "${TSTORB}" == "${TRIMORBIT}" ] && [ "${TSTFRAME}" == "${SAOCOMOFRAME}" ] 
									then
										# file contains the same DATE, the same orbit, the same Frame ? 
										# That is the xemt file I was looking for 
										XEMTFILE=${TSTXEMT}
										# and the origonal file name is 
										RAWIMGFILE=`${PATHGNU}/grep "<id>" ${TSTXEMT} | cut -d ">" -f 2  | cut -d "<" -f 1`
										# and focus date is 
										FOCUSDATE=`${PATHGNU}/grep "<startTime>" ${TSTXEMT}  | tail -1 | ${PATHGNU}/grep -Eo "[0-9]{4}-[0-9]{2}-[0-9]{2}" | ${PATHGNU}/gsed s"/-//g"`
										echo "	That is the xemt file for that image. "		
										FOUND="YES"						
										break
									else 
										echo "	That is not the xemt file for that image. "	
										FOUND="NO"
		
								fi
						done 
						if [ "${FOUND}" == "YES" ] 
							then 
								echo ""
								echo "Raw dir name:				${RAWIMGFILE}" >> ${SAOCOMIMGPATH}/Pedigree.txt
		   						echo "xemt file and dir name:		${XEMTFILE}" >> ${SAOCOMIMGPATH}/Pedigree.txt
		   						echo "Focus date: 				${FOCUSDATE}" >> ${SAOCOMIMGPATH}/Pedigree.txt
		   						echo "Acquisition date: 			${SAOCOMDATE}" >> ${SAOCOMIMGPATH}/Pedigree.txt
		   						echo "Image full name: 	  ${SAOCOMIMG}" >> ${SAOCOMIMGPATH}/Pedigree.txt
		   						echo "Orbit: 		${SAOCOMORBIT}" >> ${SAOCOMIMGPATH}/Pedigree.txt
								echo "Direction: 	${SAOCOMMODE}" >> ${SAOCOMIMGPATH}/Pedigree.txt
								echo "Frame: 		${SAOCOMOFRAME}" >> ${SAOCOMIMGPATH}/Pedigree.txt
							else 
								EchoTee "	Xemt file not found for ${SAOCOMIMG} - probably moved to ${RAW}_FORMER ? " 
								EchoTee "==> move ${SAOCOMIMGPATH} back in ${RAW} and relaunch; exiting..."
								exit
								
						fi
				
						# if data exist in /Data, make a LINK
						if [ -f "${SAOCOMIMGPATH}/Data/SLCData.${INITPOL}" ] && [ -s "${SAOCOMIMGPATH}/Data/SLCData.${INITPOL}" ]
							then
								EchoTee "Data found in ${SAOCOMIMGPATH} for ${SAOCOMDATE} in orbit ${SAOCOMORBIT}, ${SAOCOMMODE} "
								mkdir -p ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop
								if [ ! -d ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl ]
									then
										# There is no  ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE} DIR yet, hence it is a new img; move new img there
										mv ${SAOCOMIMGPATH} ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl
										#and create a link
										ln -s ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl ${SAOCOMIMGPATH}
										echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl/Read_w_AMSTerEngine_V.txt
									else
										# There was already a ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl DIR, hence it is an updated (re-created) img; move new img there
										EchoTee "There was already a ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl directory,"
										# Get its frame 
										OLDSAOCOMFRAME=$(${PATHGNU}/grep "Frame" ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl/Pedigree.txt | ${PATHGNU}/grep -Eo "[0-9]*" )

										# Check if same frame ? 
										if [ "${SAOCOMOFRAME}" != "${OLDSAOCOMFRAME}" ]
											then 
												EchoTee "   though that image was updated (re-created) with another frame. Keep only the most recent. "
												CREATIONDATEEXISTINGIMG=$(${PATHGNU}/grep "Focus date" ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl/Pedigree.txt  | ${PATHGNU}/grep -Eo "[0-9]*")
												CREATIONDATENEWIMG=${FOCUSDATE}
												if [ "${CREATIONDATEEXISTINGIMG}" -ge "${CREATIONDATENEWIMG}" ]
													then 
														EchoTee "Existing image is more recent or same date (${CREATIONDATEEXISTINGIMG} vs ${CREATIONDATENEWIMG}). Keep it..."
													else 
														EchoTee "New image is more recent (${CREATIONDATENEWIMG} vs ${CREATIONDATEEXISTINGIMG}). Remove former and replace with new one..."
														rm -rf ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl
														mv -f ${SAOCOMIMGPATH} ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl
														# Create the link 
														ln -s ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl ${SAOCOMIMGPATH}
														echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop/${SAOCOMDATE}.csl/Read_w_AMSTerEngine_V.txt
														
														# List updated image in list for further re-processing
														echo " ${SAOCOMIMG}" >> ${CSL}/SAOCOM_RE_READ_${RUNDATE}.txt  #  List all images in the form of SAO1A_20230401_042_389_A.csl
														# OR make later a reading of all the updated images like for S1 orbit? : 
														# ${PATHGNU}/grep -iB 3 "precise orbit update performed" ${CSL}/S1DataReaderLog.txt | ${PATHGNU}/grep Start | ${PATHGNU}/grep -Eo "[0-9]{8}T" | cut -d T -f1 | uniq > ${CSL}/S1DataReaderLog_NEWORB.txt
												fi
											else 
												EchoTee "   though that image was updated (re-created) with the same frame. "
												EchoTee " This is unexpected... please check and select manually (discard the one you do not want to keep). Stop here. "
												exit
										fi


								fi
							else 
								EchoTee "No data found in ${SAOCOMIMGPATH}. Maybe a problem with the data ? Image will not be moved to ${PARENTCSL}_${SAOCOMORBIT}_${SAOCOMMODE}/NoCrop"
								EchoTee "Remove ${SAOCOMIMGPATH}..."
								rm -rf ${SAOCOMIMGPATH}
						fi
				fi

		done
		echo

		EchoTee ""
		EchoTee "All S1 SAOCOM read; now moving images created (no acquired !) > 6 months in : "
		EchoTee "     ${RAW}_FORMER/_YYYY"
		EchoTee ""
		cd ${RAW}

		TESTDIR=`basename ${RAW}`
		#if [[ $(echo $TESTDIR | ${PATHGNU}/grep -Eo "_[0-9]{4}" | wc -l) -gt 0 ]]
		if echo "${TESTDIR}" | ${PATHGNU}/grep -q '_[0-9]\{4\}$'
			then
				# Dir name contains only _yyyy and hence it is probably run to read only data in _FORMER/_YYYY dir. No need to move to FORMER then
				EchoTee "Probably reading data from _FORMER/_YYYY dir. No need to move them to FORMER again then."
			else
				if [ -n "$(find ${RAW} -mindepth 1 -type d )" ] 
					then
#						for FILESAFE in `ls -d *.SAFE`
						for IMGDIR in `find ${RAW} -maxdepth 1 -mindepth 1 -type d -printf "%f\n"`		# i.e. all dirs in RAW
							do
 								# search .xemt fil in dir 
 								XEMTFILE=$(basename ${RAW}/${IMGDIR}/*.xemt)
  								FOCUSDATE=$(echo ${XEMTFILE} | ${PATHGNU}/grep -Eo "[0-9]{8}T[0-9]{6}" | cut -d T -f 1)

								YEARFILE=`echo ${FOCUSDATE} | cut -c 1-4`
								MMFILE=`echo ${FOCUSDATE} | cut -c 5-6 | ${PATHGNU}/gsed 's/^0*//'`
								DATEFILE=`echo "${YEARFILE} + ( ${MMFILE} / 12 ) - 0.0001" | bc -l` # 0.0001 to avoid next year in december
								YRNOW=`date "+ %Y"`
								MMNOW=`date "+ %-m"`
								DATENOW=`echo "${YRNOW} + ( ${MMNOW} / 12 )" | bc -l`
								DATEHALFYRBFR=`echo "${DATENOW} - 0.5" | bc -l`
								TST=`echo "${DATEFILE} < ${DATEHALFYRBFR}" | bc -l`
								if [ ${TST} -eq 1 ]
									then
										mkdir -p ${RAW}_FORMER/_${YEARFILE}
										mv ${IMGDIR} ${RAW}_FORMER/_${YEARFILE}
								fi
						done
					else
						"No data recently created ; nothing to move."
				fi
		fi
		cd ${CSL}

# create here a cleaning like S1 updated obrit: CHECK FROM HERE 
# vvvvv	
		if [ "${SAR_MASSPROCESS}" != "" ] || [ "${RESAMPLED}" != "" ] ; then
		
			#if [ -f "${CSL}/SAOCOMDataReaderLog_${RUNDATE}.txt" ] && [ -s "${CSL}/SAOCOMDataReaderLog_${RUNDATE}.txt" ]  ; then
			if [ -f "${CSL}/SAOCOM_RE_READ_${RUNDATE}.txt" ] && [ -s "${CSL}/SAOCOM_RE_READ_${RUNDATE}.txt" ]  ; then
				EchoTee "List all processes to clean in RESAMPLED and SAR_MASSPROCESS which include images that were updated."
				for IMGTOCLEAN in `cat ${CSL}/SAOCOM_RE_READ_${RUNDATE}.txt`   #  List all images in the form of SAO1A_20230401_042_389_A.csl
					do
						DATEIMGTOCLEAN=`echo "${IMGTOCLEAN}" | cut -d _ -f2 `
						if [ "${RESAMPLED}" != "" ] ; then
	 						cd ${RESAMPLED}/SAOCOM
							EchoTee "Image ${DATEIMGTOCLEAN} was updated. "
							EchoTee "List all processing involving ${DATEIMGTOCLEAN} from RESAMPLED/SAOCOM/${REGION}*"
	
							find ${REGION}* -name "*${DATEIMGTOCLEAN}*" -a -prune 2>/dev/null >> ${CSL}/CleanRESAMPLED_${RUNDATE}_tmp.txt # e.g. LagunaFea_A_xx/SMNoCrop_SM_yyyymmdd/yyyymmdd_yyyymmdd
						fi
						if [ "${SAR_MASSPROCESS}" != "" ] ; then
							cd ${SAR_MASSPROCESS}/SAOCOM
							EchoTee "List all processing involving ${DATEIMGTOCLEAN} from SAR_MASSPROCESS/S1/${REGION}*"
							find ${REGION}* -name "*${DATEIMGTOCLEAN}*" -a -prune 2>/dev/null >> ${CSL}/CleanMASSPROCESS_${RUNDATE}_tmp.txt
						fi
				done
				
				echo
				# add possible former list that was postponed because a run was in progress
				cat ${CSL}/CleanRESAMPLED_TODO_NEXT_TIME.txt ${CSL}/CleanRESAMPLED_${RUNDATE}_tmp.txt 2>/dev/null | sort | uniq > ${CSL}/CleanRESAMPLED_${RUNDATE}.txt
				cat ${CSL}/CleanMASSPROCESS_TODO_NEXT_TIME.txt ${CSL}/CleanMASSPROCESS_${RUNDATE}_tmp.txt 2>/dev/null | sort | uniq > ${CSL}/CleanMASSPROCESS_${RUNDATE}.txt

				rm -f ${CSL}/CleanRESAMPLED_${RUNDATE}_tmp.txt ${CSL}/CleanMASSPROCESS_${RUNDATE}_tmp.txt

				EchoTee "Move in *_CLN all the processes in RESAMPLED and/or SAR_MASSPROCESS which include images that were re-read"
				EchoTee "   Move them in ${RESAMPLED}/SAOCOM_CLN/"
				EchoTee "            and ${SAR_MASSPROCESS}/SAOCOM_CLN/"
				EchoTee "Note that old products in *_CLN (>180 days; see param MACLN in script) will be deleted."

				# get all modes in ${CSL}/CleanRESAMPLED_${RUNDATE}.txt
				${PATHGNU}/gsed 's%\/.*%%' ${CSL}/CleanRESAMPLED_${RUNDATE}.txt | sort | uniq > TRKDIR_list_${RUNDATE}_${RNDM1}.txt		# list all mode dirs in RESAMPLED, eg. LagunaFea_A_xx 
				DATAPATH="$(dirname "$PARENTCSL")"  # get the parent dir, one level up

				for TRKDIR in `cat TRKDIR_list_${RUNDATE}_${RNDM1}.txt 2>/dev/null`
				do
				# If no ${PARENTCSL}_${SAOCOMMODE}_${SAOCOMORBIT}/NoCrop/DoNotUpdateProducts_*_*.txt of less than 1 day (1440 min) then can remove products
				# Note that we consider that if DoNotUpdateProducts_*_*.txt are odler than 1440 min, they must be ghost file and will be ignored.
					CHECKFLAGUSAGE=`find ${DATAPATH}/${TRKDIR}/NoCrop/ -maxdepth 1 -name "DoNotUpdateProducts_*_*.txt" -type f -mmin -1440 | wc -l`
					if [ ${CHECKFLAGUSAGE} -eq 0 ]
						then
							echo # just if nothing shows up in loop
							# ok no process running since less than 1 day: can proceed to cleaning
										#for FILESTOCLEAN in `cat  ${CSL}/CleanRESAMPLED_${RUNDATE}.txt`
										if [ "${RESAMPLED}" != "" ] ; then

											for FILESTOCLEAN in `${PATHGNU}/grep ${TRKDIR} ${CSL}/CleanRESAMPLED_${RUNDATE}.txt`  # e.g. LagunaFea_A_xx/SMNoCrop_SM_yyyymmdd/yyyymmdd_yyyymmdd
											do
												if test "$(jobs | wc -l)" -ge ${CPU}
													then
														case ${OS} in
															"Linux")
																wait -n 	;;
															"Darwin")
																waitn		;;
														esac
												fi
												# Run tests in pseudo parallelism
												{
													PATHFILESTOCLEAN=$(dirname "${FILESTOCLEAN}")
													mkdir -p ${RESAMPLED}/SAOCOM_CLN/${PATHFILESTOCLEAN}
													# echo "Image ${FILESTOCLEAN} re-read. Should move ${RESAMPLED}/SAOCOM/${FILESTOCLEAN} to ${RESAMPLED}/SAOCOM_CLN/${PARENTCSL}_${SAOCOMMODE}_${SAOCOMORBIT}/"
													mv -f ${RESAMPLED}/SAOCOM/${FILESTOCLEAN} ${RESAMPLED}/SAOCOM_CLN/${FILESTOCLEAN}
												} &
											done
											wait
											# because products were cleaned, one can discard the list (if any) of products to clean
											rm -f ${CSL}/CleanRESAMPLED_TODO_NEXT_TIME.txt
										fi

										#for FILESTOCLEAN in `cat  ${CSL}/CleanMASSPROCESS_${RUNDATE}.txt`
										if [ "${SAR_MASSPROCESS}" != "" ] ; then
											for FILESTOCLEAN in `${PATHGNU}/grep ${TRKDIR}  ${CSL}/CleanMASSPROCESS_${RUNDATE}.txt`
											do
												if test "$(jobs | wc -l)" -ge ${CPU}
													then
														case ${OS} in
															"Linux")
																wait -n 	;;
															"Darwin")
																waitn		;;
														esac
												fi
												# Run tests in pseudo parallelism
												{
													# if a pair MAS_SLV was already updated for the MAS and is now updated for the SLV, the MAS_SLV dir exist already. Rename it first as MAS_SLV_1st_update
													if [ -d ${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEAN} ]
														then
															mv -f ${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEAN} ${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEAN}_1st_update
															mv -f ${SAR_MASSPROCESS}/SAOCOM/${FILESTOCLEAN} ${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEAN}
														else
															PATHFILESTOCLEAN=$(dirname "${FILESTOCLEAN}")

															if [ -f "${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEAN}" ] && [ -s "${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEAN}" ]
																then
																	FILESTOCLEANEXT="${FILESTOCLEAN##*.}" # extention only
																	FILESTOCLEANNOEXT="${FILESTOCLEAN%.*}" # path and name without extention
																	mv -f ${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEAN} ${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEANNOEXT}_1st_update.${FILESTOCLEANEXT}
															fi
															mkdir -p ${SAR_MASSPROCESS}/SAOCOM_CLN/${PATHFILESTOCLEAN}
															# echo "Image ${FILESTOCLEAN} was re-read. Should move  ${SAR_MASSPROCESS}/SAOCOM/${FILESTOCLEAN} to ${SAR_MASSPROCESS}/SAOCOM_CLN/${PARENTCSL}_${SAOCOMMODE}_${SAOCOMORBIT}/"
															mv -f ${SAR_MASSPROCESS}/SAOCOM/${FILESTOCLEAN} ${SAR_MASSPROCESS}/SAOCOM_CLN/${FILESTOCLEAN}
													fi
												} &
											done
											wait
										# because products were cleaned, one can discard the list (if any) of products to clean
										rm -f ${CSL}/CleanMASSPROCESS_TODO_NEXT_TIME.txt
									fi
						else
							# Some processes are running. Let's wait next run to clean the products.
							# Store them in ${CSL}/CleanRESAMPLED_TODO_NEXT_TIME.txt and ${CSL}/CleanMASSPROCESS_TODO_NEXT_TIME.txt
							EchoTee " A process seems to be using data from ${SAOCOMORBIT}. To avoid possible clash, we postpone here the move of old products using images with former read."
							# store/add them in a file for next run
							cat ${CSL}/CleanRESAMPLED_${RUNDATE}.txt >> ${CSL}/CleanRESAMPLED_TODO_NEXT_TIME.txt
							cat ${CSL}/CleanMASSPROCESS_${RUNDATE}.txt >> ${CSL}/CleanMASSPROCESS_TODO_NEXT_TIME.txt
							# sort and uniq
							sort ${CSL}/CleanRESAMPLED_TODO_NEXT_TIME.txt | uniq > ${CSL}/CleanRESAMPLED_TODO_NEXT_TIME.clean.txt
							sort ${CSL}/CleanMASSPROCESS_TODO_NEXT_TIME.txt | uniq > ${CSL}/CleanMASSPROCESS_TODO_NEXT_TIME.clean.txt
							mv -f ${CSL}/CleanRESAMPLED_TODO_NEXT_TIME.clean.txt ${CSL}/CleanRESAMPLED_TODO_NEXT_TIME.txt
							mv -f ${CSL}/CleanMASSPROCESS_TODO_NEXT_TIME.clean.txt ${CSL}/CleanMASSPROCESS_TODO_NEXT_TIME.txt
					fi
				done
				rm -f TRKDIR_list_${RUNDATE}_${RNDM1}.txt
			else
				EchoTee " No image re-read."
				# file is hence empty
# ^^^^^^^
# TO HERE 
				rm -f ${CSL}/SAOCOMDataReaderLog_${RUNDATE}.txt
			fi
		fi
		;;
	"S1") # Use bulk reader
		# first update the orbit table
		#updateS1PrecisesOrbits  	# obsolate

		if [ "${NOORB}" == "-n" ]
			then
				EchoTee "Request to skip local S1 orbit data base update"
			else
				EchoTee "Request to update local S1 orbit data base. This will be performed since the last available precise orbit date"
				# Since V April 2022, MasTer Engine uses again ESA orbits. Add -ASF param below if want to take orbits from ASF site
				if [ "${FAY}" == "ForceAllYears" ]
					then
						updateS1Orbits from=20140101	# Update the whole local S1 orbit data base
					else
						updateS1Orbits					# Update only the local S1 orbit data base since the last available precise orbit date
				fi
		fi

		PARENTCSL="$(dirname "$CSL")"  # get the parent dir, one level up
		REGION=`basename ${PARENTCSL}`

		# Check if there are any subfolders ending with ".csl"
	    if find "${CSL}" -name "*.csl" -print -quit | grep -q .; then
	      EchoTee "Subfolders with '.csl' found in ${CSL}"
	      EchoTee "Check if the links are OK, eg. not from the wrong OS"
	      FIRSTLINK=`find * -maxdepth 1 -type l -name "*.csl" 2>/dev/null | head -1`		# what if not link exist yet ??
	      TestLink ${FIRSTLINK}
	    else
	      EchoTee "No subfolders with '.csl' found in ${CSL}, this is a first image reading"
	    fi

		# Check if links in ${PARENTCSL} points toward files (must be in ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/)
		# if not, remove broken link
		EchoTee "Remove possible broken links"
		for LINKS in `ls -d *.csl 2>/dev/null`
			do
				if test "$(jobs | wc -l)" -ge ${CPU}
					then
						case ${OS} in
							"Linux")
								wait -n 	;;
							"Darwin")
								waitn		;;
						esac
				fi
				# Run tests in pseudo parallelism
				{
					find -L ${LINKS} -type l ! -exec test -e {} \; -exec rm {} \; # first part stays silent if link is ok (or is not a link but a file or dir); answer the name of the link if the link is broken. Second part removes link if broken
				} &
		done
		wait

		if [ "${FAY}" == "ForceAllYears" ]
			then
				EchoTee ""
				EchoTeeYellow "Read recent images"
				if [ `ls -d ${RAW}/*.SAFE 2>/dev/null | wc -l` -le 0 ] ; then
					EchoTee "No recent data."
					touch ${CSL}/S1DataReaderLog.txt
				else
					if [[ "${INITPOL}" == "ALLPOL" ]]
						then
							# Read all polarisations
							S1DataReader ${RAW} ${CSL} ${KMLS1}
						else
							# Read only requested polarisation
							S1DataReader ${RAW} ${CSL} ${KMLS1} P=${INITPOL}
					fi
					cp ${CSL}/S1DataReaderLog.txt ${CSL}/S1DataReaderLog_Recent.txt
				fi
				EchoTee ""
				EchoTeeYellow "Read older images"
				# Read in ${RAW}_FORMER/${YYYY}
				if [ -d ${RAW}_FORMER ]
					then
						if [[ "${INITPOL}" == "ALLPOL" ]]
							then
								# Read all polarisations
								S1DataReader ${RAW}_FORMER ${CSL} ${KMLS1}
							else
								# Read only requested polarisation
								S1DataReader ${RAW}_FORMER ${CSL} ${KMLS1} P=${INITPOL}
						fi
						cp ${CSL}/S1DataReaderLog.txt ${CSL}/S1DataReaderLog_Former.txt 2>/dev/null
				fi
				cat ${CSL}/S1DataReaderLog_Recent.txt ${CSL}/S1DataReaderLog_Former.txt > ${CSL}/S1DataReaderLog.txt 2>/dev/null
				rm -f ${CSL}/S1DataReaderLog_Recent.txt ${CSL}/S1DataReaderLog_Former.txt 2>/dev/null

			else
				EchoTeeYellow "Read only recent images"
				if [ `ls -d ${RAW}/*.SAFE 2>/dev/null | wc -l` -le 0 ] ; then
   					EchoTee "No recent data."
   					touch ${CSL}/S1DataReaderLog.txt
				else
					if [[ "${INITPOL}" == "ALLPOL" ]]
						then
							# Read all polarisations
							S1DataReader ${RAW} ${CSL} ${KMLS1}
						else
							# Read only requested polarisation
							S1DataReader ${RAW} ${CSL} ${KMLS1} P=${INITPOL}
					fi
				fi
		fi

		# Check if some data with pol != initpol

		if [[ "${INITPOL}" != "ALLPOL" ]]
			then
				case "${INITPOL}" in
					"VV")
						# list all 3 lines with other pol, extract only those with the dates, which are those also TOPSAR string, then get only the file names
						${PATHGNU}/grep -B 3 "Available polarizations are: HH" ${CSL}/S1DataReaderLog.txt  |  ${PATHGNU}/grep "TOPSAR" | cut -d " " -f 6  > ${CSL}/List_IMG_pol_HH_${RUNDATE}.txt

						if [ -f "${CSL}/List_IMG_pol_HH_${RUNDATE}.txt" ] && [ -s "${CSL}/List_IMG_pol_HH_${RUNDATE}.txt" ]
							then
								mkdir -p ${RAW}_FORMER/___tmp_img_pol_HH
								# move all the HH files in a temp dir where they will be read
								while read -r FILEHHPO
								do
									mv ${RAW}/${FILEHHPO} ${RAW}_FORMER/___tmp_img_pol_HH
								done < ${CSL}/List_IMG_pol_HH_${RUNDATE}.txt

								cd  ${RAW}_FORMER/___tmp_img_pol_HH
								S1DataReader ${RAW} ${CSL} ${KMLS1}	P=HH

								# get them back
								while read -r FILEHHPO
								do
									mv ${RAW}_FORMER/___tmp_img_pol_HH/${FILEHHPO} ${RAW}
								done < ${CSL}/List_IMG_pol_HH_${RUNDATE}.txt
								cd ${CSL}
							else
								# if file is empty, delete it
								rm -f ${CSL}/List_IMG_pol_HH_${RUNDATE}.txt
						fi
						;;
					"HH")
						# list all 3 lines with other pol, extract only those with the dates, which are those also TOPSAR string, then get only the file names
						${PATHGNU}/grep -B 3 "Available polarizations are: VV" ${CSL}/S1DataReaderLog.txt  |  ${PATHGNU}/grep "TOPSAR" | cut -d " " -f 6  > ${CSL}/List_IMG_pol_VV_${RUNDATE}.txt

						if [ -f "${CSL}/List_IMG_pol_VV_${RUNDATE}.txt" ] && [ -s "${CSL}/List_IMG_pol_VV_${RUNDATE}.txt" ]
							then
								mkdir -p ${RAW}_FORMER/___tmp_img_pol_VV
								# move all the VV files in a temp dir where they will be read
								while read -r FILEVVPO
								do
									mv ${RAW}/${FILEVVPO} ${RAW}_FORMER/___tmp_img_pol_VV
								done < ${CSL}/List_IMG_pol_VV_${RUNDATE}.txt

								cd  ${RAW}_FORMER/___tmp_img_pol_VV
								S1DataReader ${RAW} ${CSL} ${KMLS1}	P=VV

								# get them back
								while read -r FILEVVPO
								do
									mv ${RAW}_FORMER/___tmp_img_pol_VV/${FILEVVPO} ${RAW}
								done < ${CSL}/List_IMG_pol_VV_${RUNDATE}.txt
								cd ${CSL}
							else
								# if file is empty, delete it
								rm -f ${CSL}/List_IMG_pol_VV_${RUNDATE}.txt
						fi
						;;

				esac
		fi

		EchoTee ""
		EchoTee "All S1 img read; now moving images > 6 months in : "
		EchoTee "     ${RAW}_FORMER/_YYYY"
		EchoTee ""
		cd ${RAW}

		TESTDIR=`basename ${RAW}`
		#if [[ $(echo $TESTDIR | ${PATHGNU}/grep -Eo "_[0-9]{4}" | wc -l) -gt 0 ]]
		if echo "${TESTDIR}" | ${PATHGNU}/grep -q '_[0-9]\{4\}$'
			then
				# Dir name contains only _yyyy and hence it is probably run to read only data in _FORMER/_YYYY dir. No need to move to FORMER then
				EchoTee "Probably reading data from _FORMER/_YYYY dir. No need to move them to FORMER again then."
			else
				if [ `ls -d ${RAW}/*.SAFE 2>/dev/null | wc -l` -le 0 ] ; then
							EchoTee "No recent data ; nothing to move."
					else
						for FILESAFE in `ls -d *.SAFE`
							do
								YEARFILE=`echo ${FILESAFE} | cut -c 18-21`
								MMFILE=`echo ${FILESAFE} | cut -c 22-23 | ${PATHGNU}/gsed 's/^0*//'`
								DATEFILE=`echo "${YEARFILE} + ( ${MMFILE} / 12 ) - 0.0001" | bc -l` # 0.0001 to avoid next year in december
								YRNOW=`date "+ %Y"`
								MMNOW=`date "+ %-m"`
								DATENOW=`echo "${YRNOW} + ( ${MMNOW} / 12 )" | bc -l`
								DATEHALFYRBFR=`echo "${DATENOW} - 0.5" | bc -l`
								TST=`echo "${DATEFILE} < ${DATEHALFYRBFR}" | bc -l`
								if [ ${TST} -eq 1 ]
									then
										mkdir -p ${RAW}_FORMER/_${YEARFILE}
										mv ${FILESAFE} ${RAW}_FORMER/_${YEARFILE}
								fi
						done
				fi
		fi

		cd ${CSL}
		echo

		# sort Asc and Desc orbits
		EchoTee ""
		EchoTee "Now sorting S1 :"
		EchoTee "Because S1 mass reading copes with both Asc and Desc orbits and for each Orbit Track at the same time, I will sort them out here for you using links in corresponding dirs."
		EchoTeeRed "Do not remove image files from ${CSL} !!"
		EchoTee ""
		for S1IMGPATH in ${CSL}/*.csl  # list actually the former links and the new dir if new images were read
			do
				if test "$(jobs | wc -l)" -ge ${CPU}
					then
						case ${OS} in
							"Linux")
								wait -n 	;;
							"Darwin")
								waitn		;;
						esac
				fi
				# Run tests in pseudo parallelism
				{

					S1IMG=`echo ${S1IMGPATH##*/}` 				# Trick to get only name without path
					S1TRK=`echo ${S1IMG} | cut -d _ -f 2` 		# Get the orbit nr
					S1MODE=`echo ${S1IMG} | cut -d _ -f 4 | cut -c 1` # Get the Asc or Desc mode
					mkdir -p ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop
					if [ ! -d ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/${S1IMG} ]
						then
								# There is no  ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/${S1IMG} DIR yet, hence it is a new img; move new img there
								mv ${S1IMG} ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/
								#and create a link
								ln -s ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/${S1IMG} ${CSL}
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/${S1IMG}/Read_w_AMSTerEngine_V.txt
					fi
				} &
		done
		wait

		echo
		# Do not test if there are files in ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/ without links in ${PARENTCSL}.
		# Shouldn't be a problem because in such a case, without link in PARENTCSL, it dowload the image again.

		# Stitch bursts and check size. Re-read if size (in bytes) of image with stitched bursts is not compliant with cols x rows x 8
		# It will only stitch modes as expressed in a table that is expected here :
		EchoTee ""
		EchoTee "Now stiches all bursts of S1 images (if wide swath) "
		EchoTee "  and check if size is compliant with number or lines and columns. If not, re-stitch the image "

		EchoTee "Then check the size of all Primary images and store that info in NoCrop/List_Master_Sizes.txt. "
		EchoTee "  You may want to check it to ensure that no bursts are missing in some images. "
		EchoTee ""
		EchoTee "Then delete data that are in quarantained in SAR_CSL/S1/region/Quarantained. "
		EchoTee ""
		EchoTee "Then list bursts for each image in files. "
		EchoTee ""

		for TRACKS in `ls -d ${PARENTCSL}_* `  # all tracks without parent dir
			do
				if test "$(jobs | wc -l)" -ge ${CPU}
					then
						case ${OS} in
							"Linux")
								wait -n 	;;
							"Darwin")
								waitn		;;
						esac
				fi
				# Run tests in pseudo parallelism
				{

					cd ${TRACKS}/NoCrop
					EchoTee ""
					EchoTee "Check mode ${TRACKS}: "
					EchoTee "----------------------"
					Check_All_S1_ImgReadSize.sh ${INITPOL}
					cd ${TRACKS}/NoCrop
					List_All_S1_ImgSize.sh
					if [ -d ${TRACKS}/Quarantained ] ; then
						cd ${TRACKS}/Quarantained
						for IMGQUARANTAINED in `ls -d *.csl `
							do
							rm -Rf ${TRACKS}/NoCrop/${IMGQUARANTAINED}
						done
					fi

					cd ${TRACKS}/NoCrop
					FIRSTIMG=`find . -type f -name "SLCImageInfo.txt" -print -quit`
					CHECKWS=`${PATHGNU}/grep "Beam" ${FIRSTIMG} | ${PATHGNU}/gsed 's@^[^0-9]*\([0-9]\+\).*@\1@'`
					if [ "${CHECKWS}" != "0" ]
						then
							EchoTee "S1 is SM; skip burst listing"
						else
							EchoTee "S1 is wide swath; proceed to burst listing"
							List_S1_Frames_Swaths_Bursts.sh
					fi
				} &
		done
		wait

		EchoTee ""
		cd ${CSL}
		# Clear all processes which include images for which Fast 24 frame was updated in RESAMPLED, SAR_MASSPROCESS
		# BELOW NEEDED UPDATE in V1.5.3
		# Because the S1Reader output a new line for each updated frame of the same image, let's uniq the log file
		#	cat ${CSL}/S1DataReaderLog.txt | uniq > ${CSL}/S1DataReaderLog_${RUNDATE}.txt
		# new:
		# serach for lines with info about FAST24 img,i.e. "Fast-24h frame %d replaced by Normal Archive one in image %s\n"
		${PATHGNU}/grep "Fast-24h frame" ${CSL}/S1DataReaderLog.txt > ${CSL}/S1DataReaderLog_FAST24.txt
		# uniq just in case
		cat ${CSL}/S1DataReaderLog_FAST24.txt | uniq > ${CSL}/S1DataReaderLog_FAST24_${RUNDATE}.txt

		if [ "${SAR_MASSPROCESS}" != "" ] || [ "${RESAMPLED}" != "" ] ; then
			if [ -f "${CSL}/S1DataReaderLog_FAST24_${RUNDATE}.txt" ] && [ -s "${CSL}/S1DataReaderLog_FAST24_${RUNDATE}.txt" ]  ; then
				EchoTee "List all processes to clean which include images for which Fast 24 frame was updated in RESAMPLED, SAR_MASSPROCESS"
				for IMGTOCLEAN in `cat ${CSL}/S1DataReaderLog_FAST24_${RUNDATE}.txt`
					do
						if test "$(jobs | wc -l)" -ge ${CPU}
							then
								case ${OS} in
									"Linux")
										wait -n 	;;
									"Darwin")
										waitn		;;
								esac
						fi
						# Run tests in pseudo parallelism
						{
							DATEIMGTOCLEAN=`echo "${IMGTOCLEAN}" | cut -d _ -f3 `

							if [ "${RESAMPLED}" != "" ] ; then
								cd ${RESAMPLED}/S1
								EchoTee "${IMGTOCLEAN} was updated (Fast-24h frames were replaced by ArchNorm ones)"
								EchoTee "List all processing involving ${DATEIMGTOCLEAN} (i.e. ${IMGTOCLEAN}) from RESAMPLED"

								#find ${REGION}* -name "*${DATEIMGTOCLEAN}*" -a -prune >> ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}.txt
								find ${REGION}* -name "*${DATEIMGTOCLEAN}*" -a -prune 2>/dev/null  >> ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}_tmp.txt
							fi

							if [ "${SAR_MASSPROCESS}" != "" ]  ; then
								cd ${SAR_MASSPROCESS}/S1/
								EchoTee "List all processing involving ${DATEIMGTOCLEAN} (i.e. ${IMGTOCLEAN}) from SAR_MASSPROCESS"
								#find ${REGION}* -name "*${DATEIMGTOCLEAN}*" -a -prune  >> ${CSL}/FAST24_CleanMASSPROCESS_${RUNDATE}.txt
								find ${REGION}* -name "*${DATEIMGTOCLEAN}*" -a -prune 2>/dev/null  >> ${CSL}/FAST24_CleanMASSPROCESS_${RUNDATE}_tmp.txt
							fi
						} &
				done
				wait

				echo
				# add possible former list that was postponed because a run was in progress
				cat ${CSL}/FAST24_CleanRESAMPLED_TODO_NEXT_TIME.txt ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}_tmp.txt 2>/dev/null | sort | uniq > ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}.txt
				cat ${CSL}/FAST24_CleanMASSPROCESS_TODO_NEXT_TIME.txt ${CSL}/FAST24_CleanMASSPROCESS_${RUNDATE}_tmp.txt 2>/dev/null | sort | uniq > ${CSL}/FAST24_CleanMASSPROCESS_${RUNDATE}.txt

				rm -f ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}_tmp.txt ${CSL}/FAST24_CleanMASSPROCESS_${RUNDATE}_tmp.txt

				# Move files - this could be deleted later I guess
				# Check first that no one is using it

#				# Check that no SuperMaster_MassProc.sh is running with a LaunchMTparam_..txt from S1. Maybe not the best test...
#				CHECKMP=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep SuperMaster_MassProc.sh" | ${PATHGNU}/grep LaunchMTparam_  | ${PATHGNU}/grep "/S1/" | wc -l`
#				if [ ${CHECKMP} -eq 0 ]
#					then
						EchoTee "Move in *_CLN all the processes in RESAMPLED and/or SAR_MASSPROCESS which include images for which Fast 24 frame were updated"
						EchoTee "   Move them in ${RESAMPLED}/S1_CLN/CLEANED_FAST24/"
						EchoTee "            and ${SAR_MASSPROCESS}/S1_CLN/CLEANED_FAST24/"
						EchoTee "Note that old products in *_CLN (>180 days; see param MACLN in script) will be deleted."

				# get all modes in ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}.txt
				${PATHGNU}/gsed 's%\/.*%%' ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}.txt | sort | uniq > TRKDIR_list_${RUNDATE}_${RNDM1}.txt
				DATAPATH="$(dirname "$PARENTCSL")"  # get the parent dir, one level up

				for TRKDIR in `cat TRKDIR_list_${RUNDATE}_${RNDM1}.txt`
				do
				# If no ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/DoNotUpdateProducts_*_*.txt of less than 1 day (1440 min) then can remove products
				# Note that we consider that if DoNotUpdateProducts_*_*.txt are odler than 1440 min, they must be ghost file and will be ignored.
					CHECKFLAGUSAGE=`find ${DATAPATH}/${TRKDIR}/NoCrop/ -maxdepth 1 -name "DoNotUpdateProducts_*_*.txt" -type f -mmin -1440 | wc -l`
					if [ ${CHECKFLAGUSAGE} -eq 0 ]
						then
							# ok no process running since less than 1 day: can proceed to cleaning
#							#for FILESTOCLEAN in `cat  ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}.txt`
							echo # just in case nothing in loop

							if [ "${RESAMPLED}" != "" ] ; then
								for FILESTOCLEAN in `${PATHGNU}/grep ${TRKDIR} ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}.txt`
								do
									if test "$(jobs | wc -l)" -ge ${CPU}
										then
											case ${OS} in
												"Linux")
													wait -n 	;;
												"Darwin")
													waitn		;;
											esac
									fi
									# Run tests in pseudo parallelism
									{
										PATHFILESTOCLEAN=$(dirname "${FILESTOCLEAN}")
										mkdir -p ${RESAMPLED}/S1_CLN/CLEANED_FAST24/${PATHFILESTOCLEAN}
										mv -f ${RESAMPLED}/S1/${FILESTOCLEAN} ${RESAMPLED}/S1_CLN/CLEANED_FAST24/${FILESTOCLEAN}
									} &
								done
								wait

								# because products were cleaned, one can discard the list (if any) of products to clean
								rm -f ${CSL}/FAST24_CleanRESAMPLED_TODO_NEXT_TIME.txt 2>/dev/null
							fi
#
#							#for FILESTOCLEAN in `cat  ${CSL}/FAST24_CleanMASSPROCESS_${RUNDATE}.txt`

							if [ "${SAR_MASSPROCESS}" != "" ] ; then
								for FILESTOCLEAN in `${PATHGNU}/grep ${TRKDIR} ${CSL}/FAST24_CleanMASSPROCESS_${RUNDATE}.txt`
								do
									if test "$(jobs | wc -l)" -ge ${CPU}
										then
											case ${OS} in
												"Linux")
													wait -n 	;;
												"Darwin")
													waitn		;;
											esac
									fi
									# Run tests in pseudo parallelism
									{
										PATHFILESTOCLEAN=$(dirname "${FILESTOCLEAN}")
										mkdir -p ${SAR_MASSPROCESS}/S1_CLN/CLEANED_FAST24/${PATHFILESTOCLEAN}
										mv -f ${SAR_MASSPROCESS}/S1/${FILESTOCLEAN} ${SAR_MASSPROCESS}/S1_CLN/CLEANED_FAST24/${FILESTOCLEAN}
									} &
								done
								wait

								# because products were cleaned, one can discard the list (if any) of products to clean
								rm -f ${CSL}/FAST24_CleanMASSPROCESS_TODO_NEXT_TIME.txt  2>/dev/null
							fi
					else
						#EchoTee " A SuperMaster_MassProc.sh seems to be using a LaunchParam_....txt file. To avoid possible clash, we postpone here the move of old products using outdated fast24 images"
						EchoTee " A process seems to be using data from ${TRKDIR}. To avoid possible clash, we postpone here the move of old products using images with outdated fast24 images"
						RUNPROC=`find ${DATAPATH}/${TRKDIR}/NoCrop/ -maxdepth 1 -name "DoNotUpdateProducts_*_*.txt" -type f -mmin -1440`
						EchoTee "  Running process : ${RUNPROC}"

						# store/add them in a file for next run
						cat ${CSL}/FAST24_CleanRESAMPLED_${RUNDATE}.txt >> ${CSL}/FAST24_CleanRESAMPLED_TODO_NEXT_TIME.txt
						cat ${CSL}/FAST24_CleanMASSPROCESS_${RUNDATE}.txt >> ${CSL}/FAST24_CleanMASSPROCESS_TODO_NEXT_TIME.txt
						# sort and uniq
						sort ${CSL}/FAST24_CleanRESAMPLED_TODO_NEXT_TIME.txt | uniq > ${CSL}/FAST24_CleanRESAMPLED_TODO_NEXT_TIME.clean.txt
						sort ${CSL}/FAST24_CleanMASSPROCESS_TODO_NEXT_TIME.txt | uniq > ${CSL}/FAST24_CleanMASSPROCESS_TODO_NEXT_TIME.clean.txt
						mv -f ${CSL}/FAST24_CleanRESAMPLED_TODO_NEXT_TIME.clean.txt ${CSL}/FAST24_CleanRESAMPLED_TODO_NEXT_TIME.txt
						mv -f ${CSL}/FAST24_CleanMASSPROCESS_TODO_NEXT_TIME.clean.txt ${CSL}/FAST24_CleanMASSPROCESS_TODO_NEXT_TIME.txt

					fi
				done
				rm -f TRKDIR_list_${RUNDATE}_${RNDM1}.txt
			else
				EchoTee " No Fast-24h frames replaced by ArchNorm ones."
				# file is hence empty
				rm -f ${CSL}/S1DataReaderLog_FAST24_${RUNDATE}.txt
			fi
		fi
		echo

		EchoTee "Run the check of S1 orbits"
		EchoTee "--------------------------"
		echo
			${PATHGNU}/grep -iB 3 "precise orbit update performed" ${CSL}/S1DataReaderLog.txt | ${PATHGNU}/grep Start | ${PATHGNU}/grep -Eo "[0-9]{8}T" | cut -d T -f1 | uniq > ${CSL}/S1DataReaderLog_NEWORB.txt
			# uniq just in case (contains then ony lines such as: 20200923)
			cat ${CSL}/S1DataReaderLog_NEWORB.txt | uniq > ${CSL}/S1DataReaderLog_NEWORB_${RUNDATE}.txt


#			#S1OrbitUpdater ${CSL} -u | tee  ${CSL}/UpdatabelOrbits_${RUNDATE}.txt
#			# Test if orbits are missing :
#			cat ${CSL}/UpdatabelOrbits_${RUNDATE}.txt | ${PATHGNU}/grep "No precise orbit file found in local data base for this image" -B 1 | ${PATHGNU}/grep -v "No precise orbit file found in local data base for this image" | cut -d _ -f3 >  ${CSL}/NoPreciseOrbitsFoundFor_${RUNDATE}.txt
#			rm  ${CSL}/UpdatabelOrbits_${RUNDATE}.txt
#			# One should check here if some images are less than 1 months old. If yes, there must be a problem with orbits download
#			echo
#			 EchoTee "Check if files that could have been updated and were not are older than 30 days."
#			 EchoTee " This would mean that there is a problem with orbits "
#			# get the list of YYYYmm of missing orbits from ${CSL}/NoPreciseOrbitsFoundFor_${RUNDATE}.txt
#			if [ -s ${CSL}/NoPreciseOrbitsFoundFor_${RUNDATE}.txt ] ; then
#				cat ${CSL}/NoPreciseOrbitsFoundFor_${RUNDATE}.txt | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -c 1-6 | sort | uniq > ${CSL}/OrbitsToDownload_${RUNDATE}.txt
#
#				# If at least one orbit to download exists, then try to re-download the whole orbits using CSL function
#				if [ -s ${CSL}/OrbitsToDownload_${RUNDATE}.txt ] ; then
#					updateS1PrecisesOrbits
#				fi
#
#				for DATETOCHECK in `cat ${CSL}/NoPreciseOrbitsFoundFor_${RUNDATE}.txt`
#					do
#						TODAY=`date +%s`  							# Today as seconds since 1970-01-01
#						DOITOCHECK=`date -d "${DATETOCHECK}" +%s`	# Date to check as seconds since 1970-01-01
#						DIFFSEC=`echo "( ${TODAY} - ${DOITOCHECK} )" | bc `
#						DIFFDAYS=`echo "( ${DIFFSEC} / 86400 )" | bc `
#						echo "Date diff : ${TODAY} - ${DOITOCHECK} = ${DIFFSEC}"
#						if [ ${DIFFSEC} -le 2678400 ] # if diff is less than 31 days in sec : ok
#							then
#								EchoTeeYellow " Image without updated orbit (${DATETOCHECK}) is less than 31 days old. Might not be a problem "
# 							else
# 								EchoTeeRed " Image without updated orbit (${DATETOCHECK}) is older than 31 days. "
# 								EchoTeeRed " ${DIFFDAYS} days old without updated orbits is abnormal. Tried to get orbits and relaunch."
# 								SpeakOut "Image ${DATETOCHECK} without updated orbit is ${DIFFDAYS} days old, that is older than 31 days. Tried to get orbits and relaunch."
# 								# Flag to relaunch Read_All_Img
# 								REPLAY=ReplayYes
# 						fi
# 				done
# 			fi
#		echo
		# Clear all processes which include images for which orbit was updated in RESAMPLED, SAR_MASSPROCESS
#			cp ${CSL}/S1OrbitUpdaterLog.txt ${CSL}/S1OrbitUpdaterLog_${RUNDATE}.txt
		if [ "${SAR_MASSPROCESS}" != "" ] || [ "${RESAMPLED}" != "" ] ; then

			if [ -f "${CSL}/S1DataReaderLog_NEWORB_${RUNDATE}.txt" ] && [ -s "${CSL}/S1DataReaderLog_NEWORB_${RUNDATE}.txt" ] ; then # still contains then ony lines such as: ---> Frame already present in image S1B_21_20200923_D.csl.
				EchoTee "List all processes to clean which include images for which orbit was updated in RESAMPLED, SAR_MASSPROCESS"
				for DATEIMGTOCLEAN in `cat ${CSL}/S1DataReaderLog_NEWORB_${RUNDATE}.txt 2>/dev/null`
					do
 						if test "$(jobs | wc -l)" -ge ${CPU}
							then
								case ${OS} in
									"Linux")
										wait -n 	;;
									"Darwin")
										waitn		;;
								esac
						fi
						# Run tests in pseudo parallelism
						{

#							DATEIMGTOCLEAN=`echo "${IMGTOCLEAN}" | cut -d _ -f3 `
							if [ "${RESAMPLED}" != "" ] ; then
	 							cd ${RESAMPLED}/S1
								EchoTee "Orbit of ${DATEIMGTOCLEAN} was updated. "
								EchoTee "List all processing involving ${DATEIMGTOCLEAN}from RESAMPLED/S1/${REGION}*"

								find ${REGION}* -name "*${DATEIMGTOCLEAN}*" -a -prune 2>/dev/null >> ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}_tmp.txt
							fi
							if [ "${SAR_MASSPROCESS}" != "" ] ; then
								cd ${SAR_MASSPROCESS}/S1
								EchoTee "List all processing involving ${DATEIMGTOCLEAN} from SAR_MASSPROCESS/S1/${REGION}*"
								find ${REGION}* -name "*${DATEIMGTOCLEAN}*" -a -prune 2>/dev/null >> ${CSL}/ORB_CleanMASSPROCESS_${RUNDATE}_tmp.txt
							fi
						} &
				done
				wait

				echo
				# add possible former list that was postponed because a run was in progress
				cat ${CSL}/ORB_CleanRESAMPLED_TODO_NEXT_TIME.txt ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}_tmp.txt 2>/dev/null | sort | uniq > ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}.txt
				cat ${CSL}/ORB_CleanMASSPROCESS_TODO_NEXT_TIME.txt ${CSL}/ORB_CleanMASSPROCESS_${RUNDATE}_tmp.txt 2>/dev/null | sort | uniq > ${CSL}/ORB_CleanMASSPROCESS_${RUNDATE}.txt

				rm -f ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}_tmp.txt ${CSL}/ORB_CleanMASSPROCESS_${RUNDATE}_tmp.txt

				# Move files - this could be deleted later I guess; in such a case you may prefer delete from the find cmd line above

#				# Check that no SuperMaster_MassProc.sh is running with a LaunchMTparam_..txt from S1. Maybe not the best test...
#				CHECKMP=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep SuperMaster_MassProc.sh" | ${PATHGNU}/grep LaunchMTparam_  | ${PATHGNU}/grep "/S1/" | wc -l`
#				if [ ${CHECKMP} -eq 0 ]
#					then
						EchoTee "Move in *_CLN all the processes in RESAMPLED and/or SAR_MASSPROCESS which include images for which orbits were updated"
						EchoTee "   Move them in ${RESAMPLED}/S1_CLN/CLEANED_ORB/"
						EchoTee "            and ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/"
						EchoTee "Note that old products in *_CLN (>180 days; see param MACLN in script) will be deleted."

				# get all modes in ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}.txt
				${PATHGNU}/gsed 's%\/.*%%' ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}.txt | sort | uniq > TRKDIR_list_${RUNDATE}_${RNDM1}.txt
				DATAPATH="$(dirname "$PARENTCSL")"  # get the parent dir, one level up

				for TRKDIR in `cat TRKDIR_list_${RUNDATE}_${RNDM1}.txt 2>/dev/null`
				do
				# If no ${PARENTCSL}_${S1MODE}_${S1TRK}/NoCrop/DoNotUpdateProducts_*_*.txt of less than 1 day (1440 min) then can remove products
				# Note that we consider that if DoNotUpdateProducts_*_*.txt are odler than 1440 min, they must be ghost file and will be ignored.
					CHECKFLAGUSAGE=`find ${DATAPATH}/${TRKDIR}/NoCrop/ -maxdepth 1 -name "DoNotUpdateProducts_*_*.txt" -type f -mmin -1440 | wc -l`
					if [ ${CHECKFLAGUSAGE} -eq 0 ]
						then
							echo # just if nothing shows up in loop
							# ok no process running since less than 1 day: can proceed to cleaning
										#for FILESTOCLEAN in `cat  ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}.txt`
										if [ "${RESAMPLED}" != "" ] ; then

											for FILESTOCLEAN in `${PATHGNU}/grep ${TRKDIR} ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}.txt`
											do
												if test "$(jobs | wc -l)" -ge ${CPU}
													then
														case ${OS} in
															"Linux")
																wait -n 	;;
															"Darwin")
																waitn		;;
														esac
												fi
												# Run tests in pseudo parallelism
												{
													PATHFILESTOCLEAN=$(dirname "${FILESTOCLEAN}")
													mkdir -p ${RESAMPLED}/S1_CLN/CLEANED_ORB/${PATHFILESTOCLEAN}
													# echo "Image ${FILESTOCLEAN} updated. Should move ${RESAMPLED}/S1/${FILESTOCLEAN} to ${RESAMPLED}/S1_CLN/CLEANED_ORB/${PARENTCSL}_${S1MODE}_${S1TRK}/"
													mv -f ${RESAMPLED}/S1/${FILESTOCLEAN} ${RESAMPLED}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN}
												} &
											done
											wait
											# because products were cleaned, one can discard the list (if any) of products to clean
											rm -f ${CSL}/ORB_CleanRESAMPLED_TODO_NEXT_TIME.txt
										fi

										#for FILESTOCLEAN in `cat  ${CSL}/ORB_CleanMASSPROCESS_${RUNDATE}.txt`
										if [ "${SAR_MASSPROCESS}" != "" ] ; then
											for FILESTOCLEAN in `${PATHGNU}/grep ${TRKDIR}  ${CSL}/ORB_CleanMASSPROCESS_${RUNDATE}.txt`
											do
												if test "$(jobs | wc -l)" -ge ${CPU}
													then
														case ${OS} in
															"Linux")
																wait -n 	;;
															"Darwin")
																waitn		;;
														esac
												fi
												# Run tests in pseudo parallelism
												{
													# if a pair MAS_SLV was already updated for the MAS and is now updated for the SLV, the MAS_SLV dir exist already. Rename it first as MAS_SLV_1st_update
													if [ -d ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN} ]
														then
															mv -f ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN} ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN}_1st_update
															mv -f ${SAR_MASSPROCESS}/S1/${FILESTOCLEAN} ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN}
														else
															PATHFILESTOCLEAN=$(dirname "${FILESTOCLEAN}")

															if [ -f "${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN}" ] && [ -s "${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN}" ]
																then
																	FILESTOCLEANEXT="${FILESTOCLEAN##*.}" # extention only
																	FILESTOCLEANNOEXT="${FILESTOCLEAN%.*}" # path and name without extention
																	mv -f ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN} ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEANNOEXT}_1st_update.${FILESTOCLEANEXT}
															fi
															mkdir -p ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${PATHFILESTOCLEAN}
															# echo "Image ${FILESTOCLEAN} updated. Should move  ${SAR_MASSPROCESS}/S1/${FILESTOCLEAN} to ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${PARENTCSL}_${S1MODE}_${S1TRK}/"
															mv -f ${SAR_MASSPROCESS}/S1/${FILESTOCLEAN} ${SAR_MASSPROCESS}/S1_CLN/CLEANED_ORB/${FILESTOCLEAN}
													fi
												} &
											done
											wait
										# because products were cleaned, one can discard the list (if any) of products to clean
										rm -f ${CSL}/ORB_CleanMASSPROCESS_TODO_NEXT_TIME.txt
									fi
						else
							# Some processes are running. Let's wait next run to clean the products.
							# Store them in ${CSL}/ORB_CleanRESAMPLED_TODO_NEXT_TIME.txt and ${CSL}/ORB_CleanMASSPROCESS_TODO_NEXT_TIME.txt
							EchoTee " A process seems to be using data from ${S1TRK}. To avoid possible clash, we postpone here the move of old products using images with outdated orbits."
							# store/add them in a file for next run
							cat ${CSL}/ORB_CleanRESAMPLED_${RUNDATE}.txt >> ${CSL}/ORB_CleanRESAMPLED_TODO_NEXT_TIME.txt
							cat ${CSL}/ORB_CleanMASSPROCESS_${RUNDATE}.txt >> ${CSL}/ORB_CleanMASSPROCESS_TODO_NEXT_TIME.txt
							# sort and uniq
							sort ${CSL}/ORB_CleanRESAMPLED_TODO_NEXT_TIME.txt | uniq > ${CSL}/ORB_CleanRESAMPLED_TODO_NEXT_TIME.clean.txt
							sort ${CSL}/ORB_CleanMASSPROCESS_TODO_NEXT_TIME.txt | uniq > ${CSL}/ORB_CleanMASSPROCESS_TODO_NEXT_TIME.clean.txt
							mv -f ${CSL}/ORB_CleanRESAMPLED_TODO_NEXT_TIME.clean.txt ${CSL}/ORB_CleanRESAMPLED_TODO_NEXT_TIME.txt
							mv -f ${CSL}/ORB_CleanMASSPROCESS_TODO_NEXT_TIME.clean.txt ${CSL}/ORB_CleanMASSPROCESS_TODO_NEXT_TIME.txt
					fi
				done
				rm -f TRKDIR_list_${RUNDATE}_${RNDM1}.txt

			else
				EchoTee " No orbits updated."
				# file is hence empty
				rm -f ${CSL}/S1DataReaderLog_NEWORB_${RUNDATE}.txt
			fi
		fi
		;;

	"TDX") 	# because TDX format change all the time, use here the bulk reader that will take care of the dir structure
			# Not sure if it will take care of images already read...

			EchoTee "It will read all the TDX images from the dir. It is your responsability to ensure that they all cover the same footprint, though Lat and Long of center of scene is provided as text file for check."

			PARENTCSL="$(dirname "$CSL")"  # get the parent dir, one level up
			REGION=`basename ${PARENTCSL}`
		
			# Check if there are any subfolders ending with ".csl"
	    	if find "${CSL}" -type d -name "*.csl" -print -quit | grep -q .; then
	    	  echo "Subfolders with '.csl' found in $CSL}"
	    	  echo "Check if the links are OK, eg. not from the wrong OS"
    		  FIRSTLINK=`find * -maxdepth 1 -type l -name "*.csl" 2>/dev/null | head -1`		# what if not link exist yet ??
	    	  TestLink ${FIRSTLINK}
	    	else
	    	  echo "No subfolders with '.csl' found in ${CSL}, this is a first image reading"
	    	fi
 	
			# Check if links in ${PARENTCSL} points toward files (must be in ${PARENTCSL}_TX/NoCrop/  or ${PARENTCSL}_RX/NoCrop/ )
			# if not, remove broken link
			EchoTee "Remove possible broken links"

			for LINKS in `ls -d */*.csl 2>/dev/null`
				do
					find -L ${LINKS} -type l ! -exec test -e {} \; -exec rm {} \; # first part stays silent if link is ok (or is not a link but a file or dir); answer the name of the link if the link is broken. Second part removes link if broken
			done

			EchoTee "Read images"
			TSXDataReader ${RAW} ${CSL}

			# TDX images may be acquired in different frames on the sam date. Unfortunately the dir are numbered with increasing nr.
			# Lets sort them out and rename
# 			for DUPLICATESIMG in `ls -d ${CSL}/*`
# 			do
# 				SUFFIX=`echo ${CSL}/${DUPLICATESIMG} | cut -d _ -f 4`
# 				if [ ${SUFFIX} != "" ] || [ ${SUFFIX} != "1" ]					  				# now in the form of _n  (_2 from example above if duplicates exists)
# 					then
# 						NAMETOSUFFIX=`echo ${CSL}/${DUPLICATESIMG}  | cut -d _ -f 1-3`
# 						if [ ! -d ${CSL}/${NAMETOSUFFIX}_1 ]
# 							then
# 								mv 	${CSL}/${DUPLICATESIMG} ${CSL}/${NAMETOSUFFIX}_1
# 							else
# 								# check that it is similar footprint than what is in _1.
# 								# Check coord of master
# 								TDXCENTERLON=`echo ${CSL}/${DUPLICATESIMG}/*.master.csl/Info/SLCImageInfo.txt  | cut -d: -f2 | ${PATHGNU}/grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tr '\n' ' ' | tr -d '[:space:]'; echo "" | xargs printf "%.*f\n" 2` # select Long as integer with sign
# 								TDXCENTERLAT=`echo ${CSL}/${DUPLICATESIMG}/*.master.csl/Info/SLCImageInfo.txt  | cut -d: -f3 | ${PATHGNU}/grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tr '\n' ' ' | tr -d '[:space:]'; echo "" | xargs printf "%.*f\n" 2` # select Lat as integer with sign
# 								# Check coord of master in _1
# 								TDXCENTERLO1=`echo ${CSL}/${NAMETOSUFFIX}_1/*.master.csl/Info/SLCImageInfo.txt  | cut -d: -f2 | ${PATHGNU}/grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tr '\n' ' ' | tr -d '[:space:]'; echo "" | xargs printf "%.*f\n" 2` # select Long as integer with sign
# 								TDXCENTERLA1=`echo ${CSL}/${NAMETOSUFFIX}_1/*.master.csl/Info/SLCImageInfo.txt  | cut -d: -f3 | ${PATHGNU}/grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tr '\n' ' ' | tr -d '[:space:]'; echo "" | xargs printf "%.*f\n" 2` # select Lat as integer with sign
# 								echo "Footprints of first image and second image are "
# 								if [ ${TDXCENTERLON} == ${TDXCENTERLO1}] && [ ${TDXCENTERLAT} == ${TDXCENTERLA1}]
# 									then
# 										mv 	${CSL}/${DUPLICATESIMG} ${CSL}/${NAMETOSUFFIX}_1
# 									else
# 										if [ ! -d ${CSL}/${NAMETOSUFFIX}_2 ]
# 											then
# 												mv ${CSL}/${DUPLICATESIMG} ${CSL}/${NAMETOSUFFIX}_2
# 											else
# 												echo "Seems that you have more than 3 images acquired on the same date ? Check or change script in line 530"
# 												exit 0
# 										fi
# 								fi
# 						fi
# 				fi
# 			done

			EchoTee ""
			EchoTee "All TDX img read; now sorting images in : "
			EchoTee "     ${PARENTCSL}_info_orbits_TX/NoCrop/ for master.csl (i.e. transmitting sat)"
			EchoTee "     or ${PARENTCSL}_info_orbits_RX/NoCrop/ for slave.csl (i.e. receiveing sat)"
			EchoTee "  and rename as date.csl "
			EchoTee ""

			rm -f Center_Of_Scene.txt

#			for TDXIMGPATH in ${CSL}/*/*.csl  # list actually the former links and the new dir if new images were read
			for TDXIMGPATH in `find ${CSL} -name "*.csl" -type d  -print`  # list actually the former links and the new dir if new images were read
				do
					if test "$(jobs | wc -l)" -ge ${CPU}
						then
							case ${OS} in
								"Linux")
									wait -n 	;;
								"Darwin")
									waitn		;;
							esac
					fi
					# Run tests in pseudo parallelism
					{

						PATHPAIRSTDX="$(dirname "$TDXIMGPATH")"	  				# get the parent dir
						PAIRSTDX=`basename ${PATHPAIRSTDX}`						# one level above parent dir
						# test if PAIRSTDX is NoCrop, which would mean this is an old format
						if [ ${PAIRSTDX} == "NoCrop" ]
							then
								# old format
								echo "old format - sort yourself the data"
								echo "Sort yourself ${TDXIMGPATH}" >> ERROR.txt
								continue
							else

								TDXIMG=`echo ${TDXIMGPATH##*/}` 						# Trick to get only name without path
								#TDXPATH=												# one level up, i.e. path to TDXIMG
								TDXDATE=`echo ${TDXIMG} | cut -d _ -f 1` 				# Get the date
								TDXSAT=`echo ${TDXIMG} | cut -d _ -f 2 | cut -d. -f1` 	# Get the sat (TSXi or TDXi)
								TDXMODE=`echo ${TDXIMG} | cut -d . -f 2` 				# Get the master or slave mode

								# if more than one image with the same date
								TDXDIRENDNAME=`echo "${PAIRSTDX}" | cut -d _ -f 2-4` 			# Get the end of dir name (eg TDM_PM). Set f at 2-4 instead of 2-3 just in case
																								# there is more than one img and hence end with _n  (eg TDM_PM_2)
								TDXDUPLICATETMP=`echo "${PAIRSTDX}" | cut -d _ -f 4` 	  		# Get the dupliation nr in case of several img on the same day  (2 from example above)

								if [ "${TDXDUPLICATETMP}" == "" ]					  				# now in the form of _n  (_2 from example above if duplicates exists)
									then
										TDXDUPLICATE=""
									else
										TDXDUPLICATE=_${TDXDUPLICATETMP}
								fi

								TDXBIS=`echo ${TDXDIRENDNAME} | cut -d_ -f 2` # Get Bistatic (BS) or Poursuite Mode (PM)

								TDXSCENEID=`updateParameterFile ${TDXIMGPATH}/Info/SLCImageInfo.txt "Scene ID"`
								TDXSCENELOC=`updateParameterFile ${TDXIMGPATH}/Info/SLCImageInfo.txt "Scene location"`
								TDXORBMODE=`echo ${TDXSCENEID} | cut -d_ -f3` 	# A or D
								echo "Scene ID is: ${TDXSCENEID}"
								TDXORBNR=`echo "${TDXSCENEID}" | ${PATHGNU}/grep -Eo "_[0-9]{3}_" ` # select _ORBnr_, that is the only number of 3 digits framed by _ in the scene ID

								TDXBW=`updateParameterFile ${TDXIMGPATH}/Info/SLCImageInfo.txt "Range bandwidth" ` # band width in Hz
								TDXBWMHZ=`echo "(${TDXBW} /1000000)" | bc  ` # band width in Mhz

								TDXCENTERLON=`echo ${TDXSCENELOC} | cut -d: -f2 | ${PATHGNU}/grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tr '\n' ' ' | tr -d '[:space:]'; echo "" ` # select Long as integer with sign
								TDXCENTERLAT=`echo ${TDXSCENELOC} | cut -d: -f3 | ${PATHGNU}/grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tr '\n' ' ' | tr -d '[:space:]'; echo "" ` # select Lat as integer with sign

								if [ ${TDXMODE} == "master" ] ; then TDXCODE=TX ; else TDXCODE=RX ; fi

								TDXDIR=${PARENTCSL}_${TDXBWMHZ}Mhz_${TDXBIS}_${TDXORBMODE}${TDXORBNR}${TDXCODE}${TDXDUPLICATE}/NoCrop

								if [ ! -d ${TDXDIR}/${TDXIMG} ]
									then
										echo "Center of ${TDXDATE}_${TDXORBMODE}${TDXORBNR}${TDXBWMHZ}Mhz_${TDXBIS}${TDXDUPLICATE} Scene  Lat: ${TDXCENTERLAT}  Long: ${TDXCENTERLON}" >> Center_Of_Scene.txt
										mkdir -p ${TDXDIR}

										# There is no  ${PARENTCSL}_${TDXORBMODE}_${TDXORBNR}_Lat${TDXCENTERLAT}_Long${TDXCENTERLON}_${TDXCODE}/NoCrop/${TDXIMG} DIR yet, hence it is a new img; move new img there
										mv ${TDXIMGPATH} ${TDXDIR}/${TDXDATE}.csl
										#and create a link
										ln -s ${TDXDIR}/${TDXDATE}.csl ${CSL}/${TDXDATE}_${TDXDIRENDNAME}/${TDXDATE}_${TDXSAT}.${TDXMODE}.csl
										echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${TDXDIR}/${TDXDATE}.csl/Read_w_AMSTerEngine_V.txt
								fi
						fi	# test old or recent format
					} &
			done
			wait
			echo

		;;
	"ICEYE")
		# Use the bulk reader
		PARENTCSL="$(dirname "$CSL")"  # get the parent dir, one level up
		REGION=`basename ${PARENTCSL}`
		
		# Check if there are any subfolders ending with ".csl"
	    if find "${CSL}" -type d -name "*.csl" -print -quit | grep -q .; then
	      echo "Subfolders with '.csl' found in ${CSL}"
	      echo "Check if the links are OK, eg. not from the wrong OS"
	      FIRSTLINK=`find * -maxdepth 1 -type l -name "*.csl" 2>/dev/null | head -1`		# what if not link exist yet ??
        TestLink ${FIRSTLINK}
	    else
	      echo "No subfolders with '.csl' found in ${CSL}, this is a first image reading"
	    fi
  
		# Check if links in ${PARENTCSL} points toward files (must be in ${PARENTCSL}_${ICYMODE}_${ICYTRK}_${ICYINCID}deg/NoCrop/)
		# if not, remove broken link
		EchoTee "Remove possible broken links"
		for LINKS in `ls -d *.csl 2>/dev/null`
			do
				find -L ${LINKS} -type l ! -exec test -e {} \; -exec rm {} \; # first part stays silent if link is ok (or is not a link but a file or dir); answer the name of the link if the link is broken. Second part removes link if broken 
		done
			
		if [ "${FAY}" == "ForceAllYears" ]
			then 
				EchoTeeYellow "Read all images in ${RAW}"
				ICEYEDataReader ${RAW} ${CSL} -r
			else 
				EchoTeeYellow "Read only new images in ${RAW} not yet in ${PARENTCSL}"
				ICEYEDataReader ${RAW} ${CSL} 
		fi
		EchoTee ""
		EchoTee "All ICEYE img read; now sorting them by mode, track and incidence "
		EchoTee ""
		cd ${CSL}
		for ICYIMGPATH in `find ${CSL} -name "*.csl" -print`  # list actually the former links and the new dir if new images were read
			do
				ICYIMG=`echo ${ICYIMGPATH##*/}` 				# Trick to get only name without path
				ICYDATE=`updateParameterFile ${ICYIMGPATH}/Info/SLCImageInfo.txt "Acquisition date"` 					# Get date
				ICYMODE=`updateParameterFile ${ICYIMGPATH}/Info/SLCImageInfo.txt "Heading direction" | cut -c 1` 		# Get the orbit mode (Asc or Des)
				ICYTYPE=`updateParameterFile ${ICYIMGPATH}/Info/SLCImageInfo.txt "Product ID"` 						# Stripmap or SpotlightHigh
				ICYLOOK=`updateParameterFile ${ICYIMGPATH}/Info/SLCImageInfo.txt "Look direction" | cut -c 1` 		# L(eft) or R(ight)
				ICYINCID=`updateParameterFile ${ICYIMGPATH}/Info/SLCImageInfo.txt "Incidence angle at median slant range" | $PATHGNU/gawk '{print int($1+0.5)}' ` 		# incidence angle (rounded)
				ICYTRK=${ICYTYPE}_${ICYLOOK}L
				mkdir -p ${PARENTCSL}_${ICYMODE}_${ICYTRK}_${ICYINCID}deg/NoCrop
				if [ ! -d ${PARENTCSL}_${ICYMODE}_${ICYTRK}_${ICYINCID}deg/NoCrop/${ICYDATE}.csl ]
					then
						# There is no  ${PARENTCSL}_${ICYMODE}_${ICYTRK}_${ICYINCID}deg/NoCrop/${ICYDATE}.csl DIR yet, hence it is a new img; move new img there
							mv ${ICYIMG} ${PARENTCSL}_${ICYMODE}_${ICYTRK}_${ICYINCID}deg/NoCrop/${ICYDATE}.csl 
							#and create a link
							ln -s ${PARENTCSL}_${ICYMODE}_${ICYTRK}_${ICYINCID}deg/NoCrop/${ICYDATE}.csl ${CSL}/${ICYIMG} 
							echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${PARENTCSL}_${ICYMODE}_${ICYTRK}_${ICYINCID}deg/NoCrop/${ICYDATE}.csl/Read_w_AMSTerEngine_V.txt
				fi  
		done
		echo 		
		;; 		
	*) 	# Do not use Bulk Reader; compare instead with existing images and read only the new ones
		# Read existing raw archives
		# BEWARE, ${RAW} can't end with a /
		#ls ${RAW}* | ${PATHGNU}/grep -v ".txt" | ${PATHGNU}/grep -v ".png" | ${PATHGNU}/grep -v ".tmp" | ${PATHGNU}/grep -v ".dat"  | ${PATHGNU}/grep -v ".gz" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".zip" | ${PATHGNU}/grep -v ".kml" | ${PATHGNU}/grep -v ".Z" > List_raw.txt

		if [ "${SAT}" == "CSK" ]
			then 
				# cna have several images acquired on the same day
				rm -f List_raw.txt
				for RAWIMGDIR in `find "${RAW}" -maxdepth 1 -mindepth 1 -type d | xargs -I {} basename {}` ; do
				    # Count the number of .h5 files in the subdirectory
				    NRIMG=$(find "${RAW}/${RAWIMGDIR}" -maxdepth 1 -type f -name "*.h5" | wc -l)
					# list as many times the date in List_raw.txt as there are h5 files in dir 
				    
				    for i in $(seq 1 ${NRIMG})	
				    	do
				        echo "${RAWIMGDIR}" >> List_raw.txt  # List the subdirectory once
					done
				done
			else 
				find "${RAW}" -maxdepth 1 -mindepth 1 -type d | xargs -I {} basename {} > List_raw_tmp.txt	#  | xargs -I {} basename {}  removes path
				cat List_raw_tmp.txt | ${PATHGNU}/grep -v "\.txt" | ${PATHGNU}/grep -v "\.tmp" | ${PATHGNU}/grep -v "\.gz" | ${PATHGNU}/grep -v "\.zip" | ${PATHGNU}/grep -v "\.Z" > List_raw.txt
				rm -f List_raw_tmp.txt 
		fi

		# List images already in read csl format
		rm -f List_csl.txt
		case ${SAT} in
			"ENVISAT") 
				# Need the dir and date for comparison, i.e. list CSL dir names as in RAW instead of date 
				ls ${CSL} | ${PATHGNU}/grep -v ".txt" > List_csl_dates.txt
				for DATECSL in `cat -s List_csl_dates.txt`
					do	
						DATE=`echo ${DATECSL} | cut -d . -f 1`
						# ls -R ${RAW} *.N1  2>/dev/null | ${PATHGNU}/grep ${DATE} | cut -d _ -f7 >> List_csl.txt # Now List_csl.txt contains orbits names as dirs in CSL 
						ls -R ${RAW} | ${PATHGNU}/grep ".N1" | ${PATHGNU}/grep ${DATE} | cut -d _ -f7 >> List_csl.txt # Now List_csl.txt contains orbits names as dirs in CSL 
					done
					;;
			"ERS") 
				# Need the dir and date for comparison, i.e. list CSL dir names as in RAW instead of date 
				ls ${CSL} | ${PATHGNU}/grep -v ".txt" > List_csl_dates.txt
				for DATECSL in `cat -s List_csl_dates.txt`
					do	
						DATE=`echo ${DATECSL} | cut -d . -f 1`
						echo "// Searching for dates in LEA files for ${DATE}... May take time..."
						PATHTOFILE=`${PATHGNU}/grep -rl "${DATE}" ${RAW} | ${PATHGNU}/grep -i "LEA"`
						DIRNAMERAW=$(basename $(dirname $(dirname ${PATHTOFILE})))
						echo "${DIRNAMERAW}" >> List_csl.txt # Now List_csl.txt contains orbits names as dirs in CSL 
					done
					;;
			"ALOS") 
				# Need the dir and date for comparison, i.e. list CSL dir names as in RAW instead of date 
				ls ${CSL} | ${PATHGNU}/grep -v ".txt" > List_csl_dates.txt
				for DATECSL in `cat -s List_csl_dates.txt`
					do	
						DATE=`echo ${DATECSL} | cut -d . -f 1`
						echo "// Searching for dates in workreport files for ${DATE}... May take time..."
						PATHTOFILE=`${PATHGNU}/grep -rl "${DATE}" ${RAW} | ${PATHGNU}/grep "workreport"`
						#DIRNAMERAW=$(basename $(dirname $(dirname ${PATHTOFILE})))
						DIRNAMERAW=$(basename $(dirname ${PATHTOFILE}))
						echo "${DIRNAMERAW}" >> List_csl.txt # Now List_csl.txt contains orbits names as dirs in CSL 
					done
					;;

		"RS1"|"RADARSAT1") 
				# Need the dir and date for comparison, i.e. list CSL dir names as in RAW instead of date 
				ls ${CSL} | ${PATHGNU}/grep -v ".txt" > List_csl_dates.txt
				for DATECSL in `cat -s List_csl_dates.txt`
					do	
						DATE=`echo ${DATECSL} | cut -d . -f 1`
						echo "// Searching for dates in LEA files for ${DATE}... May take time..."
						PATHTOFILE=`${PATHGNU}/grep -rl "${DATE}" ${RAW} | ${PATHGNU}/grep -i "LEA"`
						DIRNAMERAW=$(basename $(dirname ${PATHTOFILE}))		# One level less than ERS because no SCENE1 dir
						echo "${DIRNAMERAW}" >> List_csl.txt # Now List_csl.txt contains orbits names as dirs in CSL 
					done
					;;
#		"SAOCOM") 
#				# Need the bulkreader because frames changes all the time ; bulkreader compares the image with area of interest provided as a kml 
#				# It also check the date of ficusing. If image was already read but it is a new focus, like update of S1 orbit, it logs the Info
#				#  so that the former processing of coregistration and mass processing can be updated. 
#
#					;;
			*) 	
				#ls ${CSL}/* | ${PATHGNU}/grep -v ".txt" > List_csl.txt
				ls ${CSL} | ${PATHGNU}/grep -v ".txt" > List_csl.txt
				;;
		esac

		# Search for only the new ones to be processed:
		#    In List_csl.txt names are date.csl, 
		#    while in List_raw.txt names are a complex dir name that includes date somewhere
		cp -f List_raw.txt Img_To_Read.txt
		rm -f Multi_Img_To_Ignore_tmp.txt
		if [ -f "List_csl.txt" ] && [ -s "List_csl.txt" ] ; then 
			for LINE in `cat -s List_csl.txt`
				do	
					if [ "${SAT}" == "ALOS2" ]
						then 
							DATE=`echo ${LINE} | cut -d . -f1 | cut -c 3-8`
						else 
							if [ "${SAT}" == "CSK" ]
								then 
									DATE=`echo ${LINE} | cut -d . -f1 | cut -c 1-8` # in case multiple CSK images acquired on the same day and labelled yyyymmdd_i.csl
								else 
									DATE=`echo ${LINE} | cut -d . -f1 ` 
							fi
					fi
					TSTINDEX=`${PATHGNU}/grep ${DATE} Img_To_Read.txt | wc -l`
					if [ ${TSTINDEX} -eq 1 ]
						then 
							${PATHGNU}/grep -v ${DATE} Img_To_Read.txt > Img_To_Read_tmp.txt
							cp -f Img_To_Read_tmp.txt Img_To_Read.txt
						else 
							if [ "${SAT}" == "CSK" ]
								then 
									# may have multiple images acquired on the same day
									# If nr of read image in csl is the same as in raw, one can suppose images are already read. 
									# If that nr is not the same, delete what is already read in CSL and read again 
									NROFRAWIMG=`${PATHGNU}/grep ${DATE} List_Raw.txt | wc -l`
									if [ "${NROFRAWIMG}" == "${TSTINDEX}" ] 
										then 
											# Store image in list to ignore 
											echo "${DATE}" >> Multi_Img_To_Ignore_tmp.txt
											#ok, seems to be read as much as there are h5 files; remove that date from list to read
											${PATHGNU}/grep -v ${DATE} Img_To_Read.txt > Img_To_Read_tmp.txt
											cp -f Img_To_Read_tmp.txt Img_To_Read.txt
										else 
											# ignore if DATE is in Multi_Img_To_Ignore_tmp.txt
											if ! grep -q "${DATE}" Multi_Img_To_Ignore_tmp.txt ; then
												# it seems that the image is either not read yet (TSTINDEX=0) or some images are not read (TSTINDEX=2). 
												# In that last case, remove partial existing and read again. Hence in both case, do not grep -v the date from the list to read
												if [ "${TSTINDEX}" != "0" ]
													then 
														rm -Rf ${CSL}/${DATE}* 2> /dev/null
														rm -Rf ${CSL}_Asc/${DATE}* 2> /dev/null
														rm -Rf ${CSL}_Desc/${DATE}* 2> /dev/null
												fi
											fi
									fi
									
								else 
									${PATHGNU}/grep -vx ${DATE} Img_To_Read.txt > Img_To_Read_tmp.txt		# If a date appears more than one time in a file name, it means that it was probably prepared by Prepa_TSX.sh
									cp -f Img_To_Read_tmp.txt Img_To_Read.txt								# hence one  can reject the line that fits exactly the date(_index)  
							fi
					fi

				done
			# now one can sort and uniq the list of images to read 
			sort Img_To_Read.txt | uniq > Img_To_Read_tmp.txt
			cp -f Img_To_Read_tmp.txt Img_To_Read.txt

			rm -f Img_To_Read_tmp.txt Multi_Img_To_Ignore_tmp.txt

		fi 
		
		EchoTee ""
		EchoTee "Reading..."
		for IMGDIR in `cat -s Img_To_Read.txt`
		do	
			if test "$(jobs | wc -l)" -ge ${CPU} 
				then
					case ${OS} in 
						"Linux") 
							wait -n 	;;
						"Darwin")
							waitn		;;
					esac	
			fi
			# Run tests in pseudo parallelism
			{
				case ${SAT} in
					"RADARSAT") 
								IMG=`GetDate ${IMGDIR}`
								RSAT2DAtaReader ${CSL}/Read_${IMG}.txt -create
								ChangeInPlace PathToRSAT2Directory "${RAW}/${IMGDIR}" ${CSL}/Read_${IMG}.txt
								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
								RSAT2DAtaReader ${CSL}/Read_${IMG}.txt	
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
								EchoTee "Image ${IMG} red"
								;;
					"RADARSAT1"|"RS1") 
								# RS1 format is CEOS, similar to ERS. It can hence be read with the same reader. 
								# Remember that orbits are not read though, hence you can only work in slant range. 
								IMG=`GetDateRS1 ${RAW}/${IMGDIR}`
								ERSDataReader ${CSL}/Read_${IMG}.txt -create
								#EchoTee "${RAW}/${IMGDIR}/*.N1"
								ChangeInPlace PathToDirectory ${RAW}/${IMGDIR} ${CSL}/Read_${IMG}.txt
								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
								#ChangeInPlace DORIS_DirectoryPath ${ENVORB} ${CSL}/Read_${IMG}.txt
								ERSDataReader ${CSL}/Read_${IMG}.txt
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
								EchoTee "Image ${IMG} red"
								;;
	
					"CSK") 
								IMG=`GetDateOnly ${IMGDIR}`
								NRCSK=`ls ${RAW}/${IMGDIR}/*.h5 | wc -l |  ${PATHGNU}/gsed 's/[^0-9]*//g'`
								
								EchoTee "WARNING: there are -${NRCSK}- csk images acquired on ${IMG}; Processing them with additional index in SAR_CSL/ dir naming. " 
								i=0

								if [ "${NRCSK}" != "1" ]
									then 
										for IMGH5 in `ls ${RAW}/${IMGDIR}/*.h5`	# with path 
											do 
												i=`echo "${i} + 1" | bc -l`
												CSKDataReader ${CSL}/Read_${IMG}_${i}.txt -create
												ChangeInPlace PathToHDF5File ${IMGH5}  ${CSL}/Read_${IMG}_${i}.txt
												ChangeInPlace outputFilePath ${CSL}/${IMG}_${i} ${CSL}/Read_${IMG}_${i}.txt
												CSKDataReader ${CSL}/Read_${IMG}_${i}.txt
												TRKHEADING=`updateParameterFile ${CSL}/${IMG}_${i}.csl/Info/SLCImageInfo.txt Heading | cut -d c -f1`
												TRKHEADING=${TRKHEADING}c
												SCENELOCATION=`updateParameterFile ${CSL}/${IMG}_${i}.csl/Info/SLCImageInfo.txt "Scene location"`
												echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
												EchoTee " Track of ${IMG}_${i} : ${TRKHEADING}" 
												EchoTee "Image ${IMG}_${i} red"
												EchoTee "Image ${IMG}_${i} : ${TRKHEADING}  : ${SCENELOCATION}" >> List_Files_Trk_Location_${RUNDATE}.txt
											done
									else 
										CSKDataReader ${CSL}/Read_${IMG}.txt -create
										ChangeInPlace PathToHDF5File ${RAW}/${IMGDIR}/*.h5  ${CSL}/Read_${IMG}.txt
										ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
										CSKDataReader ${CSL}/Read_${IMG}.txt
										TRKHEADING=`updateParameterFile ${CSL}/${IMG}.csl/Info/SLCImageInfo.txt Heading | cut -d c -f1`
										TRKHEADING=${TRKHEADING}c
										SCENELOCATION=`updateParameterFile ${CSL}/${IMG}.csl/Info/SLCImageInfo.txt "Scene location"`
										echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
										EchoTee " Track of ${IMG} : ${TRKHEADING}" 
										EchoTee "Image ${IMG} red"
										EchoTee "Image ${IMG} : ${TRKHEADING}  : ${SCENELOCATION}" >> List_Files_Trk_Location_${RUNDATE}.txt
								fi
								;;

					"K5"|"KOMPSAT") 
								IMG=`GetDateK5 ${IMGDIR}`
								CSKDataReader ${CSL}/Read_${IMG}.txt -create
								ChangeInPlace PathToHDF5File ${RAW}/${IMGDIR}/*.h5  ${CSL}/Read_${IMG}.txt
								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
								CSKDataReader ${CSL}/Read_${IMG}.txt
								TRKHEADING=`updateParameterFile ${CSL}/${IMG}.csl/Info/SLCImageInfo.txt Heading | cut -d c -f1`
								TRKHEADING=${TRKHEADING}c
								SCENELOCATION=`updateParameterFile ${CSL}/${IMG}.csl/Info/SLCImageInfo.txt "Scene location"`
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
								EchoTee " Track of ${IMG} : ${TRKHEADING}" 
								EchoTee "Image ${IMG} red"
								EchoTee "Image ${IMG} : ${TRKHEADING}  : ${SCENELOCATION}" >> List_Files_Trk_Location_${RUNDATE}.txt
								;;


					"TSX") 
								# Date is taken from the raw dir name - Prepa_TSX.sh is required to get the original name 
								if echo "${IMGDIR}" | grep -Eq "^[0-9]{8}$"	# if IMGDIR contains 8 digits 
									then
								    	EchoTee "The directory name is a 8 digits format, i.e. the date (probably prepared with Prepa_TSX.sh)"
								    	IMG=`GetDateOnly ${IMGDIR}`
								elif echo "${IMGDIR}" | grep -Eq "^[0-9]{8}_[0-9]+$"	# if IMGDIR contains 8 digits and a "_" and again digits,
						    		then 
						    			EchoTee "The directory name is a 8 digits format and an index (probably prepared with Prepa_TSX.sh and with several images with different footprints for the same date)"
						    			IMG=`GetDateOnly ${IMGDIR}`
					    		else
								    	EchoTee "The directory name seems to be the original name. Beware not to have several images acquired the same day in ${RAW} because it would read only one"
								   	 	IMG=`GetSARL1BDate ${IMGDIR}`
								fi

								EchoTee ""
							
								if
									test -d ${RAW}/${IMGDIR}/TSX-1.SAR.L1B
									then 
										TSXDIR=`cd ${RAW}/${IMGDIR}/TSX-1.SAR.L1B/; ls -d $PWD/T*/`	
										TSXDIR=`echo ${TSXDIR} | ${PATHGNU}/gsed -e 's/\/$//g'`    # need to remove ending slash
											 # Actual path to the data. 
											 # NB: This assumes there is only one subdir that starts with T in the Terrasar data dir
									else 
										if [ -d "${RAW}/${IMGDIR}/ANNOTATION" ] 
											then 
												# Seems that one dir level is missing. 
												TSXSUDIREXPECTEDNAME=`ls ${RAW}/${IMGDIR}/*.xml | head -1 | cut -d . -f 1`
												TSXXMLEXPECTEDNAME=`ls ${RAW}/${IMGDIR}/*.xml | head -1`
												if [ -f "${TSXXMLEXPECTEDNAME}" ] 
													then 
														# try to add that level
														mkdir -p "${TSXSUDIREXPECTEDNAME}"
														mv ${RAW}/${IMGDIR}/ANNOTATION ${TSXSUDIREXPECTEDNAME}/
														mv ${RAW}/${IMGDIR}/AUXRASTER ${TSXSUDIREXPECTEDNAME}/
														mv ${RAW}/${IMGDIR}/IMAGEDATA ${TSXSUDIREXPECTEDNAME}/
														mv ${RAW}/${IMGDIR}/PREVIEW ${TSXSUDIREXPECTEDNAME}/
														mv ${RAW}/${IMGDIR}/SUPPORT ${TSXSUDIREXPECTEDNAME}/
														mv ${TSXXMLEXPECTEDNAME} ${TSXSUDIREXPECTEDNAME}/
														
													else 
														echo "Can't figure out your format. I do expect something like : ${RAW}/${IMGDIR}/TSX1_SAR__blabla_SRA_yyyymmddThhmmss_yyyymmddThhmmss/ANNOTATION and more directories in there"
														exit
												fi
										fi
										TSXDIR=`cd ${RAW}/${IMGDIR}/; ls -d $PWD/T*/`	
										TSXDIR=`echo ${TSXDIR} | ${PATHGNU}/gsed -e 's/\/$//g'`    # need to remove ending slash
										# Actual path to the data. 
										# NB: This assumes there is only one subdir that starts with T in the Terrasar data dir


								fi
								
								# Check that image is not read yet
								if [ ! -d ${CSL}/${IMG}.csl ]
									then 
										TSXDataReader ${CSL}/Read_${IMG}.txt -create
										ChangeInPlace PathToTSXDir ${TSXDIR} ${CSL}/Read_${IMG}.txt
										ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
										TSXDataReader ${CSL}/Read_${IMG}.txt
										echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
										EchoTee "Image ${IMG} red"
									else 
										if echo "${IMGDIR}" | grep -Eq "^[0-9]{8}_[0-9]+$"	# if IMGDIR contains 8 digits and a "_" and again digits,
											then 
												# then it was probably prepared with Prapa_TSX.sh and hence is another footprint. In that case, read it and save it with same index
												if [ ! -d ${CSL}/${IMGDIR}.csl ]
													then 
														TSXDataReader ${CSL}/Read_${IMGDIR}.txt -create
														ChangeInPlace PathToTSXDir ${TSXDIR} ${CSL}/Read_${IMGDIR}.txt
														ChangeInPlace outputFilePath ${CSL}/${IMGDIR} ${CSL}/Read_${IMGDIR}.txt
														TSXDataReader ${CSL}/Read_${IMGDIR}.txt
														echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMGDIR}.csl/Read_w_AMSTerEngine_V.txt
														EchoTee "Image ${IMGDIR} red"
														EchoTee " BEWARE: this image seems to be of the same date as another one and hence is probably another footprint."
														EchoTee " 		  You can check e.g. by running _Check_CSL_Corners_Trk_etc.sh in the directory that contains you images.csl"
														EchoTee " 		  It is your responsability to store them by footprints in different directories for a proper mass porcessing."
														EchoTee ""
													else 
														EchoTee "Image ${IMGDIR} was already in ${CSL} ; skip "
												fi											
											else 
												EchoTee "Image ${IMG} was already in ${CSL} ; skip "
										fi
										
								fi
								;;
# 					"TSXfromTDX") 
# 								IMG=`GetDate ${IMGDIR}`
# 								if
# 									test -d ${RAW}/${IMGDIR}/TSX-1.SAR.L1B
# 									then 
# 										ls -d ${RAW}/${IMGDIR}/TSX-1.SAR.L1B/T*/ > tmp.txt	
# 									else 
# 										ls -d ${RAW}/${IMGDIR}/T*/ > tmp.txt	
# 								fi
# 								TSXDIR_BTX=`grep BTX tmp.txt | ${PATHGNU}/gsed -e 's/\/$//g'`    # need to remove ending slash
# 						
# 								# Read first (Transmit) image
# 								TSXDataReader ${CSL}/Read_${IMG}_BTX.txt -create
# 								ChangeInPlace "NO        " "YES      " ${CSL}/Read_${IMG}_BTX.txt
# 								ChangeInPlace PathToTSXDir ${TSXDIR_BTX} ${CSL}/Read_${IMG}_BTX.txt
# 								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}_BTX.txt
# 								# if 
# 		# 							test ! -d ${CSL}/BTX/
# 		# 							then 
# 		# 								mkdir ${CSL}/BTX/
# 		# 						fi
# 								TSXDataReader ${CSL}/Read_${IMG}_BTX.txt
# 								EchoTee "Frist Image ${IMG}_BTX red"
# 								;;
					"PAZ") 
								# PAZ is TSX-like. It can hence be read with the TSX reader; date is taken from the raw dir name as ...yyyymmddT... 
								IMG=`GetDateYyyyMmDdT ${IMGDIR}`
								TSXDataReader ${CSL}/Read_${IMG}.txt -create
								ChangeInPlace PathToTSXDir ${RAW}/${IMGDIR} ${CSL}/Read_${IMG}.txt
								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
								TSXDataReader ${CSL}/Read_${IMG}.txt
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
								EchoTee "Image ${IMG} red"
								;;
					"ENVISAT") 
								# ENVISAT date is read from N1 file
								IMG=`GetDateEnvisat ${RAW}/${IMGDIR}`
								EnviSATDataReader ${CSL}/Read_${IMG}.txt -create
								EchoTee "${RAW}/${IMGDIR}/*.N1"
								ChangeInPlace PathToEnviSATDataFile ${RAW}/${IMGDIR}/*.N1 ${CSL}/Read_${IMG}.txt
								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
								ChangeInPlace DORIS_DirectoryPath ${ENVORB} ${CSL}/Read_${IMG}.txt
								EnviSATDataReader ${CSL}/Read_${IMG}.txt
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
								EchoTee "Image ${IMG} red"
								;;
					"ERS") 
								# ERS date is read from LEA file
								IMG=`GetDateERS ${IMGDIR}`
								ERSDataReader ${CSL}/Read_${IMG}.txt -create
								#EchoTee "${RAW}/${IMGDIR}/*.N1"
								ChangeInPlace PathToDirectory ${RAW}/${IMGDIR}/SCENE1 ${CSL}/Read_${IMG}.txt
								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
								#ChangeInPlace DORIS_DirectoryPath ${ENVORB} ${CSL}/Read_${IMG}.txt
								ERSDataReader ${CSL}/Read_${IMG}.txt
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
								EchoTee "Image ${IMG} red"
								;;

					"ALOS") 
								# ALOS: date is supposed to be in the file workreport 
								IMG=`GetDateALOS ${RAW}/${IMGDIR}`
								ALOSDataReader ${CSL}/Read_${IMG}.txt -create
								#PATHTOINPUTDIR=`ls -d ${RAW}/${IMGDIR}/PSR*`
								ChangeInPlace PathToDirectory ${RAW}/${IMGDIR} ${CSL}/Read_${IMG}.txt
								VOLALPSR=`basename ${RAW}/${IMGDIR}/VOL-AL*`
								ChangeInPlace "VOL-ALPSR..." ${VOLALPSR} ${CSL}/Read_${IMG}.txt
								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
								ALOSDataReader ${CSL}/Read_${IMG}.txt
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
								EchoTee "Image ${IMG} red"
								;;
								
					"ALOS2") 
								# ALOS2 and ALOS2 SM : date is supposed to be the last 6 digits of the raw dir name : yymmdd
								IMG=`GetDateALOS2 ${RAW}/${IMGDIR}`
								ALOSDataReader ${CSL}/Read_${IMG}.txt -create
								ChangeInPlace PathToDirectory ${RAW}/${IMGDIR}  ${CSL}/Read_${IMG}.txt
								VOLALPSR=`basename ${RAW}/${IMGDIR}/VOL-ALOS*`
								ChangeInPlace "VOL-ALPSR..." ${VOLALPSR} ${CSL}/Read_${IMG}.txt
								ChangeInPlace outputFilePath ${CSL}/${IMG} ${CSL}/Read_${IMG}.txt
								ALOSDataReader ${CSL}/Read_${IMG}.txt
								echo "Last created AMSTer Engine source dir suggest reading with ME version: ${LASTVERSIONMT}" > ${CSL}/${IMG}.csl/Read_w_AMSTerEngine_V.txt
								EchoTee "Image ${IMG} red"
								;;
					#"S1") 		EchoTee "Using here the native bulk reader for S1"
					#			;;	

# Use the Bulk reader !  					
#  					"SAOCOM") 
#  							#	IMG=`GetDate ${IMGDIR}`
#  								# get IMGDIR
#  							#	IMGDIR must be name from `find ${RAW} -maxdepth 1 -mindepth 1 -type d -printf "%f\n"` 
# 
# 								touch ${CSL}/Pedigree.txt # A file to remember where the image comes from...
#  								echo "Raw dir name:				${IMGDIR}" >> ${CSL}/Pedigree.txt
#  								# search .xemt fil in dir 
#  								XEMTFILE=$(basename ${RAW}/${IMGDIR}/*.xemt)
#   								echo "xemt file and dir name:		${XEMTFILE}" >> ${CSL}/Pedigree.txt
#   								FOCUSDATE=$(echo ${XEMTFILE} | ${PATHGNU}/grep -Eo "[0-9]{8}T[0-9]{6}")
#   								echo "Focus date: 				${FOCUSDATE}" >> ${CSL}/Pedigree.txt
#  								# Read the start time from the xemt file and output it in the form of yyyymmdd
#  								IMGDATE=$(${PATHGNU}/gawk -F'[-T]' '/<startTime>/{gsub(/[:.]/,"",$6); print $2$3$4; exit}' ${RAW}/${IMGDIR}/${XEMTFILE} | cut -d ">" -f 2)
#   								echo "Acquisition date: 			${IMGDATE}" >> ${CSL}/Pedigree.txt
#  								# name of dir where data are expected; also name of possile zip file if not unzip yet
#  								XEMTNAME=$(echo "${XEMTFILE}" | ${PATHGNU}/gsed s"/.xemt//")
#  								# if not unzipped yet, do it here
#  								if [ -f "${RAW}/${IMGDIR}/${XEMTNAME}.zip" ]
#  									then 
#  										ZIPFILE=${RAW}/${IMGDIR}/${XEMTNAME}.zip
#  										unzip ${ZIPFILE} -d "${ZIPFILE%.*}" && rm -f ${ZIPFILE}	# unzip in place and remove zip file; now data are in ${RAW}/${IMGDIR}/${XEMTNAME}
#   								fi
#  								# Read the data and store in general target dir in a subdir named TMP because date is unknown
#  								mkdir -p ${CSL}/TMP
#  								SAOCOMDataReader ${RAW}/${IMGDIR} ${CSL}/TMP ${KMLS1} P=${INITPOL}
#  								# Now image is read in ${CSL}/TMP/SAO1AorB_DATE_ORB_FRAME_AorD.csl, e.g. PATH_1650/SAR_CSL/SAOCOM/LagunaFea/NoCrop/TMP/SAO1A_20230401_042_389_A.csl
#  								CSLFULLNAME=$(basename ${CSL}/TMP/*.csl)
#   								echo "Image full name: 	  ${CSLFULLNAME}" >> ${CSL}/Pedigree.txt
#  								# Get the Orbit and Frame 
#  								SAOCOMORBIT=`echo ${CSLFULLNAME} | cut -d _ -f 3 ` # Get the orbit nr
#  								SAOCOMORBITDIR=`echo ${CSLFULLNAME} | cut -d _ -f 5 | cut -d . -f 1 ` # Get the orbit nr
#  				 				SAOCOMOFRAME=`echo ${CSLFULLNAME} | cut -d _ -f 4 ` # Get the frame nr
#   								echo "Orbit: 		${SAOCOMORBIT}" >> ${CSL}/Pedigree.txt
#   								echo "Direction: 	${SAOCOMORBITDIR}" >> ${CSL}/Pedigree.txt
#   								echo "Frame: 		${SAOCOMOFRAME}" >> ${CSL}/Pedigree.txt
#  				 				
# 								# Move image in CSL format in final dir and keep link in general dir 
# 								PARENTCSL="$(dirname "$CSL")"  # get the parent dir, one level up
# 								mkdir -p ${PARENTCSL}_${SAOCOMORBITDIR}_${SAOCOMORBIT}_${SAOCOMOFRAME}/NoCrop
# 								
# 								mv ${CSL}/TMP/${CSLFULLNAME} ${PARENTCSL}_${SAOCOMORBITDIR}_${SAOCOMORBIT}_${SAOCOMOFRAME}/NoCrop/${IMGDATE}.csl
#  								# keep travck of name of original dir
#  								mv ${CSL}/Pedigree.txt ${PARENTCSL}_${SAOCOMORBITDIR}_${SAOCOMORBIT}_${SAOCOMOFRAME}/NoCrop/${IMGDATE}.csl/Pedigree.txt
# # 								touch ${PARENTCSL}_${SAOCOMORBITDIR}_${SAOCOMORBIT}_${SAOCOMOFRAME}/${IMGDATE}.csl/${CSLFULLNAME}.txt
#  								
#  								# create a link back in read dir 
#  								ln -s ${PARENTCSL}_${SAOCOMORBITDIR}_${SAOCOMORBIT}_${SAOCOMOFRAME}/NoCrop/${IMGDATE}.csl ${CSL}/${CSLFULLNAME}
# #  								;;								
					*) 
								EchoTee "No satellite provided or unrecognozed name... Exiting."
								exit 
								;;

				esac	
			} &
		done 
		wait 
		;;
esac
#fi

if [ "${REPLAY}" == "ReplayYes" ] 
	then 
		EchoTeeRed "Seems that you encountered problems with missing orbits. Try to relaunch current script"
		# First one need to neutralize the replay possibility to avoid infinite loop
		${PATHGNU}/gsed "s/REPLAY=ReplayYes/REPLAY=ReplayNo/" $(dirname $0)/${PRG} >  TMP_${PRG}
		 chmod +x TMP_${PRG}
		 ./TMP_${PRG} ${RAW} ${CSL} ${SAT} ${KMLS1} ${FAY} 
		 rm TMP_${PRG}
		# Flag to avoid infinite loop in case of unsolvable problme
		EchoTeeRed "Hope that re-reading the images after new orbits download(s) helped..."

fi
echo

# remove old logs > MAXLOG defined below (in days), e.g. 60 days or any other value
MAXLOG=40

cd ${CSL}
find . -maxdepth 1 -name "LogFile_ReadAll_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;
if [ ${SAT} = "S1" ] ; then 
	find . -maxdepth 1 -name "NoPreciseOrbitsFoundFor_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;
	find . -maxdepth 1 -name "ORB_CleanMASSPROCESS_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;
	find . -maxdepth 1 -name "ORB_CleanRESAMPLED_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;	
	find . -maxdepth 1 -name "CleanMASSPROCESS_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;
	find . -maxdepth 1 -name "CleanRESAMPLED_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;	
	find . -maxdepth 1 -name "OrbitsToDownload_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;
	find . -maxdepth 1 -name "S1DataReaderLog_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;
	find . -maxdepth 1 -name "SAOCOMDataReaderLog_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;
	find . -maxdepth 1 -name "S1OrbitUpdaterLog_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;
	find . -maxdepth 1 -name "List_IMG_pol_HH_*.txt" -type f -mtime +${MAXLOG} -exec rm -f {} \;

fi

#rm -f Img_To_Read.txt List_csl_dates.txt List_csl.txt List_raw.txt 

MACLN=180
# remove S1_CLN or SAOCOM_CLN if more than MAXCLN days
if [ "${SAT}" = "S1" ] 
	then 
		if [ "${RESAMPLED}" != "" ] ; then 
			EchoTee "Clean products in ${RESAMPLED}/S1_CLN of more than ${MACLN} days"
			find ${RESAMPLED}/S1_CLN/ -maxdepth 5 -mindepth 4 -type d -name "*_S1*_*" -mtime +${MACLN} -exec rm -Rf {} \;
		fi
		if [ "${SAR_MASSPROCESS}" != "" ] ; then 
			EchoTee "Clean products in ${SAR_MASSPROCESS}/S1_CLN of more than ${MACLN} days"
			find ${SAR_MASSPROCESS}/S1_CLN -maxdepth 5 -mindepth 4 -type d -name "*_S1*_*" -mtime +${MACLN} -exec rm -Rf {} \;
			find ${SAR_MASSPROCESS}/S1_CLN/*/*/*/*/*/ -maxdepth 1 -type f -name "*S1*deg*" -mtime +${MACLN} -exec rm -f {} \;			
		fi
fi

#if [ "${SAT}" = "SAOCOM" ] 
#	then 
#		if [ "${RESAMPLED}" != "" ] ; then 
#			EchoTee "Clean products in ${RESAMPLED}/SAOCOM_CLN of more than ${MACLN} days"
#			find ${RESAMPLED}/SAOCOM_CLN/ -maxdepth 4 -mindepth 3 -type d -name "20[0-9][0-9][0-9][0-9][0-9][0-9]_20[0-9][0-9][0-9][0-9][0-9][0-9]" -mtime +${MACLN} -exec rm -Rf {} \;
#		fi
#
#		if [ "${SAR_MASSPROCESS}" != "" ] ; then 
#			EchoTee "Clean products in ${SAR_MASSPROCESS}/SAOCOM_CLN of more than ${MACLN} days"
#			find ${SAR_MASSPROCESS}/SAOCOM_CLN -maxdepth 4 -mindepth 3 -type d -name "20[0-9][0-9][0-9][0-9][0-9][0-9]_20[0-9][0-9][0-9][0-9][0-9][0-9]" -mtime +${MACLN} -exec rm -Rf {} \;
#			find ${SAR_MASSPROCESS}/SAOCOM_CLN/*/*/*/*/ -maxdepth 1 -type f -name "*SAOCOM*deg*" -mtime +${MACLN} -exec rm -f {} \;			
#
#		fi
#fi



# For S1 images, check if images exist with pol  different from INITPOL
#if [ ${SAT} = "S1" ] ; then 
	# Read S1DataReaderLog.txt and search for images without INIPO
#fi

EchoTee "------------------------------------"
EchoTee "All img read"
EchoTee "------------------------------------"

