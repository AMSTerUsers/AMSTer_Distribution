#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at processing all compatible pairs form a give sat/mode in 
#     the geometry of a given Global Primary (SuperMaster) as selected by Prepa_MSBAS.sh eg in 
#     /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/seti/setParametersFile.txt
#   
# All Secondary images must have been resamled at Global Primary (SuperMaster) grid using SuperMasterCorg.sh and stored 
#     in a dir such as /Volumes/hp-1650-Data_Share1/SAR_SM/RESAMPLED/SATDIR/TRKDIR
#
# Parameters : - file with the compatible pairs (incl path; named as table_MinBp_MaxBp_MinBt_MaxBt.txt)    
#              - file with the processing parameters (incl path) 
#			   - optional: -f option as a third param forces the script to build the list of existing 
#						 pairs based on the files in Geocoded/DefoInterpolx2Detrend 
#						 instead of on the list of pair dirs. 
#						 -list=filename, it forces to compute only pairs in provided list 
#						 (filename MUST be in the form of list of PRM_SCD dates)
#
# Dependencies:
#    - Data coregistered on a Global Primary (SuperMaster)... of course
#	 - AMSTerEngine and AMSTerEngine Tools, at least V20190716
#	 - PRAMETERS file, at least V 20190710
#    - The FUNCTIONS_FOR_MT.sh file with the function used by the script. Will be called automatically by the script
#    - gnu sed and awk for more compatibility. 
#    - cpxfiddle is usefull though not mandatory. This is part of Doris package (TU Delft) available here :
#            http://doris.tudelft.nl/Doris_download.html. 
#    - Fiji (from ImageJ) is usefull as well though not mandatory
#    - convert (to create jpg images from sun rasters)
#    - bc (for basic computations in scripts)
#    - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#    - gmt (for inverting deformation if MAS > SLV)
#    - snaphu
#    - masterDEM.sh
#	 - linux trap function
#	 - byte2Float.py
#
#
# New in Distro V 1.0:	- Based on developpement version 15.1 and Beta V4.0.0
# New in Distro V 1.0:	- add counter for pairs to process
# New in Distro V 1.0.1: - remove log files older than 30 days
# New in Distro V 1.1: - remove S1 master.interpolated.csl (but the Info) after processing
# New in Distro V 1.2: - if launched with option -f, it forces to create the list of existing 
#						 pairs based on the files in Geocoded/DefoInterpolx2Detrend 
#						 instead of on the list of pair dirs. 
#					   - do not list _CheckResults dir while building existing pairs list
# New in Distro V 1.3: - if launched with option -list=filename, it forces to compute only pairs 
#						 in provided list (filename MUST be in the form of list of MASTER_SLAVE dates)
# New in Distro V 1.3.1:- Read parameter to allow calibration of S1 images
# New in Distro V 1.3.2:- bug fix to test list of files to read
# New in Distro V 1.3.3:- keep copy of param file in pair dir
# New in Distro V 1.3.4:- check OS in order to let MakeFig functions sleep 1 sec when Linux 
# New in Distro V 1.3.5:- path to gnu grep
# New in Distro V 1.4.0:- if forced pairs in table_MinBp_MaxBp_MinBt_MaxBt_AdditionalPairs.txt, it 
#						  copy that file in the SAR_MASSPROCESS/SAT/TRK for further usage by build_header_msbas_criteria.sh
# New in Distro V 1.5.0:- cleaning and update to cope with improvements in SinglePair.sh 2.3.0
# New in Distro V 1.6.0:- allows mapping of zones unwrapped with snaphu
# 						- When using S1, creates an empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt to let ReadAll_Img.sh to know
#							  that it can't remove the processed products of S1 data of the same mode as the one under progress to avoid prblms.
#							  Note that the script will remove that file at normal termination or CTRL-C, but not if script is terminated using kill. In such a case, you need to remove the file manaully.
#							  Note also that DoNotUpdateProducts_Date_RND.txt is touched at every time a new pair is processed. It allows to check that it is a recent processing and not a ghost file.  
# New in Distro V 1.6.1:- Get master.mod from OUTPUTDATA/ModulesForCoreg instead of OUTPUTDATA/SUPERMASNAME_SLVNAME using again function GetImgMod. 
# New in Distro V 1.7.0:- Do not remove SuperMasterResampled.csl in InSARProducts for S1 Strip Map when it is a link 
# New in Distro V 1.8.0:- Search for duplicated files in Geocoded and GeocodedRasters... just in case, 
#						  and save the list in Geocoded/Duplicated_Files.txt. Procedure is based on Remove_Duplcaite_Pairs_File.sh
# New in Distro V 1.8.1:- improve log managment at the end of processing
#						- do not list pairs that exist but that would be inverted as pair to process
# New in Distro V 1.8.2:- to cope with very large number of dir, uses find instead of ls for listing the existing dir 
# New in Distro V 1.8.3:- debug list of existing pairs for non S1 images (leading ./ in list was preventing proper comparison for new pairs to process, which made the script to attempt and skip pairs that were already computed)
# New in Distro V 1.9.0:- Allows defining forced geocoded are with a kml using the GEOCKML parameter to be read from the LaunchParam.txt 
# New in Distro V 1.9.1:- Cleean log files older than 30 days in SAR_MASSPROCESS named Check_MoveFromRundir*.txt
# New in Distro V 1.9.2:- start processing the newest interferos firsts (just in case the user would need urgently the info)
# New in Distro V 1.9.3:- Keep track of MasTer Engine version in log by looking at MasTer Engine source dir 
# New in Distro V 1.9.4:- Improve diff check when dumping results to final dir when source and target dirs are not the same.  
#						- prevent rsyncing the massprocessing dir instead of all its subdirs
#						- done on Aug 10 2022
# New in Distro V 1.10: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V 1.11: - allows recursive unwrapping
# New in Distro V 2.0 : - copy processed dir to SAR_MASSPROCESS while starting computing the next pair instead of doing it at the end
#						- cosmetic: replace messages about 4th param as 3rd param
#						- set cleaning log files after duration now hardcoded in a variable at the end. (was hardcoded as number in each line before)
# New in Distro V 2.1 : - Just in case a table_0_xx_0_xx_AdditionalPairs.txt would have a wrong format and create additional columns, trim the list of pairs after yyyymmdd_yyyymmdd, that is 17 characters
# New in Distro V 2.2 : - To avoid hanging on empty pair in list of pairs to process, add a test in mass processing loop.
# New in Distro V 2.3 : - Additional test on input pair list format
# New in Distro V2.3.1: - Display full command line used if more than one param
# New in Distro V2.3.2: - cosmetic: renaming S1 SM ampli image from MAS to MASNAME seems obsolate 
# New in Distro V2.3.3: - improve tests before removing processed directories after completion 
# New in Distro V2.4: 	- replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V2.5: 	- read UTM zone for geocoding
# New in Distro V2.6 20231002:	- compatible with new multi-mevel masks where 0 = non masked and 1 or 2 = masked  
#								- add fig snaphuMask and keep copy of unmasked defo map
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

PAIRFILE=$1					# File with the compatible pairs; named as table_MinBp_MaxBp_MinBt_MaxBt.txt
PARAMFILE=$2				# File with the parameters needed for the run
LISTOFPROCESSED=$3			# if -f, it forces to create the list of existing pairs based on the files in Geocoded/DefoInterpolx2Detrend 
							# if -list=filename, it forces to compute only pairs in provided list (file MUST be in the form of list of PRM_SCD dates)

if [ $# -lt 2 ] ; then echo “Usage $0 PAIRS_FILE PARAMETER_FILE ”; exit; fi

#if [ $# -eq 3 ] ; then LISTOFPROCESSED=YES ; else LISTOFPROCESSED=NO ; fi 
if [ $# -eq 3 ]
	then 
		case ${LISTOFPROCESSED} in 
			"-f") # get the list of proecessed pairs from Geocoded/DefoInterpolx2Detrend
				LISTOFPROCESSED=YES ;;
			"-list="*)  # Do not compute list of processed pairs to compute wich is still to process because the list of pairs to process is provided instead
			 	PATHTOPAIRLIST=`echo ${LISTOFPROCESSED} | cut -d = -f2 `
			 	LISTOFPROCESSED=FILE
			 	# check that list is of correct form
				PAIRDATE=`head -1 ${PATHTOPAIRLIST} | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}"`  # get date_date
				TESTPAIR=`head -1 ${PATHTOPAIRLIST} | ${PATHGNU}/gsed "s/${PAIRDATE}//g" | wc -m` # check that there is nothing esle than PAIRDATE
				if [ `echo "${PAIRDATE}" | wc -m` == 18 ] && [ ${TESTPAIR} == 1 ] 
					then 
						echo "Valid pair files to process"  
					else 
						echo "Invalid pair files to process; must be in the form of DATE_DATE. Exit" 
						exit 0 
				fi
			 	;;
			 	
			*)	# not sure what is wanted hence keep default processing 
				echo "Not sure what your 3rd parameter is. "
				echo "  This option must be -f to search for list of processed pairs in Geocoded/DefoInterpolx2Detrend or "
				echo "                      -file=list to provide a list of pairs to process.  " 
				echo "Since the 3rd parameter provided is of none of these forms, let's keep default processing, "
				echo "  i.e. compute the list of preocessed pairs from the pair dirs in SAR_MASSPROCESS" 
				LISTOFPROCESSED=NO ;;	
		esac  
	else 
		LISTOFPROCESSED=NO
fi 

# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

SUPERMASTER=`GetParam SUPERMASTER`			# SUPERMASTER, date of the Global Primary (SuperMaster) as selected by Prepa_MSBAS.sh in
											# e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/seti/setParametersFile.txt

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

MULTIUWP=`GetParam "MULTIUWP"`				# MULTIUWP, MultiSnaphuYes performs recursive snaphu unwrapping (need 4 params bellow). MultiUnwrapNo (or any other string) will perform single snaphu unwrapping 
WHICHINTERF=`GetParam "WHICHINTERF"`		# WHICHINTERF, which interferogram to unwrap, ResidInterf (residual interfero) or ResidInterfFilt (residual interfero filtered) 
COEFREQ=`GetParam "COEFREQ"`				# COEFREQ, Coefficient of increase of cut-off frequency
CUTINI=`GetParam "CUTINI"`					# CUTINI, Initial cut-off frequency (e.g. 12.5 for a 400x400 image, 10 for a 2200x1500 img)
NITMAX=`GetParam "NITMAX"`					# NITMAX, Max total nr of iterrations
COHMUWPTHRESH=`GetParam "COHMUWPTHRESH"`	# COHMUWPTHRESH, coh threshold (between 0 and 1) below which it replaces the phase by white noise (corresponding mask will be produced). If set to 0, do not mask with white noise 

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
GEOCKML=`GetParam "GEOCKML,"`				# GEOCKML, a kml file to define final geocoded product. If not found, it will use the coordinates above

REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
DEMNAME=`GetParam "DEMNAME,"`				# DEMNAME, name of DEM inverted by lines and columns

MASSPROCESSPATH=`GetParam MASSPROCESSPATH`	# MASSPROCESSPATH, path to dir where all processed pairs will be stored in sub dir named by the sat/trk name (SATDIR/TRKDIR)
RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data are stored 

mkdir -p ${PROROOTPATH}
eval PROPATH=${PROROOTPATH}/${SATDIR}/${TRKDIR}	# Path to dir where data will be processed.

source ${FCTFILE}

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

case ${CROP} in 
	"CROPyes") 
		CROPDIR=/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP} #_Zoom${ZOOM}_ML${INTERFML}
		;;
	"CROPno")		
		CROPDIR=/NoCrop 
		;;
	*.kml)  
		CROPDIR=/NoCrop 
		CROPKML=${CROP}
		;;
esac


# Check GeocMethod : if you process a MassProcessing, I guess you intend to make MSBAS, hence FORCE is required
if [ ${GEOCMETHD} == "ClosestMassProc" ]
	then
		EchoTeeRed " OK you want to keep geocoded pixels as close as possible as original ones although you run a Mass Process."
		EchoTeeRed "   Be aware that you wan't be able to do MSBAS because other modes will be in different grid."
		EchoTeeRed "   It will be ok for a SBAS with only this mode though. You know what you are doing..."
		GEOCMETHD="Closest"
	else 
		if [ ${GEOCMETHD} != "Forced" ] 
			then 
				EchoTeeRed "Geocoded pixels not forced to fixed grid. You wan't be able to run MSBAS. If you want it anyway, change GEOCMETHD to ClosestMassProc." 
				exit 0
			else  
				EchoTeeRed "HOPE YOU HAVE CHECKED THE SIZE OF YOUR GEOCODED PIXELS AND THE COORDINATES OF YOUR FINAL PRODUCTS' CORNERS." 
		fi
fi
echo 
echo 


eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
eval RNDM1=`echo $(( $RANDOM % 10000 ))`

# Define Dir where data are/will be cropped
INPUTDATA=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}
mkdir -p ${INPUTDATA}


# Test if S1 is strip map, because it would then require normal processing
case ${SATDIR} in 
	"S1") 
		# need this definition here for usage in GetParamFromFile
		MASDIR=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${SUPERMASTER}` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway

		S1ID=`GetParamFromFile "Scene ID" SAR_CSL_SLCImageInfo.txt`
		S1MODE=`echo ${S1ID} | cut -d _ -f 2`	
		if [ ${S1MODE} == "IW" ] || [ ${S1MODE} == "EW" ]
			then 
				S1MODE="WIDESWATH"
				EchoTeeRed "Wideswath S1 data can't be coregistered on a SUPERMASTER for SuperMaster_MassProc.sh."
				EchoTeeRed " Pairs will be processed separately and compared to each other after geocoding."
				SUPERMASNAME=`ls ${INPUTDATA} | ${PATHGNU}/grep ${SUPERMASTER} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
			else 
				S1MODE="STRIPMAP"
				SUPERMASNAME=`echo ${MASDIR} | cut -d. -f1`		
		fi
		EchoTee "Processing S1 images in mode ${S1MODE}" 
		
		# Creates an empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt to let ReadAll_Img.sh to know
		# that it can't remove the processed products of S1 data of the same mode as the one under progress to avoid prblms
		eval FLAGUSAGE=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/DoNotUpdateProducts_${RUNDATE}_${RNDM1}_MP.txt
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
		S1MODE="DUMMY"  # needed to ease some tests 
		
		# Ensure that MAS is in _TX	
		MASTDXMODE="_${TRKDIR##*_}"   # everything after last _, incl _
		BSORPM==`echo ${TRKDIR} | rev | cut -d_ -f 4 | rev` 	# i.e. from TRKDIR name: PM (pursuite) or BS (bistatic) 
		TDXMODE=`echo ${TRKDIR} | rev | cut -c4- | rev`   		# i.e. everything in TRKDIR name but the _TX or _RX

		if [ ${MASTDXMODE} != "_TX" ] 
 			then 
 				EchoTee "Primary mode is ${MASTDXMODE}, not TX; please check" 
 				exit 0
		fi
		SLVTDXMODE="_TX"
		SUPERMASNAME=${SUPERMASTER}
		;;
	*) 
		SUPERMASNAME=${SUPERMASTER}
		;;
esac

SUPERMASDIR=${SUPERMASNAME}.csl

# Check required dir:
#####################
	# Where data will be processed for the coregistration computation
	if [ -d "${PROROOTPATH}/" ]
		then
		  echo "  // OK: a directory exist where I can create a processing dir." 
		else
			PROROOTPATH="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$PROROOTPATH)"
		   if [ -d "${PROROOTPATH}/" ]
				then
					echo "  // Double mount of hp-storeesay. Renamed dir with -1"
				else 
					echo " "
					echo "  // NO directory ${PROROOTPATH}/ where I can create a processing dir. Can't run..." 
					echo "  // Check parameters files and  change hard link if needed."
					exit 1
			fi
	fi

	# Path to data
	if [ -d "${DATAPATH}" ]
		then
		   echo "  // OK: a directory exist where data are supposed to be stored." 
		   mkdir -p ${PROPATH}
		else
		   DATAPATH="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$DATAPATH)"
		   if [ -d "${DATAPATH}/" ]
				then
					echo "  // Double mount of hp-storeesay. Renamed dir with -1"
				else 
					echo "  // "
					echo "  // NO expected data directory. Can't run..." 
					echo "  // PLEASE REFER TO SCRIPT and  change hard link if needed"
					exit 1
			fi
	fi
	
	if [ -d "${DEMDIR}" ]
		then
		   echo "  // OK: a directory exist where DEM is supposed to be stored." 
		else
			DEMDIR="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$DEMDIR)"
		   if [ -d "${DEMDIR}/" ]
				then
					echo "  // Double mount of hp-storeesay. Renamed dir with -1"
				else 
					echo " "
					echo "  // NO expected DEM directory. Can't run..." 
					echo "  // PLEASE REFER TO SCRIPT and  change hard link if needed"
					exit 1		
			fi
	fi

	# Define Super Master Crop Dir and place where original data are
	if [ ${CROP} == "CROPyes" ]
		then
			SMCROPDIR=SMCrop_SM_${SUPERMASTER}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}   #_Zoom${ZOOM}_ML${INTERFML}
		else
			SMCROPDIR=SMNoCrop_SM_${SUPERMASTER}  #_Zoom${ZOOM}_ML${INTERFML}
	fi
	# Resampled data on SuperMaster in csl format are stored in 
	OUTPUTDATA=${RESAMPDATPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}

EchoTee "" 
EchoTee "---------------------------------------------------------------------"
EchoTee " Suppose resampled data to SM are stored somewhere on ${OUTPUTDATA}"
EchoTee "         If not change hard link in parameters file"
EchoTee ""
EchoTee " Suppose data will be processed somewhere in ${PROPATH}/"
EchoTee "         If not change hard link in parameters file"
EchoTee " Suppose processed data will be stored somewhere in ${MASSPROCESSPATH}/"
EchoTee "---------------------------------------------------------------------"
EchoTee ""



# Path to resampled data  
	if [ -d "${OUTPUTDATA}" ]  # Path to dir where resampled data are stored.
	then
	   echo "  // OK: a directory exist where Resampled data on Global Primary (SuperMaster) ${SUPERMASTER} are stored ." 
	   echo "  //    They were most probably computed wth a script SuperMasterCoreg.sh"
	   mkdir -p ${PROPATH}
	else
	   echo " "
	   echo "  // NO expected ${OUTPUTDATA} directory."
	   echo "  // Can't run wthout these Resampled data on Global Primary (SuperMaster) ${MAS}" 
	   echo "  // PLEASE REFER TO SCRIPT and  change hard link if needed,"
	   echo "  // or run the appropriate script such as SuperMasterCoreg.sh "
	   exit 1
	fi


# Path to where mass processing results will be sored
if [ -d "${MASSPROCESSPATH}" ]
then
   echo "  // OK: a directory exist where Mass Processing results can be stored. "
else
   echo "  // "
   echo "  // NO expected directory where Mass Processing results can be stored. Can't run..." 
   echo "  // PLEASE REFER TO SCRIPT and  change hard link if needed or create dir."
   exit 1
fi

# Check that PROCESSMODE is consistent with unwrapping parameters
		if [ "${PROCESSMODE}" == "" ] 
			then 
				EchoTee "PROCESSMODE parameter is missing in your Launch Parameters File, which must be version April 2019 or later. Please update." 
				exit 1
		fi
		if  [ "${PROCESSMODE}" != "${SNAPHUMODE}" ] && [ "${UW_METHOD}" == "SNAPHU" ]
			then 
				EchoTee "You request a ${PROCESSMODE} processing but intend to unwrap with snaphu using ${UW_METHOD} default Snaphu parameters. Please update" 
				exit 1
		fi

# Let's Go:
###########	

# Prepare
	# Create working dirs if does not exist yet
	RUNDIR=${PROPATH}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}
	mkdir -p ${RUNDIR}

	MASSPROCESSPATHLONG=${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}	# i.e. now as written here
	mkdir -p ${MASSPROCESSPATHLONG}
	
cd ${RUNDIR}				# i.e. now ${PROROOTPATH}/${SATDIR}/${TRKDIR}/SMas_${MAS}/(No)Crop
cp ${PARAMFILE} ${RUNDIR} 		

# Check here if it runs on same physical disk as final storage or SAR_MASSPROCESS
# If 4 1st dir of PROROOTPATH is the same as 4 1st dir of MASSPROCESSPATH, then mv, else cp and check
	execdir=`RemDoubleSlash  ${PROROOTPATH}`
	storedir=`RemDoubleSlash  ${MASSPROCESSPATH}`
	execdir=`echo ${execdir} | cut -d / -f 3`
	storedir=`echo ${storedir} | cut -d / -f 3`

	tmp2=`RemDoubleSlash  ${MASSPROCESSPATHLONG}`
	MASSPROCESSPATHLONG=`echo ${tmp2}`
	EchoTee " Processing will be done on ${execdir} and results will be stored in ${storedir}"


# Log File
LOGFILE=${RUNDIR}/LogFile_MassProcess_Super${MAS}_${RUNDATE}_${RNDM1}.txt

echo "" > ${LOGFILE}
EchoTee "Processing launched on ${RUNDATE} \n" 
EchoTee "Main script version: " 
EchoTee "    ${PRG} ${VER}, ${AUT}" 
EchoTee " "
EchoTee "Functions script version: " 
EchoTee "    ${FCTFILE} ${FCTVER}, ${FCTAUT}"
EchoTee " " 
EchoTee "--------------------------------"	
EchoTee "--------------------------------\n"
EchoTee "Command line used :"
EchoTee "$(dirname $0)/${PRG} ${PAIRFILE} ${PARAMFILE} $3"
EchoTee " "
EchoTee "--------------------------------"
EchoTee " Using the parameters file that contains the following parameters:" 
EchoTee "  (Parameters are echoed only in Logfile) \n"
cat ${PARAMFILE} >> ${LOGFILE}
EchoTee "--------------------------------"	
EchoTee "--------------------------------"
EchoTee "Will process pairs that are in :"
EchoTee "    ${PAIRFILE}"
EchoTee " But not in yet in "
EchoTee "    ${MASSPROCESSPATHLONG}"
EchoTee "That is  "
# List existing pairs in dir in pwd
cd ${MASSPROCESSPATHLONG}

case ${LISTOFPROCESSED} in 
			"YES")
				# force to build the list of existing pairs based on the files in Geocoded/DefoInterpolx2Detrend
				rm -f ExistingPairs_${RUNDATE}_${RNDM1}.txt
				for GEOCODEDPAIR in `find ${MASSPROCESSPATHLONG}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg"` ; do 
					echo "${GEOCODEDPAIR}" | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}">> ExistingPairs_${RUNDATE}_${RNDM1}.txt # select date_date where date is 8 numbers
				done ;;
			"NO")
				# force to build the list of existing pairs based on the list of pair dirs in MASSPROCESSPATHLONG
				# If MASSPROCESSPATHLONG contains subdir, check pairs already processed (in the form of date_date ; also for S1) :
				if find "${MASSPROCESSPATHLONG}" -mindepth 1 -print -quit | ${PATHGNU}/grep -q . ; then 
					if [ "${SATDIR}" == "S1" ]
							then 
								#ls -d * | ${PATHGNU}/grep -v ".txt"  | ${PATHGNU}/grep -v "Geocoded" | ${PATHGNU}/grep -v "_CheckResults" | cut -d _ -f 3,7 > ExistingPairs_${RUNDATE}_${RNDM1}.txt
								find . -maxdepth 1 -type d -name "*_*" | ${PATHGNU}/grep -v "Check" | ${PATHGNU}/grep -v ".txt"  | cut -d _ -f 3,7 > ExistingPairs_${RUNDATE}_${RNDM1}.txt
							else 
								#ls -d * | ${PATHGNU}/grep -v ".txt"  | ${PATHGNU}/grep -v "Geocoded" | ${PATHGNU}/grep -v "_CheckResults" > ExistingPairs_${RUNDATE}_${RNDM1}.txt
								find . -maxdepth 1 -type d -name "*_*" | ${PATHGNU}/grep -v "Check" | ${PATHGNU}/grep -v ".txt" | cut -d / -f 2 > ExistingPairs_${RUNDATE}_${RNDM1}.txt
					fi
				fi		;;
			"FILE")	
				# will use PATHTOPAIRLIST as PairsToProcess_${RNDM}.txt, hence create dummy ExistingPairs_${RNDM}.txt
				touch ExistingPairs_${RUNDATE}_${RNDM1}.txt
				;;
esac

if [  ${LISTOFPROCESSED} == "FILE" ]
	then 
		# assign the list of pairs to process as the list provided in 3rd param
		cp ${PATHTOPAIRLIST} ${MASSPROCESSPATHLONG}/PairsToProcess_${RUNDATE}_${RNDM1}.txt
	else 
		# Compatible Pairs (in the form of "date_date"; also for S1):
		 if ${PATHGNU}/grep -q Delay "${PAIRFILE}"
			then
				# If PAIRFILE = table from Prepa_MSBAS.sh, it contains the string "Delay", then
				# Remove header and extract only the pairs in ${PAIRFILE}
				cat ${PAIRFILE} | tail -n+3 | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${PAIRFILE}_NoBaselines_${RNDM1}.txt 
			else
				# If PAIRFILE = list of images to play, it contains already only the dates
				if cat ${PAIRFILE} | tail -1 | ${PATHGNU}/grep -q _  
					then
						# Pair files contains _ then already ready
						cp ${PAIRFILE} ${PAIRFILE}_NoBaselines_${RNDM1}.txt
					else 
						# Pair files does not contains _ and hence need formatting
						cat ${PAIRFILE} | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${PAIRFILE}_NoBaselines_${RNDM1}.txt 
				fi
		 fi
		 
		#Just in case a table_0_xx_0_xx_AdditionalPairs.txt would have a wrong format and create additional columns, trim here the list of pairs after yyyymmdd_yyyymmdd, that is 17 characters
		cut -c1-17 ${PAIRFILE}_NoBaselines_${RNDM1}.txt > ${PAIRFILE}_NoBaselines_${RNDM1}_TMP.txt
		mv -f ${PAIRFILE}_NoBaselines_${RNDM1}_TMP.txt ${PAIRFILE}_NoBaselines_${RNDM1}.txt

		# Search for only the new ones to be processed:
		if [ -f "ExistingPairs_${RUNDATE}_${RNDM1}.txt" ] && [ -s "ExistingPairs_${RUNDATE}_${RNDM1}.txt" ]
			then
				#${PATHGNU}/grep -Fxvf ExistingPairs_${RUNDATE}_${RNDM1}.txt ${PAIRFILE}_NoBaselines_${RNDM1}.txt > PairsToProcess_${RUNDATE}_${RNDM1}.txt
				# get what is in ${PAIRFILE}_NoBaselines_${RNDM1}.txt but not in ExistingPairs_${RUNDATE}_${RNDM1}.txt
				${PATHGNU}/grep -Fxvf ExistingPairs_${RUNDATE}_${RNDM1}.txt ${PAIRFILE}_NoBaselines_${RNDM1}.txt > PairsToProcess_${RUNDATE}_${RNDM1}_tmp.txt
				# skip possible swapped existing pair
				${PATHGNU}/gawk -F "_" ' { t = $1; $1 = $2; $2 = t; print; } ' OFS="_" ExistingPairs_${RUNDATE}_${RNDM1}.txt > ExistingPairs_${RUNDATE}_${RNDM1}_inverted.txt
				# get what is in PairsToProcess_${RUNDATE}_${RNDM1}_tmp.txt but not in ExistingPairs_${RUNDATE}_${RNDM1}_inverted.txt
				${PATHGNU}/grep -Fxvf ExistingPairs_${RUNDATE}_${RNDM1}_inverted.txt PairsToProcess_${RUNDATE}_${RNDM1}_tmp.txt > PairsToProcess_${RUNDATE}_${RNDM1}.txt
			else
				cp ${PAIRFILE}_NoBaselines_${RNDM1}.txt ${MASSPROCESSPATHLONG}/PairsToProcess_${RUNDATE}_${RNDM1}.txt
		fi
fi

# sort pairs to process in reverse order to compute first the most recent ones 
sort -r PairsToProcess_${RUNDATE}_${RNDM1}.txt -o PairsToProcess_${RUNDATE}_${RNDM1}.txt 

NPAIRS=`wc -l < PairsToProcess_${RUNDATE}_${RNDM1}.txt`
EchoTee " ${NPAIRS} pairs :"
cat PairsToProcess_${RUNDATE}_${RNDM1}.txt >> ${LOGFILE}
cat PairsToProcess_${RUNDATE}_${RNDM1}.txt
EchoTee "--------------------------------"
EchoTee "-------------------------------- \n"

# if table_MinBp_MaxBp_MinBt_MaxBt_AdditionalPairs.txt exists with forced pairs, 
# let's copy that file in the SAR_MASSPROCESS/SAT/TRK for further usage by build_header_msbas_criteria.sh
FORCEDPAIRFILESNOEXT=`echo ${PAIRFILE%.*}`  # path and name without last extention
if [ -f "${FORCEDPAIRFILESNOEXT}_AdditionalPairs.txt" ] && [ -s "${FORCEDPAIRFILESNOEXT}_AdditionalPairs.txt" ] ; then cp -f ${FORCEDPAIRFILESNOEXT}_AdditionalPairs.txt ${MASSPROCESSPATHLONG}/ ; fi 

# Start processing chain
########################

cd ${RUNDIR}
MAINRUNDIR=${RUNDIR}			# keep this as RUNDIR will be renamed for each pair


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

# DEM
if [ "${SATDIR}" != "S1" ] || [ "${S1MODE}" != "WIDESWATH" ]
then
	IMGWITHDEM=${SUPERMASNAME} 	# When computed during SinglePair with SuperMaster (or during mass processing)

	if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
		then 
			# CHECK THAT MASK IS SIMILAR TO POSSIBLE FORMER RUN
			FORMERMASK=`ls -d ${MASSPROCESSPATHLONG}/* | head -1`
			if [ -f "${FORMERMASK}/slantRange.txt" ] && [ -s "${FORMERMASK}/slantRange.txt" ] ; then 
				FORMERMASK=`updateParameterFile ${FORMERMASK}/slantRange.txt "Georeferenced mask file path"`
				if  [ "${FORMERMASK}" != "${PATHTOMASK}" ] 
					then 
					EchoTeeRed " Mask request is not the same as former processingg. Please check"
					SpeakOut " Mask request is not the same as former processing. Please check."
				fi 
			fi

			MASKBASENAME=`basename ${PATHTOMASK##*/}`
		else 
			MASKBASENAME=`echo "NoMask"` # not sure I need it
	fi 	# i.e. "NoMask" or "mask file name without ext" from Param file


	# Need this for ManageDEM
	PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
	PIXSIZERG=`echo "${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 

	ManageDEM
else 
	# select in ${MASSPROCESSPATHLONG}/PairsToProcess_${RUNDATE}_${RNDM1}.txt only_the_masters  

	rm -f only_the_masters_tmp.txt
	for PAIRTOCHECK in `cat -s ${MASSPROCESSPATHLONG}/PairsToProcess_${RUNDATE}_${RNDM1}.txt`
		do
		echo ${PAIRTOCHECK} | cut -d _ -f 1 >> only_the_masters_tmp.txt
	done
	sort only_the_masters_tmp.txt | uniq > only_the_masters.txt
	rm -f only_the_masters_tmp.txt

	if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
		then 
			EchoTeeRed " If not the first mass processing run for this mode, it is your responsability to check that the mask is the same as the one used for pairs already processed. Please check."
			SpeakOut " If not the first mass processing run for this mode, it is your responsability to check that the mask is the same as the one used for pairs already processed."
	fi

	for MASONLY in `cat -s only_the_masters.txt`
		do
		# check if DEM and filter exist	
		MASONLYNAME=`ls ${INPUTDATA} | ${PATHGNU}/grep ${MASONLY} | cut -d . -f 1 `  				# Must get here the whole S1 name as in ${INPUTDATA}/${IMGWITHDEM}.csl but csl extension is added in MangeDEM
		IMGWITHDEM=${MASONLYNAME} 	# When computed during SinglePair with SuperMaster (or during mass processing)

		if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
			then 
				MASKBASENAME=`basename ${PATHTOMASK##*/}`
			else 
				MASKBASENAME=`echo "NoMask"` # not sure I need it
		fi 	# i.e. "NoMask" or "mask file name without ext" from Param file

		# Need this for ManageDEM
		PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
		PIXSIZERG=`echo "${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 

		ManageDEM
	done
	rm -f only_the_masters.txt
fi

# Get date of last AMSTer Engine source dir (require FCT file sourced above)
GetAMSTerEngineVersion

i=0
# PROCESS PAIRS: coreg and resample, or link to existing if Master is SuperMaster
for PAIRS in `cat -s ${MASSPROCESSPATHLONG}/PairsToProcess_${RUNDATE}_${RNDM1}.txt`
do	
	if [ "${PAIRS}" != "" ] ; then 		# skip empty pair

		i=`echo "$i + 1" | bc -l`
		MAS=`echo ${PAIRS} | cut -d _ -f 1`     # i.e. a date (also for S1)
		SLV=`echo ${PAIRS} | cut -d _ -f 2`

		# some naming and conventions
		if [ ${SATDIR} == "S1" ] 
			then 
				MASNAME=`ls ${INPUTDATA} | ${PATHGNU}/grep ${MAS} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
				SLVNAME=`ls ${INPUTDATA} | ${PATHGNU}/grep ${SLV} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
				# repeat touch FLAG to keep recent date and offer the possibility to check that FLAG is not a ghost file 
				touch ${FLAGUSAGE}
			else
				MASNAME=${MAS} 
				SLVNAME=${SLV} 
		fi	
		MASDIR=${MASNAME}.csl
		SLVDIR=${SLVNAME}.csl

		# if SLV is SUPERMASTER, swap ? 
		if [ "${SLV}" == "${SUPERMASTER}" ] && [ "${S1MODE}" != "WIDESWATH" ]  # do not test S1, test S1MODE instead
			then 
				EchoTee ""
				EchoTeeYellow "Secondary is Global Primary (SuperMaster); swap PRM and SCD to benefit from processing already performed at geocoding"
				SLV=${MAS}
				SLVNAME=${MASNAME}
				SLVDIR=${MASDIR}
				MAS=${SUPERMASTER}
				MASNAME=${SUPERMASNAME}
				MASDIR=${SUPERMASDIR}
		fi
		echo
		EchoTee ""
		EchoTee "--------------------------------------------------------------------------------------------"
		EchoTeeYellow "Shall process ${MASNAME} - ${SLVNAME} ; Global Primary is ${SUPERMASTER} ; pair $i/${NPAIRS} "
		EchoTee "--------------------------------------------------------------------------------------------"

		# Check if pair not already processed - mostly in case of supermaster as slave... 
		if [ -d ${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME} ] || [ -d ${MAINRUNDIR}/${MASNAME}_${SLVNAME} ] || [ -d ${MASSPROCESSPATHLONG}/${SLVNAME}_${MASNAME} ] || [ -d ${MAINRUNDIR}/${SLVNAME}_${MASNAME} ]
			then 
				EchoTeeYellow "Pair exists and skipped : ${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}"
			else
				RUNDIR=/${RUNDIR}/${MASNAME}_${SLVNAME}		# Now where pair must be processed
				mkdir -p ${RUNDIR}
				cd ${RUNDIR}				

				# Store date of last AMSTer Engine source dir
				echo "Last created AMSTer Engine source dir suggest Mass Porcessing with AE version: ${LASTVERSIONMT}" > ${RUNDIR}/Processing_Pair_w_AMSTerEngine_V.txt

				if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ] && [ "${CROPKML}" != "" ] 
						then # pseudo crop based on kml file for S1 images
							initInSAR ${INPUTDATA}/${MASDIR} ${INPUTDATA}/${SLVDIR} ${RUNDIR}/i12 ${CROPKML} P=${INITPOL}
						else 
							initInSAR ${INPUTDATA}/${MASDIR} ${INPUTDATA}/${SLVDIR} ${RUNDIR}/i12 P=${INITPOL}
				fi
				cp ${PARAMFILE} ${RUNDIR}
				# Attempt here to force polarisation to INITOPOL but better check
				POLMAS=`GetParamFromFile "Master polarization channel" InSARParameters.txt`
				POLSLV=`GetParamFromFile "Slave polarization channel" InSARParameters.txt`
				if [ "${POLMAS}" != "${INITPOL}" ] ; then EchoTee "Polarisation of Primary (${MAS}) is not the same as the preferred one requested (INITPOL in ParametersFile) : ${POLMAS}-${INITPOL}. Check" ; fi

				# if MAS is not SUPERMASTER, or if S1 wideswath, one need to process each pair. If not, then we can benefit from what is already computed at SuperMasterCoreg
				# Add path to SuperMaster here 
				if [ "${MAS}" != "${SUPERMASTER}" ] || { [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ] ; }  # FLAG 0:  because no S1 supermaster processing possible 
					then # FLAG 0
						# Amplitude images"					
						EchoTee "--------------------------------"
						EchoTee "Amplitude images"					
						EchoTee "--------------------------------"
						EchoTee "--------------------------------"

						if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]		# FLAG 1				
							then	
								EchoTee "Skip Amplitude generation because not needed for S1 coreg"
								EchoTee " If want to run it anyway, ensure to have read S1 image with -b option"
								cd ${RUNDIR}/i12
							else
								ChangeParam "Global master to master InSAR directory path" ${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/ InSARParameters.txt
								# Check if master and slave were already used as master in OUTDATA and get the required info:
								# Copy files that can be needed. Attention, one must COPY and not LINK the files because they are changed during processing
								# The function below also update InSARParameters.txt
								if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ]		# FLAG 2
									then 
										EchoTee "Skip module image and Coarse Coregistration computation for S1 because orbits are good enough." 
										EchoTee "Ensure that InitInSAR was informed of the Global Primary (SuperMaster) orbitography"
										FORCECOREG=NO  # will not need to force the coarse coregistration despite the SM
										cd ${RUNDIR}/i12
									else 
										if [ ${SATDIR} == "TSX" ] || [ ${SATDIR} == "TDX" ] || [ ${SATDIR} == "ENVISAT" ] # S1 wideswath are already excluded from MODFROMSM
											then 
												if [ ${CCOHWIN} == 0 ] 
													then 
														EchoTee "Primary and Secondary are already coregistered on a Global Primary (SuperMaster) and TSX/TDX or ENVISAT orbits are good enough to Skip module image and Coarse Coregistration computation." 
														EchoTee "You choose that option by setting CCOHWIN=0. Ensure that InitInSAR was informed of the Global Primary (SuperMaster) orbitography"
														FORCECOREG=NO  # will not need to force the coarse coregistration despite the SM
														cd ${RUNDIR}/i12
													else 
														EchoTee "Primary and Secondary are already coregistered on a Global Primary (SuperMaster). Although TSX/TDX or ENVISAT orbits are good enough, you choosed NOT to Skip module image and Coarse Coregistration computation by setting CCOHWIN=0." 
														EchoTee "Therefore one need to compute module image for the Coarse Coregistration."
														FORCECOREG=YES # will need to force the coarse coregistration despite the SM
														MakeAmpliImgAndPlot 1 1 ORIGINALFORM 	# Parameter is ML factor for RASTER image in x and y; force ORIGINALFORM for module used for coreg
												fi
											else 
												EchoTee "Primary and Secondary are already coregistered on a Global Primary (SuperMaster) but ERS, RS, CSK, ALOS... orbits are not safe enough to Skip module image and Coarse Coregistration computation." 
												EchoTee "Therefore one need to compute module image for the Coarse Coregistration."
												FORCECOREG=YES # will need to force the coarse coregistration despite the SM
												MakeAmpliImgAndPlot 1 1 ORIGINALFORM 	# Parameter is ML factor for RASTER image in x and y; force ORIGINALFORM for module used for coreg
										fi
								fi # end of FLAG 2, i.e. if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ]
						fi	 # end of FLAG 1, i.e. if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]		
						EchoTee "--------------------------------"	
						EchoTee "Coregistration - resampling"	
						EchoTee "--------------------------------"
						EchoTee "--------------------------------"
						if [ "${SATDIR}" == "S1" ]  && [ "${S1MODE}" == "WIDESWATH" ] 
							then
								# Performing zoom with S1 wide swath is possible if images are coreg with option -d
								if [ "${ZOOM}" != "1" ] 
									then 
										EchoTeeRed "Coregister Sentinel data with zoom factor not 1." 
										S1Coregistration -d
									else 
										S1Coregistration
								fi
							else
								cd ${RUNDIR}/i12
								if [ "${FORCECOREG}" == "NO" ]
									then 
										EchoTee "Primary and Secondary are already coregistered on a Global Primary (SuperMaster). Let's take these interpolated.csl image as input image and skip coarse coreg"
										EchoTee "Ensure that InitInSAR was informed of the Global Primary (SuperMaster) orbitography"
										echo
									else 
										EchoTee "Primary and Secondary are not coregistered on a Global Primary (SuperMaster) or you choosed not to skip coarse coreg."
										CoarseCoregTestQuality
								fi	

								# Fine Coregistration
								EchoTee "--------------------------------"	

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
								TSTFINECOREG=`${PATHGNU}/grep "Total number of anchor points" ${LOGFILE} | tail -n1 | tr -dc '[0-9]'`
								if [ "${TSTFINECOREG}" -le "4" ] ; then EchoTee " Fine processing seemed to have failed (less than 4 anchor points... Exiting" ; exit 0 ; fi
	
								EchoTeeYellow "  // fine coreg done with ${TSTFINECOREG} anchor points" 
								EchoTee "--------------------------------"		

								# Interpolaton - Can try to Launch in background ?
								interpolation | tee -a ${LOGFILE}
						fi # end of if [ "${SATDIR}" == "S1" ]  && [ "${S1MODE}" == "WIDESWATH" ] 
					
						EchoTee "Interpolation done" 
						EchoTee "-------------------------------- \n"
			
					else # FLAG 0: MAS is SUPERMASTER (not for S1 Wideswath though), hence one can get many info form OUTPUTDATA 
						# Link to data already available in OUTPUTDATA
						cd ${RUNDIR}/i12/InSARProducts
						echo ; EchoTee ""
						EchoTeeYellow "To speed up the process and save storage, one link the MAS and SLV modules from OUTPUTDATA."
						if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ] 
							then 
								SUPERMASNAMEBAK=${SUPERMASNAME}
								SUPERMASNAME=${SUPERMASTER}  # may be a problem later ?  
						fi
						ln -s ${OUTPUTDATA}/${SUPERMASNAME}_${SLVNAME}/i12/InSARProducts/${SLVNAME}.interpolated.csl ${RUNDIR}/i12/InSARProducts/${SLVNAME}.interpolated.csl
	# link below does not exists 
	#					ln -s ${OUTPUTDATA}/${SUPERMASNAME}_${SLVNAME}/i12/InSARProducts/${MASNAME}.${POLMAS}.mod ${RUNDIR}/i12/InSARProducts/${SUPERMASNAME}.${POLMAS}.mod 
	# must get the file
						# Copy files that can be needed. Attention, one must COPY and not LINK the files because they are changed during processing
						# The function below also update InSARParameters.txt
						if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ]
							then 
								GetImgMod ${MASNAME} master  
							else 
								GetImgMod ${MAS} master  
						fi
					
						ln -s ${OUTPUTDATA}/${SUPERMASNAME}_${SLVNAME}/i12/InSARProducts/${SLVNAME}.${POLSLV}.mod ${RUNDIR}/i12/InSARProducts/${SLVNAME}.${POLSLV}.mod

						# Need to update the InSARProducts.txt
						cd ${RUNDIR}/i12/TextFiles
						mv InSARParameters.txt InSARParameters.back.txt
				
						# Get the beginning of the Param file from RESAMPLED dir
						${PATHGNU}/gsed -n /"InSAR parameters file"/,/"Global master to master InSAR processing"/p ${OUTPUTDATA}/${SUPERMASTER}_${SLVNAME}/i12/TextFiles/InSARParameters.txt > ${RUNDIR}/i12/TextFiles/tmpHeadOUTPUTDATAInSARParam.txt
						# Get the end of the Param file from the one prepared for the current pair some (mili)sec  ago
						${PATHGNU}/gsed -n '/Global master to master InSAR processing/,$p' ${RUNDIR}/i12/TextFiles/InSARParameters.back.txt | ${PATHGNU}/grep -v "Global master to master InSAR processing" > ${RUNDIR}/i12/TextFiles/tmpTailRUNDIRInSARParam.txt
						cat tmpHeadOUTPUTDATAInSARParam.txt tmpTailRUNDIRInSARParam.txt > ${RUNDIR}/i12/TextFiles/InSARParameters.txt
				
						# Change interpolated path to RUNDIR because link point toward files that are not anymore in dir where they were processed
						ChangeParam "Reduced master amplitude image file path" "${RUNDIR}/i12/InSARProducts/${SUPERMASNAME}.${POLMAS}.mod" InSARParameters.txt
						ChangeParam "Reduced slave amplitude image file path" "${RUNDIR}/i12/InSARProducts/${SLVNAME}.${POLSLV}.mod" InSARParameters.txt
	
						#ChangeParam "Interpolated slave image file path" "${RUNDIR}/i12/InSARProducts/${SLVNAME}.${POLSLV}.interpolated" InSARParameters.txt
						ChangeParam "Interpolated slave image file path" "${RUNDIR}/i12/InSARProducts/${SLVNAME}.interpolated.csl" InSARParameters.txt
						rm tmpHeadOUTPUTDATAInSARParam.txt tmpTailRUNDIRInSARParam.txt InSARParameters.back.txt
				fi 	# end of FLAG 0: MAS is SUPERMASTER (not for S1 Wideswath though), hence one can get many info form OUTPUTDATA

				# get back to multilooking for InSAR
				EchoTee " "	
				EchoTee " Change the ML factor to desired ML factor for final product generation "	
				if [ "${PIXSHAPE}" == "ORIGINALFORM" ] 
					then
						ChangeParam "Range reduction factor" ${INTERFML} InSARParameters.txt
						ChangeParam "Azimuth reduction factor" ${INTERFML} InSARParameters.txt	  	
						PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
						PIXSIZERG=`echo "${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 
					else  
						RatioPix ${INTERFML}
						ChangeParam "Range reduction factor" ${RGML} InSARParameters.txt
						ChangeParam "Azimuth reduction factor" ${AZML} InSARParameters.txt
						PIXSIZEAZ=`echo "${AZSAMP} * ${AZML}" | bc`  # size of ML pixel in az (in m) 
						PIXSIZERG=`echo "${RGSAMP} * ${RGML}" | bc`  # size of ML pixel in range (in m) 
						unset RGML
						unset AZML
				fi

				# INSAR
				case ${SATDIR} in
					"RADARSAT") 
						InSARprocess 1 1	;;    #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
					"TSX") 
						InSARprocess 1 1 	;;   #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
					"TDX") 
						InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
					"CSK") 
						InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
					"S1") 
						InSARprocess 1 2  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
					"ENVISAT") 
						InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
					"ERS") 
						InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
					*) 
						InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
				esac

				HEADING=`updateParameterFile ${RUNDIR}/i12/TextFiles/masterSLCImageInfo.txt "Heading direction"`
				HEADING=`echo ${HEADING} | cut -d " " -f 1`
				EchoTee "Satellite is ${HEADING}."

				# compute unwrapping and plot figs
				if [ ${SKIPUW} == "SKIPyes" ] 
					then
						EchoTeeYellow "  // Skip geocoding as requested, hence obviously skip interpolation and Detrending..."
				#       Parameters are which products to geocode: set YES or NO in right order as below
				#       SLRDEMorDEFO, MASAMPL, SLVAMPL, COH, INTERF, FILTINTERF, RESINTERF, UNWPHASE
						FILESTOGEOC=`echo "NO YES YES YES NO YES YES NO"`
					else 
						case ${SATDIR} in
							"RADARSAT") 
								UnwrapAndPlot 1 1   #  Parameters = ML factor for raster figures only (eg 5 1 for rectangle pixels)
								;;
							"TSX") 
								UnwrapAndPlot 1 1   #  Parameters = ML factor for raster figures only (eg 5 1 for rectangle pixels)
								;;
							"TDX") 
								UnwrapAndPlot 1 1   #  Parameters = ML factor for raster figures only (eg 5 1 for rectangle pixels)
								;;
							"CSK") 
								UnwrapAndPlot 1 1   #  Parameters = ML factor for raster figures only (eg 5 1 for rectangle pixels)
								;;
							"S1") 
								UnwrapAndPlot 1 2   #  Parameters = ML factor for raster figures only (eg 5 1 for rectangle pixels)
								;;
							"ENVISAT") 
								UnwrapAndPlot 1 1   #  Parameters = ML factor for raster figures only (eg 5 1 for rectangle pixels)
								;;
							*) 
								UnwrapAndPlot 1 1   #  Parameters = ML factor for raster figures only (eg 5 1 for rectangle pixels)
								;;
						esac	
					
						# Interpolation of small gaps - gaps are from holes in DEM and/or mask
						if [ ${INTERPOL} == "BEFORE" ] || [ ${INTERPOL} == "BOTH" ]
							then
								EchoTee "You requested an interpolation before geocoding. "
								DEFORG=`GetParamFromFile "Deformation measurement range dimension" InSARParameters.txt`
								DEFOAZ=`GetParamFromFile "Deformation measurement azimuth dimension" InSARParameters.txt`

								if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
									then 
										EchoTee "First multiply deformation map with NaN mask."

										if [ -f "${RUNDIR}/i12/InSARProducts/binarySlantRangeMask" ]
											then 
												EchoTee "Suppose multilevel masking where 1 and/or 2 = to be masked and 0 = non masked."
												# i.e. use new masking method with multilevel masks where 0 = non masked and 1 or 2 = masked
												byte2Float.py ${RUNDIR}/i12/InSARProducts/snaphuMask
												ffa ${RUNDIR}/i12/InSARProducts/deformationMap N ${RUNDIR}/i12/InSARProducts/snaphuMaskFloat -i
												convert -depth 8 -equalize -size ${DEFORG}x${DEFOAZ} gray:${RUNDIR}/i12/InSARProducts/snaphuMask ${RUNDIR}/i12/InSARProducts/snaphuMask.gif
											else 
												if [ ${UW_METHOD} == "CIS" ]
													then 
														EchoTee "CIS unwrapping performed with mask. However, deformation maps are not shown with masked area because there is no product with teh same size. "
														EchoTee "However, you can easily do it manually with any GIS software. "
													else 
														EchoTee "Suppose mask where 0 = to be masked and 1 = non masked."
														# i.e. use old masking method with single level masks where 0 = masked
														ffa ${RUNDIR}/i12/InSARProducts/deformationMap N ${RUNDIR}/i12/InSARProducts/slantRangeMask -i
												fi
										fi
								fi
								fillGapsInImage ${RUNDIR}/i12/InSARProducts/deformationMap ${DEFORG} ${DEFOAZ} 
								# make raster
								MakeFig ${DEFORG} 1.0 1.2 normal jet 1/1 r4 ${PATHDEFOMAP}.interpolated 
							else
								EchoTee "You did not request an interpolation before geocoding."
						fi				
		
						# Remove best plane 
						if [ ${REMOVEPLANE} == "DETREND" ] 
							then 
								EchoTee "You request detrending. \n" 
								RemovePlane 
							else 
								EchoTee "You did not request detrending. \n" 
						fi
				fi   # end of test SKIPUW

		
				# Because for S1 STRIPMAP images masters are in the form of a date, one must rename the files as (super)master-name 	
				if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "STRIPMAP" ] ; then 
					cp ${RUNDIR}/i12/InSARProducts/${MAS}.${POLMAS}.mod ${RUNDIR}/i12/InSARProducts/${MASNAME}.${POLMAS}.mod 2>/dev/null
				fi			
		
				# compute multiple geocoding and plot 
					#  Parameters are which products to geocode: set YES or NO in right order as below
					#  SLRDEM, MASAMPL, SLVAMPL, COH, INTERF, FILTINTERF, RESINTERF, UNWPHASE
					# FILESTOGEOC=`echo "YES YES YES YES NO YES YES YES"`
					ManageGeocoded

				# Clean slave.interpolated if S1
				if [ ${SATDIR} == "S1" ] ; then 
					SUBD=`echo ${RUNDIR}/i12/InSARProducts/S1*.interpolated.csl`
					if [ ! -L ${SUBD} ]
						then 	
							EchoTee "Clean ${SUBD}/Data and /Headers"
							rm -Rf ${SUBD}/Data
							rm -Rf ${SUBD}/Headers
						else
							EchoTee "Keep ${SUBD}/Data and /Headers becaus it is only a link"
					fi 
				fi
		fi # end of if [ pair to process does not exist ]		
	
		# See line 819 "may be a problem later ? "; one must now get back to proper naming
		if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" != "WIDESWATH" ] && [ "${SUPERMASNAMEBAK}" != "" ] 
			then 
				SUPERMASNAME=${SUPERMASNAMEBAK}  # For not being a problem later  
				SUPERMASNAMEBAK=""
		fi
						
		cd ${MAINRUNDIR}
	
		# copy/move processed pair in background
	
		if [ "${execdir}" == "${storedir}" ]
			then 
				EchoTee ""
				EchoTee ""
				EchoTee "Same physical disk; Everything will be moved to ${MASSPROCESSPATHLONG} after the processing of all the pairs..."
				# Do not move now because (at least for images other than S1 WS) may need info from pairs with same master already processed here
				#EchoTee "Associated text files and logs will be moved later"
				#mv -f ${RUNDIR} ${MASSPROCESSPATHLONG} &
			else 
				EchoTee ""
				EchoTee ""
				EchoTee "Not the same physical disk; Start copying now ${RUNDIR} in background to ${MASSPROCESSPATHLONG}."
				EchoTee "Comparison will be performed with diff at the end to ensure that everything was copied before removing from processing disk."
				cp -R ${RUNDIR} ${MASSPROCESSPATHLONG} &
				EchoTee "Associated text files and logs will be copied later"	
				EchoTee ""
				EchoTee ""
		fi
	
		RUNDIR=${MAINRUNDIR}
	fi # end of skip empty pair
done

# wait for last pair to be copied
wait

EchoTee "--------------------------------------------------------"
EchoTee "Dump script in ${LOGFILE} for debugging " 
EchoTee "--------------------------------------------------------" 
cat $(dirname $0)/${PRG} >> ${LOGFILE}
EchoTee " " 

EchoTee "--------------------------------------------------------"
EchoTee "Dump Functions related to script in ${LOGFILE} for debugging " 
EchoTee "--------------------------------------------------------" 
cat ${FCTFILE} >> ${LOGFILE}
EchoTee " " 	

EchoTee "--------------------------------------------------------"
EchoTee "Dump list of pairs etc... in ${LOGFILE} for debugging " 
EchoTee "--------------------------------------------------------" 

if [ -f "${MASSPROCESSPATHLONG}/ExistingPairs_${RUNDATE}_${RNDM1}.txt" ] && [ -s "${MASSPROCESSPATHLONG}/ExistingPairs_${RUNDATE}_${RNDM1}.txt" ]
  then
	EchoTee "Dump ExistingPairs_${RUNDATE}_${RNDM1}.txt\n"
	cat ${MASSPROCESSPATHLONG}/ExistingPairs_${RUNDATE}_${RNDM1}.txt >> ${LOGFILE}
	rm -f ${MASSPROCESSPATHLONG}/ExistingPairs_${RUNDATE}_${RNDM1}.txt
	EchoTee "--------------------------------------------------------" 
fi

EchoTee "Dump PairsToProcess_${RUNDATE}_${RNDM1}.txt\n"
cat ${MASSPROCESSPATHLONG}/PairsToProcess_${RUNDATE}_${RNDM1}.txt >> ${LOGFILE}
rm -f ${MASSPROCESSPATHLONG}/PairsToProcess_${RUNDATE}_${RNDM1}.txt
EchoTee "--------------------------------------------------------" 

# No need to give path here because it is in the PAIRFILE param.
rm -f ${PAIRFILE}_NoBaselines_${RNDM1}.txt

# move results to ${MASSPROCESSPATHLONG}
# Instead of moving that is impossible beacause of permissions between different OS
#     one cp then check if similar. 
# Ignore Geocoded and GeocodedRasters as well as PairsToProcess_${RUNDATE}_${RNDM1}.txt
#     that are only in target dir (MASSPROCESSPATHLONG) and all the links to 
#     interpolated.mod files     
#######################################################
EchoTee ""
EchoTee "--------------------------------------------------------"
EchoTee "Copying results to ${MASSPROCESSPATHLONG}" 
## If 4 1st dir of PROROOTPATH is the same as 4 1st dir of MASSPROCESSPATH, then mv, else cp and check
#execdir=`RemDoubleSlash  ${PROROOTPATH}`
#storedir=`RemDoubleSlash  ${MASSPROCESSPATH}`
#execdir=`echo ${execdir} | cut -d / -f 3`
#storedir=`echo ${storedir} | cut -d / -f 3`
#
#tmp2=`RemDoubleSlash  ${MASSPROCESSPATHLONG}`
#MASSPROCESSPATHLONG=`echo ${tmp2}`

EchoTee " Processing was done on ${execdir} and results must be store in ${storedir}"
if [ "${execdir}" == "${storedir}" ]
	then 
		EchoTee "Same physical disk; Move all processed Pair directories and text (log) files to ${MASSPROCESSPATHLONG}."
		mv -f ${MAINRUNDIR}/* ${MASSPROCESSPATHLONG}	
		# From now on, log file is in ${MASSPROCESSPATHLONG}
		LOGFILE=${MASSPROCESSPATHLONG}/LogFile_MassProcess_Super${MAS}_${RUNDATE}_${RNDM1}.txt
	else 
		EchoTee "Not the same physical disk; Processed Pair directories were copied in background to ${MASSPROCESSPATHLONG}."
		EchoTee "Now move associated text files and logs"
		cp -R ${MAINRUNDIR}/* ${MASSPROCESSPATHLONG}
 		# not faster than cp ?
 		#rsync -a --inplace -W --no-compress ${MAINRUNDIR} ${MASSPROCESSPATHLONG}
		# up to 20% faster than conventionnal rsync but might be limited to 100 characters long file names 
 		#tar cf - *  | (cd ${MASSPROCESSPATHLONG} ; tar xf -)

		# From now on, log file is in ${MASSPROCESSPATHLONG}
		LOGFILE=${MASSPROCESSPATHLONG}/LogFile_MassProcess_Super${MAS}_${RUNDATE}_${RNDM1}.txt

		EchoTee "Compare now with diff to ensure that everything was copied before removing from processing disk."

		diff -r -q ${MAINRUNDIR} ${MASSPROCESSPATHLONG} | ${PATHGNU}/grep "Only in ${MAINRUNDIR}" > ${MASSPROCESSPATHLONG}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt
		cat ${MASSPROCESSPATHLONG}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt | ${PATHGNU}/grep -v Geocoded | ${PATHGNU}/grep -v PairsToProcess_${RUNDATE}_${RNDM1}.txt > ${MASSPROCESSPATHLONG}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt

		echo ""
		echo "Ignore messages diff about interpolated.mod wich appears because of links. " 
		echo ""

		if [ -f "${MASSPROCESSPATHLONG}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt" ] && [ -s "${MASSPROCESSPATHLONG}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt" ]
			then 
				EchoTee "Not everything was copied - Do not remove from source dir ${MAINRUNDIR}. Check yourself !!" 
				EchoTee "Attempt a rsync in the mean time"
				rsync -av ${MAINRUNDIR}/ ${MASSPROCESSPATHLONG}

			else 
				EchoTee "Everything was copied to ${MASSPROCESSPATHLONG}."
				# Do not remove until prblm of communication with hp disks is solved...

				if [ `echo ${PROROOTPATH} | ${PATHGNU}/grep $HOME | wc -l` - gt 0 ] 
					then 
						# Processing was not performed in HOME dir, hence check that the disk where it was processed is still mounted before attempting removing files				
						
						# remove double slash
						PROROOTPATHSINGLESLASH=`RemDoubleSlash  ${PROROOTPATH}`
						HD=`echo ${PROROOTPATHSINGLESLASH} | cut -d "/" -f 3`
						EchoTee "Remove from source dir (${MAINRUNDIR}) if ${HD} is connected" 
				
						# Some warnings or hints... 	
						echo		
						echo "If using Remote Desktop, ignore possible message about thinclinet_drives."
						echo "If scripts hangs over forever when run on Linux, check that df is not causing it (just run it at a Terminal). If so, reboot..."
						
						if [ `df | ${PATHGNU}/grep ${HD} | wc -l` -lt 1 ] 
							then 
								echo "Disk seems to be disconnected - DO NOT REMOVE PROCESSED PAIR DIRS"
							else 
								echo "Disk seems ok - REMOVE PROCESSED PAIR DIRS"
								rm -r ${MAINRUNDIR}/*
								rm -f ${MASSPROCESSPATHLONG}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt
						fi
					else 
						echo "REMOVE PROCESSED PAIR DIRS"
						rm -r ${MAINRUNDIR}/*
						rm -f ${MASSPROCESSPATHLONG}/Check_MoveFromRundir_${RUNDATE}_${RNDM1}.txt
				fi
				echo
		fi	
fi

if [ "${SATDIR}" == "S1" ] ; then rm -f ${FLAGUSAGE} ; fi

# remove old logs > OLDNESS=30 days
cd ${MASSPROCESSPATHLONG}
OLDNESS=30
find . -maxdepth 1 -name "LogFile*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "LaunchMTparam_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "ExistingPairs_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "PairsToProcess_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "Check_MoveFromRundir_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;


# Search for duplicate files... just in case
	cd ${MASSPROCESSPATHLONG}/Geocoded
	EchoTee "Serching for all files containing pair of dates (yyyymmdd_yyyymmdd) and ending with deg... " 
	find . -maxdepth 1 -type f -name "*deg" > List_Files_Serached_For_Ducplic.txt
	EchoTee ""

	EchoTee "Extracting only dates (yyyymmdd_yyyymmdd)...  May take some time !" 
	rm -f List_Pairs_Serached_For_Ducplic.txt
	for IMGTOTEST in `cat List_Files_Serached_For_Ducplic.txt`
	do 
		echo "${IMGTOTEST}" | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}" >> List_Pairs_Serached_For_Ducplic.txt
	done 
	
	if [ -f List_Pairs_Serached_For_Ducplic.txt ] && [ -s List_Pairs_Serached_For_Ducplic.txt ] ; then 
		# show how many times each line is present in file
		#sort List_Pairs_Serached_For_Ducplic.txt | uniq -c
		EchoTee ""
		# count how many duplicated lines 
		NRDUPLIC=`sort List_Pairs_Serached_For_Ducplic.txt | uniq -cd | wc -l`

		# count how many lines in total 
		TOT=`cat List_Pairs_Serached_For_Ducplic.txt | wc -l`

		if [ ${NRDUPLIC} -gt 0 ] 
			then 
				EchoTee "Directory $pwd contains ${TOT} files, among which ${NRDUPLIC} are duplicated pairs. "
				EchoTee "See list below (nr_occurrence   date_date):"
				# show only duplicates lines 
				sort List_Pairs_Serached_For_Ducplic.txt | uniq -cd > Duplicated_Files.txt
				EchoTee "Corresponding files are: "
		
				for DATES in `sort List_Pairs_Serached_For_Ducplic.txt | uniq -d`
				#while read -r NR DATES
					do 
						${PATHGNU}/find . -maxdepth 1 -type f -name "*${DATES}*deg" -printf "%T@ %Tc %p\n" | sort -n
						EchoTee "Search for the oldest: " 
						OLDEST=`${PATHGNU}/find . -maxdepth 1 -type f -name "*${DATES}*deg" -printf "%T@ %Tc %p\n" | sort -n | head -1`
						OLDESTFILE=`echo "${OLDEST}" | cut -d "/" -f2`
						EchoTee " // ${OLDESTFILE} and its hdr:"
						EchoTee ${OLDESTFILE}
						EchoTee ${OLDESTFILE}.hdr
						EchoTee " // And probably in GeocodedRasters as well ?:"
						EchoTee ${MASSPROCESSPATHLONG}/GeocodedRasters/${OLDESTFILE}.ras
						#rm ${OLDESTFILE}
						#rm ${OLDESTFILE}.hdr

						EchoTee ""
				done
				#done < Duplicated_Files.txt

			else 
				EchoTee "Directory $pwd contains ${TOT} files, among which none are duplicated pairs. "
		fi
		echo ""
		rm -f List_Pairs_Serached_For_Ducplic.txt List_Files_Serached_For_Ducplic.txt # Duplicated_Files.txt
	fi
echo "All done - hope it worked." 
SpeakOut " Mass processing of satellite ${SATDIR}, mode ${TRKDIR} is finished. Enjoy mass processing."

# done
