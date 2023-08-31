#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at resampling all images form a give sat/mode in a SuperMaster
#     geometry using CSL Insar Suite. 
#
# Parameters :      - file with the processing parameters (incl path) 
#                   - FORCES1DEM: if  FORCE, then recompute DEM for each S1 wide swath image 
#					- list of images to coregister provided as dates if not S1 Wide Swath, and as name if S1 Wide Swath (i.e. S1X_TRK_DATE_AD.csl where x = A or B and AD = A or D)
#						BEWARE! : In that case, param 2 MUST be  NoForce (or whatever you want) if you do not want to Force recomputing the DEM, or 
#							 FORCE if you want to Force recomputing the DEM (for S1 wide swath)
#
# Dependencies:
#	 - CIS and CIS Tools, at least V2020426
#	 - PRAMETERS file, at least V V20200505
#    - The FUNCTIONS_FOR_CIS.sh file with the function used by the script. Will be called automatically by the script
#    - gnu sed and awk for more compatibility. 
#    - cpxfiddle is usefull though not mandatory. This is part of Doris package (TU Delft) available here :
#            http://doris.tudelft.nl/Doris_download.html. 
#    - Fiji (from ImageJ) is usefull as well though not mandatory
#    - convert (to create jpg images from sun rasters)
#    - bc (for basic computations in scripts)
#    - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
# 	 - scripts : RenamePathAfterMove.sh and RenamePath_Volumes.sh 
#				(and maybe UpdateLinkAfterMove.sh though commented for now)
#	 - linux trap function
#
# New in Distro V 1.0:	- Based on developpement version 5.1 and Beta V5.0.0
# New in Distro V 1.1:	- avoid attempting to coregister the Quarantained dir
# New in Distro V1.1.1: - add file with date when no new data to process. This is used as test in mass processing
#                       - remove text and logs files older than 30 days
# New in Distro V1.1.2:	- Read parameter to allow calibration of S1 images
# New in Distro V1.2.0:	- debug FORCE all dem for S1
# New in Distro V1.2.1:	- clean log files also when no new data to coreg
# New in Distro V1.3.0:	- Cleaned and updated to cope with new improvements in SinglPair.sh V2.3.0
#						  Unlike SinglePai.sh though we do not test the quality of the fine coregstration
# New in Distro V1.4.0:	- When using S1, creates an empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt to let ReadAll_Img.sh to know
#							  that it can't remove the processed products of S1 data of the same mode as the one under progress to avoid prblms.
#							  Note that the script will remove that file at normal termination or CTRL-C, but not if script is terminated using kill. In such a case, you need to remove the file manaully 
#							  Note also that DoNotUpdateProducts_Date_RND.txt is touched at every time a new pair is processed. It allows to check that it is a recent processing and not a ghost file.  
# New in Distro V1.4.1:	- remove duplicate lines to get Reduced master amplitude image range & az dimension when computing ampli of Slave only
# New in Distro V1.4.2: - improve log managment at the end of processing
# New in Distro V1.4.3: - skip images in quarantained dir
# New in Distro V1.4.4: - remove Quarantained log files older than 30 days
# New in Distro V1.5.0: - debug resampling S1 SM: need kepeing Img name as NAME and not date in _Ampli_Img... dir
# New in Distro V1.5.1: - Keep track of MasTer Engine version in by looking at MasTer Engine source dir 
#						- avoir error message when checking non existing Quarantained dir
#						- done on May 6, 2022
# New in Distro V1.5.2: - DO NOT make a link to interpolated ras file for S1 in SM mode because dir name will be changed (SM name becomes SM date). 
#						  This would make the broken link to be ignored when moved and would never agree in final rsync when dump results from/to different disks  
#						- Improve diff check when dumping results to final dir when source and target dirs are not the same.  
#						- done on Aug 10 2022
# New in Distro V1.6.0: - set car RECOMPDEM to FORCE when FORCES1DEM = FORCE to get it operating properly at ManageDEM fct
# New in Distro V2.0.0: - allows coregistration of images provided in a list provided as a THIRD param.   
#						- skip __TMP_QUARANTINE while listing existing images
# New in Distro V2.1.0: - proper managment of PROROOTPATH when run from __SplitCoreg.sh
# New in Distro V2.2.0: - If run for a list of image, one must only check images to Crop for that list
# New in Distro V2.3.0: - bug in search for empty OUTPUTDATA dir (search for subdirs named by SM). Only affected first run. 
# New in Distro V2.3.1: - Display full command line used if more than one param
# New in Distro V2.4: 	- replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V2.4.1: - display the number of image / total images to process 
# New in Distro V2.5.0: - avoid confusion when no new data to process (error of if ! -s)
# New in Distro V2.6.0: - read UTM zone for geocoding
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2015/08/24 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.6.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 29, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

PARAMFILE=$1				# File with the parameters needed for the run
FORCES1DEM=$2				# For S1 processing : if FORCE, then recompute DEM for each S1 image 
LISTTOCOREG=$3				# To coregister a list of images (provided as list of name if S1 (e.g. S1x_Trk_DATE_AD.csl) or dates if not S1, in 1 col). 
							# In that case, param 2 MUST be  NoForce (or whatever you want) if you do not want to Force recomputing the DEM, or 
							#    FORCE if you want to Force recomputing the DEM (for S1 wide swath)

if [ $# -lt 1 ] ; then echo  "Usage $0 PARAMETER_FILE [FORCEDEM] [List_To_Coreg]" ; exit; fi

# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

SUPERMASTER=`GetParam SUPERMASTER`			# SUPERMASTER, date of the super master as selected by Prepa_MSBAS.sh in
											# e.g. /Volumes/hp-1650-Data_Share1/SAR_SUPER_MASTERS/MSBAS/VVP/seti/setParametersFile.txt

PROROOTPATH=`GetParam PROROOTPATH`			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name. 
DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 
FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored

DEMDIR=`GetParam DEMDIR`					# DEMDIR, path to dir where DEM is stored

if [ ${FORCES1DEM} == "FORCE" ] 
 then 
	RECOMPDEM="FORCE"			# RECOMPDEM, recompute DEM even if already there (FORCE), or trust the one that would exist (KEEP)
 else 
	RECOMPDEM=`GetParam "RECOMPDEM,"`			# RECOMPDEM, recompute DEM even if already there (FORCE), or trust the one that would exist (KEEP)
fi

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

MASSPROCESSPATH=`GetParam MASSPROCESSPATH`	# MASSPROCESSPATH, path to dir where all processed pairs will be stored in sub dir named by the sat/trk name (SATDIR/TRKDIR)
RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data will be stored 


if [ `echo "${PROROOTPATH}" | grep "_Part_" 2>/dev/null | wc -w` -gt 0 ]
	then 
		# from _SplitCoreg.sh run
		eval PROPATH=${PROROOTPATH}	# Path to dir where data will be processed.
		mkdir -p ${PROROOTPATH}
	else 
		# from normal run
		eval PROPATH=${PROROOTPATH}/${SATDIR}/${TRKDIR}	# Path to dir where data will be processed.
fi

source ${FCTFILE}

# Get date of last MasTer Engine source dir (require FCT file sourced above)
GetMasTerEngineVersion

# Define Crop Dir
if [ ${CROP} == "CROPyes" ]
	then
		CROPDIR=/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP} #_Zoom${ZOOM}_ML${INTERFML}
	else
		CROPDIR=/NoCrop
fi

# Define Dir where data are/will be cropped
INPUTDATA=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}
mkdir -p ${INPUTDATA}

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
eval RNDM1=`echo $(( $RANDOM % 10000 ))`

case ${SATDIR} in 
	"S1") 
		# need this definition here for usage in GetParamFromFile
		MASDIR=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${SUPERMASTER}` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name.csl of the image anyway

		S1ID=`GetParamFromFile "Scene ID" SAR_CSL_SLCImageInfo.txt`
		S1MODE=`echo ${S1ID} | cut -d _ -f 2`	
		# If S1 is strip map, it requires normal processing
		if [ ${S1MODE} == "IW" ] || [ ${S1MODE} == "EW" ]
			then 
				S1MODE="WIDESWATH"
				EchoTee "S1 data do not require coregistration on a SUPERMASTER for SuperMaster_MassProc.sh."
				EchoTee "However, we will take this opportunity to compute DEM for each (New) S1 image."
			else 
				S1MODE="STRIPMAP"
		fi
		EchoTee "Processing S1 images in mode ${S1MODE}" 
		
		# Creates an empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt to let ReadAll_Img.sh to know
		# that it can't remove the processed products of S1 data of the same mode as the one under progress to avoid prblms
		eval FLAGUSAGE=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/DoNotUpdateProducts_${RUNDATE}_${RNDM1}_MCOREG.txt
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
		
		;;
	"TDX")
		S1MODE="DUMMY"  #Just un case... 
		# ensure that one works only with Transmit mode
		MASTDXMODE="_${TRKDIR##*_}"   # everything after last _, incl _
		BSORPM==`echo ${TRKDIR} | rev | cut -d_ -f 4 | rev` 	# i.e. from TRKDIR name: PM (pursuite) or BS (bistatic) 
		# As this script is not aimed at processing bistatic mode, lets put this :
		ChangeParam "Bistatic interferometric pair" NO InSARParameters.txt
		
		TDXMODE=`echo ${TRKDIR} | rev | cut -c4- | rev`   		# i.e. everything in TRKDIR name but the _TX or _RX

		# Master must always be TX. Slv is TX except when Topo with master date = slave date :
 		if [ ${MASTDXMODE} != "_TX" ] 
 			then 
 				EchoTee "Master mode is ${MASTDXMODE}, not TX; please check" 
 				exit 0
 			else 
 				SLVTDXMODE="_TX"	 #Just un case... 
		fi
		;;	
	*)
		S1MODE="DUMMY"  #Just un case... 
		;;
esac	

# Supermaster directory name based on date given in LaunchParameters file
if [ ${SATDIR} == "S1" ] ; then 
		if [ "${S1MODE}" == "WIDESWATH" ] ; then 
				SUPERMASNAME=`ls ${INPUTDATA} | ${PATHGNU}/grep ${SUPERMASTER} | cut -d . -f 1` 		 # i.e. if S1 in wideswath is given in the form of date, MASNAME is now the full name of the image anyway and no crop is possible for S1
			else 
				SUPERMASNAME=`ls  ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${SUPERMASTER}  | cut -d . -f 1` 		 # i.e. if S1 is not wideswath, crop is possible, so one must search for the name in NoCrop; MASNAME is now the full name of the image anyway
		fi
	else
		SUPERMASNAME=${SUPERMASTER} 
fi	
SUPERMASDIR=${SUPERMASNAME}.csl

# Check required dir:
#####################
	# Where data will be processed for the coregistration computation
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
		
	# Resampled data on SuperMaster in csl format will be stored in 
	if [ ${CROP} == "CROPyes" ]
		then
			SMCROPDIR=SMCrop_SM_${SUPERMASTER}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}  #_Zoom${ZOOM}_ML${INTERFML}
		else
			SMCROPDIR=SMNoCrop_SM_${SUPERMASTER}  #_Zoom${ZOOM}_ML${INTERFML}
	fi
	OUTPUTDATA=${RESAMPDATPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}
	mkdir -p ${OUTPUTDATA}
	
	EchoTee "" 
	EchoTee "---------------------------------------------------------------------"
	EchoTee "Suppose data are stored somewhere on ${DATAPATH}/${SATDIR}/${TRKDIR}"
	EchoTee "    If not change hard link in parameters file"
	EchoTee ""
	EchoTee "Suppose data will be processed somewhere in ${PROPATH}/COREG/"
	EchoTee "    If not change hard link in parameters file"
	EchoTee "---------------------------------------------------------------------"
	EchoTee ""


# Let's Go:
###########	
	RUNDIR=${PROPATH}/COREG/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}
	mkdir -p ${RUNDIR}
	cd ${RUNDIR}

	cp ${PARAMFILE} ${RUNDIR}


# Log File
LOGFILE=${RUNDIR}/LogFile_Super${MAS}_${RUNDATE}_${RNDM1}.txt

echo "" > ${LOGFILE}
EchoTee "Processing launched on ${RUNDATE} " 
EchoTee "" 
EchoTee "Main script version: " 
EchoTee "${PRG} ${VER}, ${AUT}" 
EchoTee ""
EchoTee "Functions script version: " 
EchoTee "${FCTFILE} ${FCTVER}, ${FCTAUT}"
EchoTee "" 
EchoTee "--------------------------------"	
EchoTee "--------------------------------"
EchoTee ""
EchoTee "Command line used :"
EchoTee "$(dirname $0)/${PRG} ${PARAMFILE} $2 $3"
EchoTee ""
EchoTee "And this parameters file contains the following parameters:" 
echo "  //   (Parameters are echoed only in Logfile)"
EchoTee "--------------------------------"	
cat ${PARAMFILE} >> ${LOGFILE}
EchoTee "--------------------------------"	
EchoTee "--------------------------------"
EchoTee ""
if [ "${LISTTOCOREG}" != "" ]
	then 
		EchoTee "Will process requested images that are in :"
		EchoTee "    ${LISTTOCOREG}"
		EchoTee "That is (unless they were already processed): "
		# List requested images
		cat ${LISTTOCOREG}
		cat ${LISTTOCOREG} >> ${LOGFILE}
		EchoTee "--------------------------------"
		EchoTee "--------------------------------"
		EchoTee ""
fi

# Compare with what exist already in ${OUTPUTDATA} in order to 
#  process only the new ones, again without Super Master:
##################################################################
cd ${OUTPUTDATA}

#	if find "${OUTPUTDATA}" -mindepth 1 -print -quit | ${PATHGNU}/grep -q . ; then 
	if [ `find ${OUTPUTDATA} -maxdepth 1 -type d -name "${SUPERMASTER}*" 2>/dev/null | wc -l ` -ge 1 ] ; then 	
			echo "  //  OUTPUTDATA dir not empty. Check what is already processed"
			if [ "${SATDIR}" == "S1" ]
				then 
					ls -d ${OUTPUTDATA}/${SUPERMASTER}* | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d _ -f 2-5 | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/grep -v Quarantained  | ${PATHGNU}/grep -v TMP_QUARANTINE | ${PATHGNU}/gsed 's/$/.csl/' > Processed_slaves_${RUNDATE}_${RNDM1}.txt
					# list quaraintained if dir exist and is not empty
					if [ -d ${DATAPATH}/${SATDIR}/${TRKDIR}/Quarantained ] && [ `ls -l ${DATAPATH}/${SATDIR}/${TRKDIR}/Quarantained | wc -l` -gt 1 ] ; then 
						ls -d ${DATAPATH}/${SATDIR}/${TRKDIR}/Quarantained/*.csl | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d _ -f 3  > Quarantained_${RUNDATE}_${RNDM1}.txt
					fi
				else
					ls -d ${OUTPUTDATA}/${SUPERMASTER}* | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d _ -f 2 | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/grep -v Quarantained  | ${PATHGNU}/grep -v TMP_QUARANTINE | ${PATHGNU}/gsed 's/$/.csl/' > Processed_slaves_${RUNDATE}_${RNDM1}.txt
					# list quaraintained 
					if [ -d ${DATAPATH}/${SATDIR}/${TRKDIR}/Quarantained ] && [ `ls -l ${DATAPATH}/${SATDIR}/${TRKDIR}/Quarantained | wc -l` -gt 1 ] ; then 
						ls -d ${DATAPATH}/${SATDIR}/${TRKDIR}/Quarantained/*.csl | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d . -f 1  > Quarantained_${RUNDATE}_${RNDM1}.txt
					fi
			fi
			if [ ! -s Quarantained_${RUNDATE}_${RNDM1}.txt ] ; then 
				touch Quarantained_${RUNDATE}_${RNDM1}.txt
			fi
		else
			echo "  //  OUTPUTDATA dir is empty. Create empty list file"
			touch Processed_slaves_${RUNDATE}_${RNDM1}.txt
			touch Quarantained_${RUNDATE}_${RNDM1}.txt
	fi

# Listing all existing data from DATAPATH without Crop, but the Super Master
##############################################################
if [ "${LISTTOCOREG}" == "" ]
	then 
		ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/grep -v .txt | ${PATHGNU}/grep -v Quarantained  | ${PATHGNU}/grep -v TMP_QUARANTINE > All_Slaves_${RUNDATE}_${RNDM1}.txt
	else
		# check list format ; must be as named in DATAPATH, that is date.csl or S1_name.csl 
		if [ "${SATDIR}" == "S1" ] 
			then 
				TST=`cat ${LISTTOCOREG} | head -1 | grep ".csl" | grep "S1" 2>/dev/null | wc -w`
			else 
				TST=`cat ${LISTTOCOREG} | head -1 | grep ".csl" 2>/dev/null | wc -w`
		fi		
		
		#if OK, carry on
		if [ ${TST} -gt 0 ] 
			then 
				cat ${LISTTOCOREG} > All_Slaves_${RUNDATE}_${RNDM1}.txt
			else 
				EchoTee " Sorry, you list of image to coregister must be in the form of date.csl if not S1 and S1AB_TRK_DATE_AD.csl if S1; Can't run. Exit'" 
				exit
		fi
fi

# Get only the new files to porcess
###################################

if [ "${LISTTOCOREG}" == "" ]
	then 
		# there must be more img in All_Slaves_ than in Processed_slaves_
		sort All_Slaves_${RUNDATE}_${RNDM1}.txt Processed_slaves_${RUNDATE}_${RNDM1}.txt | uniq -u > New_Slaves_to_process_${RUNDATE}_${RNDM1}_tmp.txt 
	else
		# the list may contain less images to process than what already exist in Processed_slaves_. Hence one must take only what is in  All_Slaves_ but that is not in Processed_slaves_
		# hence remove from All_Slaves_${RUNDATE}_${RNDM1}.txt each line that contains what is in lines of Processed_slaves_${RUNDATE}_${RNDM1}.txt
		grep -Fv -f Processed_slaves_${RUNDATE}_${RNDM1}.txt All_Slaves_${RUNDATE}_${RNDM1}.txt > New_Slaves_to_process_${RUNDATE}_${RNDM1}_tmp.txt 
fi


# ignore images in .../SAR_CSL/sat/region/Quarantained
grep -Fv -f Quarantained_${RUNDATE}_${RNDM1}.txt New_Slaves_to_process_${RUNDATE}_${RNDM1}_tmp.txt > New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt
rm -f New_Slaves_to_process_${RUNDATE}_${RNDM1}_tmp.txt #Quarantained_${RUNDATE}_${RNDM1}.txt

if [ -f New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt ] && [ -s New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt ] 
	then 
		rm -f ${OUTPUTDATA}/_No_New_Data_Today.txt
	else 
		if [ "${FORCES1DEM}" == "FORCE" ] 
			then 
				rm -f ${OUTPUTDATA}/_No_New_Data_Today.txt		# if FORCE, do it anyway 
				RECOMPDEM="FORCE"
			else 
				EchoTee "No new slave to coregister; end here."
 				rm -f ${OUTPUTDATA}/New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt
 				rm -f ${OUTPUTDATA}/All_Slaves_${RUNDATE}_${RNDM1}.txt
 				rm -f ${OUTPUTDATA}/Processed_slaves_${RUNDATE}_${RNDM1}.txt	
				# Add a flag somewhere to avoid attempting running nexts steps with automated processing:
				TODAYDATE=`date "+ %Y%m%d" | ${PATHGNU}/gsed "s/ //g"`
				echo "No new data on ${TODAYDATE}" > ${OUTPUTDATA}/_No_New_Data_Today.txt
#				mv -f *.txt ${OUTPUTDATA}	
				exit 0 
		fi

fi 

# ReCrop if required
####################
	# Test if supermaster already cropped. If not, do.
	if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ] 
		then 
			SUPERMASTER=${SUPERMASNAME} 
	fi

	case ${CROP} in 
		"CROPyes")

			if [ ! -d "${INPUTDATA}/${SUPERMASTER}.csl" ]; then
				EchoTee "No Crop of that size yet for Super Master ${SUPERMASTER}"
				EchoTee "=> Will create a dir and store data there"
				echo
				Crop ${SUPERMASTER} 
			fi

			# Crop new slaves.
			# Check only the new slaves to crop. 
			ls ${INPUTDATA} | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/grep -v .txt > Cropped_slaves_${RUNDATE}_${RNDM1}.txt
			if [ "${LISTTOCOREG}" == "" ]
				then 
					# there might be more img in All_Slaves_ than in Cropped_slaves_
					sort All_Slaves_${RUNDATE}_${RNDM1}.txt Cropped_slaves_${RUNDATE}_${RNDM1}.txt | uniq -u > New_Slaves_to_Crop_${RUNDATE}_${RNDM1}.txt
				else
					# the provided list (i.e. All_Slaves_) may contain less images to process than what already exist in Cropped_slaves_.
					# Hence one must take only what is in  All_Slaves_ but that is not in Cropped_slaves_
					# Remove from All_Slaves_${RUNDATE}_${RNDM1}.txt each line that contains what is in lines of Cropped_slaves_${RUNDATE}_${RNDM1}.txt
					grep -Fv -f Cropped_slaves_${RUNDATE}_${RNDM1}.txt All_Slaves_${RUNDATE}_${RNDM1}.txt > New_Slaves_to_Crop_${RUNDATE}_${RNDM1}.txt
			fi

			for SLVDIR in `cat -s New_Slaves_to_Crop_${RUNDATE}_${RNDM1}.txt`
			do
				if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ] ; then 
						SLV=`echo ${SLVDIR} | cut -d . -f 1` 
					else	
						SLV=`GetDateCSL ${SLVDIR}`
				fi
				
				EchoTee "Crop ${SLV} "
				Crop ${SLV} 
			done ;;
		"CROPno")		
			EchoTee "No crop applied. Keep full footprint" 
			echo ;;
		*.kml)  # do not quote this because of the wild card
			if [ ${SATDIR} == "S1" ]
				then 
					EchoTee "Shall use ${CROP} file for pseudo crop by defining area of interest."
					CROPKML=${CROP}
				else 	
					EchoTee "Option for crop with kml not tested yet for non S1 images; Check scripts and test..."
					exit 0
			fi	;;
	esac


# Compute ratio between Az and Range pix size
# Ratio must be computed after Crop and zoom to get info from zoom 
	RGSAMP=`GetParamFromFile "Range sampling [m]" SuperMaster_SLCImageInfo.txt`   # not rounded 
	EchoTee "Range sampling : ${RGSAMP}"
	AZSAMP=`GetParamFromFile "Azimuth sampling [m]" SuperMaster_SLCImageInfo.txt` # not rounded
	EchoTee "Azimuth sampling : ${AZSAMP}"
	INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" SuperMaster_SLCImageInfo.txt` # not rounded
	EchoTee "Incidence angle : ${INCIDANGL}"
	RATIO=`echo "scale=2; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l | xargs printf "%.*f\n" 0` # with two digits and rounded to 0th decimal
	RATIOREAL=`echo "scale=5; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l` # with 5 digits 
	
	EchoTee "--------------------------------"
	EchoTee "Pixel Ratio is ${RATIO}"
	EchoTee "Pixel Ratio as Real is ${RATIOREAL}"
	EchoTee "--------------------------------"
	EchoTee ""

# Start processing chain
###################################
MAINRUNDIR=${RUNDIR}			# keep this as RUNDIR will be renamed for each pair

if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
	then #MASKBASENAME=`basename ${PATHTOMASK##*/} .nvi`  
		MASKBASENAME=`basename ${PATHTOMASK##*/}`  
	else MASKBASENAME=`echo "NoMask"` # not sure I need it
fi 	# i.e. "NoMask" or "mask file name without ext" from Param file

# Need this for ManageDEM
PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
PIXSIZERG=`echo "${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 


MAS=${SUPERMASTER}
MASDIR=${SUPERMASDIR}

# If DEM is not in INPUTDATA/SuperMaster.csl, or if FORCE option is set for DEM computation, let's compute it now.
##################################################################################################################
echo ""
EchoTee "--------------------"
EchoTee "--------------------"
EchoTee "START PROCESSING DEM"
EchoTee "--------------------"
EchoTee "--------------------"

if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ] ; then 
	# Because S1 data can't be coregistered on a SUPERMASTER, we will need a DEM for each image 
	EchoTee "Be sure of your choice of mask because it will be computed for each img."
	if [ "${FORCES1DEM}" == "FORCE" ] ; then
			EchoTee "You requested to recompute DEM (and mask) for each S1 image"
			DEMTOPROCESS=All_Slaves_${RUNDATE}_${RNDM1}.txt		
		else 
			EchoTee "You requested to recompute only DEM (and mask) for New S1 images"
			DEMTOPROCESS=New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt
	fi

    NPAIRS=`wc -l < ${DEMTOPROCESS}`
	i=0
	for SLVDIR in `cat -s ${DEMTOPROCESS}`    # i.e. SLVDIR is S1_name.csl
	do
		i=`echo "$i + 1" | bc -l`
		EchoTee "----------------------------------------------------------------------------------------"
		EchoTeeYellow "Shall compute DEM for ${SLVDIR} before coregistration, that is image $i/${NPAIRS} "
		EchoTee "----------------------------------------------------------------------------------------"

		#IMGWITHDEM=`GetDateCSL ${SLVDIR}`				# i.e. IMGWITHDEM is SLV i.e. only the date 
		IMGWITHDEM=`echo ${SLVDIR} | cut -d . -f 1`		# i.e. IMGWITHDEM is S1 SLV name without csl
		ManageDEM  
	done	
fi 	

# Thanks to coregistration on a SUPERMASTER, one need to compute only one DEM. If S1, we computed DEM for each SLV, let's do the SUPERMASTER also
IMGWITHDEM=${SUPERMASNAME}
ManageDEM

# Now that links are up to date and/or files (re-)calculated, lets update slantRange.txt
#SlantRangeExtDEM SUPERMASTER BlankRunYes 

RUNDIR=${MAINRUNDIR}

echo ""
EchoTee "--------------------"
EchoTee "--------------------"
EchoTee "START COREGISTRATION"
EchoTee "--------------------"
EchoTee "--------------------"
# If Process all images to coregister on SUPERMASTER
####################################################

# Get date of last MasTer Engine source dir (require FCT file sourced above)
GetMasTerEngineVersion
# Store date of last MasTer Engine source dir
echo "Last created MasTer Engine source dir suggest projecting DEM in slant range with ME version: ${LASTVERSIONCIS}" > ${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}/${MASDIR}/Projecting_DEM_w_MasTerEngine_V.txt

NPAIRS=`wc -l < New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt`

i=0
for SLVDIR in `cat -s New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt`    # i.e. SLVDIR is date.csl or S1_name.csl
do	
	i=`echo "$i + 1" | bc -l`
	EchoTee "----------------------------------------------------------------------------------------"
	EchoTeeYellow "Shall coregister ${SLVDIR} on ${SUPERMASTER}, that is image $i/${NPAIRS} "
	EchoTee "----------------------------------------------------------------------------------------"

	SLV=`GetDateCSL ${SLVDIR}`				# i.e. SLV is now only the date anyway
	if [ ${SATDIR} == "S1" ] ; then 
		SLVNAME=`echo ${SLVDIR} | cut -d . -f 1` 		 

		# repeat touch FLAG to keep recent date and offer the possibility to check that FLAG is not a ghost file 
		touch ${FLAGUSAGE}

	else
		SLVNAME=${SLV} 
	fi										# i.e. SLVNAME is given in the form of date or S1_name without extention .csl


	EchoTee "Initialise InSAR for pair ${SUPERMASTER}_${SLV}"		
	EchoTee "---------------------------------------"
	EchoTee "---------------------------------------"
		RUNDIR=${MAINRUNDIR}/${SUPERMASTER}_${SLVNAME}   # Rundir for each super master pairs
		mkdir -p ${RUNDIR}
		cd ${RUNDIR}  
     	#MASDIR=${SUPERMASTER}.csl
     	MASDIR=${SUPERMASDIR}
		MakeInitInSAR ${INPUTDATA} ${RUNDIR}  # Param : WhereAreCSLdata WhereToRun
	
	EchoTee "--------------------------------"
	EchoTee "Amplitude images"					
	EchoTee "--------------------------------"
	EchoTee "--------------------------------"
			if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]						
			then	
				EchoTee "Skip Amplitude generation because not needed for S1 coreg. "
				EchoTee "No need of _SUPERMASTER_Ampli_Img_Reduc nor ModulesForCoreg directories."
				EchoTee " If want to run Amplitude generation anyway, ensure to have read S1 image with -b option"
				cd ${RUNDIR}/i12
			else
				# Although TSX, TDX and ENVISAT may have orbits good enough to skip coarse coreg, we prefer to compute it here
				mkdir -p  ${OUTPUTDATA}/ModulesForCoreg
				# Compute (master and) SLV amplitudes
				if [ ! -f ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/InSARProducts/${SUPERMASTER}.*.mod ]
					then # supermaster not processed yet. Must compute ampli of both SM and SLV
						EchoTee "Compute Super Master ${MAS} and Slave ${SLV} amplitude reduction (size are != because before InSAR)"
						EchoTee "Using original pixel shape and save it as OriginalCoreg"
						MakeAmpliImgAndPlot 1 1 ${PIXSHAPE} MasAndSlv
						EchoTee "Keep copy of master module with ML for ampli coregistration for further mass processing use."
						PATHMAS=`GetParamFromFile "Reduced master amplitude image file path" InSARParameters.txt`
						MRGORIG=`GetParamFromFile "Reduced master amplitude image range dimension" InSARParameters.txt`
						MAZORIG=`GetParamFromFile "Reduced master amplitude image azimuth dimension" InSARParameters.txt`
						MASPOL=`echo "${PATHMAS}" | ${PATHGNU}/gawk -F '/' '{print $NF}'`
						cp -f InSARProducts/${MASPOL} ${OUTPUTDATA}/ModulesForCoreg/${MASPOL}.OriginalCoreg_Z${ZOOM}_ML${MLAMPLI}_W${MRGORIG}_L${MAZORIG}
						if [ ! -s ${PATHMAS} ] ; then
							EchoTeeRed "  // Module file of supermaster is empty. May indicate that crop is outside of image or CSL image corrupted.  \n"
						fi	
						# STORE INFO ABOUT SUPERMASTER IN ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc FOR FUTHER USE WITH OTHER SLAVES
						mkdir -p ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/TextFiles
						mkdir -p ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/InSARProducts
						cp ${RUNDIR}/i12/TextFiles/InSARParameters.txt  ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/TextFiles/
						cp ${RUNDIR}/i12/InSARProducts/${MASPOL} ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/InSARProducts/
						# to be clean update here the path to that supermaster.*.mod file in InSARParameters.txt
						updateParameterFile ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/TextFiles/InSARParameters.txt "Reduced master amplitude image file path"  ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/InSARProducts/${MASPOL}
					else # supermaster already processed; only need to compute ampli of save
						EchoTee "Compute Slave ${SLV} amplitude reduction (size are != because before InSAR)"
						EchoTee "Using original pixel shape and save it as OriginalCoreg"
						MakeAmpliImgAndPlot 1 1 ${PIXSHAPE} slaveOnly
						# And Super master reduced size and path are to be set in InSARParameters.txt.
						#   We must read them from ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/ InSARParameters.txt 
						SMRANGESIZE=`GetParamFromFile "Reduced master amplitude image range dimension" SuperMasterCoreg_SLCImageInfo.txt`
						SMAZSIZE=`GetParamFromFile "Reduced master amplitude image azimuth dimension" SuperMasterCoreg_SLCImageInfo.txt`
						PATHMAS=`GetParamFromFile "Reduced master amplitude image file path" SuperMasterCoreg_SLCImageInfo.txt`
						MASPOL=`echo "${PATHMAS}" | ${PATHGNU}/gawk -F '/' '{print $NF}'`
#						SMRANGESIZE=`GetParamFromFile "Reduced master amplitude image range dimension" SuperMasterCoreg_SLCImageInfo.txt`
#						SMAZSIZE=`GetParamFromFile "Reduced master amplitude image azimuth dimension" SuperMasterCoreg_SLCImageInfo.txt`
						updateParameterFile ${RUNDIR}/i12/TextFiles/InSARParameters.txt "Reduced master amplitude image range dimension" ${SMRANGESIZE}
						updateParameterFile ${RUNDIR}/i12/TextFiles/InSARParameters.txt "Reduced master amplitude image azimuth dimension" ${SMAZSIZE}
						updateParameterFile ${RUNDIR}/i12/TextFiles/InSARParameters.txt "Reduced master amplitude image file path"  ${OUTPUTDATA}/_${SUPERMASTER}_Ampli_Img_Reduc/i12/InSARProducts/${MASPOL}
				fi
				# Keep the slave OriginalCoreg for further use in MSBAS mass processing
				PATHSLV=`GetParamFromFile "Reduced slave amplitude image file path" InSARParameters.txt`
				SRGORIG=`GetParamFromFile "Reduced slave amplitude image range dimension" InSARParameters.txt`
				SAZORIG=`GetParamFromFile "Reduced slave amplitude image azimuth dimension" InSARParameters.txt`
				SLVPOL=`echo "${PATHSLV}" | ${PATHGNU}/gawk -F '/' '{print $NF}'`
				cp InSARProducts/${SLVPOL} ${OUTPUTDATA}/ModulesForCoreg/${SLVPOL}.OriginalCoreg_Z${ZOOM}_ML${MLAMPLI}_W${SRGORIG}_L${SAZORIG}
				if [ ! -s ${PATHSLV} ] ; then
					EchoTeeRed "  // Module file of slave is empty. May indicate that crop is outside of image or CSL image corrupted.  \n"
				fi	
			fi	
	echo 
	EchoTee "--------------------------------"	
	EchoTee "Coregistration - resampling"	
	EchoTee "--------------------------------"
	EchoTee "--------------------------------"
	if [ "${SATDIR}" == "S1" ]  && [ "${S1MODE}" == "WIDESWATH" ] ; then
		EchoTee "S1Coregistration not needed - will be computed anyway for each pair at mass processing."
	else
		# Coarse Coregistration and quality testing

			CoarseCoregTestQuality	
			EchoTee "--------------------------------"		

		# Fine Coregistration
			ChangeParam "Fine registration range distance between anchor points [pix]" ${FCDISTANCHOR} InSARParameters.txt
			EchoTee ""
			ChangeParam "Fine registration azimuth distance between anchor points [pix]" ${FCDISTANCHOR} InSARParameters.txt
			EchoTee ""
			EchoTee ""
			ChangeParam "Fine coregistration correlation threshold" ${FCOH} InSARParameters.txt
			EchoTee ""
	
			RatioPix ${FCOHWIN}
			ChangeParam "Fine coregistration range window size [pix]" ${RGML} InSARParameters.txt
			ChangeParam "Fine coregistration azimuth window size [pix]" ${AZML} InSARParameters.txt
			unset RGML
			unset AZML
		
			fineCoregistration		| tee -a ${LOGFILE}
			#Test Fine Coreg. 
			TSTFINECOREG=`grep "Total number of anchor points" ${LOGFILE} | tail -n1 | tr -dc '[0-9]'`
			if [ "${TSTFINECOREG}" -le "4" ] ; then EchoTee "Fine processing seemed to have failes (less than 4 anchor points... Exiting" ; exit 0 ; fi

			EchoTee "fine coreg done with ${TSTFINECOREG} anchor points" 
			EchoTee "--------------------------------"		
	

		#Interpolation: slave to super master. Slave amplitude plot. 
			interpolation	| tee -a ${LOGFILE}
			EchoTee "Interpolation done" 
			EchoTee "--------------------------------"
		
			OMRG=`GetParamFromFile "Slave image range dimension" InSARParameters.txt`
			SLVINTERP=`GetParamFromFile "Interpolated slave image file path" InSARParameters.txt`
			# For new interpolated image csl format. 
			POLSLV=`echo ${SLVPOL} | cut -d . -f 2`		# e.g. VV
			SLVINTERP=`ls ${SLVINTERP}/Data/SLCData.${POLSLV}`
			case ${SATDIR} in
				"ENVISAT") 
						MakeFig ${OMRG} 1.0 1.0 mag gray 1/4 cr4 ${SLVINTERP} 
					
						ln -s ${SLVINTERP}.ras ${RUNDIR}/i12/InSARProducts/${SLVPOL}.interpolated.csl.ras
						;;
				*) 
						MakeFig ${OMRG} 1.0 1.0 mag gray 4/4 cr4 ${SLVINTERP} 
						
						if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ]
							then
								echo "Do not link ${SLVINTERP}.ras because supermaster name will be changed as date in dir naming"
								touch ${RUNDIR}/i12/InSARProducts/SEE_${SLVPOL}.interpolated.csl.ras_in_interpolated_Dir_Data
							else
								ln -s ${SLVINTERP}.ras ${RUNDIR}/i12/InSARProducts/${SLVPOL}.interpolated.csl.ras
						fi 
						;;
			esac		
	fi

	# Store date of last MasTer Engine source dir
	#echo "Last created MasTer Engine source dir suggest coregistration with ME version: ${LASTVERSIONCIS} saved in ${RUNDIR}/Coreg_w_MasTerEngine_V.txt" 
	echo "Last created MasTer Engine source dir suggest coregistration with ME version: ${LASTVERSIONCIS}" > ${RUNDIR}/Coreg_w_MasTerEngine_V.txt

		
	# Get back to base dir 	
	cd ${MAINRUNDIR}
	RUNDIR=${MAINRUNDIR}
done

cd ${MAINRUNDIR}

if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ] ; then 
	# need to rename supermaster. Note that info files also should be changed
	for stringname in `ls -d *${SUPERMASNAME}*`
	   do
		# dirs
		SUPERMASDATE=`echo "${SUPERMASTER}" | cut -d _ -f 3`
		NEWNAME=`echo ${stringname} | gsed "s/${SUPERMASNAME}/${SUPERMASDATE}/" `
		mv ${stringname} ${NEWNAME}
	done
fi 


# Must dump the log in script before moving
EchoTee "--------------------------------------------------------"
EchoTee "Dump script in ${LOGFILE} for debugging " 
EchoTee "--------------------------------------------------------" 
cat $(dirname $0)/${PRG} >> ${LOGFILE}

EchoTee "" 	
EchoTee "--------------------------------------------------------"
EchoTee "Dump FUNCTIONS_FOR_CIS.sh  in ${LOGFILE} for debugging " 
EchoTee "--------------------------------------------------------" 
cat ${FCTFILE} >> ${LOGFILE}
EchoTee "" 
EchoTee "" 	
EchoTee "--------------------------------------------------------"
EchoTee "Dump list of pairs etc... in ${LOGFILE} for debugging " 
EchoTee "--------------------------------------------------------" 
EchoTee "Dump New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt\n"
cat ${OUTPUTDATA}/New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt >> ${LOGFILE}
rm -f ${OUTPUTDATA}/New_Slaves_to_process_${RUNDATE}_${RNDM1}.txt

EchoTee "--------------------------------------------------------" 
EchoTee "Dump All_Slaves_${RUNDATE}_${RNDM1}.txt\n"
cat ${OUTPUTDATA}/All_Slaves_${RUNDATE}_${RNDM1}.txt >> ${LOGFILE}
rm -f ${OUTPUTDATA}/All_Slaves_${RUNDATE}_${RNDM1}.txt
EchoTee "--------------------------------------------------------" 
	EchoTee "Dump Processed_slaves_${RUNDATE}_${RNDM1}.txt\n"
	cat ${OUTPUTDATA}/Processed_slaves_${RUNDATE}_${RNDM1}.txt >> ${LOGFILE}
	rm -f ${OUTPUTDATA}/Processed_slaves_${RUNDATE}_${RNDM1}.txt
	EchoTee "--------------------------------------------------------" 

if [ ${CROP} == "CROPyes" ]
	then
	EchoTee "Dump New_Slaves_to_Crop_${RUNDATE}_${RNDM1}.txt\n"
	cat ${OUTPUTDATA}/New_Slaves_to_Crop_${RUNDATE}_${RNDM1}.txt>> ${LOGFILE}
	rm -f ${OUTPUTDATA}/New_Slaves_to_Crop_${RUNDATE}_${RNDM1}.txt
	EchoTee "--------------------------------------------------------" 
	EchoTee "Dump Cropped_slaves_${RUNDATE}_${RNDM1}.txt\n"
	cat ${OUTPUTDATA}/Cropped_slaves_${RUNDATE}_${RNDM1}.txt >> ${LOGFILE}
	rm -f ${OUTPUTDATA}/Cropped_slaves_${RUNDATE}_${RNDM1}.txt
	EchoTee "--------------------------------------------------------" 
fi

rm -f Read_*.txt
rm -f slantRange.txt

EchoTee "" 
# move results to ${DATAPATH}_Resampled_${MAS}
# Instead of moving that is impossible beacause of permissions between different OS
#     one cp then check if similar. 
#######################################################
EchoTee "--------------------------------------------------------"
EchoTee "Moving results to ${OUTPUTDATA} without keeping permissions" 
EchoTee "and rebuild the path in InSARParameter.txt. " 
EchoTee ""

# better move than cp but crash when move from Linux to Win because of permissions.
# Hence copy, then check...  

# If 4 1st dir of PROROOTPATH is the same as 4 1st dir of OUTPUTDATA, then mv, else cp and check
tst1=`RemDoubleSlash  ${PROROOTPATH}`
tst2=`RemDoubleSlash  ${OUTPUTDATA}`
tst1=`echo ${tst1} | cut -d / -f 3`
tst2=`echo ${tst2} | cut -d / -f 3`

EchoTee " Processing was done on ${tst1} and results must be store in ${tst2}"
if [ "${tst1}" == "${tst2}" ]
	then 
		EchoTee "Same physical disk; Everything was moved to ${OUTPUTDATA}."
		mv -f * ${OUTPUTDATA}	
	else 
		cp -r * ${OUTPUTDATA}

		diff -r -q ${MAINRUNDIR} ${OUTPUTDATA} | ${PATHGNU}/grep "Only in ${MAINRUNDIR}"  > ${OUTPUTDATA}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt
		cat ${OUTPUTDATA}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt | ${PATHGNU}/grep -v .txt | ${PATHGNU}/grep -v ModulesForCoreg > ${OUTPUTDATA}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt
		EchoTee ""
		EchoTee "Not the same physical disk; Copy and Check if all is copied - ignore messages diff about links. " 
		EchoTee ""

		# From now on, log file is in ${MASSPROCESSPATHLONG}
		LOGFILE=${OUTPUTDATA}/LogFile_Super${MAS}_${RUNDATE}_${RNDM1}.txt

		echo ""

		if [ -f "${OUTPUTDATA}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt" ] && [ -s "${OUTPUTDATA}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt" ]
			then 
				EchoTee "Not everything was copied - no remove from source dir ${MAINRUNDIR}. Check yourself !!" 
			else 
				EchoTee "Everything was copied to ${OUTPUTDATA}."
				EchoTee "Remove from source dir ${MAINRUNDIR}." 
				rm -r ${MAINRUNDIR}/*
				rm -f ${OUTPUTDATA}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt
		fi
fi

echo "Rebuild the path in InSARParameter.txt. " 
cd ${OUTPUTDATA}

if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ] ; then 
		RenamePathAfterMove.sh ${SATDIR}STRIPMAP
	else 
		RenamePathAfterMove.sh ${SATDIR}
fi

RenamePath_Volumes.sh

if [ "${SATDIR}" == "S1" ] ; then rm -f ${FLAGUSAGE} ; fi

# Need this for updating link to resampled S1 images (needed e.g. for SuperMaster_MassProc.sh)
# if [ "${SATDIR}" == "S1" ] ; then UpdateLinkAfterMove.sh ; fi

# remove old files
cd  ${OUTPUTDATA}/
find . -maxdepth 1 -name "LogFile*.txt" -type f -mtime +30 -exec rm -f {} \;
find . -maxdepth 1 -name "Quarantained_*.txt" -type f -mtime +30 -exec rm -f {} \;

SpeakOut "SuperMaster coregistration of ${SATDIR} ${TRKDIR} ${REGION} done. "

# done 
