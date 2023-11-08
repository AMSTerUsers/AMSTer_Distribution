#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at computing the slant range DEM (and mask if requested and path provided in ParametersFile.txt) 
#    for a given image. DEM (and mask) can be used later for a pair or Global Primary (supermaster)  
#    processing, as the results are stored in appropriate dir.
# Processing is perfomed and results are stored first in 
#    /Volumes.../SAR_CSL/SATDIR/TRKDIR/Crop_REGION_CROP/MAS.csl
# And results are also stored in the Crop Dir for Mass Processing if it exists, i.e.  
#    /Volumes.../SAR_CSL/SATDIR/TRKDIR/SMCrop_SM_SUPERMASTER_REGION_CROP/MAS.csl
#
# It is based on SinglePair.sh VBeta 2.0, that is why it started with version nr Beta 2.0. 
#    and from which all the SLV related stuffs were removed because useless for DEM
#
# Parameters : - PRM date or S1 name (accept both date or name for S1)
#              - PRAMETERS file, incl path (e.g. /Users/doris/PROCESS/SCRIPTS_MT/___V20190710_LaunchMTparam.txt)
#
# Dependencies:
#	- AMSTer Engine and AMSTer Engine Tools, at least V20190716
#	- PRAMETERS file, at least V 20190710
#   - The FUNCTIONS_FOR_MT.sh file with the function used by the script. Will be called automatically by the script
#   - gnu sed (gsed) and gnu awk (gawk) for more compatibility. 
#   - cpxfiddle is usefull though not mandatory. This is part of Doris package (TU Delft) available here :
#            http://doris.tudelft.nl/Doris_download.html. 
#   - bc (for basic computations in scripts)
#   - maybe some Mac functions such as "say" or espeak for Linux but might not be mandatory 
#	 - linux trap function
#
# New in Distro V 1.0:		- Based on developpement version of SinglePair.sh VBeta 2.0 and 
#                       	  version of MasterDEM.sh beta2.2.2
# New in Distro V 1.0.1:	- some cleaning and add PATHGNU to gsed
# New in Distro V 1.2.0:	- When using S1, creates an empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt to let ReadAll_Img.sh to know
#							  that it can't remove the processed products of S1 data of the same mode as the one under progress to avoid prblms.
#							  Note that the script will remove that file at normal termination or CTRL-C, but not if script is terminated using kill. In such a case, you need to remove the file manaully 
# New in Distro V 1.2.1:	- allows processing S1 WS with Zoom, i.e. Requires CropYes but not before zooming, hence skipped here 
# New in Distro V 2.0.0:	- correct bug that preventend zooming when data where already read with zoom=1 (was only zooming at geocoding)
# New in Distro V 2.1.0:	- Keep track of MasTer Engine version in /Projecting_DEM_w_MasTerEngine_V.txt by looking at MasTer Engine source dir 
# New in Distro V 2.1.1: 	- read UTM zone for geocoding, though not needed here (for completeness)
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

MASINPUT=$1					# date or S1 name of Primary image (for S1 : it could be either in the form of yyyymmdd or S1a/b_sat_trk_a/d)
PARAMFILE=$2				# File with the parameters needed for the run
COMMENT=_TEMP_FOR_DEM

echo "Command Launched: ${PRG} ${MASINPUT} ${PARAMFILE}"

if [ $# -lt 2 ] ; then echo " Usage $0 MAS PARAMETER_FILE "; exit; fi

# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

# Read here all parameters from ParametersFile.txt although not all of them are used here. Could be cleaned...
PROROOTPATH=`GetParam PROROOTPATH`			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name. 
DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 
FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored

DEMDIR=`GetParam DEMDIR`					# DEMDIR, path to dir where DEM is stored
RECOMPDEM=`GetParam "RECOMPDEM,"`			# RECOMPDEM, recompute DEM even if already there (FORCE), or trust the one that would exist (KEEP)
SIMAMP=`GetParam "SIMAMP,"`					# SIMAMP, (SIMAMPno or SIMAMPyes). Option to compute simulated amplitude during Extenral DEM generation - usually not needed.

POP=`GetParam "POP,"`						# POP, option to pop up figs or not (POPno or POPyes)
FIG=`GetParam "FIG,"`						# FIG, option to compute or not the quick look using cpxfiddle (FIGno or FIGyes)

SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)

CROP=`GetParam "CROP,"`						# CROP, CROPyes or CROPno 
FIRSTL=`GetParam "FIRSTL,"`					# Crop limits: first line to use
LASTL=`GetParam "LASTL,"`					# Crop limits: last line to use
FIRSTP=`GetParam "FIRSTP,"`					# Crop limits: first point (row) to use
LASTP=`GetParam "LASTP,"`					# Crop limits: last point (row) to use

MLAMPLI=`GetParam "MLAMPLI,"`				# MLAMPLI, Multilooking factor for amplitude images reduction (used for coregistration - 4-6 is appropriate). If rectangular pixel, it will be multiplied by corresponding ratio.
ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
PIXSHAPE=`GetParam "PIXSHAPE,"`				# PIXSHAPE, pix shape for products : SQUARE or ORIGINALFORM   
CALIBSIGMA=`GetParam "CALIBSIGMA,"`			# CALIBSIGMA, if SIGMAYES it will output sigma nought calibrated amplitude file at the insar product generation step  

COH=`GetParam "COH,"`						# Coarse coregistration correlation threshold  
CCOHWIN=`GetParam "CCOHWIN,"`     			# CCOHWIN, Coarse coreg window size (64 by default but may want less for very small crop)
CCDISTANCHOR=`GetParam "CCDISTANCHOR,"`		# CCDISTANCHOR, Coarse registration range & az distance between anchor points [pix]

FCOH=`GetParam "FCOH,"`						# Fine coregistration correlation threshold 
FCOHWIN=`GetParam "FCOHWIN,"`				# FCOHWIN, Fine coregistration window size (size in az or rg is computed based on Az/Rg ratio) 
FCDISTANCHOR=`GetParam "FCDISTANCHOR,"`		# FCDISTANCHOR, Fine registration range & az distance between anchor points [pix]

PROCESSMODE=`GetParam "PROCESSMODE,"`		# PROCESSMODE, DEFO to produce DInSAR or TOPO to produce DEM
		
INITPOL=`GetParam "INITPOL,"`		        # INITPOL, force polarisation at initInSAR for InSAR processing. If it does not exists it will find the first compatible MAS-SLV pol. 
LLRGCO=`GetParam "LLRGCO,"`					# LLRGCO, Lower Left Range coord offset for final interferometric products generation. Used mainly for Shadow measurements
LLAZCO=`GetParam "LLAZCO,"`					# LLAZCO, Lower Left Azimuth coord offset for final interferometric products generation. Used mainly for Shadow measurements
INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
COHESTIMFACT=`GetParam "COHESTIMFACT,"`		# COHESTIMFACT, Coherence estimator window size
FILTFACTOR=`GetParam "FILTFACTOR,"`			# Range and Az filtering factor for interfero
POWSPECSMOOTFACT=`GetParam "POWSPECSMOOTFACT,"`	# POWSPECSMOOTFACT, Power spectrum filtering factor (for adaptative filtering)

APPLYMASK=`GetParam "APPLYMASK,"`			# APPLYMASK, Apply mask before unwrapping (APPLYMASKyes or APPLYMASKno)
if [ ${APPLYMASK} == "APPLYMASKyes" ] 
 then 
  PATHTOMASK=`GetParam "PATHTOMASK,"`			# PATHTOMASK, geocoded mask file name and path
 else 
  PATHTOMASK=`echo "NoMask"`
fi

SKIPUW=`GetParam "SKIPUW,"`					# SKIPUW, SKIPyes skips unwrapping and geocode all available products

CONNEXION_MODE=`GetParam "CONNEXION_MODE,"`	# CONNEXION_MODE, number of times that connexion search radius is augmented when stable connections are found ; 0 search along all coh zone  
BIASCOHESTIM=`GetParam "BIASCOHESTIM,"`		# BIASCOHESTIM, Biased coherence estimator range & Az window size (do not appli pix rratio) 
BIASCOHSPIR=`GetParam "BIASCOHSPIR,"`		# BIASCOHSPIR, Biased coherence square spiral size (if residual fringes are not unwrapped decrease it; must be odd)  
COHCLNTHRESH=`GetParam "COHCLNTHRESH,"`		# COHCLNTHRESH, Coherence cleaning threshold - used for mask
FALSERESCOHTHR=`GetParam "FALSERESCOHTHR,"`	# FALSERESCOHTHR, False Residue Coherence Threshold: higher is much slower. Use max 0.15 e.g. in crater 
UW_METHOD=`GetParam "UW_METHOD,"`			# UW_METHOD, Select phase unwrapping method (SNAPHU, CIS or DETPHUN)
DEFOTHRESHFACTOR=`GetParam "DEFOTHRESHFACTOR,"`	# DEFOTHRESHFACTOR, Snaphu : Factor applied to rho0 to get threshold for whether or not phase discontinuity is possible. rho0 is the expected, biased correlation measure if true correlation is 0. Increase if not good. 
DEFOCONST=`GetParam "DEFOCONST,"`				# DEFOCONST, Snaphu : Ratio of phase discontinuity probability density to peak probability density expected for discontinuity-possible pixel differences. Value of 1 means zero cost for discontinuity, 0 means infinite cost. Decrease if prblm. 
DEFOMAX_CYCLE=`GetParam "DEFOMAX_CYCLE,"`		# DEFOMAX_CYCLE, Snaphu : Max nr of expected phase cycle discontinuity. For topo where no phase jump is expected, it can be set to zero. 
SNAPHUMODE=`GetParam "SNAPHUMODE,"`				# SNAPHUMODE, Snaphu : TOPO, DEFO, SMOOTH, or NOSTATCOSTS. 
DETITERR=`GetParam "DETITERR,"`				# DETITERR, detPhUn : Number of iterration for detPhUn (Integer: 1, 2 or 3 is generaly OK)
DETCOHTHRESH=`GetParam "DETCOHTHRESH,"`		# DETCOHTHRESH, Coherence threshold
ZONEMAP=`GetParam "ZONEMAP"` 				# ZONEMAP, if ZoneMapYes, it will create a map with the unwrapped zones named snaphuZoneMap. Each continuously unwrapped zone is numbered (from 1 to...)
ZONEMAPSIZE=`GetParam "ZONEMAPSIZE"` 		# ZONEMAPSIZE, Minimum size of unwrapped zone to map (in frazction of total nr of pixels)
ZONEMAPCOST=`GetParam "ZONEMAPCOST"` 		# ZONEMAPCOST, Cost threshold for connected components (zones). Higher threshold will give smaller connected zones
ZONEMAPTOTAL=`GetParam "ZONEMAPTOTAL"` 		# ZONEMAPTOTAL, Maximum number of mapped zones	

INTERPOL=`GetParam "INTERPOL,"`				# INTERPOL, interpolate the unwrapped interfero BEFORE or AFTER geocoding or BOTH. 	
REMOVEPLANE=`GetParam "REMOVEPLANE,"`		# REMOVEPLANE, if DETREND it will remove a best plane after unwrapping. Anything else will ignore the detrending. 	

PROJ=`GetParam "PROJ,"`						# PROJ, Chosen projection (UTM or GEOC)
GEOCMETHD=`GetParam "GEOCMETHD,"`			# GEOCMETHD, Resampling Size of Geocoded product: Forced (at FORCEGEOPIXSIZE - convenient for further MSBAS), Auto (closest multiple of 10), Closest (closest to ML az sampling)
RADIUSMETHD=`GetParam "RADIUSMETHD,"`		# LetCIS (CIS will compute best radius) or forced to a given radius 
RESAMPMETHD=`GetParam "RESAMPMETHD,"`		# TRI = Triangulation; AV = weighted average; NN = nearest neighbour 
WEIGHTMETHD=`GetParam "WEIGHTMETHD,"`		# Weighting method : ID = inverse distance; LORENTZ = lorentzian 
IDSMOOTH=`GetParam "IDSMOOTH,"`				# ID smoothing factor  
IDWEIGHT=`GetParam "IDWEIGHT,"`				# ID weighting exponent 
FWHM=`GetParam "FWHM,"`						# Lorentzian Full Width at Half Maximum
ZONEINDEX=`GetParam "ZONEINDEX,"`			# Zone index  
FORCEGEOPIXSIZE=`GetParam "FORCEGEOPIXSIZE,"` # Pixel size (in m) wanted for your final products. Required for MSBAS

UTMZONE=`GetParam "UTMZONE,"`				# UTMZONE, letter of row and nr of col of the zone where coordinates below are computed (e.g. U32)
XMIN=`GetParam "XMIN,"`						# XMIN, minimum X UTM coord of final Forced geocoded product
XMAX=`GetParam "XMAX,"`						# XMAX, maximum X UTM coord of final Forced geocoded product
YMIN=`GetParam "YMIN,"`						# YMIN, minimum Y UTM coord of final Forced geocoded product
YMAX=`GetParam "YMAX,"`						# YMAX, maximum Y UTM coord of final Forced geocoded product

REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
DEMNAME=`GetParam "DEMNAME,"`				# DEMNAME, name of DEM inverted by lines and columns

RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data will be stored 

eval PROPATH=${PROROOTPATH}/${SATDIR}

source ${FCTFILE}

# Define Crop Dir
if [ ${CROP} == "CROPyes" ]
	then
		if [ ${ZOOM} -eq 1 ] 
			then 
				CROPDIR=/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP} #_Zoom${ZOOM}_ML${INTERFML}
			else
				CROPDIR=/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}_Zoom${ZOOM} #_ML${INTERFML}
		fi		
	else
		CROPDIR=/NoCrop
fi

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
eval RNDM1=`echo $(( $RANDOM % 10000 ))`

if [ "${SATDIR}" == "S1" ] ; then 
		# Creates an empty file .../SAR_CSL/S1/REGION/NoCrop/.DoNotUpdateProducts_Date_RNDM.txt to let ReadAll_Img.sh to know
		# that it can't remove the processed products of S1 data of the same mode as the one under progress to avoid prblms
		eval FLAGUSAGE=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/DoNotUpdateProducts_${RUNDATE}_${RNDM1}_DEM.txt
		function CleanExit()
			{
				# if ctrl-c is pressed, it removes ${FLAGUSAGE} before exiting
				# NOTE that it does not work if script is terminated using kill !
				rm -f ${FLAGUSAGE}
				exit
			}
			
		trap CleanExit SIGINT
		# also clean if exit
		trap "rm -f ${FLAGUSAGE}" EXIT
		touch ${FLAGUSAGE}

fi 

# Prepare image naming
MAS=`GetDateCSL ${MASINPUT}`    # i.e. if S1 is given in the form of name, MAS is now only the date anyway
if [ ${SATDIR} == "S1" ] ; then 
		MASNAME=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${MAS} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
		MASDIR=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${MAS}` 		 # i.e. if S1 is given in the form of date, MASDIR is now MASNAME.csl
	else
		MASNAME=${MAS}
		MASDIR=${MASNAME}.csl 
fi	

if [ "${SATDIR}" == "S1" ] 
	then 
		S1ID=`GetParamFromFile "Scene ID" SAR_CSL_SLCImageInfo.txt`
		S1MODE=`echo ${S1ID} | cut -d _ -f 2`	
		if [ ${S1MODE} == "IW" ] || [ ${S1MODE} == "EW" ]
			then 
				S1MODE="WIDESWATH"
				CROPDIR=/NoCrop
			else 
				S1MODE="STRIPMAP"
		fi
		EchoTee "Processing S1 images in mode ${S1MODE}" 
	else 
		S1MODE="DUMMY"
fi

# Define Dir where data are/will be cropped
INPUTDATA=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}
mkdir -p ${INPUTDATA}

SUPERMASTER=${MAS}
SUPERMASNAME=${MASNAME}
SUPERMASDIR=${MASDIR}

# Check required dir:
#####################
	# Where data will be processed
	if [ -d "${PROROOTPATH}/" ]
	then
 	  echo "  //  OK: a directory exist where I can create a processing dir." 
	else
		PROROOTPATH="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$PROROOTPATH)"
	   if [ -d "${PROROOTPATH}/" ]
			then
  	 			echo "  // Double mount of hp-storeesay. Renamed dir with -1"
 	  		else 
  	 			echo " "
  	 			echo "  //  NO directory ${PROROOTPATH}/ where I can create a processing dir. Can't run..." 
   				echo "  //  Check parameters files and  change hard link if needed."
  	 			exit 1
 	  	fi
	fi

	# Path to data
	if [ -d "${DATAPATH}" ]
	then
	   echo "  //  OK: a directory exist where data in csl format are supposed to be stored." 
	   mkdir -p ${PROPATH}
	else
	   DATAPATH="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$DATAPATH)"
	   if [ -d "${DATAPATH}/" ]
			then
				echo "  // Double mount of hp-storeesay. Renamed dir with -1"
			else 
	 			echo " "
	   			echo "  //  NO expected data directory. Can't run..." 
	   			echo "  //  PLEASE REFER TO SCRIPT and  change hard link if needed"
	   			exit 1
		fi
	fi

	if [ -d "${DEMDIR}" ]
	then
	   echo "  //  OK: a directory exist where DEM is supposed to be stored." 
	else
		DEMDIR="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$DEMDIR)"
	   if [ -d "${DEMDIR}/" ]
			then
				echo "  // Double mount of hp-storeesay. Renamed dir with -1"
			else 
	  			echo " "
	   			echo "  //  NO expected DEM directory. Can't run..." 
	   			echo "  //  PLEASE REFER TO SCRIPT and  change hard link if needed"
	   			exit 1		
	   	fi
	fi

	echo "" 
	echo "  // ---------------------------------------------------------------------"
	echo "  //  Suppose data are stored somewhere on ${DATAPATH}"
	echo "  //          If not change hard link in parameters file"
	echo "  //  Suppose data will be processed somewhere in ${PROPATH}/"
	echo "  //          If not change hard link in parameters file"
#	echo "  //  Suppose you have adapted the size and coordinates of DEM in parameters file"
#	echo "  //  Suppose processing zone UTM 35 - cfr envi headers"
	echo "  // ---------------------------------------------------------------------"
	echo ""


# Let's Go:
###########	
 
	# Create working dirs if does not exist yet
	mkdir -p ${PROPATH}/${TRKDIR}
	cd ${PROPATH}/${TRKDIR}

	RUNDIR=${PROPATH}/${TRKDIR}/${MAS}_${REGION}_Zoom${ZOOM}_ML${INTERFML}${COMMENT}
	if [ ! -d "${RUNDIR}" ]; then
			mkdir ${RUNDIR}
		else
			echo "  //  Sorry, ${RUNDIR} dir exists. Probable previous computation. Please check."
			exit 0
	fi

	cp ${PARAMFILE} ${RUNDIR}
	cd ${RUNDIR}

	# Log File
	LOGFILE=${RUNDIR}/LogFile_${MAS}_${RUNDATE}.txt

	echo "" > ${LOGFILE}
	EchoTee "--------------------------------"	
	EchoTee "Processing launched on ${RUNDATE} " 
	EchoTee "" 
	EchoTee "Main script version: " 
	EchoTee "    ${PRG} ${VER}, ${AUT}" 
	EchoTee ""
	EchoTee "Functions script version: " 
	EchoTee "    ${FCTFILE} ${FCTVER}, ${FCTAUT}"
	EchoTee "" 
	EchoTee "--------------------------------"	
	EchoTee "--------------------------------"
	EchoTee ""
	EchoTee "Command line used and parameters:"
	EchoTee "$(dirname $0)/${PRG} $1 $2 $3 $4 $5"
	EchoTee ""
	EchoTee " And this parameters file contains the following parameters:" 
	EchoTee "  (Parameters are echoed only in Logfile)"
	EchoTee ""
	EchoTee "--------------------------------"	
	cat ${PARAMFILE} >> ${LOGFILE}
	EchoTee "--------------------------------"	
	EchoTee "--------------------------------"
	EchoTee ""

# Crop
	EchoTee "Crop CSL"	
	EchoTee "--------------------------------"
	
	if [ ${CROP} == "CROPyes" ] && [ "${S1MODE}" != "WIDESWATH" ]
		then
			# Create Crop Dir on archive disk
			if [ ! -d "${INPUTDATA}/${MASDIR}" ]; then  # i.e. ${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}
					EchoTee "No Crop of that size yet. Will crop it here."
				  Crop ${MASNAME}       
					EchoTee "Crop applied : lines ${FIRSTL}-${LASTL} ; pixels ${FIRSTP}-${LASTP}"
					EchoTee "Crop applied : Zoom ${ZOOM} ; Interferometric products ML factor ${INTERFML}"			
				else
					EchoTee "Primary image ${MAS} already cropped."
					EchoTee ""
			fi
		else 
			EchoTee "No crop applied. Keep full footprint"
	fi

# Compute ratio between Az and Range pix size
# Ratio must be computed after Crop and zoom to get info from zoom 
	RGSAMP=`GetParamFromFile "Range sampling [m]" SinglePair_SLCImageInfo.txt`   # not rounded 
	EchoTee "Range sampling : ${RGSAMP}"
	AZSAMP=`GetParamFromFile "Azimuth sampling [m]" SinglePair_SLCImageInfo.txt` # not rounded
	EchoTee "Azimuth sampling : ${AZSAMP}"
	INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" SinglePair_SLCImageInfo.txt` # not rounded
	EchoTee "Incidence angle : ${INCIDANGL}"
	RATIO=`echo "scale=2; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l | xargs printf "%.*f\n" 0` # with two digits and rounded to 0th decimal
	RATIOREAL=`echo "scale=5; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l` # with 5 digits 
	
	EchoTee "--------------------------------"
	EchoTee "Pixel Ratio is ${RATIO}"
 	EchoTee "Pixel Ratio as Real is ${RATIOREAL}"
	EchoTee "--------------------------------"
	EchoTee ""


	if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
		then MASKBASENAME=`basename ${PATHTOMASK##*/}`  
		else MASKBASENAME=`echo "NoMask"` # not sure I need it
	fi 	# i.e. "NoMask" or "mask file name without ext" from Param file


# slantRangeDEM
# processing single pair without SuperMaster; DEM maybe not computed yet. If not or if FORCED, will do it here 
EchoTee ""	
EchoTee "External DEM"			
EchoTee "--------------------------------"

IMGWITHDEM=${MASNAME}
SlantRangeExtDEM PAIR BlankRunNo   

# Get date of last AMSTer Engine source dir (require FCT file sourced above)
GetAMSTerEngineVersion
# Store date of last AMSTer Engine source dir

#echo "Last created AMSTer Engine source dir suggest projecting DEM in slant range with ME version: ${LASTVERSIONMT} in ${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${MASDIR}/Projecting_DEM_w_AMSTerEngine_V.txt"
echo "Last created AMSTer Engine source dir suggest projecting DEM in slant range with ME version: ${LASTVERSIONMT}" > ${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${MASDIR}/Projecting_DEM_w_AMSTerEngine_V.txt

EchoTee ""	
EchoTee " Clean ${RUNDIR}"
echo
# cleaning
rm -f *.txt
cd ..
rm -Rf ${RUNDIR}

if [ "${SATDIR}" == "S1" ] ; then rm -f ${FLAGUSAGE} ; fi

# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		espeak " DEM computed. Hope it worked." ;;
	"Darwin")
		say " DEM computed. Hope it worked." 	;;
	*)
		echo " DEM computed. Hope it worked." 	;;
esac			

# All done 
