#!/bin/bash
######################################################################################
# This script aims at removing atmospheric delay screens to all pairs in 
# SAR_MASSPROCESS and Re-Geocode the deformation maps. It will proceed for all 
# pairs for which there is an atmo delay screen in the directory provided in LaunchParam.txt. 
#
# These delay screens (e.g. computed with MANGO toolbox) are in a provide dir in the form 
# of envi Harris .r4 files + their .hdr file (in Lat Long). The MUST be named like
#  YYYYMMDD_YYYYMMDD_ATMOCORR_*.r4 where YYYYMMDD are the date of Primary and Secondary images 
#  in the same order as in the SAR_MASSPROCESS directory (cfr ${MASSPROCESSPATH}) and ATMOCORR 
#  is the name of the atmospheric correction  (e.g. MangoGIPSY, MangoGAMIT,...). 
# Note that these atmo delay screens are supposed to be removed from the deformation maps, hence 
# THEY MUST BE PROVIDED IN METERS AND WITH THE RIGHT SIGN (e.g. if PRIMARY is after 
# Secondary date, the atmo correction must have been multiplied by -1).
#
# It will read in the provided LaunchParam.txt file (parameter 1) if the satellite is  
# S1 in WIDESWATH mode without Super Master (i.e. Global Primary) or not. 
# 	If S1 WIDESWATH mode without Super Master, it will project each atmo screen in
#	  SAR_CSL/.../MAS dir (the path to SAR_CSL is found in the LaunchParam.txt).
# 	  This is performed using Proj_AllFiles_in_SltRg.sh as much time as there are MAS. 
# 	  Note that it checks first if some atmo delay screens are already projected and skip their 
#	  re-projection, unless the last param is ForceReporj. 
#	  All reprojected files are stored in MAS/Data/slantRangeFiles to avoid setting them 
#     all the the size of MAS in i12/InSARProducts when performing InSARProductsGeneration -r
# 	If not, it will project all atmo screens in SAR_CSL/.../SUPERMAS dir.
# 	  This is performed using Proj_AllFiles_in_SltRg.sh only once. 
# 	  Note that it checks first if some atmo screens are already projected and skip their 
#	  re-projection, unless the last param is ForceReporj. 
#	  All reprojected files are stored in MAS/Data/slantRangeFiles to avoid setting them 
#     all the the size of MAS in i12/InSARProducts when performing InSARProductsGeneration -r
#
# Atmo delay screens are stored (in envi Harris .r4 + hdr files formal in Lat Long) in a dir 
#   provided as parameter in LaunchParam.txt file. 
#   Values are in meters ! 
#
# The script will then create a temporary symbolic link from the atmo screen in SAR_CSL/../MAS. 
# In the SAR_MASSPRCESS/...pair.../i12 directory, it will crop the atmo screen at the same 
#	size as all the InSARProducts using the command InSARProductsGeneration -r
# Then it removes the links to the atmo screen from the deformation map in SAR_CSL/../MAS.
#
# Finally, it will perform the re-geocoding (and detrending if requested in the 
#	  LaunchParam.txt file) using Detrend_Geoc_CorrectedAtmo.sh script. 
#	  It will add a comment for renaming the re-geocoded atmo-corrected files based on
#	  parameters read in the LaunchParam.txt:   
#				- ReGeocoded (if re-geocoded with new parameters). 
#					Re-geocoding is done anyway.
#				- ReDetrend (if re-detrended e.g. to test new filter at detrending to mask deformation). 
#					Removing a best plane is done by selecting DETREND as REMOVEPLANE parameter in LaunchParameters.txt  
#				- MangoGAMIT, (if corrected with the GNSS based correction Mango Toolbox based on ZTD extracted with GAMIT, Albino et al. 2025).  
#					Removing atmospheric correction based on GAMIT GNSS ZTD data is done by selecting MangoGAMIT as ATMOCORR parameter in LaunchParameters.txt
#				- MangoGIPSY, (if corrected with the GNSS based correction Mango Toolbox based on ZTD extracted with GIPSY, Albino et al. 2025) 
#				- MangoBERNESE, (if corrected with the GNSS based correction Mango Toolbox based on ZTD extracted with BERNESE, Albino et al. 2025) 
#				- GACOS (if corrected with ECMWG+GNSS model based correction, Yu et al. 2018)
# 				- GACOSIncidMapMEAN 		:  
#				- GACOSIncidMapMEDIAN 		:	also GACOS though specify in the name 
#				- GACOSIncidMapNoRef 		:		- which incidence angle you used: from a map or a fixed single value, and
#				- GACOSIncidFixMEAN 		:		- which type of reference used (mean or median no whole map or no ref) 
#				- GACOSIncidFixMEDIAN 		:	These GACOS names are arbitrary chosen. Feel free to define others for your needs. 
#				- GACOSIncidFixNoRef		:	Remember, these names must however be in the atmo screen name after the dates.
#				See in __HardCodedLines.sh in ReadArrayAtmoModels for all modes pre-defined
#
# Parameters : 	- Parameters file with new paramaters for reprocessing (a least LaunchMTparam.txt version >= 20260811) 
#				- [optional]: ForceReproj: if last parameter is ForceReproj, it will reproject each
#				- [optional]: List of pairs to process (in the form of YYYYMMDD_YYYYMMDD) passed to the script as -pairs=Path/ToYour/ListOfPairs.txt
#
# Hard coded:	- List of recognized atmospheric corrections. See AtmoCorrList
#
# Dependencies:	- Proj_AllFiles_in_SltRg.sh
#				- Detrend_Geoc_CorrectedAtmo.sh
#				- RenamePath_Volumes.sh
#
# WARNING: run a test before operate on full scale to bee sure that the naming and renaming fits your needs. 
#
#
# New in Distro V 1.0 20260529:	- setup
# New in Distro V 1.1 20260618:	- exit as soon as a command or a script launched from here exit with non 0, that is with an error
#								- revise exit status: set to exit 1 everywhere i.e. exit with error (exit 0 would be exit with success)
# New in Distro V 1.2 20260626:	- check defor mode dir /Geocoded/Defo_UnselectedVersions etc... instead of /Geocoded/Defo_original_before_"${COMMENT}
#								  in order to cope with several atmo corr if any and serach by type of correction already applied. 
# New in Distro V 1.3 20260806:	- Add comparison with former results and keep only the best one in DefoModei
#								- Add option for forcing processing only a list of pairs 
#								- set the list of recognized atmospheric corrections in an array AtmoCorrList
# New in Distro V 1.4 20260810:	- complete the branches without Global Primary (SuperMaster):
#								  the four projection cases (with/without Global Primary, with/without
#								  ForceReproj) are now one single function ProjectScreensInSltRg
#								- force INPUTDATA to NoCrop for S1 IW/EW, as Proj_AllFiles_in_SltRg.sh does
#								- guard every mv on a possibly empty glob (would abort the run, set -e)
#								- restore the screens and clean TEMP_PROCESS even when the projection fails
#								- honour -pairs also with ForceReproj
#								- report the screens to project for every Primary date, not only the last one
#								- search all the /Geocoded/Defo* modes to know which pairs are already corrected
# New in Distro V 1.5 20260811:	- take path to atmo screens as param in LaunchParam.txt 
#								- check that atmospheric delay screens are named date_date_AtmoCorr_*.r4 and .hdr
#								- add test for S1MODE
# New in Distro V 1.6 20260813:	- Source the array with the list of recognised atmospheric correction models from __HardCodedLines.sh
# New in Distro V 1.7 20260817:	- the list of the pairs already corrected with ${ATMOCORR} was built with an 
#								  unanchored *"${ATMOCORR}"* glob. As AtmoCorrList holds tags of which another 
#								  one is a prefix (GACOS, GACOSIncidMapMEAN, GACOSIncidMapMEDIAN...), a pair 
#								  corrected with GACOSIncidMapMEDIAN was seen as already corrected with GACOS 
#								  and was hence never corrected with GACOS. The tag is now matched as a whole 
#								  token, i.e. *_${ATMOCORR}.*deg
#								- drop the spurious leading / in the output path of the two ffa calls 
#								  (harmless, but it was printing ///Volumes/... in the logs) 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/10 -						 
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.7 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 17, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# Optional -pairs FILE : restrict processing to the pairs (YYYYMMDD_YYYYMMDD, one per
# line; full screen/interfero paths accepted, the pair is extracted) listed in FILE.
# Parsed out first so the positional args below keep their historical meaning.
ONLYPAIRS=""
_args=()
while [ $# -gt 0 ]; do
	case "$1" in
		-pairs=*) ONLYPAIRS="${1#*=}"; shift 
		ECHOCMD="pairs=${ONLYPAIRS}"
		;;
		*)        _args+=("$1");       shift ;;
	esac
done
set -- "${_args[@]}"		# Reset input parameters numbering 

PARAMFILE=$1				# File with the parameters needed for the run
FORCE=$2					# Optional: if parameter is ForceReproj, it will force reprojecting each atmo screen and re-perform correction and geocoding  

# vvvvvvvvvvvvvv Hard coded vvvvvvvvvvv
# List of atmo corrections
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below
	# ReadArrayAtmoModels for AtmoCorrList=(MangoGAMIT MangoGIPSY MangoBERNESE GACOS...)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

echo "Command Launched: ${PRG} ${PARAMFILE} ${FORCE} ${ECHOCMD}"

if [ $# -lt 1 ] ; then echo " Usage $0 PARAMETER_FILE [ForceReproj] [-pairs=ListOfPairs.txt]"; exit 1; fi


# Read parameters file as from SuperMaster_MassProc.sh - may read too much parameters but it is safe...
######################	
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
	DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored (SAR_CSL)
	FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored
	
	DEMDIR=`GetParam DEMDIR`					# DEMDIR, path to dir where DEM is stored
	RECOMPDEM=`GetParam "RECOMPDEM,"`			# RECOMPDEM, recompute DEM even if already there (FORCE), or trust the one that would exist (KEEP)
	SIMAMP=`GetParam "SIMAMP,"`					# SIMAMP, (SIMAMPno or SIMAMPyes). Option to compute simulated amplitude during Extenral DEM generation - usually not needed.
	
	POP=`GetParam "POP,"`						# POP, option to pop up figs or not (POPno or POPyes)
	FIG=`GetParam "FIG,"`						# FIG, option to compute or not the quick look using cpxfiddle (FIGno or FIGyes)
	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	
	S1COREGMODE=`GetParam S1COREGMODE`			# S1COREGMODE, For S1 only: either S1SM (for coregistering all the S1 on a given Super Master),
													# or S1ORBIT (or anything else than S1SM) to skip coreg and rely only on the S1 orbits. 

	SUPERMASTER=`GetParam SUPERMASTER`			# SUPERMASTER, date of the Global Primary (SuperMaster) as selected by Prepa_MSBAS.sh in
												# e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/seti/setParametersFile.txt

	CROP=`GetParam "CROP,"`						# CROP, CROPyes or CROPno 
	FIRSTL=`GetParam "FIRSTL,"`					# Crop limits: first line to use
	LASTL=`GetParam "LASTL,"`					# Crop limits: last line to use
	FIRSTP=`GetParam "FIRSTP,"`					# Crop limits: first point (row) to use
	LASTP=`GetParam "LASTP,"`					# Crop limits: last point (row) to use
	COORDSYST=`GetParam "COORDSYST,"`			# COORDSYST, type of coordinates used to define crop: SRA (lines and pixels) or GEO
	
		if [ "${CROP}" == "CROPyes" ] && [ "${COORDSYST}" == "" ]
			then 
				echo " COORDSYST not defined. I try to see if there is a dot in your coordinates for crop region. "
				if [[ "${FIRSTL}${LASTL}${FIRSTP}${LASTP}" == *.* ]] 
					then
						echo "At least one of the crop coordinates has a dot. Must hence be GEO coord system"
						COORDSYST="GEO"
					else
						echo "None of the crop coordinates has a dot. Must hence be SRA coord system"
						COORDSYST="SRA"
				fi
		fi
	
	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	
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

	ATMOCORR=`GetParam "ATMOCORR,"`				# ATMOCORR, to apply an atmospheric correction. 
	PATHATMOSCREENS=`GetParam "PATHATMOSCREENS,"`	#  PATHATMOSCREENS, path to dir containing all the atmospheric screens (in m) for atmospheric corrections 

	
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
	GEOCKML=`GetParam "GEOCKML,"`				# GEOCKML, a kml file to define final geocoded product. If not found, it will use the coordinates above

	ETADPROD=`GetParam "ETADPROD,"`				# ETADPROD, only for S1: use of ETAD products at InSARProductsGeneration: ETADno (no ETAD correction) or ETADxyz, where x, y and z are Iono, Geo and Tropo correction respectively and take values 0 (not used) or 1 (used)
	ETADCOMBI=`GetParam "ETADCOMBI,"`			# ETADCOMBI, only for S1 (ETADCOMBIyes or ETADCOMBIno): if yes, and if ETADPROD is with two or more 1, it will compute all the combinations of corrections in addition to the resquested one 
	ETADGEOC=`GetParam "ETADGEOC,"`				# ETADGEOC, only sor S1: Use of ETAD products to improve geocoding (ETADGEOCyes, or ETADGEOCno)

	
	DEMNAME=`GetParam "DEMNAME,"`				# DEMNAME, name of DEM inverted by lines and columns
	
	RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data will be stored 

	MASSPROCESSPATH=`GetParam MASSPROCESSPATH`	# MASSPROCESSPATH, path to dir where all processed pairs will be stored in sub dir named by the sat/trk name (SATDIR/TRKDIR)
	RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data are stored 
	
	eval PROPATH=${PROROOTPATH}/${SATDIR}
	
	source ${FCTFILE}

#  Define AtmoCorrList=(MangoGAMIT MangoGIPSY MangoBERNESE GACOS...) from __HardCodedLines.sh
ReadArrayAtmoModels

# Force the present script to stop if any of the scripts launched from here exit with non zero exit code, that is with an error
###############################################################################################################################
set -e
# Now any command that returns non-zero exits this script immediately

# Some functions 
################

function ResizeAndAtmoCorrAndRegeoc()
	{
	unset LIST_TO_PROCESS
	unset PROJGEOM
	local LIST_TO_PROCESS=$1 # list of atmo screens 
	local PROJGEOM=$2 		 # if PROJ_ON_SM, will project on Super Master. If not (eg PROJ_ON_SM), it will project on Master
	local PROJ

		# perform resizing and atmo correction 
		if [ -f "${LIST_TO_PROCESS}" ] && [ -s "${LIST_TO_PROCESS}" ]
			then 
				while IFS= read -r ATMOSCREEN; do
 					MAS="${ATMOSCREEN%%_*}"
    				SLV="${ATMOSCREEN#*_}"; SLV="${SLV%%_*}"
    				
					#MASNAME=$(ls -d "${INPUTDATA}/"*"${MAS}"* 2>/dev/null | head -1 | xargs basename 2>/dev/null) 
					#SLVNAME=$(ls -d "${INPUTDATA}/"*"${SLV}"* 2>/dev/null | head -1 | xargs basename 2>/dev/null) 
					# faster ? 
					f=("${INPUTDATA}/"*"${MAS}"*/)
					if [[ -d "${f[0]}" ]]; then
					    MASDIR=$(basename "${f[0]}")
					    MASNAME="${MASDIR%.*}"
					fi
					
					f=("${INPUTDATA}/"*"${SLV}"*/)
					if [[ -d "${f[0]}" ]]; then
					    SLVDIR=$(basename "${f[0]}")
					    SLVNAME="${SLVDIR%.*}"
					fi								

					if [ "${PROJGEOM}" == "PROJ_ON_SM" ] 
						then 
							PROJ="${SUPERMASDIR}"  
							MSG="(in Global Primary geometry)"
							MSG2="(in Global Primary geometry)"
						else 
							PROJ="${MASDIR}" 
							MSG="(in ${MAS} Primary geometry)"	
							MSG2="(in Primary geometry)"						
					fi


					EchoTee " Resize slant range atmoshperic screens to interferometric products pairs ${MASNAME}_${SLVNAME} ${MSG}..."
					EchoTee "-----------------------------------------------------------------------------------------------------------------------------"
					EchoTee ""
					
					ln -s "${INPUTDATA}/${PROJ}/Data/slantRangeFiles/${ATMOSCREEN}.slantRange" "${INPUTDATA}/${PROJ}/Data"
					# set it at same size as all InSARProducts
						# need this definition here for usage in GetParamFromFile
						RUNDIR="${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}"
					# skip pairs that have an atmo screen but were never mass-processed
					# (a failed cd would leave the loop running in the wrong directory)
					if [ ! -d "${RUNDIR}/i12" ]
						then
							EchoTee "  => Pair ${MASNAME}_${SLVNAME} not found in ${MASSPROCESSPATHLONG} - SKIPPED (screen not applied)"
							EchoTee ""
							echo "${MAS}_${SLV}" >> "${MASSPROCESSPATHLONG}/List_Pairs_MissingInMassProcess_${RUNDATE}_${RNDM1}.txt"
							rm -f "${INPUTDATA}/${PROJ}/Data/${ATMOSCREEN}.slantRange"
							continue
					fi
					cd ${RUNDIR}/i12
					# MUST CHECK PATH TO MAS, SLV AND " Global master to master InSAR processing " IN InSARParameters.txt !! 
					RenamePath_Volumes.sh ${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}

					InSARProductsGeneration -r
					rm -f "${INPUTDATA}/${PROJ}/Data/${ATMOSCREEN}.slantRange"	
					
					# substract from defo map and defo map.interpolated
					EchoTee ""
					EchoTee " Substract atmo screen ${MSG} from defo in pair ${MASNAME}_${SLVNAME}"
					EchoTee "-----------------------------------------------------------------------------------------"
					
					ffa "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/deformationMap" - "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/${ATMOSCREEN}.slantRange" "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/deformationMap_${ATMOCORR}"		
					
					DEFORG=`GetParamFromFile "Deformation measurement range dimension" InSARParameters.txt`
					MakeFig ${DEFORG} 1.0 1.2 normal jet 1/1 r4 "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/deformationMap_${ATMOCORR}"		
					MakeFig ${DEFORG} 1.0 1.2 normal jet 1/1 r4 "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/${ATMOSCREEN}.slantRange"		
					
					if [ -f "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/deformationMap.interpolated" ] ; then 
						EchoTee " Substract atmo screen from defo interpolated in pair ${MASNAME}_${SLVNAME}"
						ffa "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/deformationMap.interpolated" - "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/${ATMOSCREEN}.slantRange" "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/deformationMap.interpolated_${ATMOCORR}"		
						MakeFig ${DEFORG} 1.0 1.2 normal jet 1/1 r4 "${MASSPROCESSPATHLONG}/${MASNAME}_${SLVNAME}/i12/InSARProducts/deformationMap.interpolated_${ATMOCORR}"		
					fi
		
					# Update list of pairs to regeocode in the form of YYYYMMDD_YYYYMMDD
					echo "${MAS}_${SLV}" >> "${MASSPROCESSPATHLONG}/List_Pairs_ToRegeoc_${RUNDATE}_${RNDM1}.txt"
					EchoTee ""
					
				done < "${LIST_TO_PROCESS}"

			else 
				EchoTee "No slant range atmoshperic screens to resize into interferometric products pairs ${MSG2}..."
				EchoTee ""
		fi

		# Re-detrend (if requested) and ReGeocode the corrected maps (and re-interpolate the re-geocoded files if requested) 
		if [ -f "${MASSPROCESSPATHLONG}/List_Pairs_ToRegeoc_${RUNDATE}_${RNDM1}.txt" ] && [ -s "${MASSPROCESSPATHLONG}/List_Pairs_ToRegeoc_${RUNDATE}_${RNDM1}.txt" ] 
			then
				EchoTee "************************************** ${PRG} *********************************************************************************"
				EchoTee "Re-detrend (if requested) and ReGeocode atmo-corrected maps (and re-interpolate the re-geocoded files if requested) ${MSG2}"
				EchoTee "**********************************************************************************************************************************************"
				EchoTee ""

				Detrend_Geoc_CorrectedAtmo.sh "${MASSPROCESSPATHLONG}/List_Pairs_ToRegeoc_${RUNDATE}_${RNDM1}.txt" "${PARAMFILE}" "${COMMENT}"
			else
				EchoTee "Nothing to re-detrend / ReGeocode atmo-corrected maps / re-interpolate ${MSG2}"
		fi
}

# returns 0 if $1 is in the remaining arguments
function IsInList() 
{
	_needle="$1" ; shift
	for _item in "$@" ; do
		[ "$_item" = "${_needle}" ] && return 0
	done
	return 1
}

# Return the name of the .csl dir of a given date (or S1 name) in ${INPUTDATA}
function GetCslDirForDate()
	{
	unset DATEORNAME
	local DATEORNAME="$1"
	local D
	for D in "${INPUTDATA}/"*"${DATEORNAME}"*/ ; do
		[ -d "${D}" ] || continue
		basename "${D}"
		return 0
	done
	return 1
	}

# Move the freshly projected screens from <img>.csl/Data to <img>.csl/Data/slantRangeFiles,
# so that InSARProductsGeneration -r does not resize them all at the size of the Primary.
function StoreSlantRangeFiles()
	{
	unset CSLDIR
	local CSLDIR="$1"
	local NB

	if [ -z "${CSLDIR}" ] || [ ! -d "${INPUTDATA}/${CSLDIR}/Data" ] ; then
		EchoTeeRed "  => No ${INPUTDATA}/${CSLDIR}/Data dir; can't store the projected screens."
		return 1
	fi
	mkdir -p "${INPUTDATA}/${CSLDIR}/Data/slantRangeFiles"
	# remove temporary symlinks possibly left in Data/ by a previous run (would make mv fail with "identical")
	${PATHGNU}/find "${INPUTDATA}/${CSLDIR}/Data/" -maxdepth 1 -name "*.slantRange" -type l -exec rm -f {} \;
	# count first: mv on an unmatched glob returns non zero, which would abort the whole script (set -e)
	NB=$(${PATHGNU}/find "${INPUTDATA}/${CSLDIR}/Data/" -maxdepth 1 -name "*.slantRange" -type f | wc -l)
	if [ "${NB}" -eq 0 ] ; then
		EchoTeeRed "  => No *.slantRange produced in ${INPUTDATA}/${CSLDIR}/Data. Check the Proj_AllFiles_in_SltRg.sh log."
		return 1
	fi
	${PATHGNU}/find "${INPUTDATA}/${CSLDIR}/Data/" -maxdepth 1 -name "*.slantRange" -type f \
		-exec mv -f {} "${INPUTDATA}/${CSLDIR}/Data/slantRangeFiles/" \;
	EchoTee "  => ${NB} projected screen(s) stored in ${CSLDIR}/Data/slantRangeFiles"
	return 0
	}

# Project a set of atmo screens in the slant range geometry of one image.
#	$1 : date (or S1 name) of the image to project on, e.g. ${SUPERMASTER} or a Primary date
#	$2 : file listing the screens to project (file names with their extension, one per line)
# Returns 0 if there was nothing to project (not an error), 1 if the projection or the
# storage failed, so that the caller can skip that date instead of aborting the whole run.
function ProjectScreensInSltRg()
	{
	unset PROJONIMG LISTSCREENS
	local PROJONIMG="$1"
	local LISTSCREENS="$2"
	local TMPPROC="${PATHATMOSCREENS}/TEMP_PROCESS"
	local STRING TOMOVE CSLDIR NB RC

	if [ ! -s "${LISTSCREENS}" ] ; then
		EchoTee "  => No new atmospheric screen to project on ${PROJONIMG}."
		return 0
	fi

	# TEMP_PROCESS must be empty: leftovers of an interrupted run would be projected
	# on ${PROJONIMG} as well, silently corrupting the screens of another date
	mkdir -p "${TMPPROC}"
	if [ -n "$(ls -A "${TMPPROC}" 2>/dev/null)" ] ; then
		EchoTeeRed "  => ${TMPPROC} is not empty (interrupted former run ?); moving its content back first."
		mv -f "${TMPPROC}"/* "${PATHATMOSCREENS}"/
	fi

	# move the screens to project, and their .hdr, in TEMP_PROCESS
	while IFS= read -r STRING; do
		[ -n "${STRING}" ] || continue
		TOMOVE="${STRING%.*}"		# name without its extension, to move both .r4 and .hdr.
									# %.* and not %%.* : a screen name may contain a dot
									# (e.g. ..._0.5.r4), which %%.* would truncate
		if [ -f "${PATHATMOSCREENS}/${STRING}" ] ; then
			mv -f "${PATHATMOSCREENS}/${TOMOVE}".* "${TMPPROC}"/
		else
			EchoTeeRed "  => ${STRING} listed but not found in ${PATHATMOSCREENS}; ignored."
		fi
	done < "${LISTSCREENS}"

	NB=$(ls -1 "${TMPPROC}"/*.r4 2>/dev/null | wc -l)
	if [ "${NB}" -eq 0 ] ; then
		EchoTee "  => No screen actually available to project on ${PROJONIMG}."
		rmdir "${TMPPROC}" 2>/dev/null
		return 0
	fi
	EchoTee "  => ${NB} screen(s) to project on ${PROJONIMG}"

	# Do not let a failure here abort the caller before the screens are moved back
	RC=0
	Proj_AllFiles_in_SltRg.sh "${PROJONIMG}" "${PARAMFILE}" "${TMPPROC}" || RC=$?

	# put the screens back where they came from, whatever happened
	if [ -n "$(ls -A "${TMPPROC}" 2>/dev/null)" ] ; then mv -f "${TMPPROC}"/* "${PATHATMOSCREENS}"/ ; fi
	rmdir "${TMPPROC}" 2>/dev/null

	if [ ${RC} -ne 0 ] ; then
		EchoTeeRed "  => Proj_AllFiles_in_SltRg.sh exited with ${RC} for ${PROJONIMG}."
		return 1
	fi

	# the projected files are in <img>.csl/Data ; store them in Data/slantRangeFiles
	CSLDIR=$(GetCslDirForDate "${PROJONIMG}") || CSLDIR=""
	StoreSlantRangeFiles "${CSLDIR}"
	}

# CheckAtmoCorrFiles <dir> <atmocorr>   -> 0 if both .r4 and .hdr present
	CheckAtmoCorrFiles()
	{
		local dir="$1" corr="$2" ext n
		local datepair="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
	
		for ext in r4 hdr ; do
			set -- "${dir}"/${datepair}_"${corr}"*."${ext}"
			[ -e "$1" ] && n=$# || n=0
			[ ${n} -eq 0 ] && { echo "no *.${ext} for ${corr} in ${dir}" >&2 ; return 1 ; }
		done
		return 0
	}


# Define CROPDIR, SMCROPDIR, MASSPROCESSPATHLONG and GEOCDIR
#################################################

	# Define Crop Dir
	if [ "${CROP}" == "CROPyes" ]
		then
			if [ "${ZOOM}" == "1" ] 
				then 
					CROPDIR="/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}" #_Zoom${ZOOM}_ML${INTERFML}
				else
					CROPDIR="/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}_Zoom${ZOOM}" #_ML${INTERFML}
			fi		
		else
			CROPDIR=/NoCrop
	fi
	

	# Define Super Master Crop Dir and place where original data are
	if [ "${CROP}" == "CROPyes" ]
		then
			SMCROPDIR="SMCrop_SM_${SUPERMASTER}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}"   #_Zoom${ZOOM}_ML${INTERFML}
		else
			SMCROPDIR="SMNoCrop_SM_${SUPERMASTER}"  #_Zoom${ZOOM}_ML${INTERFML}
	fi

	MASSPROCESSPATHLONG="${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}"
	GEOCDIR="${MASSPROCESSPATHLONG}/Geocoded"

	INPUTDATA="${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}"		# needed to get AZ and RG sampling for instance 


# Create log file
#################
	eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
	eval RNDM1=`echo $(( $RANDOM % 10000 ))`
	
	LOGFILE="${MASSPROCESSPATHLONG}/LogFile_ReDetrend_Geoc_${RUNDATE}_${RNDM1}.txt"


# Check atmospheric delay screens (dir and file naming and format)
##################################################################
	if [[ -d "${PATHATMOSCREENS}" && -n "$(ls -A "${PATHATMOSCREENS}" 2>/dev/null)" ]] 
		then 
			EchoTee " Directory containing the atmosheric delays ${PATHATMOSCREENS} exists and is not empty,"
			if CheckAtmoCorrFiles "${PATHATMOSCREENS}" "${ATMOCORR}" 
				then
					EchoTee "    and files are correctly named date_date_${ATMOCORR}*.r4 ; that is what I need."
				else
					EchoTee "    but files are not correctly named. It must be like date_date_${ATMOCORR}*.r4 ; I can't work. Exiting....."
					exit 1
			fi 
			#
		else 
			echo "Directory containing the atmosheric delays ${PATHATMOSCREENS} does not exist or is empty; I can't work. Exiting...."
			exit 1
	fi
	echo 




# Check SAR_MASSPROCESS/... dir and its /Geocoded subdir 
########################################################
	if [[ -d "${GEOCDIR}" && -n "$(ls -A "${GEOCDIR}" 2>/dev/null)" ]] 
		then 
			EchoTee " Directory ${GEOCDIR} exists and is not empty; that is what I need."
		else 
			echo "Directory ${GEOCDIR} does not exist or is empty; I can't work. Exiting....'"
			exit 1
	fi
	echo 

# updating COMMENT based on options from the LaunchParam.txt
############################################################
	COMMENT="ReGeocoded"
	
	if [ "${REMOVEPLANE}" == "DETREND" ] ; then COMMENT="${COMMENT}_ReDetrend" ; fi
	
	if ! IsInList "${ATMOCORR}" "${AtmoCorrList[@]}" ; then
		echo "Unknown type of modeling. Hope you know what you are doing. Files will be named with string ${COMMENT}_${ATMOCORR}"
	fi
	
	COMMENT="${COMMENT}_${ATMOCORR}"

# Check S1 mode and define SUPERMASNAME and SUPERMASDIR
#######################################################

	if [ "${SATDIR}" == "S1" ] 
		then  
			# need this definition here for usage in GetParamFromFile
			MASDIR=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${SUPERMASTER}` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
			S1ID=`GetParamFromFile "Scene ID" SAR_CSL_SLCImageInfo.txt`
			S1MODE=`echo ${S1ID} | cut -d _ -f 2`	
			
			if  [ "${S1MODE}" == "" ] ; then EchoTee "I can't figure out the S1MODE: IW, EW or SM ? Check path to global master ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/${SUPERMASTER}. ; exiting " ; exit  1 ; fi
			 
			if [ "${S1MODE}" == "IW" ] || [ "${S1MODE}" == "EW" ]
				then 
					if [ "${S1COREGMODE}" == "S1SM" ] 
						then 
							S1MODE="WSWATHSM"
 							USESM="Yes"
 							EchoTee "Process ${SATDIR} ${S1MODE} with Global Primary ${SUPERMASTER}"
						else
							S1MODE="WIDESWATH"
							USESM="No"
							EchoTee "Process ${SATDIR} ${S1MODE} without Global Primary ${SUPERMASTER}"
					fi
					# S1 IW/EW CSL data are stored in NoCrop: the crop is applied later, at the
					# interferometric processing stage. Proj_AllFiles_in_SltRg.sh forces
					# CROPDIR=/NoCrop for these modes, so INPUTDATA must point to the same place,
					# otherwise the screens are projected in one dir and searched for in another.
					if [ "${CROPDIR}" != "/NoCrop" ] ; then
						EchoTee "S1 ${S1MODE}: CSL data are in NoCrop; forcing INPUTDATA to NoCrop, as Proj_AllFiles_in_SltRg.sh does."
						CROPDIR="/NoCrop"
						INPUTDATA="${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}"
					fi
					SUPERMASNAME=`ls ${INPUTDATA} | ${PATHGNU}/grep ${SUPERMASTER} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
				else 
					S1MODE="STRIPMAP"
					SUPERMASNAME=`echo ${MASDIR} | cut -d. -f1`		
 					USESM="Yes"
 					EchoTee "Process ${SATDIR} ${S1MODE} with Global Primary ${SUPERMASTER}"
			fi
			EchoTee  "Processing S1 images in mode ${S1MODE}" 
 		else 
 			SUPERMASNAME="${SUPERMASTER}"
 			USESM="Yes"
 			EchoTee "Process ${SATDIR} with Global Primary ${SUPERMASTER}"
 	fi
 	if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]&& [ "${ZOOM}" != "1" ] ; then EchoTeeRed "Sentinel IW data processing only possible with zoom factor 1" ; exit 1 ; fi

	SUPERMASDIR="${SUPERMASNAME}.csl"



# Check list of atmospheric screens to process
############################################
	cd "${PATHATMOSCREENS}"
	
	EchoTee ""
	EchoTee "******************************* ${PRG}"
	EchoTee "Check list of atmospheric screens to process..."
	EchoTee "*********************************************"
	EchoTee ""
	
	# List all atmo screens
	ls *.r4 > "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt"		# each screen is named like 20141216_20150210_*.r4

	# Optional restriction to a given pair list (-pairs=ONLYPAIRS): keep only screens whose
	# pair YYYYMMDD_YYYYMMDD appears in ONLYPAIRS. Nothing else in the workflow changes.
	if [ -n "${ONLYPAIRS}" ] ; then
		${PATHGNU}/grep -oE '[0-9]{8}_[0-9]{8}' "${ONLYPAIRS}" | sort -u > "List_OnlyPairs_${RUNDATE}_${RNDM1}.txt"
		${PATHGNU}/grep -F -f "List_OnlyPairs_${RUNDATE}_${RNDM1}.txt" "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt" > "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt.tmp" || true
		mv "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt.tmp" "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt"
		EchoTee "Restriction -pairs : $(wc -l < "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt") masque(s) retenu(s) sur $(cat "List_OnlyPairs_${RUNDATE}_${RNDM1}.txt" | wc -l) paire(s) demandée(s)"
	fi

	# List all master dates - needed if not working on a super master (from the possibly-restricted list)
	${PATHGNU}/grep -oE '^[0-9]{8}' "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt" | sort -u > "List_MAS_${RUNDATE}_${RNDM1}.txt"

	if [ "${USESM}" == "Yes" ]	# i.e. if all images are coregistered on a Super Master 
		then 
			# All atmo screens will be projected in slant range in SAR_CSL/SAT/TRK/SuperMaster/Data
			# Search in SAR-CSL/.../SM/Data which screen is not projected yet
			while IFS= read -r ATMOSCREEN; do
			    if ! ls "${INPUTDATA}/${SUPERMASDIR}/Data/slantRangeFiles/"*"${ATMOSCREEN}"* 2>/dev/null | ${PATHGNU}/grep -q .
			    	then
			        	echo "${ATMOSCREEN}" >> List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt
			        else 
			        	echo "${ATMOSCREEN}" >> List_AtmoScreen_AlreadyComputed_${RUNDATE}_${RNDM1}.txt
			    fi
			done <  "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt"
			
			if [ "${FORCE}" == "ForceReproj" ]
				then
					EchoTee "Force Reprojecting all screens in slant Range"
					if [ -f "List_AtmoScreen_AlreadyComputed_${RUNDATE}_${RNDM1}.txt" ] ; then
						cat "List_AtmoScreen_AlreadyComputed_${RUNDATE}_${RNDM1}.txt" >> "List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt"
						rm -f "List_AtmoScreen_AlreadyComputed_${RUNDATE}_${RNDM1}.txt"
					fi
			fi
			
		else
			# All atmo screens will be projected in slant range in each SAR_CSL/SAT/TRK/Img/Data
			# List in SAR-CSL/.../Img/Data which screen is not projected yet
			
			while IFS= read -r DATE; do
			    already="List_AtmoScreen_${DATE}_AlreadyComputed_${RUNDATE}_${RNDM1}.txt"
			    tocompute="List_AtmoScreen_${DATE}_ToCompute_${RUNDATE}_${RNDM1}.txt"
			    all="List_All_AtmoScreen_${DATE}_${RUNDATE}_${RNDM1}.txt"
			
			    while IFS= read -r STRING; do
			        MASDIR=$(ls -d "${INPUTDATA}/"*"${DATE}"* 2>/dev/null | head -1 | xargs basename 2>/dev/null)
			        
			        if [ "${FORCE}" == "ForceReproj" ]
						then
							echo "$STRING" >> "${all}"
						else 
							# sort files depending on already projected or not
			        
			       			if [ -n "$MASDIR" ] && ls "${INPUTDATA}/${MASDIR}/Data/slantRangeFiles/"*"${STRING}"* 2>/dev/null | ${PATHGNU}/grep -q .; then
			       			    echo "$STRING" >> "${already}"
			       			else
			       			    echo "$STRING" >> "${tocompute}"
			       			fi
			       	fi
			    done < <(grep "^${DATE}" "List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt") # Search for MAS_SLV atmo screens 
			
			done < "List_MAS_${RUNDATE}_${RNDM1}.txt"		# For each MASTER date
	fi

	EchoTee "	List of atmo screens to project in slant range:"
	NBTOPROJ=0
	if [ "${USESM}" == "Yes" ]
		then
			# With a Global Primary: one single list
			if [ -s "List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt" ] ; then
				cat "List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt"
				cat "List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt" >> "${LOGFILE}"
				EchoTee "(See List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt)"
				NBTOPROJ=$(wc -l < "List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt")
			fi
		else
			# Without a Global Primary: one list per Primary date, hence loop over them
			# instead of relying on ${DATE} left over from the loop above
			while IFS= read -r MASDATETOPROJ; do
				[ -n "${MASDATETOPROJ}" ] || continue
				if [ "${FORCE}" == "ForceReproj" ]
					then LISTTOREPORT="List_All_AtmoScreen_${MASDATETOPROJ}_${RUNDATE}_${RNDM1}.txt"
					else LISTTOREPORT="List_AtmoScreen_${MASDATETOPROJ}_ToCompute_${RUNDATE}_${RNDM1}.txt"
				fi
				if [ -s "${LISTTOREPORT}" ] ; then
					EchoTee "	- Primary ${MASDATETOPROJ}:"
					cat "${LISTTOREPORT}"
					cat "${LISTTOREPORT}" >> "${LOGFILE}"
					NBTOPROJ=$(( NBTOPROJ + $(wc -l < "${LISTTOREPORT}") ))
				fi
			done < "List_MAS_${RUNDATE}_${RNDM1}.txt"
			EchoTee "(See List_AtmoScreen_<PrimaryDate>_ToCompute_${RUNDATE}_${RNDM1}.txt)"
	fi
	if [ "${NBTOPROJ}" -eq 0 ] ; then EchoTee "	- none - " ; fi


	EchoTee ""
	
# Project all atmo screens using Proj_AllFiles_in_SltRg.sh
####################################################################
# in slant Range of the Global Primary (all sat, and S1 in WSWATHSM mode) or
# in slant Range of each Primary (S1 in WIDESWATH mode, i.e. no Global Primary)

	EchoTee "****************************************** ${PRG} *********************************"
	EchoTee "Project all atmo screens in slant Range geometry: "
	EchoTee "*************************************************************************************************"
	EchoTee ""

	FAILEDPROJ="${PATHATMOSCREENS}/List_Dates_ProjectionFailed_${RUNDATE}_${RNDM1}.txt"

	if [ "${USESM}" == "Yes" ]	# i.e. if all images are coregistered on a Global Primary
		then
			# One single projection, in the Global Primary geometry.
			# If ForceReproj: project all the screens, else only the new ones.
			if [ "${FORCE}" == "ForceReproj" ]
				then
					EchoTee "Force projection of all atmospheric screens into Global Primary slant range geometry..."
					SCREENLIST="List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt"
				else
					EchoTee "Projection of the new atmospheric screens into Global Primary slant range geometry..."
					SCREENLIST="List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt"
			fi
			if ! ProjectScreensInSltRg "${SUPERMASTER}" "${SCREENLIST}" ; then
				EchoTeeRed " Projection in the Global Primary ${SUPERMASTER} geometry FAILED; nothing can be corrected."
				echo "${SUPERMASTER}" >> "${FAILEDPROJ}"
			fi

		else
			# No Global Primary: one projection per Primary date, each in its own geometry.
			# If ForceReproj: project all the screens of that date (List_All_AtmoScreen_${DATE}_...),
			# else only the new ones (List_AtmoScreen_${DATE}_ToCompute_...).
			while IFS= read -r DATE; do
				[ -n "${DATE}" ] || continue
				if [ "${FORCE}" == "ForceReproj" ]
					then
						EchoTee "Force projection of the atmospheric screens of ${DATE} into its own Primary slant range geometry..."
						SCREENLIST="List_All_AtmoScreen_${DATE}_${RUNDATE}_${RNDM1}.txt"
					else
						EchoTee "Projection of the new atmospheric screens of ${DATE} into its own Primary slant range geometry..."
						SCREENLIST="List_AtmoScreen_${DATE}_ToCompute_${RUNDATE}_${RNDM1}.txt"
				fi
				# a failure on one date must not kill the whole run: the other dates can still be corrected
				if ! ProjectScreensInSltRg "${DATE}" "${SCREENLIST}" ; then
					EchoTeeRed " Projection in the ${DATE} Primary geometry FAILED; the pairs of that date are skipped."
					echo "${DATE}" >> "${FAILEDPROJ}"
				fi
				EchoTee ""
			done < "List_MAS_${RUNDATE}_${RNDM1}.txt"		# For each Primary date
	fi

	if [ -s "${FAILEDPROJ}" ] ; then
		EchoTeeRed ""
		EchoTeeRed " WARNING: projection failed for $(wc -l < "${FAILEDPROJ}") date(s), see ${FAILEDPROJ}"
		EchoTeeRed ""
	fi

# Resize at size of InSARProducts files and remove atmo screen from defo
######################################################################
# First, ln each projected atmo filter in ${INPUTDATA}/${MASDIR}/Data
# Then execute InSARProductsGeneration -r in each  MASS_PROCESS/.../i12/InSARProducts to get the atmo filter at the same size as all the interf products 
# Then substract that atmo filter from the deformation map and name it deformationMap_${ATMOCORR}

	EchoTee "******************************* ${PRG} ****************************"
	EchoTee "Resize atmo screens at size of InSARProducts files and remove atmo screen from defo"
	EchoTee "***********************************************************************************"
	EchoTee ""


	# If no ForceReproj, build list of pairs to process - may differ from List_AtmoScreen_ToCompute_${RUNDATE}_${RNDM1}.txt !
	# 	Compare list List_All_AtmoScreen_....txt and pairs in SAR_MASSPROCESS/.../Geocoded/Defo_UnselectedVersions"
	# 	If no Defo map exist with the same ATMOCORR, consider the pair to be computed 
	
	if [ "${FORCE}" == "ForceReproj" ]
		then
			# Force reprocessing everything: take all the screens (already restricted to
			# -pairs if that option was used)
			LIST_TO_PROCESS="List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt"
		else
			# Only the pairs that have no deformation map corrected with ${ATMOCORR} yet.
			# Search EVERY mode dir (Defo, DefoDetrend, DefoInterpol, DefoInterpolx2,
			# DefoInterpolDetrend, DefoInterpolx2Detrend) and their _UnselectedVersions:
			# depending on INTERPOL and REMOVEPLANE the corrected map may sit in any of
			# them, and searching only /Geocoded/Defo would re-correct every pair forever.
			INPUT_LIST="List_All_AtmoScreen_${RUNDATE}_${RNDM1}.txt"
			OUTPUT="List_AtmoScreen_forPairs_To_Correct_${RUNDATE}_${RNDM1}.txt"
			LOOKUP=$(mktemp "${TMPDIR:-/tmp}/AtmoCorrLookup.XXXXXX")

			: > "${OUTPUT}"			# start from an empty list

			# list of pairs already corrected with ${ATMOCORR}, whatever the mode
			for DIR in "${MASSPROCESSPATHLONG}"/Geocoded/Defo*/ ; do
				[ -d "${DIR}" ] || continue
				case "$(basename "${DIR}")" in
					*_TMP_*|*_New_*)	continue ;;	# temporary or other-grid dirs
				esac
				# The tag must be matched as a WHOLE TOKEN, i.e. preceded by "_" and followed
				# by a ".": the geocoded products are named
				#	deformationMap[.interpolated]_<TAG>[.flattened].UTM.<pixsize>.bil_..._<look>deg
				# An unanchored *"${ATMOCORR}"* glob would, with ATMOCORR=GACOS, also claim the
				# pairs corrected with GACOSIncidMapMEDIAN, GACOSIncidFixMEAN... as already done,
				# and those pairs would then never be corrected with GACOS itself.
				for f in "${DIR}"*_"${ATMOCORR}".*deg ; do
					[ -e "${f}" ] || continue
					basename "${f}" | ${PATHGNU}/grep -oE '[0-9]{8}_[0-9]{8}'
				done
			done | sort -u > "${LOOKUP}"

			EchoTee "	$(wc -l < "${LOOKUP}") pair(s) already corrected with ${ATMOCORR} in $(basename "${MASSPROCESSPATHLONG}")/Geocoded/Defo*"

			# keep the screens whose pair is not in that lookup
			while IFS= read -r STRING; do
				[ -n "${STRING}" ] || continue
				MAS="${STRING%%_*}"
				SLV="${STRING#*_}" ; SLV="${SLV%%_*}"
				if ! ${PATHGNU}/grep -qx "${MAS}_${SLV}" "${LOOKUP}" ; then
					echo "${STRING}" >> "${OUTPUT}"		# screen name, with its dates
				fi
			done < "${INPUT_LIST}"

			rm -f "${LOOKUP}"
			LIST_TO_PROCESS="${OUTPUT}"
			EchoTee "	$(wc -l < "${LIST_TO_PROCESS}") screen(s) to apply (see ${LIST_TO_PROCESS})"
	fi

	# perform resizing and atmo correction 
	if [ "${USESM}" == "Yes" ]	# i.e. if all images are coregistered on a Super Master 
		then 
			# Use SuperMaster: select list of pairs to process
			ResizeAndAtmoCorrAndRegeoc "${LIST_TO_PROCESS}" "PROJ_ON_SM"	
		
		else 
			# Do not use SuperMaster: select list of pairs to process
			ResizeAndAtmoCorrAndRegeoc "${LIST_TO_PROCESS}" "PROJ_ON_MASTER"
	fi

# Some Cleaning of log files older than OLDNESS days...
OLDNESS=15
cd "${PATHATMOSCREENS}"
find . -maxdepth 1 -name "List_MAS_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "List_AtmoScreen_ToCompute_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "List_AtmoScreen_AlreadyComputed_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "List_All_AtmoScreen_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
find . -maxdepth 1 -name "List_Pairs_MissingInMassProcess_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;


cd "${MASSPROCESSPATHLONG}"
find . -maxdepth 1 -name "List_Pairs_ToRegeoc_*.txt" -type f -mtime +${OLDNESS} -exec rm -f {} \;
