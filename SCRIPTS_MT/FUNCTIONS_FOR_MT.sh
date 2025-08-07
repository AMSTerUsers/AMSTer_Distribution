#!/bin/bash
# ****************************************************************************************
# This script contains functions for MT autmated run scripts
# It was fully refurbished to work with similar naming as what is present in the 
#     CSL InSARParameters.txt files etc... and adapted to the new processing chain 
#     making us of data already read in csl format using script Read_All_Img.sh
#
# Dependencies: Ensure having
#	- MT and MT Tools (incl. updateParameterFile), at least V20190716
#   - gnu sed (gsed) and gnu awk (gawk) for more compatibility. 
#   - cpxfiddle is part of Doris package (TU Delft) available here :
#            http://doris.tudelft.nl/Doris_download.html. 
#    - Fiji (from ImageJ) is usefull as well though not mandatory. Check hard coded PATHFIJI to app
#    - convert (to create jpg images from sun rasters)
#    - bc (for basic computations in scripts)
#    - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#    - snaphu
#	 - MasterDEM.sh script
#	 - __HardCodedLines.sh for the Path to binaries and sources for tracking the version of AMSTer Engine
#
#  Note: Function CreateHDR (used only for SinglePair.sh and SinglePairNiUnwrap.sh for flip/flop images) 
#        contains dummy hard coded values for UTM zone 35. No need to worry. 
#
# HARDCODED: - path to cpxfiddle (usually installed in /usr/local/bin/)
#
#
# New in Distro V 1.0:	- Based on developpement version 11.1 and beta version 5.2.1
#		Distro V 1.0.1:	- change Fct to plot geocoded residual interfero for better contrasts
#		Distro V 1.0.2:	- Get Bt=0 for TDX
#		Distro V 1.1.0:	- Let MT gives automatically the path to mask at geocoding
#		Distro V 1.2.0:	- offer option to calibrate the amplitude image 
#		Distro V 1.2.1:	- remove tee after cd in UnwrapAndPlot function
#		Distro V 1.3.0:	- add a Coherence Cleaning Threshold for Snaphu unwrapping (only operational with MT V >= 20200227). 
#  							If =1, only pixels defined by mask will be unwrapped. 
#							If 0<CohClnThreshold<1, all pixels defined by mask + pixels above CohClnThreshold will be unwrapped 
#		Distro V1.3.1: - remove option  -t=${DETCOHTHRESH} in DetPhun since that parameter os now read directecly from the LaunchParameters.txt since 20200219
#		Distro V1.4.0: - update Bistatic info at initInSAR
#					    - do not attempt to make fig of defoMap.Interpolated.flatten when processing TOPO
#		Distro V1.4.1: - former naming of fct amplitudeImagesReduction was updated with amplitudeImageReduction
#		Distro V1.4.2: - add function to plot black and white jpg figs with Fiji (can be used instead cpxfiddle for rasters, 
#						  but it is much slower and no color code is added. This could be easily done though... 
#						  Nevertheless, the fct is not used in scripts yet. Prefer modif here after.
#					   - Let the computer to sleep 1 sec if Linux before using cpxfiddle to create ras file  
#						 (This is is faster than using Fiji and it is compliant with the all the scripts that expect .ras files) 
#		Distro V1.4.3: - make fig of slantRangeMask in C1 instead of r4 now that mask is byte instead of float
#		Distro V1.4.4: - remove sleep while creating rasters in Linux as it does not help. Instead hard code path to cpxfiddle
#		Distro V1.4.5: - When unwrapping procedure is unknown, it will unwrap with same full procedure as "snaphu" 
#					   - Some cleaning 
#		Distro V1.4.6: - Remove obsolate update of Bistatic parameter in InSARParameters.txt from MakeInitInsar fct. 
#		Distro V1.5.0: - allows mapping of zones unwrapped with snaphu
# 		Distro V1.5.1: - Rename snaphuZoneMap and unwrappedPhase in InSARProducts with same long naming (Ha, Bt, Bp etc...) as the other products
# 		Distro V1.5.2: - uses option -g to create snaphu.conf file with appropriate parameters for zone mapping
# 		Distro V1.5.3: - path to CPXFIDDLE only used as state variable
# 		Distro V1.5.4: - For DEM: avoid scientific exp numbers while computing with bc thanks to PARAMSC=$(printf "%.20f" $PARAM)
#					   - bug corrected in assessment of DEM pix size when smaller than interf size.  
# 		Distro V1.5.5: - Computes DEM resolution using awk instead of system printf wich was crashing in Linux.... Wierd indeed... 
# 		Distro V1.5.6: - Computes DEM resolution using awk instead of system printf also id CSLDATALOC is not PAIR
# 		Distro V1.5.7: - Update MakeFigFiji to cope with data format as Real32
# 		Distro V1.5.8: - allows DetPhun 1&2 with CIS Branch Cut unwrapping
#					   - add function for allowing zoom in S1 WS data 
# 		Distro V1.5.9: - allows ZOOM factor to be proportionnal to RATIOPIX (ZOOM factor is used as input for smallest size of pixel; largest side is zommed as ZOOM * RATIOPIX)
#						 THIS VERTION WAS REVERTED TO 1.5.8 because such a zoom takes too much room for no gain
# 		Distro V1.6.0: - bug in estimation of geocoded pixel size (was considering AZPIXSIZE instead of AZPIXSIZE / Sin INCID)
#					      It does not affect though the Force processing when e.g. it was performed with imposed ML computed to 
#						  fit the pix size computed manually but it was providing with wrong estimate of Closest pix size. 
# 		Distro V1.6.1: - allows to mask deforamtion maps (but not unwrapped phase) with CIS branch cut algorithm
# 		Distro V1.6.2: - Bug corrected in size of Azimuth ipxel size for geocoding when Closest option selected
# 		Distro V1.6.3: - Add lines in snaphu conf for possible manual re-run of snaphu to get only recomputed zone map
# 		Distro V1.7.0: - Allows defining forced geocoded are with a kml using the GEOCKML parameter to be read from the LaunchParam.txt 
# 		Distro V1.7.1: - New fct GetMasTerEngineVersion to get the last version of MasTer Engine as param LASTVERSIONMT
# 		Distro V1.8.0: - bug: testing GEOCKML was positive when GEOCKML was the name of a dir containing files instead if the name of a kml file, resulting in wrong geocoding grid forcing. 
# 		Distro V2.0.0: - change path to MasTerEngine (former CIS) the same way for Mac and Linux
# 		Distro V2.0.1: - update $PATHMASTERENGINE
# 		Distro V2.1.0: - debug forced geocoding which was taking dummy path as valid kml, resulting in non forced geocoding grid
# 		Distro V2.1.1: - add new fct CropAtZeroAlt, useful to stay consistent with older time series of ampli image
# 		Distro V2.1.2: - correct path to MasTerEngine in fct to track version of MasTerEngine
#		Distro V2.1.3: - Rename _Sources_ME dir
#		Distro V3.0.0: - allows recursive snaphu unwrapping based on JL Froger method
#		Distro V3.0.1: - typo in function to get MasTer Engine version 
#		Distro V3.1.0: - debug recurcive unwrapping. Version for TOPO not tested
#		Distro V3.1.1: - Improve function to get MasTer Engine version 
#		Distro V3.1.2: - Get MasTer Engine version from History file if exists, from dirname if not
#		Distro V3.1.3: - avoid unharmful error message when checking for popping figures 
#		Distro V3.1.4: - Silence updateParametersFile in RemovePlane function to avoid displaying /pathToFile, 1234, 1234, /pathToFile, /pathToFile
#		Distro V3.1.5: - cosmetic: renaming geocoded S1 SM ampli image from MAS to MASNAME seems obsolate 
#					   - cosmetic: mute possible complaining message that permission can't be preserved, as it may occur when moving from Mac to Linux or Windows 
#		Distro V3.1.6: - avoid searching for ending .sh after searching for *deg  
# New   Distro V4.0:   - Use hard coded lines definition from __HardCodedLines.sh
# New   Distro V4.1: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 5.0.0: 	- read UTM zone for geocoding
# New in Distro V 6.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names (except for CIS unwrapping method name)
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 6.1 20230928:	- make figs for maskedCoherence 
# New in Distro V 6.2 20231003:	- debug figs for maskedCoherence 
# New in Distro V 6.2.1 20231004:	- add raster of geocoded maskedCoherence 
# New in Distro V 6.2.2 20231012:	- debug raster of geocoded maskedCoherence 
# New in Distro V 7.0.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#									- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 7.0.1 20231102:	- Get version of AMSTer in GetAMSTerEngineVersion to avoid reading __HardCodedLines.sh 
# New in Distro V 7.0.2 20231114:	- Put the path to AMSTerEngine sources in function GetAMSTerEngineVersion instead of calling a function in __HardCodedLines.sh
#										Indeed, the installer must have put it in {PATHAMSTERENGINE}/_Sources_AE/Older/
# New in Distro V 7.0.3 20231114:	- Debug GetAMSTerEngineVersion
# New in Distro V 7.0.4 20231122:	- Create fig of amplitude rasters with range based on min,mean + 2 stdev in PlotGeoc with new function MakeFigRAuto
# New in Distro V 7.0.5 20231222:	- Avoid error message about .ras file when FIG != FIGyes
# New in Distro V 7.1.0 20240228:	- Fix rounding pix size when smaller than one by allowing scale 5 before division  
# New in Distro V 7.1.1 20240425:	- Warns when coarse coreg fails and suggests to put image in quarantine but only log the info in ${OUTPUTDATA}/_Coarse_Coregistration_Failed.txt 
# New in Distro V 7.1.2 20240426:	- Force handling Nr of anchor points and sigma values read from lig files at coarse coregistration as integers
# New in Distro V 7.1.3 20240812:	- Correct bug introduced in V7.1.2 at CoarseCoregTestQuality fct. It created wrong error msg for processes other than S1 IW and tried to improve a successful coarse coreg. 
# New in Distro V 7.1.3 20240814:	- fct SlantRangeExtDEM adapted to old and new (>June 2024) AMSTer Engine slantRangeDEM fonction (i.e. for 3 level masks)
# New in Distro V 8.0.0 20241015:	- Allow usage of multiple masks 
# New in Distro V 8.0.1 20241114:	- Add masking with events masks in PATHTODIREVENTSMASKS
#									- no slantRangeMask.txt anymore
# New in Distro V 8.1.1 20241202:	- ManageDEM: Check that Detrend masks from ${PATHTODIREVENTSMASKS} are all projected in Slant Range in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/
# New in Distro V 8.1.2 20241203:	- externalSlantRangeDEM.txt saved with mask version in fct ManageDEM and SlantRangeExtDEM
# New in Distro V 8.1.3 20241213:	- rebulid link slantRangeMask also when the all masks in PATHTODIREVENTSMASKS are OK, just in case porcessing is performed on a computer with another OS
# New in Distro V 8.1.4 20250225:	- cosmetic: for security, indicate in SlantRangeExtDEM that since new multi level masks, there is no more slantRangeMask.txt. Instead, everything is in externalSlantRangeDEM.txt
# New in Distro V 8.2.0 20250515:	- Allows zoom factor to differ in range and azimuth. For that to happen, ZOOM factor in LaunchParameters must be provided as a string made of two numbers followed by Rg and Az, MRgNAz (M and N being Real or Integer) 
#									- corr bug that was shaping non-forced pixel shape to ML in wrong direction for Envisat (i.e. when longest side of pixel was in Rg instead of Az)
#									- new fct to check Zoom asymetry (CheckZOOMasymetry)
#									- replace i12.No.Zoom with i12.NoZoom
# New in Distro V 8.2.1 20250522:	- add \ in grep -v of ".something" and a trailing $, e.g. grep -v "\.ras$" to avoid interpreting dot 
# New in Distro V 8.2.2 20250526:	- do not attempt to move unwrapped phase if SKIPUW=yes to avoid possible error message when performing Skip unwrap
# New in Distro V 9.0.0 20250605:	- Revise asymetric ML 
#									- add RatioPixUnzoomed fct needed for ReGeocoding
# New in Distro V 9.1.0 20250617:	- cope with ETAD topo phase plots (AMSTerEngine > V20250612): either plot "First phase component" or 
#									  "Topographic phase component", "Model-based phase component file path" and "Correction phase component file path" if any
#									- avoid error message in atempt to cp externalSlantRangeDEM_NoMask.txt when used with new managment of dems and masks 
# New in Distro V 9.2.0 20250626:	- corr bug in RatioPix and RatioPixUnzoomed (was missing -l in bc command, leading to underestimate ML 1 for ENVISAT for instance)

# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better... when time.
# ****************************************************************************************
FCTVER="Distro V9.2.0 AMSTer script utilities"
FCTAUT="Nicolas d'Oreye, (c)2016-2019, Last modified on June 26, 2025"

# If run on Linux, may not need to use gsed. Can use native sed instead. 
#   It requires then to make an link e.g.: ln -s yourpath/sed yourpath/gsed in your Linux. 

# vvv ----- Hard coded lines to check --- vvv 
source $HOME/.bashrc 

source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Path to binaries and sources for tracking the version of AMSTer Engine
	#	FunctionsForAEPathSources
# ^^^ ----- Hard coded lines to check --- ^^^ 

	
OS=`uname -a | cut -d " " -f 1 `


# Define functions:
###################

# GENERAL
##########
# echo and tee at the same time
function EchoTee()
	{
	unset MESSAGE
	local MESSAGE=$1
	echo -e "  //  ${MESSAGE}"	| tee -a ${LOGFILE}
	}
function EchoTeeRed()
	{
	unset MESSAGE
	local MESSAGE=$1
	echo -e "  //  $(tput setaf 1)$(tput setab 7)${MESSAGE}$(tput sgr 0)"	| tee -a ${LOGFILE}
	}
function EchoTeeYellow()
	{
	unset MESSAGE
	local MESSAGE=$1
	echo -e "  //  $(tput setaf 3)${MESSAGE}$(tput sgr 0)"	| tee -a ${LOGFILE}
	}

function GetDateCSL()
	{
	unset DIRNAM
	local DIRNAM=$1
	# Following will be obsolate when S1 image stitching will be available at reading
	if [ ${SATDIR} == "S1" ] 
		then 
			echo "${DIRNAM}" | cut -d _ -f 3
		else
			echo "${DIRNAM}" | cut -d . -f1   # just in case...
	fi
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


function RemDoubleSlash()
	{
	unset NAMETOCLEAN
	local NAMETOCLEAN
	NAMETOCLEAN=$1
	echo ${NAMETOCLEAN} | ${PATHGNU}/gsed 's%\/\/%\/%g' 
	}

# Substitution
#################################	

# Change parameters in Parameters txt files
function ChangeParam()
	{
	unset CRITERIA NEW FILETOCHANGE
	local CRITERIA
	local NEW	
	local FILETOCHANGE
	CRITERIA=$1
	NEW=$2
	FILETOCHANGE=$3
	
	unset KEY parameterFilePath ORIGINAL
	local KEY
	local parameterFilePath 
	local ORIGINAL
	
	KEY=`echo ${CRITERIA} | tr ' ' _`
	case ${FILETOCHANGE} in
		"SM_MAS_InSARParameters.txt") parameterFilePath=${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/TextFiles/InSARParameters.txt;;
		"InSARParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/InSARParameters.txt;;
		"InSARParametersZoom.txt") parameterFilePath=${RUNDIR}/i12.NoZoom/TextFiles/InSARParameters.txt;;
		"SM_SLV_InSARParameters.txt") parameterFilePath=${MAINRUNDIR}/${SUPERMASTER}_${SLV}/i12/TextFiles/InSARParameters.txt;;
		"slantRange.txt") parameterFilePath=${RUNDIR}/slantRange.txt;;
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt;;
		"Crop.txt") parameterFilePath=${RUNDIR}/Crop.txt;;
		"CropZoom.txt") parameterFilePath=${RUNDIR}/i12.NoZoom/InSARProducts/CropZoom.txt;;
		"initInSAR.txt") parameterFilePath=${WHERETORUN}/initInSAR.txt;;
		"Read_MAS.txt") parameterFilePath=${RUNDIR}/Read_${MAS}.txt;;
		"Read_SLV.txt") parameterFilePath=${RUNDIR}/Read_${SLV}.txt;;
		"Read_SM.txt") parameterFilePath=${RUNDIR}/Read_${SUPERMASTER}.txt;;
		"bestPlaneRemoval.txt") parameterFilePath=${MASSPROCESSPATHLONG}/${FILESTODETREND}/i12/InSARProducts/bestPlaneRemoval.txt;;
	esac

	ORIGINAL=`updateParameterFile ${parameterFilePath} ${KEY} ${NEW}`
	EchoTee "=> Change in ${parameterFilePath}"
	EchoTee "...Key = ${CRITERIA} "
	EchoTee "...Former Value =  ${ORIGINAL}"
	EchoTee "    --> New Value =  ${NEW}  \n"
	}
	

# Get parameters 
#################################

function GetParamFromFile()
	{
	unset CRITERIA FILETYPE
	local CRITERIA
	local FILETYPE
	CRITERIA=$1
	FILETYPE=$2

	unset parameterFilePath KEY

	local KEY
	local parameterFilePath 

	KEY=`echo ${CRITERIA} | tr ' ' _`
	case ${FILETYPE} in
		# Checked
		"SinglePair_SLCImageInfo.txt") parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${MASDIR}/Info/SLCImageInfo.txt;;
		"SuperMasterCoreg_SLCImageInfo.txt") parameterFilePath=${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/TextFiles/InSARParameters.txt;;
		
		"InSARParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/InSARParameters.txt;;
		"geoProjectionParameters.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt;;
		"SLCImageInfo.txt") parameterFilePath=${RUNDIR}/${MASDIR}/Info/SLCImageInfo.txt;;
		"SuperMaster_SLCImageInfo.txt") parameterFilePath=${INPUTDATA}/${SUPERMASDIR}/Info/SLCImageInfo.txt;;
		"SuperMaster_InSARParameters.txt") parameterFilePath=${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/TextFiles/InSARParameters.txt;;
		"SuperMaster_SLV1_InSARParameters.txt") parameterFilePath=${OUTPUTDATA}/${SUPERMASTER}_${SLV1}/i12/TextFiles/InSARParameters.txt;;
		"SuperMaster_MASMAS_SLCImageInfo.txt") parameterFilePath=${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/TextFiles/masterSLCImageInfo.txt;;
		"SuperMaster_MASSLV_SLCImageInfo.txt") parameterFilePath=${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/TextFiles/slaveSLCImageInfo.txt;;
		"SuperMaster_MAS_SLCImageInfo.txt") parameterFilePath=${OUTPUTDATA}/${SUPERMASTER}_${SLV}/i12/TextFiles/masterSLCImageInfo.txt;;
		"SuperMaster_SLV_SLCImageInfo.txt") parameterFilePath=${OUTPUTDATA}/${SUPERMASTER}_${SLV}/i12/TextFiles/slaveSLCImageInfo.txt;;
		"SuperMasterLOCAL_InSARParameters.txt") parameterFilePath=${MAINRUNDIR}/${SUPERMASTER}_${SLV1}/i12/TextFiles/InSARParameters.txt;;			
		"MASmodImageInfo.txt") parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${MASDIR}/Info/modImageInfo.txt;;
		"SLVmodImageInfo.txt") parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${SLVDIR}/Info/modImageInfo.txt;;
		"masterSLCImageInfo.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/masterSLCImageInfo.txt;;			
		"slaveSLCImageInfo.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/slaveSLCImageInfo.txt;;			
		"slantRange.txt") parameterFilePath=${RUNDIR}/slantRange.txt;;
		"externalSlantRangeDEM.txt") parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${MASDIR}/Info/externalSlantRangeDEM.txt;;
		"externalDEM.txt") parameterFilePath=${DEMDIR}/${DEMNAME}.txt;;
		"SAR_CSL_SLCImageInfo.txt") parameterFilePath=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${MASDIR}/Info/SLCImageInfo.txt;;			
		"SinglePair_SLCImageInfo_ZoomS1.txt") parameterFilePath=${RUNDIR}/i12/TextFiles/masterSLCImageInfo.txt;;

	esac
	updateParameterFile ${parameterFilePath} ${KEY}
	}

function GetAMSTerEngineVersion 
	{
	PATHS1Reader=`which S1DataReader`
	PATHAMSTERENGINE=$(dirname ${PATHS1Reader})
	# suppose that sources are where the installer had put it... 
	eval PATHSOURCES=${PATHAMSTERENGINE}/_Sources_AE/Older/

	if [ -f ${PATHAMSTERENGINE}/_History.txt ]
		then 
			# get version from History file 
			eval LASTVERSIONMT=`head -1 ${PATHAMSTERENGINE}/_History.txt | ${PATHGNU}/grep -Eo "[0-9]{8}"`
		else 
			# get version from last directory 
			LASTDIRINFO=`${PATHGNU}/find ${PATHSOURCES} -maxdepth 1 -type d -name "V*" -printf "%T@ %Tc %p\n"  | sort -n | tail -1 `  # get last creater dir
			#	Get everything after the last /:
			LASTDIRNAME="${LASTDIRINFO##*/}"
			eval LASTVERSIONMT=`echo ${LASTDIRNAME} | cut -d "_" -f1`
	fi
	EchoTee "Last AMSTer Engine version is ${LASTVERSIONMT}"
	}
	
	
# Make figures 
##############

function MakeFig()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local E=$2
		local S=$3
		local TYPE=$4
		local COLOR=$5
		local ML=$6
		local FORMAT=$7
		local FILE=$8
		eval FILE=${FILE}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}
	
function MakeFigR()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local R=$2
		local E=$3
		local S=$4
		local TYPE=$5
		local COLOR=$6
		local ML=$7
		local FORMAT=$8
		local FILE=$9
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}
function MakeFigRAuto()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local R=$2
		local E=$3
		local S=$4
		local TYPE=$5
		local COLOR=$6
		local ML=$7
		local FORMAT=$8
		local FILE=$9
		local MEANIMG
		local STDVIMG
		local MINIMG
		local MAXFIG
		
		MINIMG=$(gdalinfo -stats ${FILE}  | ${PATHGNU}/grep "Mean" | cut -d , -f1 | cut -d = -f 2)
		MEANIMG=$(gdalinfo -stats ${FILE}  | ${PATHGNU}/grep "Mean" | cut -d , -f3 | cut -d = -f 2)
		STDVIMG=$(gdalinfo -stats ${FILE}  | ${PATHGNU}/grep "Mean" | cut -d , -f4 | cut -d = -f 2)
		
		MAXFIG=$(echo "( ${MEANIMG} + (2 * ${STDVIMG}))" | bc)
		R=${MINIMG},${MAXFIG}
		
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}
function MakeFigR3()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH LENGTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local LENGTH=$2
		local R=$3
		local E=$4
		local S=$5
		local TYPE=$6
		local COLOR=$7
		local ML=$8
		local FORMAT=$9
		local FILE=${10}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -L${LENGTH} ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -L${LENGTH} ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}
function MakeFigR3Auto()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH LENGTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local LENGTH=$2
		local R=$3
		local E=$4
		local S=$5
		local TYPE=$6
		local COLOR=$7
		local ML=$8
		local FORMAT=$9
		local FILE=${10}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -L${LENGTH} ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -L${LENGTH} ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}
function MakeFigNoNorm()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local TYPE=$2
		local COLOR=$3
		local ML=$4
		local FORMAT=$5
		local FILE=$6
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}

function MakeFigR2()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH TYPE COLOR ML FORMAT FILE WIDTH2
		local WIDTH=$1
		local TYPE=$2
		local COLOR=$3
		local ML=$4
		local FORMAT=$5
		local FILE=$6
		WIDTH2=`echo "${WIDTH} / 2" | bc`
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} -p1 -P${WIDTH2} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} -p1 -P${WIDTH2} ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}

function MakeFigNoNormFlip()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local TYPE=$2
		local COLOR=$3
		local ML=$4
		local FORMAT=$5
		local FILE=$6
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -m Y ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}	

function MakeFigRflip()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local R=$2
		local E=$3
		local S=$4
		local TYPE=$5
		local COLOR=$6
		local ML=$7
		local FORMAT=$8
		local FILE=$9
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -m Y ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -m Y ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}

function MakeFigflip()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset WIDTH TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local TYPE=$2
		local COLOR=$3
		local ML=$4
		local FORMAT=$5
		local FILE=$6
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -m Y ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -m Y ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
		if [ "${POP}" == "POPyes" ] ; then open ${FILE}.ras ; fi
	fi
	}

# Make Fiji fig - slower than cpxfiddle and creates jpg instead of ras while some fct expect ras. 
# For this reason, this fct is there if you need it but it is unused (and untested on Linux)
function MakeFigFiji()
	{
	if [ "${FIG}" == "FIGyes"  ] ; then
		unset PATHFILE
		unset WIDTH
		unset LENGTH	
		local PATHFILE=$1  
		local WIDTH=$2
		local LENGTH=$3
		FILE=$(basename ${PATHFILE})
		echo "run('Raw...', 'open=${PATHFILE} image=[32-bit Real] width=${WIDTH} height=${LENGTH} little-endian');" > ${FILE}FijiMacroFig.txt
		echo "saveAs('Jpeg', '${FILE}.jpg');" >> ${FILE}FijiMacroFig.txt
		#echo "saveAs('png', '${FILE}.jpg');" >> ${FILE}FijiMacroFig.txt  # too big file 
		echo "run('Quit');"  >> ${FILE}FijiMacroFig.txt
		${PATHGNU}/gsed -i "s/'/\"/g" ${FILE}FijiMacroFig.txt 

		# Check OS
		OS=`uname -a | cut -d " " -f 1 `

		case ${OS} in 
			"Linux") 
				${PATHFIJI}/imagej  --headless -batch ${FILE}FijiMacroFig.txt ;;
			"Darwin")
				${PATHFIJI}/ImageJ-macosx  --headless -batch ${FILE}FijiMacroFig.txt 	;;
		esac			
		# Keep script if one wants to change paramerters of the plot
		#rm ${FILE}FijiMacroFig.txt 
	fi
   	}

# Processing functions
#######################

function ChangeCropCSLImage()
	{
	unset CRITERIA NEW ORIGINAL M
	local CRITERIA=$1
	local NEW=$2
	local ORIGINAL=`grep "${CRITERIA}" ${RUNDIR}/Crop.txt | cut -c 1-15 | tr -dc '[0-9].'`
	EchoTee "=> Change ${CRITERIA} wich was ${ORIGINAL}"
	EchoTee "   in ${NEW} "
	mv ${RUNDIR}/Crop.txt ${RUNDIR}/Crop.txt.tmp
	#change at first occurence only 
 	${PATHGNU}/gawk '/'"${CRITERIA}"'/{if (M==""){sub(/'"${ORIGINAL}"'/, '"${NEW}"');M=1}};{print}' ${RUNDIR}/Crop.txt.tmp > ${RUNDIR}/Crop.txt
	rm ${RUNDIR}/Crop.txt.tmp
	}

function ChangeCropZoomCSLImage()
	{
	unset CRITERIA NEW ORIGINAL M
	local CRITERIA=$1
	local NEW=$2
	local ORIGINAL=`grep "${CRITERIA}" ${RUNDIR}/i12.NoZoom/InSARProducts/CropZoom.txt | cut -c 1-15 | tr -dc '[0-9].'`
	EchoTee "=> Change ${CRITERIA} wich was ${ORIGINAL}"
	EchoTee "   in ${NEW} "
	mv ${RUNDIR}/i12.NoZoom/InSARProducts/CropZoom.txt ${RUNDIR}/i12.NoZoom/InSARProducts/CropZoom.txt.tmp
	#change at first occurence only 
 	${PATHGNU}/gawk '/'"${CRITERIA}"'/{if (M==""){sub(/'"${ORIGINAL}"'/, '"${NEW}"');M=1}};{print}' ${RUNDIR}/i12.NoZoom/InSARProducts/CropZoom.txt.tmp > ${RUNDIR}/i12.NoZoom/InSARProducts/CropZoom.txt
	rm ${RUNDIR}/i12.NoZoom/InSARProducts/CropZoom.txt.tmp
	}

function CheckZOOMasymetry()
	{
 	# Test ZOOM factor format
 	# Regular expression to match a single number (integer or real)
 		single_number_regex='^[0-9]+(\.[0-9]+)?$'
 	# Regular expression to match the format NAzMRg or MRgNAz
 		complex_format_regex='^([0-9]+(\.[0-9]+)?)(Az|Rg)([0-9]+(\.[0-9]+)?)(Az|Rg)$'
 	
 	if [[ ${ZOOM} =~ $single_number_regex ]]
 		then
			EchoTee "ZOOM is a single number: ${ZOOM}, hence Zoom will be the same in Range and Azimuth."
			ZOOMONEVAL="One"	# i.e. ZOOM is made of a single value 	

			ZOOMAZ="${ZOOM}"	# Used e.g. in ReGeocode_SinglePair.sh to test unchanged zoom factor 
	   		ZOOMRG="${ZOOM}"    # Used e.g. in ReGeocode_SinglePair.sh to test unchanged zoom factor

		elif [[ ${ZOOM} =~ $complex_format_regex ]]; then
	 	    EchoTee "ZOOM is made of two numbers, i.e. in Rg and Az."
	
			# Extract number before first marker (Az or Rg), e.g. 1Az2Rg
			FIRST_PART="${ZOOM%%[AR][zg]*}"  	# up to first Az or Rg, e.g. 1
			REMAINDER="${ZOOM#"$FIRST_PART"}"	# from Az or Rg up to Rg or Az, e.g. Az2Rg
			
			# Get which one comes first
			if [[ "$REMAINDER" == Az* ]]
				then
					ZOOMAZ="${FIRST_PART}"				# e.g. 1
				    SECOND_PART="${REMAINDER#Az}"       # e.g. 2Rg
	   				ZOOMRG="${SECOND_PART%Rg}"          # Remove trailing "Rg"
				elif [[ "$REMAINDER" == Rg* ]]; then
	   				ZOOMRG="$FIRST_PART"
	   				SECOND_PART="${REMAINDER#Rg}"       
	   				ZOOMAZ="${SECOND_PART%Az}"
			fi
	    	EchoTee "ZOOM factor in Azimuth direction: $ZOOMAZ"
    		EchoTee "ZOOM factor in Range direction: $ZOOMRG"
			ZOOMONEVAL="Two"	# i.e. ZOOM is made of two values 	
		else
			EchoTee "WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			EchoTee "	ZOOM does not match any expected format: $ZOOM"
			EchoTee "WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    fi	
	}

function CheckFORCEGEOPIXSIZEasymetry()
	{
	# Test FORCEGEOPIXSIZE factor format
	# Regular expression to match a single number (integer or real)
		single_number_regex='^[0-9]+(\.[0-9]+)?$'
	# Regular expression to match the format NAzMRg or MRgNAz
		complex_format_regex='^([0-9]+(\.[0-9]+)?)(Az|Rg)([0-9]+(\.[0-9]+)?)(Az|Rg)$'
	
	if [[ ${FORCEGEOPIXSIZE} =~ $single_number_regex ]]
		then
			EchoTee "FORCEGEOPIXSIZE is a single number: ${FORCEGEOPIXSIZE}, hence the same in Range and Azimuth."
			FORCEGEOPIXSIZEVAL="One"							# i.e. made of only one value
			GEOPIXSIZE=${FORCEGEOPIXSIZE}

			# Dummy; Needed for naming 
			FORCEGEOPIXSIZEAZ=${GEOPIXSIZE}
			FORCEGEOPIXSIZERG=${GEOPIXSIZE}
			GEOPIXSIZEAZ=${GEOPIXSIZE}
			GEOPIXSIZERG=${GEOPIXSIZE}

			EchoTeeYellow "Forced geocoded (squared) pixel size determination. " 
			EchoTeeYellow "Assigned ${GEOPIXSIZE} m. Will also force the limits of the geocoded files."
			EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 	
	

		elif [[ ${FORCEGEOPIXSIZE} =~ $complex_format_regex ]]; then
	 	    EchoTee "FORCEGEOPIXSIZE is made of two numbers, i.e. in Rg and Az."
	
			# Extract number before first marker (Az or Rg), e.g. 1Az2Rg
			FIRST_PART="${FORCEGEOPIXSIZE%%[AR][zg]*}"  	# up to first Az or Rg, e.g. 1
			REMAINDER="${FORCEGEOPIXSIZE#"$FIRST_PART"}"	# from Az or Rg up to Rg or Az, e.g. Az2Rg
			
			# Get which one comes first
			if [[ "$REMAINDER" == Az* ]]
				then
					FORCEGEOPIXSIZEAZ="${FIRST_PART}"				# e.g. 1
				    SECOND_PART="${REMAINDER#Az}"       # e.g. 2Rg
	   				FORCEGEOPIXSIZERG="${SECOND_PART%Rg}"          # Remove trailing "Rg"
				elif [[ "$REMAINDER" == Rg* ]]; then
	   				FORCEGEOPIXSIZERG="$FIRST_PART"
	   				SECOND_PART="${REMAINDER#Rg}"       
	   				FORCEGEOPIXSIZEAZ="${SECOND_PART%Az}"
			fi
			FORCEGEOPIXSIZEVAL="Two"							# i.e. not made of only one value
	
			EchoTeeYellow "Forced geocoded (not squared) pixel size determination. " 
			EchoTeeYellow "Assigned ${FORCEGEOPIXSIZEAZ} m in Az and ${FORCEGEOPIXSIZERG} m in Rg . Will also force the limits of the geocoded files."
			EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 	

			# Dummy; Needed for naming ?
			GEOPIXSIZEAZ=${FORCEGEOPIXSIZEAZ}
			GEOPIXSIZERG=${FORCEGEOPIXSIZERG}

		else
			EchoTee "WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			EchoTee "	FORCEGEOPIXSIZE does not match any expected format: $FORCEGEOPIXSIZE"
	 		EchoTee "	... "
	 		exit 1
			EchoTee "WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	fi	
	}


# Crop and zoom ; parameter = MAS or SLV
function Crop()
	{
	unset IMG
	local IMG=$1 # Primary or Secondary image date to crop and zoom
	cutAndZoomCSLImage ${RUNDIR}/Crop.txt -create
	ChangeParam "Input file path in CSL format" ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${IMG}.csl Crop.txt
	ChangeParam "Output file path" ${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${IMG}.csl Crop.txt
	#ChangeParam "Coordinate system [SRA / GEO]" GEO Crop.txt
	#ChangeParam "Coordinate system [SRA / GEO]" SRA Crop.txt
	ChangeParam "Coordinate system [SRA / GEO]" ${COORDSYST} Crop.txt
	ChangeCropCSLImage "lower left corner X coordinate" ${FIRSTP}
	ChangeCropCSLImage "lower left corner Y coordinate" ${FIRSTL}
	ChangeCropCSLImage "upper right corner X coordinate" ${LASTP}
	ChangeCropCSLImage "upper right corner Y coordinate" ${LASTL}

	CheckZOOMasymetry
	
	if [ "${ZOOMONEVAL}" == "One" ]
		then
			ChangeCropCSLImage "X zoom factor" ${ZOOM}
			ChangeCropCSLImage "Y zoom factor" ${ZOOM}
		else 
			ChangeCropCSLImage "X zoom factor" ${ZOOMRG}
			ChangeCropCSLImage "Y zoom factor" ${ZOOMAZ}
	fi 	

	cutAndZoomCSLImage ${RUNDIR}/Crop.txt
	mv ${RUNDIR}/Crop.txt ${RUNDIR}/Crop_${IMG}.txt	
	}
	
# useful to stay consistent with older time series of ampli image
function CropAtZeroAlt()
	{
	unset IMG
	local IMG=$1 # Primary or Secondary image date to crop and zoom
	cutAndZoomCSLImage ${RUNDIR}/Crop.txt -create
	ChangeParam "Input file path in CSL format" ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${IMG}.csl Crop.txt
	ChangeParam "Output file path" ${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${IMG}.csl Crop.txt
	ChangeParam "Coordinate system [SRA / GEO]" ${COORDSYST} Crop.txt
	ChangeCropCSLImage "lower left corner X coordinate" ${FIRSTP}
	ChangeCropCSLImage "lower left corner Y coordinate" ${FIRSTL}
	ChangeCropCSLImage "upper right corner X coordinate" ${LASTP}
	ChangeCropCSLImage "upper right corner Y coordinate" ${LASTL}

	CheckZOOMasymetry
	
	if [ "${ZOOMONEVAL}" == "One" ]
		then
			ChangeCropCSLImage "X zoom factor" ${ZOOM}
			ChangeCropCSLImage "Y zoom factor" ${ZOOM}
		else 
			ChangeCropCSLImage "X zoom factor" ${ZOOMRG}
			ChangeCropCSLImage "Y zoom factor" ${ZOOMAZ}
	fi

	cutAndZoomCSLImage ${RUNDIR}/Crop.txt -e
	mv ${RUNDIR}/Crop.txt ${RUNDIR}/Crop_${IMG}.txt	
	}
	
# Init InSAR with Bistatic Check
function MakeInitInSAR()
	{
	unset CSLDATA WHERETORUN CROPKML	
	local CSLDATA=$1 		# dir for data in csl format, eg ${RUNDIR} for Single Pair or ${INPUTPATH} for Mass Process
	local WHERETORUN=$2 	# where to run InSAR, eg ${RUNDIR} or ${RUNDIR}/${SUPERMAS}_${SLV}
	local CROPKML=$3 		# kml file used for S1 image as a pseudo crop
	
	if [ "${CROP}" != "CROPyes" ] && [ "${CROP}" != "CROPno" ] 
		then 
			# Hence suppose a kml is provided 
			initInSAR ${CSLDATA}/${MASDIR} ${CSLDATA}/${SLVDIR} ${WHERETORUN}/i12 ${CROPKML} P=${INITPOL}
		else 
			initInSAR ${CSLDATA}/${MASDIR} ${CSLDATA}/${SLVDIR} ${WHERETORUN}/i12 P=${INITPOL}
	fi
	}
	
# Depending on the choice, it will recompute the DEM and/or the mask for IMGWITHDEM 
function ManageDEM()
	{
 
	CheckZOOMasymetry
	
	if [ "${ZOOMONEVAL}" == "One" ]
		then
			if [ "${ZOOM}" == "1"  ]
				then 
					ZOOMONE="Yes"
				else 
					ZOOMONE="No"
			fi
		else 
			if [ "${ZOOMAZ}" == "1"  ] && [ "${ZOOMRG}" == "1"  ] 
				then 
					ZOOMONE="Yes"
				else 
					ZOOMONE="No"
			fi
	fi
 

	if [ "${SATDIR}" == "S1" ]  && [ "${S1MODE}" == "WIDESWATH" ] && [ "${ZOOMONE}" == "No"  ] ; then 
		IMGWITHDEM=${MASNAME}
	fi
	case ${RECOMPDEM} in
		"FORCE") 
			EchoTee " You chose to compute the DEM (and MASK if requested) in slant range, even if it (they) may already exist."
			EchoTee "--------------------------------"
			EchoTee ""
			MasterDEM.sh ${IMGWITHDEM} ${PARAMFILE}  
			;;    
		"KEEP") 
			EchoTee " You chose to keep existing  DEM (and MASK if requested) in slant range. "
			EchoTee "--------------------------------"
			EchoTee ""
			if [ ! -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/externalSlantRangeDEM ] ; then
					EchoTee " But it does not exist in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/externalSlantRangeDEM. "
					EchoTee "  Recompute it here. "
					
					# If IMGWITHDEM is S1 name without .csl (from SuperMaster_MassProc.sh), add csl extension here then extract only date
					if [[ ${IMGWITHDEM} == *"S1"* ]] && [[ ${IMGWITHDEM} != *".csl"* ]]; then IMGWITHDEM=${IMGWITHDEM}.csl ; IMGWITHDEM=`GetDateCSL ${IMGWITHDEM}` ; fi
		
					MasterDEM.sh ${IMGWITHDEM} ${PARAMFILE}
				else
					if [ "${APPLYMASK}" == "APPLYMASKyes" ] ; then 
							EchoTee " externalSlantRangeDEM exist for ${IMGWITHDEM}, and you want a mask. "
							if [ -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask_${MASKBASENAME} ] 
								then 
									EchoTee " slantRangeMask_${MASKBASENAME} exist,"

									# Check that if detrend masks are requeted, they are all projected
									# If maskbasename contains NoAllDetrend 
									if [[ "${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask_${MASKBASENAME}" == *"NoAllDetrend"* ]]
										then
 											EchoTee " and do not expect Detrend masks. No need to recompute here"
 											EchoTee " I will update the link to appropriate existing slantRangeMask.   \n"
											rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask
											ln -sf ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask_${MASKBASENAME} ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask
											cp -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM_${MASKBASENAME}.txt ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM.txt
 										else 
  											EchoTee " and expect Detrend masks. Check if they are all already in slant range in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/:"

 											# check that all masks (with or without extension) in ${PATHTODIREVENTSMASKS} are projected in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/
 											# if not, reproject the DEM and masks
 											
 											# Flag for tracking missing files
											missing_files=false

 											# masks must be envi files with hdr extensions. List them all from  ${PATHTODIREVENTSMASKS}
 											for files in `find  ${PATHTODIREVENTSMASKS} -maxdepth 1 -type f -name "*.hdr"` ; do		# list all mask.hdr files with path 
 												# seach corresponding mask file (with or without extension)
 												base_name_hdr="${files##*/}"  							# mask header without path
												filename_hdr_no_ext="${base_name_hdr%.*}"				# mask header without path and without .hdr
 												
 												mask_file=$(${PATHGNU}/find "${PATHTODIREVENTSMASKS}" -maxdepth 1 -type f -name "${filename_hdr_no_ext}*" ! -name "${filename_hdr_no_ext}.hdr")	# full path to mask (with or without extension)
 												base_name_mask_file=$(basename "$mask_file")																								# mask name (with or without extension)
 												if [[ -f "${mask_file}" ]]
 													then
 														# mask corresponding to hdr file exist, hence it must be tested if present in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/
 														if [[ -f "${INPUTDATA}/${IMGWITHDEM}.csl/Data/${base_name_mask_file}" ]]
															then
																EchoTee "	Mask ${base_name_mask_file} in slant range is in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/"
															else
																EchoTee "	No mask ${base_name_mask_file} in slant range is in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/"
																missing_files=true
														fi
  													else
 														 EchoTee "Mask ${mask_file} corresponding to hdr file does not exist, hence it is not a valid mask to test"
 												fi
 											done
											
											if [ ${missing_files} == "true" ]
												then
													EchoTee " Not all the requested Detrend masks in ${PATHTODIREVENTSMASKS} are in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/."
													EchoTee "  Hence, I recompute the DEM and masks projection here. "
													
													# If IMGWITHDEM is S1 name without .csl (from SuperMaster_MassProc.sh), add csl extension here then extract only date
													if [[ ${IMGWITHDEM} == *"S1"* ]] &&  [[ ${IMGWITHDEM} != *".csl"* ]]; then IMGWITHDEM=${IMGWITHDEM}.csl ; IMGWITHDEM=`GetDateCSL ${IMGWITHDEM}` ; fi
						
													MasterDEM.sh ${IMGWITHDEM} ${PARAMFILE}
												else
													EchoTee " All detrend masks in ${PATHTODIREVENTSMASKS} are in ${INPUTDATA}/${IMGWITHDEM}.csl/Data/. No need to recompute here"

 													EchoTee " I will update the link to appropriate existing slantRangeMask, just in case.   \n"
													rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask
													ln -sf ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask_${MASKBASENAME} ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask
													cp -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM_${MASKBASENAME}.txt ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM.txt

											fi
									fi
								else 
									EchoTee " externalSlantRangeDEM did exist but not the requested mask ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask_${MASKBASENAME}."
									EchoTee "  Recompute it here. "
									
									# If IMGWITHDEM is S1 name without .csl (from SuperMaster_MassProc.sh), add csl extension here then extract only date
									if [[ ${IMGWITHDEM} == *"S1"* ]] &&  [[ ${IMGWITHDEM} != *".csl"* ]]; then IMGWITHDEM=${IMGWITHDEM}.csl ; IMGWITHDEM=`GetDateCSL ${IMGWITHDEM}` ; fi

									MasterDEM.sh ${IMGWITHDEM} ${PARAMFILE}
							fi
						else 
							EchoTee " externalSlantRangeDEM exist for ${IMGWITHDEM}, and you do not want a mask. Clean possible mask links."
							rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask		
							# and rename externalSlantRangeDEM.txt
							if [ -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM_NoMask.txt ] 		# not necessary with new dem/mask managment  
								then 
									cp -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM_NoMask.txt ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM.txt
							fi
					fi
			fi	;;   	
		*) 
			EchoTeeRed " I do not understand if you want to recompute the DEM (and maybe the MASK) in (Global)Primary slant range. Will do it anyway.  \n"
			MasterDEM.sh ${IMGWITHDEM} ${PARAMFILE}  
			;;    
	esac
	echo
	}	
	
# update the parameters in slantRange.txt
function UpdateSlantRangeTXT()
	{
	unset CSLDATALOC 
	local CSLDATALOC=$1

	# Path to master.csl directory
		if [ "${CSLDATALOC}" == "PAIR" ]
			then
				ChangeParam "Reference slant range image path in CSL format" ${INPUTDATA}/${MASDIR} slantRange.txt
			else # [ "${CSLDATALOC}" == "SUPERMASTER" ]
				ChangeParam "Reference slant range image path in CSL format" ${INPUTDATA}/${SUPERMASDIR} slantRange.txt		
		fi
	# Path to DEM and its info (coordinates, size and sampling)
		EchoTee "DEM is ${DEMNAME}" 
		ChangeParam "Georeferenced DEM file path" ${DEMDIR}/${DEMNAME} slantRange.txt
	
		DEMDIRNAMENOEXT=`echo ${DEMDIR}/${DEMNAME} | ${PATHGNU}/grep -Eo '.*[.]'`
		if [ -f ${DEMDIR}/${DEMNAME}.hdr ] || [ -f ${DEMDIRNAMENOEXT}hdr ] 
			then
				EchoTee "Update slantRange.txt from DEM hdr file. (DEM, as it has a hdr file, must be in GIS order)."
				SAMPLEDEGSC=`cat ${DEMDIR}/${DEMNAME}.hdr | ${PATHGNU}/grep info | cut -d , -f 6`
				#SAMPLEDEG=$(printf "%.20f" $SAMPLEDEGSC)  # avoid scientific exp format
				SAMPLEDEG=`echo "$SAMPLEDEGSC" | ${PATHGNU}/gawk '{printf("%0.20f",$0);}'`  # avoid scientific exp format
				SAMPLDEM=`echo "( ${SAMPLEDEG} * 40000000 ) / 360 " | bc `
				echo " SAMPLDEM is ${SAMPLDEM}"
			else
	####### New here			
				#if ${PATHGNU}/grep -q "Georeferenced mask file path" slantRange.txt
				if ${PATHGNU}/grep -q "Georeferenced mask file path" ${RUNDIR}/slantRange.txt
					then
						# if ${RUNDIR}/slantRange.txt contains line with "Georeferenced mask file path"
						#    it is the old version of AMSTer Engine slantRangeDEM fonction 
						#    and one must provide the dimensions, sampling and corner Lon Lat
						XDEMDIM=`GetParamFromFile "X (longitude) dimension [pixels]" externalDEM.txt`
						ChangeParam "X (longitude) dimension [pixels]" ${XDEMDIM} slantRange.txt
						YDEMDIM=`GetParamFromFile "Y (latitude) dimension [pixels]" externalDEM.txt` 
						ChangeParam "Y (latitude) dimension [pixels]" ${YDEMDIM} slantRange.txt
		
						LLLON=`GetParamFromFile "Lower left corner longitude [dd]" externalDEM.txt`
						ChangeParam "Lower left corner longitude [dd]" ${LLLON} slantRange.txt
						LLLAT=`GetParamFromFile "Lower left corner latitude [dd]" externalDEM.txt`
						ChangeParam "Lower left corner latitude [dd]" ${LLLAT} slantRange.txt
		
						LONSAMPDEMSC=`GetParamFromFile "Longitude sampling [dd]" externalDEM.txt`  # i.e. from externalDEM.txt=${DEMDIR}/${DEMNAME}.txt
						ChangeParam "Longitude sampling [dd]" ${LONSAMPDEMSC} slantRange.txt
						LATSAMPDEM=`GetParamFromFile "Latitude sampling [dd]" externalDEM.txt`
						ChangeParam "Latitude sampling [dd]" ${LATSAMPDEM} slantRange.txt
				
						#LONSAMPDEM=$(printf "%.20f" $LONSAMPDEMSC)  # avoid scientific exp format
						LONSAMPDEM=`echo "$LONSAMPDEMSC" | ${PATHGNU}/gawk '{printf("%0.20f",$0);}'`  # avoid scientific exp format
		
						SAMPLDEM=`echo "( ${LONSAMPDEM} * 40000000 ) / 360 " | bc ` 					
					else
						# if not, it is the version of AMSTer Engine slantRangeDEM fonction > June 2024
						#    and there is no need to provide the dimensions, sampling and corner Lon Lat
						#    though we compute the values just in case....
						XDEMDIM=`GetParamFromFile "X (longitude) dimension [pixels]" externalDEM.txt`
						YDEMDIM=`GetParamFromFile "Y (latitude) dimension [pixels]" externalDEM.txt` 
		
						LLLON=`GetParamFromFile "Lower left corner longitude [dd]" externalDEM.txt`
						LLLAT=`GetParamFromFile "Lower left corner latitude [dd]" externalDEM.txt`
		
						LONSAMPDEMSC=`GetParamFromFile "Longitude sampling [dd]" externalDEM.txt`  # i.e. from externalDEM.txt=${DEMDIR}/${DEMNAME}.txt
						LATSAMPDEM=`GetParamFromFile "Latitude sampling [dd]" externalDEM.txt`
				
						#LONSAMPDEM=$(printf "%.20f" $LONSAMPDEMSC)  # avoid scientific exp format
						LONSAMPDEM=`echo "$LONSAMPDEMSC" | ${PATHGNU}/gawk '{printf("%0.20f",$0);}'`  # avoid scientific exp format
		
						SAMPLDEM=`echo "( ${LONSAMPDEM} * 40000000 ) / 360 " | bc ` 					
						
				fi



		fi	
	# Reduction factor for DEM pix 
		EchoTee " Pix size no ML : ${AZSAMP} x ${RGSAMP} meters (from SLCImageInfo.txt)"
		EchoTee " ML Pix size : ${PIXSIZEAZ} x ${PIXSIZERG} meters."
		EchoTee " A DEM reduction factor of 2 means : 1 point of DEM every 2 pixels of non ML image"
		# Compute Rounded pix size for comp. Test the smallest pixel side : rg or az.
		ROUNDEDAZSAMP=`echo ${AZSAMP} | xargs printf "%.*f\n" 0`  # (AzPixSize) rounded to 0th digits precision
		ROUNDEDRGSAMP=`echo ${RGSAMP} | xargs printf "%.*f\n" 0`  # (RgPixSize) rounded to 0th digits precision
		if [ ${ROUNDEDAZSAMP} -ge ${ROUNDEDRGSAMP} ]
			then SMALLEST=${ROUNDEDRGSAMP}
			else SMALLEST=${ROUNDEDAZSAMP}
		fi
		# Test the smallest side of pixel (rg or az) against size of DEM pixel (DEM pix is square)
		if [ ${SMALLEST} -ge ${SAMPLDEM} ]
			then 
				EchoTee "Smallest (rounded) pix size is ${SMALLEST} m and  DEM pix size is ${SAMPLDEM}."		
				EchoTee "==> Reduction factor for DEM can be fixed to 1 "	
				# MUSTE BE OF THE SAME SHAPE AS ORIGINAL PIX SHAPE => use RatioPix 
				RatioPix 1
				ChangeParam "Range reduction factor" ${RGML} slantRange.txt
				ChangeParam "Azimuth reduction factor" ${AZML} slantRange.txt
				unset RGML
				unset AZML
			else 
				EchoTee "Smallest (rounded) pix size is ${SMALLEST} m and  DEM pix size is ${SAMPLDEM}."	
				#TARGETRESOL=`echo "(${SAMPLDEM} / 3.5)" | bc | ${PATHGNU}/gsed "s/,/./" | cut -d . -f1`  # rounded to Integer part
				# modified on june 9 2016 DD
				TARGETRESOL=`echo "(${SAMPLDEM} * (s((${INCIDANGL} * 3.1415927) / 180)) )" | bc -l `  
				
				DEMREDUCAZ=`echo "(${SAMPLDEM} / ${AZSAMP}) * 0.8" | bc -l | xargs printf "%.*f\n" 0` # 0.8 is an arbitrary factor for oversampling the DEM; value is rounded
				DEMREDUCRG=`echo "(${TARGETRESOL} / ${RGSAMP}) * 0.8" | bc -l | xargs printf "%.*f\n" 0` # 0.8 is an arbitrary factor for oversampling the DEM; value is rounded
		
				if [ ${DEMREDUCAZ} -eq "0" ] ; then DEMREDUCAZ="1" ; fi 
				if [ ${DEMREDUCRG} -eq "0" ] ; then DEMREDUCRG="1" ; fi 

				ChangeParam "Range reduction factor" ${DEMREDUCRG} slantRange.txt
				ChangeParam "Azimuth reduction factor" ${DEMREDUCAZ} slantRange.txt
		fi
   	}	
   	
# compute the external DEM in Slant Range
function SlantRangeExtDEM()
	{
	unset CSLDATALOC BLANKRUN
	local CSLDATALOC=$1 	# If csl format is in ${RUNDIR}, keep SLCImageInfo.txt ; if in ${RESAMPDATAPATH}, put SuperMaster_SLCImageInfo.txt
	local BLANKRUN=$2		#  If BLANKRUN = BlankRunYes, change info in slantRange.txt but do not reporcess the slantRange				
		
	EchoTee "Slant range referencing of external DEM:"
	slantRangeDEM ${RUNDIR}/slantRange.txt -create

	# update path to master.csl, DEM name and related info, reduction factor
	UpdateSlantRangeTXT ${CSLDATALOC}    
	EchoTee ""
	if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
		then 
			if ${PATHGNU}/grep -q "Georeferenced mask file path" ${RUNDIR}/slantRange.txt	# i.e. created with AMSTerEngine < June 2024. Expects 1 mask
				then
					EchoTeeYellow "${RUNDIR}/slantRange.txt was created using AMSTerEngine V < June 2024" 
					if [ "${PATHTOMASK}" != "" ]
						then 
							EchoTeeYellow "and mask was defined in LaunchMTParam.txt file version 20231026 as PATHTOMASK as expected. " 
							EchoTee ""
							# if path to mask is PATHTOMASK, then it a parameter file V20231026 and a mask at one or more level:
							EchoTeeYellow "Following geocoded mask will be used :"
							EchoTeeYellow " ${PATHTOMASK}" 
							EchoTeeYellow "Be sure that it is at least larger than the area of interest." 
							
						else
							EchoTeeYellow "and mask was defined as PATHTOMASKGEOC and/or PATHTOMASKCOH and/or PATHTOMASKDETREND,  " 
							EchoTeeYellow " that is LaunchMTParam.txt file version 20241015 or after. "
							EchoTee ""

							if [ "${PATHTOMASKGEOC}" != "" ] || [ "${PATHTOMASKCOH}" != "" ] || [ "${PATHTOMASKDETREND}" != "" ]
								then 
									# if path to mask is PATHTOMASKGEOC and/or PATHTOMASKCOH and/or PATHTOMASKDETREND, 
									# then it a parameter file V20241015 and (a) mask(s) at one or more level:
									
									# Create an array with non-empty values
									non_empty_paths=()
									
									# Add non-empty variables to the array
									[ -n "${PATHTOMASKGEOC}" ] && non_empty_paths+=("${PATHTOMASKGEOC}")
									[ -n "${PATHTOMASKCOH}" ] && non_empty_paths+=("${PATHTOMASKCOH}")
									[ -n "${PATHTOMASKDETREND}" ] && non_empty_paths+=("${PATHTOMASKDETREND}")
									
									# Check if all non-empty values are the same
									if [ $(printf "%s\n" "${non_empty_paths[@]}" | uniq | wc -l) -eq 1 ]
										then
									    	# All non-empty values are the same
									    	PATHTOMASK=${non_empty_paths[0]}
									    	EchoTeeYellow "This is not a problem as only one mask is used. Set it as PATHTOMASK."
											EchoTeeYellow "Following geocoded mask will be used :"

									    	EchoTeeYellow " ${PATHTOMASKGEOC}" 
										else
									    	EchoTeeRed "This is not as expected. Let's try by using only the first one and set it as PATHTOMASK"
									    	EchoTeeRed "Check yourself if it is OK."
											EchoTeeYellow "Following geocoded mask will be used :"
									    	PATHTOMASK=${non_empty_paths[0]}
									    	EchoTeeYellow " ${PATHTOMASKGEOC}" 
									fi
								else 
									EchoTeeRed "This is not as expected. You asked for masking but no PATHTOMASK mask is provided in LaunchMTParam.txt "
							fi
					fi
					ChangeParam "Georeferenced mask file path" ${PATHTOMASK} slantRange.txt
	
				else		# No mention of "Georeferenced mask file path" in slantRange.txt, i.e. created with AMSTerEngine > June 2024
					EchoTeeYellow "${RUNDIR}/slantRange.txt was created using AMSTerEngine V > June 2024" 

					if [ "${PATHTOMASK}" != "" ]
						then 
							EchoTeeYellow "but mask was defined in LaunchMTParam.txt as PATHTOMASK (i.e. file version =< 20231026)" 
							EchoTeeYellow "  instead of PATHTOMASKGEOC and/or PATHTOMASKCOH and/or PATHTOMASKDETREND as expected. " 
							EchoTeeYellow "This might not be a problem. "
							EchoTeeRed 	  "I will attempt to assign the masking value(s) in a logical way, that is: "
							EchoTeeRed 	  "		1 (if any) for Geographical mask (water bodies, ...) " 
							EchoTeeRed 	  "		2 (if any) for Thresholded coherence mask " 
							EchoTeeRed 	  "		3 (if any) for Detrend masked areas " 
							EchoTeeRed 	  "Check yourself if it is OK. " 
							EchoTee ""
							# test if contains 1
							if ${PATHGNU}/grep -qP "\x01" ${PATHTOMASK}
								then 
									EchoTeeYellow "The mask ${PATHTOMASK} contains 1. Use it as Geographical mask; set masking value to 1. " 
									ChangeParam "Mask file path 1: Geographical mask (water bodies, ...)" ${PATHTOMASK} slantRange.txt
									ChangeParam "Masking value 1" 1 slantRange.txt	# 1 = always masked
								else 
									EchoTeeYellow "The mask ${PATHTOMASK} contains no 1." 
							fi
	
							# test if contains 2
							if ${PATHGNU}/grep -qP "\x02" ${PATHTOMASK}
								then 
									EchoTeeYellow "The mask ${PATHTOMASK} contains 2. Use it as Thresholded coherence mask; set masking value to 2. " 
									ChangeParam "Mask file path 2: Thresholded coherence mask" ${PATHTOMASK} slantRange.txt
									ChangeParam "Masking value 2" 2 slantRange.txt	# 2 = mask at unwrap if below cohrence threshold
								else 
									EchoTeeYellow "The mask ${PATHTOMASK} contains no 2." 
							fi

							# test if contains 3
							if ${PATHGNU}/grep -qP "\x03" ${PATHTOMASK}
								then 
									EchoTeeYellow "The mask ${PATHTOMASK} contains 3. Use it as mask for Detrend areas; set masking value to 3. " 
									ChangeParam "Mask file path 3: Detrend masked areas" ${PATHTOMASK} slantRange.txt
									ChangeParam "Masking value 3" 3 slantRange.txt	# 3 = masked at Detrend step 
								else 
									EchoTeeYellow "The mask ${PATHTOMASK} contains no 3." 
							fi
						else
							if [ "${PATHTOMASKGEOC}" != "" ] || [ "${PATHTOMASKCOH}" != "" ] || [ "${PATHTODIREVENTSMASKS}" != "" ]
								then 
									EchoTeeYellow "and mask(s) was(were) defined as expected in LaunchMTParam.txt as PATHTOMASKGEOC and/or PATHTOMASKCOH and/or PATHTOMASKDETREND. " 
									# test if contains 1
									if [ "${PATHTOMASKGEOC}" != "" ]
										then 
											EchoTeeYellow "The following mask will be used as Geographical mask (i.e. always masked, e.g. water bodies): " 
											EchoTeeYellow "  ${PATHTOMASKGEOC}" 
											EchoTeeYellow "With the following masking value (usually 1):  " 
											EchoTeeYellow "  ${DATAMASKGEOC}" 

											ChangeParam "Mask file path 1: Geographical mask (water bodies, ...)" ${PATHTOMASKGEOC} slantRange.txt
											ChangeParam "Masking value 1" ${DATAMASKGEOC} slantRange.txt	# 1 = always masked
										else 
											EchoTeeYellow "No Geographical mask defined." 
									fi

									if [ "${PATHTOMASKCOH}" != "" ]
										then 
											EchoTeeYellow "The following mask will be used as Thresholded coherence mask (at unwrapping): " 
											EchoTeeYellow "  ${PATHTOMASKCOH}" 
											EchoTeeYellow "With the following masking value (usually 2):  " 
											EchoTeeYellow "  ${DATAMASKGEOC}" 

											ChangeParam "Mask file path 2: Thresholded coherence mask" ${PATHTOMASKCOH} slantRange.txt
											ChangeParam "Masking value 2" ${DATAMASKCOH} slantRange.txt	# 2 = mask at unwrap if below cohrence threshold
										else 
											EchoTeeYellow "No Thresholded coherence mask defined." 
									fi

									if [ "${PATHTODIREVENTSMASKS}" != "" ]
										then 
											EchoTeeYellow "All the mask(s) named eventMaskYYYYMMDDThhmmss_YYYYMMDDThhmmss(.hdr) in "
											EchoTeeYellow "  ${PATHTODIREVENTSMASKS}" 
											EchoTeeYellow "with dates included in the Primary-Secondary range of dates will be used to mask areas at Detrend."

											EchoTeeYellow "With the following masking value (usually 3):  " 
											EchoTeeYellow "  ${DATAMASKEVENTS}" 

											ChangeParam "Per date detrend mask files directory" ${PATHTODIREVENTSMASKS} slantRange.txt
											ChangeParam "Event masks masking value" ${DATAMASKEVENTS} slantRange.txt	# 3 = masked at Detrend step 
										else 
											EchoTeeYellow "No mask defined to mask areas at Detrend." 
									fi

								else 
									EchoTeeRed "This is not as expected. You asked for masking but no PATHTOMASKGEOC and/or PATHTOMASKCOH and/or PATHTOMASKDETREND is provided in LaunchMTParam.txt "
							
							fi
					fi
			fi
			
		else 
			EchoTee "No geocoded mask will be used"	
			# remove possible existing mask
			rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask
#			rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/slantRangeMask.txt	
			if [ -f "${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM_NoMask.txt" ] && [ -f "${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM.txt" ] ; then cp -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM_NoMask.txt ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM.txt ; fi			
	fi
	EchoTee ""

	# Run the slantRangeDEM if needed
	if [ ${BLANKRUN} == "BlankRunYes" ]
		then
			EchoTee ""
			EchoTee "SlantRange.txt was updated."
			EchoTee ""
		else	
			EchoTee "To be certain to force the projection of the DEM (and mask if required); delete: "
			EchoTee "  ${INPUTDATA}/${IMGWITHDEM}.csl/Data/externalSlantRangeDEM "
			EchoTee "  ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask "
			EchoTee "  and their Info txt file"
			EchoTee ""

			rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/externalSlantRangeDEM
			rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM.txt
			rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask
#			rm -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/slantRangeMask.txt			
			if [ ${SIMAMP} == "SIMAMPyes" ]
				then 
					slantRangeDEM ${RUNDIR}/slantRange.txt -s | tee -a ${LOGFILE}  # Usually not needed maybe for coreg ERS

					SLTRGDEMX=`GetParamFromFile "X size of projected products [pix]" externalSlantRangeDEM.txt`
					SLTRGDEMY=`GetParamFromFile "Y size of projected products [pix]" externalSlantRangeDEM.txt`
					# Reduce resolution of External Slant Range DEM raster fig by factor 5 to spare disk space
					case ${CSLDATALOC} in
						"PAIR")
							MakeFigR ${SLTRGDEMX} 0,1000 2 5 normal gray ${PIXFORMY}/${PIXFORMX} r4 ${INPUTDATA}/${MASDIR}/Data/simulatedAmplitude 
							MakeFigR3 ${SLTRGDEMX} ${SLTRGDEMY} 0,10000 1.0 1.0 normal jet 5/5 r4 ${INPUTDATA}/${MASDIR}/Data/externalSlantRangeDEM  ;;
						"SUPERMASTER")
							MakeFigR ${SLTRGDEMX} 0,1000 2 5 normal gray 5/5 r4 ${INPUTDATA}/${SUPERMASTER}.csl/Data/simulatedAmplitude
							MakeFigR3 ${SLTRGDEMX} ${SLTRGDEMY} 0,10000 1.0 1.0 normal jet ${MLFACTORFORFIG1}/${MLFACTORFORFIG2} r4 ${INPUTDATA}/${SUPERMASTER}.csl/Data/externalSlantRangeDEM ;;
					esac	
				else
					slantRangeDEM ${RUNDIR}/slantRange.txt | tee -a ${LOGFILE}
			fi  	# end of SIMAMP test

 			case ${APPLYMASK} in
				"APPLYMASKyes")
					if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ] && [ "${ZOOM}" != "1" ] 
						then 
							# rename Mask with mask name and create link with default mask file 
							mv -f ${RUNDIR}/i12.NoZoom/InSARProducts/${IMGWITHDEM}.Z.csl/Data/slantRangeMask ${RUNDIR}/i12.NoZoom/InSARProducts/${IMGWITHDEM}.Z.csl/Data/slantRangeMask_${MASKBASENAME}
							ln -sf ${RUNDIR}/i12.NoZoom/InSARProducts/${IMGWITHDEM}.Z.csl/Data/slantRangeMask_${MASKBASENAME} ${RUNDIR}/i12.NoZoom/InSARProducts/${IMGWITHDEM}.Z.csl/Data/slantRangeMask
							# copy Mask.txt to name with mask name - since new multi level masks, there is no more slantRangeMask.txt. Instead, everything is in externalSlantRangeDEM.txt
							cp -f ${RUNDIR}/i12.NoZoom/InSARProducts/${IMGWITHDEM}.Z.csl/Info/externalSlantRangeDEM.txt ${RUNDIR}/i12.NoZoom/InSARProducts/${IMGWITHDEM}.Z.csl/Info/externalSlantRangeDEM_${MASKBASENAME}.txt
						else 
							# rename Mask with mask name and create link with default mask file 
							mv -f ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask_${MASKBASENAME}
							ln -sf ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask_${MASKBASENAME} ${INPUTDATA}/${IMGWITHDEM}.csl/Data/slantRangeMask
							# copy Mask.txt to name with mask name - since new multi level masks, there is no more slantRangeMask.txt. Instead, everything is in externalSlantRangeDEM.txt
							cp -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM.txt ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM_${MASKBASENAME}.txt
					fi
					;;
				"APPLYMASKno")
					if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ] && [ "${ZOOM}" != "1" ] 
						then 
							cp -f ${RUNDIR}/i12.NoZoom/InSARProducts/${IMGWITHDEM}.Z.csl/Info/externalSlantRangeDEM.txt ${RUNDIR}/i12.NoZoom/InSARProducts/${IMGWITHDEM}.Z.csl/Info/externalSlantRangeDEM_NoMask.txt
						else 
							cp -f ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM.txt ${INPUTDATA}/${IMGWITHDEM}.csl/Info/externalSlantRangeDEM_NoMask.txt
					fi
					# Do nothing 
					;;
				*)
					EchoTeeRed " Please revise ParametersFile.txt as I do not recognize APPLYMASKyes or APPLYMASKyes value for APPLYMASK param."
					EchoTeeRed "  By default I apply APPLYMASKno here." ;;
			esac			
 	fi 		# end of BlankRun test
	}	
	
	
# Change value of parameters depending on the ratio between Range and Az pixel size	
#   Parameter : ML factor to adapt to pixel size ratio
function RatioPix()
	{
	unset MLTEMP 
	local MLTEMP=$1 # ML factor to adapt
	EchoTee "- - - Compute ratio and transform input parameters in Range and Azimuth to get square pix - - -" 
	# Ratio is not the same for ERS/ENVISAT than S1
	if [ "${RATIO}" -eq 1 ] 
		then 
			EchoTee "Az sampling (${AZSAMP}m) is similar to Range sampling (${RGSAMP}m)." 
			EchoTee "   Probably processing square pixel data such as RS, CSK or TSX." 
			EchoTee "Uses following Azimuth and Range factors: ${MLTEMP} and ${MLTEMP}"
			RGML=${MLTEMP}
			AZML=${MLTEMP}	
		else
			RET=$(echo "$RGSAMP < $AZSAMP" | bc )  # Trick needed for if to compare integer nrs
			if [ ${RET} -ne 0 ] 
				then
					MLTEMP2=`echo "(${MLTEMP}*${RATIOREAL})" | bc` # Integer
					EchoTee "Az sampling (${AZSAMP}m) is larger than Range sampling (${RGSAMP}m)." 
					EchoTee "   Probably processing Sentinel data." 
					EchoTee "Uses following Azimuth and Range factors: ${MLTEMP} and ${MLTEMP2}"
					RGML=${MLTEMP2}
					AZML=${MLTEMP}
					if [ "${PIXSHAPE}" == "ORIGINALFORM" ] ; then 
						RGML=${MLTEMP}
						AZML=${MLTEMP}
						EchoTee "However, your requested to keep ORIGINALFORM pixel size, hence using ${MLTEMP} for both Azimuth and Range"
					fi
				else
					MLTEMP2=`echo "(${MLTEMP}/${RATIOREAL})" | bc -l` # Real
					EchoTee "Az sampling (${AZSAMP}m) is smaller than Range sampling (${RGSAMP}m)." 
					EchoTee "   Probably processing ERS or Envisat data." 
					EchoTee "Uses following Azimuth and Range factors: ${MLTEMP2} and ${MLTEMP} (to be rounded)"
					RGML=${MLTEMP}
					AZML=${MLTEMP2}	
					if [ "${PIXSHAPE}" == "ORIGINALFORM" ] ; then 
						RGML=${MLTEMP}
						AZML=${MLTEMP}
						EchoTee "However, your requested to keep ORIGINALFORM pixel size, hence using ${MLTEMP} for both Azimuth and Range"
					fi
			fi	
			unset RET	
	fi
	# round ratio
	RGML=`echo ${RGML} | xargs printf "%.*f\n" 0`  # rounded
	AZML=`echo ${AZML} | xargs printf "%.*f\n" 0`  # rounded

	EchoTee "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	}

function RatioPixUnzoomed()
	{
	unset MLTEMP 
	local MLTEMP=$1 # ML factor to adapt
	EchoTee "- - - Compute ratio and transform input parameters in Range and Azimuth to get square pix, evaluated from UNZOOMED pixel size - - -" 
	# Ratio is not the same for ERS/ENVISAT than S1
	if [ "${UNZOOMEDRATIO}" -eq 1 ] 
		then 
			EchoTee "Az sampling (${UNZOOMEDAZSAMP}m) is similar to Range sampling (${UNZOOMEDRGSAMP}m)." 
			EchoTee "   Probably processing square pixel data such as RS, CSK or TSX." 
			EchoTee "Uses following Azimuth and Range factors: ${MLTEMP} and ${MLTEMP}"
			UNZOOMEDRGML=${MLTEMP}
			UNZOOMEDAZML=${MLTEMP}	
		else
			RET=$(echo "$UNZOOMEDRGSAMP < $UNZOOMEDAZSAMP" | bc )  # Trick needed for if to compare integer nrs
			if [ ${RET} -ne 0 ] 
				then
					MLTEMP2=`echo "(${MLTEMP}*${UNZOOMEDRATIOREAL})" | bc` # Integer
					EchoTee "Az sampling (${UNZOOMEDAZSAMP}m) is larger than Range sampling (${UNZOOMEDRGSAMP}m)." 
					EchoTee "   Probably processing Sentinel data." 
					EchoTee "Uses following Azimuth and Range factors: ${MLTEMP} and ${MLTEMP2}"
					UNZOOMEDRGML=${MLTEMP2}
					UNZOOMEDAZML=${MLTEMP}
					if [ "${PIXSHAPE}" == "ORIGINALFORM" ] ; then 
						UNZOOMEDRGML=${MLTEMP}
						UNZOOMEDAZML=${MLTEMP}
						EchoTee "However, your requested to keep ORIGINALFORM pixel size, hence using ${MLTEMP} for both Azimuth and Range"
					fi
				else
					MLTEMP2=`echo "(${MLTEMP}/${UNZOOMEDRATIOREAL})" | bc -l` # Real
					EchoTee "Az sampling (${UNZOOMEDAZSAMP}m) is smaller than Range sampling (${UNZOOMEDRGSAMP}m)." 
					EchoTee "   Probably processing ERS or Envisat data." 
					EchoTee "Uses following Azimuth and Range factors: ${MLTEMP2} and ${MLTEMP} (to be rounded)"
					UNZOOMEDRGML=${MLTEMP}
					UNZOOMEDAZML=${MLTEMP2}	
					if [ "${PIXSHAPE}" == "ORIGINALFORM" ] ; then 
						UNZOOMEDRGML=${MLTEMP}
						UNZOOMEDAZML=${MLTEMP}
						EchoTee "However, your requested to keep ORIGINALFORM pixel size, hence using ${MLTEMP} for both Azimuth and Range"
					fi
			fi	
			unset RET	
	fi
	# round ratio
	UNZOOMEDRGML=`echo ${UNZOOMEDRGML} | xargs printf "%.*f\n" 0`  # rounded
	UNZOOMEDAZML=`echo ${UNZOOMEDAZML} | xargs printf "%.*f\n" 0`  # rounded

	EchoTee "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	}

# copy resampled Secondary module and info for InSARParameters.txt for mass processing
function GetImgMod()
	{
	unset IMG TOBEUSEDAS
	local IMG=$1 # Date of img to test
	local TOBEUSEDAS=$2 # type of img.mod to be used as Primary or Secondary in the present run (must be correctly spelled, attention it is case sensitive)
	EchoTee "At least one pair must have been already processed using ${IMG} as Secondary in OUTPUTDATA and module must be in /ModulesForCoreg". 
	EchoTee "   Let's copy its module image and update InSARParameters to use it as ${TOBEUSEDAS} in the present run." 	

	# get the polarisation and size of images
	POLIMG=`ls ${OUTPUTDATA}/ModulesForCoreg/${IMG}* | ${PATHGNU}/gawk -F '/' '{print $NF}' |  cut -d . -f2`
	RGMODIMG=`ls ${OUTPUTDATA}/ModulesForCoreg/${IMG}* | ${PATHGNU}/gawk -F '/' '{print $NF}' |  cut -d . -f4 | cut -d _ -f4 | tr -dc '[0-9]'`
	AZMODIMG=`ls ${OUTPUTDATA}/ModulesForCoreg/${IMG}* | ${PATHGNU}/gawk -F '/' '{print $NF}' |  cut -d . -f4 | cut -d _ -f5 |   tr -dc '[0-9]'` 	

	# Copy module that was computed during SuperMasterCoreg.sh as {IMG}.VV.mod.OriginalCoreg_Z{ZOOM}_ML{MLAMPLI}_W{range}_L{azimuth}
	cp ${OUTPUTDATA}/ModulesForCoreg/${IMG}* ${RUNDIR}/i12/InSARProducts/${IMG}.${POLIMG}.mod

	ChangeParam "Reduced ${TOBEUSEDAS} amplitude image file path" "${RUNDIR}/i12/InSARProducts/${IMG}.${POLIMG}.mod" InSARParameters.txt
	ChangeParam "Reduced ${TOBEUSEDAS} amplitude image range dimension" ${RGMODIMG} InSARParameters.txt
	ChangeParam "Reduced ${TOBEUSEDAS} amplitude image azimuth dimension" ${AZMODIMG} InSARParameters.txt
		
	EchoTee ""
	}

# Compute amplitude images and plots; MLi factors are here for raster image
function MakeAmpliImgAndPlot()
	{
	unset ML1  ML2 TYPE IMGTORUN
	local ML1=$1 # ML factor for raster fig in x
	local ML2=$2 # ML factor for raster fig in y
	local TYPE=$3 # type of reduc factor : SQUARE of ORIGINALFORM 
	local IMGTORUN=$4 # option for Ampli image reduction of Secondary only 	
	# Amplitude image reduction
	# Process Image reduction
	# Better have a high ML to compute this step in order to reduce speckel as it will only be used
	#        for coregistration purposes. Do not forget to get it back after to desired ML factor for final products. 

	# first compute ML factor in range and azimuth for amplitude factor reduction
	case "${TYPE}" in 
		"SQUARE")  
			RatioPix ${MLAMPLI}
			ChangeParam "Range reduction factor" ${RGML} InSARParameters.txt
			ChangeParam "Azimuth reduction factor" ${AZML} InSARParameters.txt
			unset RGML
			unset AZML
			;;
		"ORIGINALFORM")
			ChangeParam "Range reduction factor" ${MLAMPLI} InSARParameters.txt
			ChangeParam "Azimuth reduction factor" ${MLAMPLI} InSARParameters.txt
			;;
		"SQUAREUNITY")  
			#Must keep it full res what ever the ML is 
			ChangeParam "Range reduction factor" 1 InSARParameters.txt
			ChangeParam "Azimuth reduction factor" 1 InSARParameters.txt
			;;
		"ORIGINALFORMUNITY")
			ChangeParam "Range reduction factor" 1 InSARParameters.txt
			ChangeParam "Azimuth reduction factor" 1 InSARParameters.txt
			;;
	esac

	cd ${RUNDIR}/i12
	
	case ${IMGTORUN} in
		"slaveOnly")
			amplitudeImageReduction slaveOnly | tee -a ${LOGFILE}
			# get actual Primary and Secondary Path and size in Range
			SRG=`GetParamFromFile "Reduced slave amplitude image range dimension" InSARParameters.txt`
			PATHSLV=`GetParamFromFile "Reduced slave amplitude image file path" InSARParameters.txt`
			FIGRATIO=`echo "(${ML1} * ${RATIO})" | bc` # Integer
			EchoTee "  FIGRATIO is ${FIGRATIO}"
			MakeFig ${SRG} 1.0 6.0 normal gray ${ML1}/${ML2} r4 ${PATHSLV} 
			;;
		"masterOnly")
			amplitudeImageReduction masterOnly | tee -a ${LOGFILE}
			# get actual Primary and Secondary Path and size in Range
			MRG=`GetParamFromFile "Reduced master amplitude image range dimension" InSARParameters.txt`
			PATHMAST=`GetParamFromFile "Reduced master amplitude image file path" InSARParameters.txt`
			FIGRATIO=`echo "(${ML1} * ${RATIO})" | bc` # Integer
			EchoTee "  FIGRATIO is ${FIGRATIO}"
			MakeFig ${MRG} 1.0 6.0 normal gray ${ML1}/${ML2} r4 ${PATHMAST} 
			;;
		*)
			amplitudeImageReduction | tee -a ${LOGFILE}
			# get actual Primary and Secondary Path and size in Range
			MRG=`GetParamFromFile "Reduced master amplitude image range dimension" InSARParameters.txt`
			SRG=`GetParamFromFile "Reduced slave amplitude image range dimension" InSARParameters.txt`
			PATHMAS=`GetParamFromFile "Reduced master amplitude image file path" InSARParameters.txt`
			PATHSLV=`GetParamFromFile "Reduced slave amplitude image file path" InSARParameters.txt`

			FIGRATIO=`echo "(${ML1} * ${RATIO})" | bc` # Integer
			EchoTee "  FIGRATIO is ${FIGRATIO}"
			MakeFig ${MRG} 1.0 6.0 normal gray ${ML1}/${ML2} r4 ${PATHMAS} 
			MakeFig ${SRG} 1.0 6.0 normal gray ${ML1}/${ML2} r4 ${PATHSLV} 
			;;
	esac
	}

# compute Coarse Coregistration
function CoarseCoregTestQuality()
	{
	ChangeParam "Coarse coregistration correlation threshold" ${COH} InSARParameters.txt
	ChangeParam "Coarse registration range distance between anchor points [pix]" ${CCDISTANCHOR} InSARParameters.txt
	ChangeParam "Coarse registration azimuth distance between anchor points [pix]" ${CCDISTANCHOR} InSARParameters.txt

	RatioPix ${CCOHWIN}
	ChangeParam "Coarse coregistration range window size [pix]" ${RGML} InSARParameters.txt
	ChangeParam "Coarse coregistration azimuth window size [pix]" ${AZML} InSARParameters.txt
	unset RGML
	unset AZML

	EchoTee ""
	EchoTee ""
	
	coarseCoregistration -f	| tee -a ${LOGFILE} # Coarse coreg computed on full search windows
	EchoTee "coarse coreg done" 
	
	# Test coregistration nr of anchors
	for ATTEMPT in 1 2 3 4
	do
		NRANCHORPTS=$(grep -m ${ATTEMPT} "Total number of anchor points" ${LOGFILE} | tail -n1 | tr -dc '[0-9]')
		EchoTeeYellow "Number of anchor points for Coarse Coreg is : ${NRANCHORPTS}" 
		EchoTee ""
		if [ "${NRANCHORPTS}" -le 10 ] ; then 	# force handling variable as integer
			# If failed 3 times, attempt to coarse coreg using Fiji - not sure it helps....
			if [ "${ATTEMPT}" -ge 4 ] ; then	
					# Failed 3 times; try with Fiji
					EchoTeeRed "  // Coarse Correg Failed 3 times; try with Fiji"
					EchoTeeRed "  // Check coregistration with Fiji - see https://imagej.net/Fiji/Downloads" 
					PATHMAST=`GetParamFromFile "Reduced master amplitude image file path" InSARParameters.txt`
					PATHSLV=`GetParamFromFile "Reduced slave amplitude image file path" InSARParameters.txt`

					MASWIDTH=`GetParamFromFile "Reduced master amplitude image range dimension" InSARParameters.txt`
					MASLENGTH=`GetParamFromFile "Reduced master amplitude image azimuth dimension" InSARParameters.txt`
					SLVWIDTH=`GetParamFromFile "Reduced slave amplitude image range dimension" InSARParameters.txt`
					SLVLENGTH=`GetParamFromFile "Reduced slave amplitude image azimuth dimension" InSARParameters.txt`

					EchoTee "Shall run Fiji on "
					EchoTee "${PATHMAST} "
					EchoTee "${PATHSLV}"
					EchoTee "Using Primary size ${MASWIDTH} x ${MASLENGTH}"
					EchoTee "And Slave size ${SLVWIDTH} x ${SLVLENGTH}"
					cp ${PATHMAST} FILE1fortest
					cp ${PATHSLV} FILE2fortest
					cp ${RUNDIR}/i12/TextFiles/InSARParameters.txt InSARParameters_testFiji.txt
					# Attention : run Fiji on Secondary then Primary to have Affine transfo in the same logic as MT. 

					CoregFiji ${PATHSLV} ${PATHMAST} ${SLVWIDTH} ${SLVLENGTH} ${MASWIDTH} ${MASLENGTH}
					
					# Get Fiji Param: (and get it in decimal instead of scientific notation)
					FijiAx=`grep "Estimated transformation model" Log_file1_file2.txt | cut -d, -f2-4 | cut -d [ -f3 | cut -d ] -f1  | cut -d , -f1 | ${PATHGNU}/gawk '{printf "%3.15f", $1}'`
					FijiBx=`grep "Estimated transformation model" Log_file1_file2.txt | cut -d, -f2-4 | cut -d [ -f3 | cut -d ] -f1  | cut -d , -f2 | ${PATHGNU}/gawk '{printf "%3.15f", $1}'`
					FijiCx=`grep "Estimated transformation model" Log_file1_file2.txt | cut -d, -f2-4 | cut -d [ -f3 | cut -d ] -f1  | cut -d , -f3 | ${PATHGNU}/gawk '{printf "%3.15f", $1}'`
					FijiAy=`grep "Estimated transformation model" Log_file1_file2.txt | cut -d, -f5-7 | cut -d [ -f2 | cut -d , -f1 | ${PATHGNU}/gawk '{printf "%3.15f", $1}'`
					FijiBy=`grep "Estimated transformation model" Log_file1_file2.txt | cut -d, -f5-7 | cut -d [ -f2 | cut -d , -f2 | ${PATHGNU}/gawk '{printf "%3.15f", $1}'`
					FijiCy=`grep "Estimated transformation model" Log_file1_file2.txt | cut -d, -f5-7 | cut -d [ -f2 | cut -d , -f3  | cut -d , -f2 | cut -d ] -f1 | ${PATHGNU}/gawk '{printf "%3.15f", $1}'`
					# Must however multiply Fiji Cx and Cy factors by ML to be consistent with MT 
					RatioPix ${INTERFML}
					FijiCx=`echo "${FijiCx} * ${RGML}" | bc -l`
					FijiCy=`echo "${FijiCy} * ${AZML}" | bc -l`
					unset RGML
					unset AZML
					
					# Replace by Fiji Param
					ChangeParam " Ax " ${FijiAx} InSARParameters.txt
					ChangeParam " Bx " ${FijiBx} InSARParameters.txt
					ChangeParam " Cx " ${FijiCx} InSARParameters.txt
					ChangeParam " Ay " ${FijiAy} InSARParameters.txt
					ChangeParam " By " ${FijiBy} InSARParameters.txt
					ChangeParam " Cy " ${FijiCy} InSARParameters.txt
				
					EchoTee "Coarse coreg with Fiji parameters using Cx=${FijiCx} and Cy=${FijiCy}"
					coarseCoregistration	| tee -a ${LOGFILE}	
					#rm Log_file1_file2.txt
			fi
			NEWCOH=`echo "(${COH} - 0.${ATTEMPT})" | bc` # Integer
			EchoTeeRed "  //  Too few anchor points - Try here to reduce coh threshold ${COH} with "
			ChangeParam "  // Coarse coregistration correlation threshold" ${NEWCOH} InSARParameters.txt
			coarseCoregistration	| tee -a ${LOGFILE}	
			SpeakOut "Coarse Coregistration threshold decreased to ${NEWCOH}" 
		else 
			EchoTee " Coarse Coregistration seems OK"
			EchoTee "-----------------------------"
			break
		fi
	done

	# Test coregistration quality
	for ATTEMPT in 1 2 3
	do
	  EchoTee "Coarse coreg run nr ${ATTEMPT}:"
	  #SIGMA=`grep -m ${ATTEMPT} sigmaRangeAzimuth ${LOGFILE} | tail -n1 |  cut -d = -f4 | ${PATHGNU}/gsed 's/\t//g' | xargs printf "%.*f\n" 0`  # rounded to 0th digits precision
	  SIGMA=$(grep sigmaRangeAzimuth ${LOGFILE} | tail -n1 |  cut -d = -f4 | ${PATHGNU}/gsed 's/\t//g' | xargs printf "%.*f\n" 0)  # rounded to 0th digits precision
	  if [ "${SIGMA}" == "" ] ; then
	  		EchoTeeRed "  // Coregistration Sigma is null. No Coarse Coreg anchor point found."
	  	else  
		  CANDIDATEPT=`grep -m ${ATTEMPT} "Number of candidate anchor points" ${LOGFILE} | cut -d = -f 2 | tr -dc '[0-9]'`
		  # ratio between candidate and used anchor point to assess quality of coregistration in %
		  RATIOCANDIANCHORPT=`echo "(${NRANCHORPTS}  * 100)/ ${CANDIDATEPT}" | bc` # Integer  
		  EchoTee "Coregistration Sigma is ${SIGMA} (Rounded)."
			if [ "${SIGMA}" -le 1 ] ; then
				EchoTee "Coregistration Sigma is less or = one." 
				EchoTee "Suppose coregistration is OK"
				EchoTee "-----------------------------"
				break
			elif [ "${SIGMA}" -le 2 ] && [ "${RATIOCANDIANCHORPT}" -ge 5 ]; then
				EchoTee "Coregistration Sigma is less or = 2 but ratio between candidate and used anchor point is ${RATIOCANDIANCHORPT} %." 
				EchoTee "Suppose coregistration is OK"
				EchoTee "-----------------------------"
				break
			elif [ "${SIGMA}" -le 2 ] && [ "${RATIOCANDIANCHORPT}" -le 5 ]; then
				EchoTee "Coregistration Sigma is less or = 2 but ratio between candidate and used anchor point is ${RATIOCANDIANCHORPT} %."
				EchoTee "=> Suppose coregistration could be improved."
				EchoTee "Re-run Coregistration"
				EchoTee "-----------------------------"
				coarseCoregistration	| tee -a ${LOGFILE}						
			elif [ "${SIGMA}" -ge 2 ]; then
				EchoTee "Coregistration Sigma is greater or = 2 : ${SIGMA}."
				EchoTee "=> Suppose coregistration could be improved."
				EchoTee "Re-run Coregistration"
				EchoTee "-----------------------------"
				coarseCoregistration	| tee -a ${LOGFILE}	
			else 
				EchoTeeRed "Coregistration Sigma seems to be wrong i.e. (null)." 	
				EchoTeeRed "Continue though you check yourself... probabaly better to put this image in quarantine." 	
					PATHMASTMP1=`GetParamFromFile "Master image file path" InSARParameters.txt`
					PATHSLVTMP1=`GetParamFromFile "Slave image file path" InSARParameters.txt`
					PATHMASTMP2=$(basename ${PATHMASTMP1})
					PATHSLVTMP2=$(basename ${PATHSLVTMP1})
				echo "Failed to coarse coreg ${PATHSLVTMP2} on ${PATHMASTMP2}" >> ${OUTPUTDATA}/_Coarse_Coregistration_Failed.txt
			fi
		fi
	done
	}

# compute Coarse Coregistration
function CoregFiji()
	{
	unset PATHFILE1
	unset PATHFILE2
	unset FILE1
	unset FILE2
	unset WIDTHMAS
	unset LENGTHMAS	
	unset WIDTHSLV
	unset LENGTHSLV	
	local PATHFILE1=$1  
	local PATHFILE2=$2
	local WIDTHMAS=$3
	local LENGTHMAS=$4
	local WIDTHSLV=$5
	local LENGTHSLV=$6
	FILE1=$(basename ${PATHFILE1})
	FILE2=$(basename ${PATHFILE2})
	echo "run('Raw...', 'open=${PATHFILE1} width=${WIDTHMAS} height=${LENGTHMAS} little-endian');" > FijiMacroTmp.txt
	echo "run('Enhance Contrast', 'saturated=0.35');" >> FijiMacroTmp.txt
	echo "run('Raw...', 'open=${PATHFILE2} width=${WIDTHSLV} height=${LENGTHSLV} little-endian');" >> FijiMacroTmp.txt
	echo "run('Enhance Contrast', 'saturated=0.35');" >> FijiMacroTmp.txt
	echo "run('Extract SIFT Correspondences', 'source_image=${FILE1} target_image=${FILE2} initial_gaussian_blur=1.60 steps_per_scale_octave=3 minimum_image_size=64 maximum_image_size=1024 feature_descriptor_size=4 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 filter maximal_alignment_error=25 minimal_inlier_ratio=0.05 minimal_number_of_inliers=7 expected_transformation=Rigid');" >> FijiMacroTmp.txt
	echo "run('Quit');"  >> FijiMacroTmp.txt
	${PATHGNU}/gsed "s/'/\"/g" FijiMacroTmp.txt > FijiMacroTmp2.txt 
	${PATHFIJI}/ImageJ-macosx  --headless -batch FijiMacroTmp2.txt >  Log_file1_file2.txt
	# rm FijiMacroTmp.txt 
   	}
   	
# compute InSAR processing and fig plotting ; ML factors here are for raster figures only
function InSARprocess()
	{
	unset MLFIG1 MLFIG2
	local MLFIG1=$1 #  ML factor for figs 
	local MLFIG2=$2 #  ML factor for figs
	EchoTee " "	
	EchoTee "InSAR Processing"			
	EchoTee "--------------------------------"
	EchoTee "--------------------------------"	

	# Reduce resolution of some raster fig by factor 4 to spare disk space"
	MLFIGSMALL1=`echo "${MLFIG1} * 4" | bc`
	MLFIGSMALL2=`echo "${MLFIG2} * 4" | bc`
	
	if [ "${PIXSHAPE}" == "ORIGINALFORM" ] ; then
			# if ML1 coh is 1 everywhere which is not a good idea. Force Coherence estimator window size to 2 to overcome this
			# Note : if INTERFML and COHESTIMFACT = 1 coherence will appear almost plain white
  			if [ "${INTERFML}" == "1" ] && [ ${COHESTIMFACT} -le 1 ] && [ ${POWSPECSMOOTFACT} -ge 1 ]; then
				EchoTeeYellow " You asked for a Coherence estimator window size of ${COHESTIMFACT} with a ML ${INTERFML} and an adaptive filtering with factor ${POWSPECSMOOTFACT}. "
				EchoTeeYellow " It will result in a coh=1 everywhere and crash at adaptive filtering."
				EchoTeeYellow " Hence I force your Coherence estimator window size to 2. You can also test higher. "
				ChangeParam "Coherence estimator range window size" 2 InSARParameters.txt
				ChangeParam "Coherence estimator azimuth window size" 2 InSARParameters.txt	
			else 
				ChangeParam "Coherence estimator range window size" ${COHESTIMFACT} InSARParameters.txt
				ChangeParam "Coherence estimator azimuth window size" ${COHESTIMFACT} InSARParameters.txt	
			fi
		else
  			if [ "${INTERFML}" == "1" ] && [ ${COHESTIMFACT} -le 1 ] && [ ${POWSPECSMOOTFACT} -ge 1 ]; then
				EchoTeeYellow " You asked for a Coherence estimator window size of ${COHESTIMFACT} with a ML ${INTERFML} and an adaptive filtering with factor ${POWSPECSMOOTFACT}. "
				EchoTeeYellow " It will result in a coh=1 everywhere and crash at adaptive filtering."
				EchoTeeYellow " Hence I force your Coherence estimator window size to 2. You can also test higher. "
				RatioPix 2
				ChangeParam "Coherence estimator range window size" ${RGML} InSARParameters.txt
				ChangeParam "Coherence estimator azimuth window size" ${AZML} InSARParameters.txt	
				unset RGML
				unset AZML
			else 
				RatioPix ${COHESTIMFACT}
				if [ ${RGML} -lt 2 ] 
					then 
						# May happen with asymetric Zoom
						EchoTeeYellow " The computed Coherence estimator window size is less than 2 in Range, which is not appropriate "
						EchoTeeYellow " Hence I force it to 2. "
						ChangeParam "Coherence estimator range window size" 2 InSARParameters.txt
					else 
						ChangeParam "Coherence estimator range window size" ${RGML} InSARParameters.txt
				fi
				if [ ${AZML} -lt 2 ] 
					then 
						# May happen with asymetric Zoom
						EchoTeeYellow " The computed Coherence estimator window size is less than 2 in Azimuth, which is not appropriate "
						EchoTeeYellow " Hence I force it to 2. "
						ChangeParam "Coherence estimator azimuth window size" 2 InSARParameters.txt
					else 
						ChangeParam "Coherence estimator azimuth window size" ${AZML} InSARParameters.txt
				fi

				unset RGML
				unset AZML
			fi
	fi
	
	#  OPTION -ha MENTIONED IN MANUAL WHEN WORKING WITH SRTM IS NOT NECESSARY (D DERAUW, PERS. COM., Jan 7 2015)
	#InSARProductsGeneration ${RUNDIR}/i12/TextFiles/InSARParameters.txt -s -i  | tee -a ${LOGFILE}
	# No  need to compute phase and height estimated standard deviations (only for topo quality estimate)
	
	if [ ${CALIBSIGMA} == "SIGMAYES" ] && [ ${SATDIR} == "S1" ]
		then 
			# compute sigma nought calibration
			InSARProductsGeneration ${RUNDIR}/i12/TextFiles/InSARParameters.txt -i -C | tee -a ${LOGFILE}
		else 
			InSARProductsGeneration ${RUNDIR}/i12/TextFiles/InSARParameters.txt -i  | tee -a ${LOGFILE}
	fi

	# Need to filter residual interf before bias coh estimation otherwise it uses the wrong interf for bias coh estimation
	# But here the filtering is applied on reduced image. Hence the filterig windows size MUST be the same in Rg and Az
	# Change filter parameters 
	ChangeParam "Range filter Full Width at Half Maximum" ${FILTFACTOR} InSARParameters.txt
	ChangeParam "Azimuth filter Full Width at Half Maximum" ${FILTFACTOR} InSARParameters.txt
    ChangeParam "Power spectrum filtering factor (for adaptative filtering)" ${POWSPECSMOOTFACT} InSARParameters.txt

	# DD 20170125 Interferogram filtering is now an adaptative Goldstein-like filtering.
	# -F parameter is used in the unwrapping procedure to consider the filter interferogram 
	
	# double filtering
	interferogramFiltering ${RUNDIR}/i12/TextFiles/InSARParameters.txt -d
	# only adaptive filtering
	#interferogramFiltering ${RUNDIR}/i12/TextFiles/InSARParameters.txt


	#Plot figs
	##########
	ISARRG=`GetParamFromFile "Interferometric products range dimension" InSARParameters.txt`
	ISARAZ=`GetParamFromFile "Interferometric products azimuth dimension" InSARParameters.txt`
	
	# interfero
	PATHINTERF=`GetParamFromFile " Interferogram file path " InSARParameters.txt`
	MakeFig ${ISARRG} 0.5 1.0 phase jet ${MLFIGSMALL1}/${MLFIGSMALL2} ci2 ${PATHINTERF} 

	# interfero filtre
	FILTINTERFFILE=`GetParamFromFile " Filtered interferogram file path " InSARParameters.txt`
	MakeFig ${ISARRG} 1.0 1.2 normal jet ${MLFIG1}/${MLFIG2} r4 ${FILTINTERFFILE} 

	# coherence
	PATHCOH=`GetParamFromFile " Coherence file path " InSARParameters.txt`
	MakeFigR ${ISARRG} 0,1 1.0 1.0 normal gray ${MLFIG1}/${MLFIG2} r4 ${PATHCOH} 
	
	# create fig for maskedCoherence if it exists		
	PATHMASKCOH=${RUNDIR}/i12/InSARProducts/maskedCoherence
	if [ -f ${PATHMASKCOH} ] ; then ${ISARRG} 0,1 1.0 1.0 normal gray ${MLFIG1}/${MLFIG2} r4 ${PATHMASKCOH} ; fi


	# interfero - dem
	PATHRESINTERF=`GetParamFromFile " Residual interferogram file path " InSARParameters.txt`
	MakeFig ${ISARRG} 1.0 1.2 normal jet ${MLFIG1}/${MLFIG2} r4 ${PATHRESINTERF} 
 
	# topo phase (first phase)
	# IF IMAGE APPEARS UNIFORM COLOR, REMOVE -r OPTION OR CHANGE MIN/MAX LIMITS IN -r OPTION 

	# for AE V < June 2025
	FIRSTPHASEFILE=`GetParamFromFile " First phase component file path " InSARParameters.txt`
	# for AE V >= June 2025
	TOPOPHASEFILE=`GetParamFromFile " Topographic phase component file path " InSARParameters.txt`
	MODELPHASEFILE=`GetParamFromFile " Model-based phase component file path " InSARParameters.txt`
	CORRPHASEFILE=`GetParamFromFile " Correction phase component file path " InSARParameters.txt`

	if [ "${FIG}" == "FIGyes"  ] ; then
		
		if [ -f "${FIRSTPHASEFILE}" ] && [ -s "${FIRSTPHASEFILE}" ] ; then
			MakeFig ${ISARRG} 1.0 5.0 phase jet ${MLFIGSMALL1}/${MLFIGSMALL2} ci2 ${FIRSTPHASEFILE} 
			mv ${FIRSTPHASEFILE}.ras ${FIRSTPHASEFILE}_wrapped.ras
			mv ${FIRSTPHASEFILE}.ras.sh ${FIRSTPHASEFILE}_wrapped.ras.sh
			${PATHGNU}/gsed  -i 's/\.ras/_wrapped\.ras/' ${FIRSTPHASEFILE}_wrapped.ras.sh
			MakeFigNoNorm ${ISARRG} normal jet ${MLFIG1}/${MLFIG2} r4 ${FIRSTPHASEFILE} 
		fi
	
		if [ -f "${TOPOPHASEFILE}" ] && [ -s "${TOPOPHASEFILE}" ] ; then
			MakeFig ${ISARRG} 1.0 5.0 phase jet ${MLFIGSMALL1}/${MLFIGSMALL2} ci2 ${TOPOPHASEFILE} 
			mv ${TOPOPHASEFILE}.ras ${TOPOPHASEFILE}_wrapped.ras
			mv ${TOPOPHASEFILE}.ras.sh ${TOPOPHASEFILE}_wrapped.ras.sh
			${PATHGNU}/gsed  -i 's/\.ras/_wrapped\.ras/' ${TOPOPHASEFILE}_wrapped.ras.sh
			MakeFigNoNorm ${ISARRG} normal jet ${MLFIG1}/${MLFIG2} r4 ${TOPOPHASEFILE} 
		fi
		if [ -f "${MODELPHASEFILE}" ] && [ -s "${MODELPHASEFILE}" ] ; then
			MakeFig ${ISARRG} 1.0 5.0 phase jet ${MLFIGSMALL1}/${MLFIGSMALL2} ci2 ${MODELPHASEFILE} 
			mv ${MODELPHASEFILE}.ras ${MODELPHASEFILE}_wrapped.ras
			mv ${MODELPHASEFILE}.ras.sh ${MODELPHASEFILE}_wrapped.ras.sh
			${PATHGNU}/gsed  -i 's/\.ras/_wrapped\.ras/' ${MODELPHASEFILE}_wrapped.ras.sh
			MakeFigNoNorm ${ISARRG} normal jet ${MLFIG1}/${MLFIG2} r4 ${MODELPHASEFILE} 
		fi
		if [ -f "${CORRPHASEFILE}" ] && [ -s "${CORRPHASEFILE}" ] ; then
			MakeFig ${ISARRG} 1.0 5.0 phase jet ${MLFIGSMALL1}/${MLFIGSMALL2} ci2 ${CORRPHASEFILE} 
			mv ${CORRPHASEFILE}.ras ${CORRPHASEFILE}_wrapped.ras
			mv ${CORRPHASEFILE}.ras.sh ${CORRPHASEFILE}_wrapped.ras.sh
			${PATHGNU}/gsed  -i 's/\.ras/_wrapped\.ras/' ${CORRPHASEFILE}_wrapped.ras.sh
			MakeFigNoNorm ${ISARRG} normal jet ${MLFIG1}/${MLFIG2} r4 ${CORRPHASEFILE} 
		fi
	
		
	fi
	#MakeFig ${ISARRG} 1.0 20 normal jet 4/4 r4 ${FIRSTPHASEFILE}
	}
	

# compute unwrapping ; ML factors here are for raster figures only
function UnwrapAndPlot()
	{
	unset MLFIG1 MLFIG2
	local MLFIG1=$1 #  ML factor for figs 
	local MLFIG2=$2 #  ML factor for figs

	EchoTee ""		
	EchoTee "Unwrapping"
	EchoTee "----------"
	case ${UW_METHOD} in 
		"SNAPHU")
			case "${MULTIUWP}" in 
				"MultiSnaphuYes") 
					# recursive snaphu unwrapping
					#############################
					cd ${RUNDIR}/i12/ 
					
					MASPOL=`GetParamFromFile "Master polarization channel" InSARParameters.txt`
					SLVPOL=`GetParamFromFile "Slave polarization channel" InSARParameters.txt`
					NUMCOL=`GetParamFromFile "Interferometric products range dimension" InSARParameters.txt`
					NUMLINE=`GetParamFromFile "Interferometric products azimuth dimension" InSARParameters.txt`
					WAVELENGTH=`GetParamFromFile "Wavelength" masterSLCImageInfo.txt`
					HWLEN=`echo "scale=10 ; (${WAVELENGTH} / 2)" | bc`			# half wave length of SAT, e.g. 0.02773288
	
					
					# what to unwrap ?: Interfero (e.g. for topo), ResidInterf (residual interfero) or ResidInterfFilt (residual interfero filtered) 
					case "${WHICHINTERF}" in 
						"ResidInterf") 
							INTERFILEPATH=`GetParamFromFile " Residual interferogram file path " InSARParameters.txt`
							;;
						"ResidInterfFilt") 
							INTERFILEPATH=`GetParamFromFile " Filtered interferogram file path " InSARParameters.txt`
							;;
						*) 
							# not sure; take most obvious, that is residual filtered interfero
							INTERFILEPATH=`GetParamFromFile " Filtered interferogram file path " InSARParameters.txt`
							;;
					esac	
					

					if [ "${COHMUWPTHRESH}" == "0" ] 
						then 
							# Do not mask with white noise
							Launch_RecurUnwr.sh ${INTERFILEPATH} ${NUMCOL} ${NUMLINE} ${COEFREQ} ${CUTINI} ${NITMAX} ${HWLEN} 
						else 
							PATHCOH=`GetParamFromFile " Coherence file path " InSARParameters.txt`
							Launch_RecurUnwr.sh ${INTERFILEPATH} ${NUMCOL} ${NUMLINE} ${COEFREQ} ${CUTINI} ${NITMAX} ${HWLEN} ${PATHCOH} ${COHMUWPTHRESH}
					fi

					# rename outputs unwrappedPhase.UNWR deformationMap.UNWR in i12/InSARProducts as unwrappedPhase.VV-VV and deformationMap
					mv -f ${RUNDIR}/i12/InSARProducts/unwrappedPhase.UNWR ${RUNDIR}/i12/InSARProducts/unwrappedPhase.${MASPOL}-${SLVPOL}
					mv -f ${RUNDIR}/i12/InSARProducts/deformationMap.UNWR ${RUNDIR}/i12/InSARProducts/deformationMap
					
					# need to update /InSARParameters.txt 
					cp ${RUNDIR}/i12/TextFiles/InSARParameters.txt ${RUNDIR}/i12/TextFiles/InSARParameters.ori.txt

					updateParameterFile ${RUNDIR}/i12/TextFiles/InSARParameters.txt "Unwrapped phase range dimension" ${NUMCOL}
					updateParameterFile ${RUNDIR}/i12/TextFiles/InSARParameters.txt "Unwrapped phase azimuth dimension" ${NUMLINE}
					
					# must rename "slantRangeDEM.VV-VV" with "deformationMap"
					# and  "Slant range DEM" with "Deformation measurement" 
					# in InSARParameters.txt
					if [ "${PROCESSMODE}" == "DEFO" ] 
						then 
							${PATHGNU}/gsed -i "s/slantRangeDEM.${MASPOL}-${SLVPOL}/deformationMap/g" ${RUNDIR}/i12/TextFiles/InSARParameters.txt
							${PATHGNU}/gsed -i "s/Slant range DEM/Deformation measurement/g" ${RUNDIR}/i12/TextFiles/InSARParameters.txt
					
							ChangeParam "Deformation measurement range dimension" ${NUMCOL} InSARParameters.txt
							ChangeParam "Deformation measurement azimuth dimension" ${NUMLINE} InSARParameters.txt
						else
							# beware, for TOPO, one must add the external phase (?)
							ChangeParam "Slant range DEM range dimension" ${NUMCOL} InSARParameters.txt
							ChangeParam "Slant range DEM azimuth dimension" ${NUMLINE} InSARParameters.txt
					fi

 
					;;
				*)	
					# Classic snaphu unwrapping
					###########################
					cd ${RUNDIR}/i12/ 

					EchoTee "Phase unwrapping using snaphu. Default snaphu config ?"
			
	
					if [ "${ZONEMAP}" == "ZoneMapYes" ] 
						then 
							phaseUnwrapping --snaphu -init -r -g
							# Zone map infos
							${PATHGNU}/gsed -i "/CONNCOMPFILE/c\CONNCOMPFILE	snaphuZoneMap" ${RUNDIR}/i12/TextFiles/snaphu.conf
							${PATHGNU}/gsed -i "/REGROWCONNCOMPS/c\REGROWCONNCOMPS	FALSE" ${RUNDIR}/i12/TextFiles/snaphu.conf
							${PATHGNU}/gsed -i "/MINCONNCOMPFRAC/c\MINCONNCOMPFRAC	${ZONEMAPSIZE}" ${RUNDIR}/i12/TextFiles/snaphu.conf
							${PATHGNU}/gsed -i "/CONNCOMPTHRESH/c\CONNCOMPTHRESH	${ZONEMAPCOST}" ${RUNDIR}/i12/TextFiles/snaphu.conf
							${PATHGNU}/gsed -i "/MAXNCOMPS/c\MAXNCOMPS	${ZONEMAPTOTAL}" ${RUNDIR}/i12/TextFiles/snaphu.conf
							# add lines for possible re-computing of zone map without re-unwrap
							${PATHGNU}/gsed -i '/.*CORRFILEFORMAT\tFLOAT_DATA.*/a # unwrapped file format' ${RUNDIR}/i12/TextFiles/snaphu.conf			# add title
							${PATHGNU}/gsed -i '/.*unwrapped file format.*/a UNWRAPPEDINFILEFORMAT\tFLOAT_DATA' ${RUNDIR}/i12/TextFiles/snaphu.conf		# add format
							${PATHGNU}/gsed -i '/.*unwrapped file format.*/i '$'\n' ${RUNDIR}/i12/TextFiles/snaphu.conf									# add empty line before title line with "unwrapped file format"
										
						else 
							phaseUnwrapping --snaphu -init -r
					fi
					${PATHGNU}/gsed -i "/DEFOTHRESHFACTOR/c\DEFOTHRESHFACTOR	${DEFOTHRESHFACTOR}" ${RUNDIR}/i12/TextFiles/snaphu.conf
					${PATHGNU}/gsed -i "/DEFOCONST/c\DEFOCONST	${DEFOCONST}" ${RUNDIR}/i12/TextFiles/snaphu.conf
					${PATHGNU}/gsed -i "/DEFOMAX_CYCLE/c\DEFOMAX_CYCLE	${DEFOMAX_CYCLE}" ${RUNDIR}/i12/TextFiles/snaphu.conf
					${PATHGNU}/gsed -i "/STATCOSTMODE/c\STATCOSTMODE ${SNAPHUMODE}" ${RUNDIR}/i12/TextFiles/snaphu.conf
		
					# adjust masking characteristics
					ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt

					if [ "${PROCESSMODE}" == "TOPO" ]
						then 
							if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
								then 
									# option m will first multiply coh with mask - ENSURE THAT IT IS ONLY MASK FOR WATER BODIES FOR INSTANCE
			
									# adjust masking characteristics: If COHCLNTHRESH=1, only pixels defined by mask will be unwrapped. If 0<CohClnThreshold<1, all pixels defined by mask + pixels above CohClnThreshold will be unwrapped 
									ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt

									if [ "${ZONEMAP}" == "ZoneMapYes" ] ; then phaseUnwrapping --snaphu -Fmg | tee -a ${LOGFILE}  ; else phaseUnwrapping --snaphu -Fm | tee -a ${LOGFILE} ; fi 
								else 
									if [ "${ZONEMAP}" == "ZoneMapYes" ] ; then phaseUnwrapping --snaphu -Fg | tee -a ${LOGFILE}  ; else phaseUnwrapping --snaphu -F | tee -a ${LOGFILE} ; fi 
							fi 			
						else 
							# if masking:APPLYMASKyes
							if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
								then 
									# adjust masking characteristics: If COHCLNTHRESH=1, only pixels defined by mask will be unwrapped. If 0<CohClnThreshold<1, all pixels defined by mask + pixels above CohClnThreshold will be unwrapped 
									ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt

									# option m will first multiply coh with mask 
									if [ "${ZONEMAP}" == "ZoneMapYes" ] ; then phaseUnwrapping --snaphu -rFmg | tee -a ${LOGFILE}  ; else phaseUnwrapping --snaphu -rFm | tee -a ${LOGFILE} ; fi 
								else 
									if [ "${ZONEMAP}" == "ZoneMapYes" ] ; then phaseUnwrapping --snaphu -rFg | tee -a ${LOGFILE} ; else phaseUnwrapping --snaphu -rF | tee -a ${LOGFILE} ; fi 
							fi 
							# recompute the zone map 
							#snaphu -f ${RUNDIR}/i12/TextFiles/snaphu.conf -G SnaphuZoneMask
					fi
					;;
			esac
			;;
		"CIS")
			cd ${RUNDIR}/i12/ 
			EchoTee "Phase unwrapping using CIS"

			ChangeParam "Biased coherence estimator range window size" ${BIASCOHESTIM} InSARParameters.txt
			ChangeParam "Biased coherence estimator azimuth window size" ${BIASCOHESTIM} InSARParameters.txt
			# Spiral 5 is ok but when applying mask before unwrapping 3 is better to avoid residual fringes not unwrapped 	
			ChangeParam "Biased coherence square spiral size" ${BIASCOHSPIR} InSARParameters.txt
	
			ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt
			ChangeParam "False residue coherence threshold" ${FALSERESCOHTHR} InSARParameters.txt
            ChangeParam "Connexion process mode" ${CONNEXION_MODE} InSARParameters.txt

			# Residues search
			residuesSearch -F | tee -a ${LOGFILE}   # -F parameter to process filtered interferogram
			RESSIZE=`GetParamFromFile "Residus image range dimension" InSARParameters.txt`
			RESSIZEAZ=`GetParamFromFile "Residus image azimuth dimension" InSARParameters.txt`
			PATHRES=`GetParamFromFile "Residus image file path" InSARParameters.txt`
			convert -depth 8 -equalize -size ${RESSIZE}x${RESSIZEAZ} gray:${PATHRES} ${PATHRES}.gif
	
			# Bias Coh estimation
			biasedCoherenceEstimation -F | tee -a ${LOGFILE}  # -F parameter to process filtered interferogram
	
			BCOHSIZE=`GetParamFromFile "Biased coherence range dimension" InSARParameters.txt`
			PATHBCOH=`GetParamFromFile "Biased coherence file path" InSARParameters.txt`
			MakeFigR ${BCOHSIZE} 0,1 1.0 1.0 normal gray 1/1 r4 ${PATHBCOH} 
	
			# Connexion residues - with mask ?
			# Get the mask       
			#RESMASK=${RUNDIR}/i12/InSARProducts/mask             
			#EchoTee "ResidueConnection with mask ${RESMASK}"
			#residuesConnexion mask=${RESMASK}	| tee -a ${LOGFILE}
	
			residuesConnexion | tee -a ${LOGFILE}
	
			PATHCNX=`GetParamFromFile "Connexions image file path" InSARParameters.txt`
			convert -depth 8 -equalize -size ${RESSIZE}x${RESSIZEAZ} gray:${PATHCNX} ${PATHCNX}.gif

			# -r = using externel DEM, ie the unwrapped residual phase is issued without adding the first phase component
			# -t generates a binary mask (based on the Coh Cleaning Threshold in InSARParam.txt) that will be used for geooding.
			#         It will skip geocoding of the pix < cleaning threshold but only those who are connected to sides ofthe images 
			# -p 	: Issues only the unwrapped phase in radian
			# -c 	: DEPRECIATED : InSAR products will all be cropped to the unwrapped phase size
			# -f 	: If an external DEM is present and if a first phase component was computed,
			#		  the -f option force removal of the best phase plane computed on the biggest zone.
			# -F	: The filtered interferogram is considered.
            # -n	: No phase normalization is performed.
            # -N	: No Nan fill of isolated and non unwrapped points.
			#phaseUnwrapping -r -t -c | tee -a ${LOGFILE}	
			if [ "${PROCESSMODE}" == "TOPO" ]
				then 
					phaseUnwrapping -tFNn | tee -a ${LOGFILE}
				else 
					phaseUnwrapping -rtFNn | tee -a ${LOGFILE}	
			fi
			# mask unwrapped phase if not got from snaphu : 
			#  Failed because unwrappedPhase does not have the same dimension as slantRangeMask - to be solved
			#EchoTee "Mask unwrapped phase."
			#ffa ${RUNDIR}/i12/InSARProducts/unwrappedPhase.${POLMAS}-${POLSLV} N ${RUNDIR}/i12/InSARProducts/slantRangeMask -i	
			;;		
		"DETPHUN1ONLY")  # i.e. without Snaphu after
			cd ${RUNDIR}/i12/ 
			EchoTee "Phase unwrapping using detPhUn 1 only with ${DETITERR} iterrations and a coh threshold of ${DETCOHTHRESH}"
			# Do not mask (phase nor coh) while using detPhUn
			# ffa ${RUNDIR}/i12/InSARProducts/residualInterferogram.${POLMAS}-${POLSLV}.f ${RUNDIR}/i12/InSARProducts/slantRangeMask -i
			if [ "${PROCESSMODE}" == "TOPO" ] 
				then 
					phaseUnwrapping -F --detPhUn N=${DETITERR} | tee -a ${LOGFILE}	
				else 
					phaseUnwrapping -rF --detPhUn N=${DETITERR} | tee -a ${LOGFILE}
			fi
			;;
		"DETPHUN2ONLY")  # i.e. without Snaphu after
			cd ${RUNDIR}/i12/ 
			EchoTee "Phase unwrapping using detPhUn 2 only with ${DETITERR} iterrations and a coh threshold of ${DETCOHTHRESH}"
				# Do not mask (phase nor coh) while using detPhUn
				if [ "${PROCESSMODE}" == "TOPO" ]
				then 
					phaseUnwrapping -2F --detPhUn N=${DETITERR} | tee -a ${LOGFILE}
				else 
					phaseUnwrapping -2rF --detPhUn N=${DETITERR} | tee -a ${LOGFILE}
			fi
			;;
		"DETPHUN1SNAPHU")  # used as pre-unwrapping and combined with Snpahu 
			cd ${RUNDIR}/i12/ 
			EchoTee "Phase unwrapping using detPhUn 1  with ${DETITERR} iterrations and a coh threshold of ${DETCOHTHRESH}, then Snaphu"

			if [ "${PROCESSMODE}" == "TOPO" ]
				then 
					if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
						then 
							# adjust masking characteristics: If COHCLNTHRESH=1, only pixels defined by mask will be unwrapped. If 0<CohClnThreshold<1, all pixels defined by mask + pixels above CohClnThreshold will be unwrapped 
							ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt

							phaseUnwrapping -Fm --detPhUn --snaphu N=${DETITERR} | tee -a ${LOGFILE}
						else  							
							phaseUnwrapping -F --detPhUn --snaphu N=${DETITERR} | tee -a ${LOGFILE}
					fi 			
				else 
					if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
						then
							# adjust masking characteristics: If COHCLNTHRESH=1, only pixels defined by mask will be unwrapped. If 0<CohClnThreshold<1, all pixels defined by mask + pixels above CohClnThreshold will be unwrapped 
							ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt

							phaseUnwrapping -rFm --detPhUn --snaphu N=${DETITERR} | tee -a ${LOGFILE}
						else  							
							phaseUnwrapping -rF --detPhUn --snaphu N=${DETITERR} | tee -a ${LOGFILE}
					fi 	
			fi
			;;
		"DETPHUN2SNAPHU")  # used as pre-unwrapping and combined with Snpahu 
			cd ${RUNDIR}/i12/ 
			EchoTee "Phase unwrapping using detPhUn 2  with ${DETITERR} iterrations and a coh threshold of ${DETCOHTHRESH}, then Snaphu"
			if [ "${PROCESSMODE}" == "TOPO" ]
				then 
					if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
						then
							phaseUnwrapping -2Fm --detPhUn --snaphu N=${DETITERR} | tee -a ${LOGFILE}
						else 								
							phaseUnwrapping -2F --detPhUn --snaphu N=${DETITERR} | tee -a ${LOGFILE}
					fi 			
				else 
					if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
						then
							phaseUnwrapping -2rFm --detPhUn --snaphu N=${DETITERR} | tee -a ${LOGFILE}
						else 
							phaseUnwrapping -2rF --detPhUn --snaphu N=${DETITERR} | tee -a ${LOGFILE}
					fi 	
			fi
			;;
			
			
		"DETPHUN1CIS")  # used as pre-unwrapping and combined with CIS branch cut 
			cd ${RUNDIR}/i12/ 
			EchoTee "Phase unwrapping using detPhUn 1  with ${DETITERR} iterrations and a coh threshold of ${DETCOHTHRESH}, then CIS branch cut"

			if [ "${PROCESSMODE}" == "TOPO" ]
				then 
					phaseUnwrapping -F --detPhUn --branchCut N=${DETITERR} | tee -a ${LOGFILE}
				else 
					phaseUnwrapping -rF --detPhUn --branchCut N=${DETITERR} | tee -a ${LOGFILE}
			fi
			;;
		"DETPHUN2CIS")  # used as pre-unwrapping and combined with CIS branch cut  
			cd ${RUNDIR}/i12/ 
			EchoTee "Phase unwrapping using detPhUn 2  with ${DETITERR} iterrations and a coh threshold of ${DETCOHTHRESH}, then CIS branch cut"
			if [ "${PROCESSMODE}" == "TOPO" ]
				then 
					phaseUnwrapping -2F --detPhUn --branchCut N=${DETITERR} | tee -a ${LOGFILE}
				else 
					phaseUnwrapping -2rF --detPhUn --branchCut N=${DETITERR} | tee -a ${LOGFILE}
			fi
			;;
			
			
		*)
			EchoTeeRed "I do not know which unwrapping method you want. Check UN_METHOD parameter in ParametersFile.txt."
			EchoTeeRed "I process Snaphu by default..." 
			cd ${RUNDIR}/i12/
			EchoTee "Phase unwrapping using snaphu. Default snaphu config ?"
			phaseUnwrapping --snaphu -init -r
			${PATHGNU}/gsed -i "/DEFOTHRESHFACTOR/c\DEFOTHRESHFACTOR	${DEFOTHRESHFACTOR}" ${RUNDIR}/i12/TextFiles/snaphu.conf
			${PATHGNU}/gsed -i "/DEFOCONST/c\DEFOCONST	${DEFOCONST}" ${RUNDIR}/i12/TextFiles/snaphu.conf
			${PATHGNU}/gsed -i "/DEFOMAX_CYCLE/c\DEFOMAX_CYCLE	${DEFOMAX_CYCLE}" ${RUNDIR}/i12/TextFiles/snaphu.conf
			${PATHGNU}/gsed -i "/STATCOSTMODE/c\STATCOSTMODE ${SNAPHUMODE}" ${RUNDIR}/i12/TextFiles/snaphu.conf

			# for manual test
			# ${PATHGNU}/gsed  -i "s/INITMETHOD	MCF/INITMETHOD	MST/" ${RUNDIR}/i12/TextFiles/snaphu.conf
			
			# adjust masking characteristics
			ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt
			
			if [ "${PROCESSMODE}" == "TOPO" ]
				then 
					if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
						then 
							# option m will first multiply coh with mask - ENSURE THAT IT IS ONLY MASK FOR WATER BODIES FOR INSTANCE
			
							# adjust masking characteristics: If COHCLNTHRESH=1, only pixels defined by mask will be unwrapped. If 0<CohClnThreshold<1, all pixels defined by mask + pixels above CohClnThreshold will be unwrapped 
							ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt

							phaseUnwrapping --snaphu -Fm | tee -a ${LOGFILE}
						else 
							phaseUnwrapping --snaphu -F | tee -a ${LOGFILE}							
					fi 			
				else 
					# if masking:APPLYMASKyes
					if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
						then 
							# adjust masking characteristics: If COHCLNTHRESH=1, only pixels defined by mask will be unwrapped. If 0<CohClnThreshold<1, all pixels defined by mask + pixels above CohClnThreshold will be unwrapped 
							ChangeParam "Coherence cleaning threshold" ${COHCLNTHRESH} InSARParameters.txt

							# option m will first multiply coh with mask 
							phaseUnwrapping --snaphu -rFm | tee -a ${LOGFILE}
						else 
							phaseUnwrapping --snaphu -rF | tee -a ${LOGFILE}							
					fi 
			fi ;;			
	esac
	
	# Get width of file for rasters and gmtmath 
	UNRPSIZE=`GetParamFromFile "Unwrapped phase range dimension" InSARParameters.txt`
	
	# TEST IF Primary DATE > OR < Secondary. INVERT UNWRAPPED IF NEEDED
	EchoTee ""
	if [ "${PROCESSMODE}" != "TOPO" ]
		then 
			EchoTee "MAS and SLV are ${MAS} and ${SLV}"
			if [ "${MAS}" -gt "${SLV}" ] 
				then
					EchoTeeYellow "Multiply unwrapped defo phase of pair ${MAS}_${SLV} by -1"
					EchoTee "Using something such as gmt gmtmath deformationMapToBeInverted -bsWIDTHOFFILE -1 MUL = deformationMapInverted"
					mv ${RUNDIR}/i12/InSARProducts/deformationMap ${RUNDIR}/i12/InSARProducts/deformationMap.WrongSign
					gmt gmtmath ${RUNDIR}/i12/InSARProducts/deformationMap.WrongSign -bs${UNRPSIZE} -1 MUL = ${RUNDIR}/i12/InSARProducts/deformationMap
				else 
					EchoTee "Primary date is before Secondary date. No need to Multiply unwrappedd phase by -1"
			fi
	fi

	#Make fig for unrwapped phase, deformationMap, and unrapped zone map
	PATHUWPPHASE=`GetParamFromFile "Unwrapped phase file path" InSARParameters.txt`
	MakeFig ${UNRPSIZE} 1.0 20 normal jet ${MLFIG1}/${MLFIG2} r4 ${PATHUWPPHASE} 

	if [ "${PROCESSMODE}" != "TOPO" ]
		then 
			PATHDEFOMAP=`GetParamFromFile "Deformation measurement file path" InSARParameters.txt`
			MakeFig ${UNRPSIZE} 1.0 1.2 normal jet ${MLFIG1}/${MLFIG2} r4 ${PATHDEFOMAP} 
	fi
	
    case ${UW_METHOD} in 
        "CIS")
			# create fig for mask
			PATHMSK=${RUNDIR}/i12/InSARProducts/mask
			convert -depth 8 -equalize -size ${BCOHSIZE}x${RESSIZEAZ} gray:${PATHMSK} ${PATHMSK}.gif
			# create fig for zoneMap
			PATHUNWPZONEMAP=${PATHUWPPHASE}.zoneMap
			MakeFig ${UNRPSIZE} 1.0 1.2 normal jet ${MLFIG1}/${MLFIG2} r4 ${PATHUNWPZONEMAP} ;;
		"SNAPHU") 
			# create fig for maskedInterferogram if snaphu is used with a mask		
			PATHMASKINTERF=${RUNDIR}/i12/InSARProducts/maskedInterferogram
			if [ -f ${PATHMASKINTERF} ] ; then MakeFig ${UNRPSIZE} 1.0 1.2 normal jet ${MLFIG1}/${MLFIG2} r4 ${PATHMASKINTERF} ; fi
			;;
	esac

	#Make fig for mask
	if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
		then 
			PATHMASK=${RUNDIR}/i12/InSARProducts/slantRangeMask
			MakeFigNoNorm ${ISARRG} normal gray 1/1 c1 ${PATHMASK} 
	fi

	# create fig for maskedCoherence if it exists		
	PATHMASKCOH=${RUNDIR}/i12/InSARProducts/maskedCoherence
	#if [ -f ${PATHMASKCOH} ] ; then MakeFigR ${UNRPSIZE} 0.1 1.0 1.0 normal gray ${MLFIG1}/${MLFIG2} r4 ${PATHMASKCOH} ; fi
	if [ -f ${PATHMASKCOH} ] ; then convert -depth 32 -equalize -size ${ISARRG}x${ISARAZ}  gray:${PATHMASKCOH} ${PATHMASKCOH}.gif ; fi

	}
	
# compute multiple geocoding in UTM
#       Parameters are which products to geocode: DEFOMAP, MASAMPL, SLVAMPL, COH, INTERF, FILTINTERF, RESINTERF, UNWPHASE
function GeocUTM()
	{
	unset DEFOMAP MASAMPL SLVAMPL COHFILE INTERF FILTINTERF RESINTERF UNWPHASE
	
	local DEFOMAP=$1 
	local MASAMPL=$2 
	local SLVAMPL=$3
	local COHFILE=$4
	local INTERF=$5
	local FILTINTERF=$6
	local RESINTERF=$7
	local UNWPHASE=$8
	EchoTee " "	
	EchoTee "Geocode"		
	EchoTee "--------------------------------"	
	EchoTee "--------------------------------"
	EchoTee ""		
	EchoTeeYellow "Geocode products according to FILESTOGEOC parameter in main script :"
	EchoTeeYellow "DEFOMAP	MASAMPL	SLVAMPL	COH	INTERF	FILTINTERF	RESINTERF	UNWPHASE"
	EchoTeeYellow "${FILESTOGEOC}"
	EchoTee "-------------------------------------------------------------------"	

	# Change default parameters :

	# Geocoded resoution : close to initial interfero or forced to common size (e.g. for further MSBAS) 
	# Size of the geocoded pixel simply rounded
	
	# Need to asses here the size in ground resolution, hence one must take into account the incidence angle
	# Following bug correction was applied on July 7th 2021
	#	PIXSIZEAZ should be	PIXSIZEAZ=`echo " ( ${AZSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
	### Below applies twice the zoom AND ML because pix size in masterSLCImageInfo.txt or slaveSLCImageInfo.txt are already zoomed and ML		 !!
	#PIXSIZEAZ=`echo "scale=5; ( ${AZSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
	#EchoTee " PIXSIZEAZ is ${PIXSIZEAZ} from AZSAMP${AZSAMP} / ZOOM${ZOOM} ) * INTERFML${INTERFML} "
	#PIXSIZEAZ=`echo "scale=5; ( ${AZSAMP} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
	#EchoTee " (Zoomed) PIXSIZEAZ is ${PIXSIZEAZ} from AZSAMP${AZSAMP} ) * INTERFML${INTERFML} "

	# Check ZOOM factor (one or two values) and compute ZOOM in Az and Rg if needed (ZOOMAZ and ZOOMRG in case of two values) becasue needed below
	CheckZOOMasymetry
	
	EchoTee "Check pixel shape and ratio"
	RatioPix ${INTERFML}
	# To be certain, re-check wich one is the largest
	ROUNDEDAZSAMP=`echo ${AZSAMP} | xargs printf "%.*f\n" 0`  # (AzPixSize) rounded to 0th digits precision
	ROUNDEDRGSAMP=`echo ${RGSAMP} | xargs printf "%.*f\n" 0`  # (RgPixSize) rounded to 0th digits precision
		if [ ${ROUNDEDAZSAMP} -ge ${ROUNDEDRGSAMP} ]
			then 
				# zoom factor already taken into account in AZSAMP and RGSAMP
				PIXSIZEAZ=`echo "scale=5; ( ${AZSAMP}) * ${AZML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
				PIXSIZERG=`echo "scale=5; ( ${RGSAMP} ) * ${RGML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision

				eval PIXSIZEAZORIGINAL=${PIXSIZEAZ} # needed in the specific case of asymetric zoom making square pix despite ORIGINALFORM 

				EchoTee " PIXSIZEAZ is ${PIXSIZEAZ}  "
			else 
				# zoom factor already taken into account in AZSAMP and RGSAMP
				PIXSIZEAZ=`echo "scale=5; ( ${AZSAMP}) * ${AZML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision
				PIXSIZERG=`echo "scale=5; ( ${RGSAMP} ) * ${RGML}" | bc`  # size of ML pixel in az (in m) - allow 5 digits precision

				EchoTee " PIXSIZERG is ${PIXSIZERG} from RGSAMP${RGSAMP} ) * INTERFML${RGML} "
				eval PIXSIZEAZORIGINAL=${PIXSIZEAZ}
				EchoTee " PIXSIZEAZ is ${PIXSIZEAZORIGINAL} "
				# from now on, the largest pixel is named AZ... even if it is RG - Yes it is uggly but changing the name could have too much impact in other scripts
				if [ "${PIXSHAPE}" != "ORIGINALFORM" ] ; then 
					PIXSIZEAZ=${PIXSIZERG}
				fi
		fi

	# Unless PIXSHAPE=ORIGINALFORM, PIXSIZEAZ below is the pixel with respect to the largest side (i.e. AZ or RG) - Yes it is uggly but changing the name could have too much impact in other scripts
	
	GEOPIXSIZERND=`echo ${PIXSIZEAZ} | cut -d . -f1`	
	if [ ${GEOPIXSIZERND} -eq "0" ] 
		then 
			GEOPIXSIZERND="1" 
			EchoTee "Truncated PIXSIZE is 0, hence increased to ${GEOPIXSIZERND}"
		else
			EchoTee "Truncated PIXSIZE is ${GEOPIXSIZERND}"
	fi 	
	

	# Size of the geocoded pixel rounded to the nearest (up) multiple of 10
	if [ -z ${GEOPIXSIZERND#?} ]   # test if all but the first digit is null
		then
		 GEOPIXSIZE10=`echo "10"`	 # if only 1 digit, uper round is 10
		else
		 unset x
		 x=$((${GEOPIXSIZERND}-${GEOPIXSIZERND: -1})) # Rounded - last digit
		 GEOPIXSIZE10=`echo "$x" +10 | bc`            # +10
	fi

	case ${GEOCMETHD} in
		"Closest") 
			EchoTeeYellow "Automatic geocoded pixel size determination."
			EchoTeeYellow "          Will get the closest multilooked original pixel size." 
			EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 		

			GEOPIXSIZE=`echo ${PIXSIZEAZ} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
			if [ ${GEOPIXSIZE} -eq "0" ] ; then GEOPIXSIZE="1" ; fi 	# just in case...
		

			if [ "${PIXSHAPE}" == "ORIGINALFORM" ]
				then 
					GEOPIXSIZEAZ=`echo ${PIXSIZEAZORIGINAL} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
					if [ ${GEOPIXSIZEAZ} -eq "0" ] ; then GEOPIXSIZEAZ="1" ; fi 	# just in case...
					GEOPIXSIZERG=`echo ${PIXSIZERG} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
					if [ ${GEOPIXSIZERG} -eq "0" ] ; then GEOPIXSIZERG="1" ; fi 	# just in case...
					ChangeParam "Easting sampling" ${GEOPIXSIZERG} geoProjectionParameters.txt 
					ChangeParam "Northing sampling" ${GEOPIXSIZEAZ} geoProjectionParameters.txt
					GEOPIXSIZENAME=${GEOPIXSIZERG}x${GEOPIXSIZEAZ}

					EchoTeeYellow "Using ${GEOPIXSIZENAME} meters geocoded Rg x Az pixel size."
				else 
					ChangeParam "Easting sampling" ${GEOPIXSIZE} geoProjectionParameters.txt 
					ChangeParam "Northing sampling" ${GEOPIXSIZE} geoProjectionParameters.txt
					GEOPIXSIZENAME=${GEOPIXSIZE}x${GEOPIXSIZE}

					EchoTeeYellow "Using ${GEOPIXSIZENAME} meters geocoded pixel size."
					
					# Dummy; Needed for naming 
					GEOPIXSIZEAZ=${GEOPIXSIZE}
					GEOPIXSIZERG=${GEOPIXSIZE}
			fi
		;;
		"Auto") 
			EchoTeeYellow "Automatic geocoded (squared) pixel size determination."
			EchoTeeYellow "          Will get the closest (upper) multiple of 10 of multilooked original pixel size. " 
			EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 	
			GEOPIXSIZE=${GEOPIXSIZE10}
	
			ChangeParam "Easting sampling" ${GEOPIXSIZE} geoProjectionParameters.txt 
			ChangeParam "Northing sampling" ${GEOPIXSIZE} geoProjectionParameters.txt
			GEOPIXSIZENAME=${GEOPIXSIZE}x${GEOPIXSIZE}
	
			EchoTeeYellow "Using ${GEOPIXSIZENAME} meters geocoded pixel size."
			
			# Dummy; Needed for naming 
			GEOPIXSIZEAZ=${GEOPIXSIZE}
			GEOPIXSIZERG=${GEOPIXSIZE}
		;;
		"Forced") 
			# Possibly force UTM coordinates of geocoded products (convenient for further MSBAS)
					
			CheckFORCEGEOPIXSIZEasymetry		# this fct also define GEOPIXSIZE, GEOPIXSIZERG and GEOPIXSIZEAZ based on FORCEGEOPIXSIZE, FORCEGEOPIXSIZEAZ and FORCEGEOPIXSIZERG

			# Change default parameters : Geoprojected products generic extension (OK also if only one value of FORCEDGEOPIXSIZE ; see fct CheckFORCEGEOPIXSIZEasymetry)
			ChangeParam "Geoprojected products generic extension" ".UTM.${FORCEGEOPIXSIZERG}x${FORCEGEOPIXSIZEAZ}" geoProjectionParameters.txt

			#GEOPIXSIZE=${FORCEGEOPIXSIZE}    					# Give the sampling rate here of what you want for your final MSBAS database
			#EchoTeeYellow "Forced geocoded (squared) pixel size determination. " 
			#EchoTeeYellow "Assigned ${GEOPIXSIZE} m. Will also force the limits of the geocoded files."
			#EchoTeeYellow "     If gets holes in geocoded products, increase interpolation radius." 	
			if [ -f "${GEOCKML}" ] 
				then
					# Seems you want to define the geocoded zone using a kml file
					if [ -f "${GEOCKML}" ] && [ -s "${GEOCKML}" ]
						then 
							# OK file exists 
							ChangeParam "Path to a kml file defining the geoProjection area" ${GEOCKML} geoProjectionParameters.txt	
						else 
							EchoTeeYellow "Can't find the kml for defining geocoding area in ${GEOCKML} " 
							EchoTeeYellow "Try using xMin, xMax, yMin and yMax instead..." 
	
							if [ "${UTMZONE}" == "" ]
								then 
									EchoTeeYellow "No UTM zone defined (empty or not in LaunchParam.txt file). Will compute it from the center of the image."
									EchoTeeYellow "  It may not be a problem unless the center of the AoI is in another zone and you need to compare different modes which can have different central UTM zone."
								else
									EchoTeeYellow "Shall use UTM zone defined in LaunchParam.txt, that is: ${UTMZONE}"
									ChangeParam "UTM zone " ${UTMZONE} geoProjectionParameters.txt
							fi
								
							ChangeParam "xMin" ${XMIN} geoProjectionParameters.txt
							ChangeParam "xMax" ${XMAX} geoProjectionParameters.txt
							ChangeParam "yMin" ${YMIN} geoProjectionParameters.txt
							ChangeParam "yMax" ${YMAX} geoProjectionParameters.txt
					fi
				else 
					if [ "${UTMZONE}" == "" ]
						then 
							EchoTeeYellow "No UTM zone defined (empty or not in LaunchParam.txt file). Will compute it from the center of the image."
							EchoTeeYellow "  It may not be a problem unless the center of the AoI is in another zone and you need to compare different modes which can have different central UTM zone."
						else
							EchoTeeYellow "Shall use UTM zone defined in LaunchParam.txt, that is: ${UTMZONE}"
							ChangeParam "UTM zone " ${UTMZONE} geoProjectionParameters.txt
					fi
	
					ChangeParam "xMin" ${XMIN} geoProjectionParameters.txt
					ChangeParam "xMax" ${XMAX} geoProjectionParameters.txt
					ChangeParam "yMin" ${YMIN} geoProjectionParameters.txt
					ChangeParam "yMax" ${YMAX} geoProjectionParameters.txt
			fi

			# Could avoid this test and keep only the else part I think... Not harmful though
			if [ "${FORCEGEOPIXSIZEVAL}" == "One" ]
				then 
					ChangeParam "Easting sampling" ${GEOPIXSIZE} geoProjectionParameters.txt 
					ChangeParam "Northing sampling" ${GEOPIXSIZE} geoProjectionParameters.txt
					GEOPIXSIZENAME=${GEOPIXSIZE}x${GEOPIXSIZE}
				else 
					ChangeParam "Easting sampling" ${FORCEGEOPIXSIZERG} geoProjectionParameters.txt 
					ChangeParam "Northing sampling" ${FORCEGEOPIXSIZEAZ} geoProjectionParameters.txt		
					GEOPIXSIZENAME=${FORCEGEOPIXSIZERG}x${FORCEGEOPIXSIZEAZ}
			fi

		;;
		*) 
			EchoTeeYellow "Not sure what you wanted => used Closest..." 
			GEOPIXSIZE=`echo ${PIXSIZEAZ} | xargs printf "%.*f\n" 0`  # (AzimuthPixSize x ML) rounded to 0th digits precision
			if [ ${GEOPIXSIZE} -eq "0" ] ; then GEOPIXSIZE="1" ; fi 	# just in case...
			GEOPIXSIZENAME=${GEOPIXSIZE}x${GEOPIXSIZE}
			EchoTeeYellow "Using ${GEOPIXSIZE} meters geocoded pixel size."
		;;
	esac

	# Change default parameters : interpolation radius (2-3 times resolution might be good; the largest radius the slowest)  
	#GEOPIXRADIUS=`echo "${GEOPIXSIZE} * 2" | bc`
	#ChangeParam "Easting interpolation radius" ${GEOPIXRADIUS} geoProjectionParameters.txt
	#ChangeParam "Northing interpolation radius" ${GEOPIXRADIUS} geoProjectionParameters.txt 

	# Define which products to geocode
	ChangeParam "Geoproject measurement" ${DEFOMAP} geoProjectionParameters.txt
	ChangeParam "Geoproject master amplitude" ${MASAMPL} geoProjectionParameters.txt 
	ChangeParam "Geoproject slave amplitude" ${SLVAMPL} geoProjectionParameters.txt 
	ChangeParam "Geoproject coherence" ${COHFILE} geoProjectionParameters.txt 
	ChangeParam "Geoproject interferogram" ${INTERF} geoProjectionParameters.txt 
	ChangeParam "Geoproject filtered interferogram" ${FILTINTERF} geoProjectionParameters.txt 
	ChangeParam "Geoproject residual interferogram" ${RESINTERF} geoProjectionParameters.txt 
	ChangeParam "Geoproject unwrapped phase" ${UNWPHASE} geoProjectionParameters.txt 

	ChangeParam "Resampling method" ${RESAMPMETHD} geoProjectionParameters.txt
	
	ChangeParam "Weighting method" ${WEIGHTMETHD} geoProjectionParameters.txt
	ChangeParam "ID smoothing factor" ${IDSMOOTH} geoProjectionParameters.txt
	ChangeParam "ID weighting exponent" ${IDWEIGHT} geoProjectionParameters.txt
	ChangeParam "FWHM : Lorentzian Full Width at Half Maximum" ${FWHM} geoProjectionParameters.txt
	# Since 2020 01 21 MT masking method is defined by either "mask" (all method but CIS) or "zoneMap" (for CIS in topo mode); no more path to mask
	# In cas eof Snaphu or DetPhun, no need to change here below
	# ChangeParam "Mask " ${PATHTOMASK} geoProjectionParameters.txt
	ChangeParam "Zone index" ${ZONEINDEX} geoProjectionParameters.txt
	
	# Geocode
	#geoProjection ${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt	| tee -a ${LOGFILE}
	# Now reverse for GIS and with .hdr
	# -f : Force to fill holes as much as possible. This may introduce some unwanted distortions.
	# -f=x : Allows forcing a hole filling factor, where x a float. 

	# Apply mask with AMSTer Engine V > 20241127	
	if [ "${APPLYMASK}" == "APPLYMASKyes" ] && grep -q "Masking: Use of slant range mask or zoneMap for measurement geo-projection" "${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt"
		then 
			ChangeParam "Masking: Use of slant range mask or zoneMap for measurement geo-projection ([mask] or [zoneMap])" mask geoProjectionParameters.txt
	fi 

   if [ "${UW_METHOD}" == "CIS" ]
        then
			# can make use of the mask generated for the borders at the unwrapping step:
			EchoTeeYellow "Geocoding using mask generated by CIS unwrapping method. "
			EchoTeeYellow "    It is built based on coh cleaning threshold (chose wizely) and is only usable "
			EchoTeeYellow "    by CIS unwrapping method to mask low coh pixels in contact with the borders of the image. "
			# Since 2020 01 21 CIS masking method is defined by either "mask" (all method but CIS) or "zoneMap" (for CIS in topo mode); no more path to mask
			# For CIS unwrapping and topo mode, it is advised to change mask as zoneMap here below
  			 if [ "${APPLYMASK}" == "APPLYMASKyes" ]
      		 	then
      		 		ChangeParam "Masking: Use of slant range mask or zoneMap for measurement geo-projection ([mask] or [zoneMap])" mask geoProjectionParameters.txt
      		 	else
      		 		ChangeParam "Masking: Use of slant range mask or zoneMap for measurement geo-projection ([mask] or [zoneMap])" zoneMap geoProjectionParameters.txt
			fi
			# ChangeParam "Mask " zoneMap geoProjectionParameters.txt
	fi

	# Below we keep geoProjectionParameters.txt from RUNDIR and not from RESAMPLED/SUPERMASTER-MASTER 
	#   because we want to force all processing done for MSBAS with same geocoded grid. These info are
	#   hence updated by the scripts based on parameters provided in ParametersFile.txt. 
	#   Ensure that these are similar for each mode that you want to combine for MSBAS. 
	if [ ${RADIUSMETHD} == "LetCIS" ] 
		then
			# Let CIS Choose what is the best radius, that is 2 times the distance to the nearest neighbor
			geoProjection -rk ${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt	| tee -a ${LOGFILE}
		else 
			# Force radius: force radius to RADIUSMETHD times the distance to the nearest neighbor. Default value (i.e. LetCIS) is 2)
			geoProjection -rk -f=${RADIUSMETHD} ${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt	| tee -a ${LOGFILE}
	fi

	}

function PlotGeoc()
	{
	unset DEFOMAP MASAMPL SLVAMPL COHFILE INTERF FILTINTERF RESINTERF UNWPHASE
	
	local DEFOMAP=$1 
	local MASAMPL=$2 
	local SLVAMPL=$3
	local COHFILE=$4
	local INTERF=$5
	local FILTINTERF=$6
	local RESINTERF=$7
	local UNWPHASE=$8	

	#Path to geocoded products
	cd ${RUNDIR}/i12/GeoProjection
	
	if [ "${DEFOMAP}" == "YES" ]
		then
			if [ "${PROCESSMODE}" == "TOPO" ] 
				then 
					# plot geocoded unwrapped DEM (instead of defomap) 
					PATHDEM=`ls slantRangeDEM.*-*.${PROJ}.${GEOPIXSIZENAME}.bil`
					MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 ${PATHDEM}
				else
					# plot geocoded unwrapped defo 
					MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.${PROJ}.${GEOPIXSIZENAME}.bil
					if [ -e deformationMap.flatttened.${PROJ}.${GEOPIXSIZENAME}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.flatttened.${PROJ}.${GEOPIXSIZENAME}.bil ; fi
					if [ -e deformationMap.interpolated.${PROJ}.${GEOPIXSIZENAME}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.${PROJ}.${GEOPIXSIZENAME}.bil ; fi
					if [ -e deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZENAME}.bil ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZENAME}.bil ; fi
					if [ -e deformationMap.interpolated.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated ; fi
					if [ -e deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated ] ; then MakeFigNoNorm ${GEOPIXW} normal jet 1/1 r4 deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated ; fi
			fi
	fi
	if [ "${MASAMPL}" == "YES" ]
		then
		# plot geocoded Primary
		PATHGEOMAS=`basename *${MASNAME}*.*.mod.${PROJ}.${GEOPIXSIZENAME}.bil`
		#if [ -f "${PATHGEOMAS}" ] && [ -s "${PATHGEOMAS}" ] ; then MakeFigR ${GEOPIXW} 0,100 0.8 1.0 normal gray 1/1 r4 ${PATHGEOMAS} ; fi
		if [ -f "${PATHGEOMAS}" ] && [ -s "${PATHGEOMAS}" ] ; then MakeFigRAuto ${GEOPIXW} 0,100 0.8 1.0 normal gray 1/1 r4 ${PATHGEOMAS} ; fi
	fi
	if [ "${SLVAMPL}" == "YES" ]
		then
		# plot geocoded Secondary
		PATHGEOSLV=`basename *${SLVNAME}*.*.mod.${PROJ}.${GEOPIXSIZENAME}.bil`
		#if [ -f "${PATHGEOSLV}" ] && [ -s "${PATHGEOSLV}" ] ; then MakeFigR ${GEOPIXW} 0,100 0.8 1.0 normal gray 1/1 r4 ${PATHGEOSLV} ; fi
		if [ -f "${PATHGEOSLV}" ] && [ -s "${PATHGEOSLV}" ] ; then MakeFigRAuto ${GEOPIXW} 0,100 0.8 1.0 normal gray 1/1 r4 ${PATHGEOSLV} ; fi
	fi
	if [ "${COHFILE}" == "YES" ]
		then
		# plot geocoded coherence
		PATHGEOCOH=`basename coherence.*.${PROJ}.${GEOPIXSIZENAME}.bil`
		MakeFigR ${GEOPIXW} 0,1 1.5 1.5 normal gray 1/1 r4 ${PATHGEOCOH}	

	fi
	if [ "${INTERF}" == "YES" ]
		then
		# plot interferogram
		PATHGEOINTERF=`basename interfero.*.${PROJ}.${GEOPIXSIZENAME}.bil`
		MakeFigR ${GEOPIXW} 0,3.15 1.1 1.1 normal jet 4/4 r4 ${PATHGEOINTERF} 
	fi
	if [ "${FILTINTERF}" == "YES" ]
		then
		# plot filtered interferogram
		# for interfero.f.${POL} or residualInterferogram.${POL}.f
 		PATHGEOFILTINTERF1=`GetParamFromFile "Filtered interferogram file path" InSARParameters.txt | ${PATHGNU}/gawk -F '/' '{print $NF}' `
 		PATHGEOFILTINTERF=`echo ${PATHGEOFILTINTERF1}.${PROJ}.${GEOPIXSIZENAME}.bil`
 		# On linux computer, for unknown reason it denies renaming geocoded resid interfero with .bil.. 
 		if [ ! -s ${PATHGEOFILTINTERF} ] ; then PATHGEOFILTINTERFNOBIL=`echo ${PATHGEOFILTINTERF1}.${PROJ}.${GEOPIXSIZENAME}` ; mv ${PATHGEOFILTINTERFNOBIL} ${PATHGEOFILTINTERF} ; fi 
 		#MakeFigR ${GEOPIXW} 0,3.1415926535897 1 0.85 normal jet 1/1 r4 ${PATHGEOFILTINTERF} 
 		MakeFig ${GEOPIXW} 1 1.2 normal jet 1/1 r4 ${PATHGEOFILTINTERF} 
	fi
	if [ "${RESINTERF}" == "YES" ]
		then
		# plot residual interferogram
#		PATHGEORESINTERF=`basename residualInterferogram.*.${PROJ}.${GEOPIXSIZENAME}.bil`
		PATHGEORESINTERF1=`GetParamFromFile "Residual interferogram file path" InSARParameters.txt | ${PATHGNU}/gawk -F '/' '{print $NF}' `
		PATHGEORESINTERF=`echo ${PATHGEORESINTERF1}.${PROJ}.${GEOPIXSIZENAME}.bil`
 		# On linux computer, for unknown reason it denies renaming geocoded filt resid interfero with .bil.. 
 		if [ ! -s ${PATHGEORESINTERF} ] ; then PATHGEORESINTERFNOBIL=`echo ${PATHGEORESINTERF1}.${PROJ}.${GEOPIXSIZENAME}` ; mv ${PATHGEORESINTERFNOBIL} ${PATHGEORESINTERF} ; fi 
		#MakeFigR ${GEOPIXW} 0,3.15 1.0 1.0 normal jet 1/1 r4 ${PATHGEORESINTERF} 	
		MakeFig ${GEOPIXW} 1.0 1.2 normal jet 1/1 r4 ${PATHGEORESINTERF} 
	fi
	if [ "${UNWPHASE}" == "YES" ]
		then
		# plot unwrapped phase
		PATHGEOUNWRAPINTERF=`basename unwrappedPhase.*.${PROJ}.${GEOPIXSIZENAME}.bil`
		MakeFigNoNorm ${GEOPIXW} normal jet 4/4 r4 ${PATHGEOUNWRAPINTERF} 
	fi

	if [ "${APPLYMASK}" == "APPLYMASKyes" ] && [ "${UW_METHOD}" == "SNAPHU" ]
		then
		# plot maskedCoherence
		PATHGEOMASKCOH=`basename maskedCoherence.${PROJ}.${GEOPIXSIZENAME}.bil`
		if [ -f ${PATHGEOMASKCOH} ] ; then MakeFigR ${GEOPIXW} 0,1 1.5 1.5 normal gray 1/1 r4 ${PATHGEOMASKCOH} ; fi
	fi

	}	

# Still used for create headers for amplitude image of Primary and Secondary Zoomed x ML
function CreateHDR()
	{
	unset SAMPLES LINES TYPE UTMXmin UTMYmin FILE CREADATE
	local SAMPLES=$1
	local LINES=$2
	local TYPE=$3
	local UTMXmin=$4
	local UTMYmin=$5
	local FILE=$6
	CREADATE=`date`
	echo -e "ENVI \r" > ${FILE}.hdr
	echo -e "description = {\r" >> ${FILE}.hdr
	echo -e "  Create New File Result ${CREADATE}}\r" >> ${FILE}.hdr
	echo -e "samples = ${SAMPLES}\r" >> ${FILE}.hdr
	echo -e "lines   = ${LINES}\r" >> ${FILE}.hdr
	echo -e "bands   = 1\r" >> ${FILE}.hdr
	echo -e "header offset = 0\r" >> ${FILE}.hdr
	echo -e "file type = ENVI Standard\r" >> ${FILE}.hdr
	echo -e "data type = ${TYPE}\r" >> ${FILE}.hdr
	echo -e "interleave = bsq\r" >> ${FILE}.hdr
	echo -e "sensor type = ${SATDIR}\r" >> ${FILE}.hdr
	echo -e "byte order = 0\r" >> ${FILE}.hdr
	case ${PROJ} in 
		"UTM")  
			# not used anymore - fct only with Dummy prjection for Amplitude image in radar geometry 
			
			# Check OS
			OS=`uname -a | cut -d " " -f 1 `
			case ${OS} in 
				"Darwin") 
					EchoTee "Automatic setting of UTM zone must be implemented (e.g. using utm python utm.from_latlon()); see https://pypi.org/project/utm/#files"
					EchoTee "In the mean time, set it manually in FUNCTIONS_FOR_MT.sh in function CreateHDR()."
					# IF YOUR OS IS mac, YOU MUST DEFINE THE UTM ZONE IN LINE BELOW 
					echo -e "map info = {UTM, 1.000, 1.000, ${UTMXmin}, ${UTMYmin}, ${GEOPIXSIZERG}, ${GEOPIXSIZEAZ}, 35, South, WGS-84, units=Meters}\r" >> ${FILE}.hdr ;;
				"Linux")
					EchoTee "Linux : get UTM zone from DEM"
					EASTDEM=`GetParamFromFile "Lower left corner longitude" externalSlantRangeDEM.txt`
					EASTDEG=`echo ${EASTDEM} | cut -d . -f 1`     # degrees from East; West is neg
					EASTDECIM=`echo ${EASTDEM} | cut -d . -f 2 `  # decimal degrees 
					EASTMIN=`echo "60 * 0.${EASTDECIM}" | bc | xargs printf "%.*f\n" 0`  # minutes (rounded)
					
					NORTHDEM=`GetParamFromFile "Lower left corner latitude" externalSlantRangeDEM.txt`
					NORTHDEG=`echo ${NORTHDEM} | cut -d . -f 1 `     # degrees from North; South is neg
					NORTHDECIM=`echo ${NORTHDEM} | cut -d . -f 2 `  # decimal degrees 
					NORTHMIN=`echo "60 * 0.${EASTDECIM}" | bc | xargs printf "%.*f\n" 0`  # minutes (rounded)
					
					UTMZONE=`echo E${EASTDEG}d${EASTMIN} N${NORTHDEG}d${NORTHMIN} | GeoConvert -m -p -3 | cut -c 1-2`
					
					if [[ ${NORTHDEG} -gt 0 ]]; then NS="North" ; else NS="South" ; fi
				
					EchoTee "UTM zone is ${UTMZONE} ${NS}"
					echo -e "map info = {UTM, 1.000, 1.000, ${UTMXmin}, ${UTMYmin}, ${GEOPIXSIZERG}, ${GEOPIXSIZEAZ}, ${UTMZONE}, ${NS}, WGS-84, units=Meters}\r" >> ${FILE}.hdr	;;
				*)
					EchoTee "I can't figure out your Operatingh System : set you UTM zone manually in FUNCTIONS_FOR_MT.sh in function CreateHDR()."
					# IF YOUR OS IS NOT RECOGNIZED, YOU MUST DEFINE THE UTM ZONE IN LINE BELOW 
					echo -e "map info = {UTM, 1.000, 1.000, ${UTMXmin}, ${UTMYmin}, ${GEOPIXSIZE}, ${GEOPIXSIZE}, 35, South, WGS-84, units=Meters}\r" >> ${FILE}.hdr 	;;
			esac		
			;;
		"LatLong")  
			# not used anymore - fct only with Dummy projection for Amplitude image in radar geometry
			echo -e "map info = {Geographic Lat/Lon, 1.000, 1.000, ${UTMXmin}, ${UTMYmin}, ${GEOPIXSIZERG}, ${GEOPIXSIZEAZ}, WGS-84, units=Degrees}\r" >> ${FILE}.hdr
			;;
		"Dummy")
			# attention, the format was tricked in order to get the UTMXmin and Ymin parameters to be used as first pixel coordinates
			echo -e "map info = {Dummy, ${UTMXmin}, ${UTMYmin}, 0 ,  0 ,  1 , 1 ,  WGS-84, units=Degrees}\r" >> ${FILE}.hdr
			;;
	esac
	echo -e "data ignore value = -32768\r" >> ${FILE}.hdr
	# Data type:
	# 1 = Byte: 8-bit unsigned integer
	# 2 = Integer: 16-bit signed integer
	# 3 = Long: 32-bit signed integer
	# 4 = Floating-point: 32-bit single-precision
	# 5 = Double-precision: 64-bit double-precision floating-point
	# 6 = Complex: Real-imaginary pair of single-precision floating-point
	# 9 = Double-precision complex: Real-imaginary pair of double precision floating-point
	# 12 = Unsigned integer: 16-bit
	# 13 = Unsigned long integer: 32-bit
	# 14 = 64-bit long integer (signed)
	# 15 = 64-bit unsigned long integer (unsigned)
	
	#gsed -i $'s/$/\r/g' ${FILE}.hdr   # Unix to DOS
	}

function RemovePlane()
	{
	if [ "${PROCESSMODE}" != "TOPO" ] # not a good idea to remove plane for DEM because it would be set to sea level etc...
		then 
			# Remove best plane 
			bestPlaneRemoval2 ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval.txt -create
	
			if [ ${INTERPOL} == "BEFORE" ] || [ ${INTERPOL} == "BOTH" ]
				then
					FILETODETREND=${RUNDIR}/i12/InSARProducts/deformationMap.interpolated
				else
					FILETODETREND=${RUNDIR}/i12/InSARProducts/deformationMap	
			fi
			EchoTee "Remove best plane from ${FILETODETREND}" 
			XDIMTODETREND=`GetParamFromFile "Deformation measurement range dimension [pix]" InSARParameters.txt`
			YDIMTODETREND=`GetParamFromFile "Deformation measurement azimuth dimension [pix]" InSARParameters.txt`
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval.txt "File to be corrected" ${FILETODETREND} > /dev/null
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval.txt "X dimension of the file to be corrected" ${XDIMTODETREND} > /dev/null
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval.txt "Y dimension of the file to be corrected" ${YDIMTODETREND} > /dev/null
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval.txt "Reference file path or NONE" "NONE" > /dev/null
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval.txt "Threshold file" "NONE"  > /dev/null
	
			bestPlaneRemoval2 ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval.txt
	
			# make raster
			MakeFig ${XDIMTODETREND} 1.0 1.2 normal jet 1/1 r4 ${FILETODETREND}.flattened
	fi
	}	

function GetSatOrbDetails()
	{
	HEADINGDIRFULL=`GetParamFromFile "Heading direction" masterSLCImageInfo.txt`
	HEADINGDIR=`echo "${HEADINGDIRFULL}" | cut -c 1-3`
	LOOKFULL=`GetParamFromFile "Incidence angle at median slant range " masterSLCImageInfo.txt`
	LOOK=`echo "${LOOKFULL}" | cut -c 1-4`
	
	HEADINGFULL=`GetParamFromFile "Azimuth heading" masterSLCImageInfo.txt`
	HEADING=`echo "${HEADINGFULL}" | cut -c 1-5`
	
	BpFULL=`GetParamFromFile "Perpendicular baseline component at image centre" InSARParameters.txt`
	Bp=`echo "${BpFULL}" | cut -c 1-5`
	
	BTFULL=`GetParamFromFile "Temporal baseline [day]" InSARParameters.txt`
	if [ ${BTFULL} == "(null)" ] ; then 
			BT=0
		else  
			BT=`echo "${BTFULL}" | cut -c 1-5 | ${PATHGNU}/gsed "s/ //g"`
	fi
	HAFULL=`GetParamFromFile "Ambiguity altitude at scene centre" InSARParameters.txt`
	HA=`echo "${HAFULL}" | cut -c 1-5`
	}
	
function ManageGeocoded()
	{
	EchoTee "--------- Prepare Geocoding---------------------"
	if [ -f ${MASSPROCESSPATHLONG}/Geocoded/Ampli/${MASNAME}.*.hdr ] && [ -s ${MASSPROCESSPATHLONG}/Geocoded/Ampli/${MASNAME}.*.hdr ]
		then 
			GEOCMAST="NO"	
			EchoTee "Primary image already geocoded. Will skip it"	
		else 
			GEOCMAST="YES"	
			EchoTee "Primary image Not geocoded yet. Will do it"							
	fi	
	if [ -f ${MASSPROCESSPATHLONG}/Geocoded/Ampli/${SLVNAME}.*.hdr ] && [ -s ${MASSPROCESSPATHLONG}/Geocoded/Ampli/${SLVNAME}.*.hdr ]
		then 
			GEOCSLAV="NO"	
			EchoTee "Secondary image already geocoded. Will skip it"	
		else 
			GEOCSLAV="YES"	
			EchoTee "Secondary image Not geocoded yet. Will do it"					
	fi	
	if [ ${SKIPUW} == "SKIPyes" ] ; then
							#  SLRDEM, MASAMPL, SLVAMPL, COH, INTERF, FILTINTERF, RESINTERF, UNWPHASE
			FILESTOGEOC=`echo "NO ${GEOCMAST} ${GEOCSLAV} YES NO YES YES NO"`	
		else 
			FILESTOGEOC=`echo "YES ${GEOCMAST} ${GEOCSLAV} YES NO YES YES YES"`
	fi
	EchoTee "Shall geocode the sequence : ${FILESTOGEOC}"
	if [ ${PROJ} == "UTM" ]
		then	
			EchoTee "UTM geoprojection"
			GeocUTM ${FILESTOGEOC}
			# get size of geocoded product
			GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
 			GEOPIXL=`GetParamFromFile "Y size of geoprojected products" geoProjectionParameters.txt`
		else
			EchoTee "Lat Long geoprojection" 
			EchoTee " not opperational yet. Please use UTM"
			GeocUTM ${FILESTOGEOC}
	fi
	if [ ${SKIPUW} == "SKIPyes" ] && [ ${SKIPUW} == "Mask" ]  ; then
		EchoTee "Skip geocoding as requested, hence obviously skip interpolation and Detrending..."
	else
		# Interpolation
		case ${INTERPOL} in 
			"AFTER")  
				if [ ${REMOVEPLANE} == "DETREND" ] 
						then 
							EchoTee "Request interpolation after geocoding."
							PATHDEFOGEOMAP=deformationMap.flattened.${PROJ}.${GEOPIXSIZENAME}.bil
							fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
							#PATHDEFOGEOMAP=deformationMap.flattened.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated	
						else 
							EchoTee "Request interpolation after geocoding."
							PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZENAME}.bil
							fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
							#PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated	
				fi ;;
			"BOTH")  
				if [ ${REMOVEPLANE} == "DETREND" ] 
						then 
							EchoTee "Request interpolation before and after geocoding."
							PATHDEFOGEOMAP=deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZENAME}.bil
							fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
							#PATHDEFOGEOMAP=deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated   
						else 
							EchoTee "Request interpolation before and after geocoding."
							PATHDEFOGEOMAP=deformationMap.interpolated.${PROJ}.${GEOPIXSIZENAME}.bil
							fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
							#PATHDEFOGEOMAP=deformationMap.interpolated.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated   
				fi ;;
			"BEFORE") 
				EchoTee "Do not request interpolation after geocoding" 
				#PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZENAME}.bil
				;;		
		esac
	fi
	# Plot 
	PlotGeoc ${FILESTOGEOC}

	# rename all geocoded products as ${FILENOEXT}_${SATDIR}_${AD}${LOOK}_${TRKDIR}_${MAS}_${SLV}_${Bp}m_${HA}m_${BT}days_${HEADING}deg.${FILEEXT}	
	GetSatOrbDetails
	
 	RenameAllProducts 
	
# rename here Primary S1 STRIPMAP from MASDATE to MASNAME
 	if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "STRIPMAP" ] ; then 		
 		mv ${MAS}.${POLMAS}.mod.UTM.${GEOPIXSIZENAME}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg ${MASNAME}.${POLMAS}.mod.UTM.${GEOPIXSIZENAME}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg 2>/dev/null
  		mv ${MAS}.${POLMAS}.mod.UTM.${GEOPIXSIZENAME}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr ${MASNAME}.${POLMAS}.mod.UTM.${GEOPIXSIZENAME}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr 2>/dev/null
 	fi	
 

	# Move geocoded to specific mass dir
	EchoTee " Shall move rev to /Geocoded"
	EchoTee "    and copy rasters to /GeocodedRasters \n"
	mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters	
	mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/Ampli
	mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/Coh	
	mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/Defo
	mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/InterfFilt
	mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/InterfResid
	mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/UnwrapPhase			

	mkdir -p ${MASSPROCESSPATHLONG}/Geocoded
	mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/Ampli
	mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/Coh
	mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/Defo
	mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/InterfFilt
	mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/InterfResid
	mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/UnwrapPhase

	cd ${RUNDIR}/i12/GeoProjection

	# postfix for geocoded images
	POSTFIX=".UTM.${GEOPIXSIZENAME}.bil"
	POLPOSTFIX=".${POLMAS}-${POLSLV}.UTM.${GEOPIXSIZENAME}.bil"
	POLPOSTFIXFILT=".${POLMAS}-${POLSLV}.f.UTM.${GEOPIXSIZENAME}.bil"

	if [ ! -f ${MASSPROCESSPATHLONG}/Geocoded/Ampli/${MASNAME}.${POLMAS}.mod${POSTFIX}*.hdr ]
		then 
			MoveGeocRename ${MASNAME}.${POLMAS}.mod Ampli
	fi	
	
	if [ ! -f ${MASSPROCESSPATHLONG}/Geocoded/Ampli/${SLVNAME}.${POLSLV}.mod${POSTFIX}*.hdr ]
		then 
			MoveGeocRename ${SLVNAME}.${POLSLV}.mod Ampli
	fi
	
	MoveGeocRename coherence Coh
	MoveGeocRename residualInterferogram${POLPOSTFIX} InterfResid
	MoveGeocRename residualInterferogram${POLPOSTFIXFILT} InterfFilt

	if [ ${SKIPUW} == "SKIPyes" ] ; then
		EchoTee "NO deformation nor unwrapped files to process"
	else 
		MoveGeocRename deformationMap${POSTFIX} Defo
		if [ "${SKIPUW}" != "Mask" ]  ; then 
			MoveGeocRename unwrappedPhase${POLPOSTFIX} UnwrapPhase
		fi

		if [ -f ${RUNDIR}/i12/GeoProjection/deformationMap.flattened${POSTFIX}_*deg ] && [ -s ${RUNDIR}/i12/GeoProjection/deformationMap.flattened${POSTFIX}_*deg ]    # DefoDetrend
			then 
				mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/DefoDetrend
				mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/DefoDetrend
				MoveGeocRename deformationMap.flattened${POSTFIX}_ DefoDetrend
		fi
		if [ -f ${RUNDIR}/i12/GeoProjection/deformationMap.interpolated${POSTFIX}_*deg ] && [ -s ${RUNDIR}/i12/GeoProjection/deformationMap.interpolated${POSTFIX}_*deg ]  # DefoInterpol
			then 
				mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/DefoInterpol
				mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/DefoInterpol
				MoveGeocRename deformationMap.interpolated${POSTFIX}_ DefoInterpol
		fi
		if [ -f ${RUNDIR}/i12/GeoProjection/deformationMap.interpolated.flattened${POSTFIX}_*deg ] && [ -s ${RUNDIR}/i12/GeoProjection/deformationMap.interpolated.flattened${POSTFIX}_*deg ]  # DefoInterpolDetrend
			then 
				mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/DefoInterpolDetrend
				mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/DefoInterpolDetrend
				MoveGeocRename deformationMap.interpolated.flattened${POSTFIX}_ DefoInterpolDetrend
		fi
		if [ -f ${RUNDIR}/i12/GeoProjection/deformationMap.interpolated${POSTFIX}.interpolated_*deg ] && [ -s ${RUNDIR}/i12/GeoProjection/deformationMap.interpolated${POSTFIX}.interpolated_*deg ]  # DefoInterpolx2
			then 
				mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/DefoInterpolx2
				mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/DefoInterpolx2
				MoveGeocRename deformationMap.interpolated${POSTFIX}.interpolated_ DefoInterpolx2
		fi
		if [ -f ${RUNDIR}/i12/GeoProjection/deformationMap.interpolated.flattened${POSTFIX}.interpolated_*deg ] && [ -s ${RUNDIR}/i12/GeoProjection/deformationMap.interpolated.flattened${POSTFIX}.interpolated_*deg ]  # DefoInterpolx2Detrend
			then 
				mkdir -p ${MASSPROCESSPATHLONG}/GeocodedRasters/DefoInterpolx2Detrend
				mkdir -p ${MASSPROCESSPATHLONG}/Geocoded/DefoInterpolx2Detrend
				MoveGeocRename deformationMap.interpolated.flattened${POSTFIX}.interpolated_ DefoInterpolx2Detrend
		fi
	fi
	}
	
function MoveGeocRename()
	{
	unset IMG TARGETDIR
	local IMG=$1 # MAS, SLV or BOTH
	local TARGETDIR=$2 # where to store figs

	# keep a link after moving, just in case... 
	EnviToBeCopied=`ls ${RUNDIR}/i12/GeoProjection/*${IMG}*deg`
	EnviHdrToBeCopied=`ls ${RUNDIR}/i12/GeoProjection/*${IMG}*deg.hdr`
	RasToBeCopied=`ls ${RUNDIR}/i12/GeoProjection/*${IMG}*deg.ras`
	mv -f ${EnviToBeCopied} ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR} 2>/dev/null	#  mute possible complaining message that permission can't be preserved, as it may occur when moving from Mac to Linux or Windows 
	#ln -s ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR}/$(basename ${EnviToBeCopied}) ${RUNDIR}/i12/GeoProjection/$(basename ${EnviToBeCopied})
	EchoTee "*${IMG}*deg copied to /Geocoded/${TARGETDIR}"
	mv -f ${EnviHdrToBeCopied} ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR} 2>/dev/null	#  mute possible complaining message that permission can't be preserved, as it may occur when moving from Mac to Linux or Windows 
	#ln -s ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR}/$(basename ${EnviHdrToBeCopied}) ${RUNDIR}/i12/GeoProjection/$(basename ${EnviHdrToBeCopied})
	EchoTee "*${IMG}*deg.hdr copied to /Geocoded/${TARGETDIR}"
	if [ "${FIG}" == "FIGyes" ] 
		then 
			cp -f ${RasToBeCopied} ${MASSPROCESSPATHLONG}/GeocodedRasters/${TARGETDIR}
			EchoTee "*${IMG}*deg.ras copied to /GeocodedRasters/${TARGETDIR}"
	fi	
	}

function MoveGeoc()
	{
	unset IMG ENDFIX
	local IMG=$1 # MAS, SLV or BOTH
	local ENDFIX=$2 # type of postfix for naming
	# may consider mv instead of cp for sake of space disk
	cp ${IMG}${ENDFIX} ${MASSPROCESSPATHLONG}/Geocoded/Ampli/${IMG}${ENDFIX}
	cp ${IMG}${ENDFIX}.hdr ${MASSPROCESSPATHLONG}/Geocoded/Ampli/${IMG}${ENDFIX}.hdr
	if [ "${FIG}" == "FIGyes"  ] ; then cp ${IMG}${ENDFIX}.ras ${MASSPROCESSPATHLONG}/GeocodedRasters/Ampli/${IMG}${ENDFIX}.ras ; fi
	EchoTee "${IMG}${ENDFIX} copied to /Geocoded/Ampli"
	}

function RenameAllProducts()
	{
	unset FILE 
	local FILE
	#for FILE in `ls | ${PATHGNU}/grep -v ".hdr" | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".rev" | ${PATHGNU}/grep -v "xRef" | ${PATHGNU}/grep -v "yRef" | ${PATHGNU}/grep -v "xRadius" | ${PATHGNU}/grep -v "yRadius" | ${PATHGNU}/grep -v "projMat"`
	#for FILE in `ls | ${PATHGNU}/grep -v ".ras" | ${PATHGNU}/grep -v ".sh" | ${PATHGNU}/grep -v ".rev" | ${PATHGNU}/grep -v "xRef" | ${PATHGNU}/grep -v "yRef" | ${PATHGNU}/grep -v "xRadius" | ${PATHGNU}/grep -v "yRadius" | ${PATHGNU}/grep -v "projMat"`
	for FILE in `ls | ${PATHGNU}/grep -v "\.sh$" | ${PATHGNU}/grep -v "\.rev$" | ${PATHGNU}/grep -v "xRef" | ${PATHGNU}/grep -v "yRef" | ${PATHGNU}/grep -v "xRadius" | ${PATHGNU}/grep -v "yRadius" | ${PATHGNU}/grep -v "projMat"`
	do
		FILENOEXT=`echo "${FILE}" |  ${PATHGNU}/gawk '{gsub(/.*[/]|[.]{1}[^.]+$/, "", $0)} 1'`
		FILEEXT=`echo "${FILE}" |  ${PATHGNU}/gawk -F'[.]' '{print $NF}'`
		case ${FILEEXT} in 
			"bil")
				mv ${FILE} ${FILENOEXT}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg ;;
			"ras")
				if [ "${FIG}" == "FIGyes"  ] ; then mv ${FILE} ${FILENOEXT}_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.ras ; fi ;;
			"hdr")
				mv ${FILE} ${FILENOEXT}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr ;;
			"interpolated")
				mv ${FILE} ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
				# get any existing hdr and adapt it 
				FORMERHDR=`ls *.hdr | head -1`
				cp ${FORMERHDR} ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
				${PATHGNU}/gsed -i "/Description/c\Description = {${FILENOEXT}.interpolated" ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr ;;
			"flattened")
				mv ${FILE} ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
				# get any existing hdr and adapt it 
				FORMERHDR=`ls *.hdr | head -1`
				cp ${FORMERHDR} ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
				${PATHGNU}/gsed -i "/Description/c\Description = {${FILENOEXT}.flattened" ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MAS}_${SLV}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr ;;

		esac		
	done 
	}

function RenameAllSlantRangeProducts()
	{
	mv coherence.${MASPOL}-${SLVPOL} coherence.${MASPOL}-${SLVPOL}.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days
	if [ "${FIG}" == "FIGyes"  ] ; then mv coherence.${MASPOL}-${SLVPOL}.ras coherence.${MASPOL}-${SLVPOL}.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days.ras ; fi

	if [ -f deformationMap  ] ; then 
		mv deformationMap deformationMap.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days
	if [ "${FIG}" == "FIGyes"  ] ; then mv deformationMap.ras deformationMap.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days.ras ; fi
	fi
	if [ -f deformationMap.interpolated  ] ; then 
		mv deformationMap.interpolated deformationMap.interpolated.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days
	if [ "${FIG}" == "FIGyes"  ] ; then mv deformationMap.interpolated.ras deformationMap.interpolated.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days.ras ; fi
	fi
	if [ -f deformationMap.interpolated.flattened  ] ; then 
		mv deformationMap.interpolated.flattened deformationMap.interpolated.flattened.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days
	if [ "${FIG}" == "FIGyes"  ] ; then mv deformationMap.interpolated.flattened.ras deformationMap.interpolated.flattened.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days.ras ; fi
	fi

	mv residualInterferogram.${MASPOL}-${SLVPOL} residualInterferogram.${MASPOL}-${SLVPOL}.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days
	if [ "${FIG}" == "FIGyes"  ] ; then mv residualInterferogram.${MASPOL}-${SLVPOL}.ras residualInterferogram.${MASPOL}-${SLVPOL}.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days.ras ; fi
	mv residualInterferogram.${MASPOL}-${SLVPOL}.f residualInterferogram.${MASPOL}-${SLVPOL}.f.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days
	if [ "${FIG}" == "FIGyes"  ] ; then mv residualInterferogram.${MASPOL}-${SLVPOL}.f.ras residualInterferogram.${MASPOL}-${SLVPOL}.f.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days.ras ; fi
	
	if [ -f snaphuZoneMap  ] ; then 
		mv snaphuZoneMap snaphuZoneMap.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days
	fi
	
	if [ "${SKIPUW}" != "Mask" ] && [ "${SKIPUW}" != "SKIPyes" ]  
		then 
			mv unwrappedPhase.${MASPOL}-${SLVPOL} unwrappedPhase.${MASPOL}-${SLVPOL}.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days
			if [ "${FIG}" == "FIGyes"  ] ; then mv unwrappedPhase.${MASPOL}-${SLVPOL}.ras unwrappedPhase.${MASPOL}-${SLVPOL}.${MAS}_${SLV}_Bp${Bp}m_BT${BT}days.ras ; fi
	fi
	}

