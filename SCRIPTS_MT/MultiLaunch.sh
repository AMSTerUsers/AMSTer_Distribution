#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at launching multiple occurrences of a SinglePair processing 
# 		using a Global Primary (SuperMaster) as Priamry and all other existing images as Secondary. 
# It can be run incrementally and will only compute the new pairs. 
#
# Attention : DO NOT LAUNCH TWO OCCUENCE IN SAME DIR 
#
# Parameters :  - Global Primary (SuperMaster) date
#				- Dir where all original data are in csl format
#					Usually something like ..YourPath.../SAR_CSL/SAT/TRK/NoCrop
#				- Dir where results will be stored 
#					If it is for amplitude stacking purpose e.g. for shadows measurements,
#					it might be something like ..YourPath.../SAR_SM/AMPLITUDES/SAT/TRK/REGION
#				- File (incl path) with the processing parameters 
#               - LABELX and LABELY: position of date label in amplitude jpg images 
#				- optional: list of images to process (in the form of yyyymmdd or S1 name)
#
# Dependencies:
# 	- MT and MT Tools, at least V20190716. 	
#	- The FUNCTIONS_FOR_MT.sh file with the function used by the script. Will be called automatically by the script
#	- gnu sed and awk for more compatibility. 
#	- bc for basic computations
#   - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#
# Hard coded:	- SOFTWARE to launch multiple times. Here it is tuned for SinglePairNoUnwrap.sh
#				    but could work with others such as SinglePair.sh
#				- Path to .bashrc (sourced for safe use in cronjob)
#
# New in Distro V 1.0:	- Based on developpement version 2.8 and Beta V1.1.0
# New in Distro V 1.1:	- Remove hard coded lines
# New in Distro V 1.2:	- also take a list of pairs to process in 7th param
# New in Distro V 1.3: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20250523:	- state that it accepts asymetric zoom (either a single real value or NAzMRg, where N and M are reals values if want an asymmetric zoom)
# New in Distro V 3.2 20250626:	- remove MULTIPLEIMG
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on June 26, 2025"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

SUPERMASTER=$1
INPUTDATA=$2
OUTPUTDATA=$3
PARAM=$4
LABELX=$5					# position of the date label in jpg fig of mod
LABELY=$6					# position of the date label in jpg fig of mod
PAIRFILES=$7				# PATH TO A LIST OF IMAGES IN THE FORM OF yyyymmdd or S1 name

# vvv ----- Hard coded lines to check --- vvv 
source /$HOME/.bashrc 
# ^^^ ----- Hard coded lines to check --- ^^^ 
 

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

SOFT=${PATH_SCRIPTS}/SCRIPTS_MT/SinglePairNoUnwrap.sh
 
if [ $# -lt 4 ] ; then echo “\n Usage $0 SUPERMASTER_DATE INPUTDATA_DIR OUTPUTDATA_DIR PARAM_FILE \n”; exit; fi

if [ $# -eq 7 ] 
	then 
		if [ -f "${PAIRFILES}" ]
			then 
				echo "Operate with a list pf pairs instead of all pairs available" 
			else 
				echo "You requested to operate with a list pf pairs instead of all pairs available but pair files does not exist. Please provide a full path; exiting..."
				exit	
		fi
fi

function GetParam()
	{
	unset PARAMETER 
	PARAMETER=$1
	PARAMETER=`grep -m 1 ${PARAMETER} ${PARAM} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAMETER=${PARAMETER}
	echo ${PARAMETER}
	}
	
function SpeakOut()
	{
	unset MESSAGE 
	local MESSAGE
	MESSAGE=$1
	# Check OS
	OS=`uname -a | cut -d " " -f 1 `

	case ${OS} in 
		"Linux") 
			espeak "${MESSAGE}" ;;
		"Darwin")
			say "${MESSAGE}" 	;;
		*)
			echo "${MESSAGE}" 	;;
	esac			
	}

PROROOTPATH=`GetParam PROROOTPATH`			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name. 

SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT 
TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF
REGION=`GetParam "REGION,"`					# Processing directory and dir where data are stored E.g. RS2_UF
LLRGCO=`GetParam "LLRGCO,"`					# LLRGCO, Lower Left Range coord offset for final interferometric products generation. Used mainly for Shadow measurements
LLAZCO=`GetParam "LLAZCO,"`					# LLAZCO, Lower Left Azimuth coord offset for final interferometric products generation. Used mainly for Shadow measurements

FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored

#MULTIPLEIMG=`GetParam MULTIPLEIMG`			# MULTIPLEIMG, as long as the stitching of S1 img is not ready, keep NOMULTIPLE to process only the first img (ie _A.csl or _D.csl) in mass processing. 
#											#            Other occurences (ie _A.1.csl or _D.1.csl etc) will be ignored. However, for manual single processing, one may want to process both images. 
#											#            In such a case, run the first processing with MASBURSTSET (and/or SLVBURSTSET) set to 1 then rerun with set to 2. Not tested... 
ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping (either a single real value or NAzMRg, where N and M are reals values if want an asymmetric zoom)
INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products

source ${FCTFILE}

RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm%Ss" | ${PATHGNU}/gsed "s/ //g"`

if [ -z ${LLRGCO} ] 
	then 
		EchoTeeYellow "LLRGCO and LLAZCO seemed not set in Parameters File. Will use default vlaue 50 and 50."
		EchoTeeYellow " This is only used to ensure common crop for shadow measurements; shouldn't be a problem except if InSAR stops before 100%"
		EchoTeeYellow ""
		LLRGCO=50	
		LLAZCO=50
fi

if [ $# -eq 7 ] 
	then 
		cat ${PAIRFILES} > New_Slaves_to_process_${RUNDATE}.txt
	else 
		
		# Listing all existing data in .csl format from DATAPATH, but the Super Master
		##############################################################
		if [ ${SATDIR} == "S1" ] 						
			then
				ls ${INPUTDATA} | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/grep -v .txt | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d_ -f 3 > All_Slaves_${RUNDATE}.txt
			else 
				ls ${INPUTDATA} | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/grep -v .txt > All_Slaves_${RUNDATE}.txt
		fi
		# Compare with what exist already in ${OUTPUTDATA} in order to 
		#  process only the new ones, again without Super Master:
		##################################################################
		if [ -d ${OUTPUTDATA} ]
			then
				if [ ${SATDIR} == "S1" ] 						
					then
						# image names with sat A or B reference in name (from bulk mass processing)
						EchoTeeRed "Suppose processed image names as PRIMARY_S1A/B_TRK_SECONDARY_D(.x)_REGION (from bulk mass processing)"
						EchoTeeRed "If processed images have another form (mostly from manual mass processing), comment/uncomment lines accordingly in ${PRG} script"
						EchoTeeRed "   (cfr lines after # process only the new ones, again without Super Master)"				
						# Check if sub dir with super master exist already to avoid ls error msg
						if [ `ls -d ${OUTPUTDATA}/${SUPERMASTER}* 2> /dev/null | wc -l` -gt 0 ] 
							then 
								# if S1 names instaed of dates:
								ls -d ${OUTPUTDATA}/${SUPERMASTER}* | ${PATHGNU}/gawk -F '/' '{print $NF}' | ${PATHGNU}/gsed "s/'${SUPERMASTER}'_//g"  | cut -d_ -f 2 > Processed_slaves_${RUNDATE}.txt
							else 
								touch Processed_slaves_${RUNDATE}.txt 
						fi
					else 
						# Check if sub dir with super master exist already to avoid ls error msg
						if [ `ls -d ${OUTPUTDATA}/${SUPERMASTER}*  2> /dev/null | wc -l` -gt 0 ] 
							then 
								ls -d ${OUTPUTDATA}/${SUPERMASTER}* | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d _ -f 2 | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/gsed 's/$/.csl/' > Processed_slaves_${RUNDATE}.txt 
							else 
								touch Processed_slaves_${RUNDATE}.txt 
						fi
				fi
		fi 
		
		# Get only the new files to process
		###################################
		sort All_Slaves_${RUNDATE}.txt Processed_slaves_${RUNDATE}.txt | uniq -u > New_Slaves_to_process_${RUNDATE}.txt 
fi

	
for PAIR in `cat -s New_Slaves_to_process_${RUNDATE}.txt`
do
	SLV=`GetDateCSL ${PAIR}`
	EchoTeeYellow "// Will process pair : ${SUPERMASTER} ${SLV} "
	EchoTeeYellow "// ***************************************** "
	if [ -f "${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt" ] && [ -s "${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt" ] 
		then
			EchoTeeYellow "Not first run, hence get size of crop already applied"
			URRGCOFFSET=`grep "Upper right range coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt`	 	# Do not change this line !! 
			URAZCOFFSET=`grep "Upper right azimuth coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt` 		# Do not change this line !! 
			URRGCOFFSETVAL=`grep "Upper right range coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt  | tr -d -c 0-9`
			URAZCOFFSETVAL=`grep "Upper right azimuth coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt  | tr -d -c 0-9`
			EchoTeeRed "Are sure of your Upper right coordinate from the _SizeOfCroppedAreaOfInterest.txt? : ${URRGCOFFSETVAL} and ${URAZCOFFSETVAL}"
			# instert in SinglePairNoUnwrap.sh a line to force Upper right range coordinate 
			${PATHGNU}/gsed "s/# Insert here below Upper right range forced coordinates/${URRGCOFFSET}/" ${SOFT} > SinglePairNoUnwrap.sh
			# instert in SinglePairNoUnwrap.sh a line to force Upper right range coordinate 
			${PATHGNU}/gsed -i "s/# Insert here below Upper right azimuth forced coordinates/${URAZCOFFSET}/" SinglePairNoUnwrap.sh 
			chmod +x SinglePairNoUnwrap.sh
		else
			EchoTeeYellow "First run, will run first pair to get the crop"
			${SOFT} ${SUPERMASTER} ${SLV} ${PARAM} 
			URRGC=`updateParameterFile ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${SUPERMASTER}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}/i12/TextFiles/InSARParameters.txt "Upper right range coordinate"`
			URAZC=`updateParameterFile ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${SUPERMASTER}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}/i12/TextFiles/InSARParameters.txt "Upper right azimuth coordinate"`
			URRGC2OFFSET=`echo "${URRGC} - ${LLRGCO} " | bc`
			URAZC2OFFSET=`echo "${URAZC} - ${LLAZCO} " | bc`
			echo 'ChangeParam "Upper right range coordinate" '${URRGC2OFFSET} 'InSARParameters.txt' > ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt
			echo 'ChangeParam "Upper right azimuth coordinate" '${URAZC2OFFSET}' InSARParameters.txt' >> ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt
			URRGCOFFSET=`grep "Upper right range coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt`
			URAZCOFFSET=`grep "Upper right azimuth coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt`
			# instert in SinglePairNoUnwrap.sh a line to force Upper right range coordinate 
			${PATHGNU}/gsed "s/# Insert here below Upper right range forced coordinates/${URRGCOFFSET}/" ${SOFT} > SinglePairNoUnwrap.sh
			# instert in SinglePairNoUnwrap.sh a line to force Upper right range coordinate 
			${PATHGNU}/gsed -i "s/# Insert here below Upper right azimuth forced coordinates/${URAZCOFFSET}/" SinglePairNoUnwrap.sh
			chmod +x SinglePairNoUnwrap.sh
			# Remove first processing before replay with the crop
			TOMOVE=`ls -d ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${SUPERMASTER}_${SLV}_${REGION}*`
			rm -rf ${TOMOVE}
	
	fi 	

	./SinglePairNoUnwrap.sh ${SUPERMASTER} ${SLV} ${PARAM} _DateLabel${LABELX}_${LABELY} NOSM ${LABELX} ${LABELY}
	TOMOVE=`ls -d ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${SUPERMASTER}_${SLV}_*`
	if [ -d ${OUTPUTDATA} ] 						
			then	
				cp -r ${TOMOVE} ${OUTPUTDATA}
				cp ./SinglePairNoUnwrap.sh ${OUTPUTDATA}/${SUPERMASTER}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}_DateLabel${LABELX}_${LABELY}
				rm -r ${TOMOVE} ./SinglePairNoUnwrap.sh
			else 
				EchoTeeRed "Can't find ${OUTPUTDATA}. Manually cp then remove ./SinglePairNoUnwrap.sh and ${TOMOVE}"
	fi
	SpeakOut "${SATDIR} ${TRKDIR} : Pair ${SUPERMASTER} ${SLV} done and copied"
	EchoTee "${SATDIR} ${TRKDIR} : Pair ${SUPERMASTER} ${SLV} done  and copied"
	EchoTee "-----------------------------------------------------------------"
	
done

