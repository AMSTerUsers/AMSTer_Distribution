#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at launching multiple occurrences of a SinglePair.sh processing 
# 		and - create slant range amplitudes images aligned on a SM, 
#			- geocode Ampli and coh only
#			- create a fake hdr file for coh in slant range (to allow reading them with a GIS software)
#			- mask the coherence in slant range (can be openend with a GIS with the same hdr as unmasked coh) 
#			- move all the geoicoded coh and ampl in dedicated directories
# based on a list of pairs provided as DATEmas DATEslv. Already existing pairs  will be skipped. 
# 
# This version is based on MultiLaunch_ForMask.sh and MultiLaunch.sh and is rather dedicated to tracking changes in coh and ampli.
#
# Attention : - DO NOT LAUNCH TWO OCCUENCE IN SAME DIR 
#			  - Do not crop S1 Wide Swath images with kml. It would prevent the size of slant range products to remain the same for all pairs
#
# Parameters :  - Dir where all original data are in csl format
#					Usually something like ..YourPath.../SAR_CSL/SAT/TRK/NoCrop
#				- Dir where results will be stored 
#				- File (incl path) with the processing parameters 
#               - path to pair list in the form of DATE DATE. 
#
# Dependencies:
# 	- MT and MT Tools, at least V20190716. 	
#	- The FUNCTIONS_FOR_MT.sh file with the function used by the script. Will be called automatically by the script
#	- gnu sed and awk for more compatibility. 
#	- bc for basic computations
#   - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#	- byte2float.py, Swap_0_1_in_ByteFile.py 
#
# Hard coded:	- Path to .bashrc (sourced for safe use in cronjob)
#
# New in Distro V 1.0:	- based on MultiLaunch_ForMask.sh V_1.3
# New in Distro V 1.1:	- properly test if amplitude already computed for Sigma0 data
# New in Distro V 1.2: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20241202:	- Mask before interpolation after unwrapping ok with the 3 version of masking methods (old 1=keep; intermediate 1,2=mask in one file, latest 1,2,3 are masked in multiple masks)
#								- swap 0 and 1 before multiply the defo by the thresholdedSlantRangeMask 
#								- take mask(s) basename only if exist  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Dec 02, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# vvv ----- Hard coded lines to check --- vvv 
source /$HOME/.bashrc 
# ^^^ ----- Hard coded lines to check --- ^^^ 

SOFTORIG=${PATH_SCRIPTS}/SCRIPTS_MT/SinglePair.sh
SOFTNAME=`basename ${SOFTORIG}`

INPUTDATA=$1		# Dir where all original data are in csl format: .../SAR_CSL/SAT/TRK/NoCrop
OUTPUTDATA=$2		# Dir where results will be stored: ../SAR_SM/MASK/SAT/TRK/REGION
PARAM=$3			# File (incl path) with the processing parameters - MUST contains the date of the supermaster if run with Bt Bp criteria
PAIRSFILE=$4		# Table with a list of pairs in the form of SAR_SM/MSBAS/REGION/seti/table_BpMin_BpMax_BtMin_BtMax.txt prepared with the script Prepa_MSBAS.sh (with or without header; it does not matter) 
if [[ "${PAIRSFILE}" != *".txt" ]]  ; then echo "Path to text file with Date_Primary Date_Secondary of pairs to process (or similar to SM_Approx_baselines.txt) must be provided as 4th parameter." ; exit 0 ; fi

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
CALIBSIGMA=`GetParam "CALIBSIGMA,"`			# CALIBSIGMA, if SIGMAYES it will output sigma nought calibrated amplitude file at the insar product generation step  

SUPERMASTER=`GetParam "SUPERMASTER,"`		# date of the Global Primary (supermaster)

FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored

ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products

APPLYMASK=`GetParam "APPLYMASK,"`			# APPLYMASK, Apply mask before unwrapping (APPLYMASKyes or APPLYMASKno)
if [ ${APPLYMASK} == "APPLYMASKyes" ] 
 then 
	PATHTOMASK=`GetParam "PATHTOMASK,"`			# PATHTOMASK, geocoded mask file name and path
	if [ "${PATHTOMASK}" != "" ]
		then 
			# old Version of LaunchParamFiles.txt, i.e. =< 20231026
			MASKBASENAME=`basename ${PATHTOMASK##*/}`  
		else 
			# Version of LaunchParamFiles.txt, i.e. >= 202341015
			PATHTOMASKGEOC=`GetParam "PATHTOMASKGEOC,"`			# PATHTOMASKGEOC, geocoded "Geographical mask" file name and path (water body etc..)
			DATAMASKGEOC=`GetParam "DATAMASKGEOC,"`				# DATAMASKGEOC, value for masking in PATHTOMASKGEOC

			PATHTOMASKCOH=`GetParam "PATHTOMASKCOH,"`			# PATHTOMASKCOH, geocoded "Thresholded coherence mask" file name and path (mask at unwrapping below threshold)
			DATAMASKCOH=`GetParam "DATAMASKCOH,"`				# DATAMASKCOH, value for masking in PATHTOMASKCOH

			PATHTODIREVENTSMASKS=`GetParam "PATHTODIREVENTSMASKS,"` # PATHTODIREVENTSMASKS, path to dir that contains event mask(s) named eventMaskYYYYMMDDThhmmss_YYYYMMDDThhmmss(.hdr) for masking at Detrend with all masks having dates in Primary-Secondary range of dates
			DATAMASKEVENTS=`GetParam "DATAMASKEVENTS,"`			# DATAMASKEVENTS, value for masking in PATHTODIREVENTSMASKS 

			if [ "${PATHTOMASKGEOC}" != "" ] ; then MASKBASENAMEGEOC=`basename ${PATHTOMASKGEOC##*/}` ; else MASKBASENAMEGEOC=NoGeogMask  ; fi
			if [ "${PATHTOMASKCOH}" != "" ] ; then MASKBASENAMECOH=`basename ${PATHTOMASKCOH##*/}` ; else MASKBASENAMECOH=NoCohMask  ; fi
			if [ "${PATHTODIREVENTSMASKS}" != "" ] 
				then 
				    if [ "$(find "${PATHTODIREVENTSMASKS}" -type f | head -n 1)" ]
				    	then 
				    		MASKBASENAMEDETREND=`basename ${PATHTODIREVENTSMASKS}` 
				    		MASKBASENAMEDETREND=Detrend${MASKBASENAMEDETREND}
				    	else 
				    		echo "${PATHTODIREVENTSMASKS} exist though is empty, hence apply no Detrend mask " 
				    		MASKBASENAMEDETREND=NoAllDetrend
				    fi
				else 
					MASKBASENAMEDETREND=NoAllDetrend
			fi

			MASKBASENAME=${MASKBASENAMEGEOC}_${MASKBASENAMECOH}_${MASKBASENAMEDETREND}

	fi
 else 
  PATHTOMASK=`echo "NoMask"`
  MASKBASENAME=`echo "NoMask"` 
fi

source ${FCTFILE}

RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm%Ss" | ${PATHGNU}/gsed "s/ //g"`

if grep -q Delay "${PAIRSFILE}"
	then
		cat ${PAIRSFILE} | tail -n+3 > ${PAIRSFILE}_NoBaselines_${RUNDATE}.txt 
		PAIRSFILE=${PAIRSFILE}_NoBaselines_${RUNDATE}.txt
		
fi

if [ -z ${LLRGCO} ] 
	then 
		EchoTeeYellow "LLRGCO and LLAZCO seemed not set in Parameters File. Will use default vlaue 50 and 50."
		EchoTeeYellow " This is only used to ensure common crop for shadow measurements; shouldn't be a problem except if InSAR stops before 100%"
		EchoTeeYellow ""
		LLRGCO=50	
		LLAZCO=50
fi
mkdir -p ${PROROOTPATH}/${SATDIR}/${TRKDIR}
mkdir -p ${OUTPUTDATA}/${SATDIR}/${TRKDIR}/${REGION}
OUTPUTDATA=${OUTPUTDATA}/${SATDIR}/${TRKDIR}/${REGION}

mkdir -p ${OUTPUTDATA}/_ALL_COH_GEOC
mkdir -p ${OUTPUTDATA}/_ALL_COH_SLANTRG
if [ "${CALIBSIGMA}" == "SIGMAYES" ]
	then
		mkdir -p ${OUTPUTDATA}/_ALL_AMPLI_SIGMA_SLANTRG
		mkdir -p ${OUTPUTDATA}/_ALL_AMPLI_SIGMA_GEOC
		OUTPUTAMPLISLANTR=${OUTPUTDATA}/_ALL_AMPLI_SIGMA_SLANTRG
		OUTPUTAMPLIGEOC=${OUTPUTDATA}/_ALL_AMPLI_SIGMA_GEOC
	else 
		mkdir -p ${OUTPUTDATA}/_ALL_AMPLI_SLANTRG
		mkdir -p ${OUTPUTDATA}/_ALL_AMPLI_GEOC
		OUTPUTAMPLISLANTR=${OUTPUTDATA}/_ALL_AMPLI_SLANTRG
		OUTPUTAMPLIGEOC=${OUTPUTDATA}/_ALL_AMPLI_GEOC
fi
# Keep track of command line and option used 
echo "Command line used and parameters:" > ${OUTPUTDATA}/Command_Line.txt
echo "$(dirname $0)/${PRG} $@" >> ${OUTPUTDATA}/Command_Line.txt

cd ${PROROOTPATH}/${SATDIR}/${TRKDIR}

cp ${PAIRSFILE} ${PROROOTPATH}/${SATDIR}/${TRKDIR}/Pairs_to_process_${RUNDATE}.txt	

# Lets start
#############

# For unknow reason the FOR crashes sometimes... Prefer WHILE loop
if [ -f "${PROROOTPATH}/${SATDIR}/${TRKDIR}/Pairs_to_process_${RUNDATE}.txt" ] && [ -s "${PROROOTPATH}/${SATDIR}/${TRKDIR}/Pairs_to_process_${RUNDATE}.txt" ] ; then 
	cat -s ${PROROOTPATH}/${SATDIR}/${TRKDIR}/Pairs_to_process_${RUNDATE}.txt | while read PAIRS; do 	
		MASTER=`echo ${PAIRS} | cut -d " " -f1 `
		SLAVE=`echo ${PAIRS} | cut -d " " -f2 `
		MAS=`GetDateCSL ${MASTER}`
		SLV=`GetDateCSL ${SLAVE}`

		# Check if pair already processed
		if [ ! -s ${OUTPUTDATA}/_ALL_COH_GEOC/coherence*${MAS}_${SLV}*deg ]
			then 
				EchoTee "${MAS}_${SLV} not processed yet"
				# Change SinglePair.sh to our specific needs:
				# Prepare changing SinglePair.sh to our specific needs:
				cp ${SOFTORIG} ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${SOFTNAME}
				SOFT=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${SOFTNAME}

				# geocode only ampli and coh
				# test if MAS and/or SLV ampli are already in ${OUTPUTDATA}/_ALL_AMPLI_GEOC/

				if [ "${CALIBSIGMA}" == "SIGMAYES" ]
					then
						TSTMAS=`ls ${OUTPUTAMPLIGEOC}/*${MAS}*sigma0*deg* 2>/dev/null | wc -l`
						TSTSLV=`ls ${OUTPUTAMPLIGEOC}/*${SLV}*sigma0*deg* 2>/dev/null | wc -l`
					else 
						TSTMAS=`ls ${OUTPUTAMPLIGEOC}/*${MAS}*mod*deg* 2>/dev/null | wc -l`
						TSTSLV=`ls ${OUTPUTAMPLIGEOC}/*${SLV}*mod*deg* 2>/dev/null | wc -l`
				fi


				if [ ${TSTMAS} -gt 1 ]
					then 
						#MAS already geocoded
						if [ ${TSTSLV} -gt 1 ]
							then
								EchoTeeYellow "MAS and SLV already geocoded; geoc only coh"
								${PATHGNU}/gsed -i "s%NO YES YES YES NO YES YES NO%NO NO NO YES NO NO NO NO%" ${SOFT}
							else
								EchoTeeYellow "MAS already geocoded but not SLV ; geoc only SLV and coh"
								${PATHGNU}/gsed -i "s%NO YES YES YES NO YES YES NO%NO NO YES YES NO NO NO NO%" ${SOFT}
						fi
					else 
						#MAS not geocoded yet
						if [ ${TSTSLV} -gt 1 ]
							then
								EchoTeeYellow "SLV already geocoded but not MAS; geoc only MAS and coh"
								${PATHGNU}/gsed -i "s%NO YES YES YES NO YES YES NO%NO YES NO YES NO NO NO NO%" ${SOFT}
							else
								EchoTeeYellow "MAS and SLV not geocoded yet ; geoc MAS, SLV and coh"
								${PATHGNU}/gsed -i "s%NO YES YES YES NO YES YES NO%NO YES YES YES NO NO NO NO%" ${SOFT}
						fi
				fi

				#avoid geocoding incidence
				TMPDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}/i12
		
				${PATHGNU}/gsed -i '/.*GeocUTM.*/i mkdir -p '${TMPDIR}'\/InSARProductsDoNotGeoc' ${SOFT}
				${PATHGNU}/gsed -i '/.*GeocUTM.*/i mv '${TMPDIR}'\/InSARProducts\/incidence\* '${TMPDIR}'\/InSARProductsDoNotGeoc' ${SOFT} # add this for mute error > /dev/null 2>&1 ?
				${PATHGNU}/gsed -i '/.*GeocUTM.*/i mv '${TMPDIR}'\/InSARProducts\/\*flip\* '${TMPDIR}'\/InSARProductsDoNotGeoc' ${SOFT}
				${PATHGNU}/gsed -i '/.*GeocUTM.*/i mv '${TMPDIR}'\/InSARProducts\/\*flop\* '${TMPDIR}'\/InSARProductsDoNotGeoc' ${SOFT}

				${PATHGNU}/gsed -i '/\# INSAR/i ChangeParam \"Lower left range coordinate\" '${LLRGCO}' InSARParameters.txt' ${SOFT}
				${PATHGNU}/gsed -i '/\# INSAR/i ChangeParam \"Lower left azimuth coordinate\" '${LLAZCO}' InSARParameters.txt' ${SOFT}
				${PATHGNU}/gsed -i '/\# INSAR/i \#TO REPLACE WITH URRGCOFFSET' ${SOFT}
				${PATHGNU}/gsed -i '/\# INSAR/i \#TO REPLACE WITH URAZCOFFSET' ${SOFT}

				EchoTeeYellow "// Will process pair : ${MAS} ${SLV} "
				EchoTeeYellow "// ***************************************** "
				if [ ! -d ${OUTPUTDATA}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML} ] 
					then 

						if [ -f "${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt" ] && [ -s "${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt" ]
							then
								EchoTeeYellow "Not first run, hence get size of crop already applied"
								URRGCOFFSET=`grep "Upper right range coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt`	 	# Do not change this line !! 
								URAZCOFFSET=`grep "Upper right azimuth coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt` 		# Do not change this line !! 
								URRGCOFFSETVAL=`grep "Upper right range coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt  | tr -d -c 0-9`
								URAZCOFFSETVAL=`grep "Upper right azimuth coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt  | tr -d -c 0-9`
								EchoTeeRed "Are sure of your Upper right coordinate from the _SizeOfCroppedAreaOfInterest.txt? : ${URRGCOFFSETVAL} and ${URAZCOFFSETVAL}"

								${PATHGNU}/gsed -i "s/#TO REPLACE WITH URRGCOFFSET/${URRGCOFFSET}/" ${SOFT}
								${PATHGNU}/gsed -i "s/#TO REPLACE WITH URAZCOFFSET/${URAZCOFFSET}/" ${SOFT}

							else
								EchoTeeYellow "First run, will run first pair to get the crop"
								#   If SinglePair.sh ask if one want to benefit from former processing, answer no automatically
								echo "y" | ${SOFT} ${MAS} ${SLV} ${PARAM}

								URRGC=`updateParameterFile ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}/i12/TextFiles/InSARParameters.txt "Upper right range coordinate"`
								URAZC=`updateParameterFile ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}/i12/TextFiles/InSARParameters.txt "Upper right azimuth coordinate"`
								URRGC2OFFSET=`echo "${URRGC} - ${LLRGCO} " | bc`
								URAZC2OFFSET=`echo "${URAZC} - ${LLAZCO} " | bc`
								echo 'ChangeParam "Upper right range coordinate" '${URRGC2OFFSET} 'InSARParameters.txt' > ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt
								echo 'ChangeParam "Upper right azimuth coordinate" '${URAZC2OFFSET}' InSARParameters.txt' >> ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt
								URRGCOFFSET=`grep "Upper right range coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt`
								URAZCOFFSET=`grep "Upper right azimuth coordinate" ${OUTPUTDATA}/_SizeOfCroppedAreaOfInterest.txt`
								# instert in SOFT a line before # INSAR to force Upper right range coordinate 

								${PATHGNU}/gsed -i "s/#TO REPLACE WITH URRGCOFFSET/${URRGCOFFSET}/" ${SOFT}
								${PATHGNU}/gsed -i "s/#TO REPLACE WITH URAZCOFFSET/${URAZCOFFSET}/" ${SOFT}
				
								# Remove first processing before replay with the crop
								TOMOVE=`ls -d ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}*`
								rm -rf ${TOMOVE}
	
						fi 	

						#   If SinglePair.sh ask if one want to benefit from former processing, answer no automatically
						echo "y" | ${SOFT} ${MAS} ${SLV} ${PARAM}

						# Some specific things for Alex
						# get header file opening slant range coherence with GIS software
						COHFILE=`basename ${TMPDIR}/InSARProducts/coherence*days`
						cp ${TMPDIR}/InSARProductsDoNotGeoc/incidence.fl?p.hdr ${TMPDIR}/InSARProducts/${COHFILE}.hdr 

						# mask coherence 
						#ffa ${TMPDIR}/InSARProducts/${COHFILE} x ${TMPDIR}/InSARProducts/slantRangeMask 
	
						if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
							then 
								EchoTee "Multiply coherence map with mask."
								if [ -f "${RUNDIR}/i12/InSARProducts/binarySlantRangeMask" ]
									then 
										EchoTee "Suppose multilevel masking where 1 and/or 2 = to be masked and 0 = non masked in a single file, without detrend mask(s)."
										EchoTee "  hence we must inverse the binarySlantRangeMask before multiply it with the coherence/"
										# i.e. use new masking method with multilevel masks where 0 = non masked and 1 or 2 = masked
										Swap_0_1_in_ByteFile.py ${TMPDIR}/i12/InSARProducts/binarySlantRangeMask
										byte2Float.py ${TMPDIR}/i12/InSARProducts/binarySlantRangeMask_Swap01
										mv -f ${TMPDIR}/i12/InSARProducts/slantRangeMask ${TMPDIR}/i12/InSARProducts/slantRangeMask_original
										mv -f ${TMPDIR}/i12/InSARProducts/binarySlantRangeMask_Swap01 ${TMPDIR}/i12/InSARProducts/slantRangeMask
										ffa ${TMPDIR}/InSARProducts/${COHFILE} x ${TMPDIR}/InSARProducts/slantRangeMask 
									else 
										if [ -f "${RUNDIR}/i12/InSARProducts/thresholdedSlantRangeMask" ] 											
											then 
												EchoTee "Suppose multilevel masking where 1 and/or 2 and/or 3 = to be masked and 0 = non masked, that is with possible detrend masks."
												EchoTee "Because processing is performed for Coh and Ampl only, I guess there is no unwrapping and no Detrend masks, "
												EchoTee "  hence we must inverse the thresholdedSlantRangeMask before multiply it with the coherence/"

												# i.e. use new masking method with multiple masks where 0 = non masked and 1 or 2 or 3 = masked
												Swap_0_1_in_ByteFile.py ${TMPDIR}/i12/InSARProducts/thresholdedSlantRangeMask
												byte2Float.py ${TMPDIR}/i12/InSARProducts/thresholdedSlantRangeMask_Swap01
												mv -f ${TMPDIR}/i12/InSARProducts/slantRangeMask ${TMPDIR}/i12/InSARProducts/slantRangeMask_original
												mv -f ${TMPDIR}/i12/InSARProducts/thresholdedSlantRangeMask_Swap01 ${TMPDIR}/i12/InSARProducts/slantRangeMask
												ffa ${TMPDIR}/InSARProducts/${COHFILE} x ${TMPDIR}/InSARProducts/slantRangeMask 
											else
												EchoTee "Suppose mask where 0 = to be masked and 1 = non masked."
												# i.e. use old masking method with single level masks where 0 = masked
												ffa ${TMPDIR}/InSARProducts/${COHFILE} x ${TMPDIR}/InSARProducts/slantRangeMask 
										fi
								fi
						fi
						mv ${TMPDIR}/InSARProducts/${COHFILE}_X_slantRangeMask ${TMPDIR}/InSARProducts/${COHFILE}.masked
	
						POL=`ls ${TMPDIR}/InSARProducts/interfero.??-?? | cut -d . -f 2`
						cp ${TMPDIR}/InSARProducts/coherence.${POL}.ras.sh ${TMPDIR}/InSARProducts/coherence.${POL}.ras_masked.sh
						${PATHGNU}/gsed -i "s/coherence.${POL}/${COHFILE}.masked/g" ${TMPDIR}/InSARProducts/coherence.${POL}.ras_masked.sh
						cd ${TMPDIR}/InSARProducts/
						${TMPDIR}/InSARProducts/coherence.${POL}.ras_masked.sh
						cd ${PROROOTPATH}/${SATDIR}/${TRKDIR}
					
						# store products in corresponding dir
						mv -f ${TMPDIR}/GeoProjection/coherence*deg ${OUTPUTDATA}/_ALL_COH_GEOC
						mv -f ${TMPDIR}/GeoProjection/coherence*deg.hdr ${OUTPUTDATA}/_ALL_COH_GEOC

						mv -f ${TMPDIR}/InSARProducts/coherence*days ${OUTPUTDATA}/_ALL_COH_SLANTRG
						mv -f ${TMPDIR}/InSARProducts/coherence*days.hdr ${OUTPUTDATA}/_ALL_COH_SLANTRG
						mv -f ${TMPDIR}/InSARProducts/coherence*days.masked ${OUTPUTDATA}/_ALL_COH_SLANTRG
						if [ "${CALIBSIGMA}" == "SIGMAYES" ]
							then
								mv -f ${TMPDIR}/GeoProjection/*sigma0.UTM*deg ${OUTPUTAMPLIGEOC}
								mv -f ${TMPDIR}/GeoProjection/*sigma0.UTM*deg.hdr ${OUTPUTAMPLIGEOC}
								mv -f ${TMPDIR}/InSARProducts/*sigma0 ${OUTPUTAMPLISLANTR}
							else 
								mv -f ${TMPDIR}/GeoProjection/*mod.UTM*deg ${OUTPUTAMPLIGEOC}
								mv -f ${TMPDIR}/GeoProjection/*mod.UTM*deg.hdr ${OUTPUTAMPLIGEOC}
								mv -f ${TMPDIR}/InSARProducts/*mod ${OUTPUTAMPLISLANTR}
						fi
						# move pairs
						TOMOVE=`ls -d ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_*`
						if [ -d ${OUTPUTDATA} ] 						
								then	
									cp -r ${TOMOVE} ${OUTPUTDATA}
									rm -r ${TOMOVE}
								else 
									EchoTeeRed "Can't find ${OUTPUTDATA}. Manually cp then remove ./${SOFTNAME} and ${TOMOVE}"
						fi
						SpeakOut "${SATDIR} ${TRKDIR} : Pair ${MAS} ${SLV} done and copied"
						EchoTee "${SATDIR} ${TRKDIR} : Pair ${MAS} ${SLV} done  and copied"
						EchoTee "-----------------------------------------------------------------"
					else 
						EchoTeeRed "Pair exists in ${OUTPUTDATA}. Please check"
				fi
			else 
				EchoTee "${MAS}_${SLV} already processed"
		fi # pair didin't exist yet
	done # next pair of list
fi

#fi
rm -f ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${SOFTNAME}
mv *.txt ${OUTPUTDATA}
