#!/bin/bash
######################################################################################
# This script aims at working on the atmo-corrected deformations maps for: 
# 	- detrend the data (if requested in LaunchParam.txt),  
#	- and re-geocode the deformation maps after Atmospheric correction applied e.g. using MANGO toolbox
# This is done for a list of pairs (provided as parameter) that were already mass processed. 
#
# Re-Geocoded data are named with a string explaining the correction applied (e.g. _MangoGAMIT).
#
# Then the improvement obtained from the atmo correction is tested against existing uncorrected pair 
# and, if any, same pair corrected with another method. This is performed using the script Select_BestVersion.py.
# The defor maps from the best correction are saved in the appropriate /Geocoded/Modes (e.g. /Geocoded/Defo, 
# /Geocoded/DefoInterpol,/Geocoded/DefoInterpolx2Detrend...), while the less favorable deformation maps
# are stored in ..._UnselectedVersions (e.g. /Geocoded/Defo_UnselectedVersions, 
# /Geocoded/DefoInterpol_UnselectedVersions,/Geocoded/DefoInterpolx2Detrend_UnselectedVersions...). 
#
# Note that these _UnselectedVersions directories may contain more than one deformation map per pair but
# there is no confusion possible as the name contains the information about the correction (if any).
# By doing this, the /Geocoded/Modes (e.g. /Geocoded/Defo, /Geocoded/DefoInterpol,/Geocoded/DefoInterpolx2Detrend...)
# always contains the best products to invert with MSBAS. 
#
# Note that the re-geocoding may be done with other geocoding parameters. In that case, the results are stored in 
# /Geocoded/Defo..._New_${COMMENT}. Multiple corrections with different atmospheric models are not planned in that case though. 
#
# Note that it will cope with inverted dates (if any) in the list compared to pair dirs. 
#
# Parameters : 	- List of pairs to reprocess, in the form list of pair of dates or pairs of image name, separated by a space or _, e.g. 
#					YYYYMMDD_YYYYMMDD, YYYYMMDD YYYYMMDD or *YYYYMMDD* *YYYYMMDD*  
#				- Parameters file with new paramaters for reprocessing (a least LaunchMTparam.txt version >= 2026) 
#				- a COMMENT for naming re-geocoded products. Automatically created by MANGO.sh, it aims at explaing the reason for the reprocessing and will be used in remaning the products:  
#						- ReGeocoded (if re-geocoded with new parameters). 
#							Re-geocoding is done anyway.
#						- ReDetrend (if re-detrended e.g. to test new filter at detrending to mask deformation). 
#							Removing a best plane is done by selecting DETREND as REMOVEPLANE parameter in LaunchParameters.txt  
#						- MangoGAMIT, (if corrected with the GNSS based correction Mango Toolbox based on ZTD extracted with GAMIT, Albino et al. 2025).  
#							Removing atmospheric correction based on GAMIT GNSS ZTD data is done by selecting MangoGAMIT as ATMOCORR parameter in LaunchParameters.txt
#						- MangoGIPSY, (if corrected with the GNSS based correction Mango Toolbox based on ZTD extracted with GIPSY, Albino et al. 2025) 
#						- MangoBERNESE, (if corrected with the GNSS based correction Mango Toolbox based on ZTD extracted with BERNESE, Albino et al. 2025) 
#						- other to come, like GACOS - not tested yet - (if corrected with ECMWG+GNSS model based correction, Yu et al. 2018)
#
# Hard coded:	- List of recognized atmospheric corrections. See AtmoCorrList
#
# Dependencies:	- RenamePath_Volumes.sh 
#				- Select_BestVersion.py to assess the improvement of the atmo correction 
#				  (must be in the PATH; needs python3 + numpy) 
#
# WARNING: run a test before operate on full scale to bee sure that the naming and renaming fits your needs. 
#
#
# New in Distro V 1.0 20260226:	- setup
# New in Distro V 1.1 20260302:	- Rename original products with COMMENT
#								- move recomputed products in Geocoded only if processed with same ReGeocoding parameters 
# New in Distro V 1.2 20260612:	- RenamePath_Volumes.sh and RenamePathAfterMove_in_SAR_MASSPROC.sh before re-geocode to be sure
# New in Distro V 1.3 20260618:	- exit as soon as a command or a script launched from here exit with non 0, that is with an error
#								- revise exit status: set to exit 1 everywhere i.e. exit with error (exit 0 would be exit with success)
# New in Distro V 1.4 20260626:	- name defor mode dir /Geocoded/Defo_UnselectedVersions etc... instead of /Geocoded/Defo_original_before_"${COMMENT}
#								  in order to cope with several atmo corr if any
# New in Distro V 1.5 20260806:	- apply testing the quality on Detrend (if any) and sort all type of products accordingly (Defo, DefoInterpol...)
#								- set the list of recognized atmospheric corrections in an array AtmoCorrList
# New in Distro V 1.6 20260810:	- complete the branch with different geocoding parameters (SAMEGEOC=No):
#								  the maps re-geocoded on the new grid, corrected AND uncorrected, are now
#								  compared with each other and dispatched in Defo..._New_${COMMENT} and
#								  Defo..._New_${COMMENT}_UnselectedVersions
#								- one single mode table (MODE / MODEPREFIX / MODEPREFIXORIG) for both branches
#								- add the INTERPOL=AFTER products, which no mode prefix was matching
#								- correct the DefoDetrend prefix: bestPlaneRemoval2 writes
#								  deformationMap_${ATMOCORR}.flattened, not deformationMap.flattened_${ATMOCORR}
#								- dispatch the /GeocodedRasters as well, through SortAtmoDefoFiles
#								- create the destination dirs before moving into them
#								- rmdir instead of rm -Rf on the _TMP dirs: never lose an unmoved file
# New in Distro V 1.7 20260811:	- store comparison results in $SCRORESDIR (.csv)
#								- PARKDIR_TMP must be outside of InSARProducts, otherwise all its defo files will be geocoded again. 
#								- similarly, to avoid being regeocoded, original_before_ defo files can't contain the string deformationMap 
# New in Distro V 1.8 20260812:	- no mv of a geocoded product may overwrite an existing map anymore: they all
#								  go through MoveAsWithoutOverwriting / StampAwayIfPresent, which insert
#								  _${RUNDATE}_${RNDM1} before the extension as long as the name is taken
#								- drop the "skip the files containing _${COMMENT}" rule of
#								  BackupAllVersionsOfPair: when MANGO.sh sets COMMENT to the name of the
#								  correction, that rule was leaving the former corrected map in
#								  /Geocoded/<MODE>, where the dispatching was overwriting it later
# New in Distro V 1.9 20260812:	- a former map corrected with the SAME method as the current run gets exactly
#								  the name of the recomputed one. It used to be silently crushed when the
#								  new map was moved in the <MODE>_TMP_... dir. It is now parked there with
#								  the tag _DUPLICATE_${RUNDATE}_${RNDM1} and the two are arbitrated by
#								  ResolveDuplicateVersions:
#									- byte identical	: the former copy is removed
#									- they differ		: Select_BestVersion.py compares these two only.
#									  The winner keeps/receives the CLEAN (untagged) name and goes on
#									  with the normal dispatching, hence to /Geocoded/<MODE> if it wins
#									  the general comparison as well. The loser keeps the
#									  _DUPLICATE_${RUNDATE}_${RNDM1} tag and is archived at once in
#									  <MODE>_UnselectedVersions. When the FORMER map wins, the tag is
#									  therefore moved from one file to the other
#									- mode not recomputed	: the tag is removed, the former map takes
#									  part in the general comparison as before
#								- the .hdr and the .ras always follow their ENVI binary: renaming and
#								  moving are done per product family (RenameProductFamily,
#								  MoveProductFamily, RemoveProductFamily)
# New in Distro V 2.0 20260812:	- V1.9 was detecting the former version of a recomputed map by looking for
#								  _${ATMOCORR} in its name. When the test missed, the former map was left
#								  in /Geocoded/<MODE>, or moved untagged in the _TMP dir where the new map
#								  then overwrote it: no comparison, no archived loser, one single line in
#								  the .csv. The clash is now DETECTED instead of predicted:
#									- GatherModesInTmp runs FIRST, so the newly geocoded maps are already
#									  in <MODE>_TMP_... when the former versions are backed up
#									- BackupAllVersionsOfPair tags a former map with
#									  _DUPLICATE_${RUNDATE}_${RNDM1} when, and only when, its name is
#									  one of those just recomputed. Any naming subtlety (ETAD, POSTFIX,
#									  a correction name being a substring of another) is thus covered
#									- the list of the recomputed names is taken BEFORE moving anything,
#									  otherwise a former map moved in early made its own .hdr look like
#									  a duplicate and the ENVI pair ended up half tagged
#								- a byte identical former map is no longer deleted: it is archived with
#								  the _DUPLICATE tag as any other loser, so a run always leaves a trace
#								- the candidates of the general comparison are listed in the log: one
#								  single candidate (hence one single line in the .csv) means the mode dir
#								  held no other version of that pair, which is not an error
# New in Distro V 2.1 20260813:	- Source the array with the list of recognised atmospheric correction models from __HardCodedLines.sh
# New in Distro V 2.2 20260817:	- a correction tag is now recognised as a WHOLE TOKEN in the file names, no 
#								  more as a substring. Since AtmoCorrList holds tags of which another one is a 
#								  prefix (GACOS, GACOSIncidMapMEAN, GACOSIncidMapMEDIAN...), the glob 
#								  *"${CORR}"* used to park the products of the CURRENT correction as if they 
#								  belonged to another method: with ATMOCORR=GACOSIncidMapMEDIAN, 
#								  deformationMap.interpolated_GACOSIncidMapMEDIAN matched *GACOS* and was moved 
#								  in OtherProcessing_tmp before the detrending. bestPlaneRemoval2 was then 
#								  reading a file that was not there anymore (Filelength = 0), wrote no 
#								  .flattened and the MakeFig of that .flattened was failing. Note that without 
#								  DETREND the same parking was also hiding the corrected map from GeocUTM.
#								  All the tests are now done with HasAtmoTag, that requires the tag to be 
#								  preceded by "_" and followed by "." or by the end of the name

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/10 -						 
######################################################################################
PRG=`basename "$0"`
VER="Distro V2.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 17, 2026"

echo " "
echo "********************************************************************************"
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo "********************************************************************************"

echo " " 

LISTPAIRS=$1	# path to a file with the list of pairs to process in the form of YYYYMMDD_YYYYMMDD or ?? 
PARAMFILE=$2	# Parameters file with new paramaters for reprocessing 
				# (LaunchMTparam.txt version >= 2026)
COMMENT=$3		# Reason for reprocessing. Note that the former products will be moved in ... as original_before_COMMENT....

# vvvvvvvvvvvvvv Hard coded vvvvvvvvvvv
# List of atmo corrections
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below
	# ReadArrayAtmoModels for AtmoCorrList=(MangoGAMIT MangoGIPSY MangoBERNESE GACOS...)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


# Force the present script to stop if any of the scripts launched from here exit with non zero exit code, that is with an error
###############################################################################################################################
#set -e
# Now any command that returns non-zero exits this script immediately

# Some checks
#############
	if [ $# -lt 2 ] ; then echo " Usage $0 PAIRS_LIST PARAMETERS_FILE [REASON_TO_REPROCESS]" ; echo ; exit 1; fi
	
# Read parameters file as from SuperMaster_MassProc.sh - may read too much parameters but it is safe...
######################	
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

	S1COREGMODE=`GetParam S1COREGMODE`			# S1COREGMODE, For S1 only: either S1SM (for coregistering all the S1 on a given Super Master),
												# or S1ORBIT (or anything else than S1SM) to skip coreg and rely only on the S1 orbits. 
	
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
	
	DEMNAME=`GetParam "DEMNAME,"`				# DEMNAME, name of DEM inverted by lines and columns
	
	MASSPROCESSPATH=`GetParam MASSPROCESSPATH`	# MASSPROCESSPATH, path to dir where all processed pairs will be stored in sub dir named by the sat/trk name (SATDIR/TRKDIR)
	RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data are stored 
	
	ETADPROD=`GetParam "ETADPROD,"`				# ETADPROD, only for S1: use of ETAD products at InSARProductsGeneration: ETADno (no ETAD correction) or ETADxyz, where x, y and z are Iono, Geo and Tropo correction respectively and take values 0 (not used) or 1 (used)
	ETADCOMBI=`GetParam "ETADCOMBI,"`			# ETADCOMBI, only for S1 (ETADCOMBIyes or ETADCOMBIno): if yes, and if ETADPROD is with two or more 1, it will compute all the combinations of corrections in addition to the resquested one 
	ETADGEOC=`GetParam "ETADGEOC,"`				# ETADGEOC, only sor S1: Use of ETAD products to improve geocoding (ETADGEOCyes, or ETADGEOCno)

	source ${FCTFILE}

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
eval RNDM1=`echo $(( $RANDOM % 10000 ))`

#  Define AtmoCorrList=(MangoGAMIT MangoGIPSY MangoBERNESE GACOS...) from __HardCodedLines.sh
ReadArrayAtmoModels

# get AMSTer version 
####################
GetAMSTerEngineVersion

# Some functions
################

## cp a file as a backup with same name but with additional original_ string before the name (it also prevent re-geocoding the old files later) 
#backup_original() {
#    local file="$1"
#
#    # Check that it exists and is a regular file
#    if [[ -f "$file" ]]; then
#        local dir base backup backupdir
#
#        dir="$(dirname -- "$file")"
#        base="$(basename -- "$file")"
#
#        backupdir="$(dirname -- "$dir")"
#        mkdir -p "${backupdir}/InSARProducts_original_before_${COMMENT}"
#       
#        backup="${backupdir}/InSARProducts_original_before_${COMMENT}/${base}"
#
#		target="$backup"
#		while [ -e "$target" ] || [ -L "$target" ] ; do	# -L also catches broken symlinks
#			target="${backup}_${RUNDATE}_${RNDM1}"
#		done
#
#        # Copy with preserved timestamps & permissions
#        cp -p -- "$file" "$target"		# -- avoids prblm if a file starts with a -
#
#    fi
#}

# Insert the string $2 in the file name $1, BEFORE its extension.
#
# The geocoded products are named e.g.
#	deformationMap.interpolated_MangoGAMIT.flattened_S1_88-0.4deg_20260418_20260512_Bp12m_HA34m_BT24days_Head349deg
# that is, they contain several dots but have NO extension, while their companion
# files end in .hdr or .ras. Only these two known extensions are recognized here:
# a generic "everything after the last dot is the extension" rule would insert the
# string in the middle of the product name (before ".flattened", ".interpolated"...).
# The binary and its .hdr get the same insertion, so the ENVI pair stays consistent.
function InsertBeforeExtension()
	{
	local NAME="$1"
	local WHAT="$2"

	case "${NAME}" in
		*.hdr)	echo "${NAME%.hdr}${WHAT}.hdr" ;;
		*.ras)	echo "${NAME%.ras}${WHAT}.ras" ;;
		*)		echo "${NAME}${WHAT}" ;;
	esac
	}

# Insert the run stamp _${RUNDATE}_${RNDM1} before the extension of the file name $1.
# $2 = optional extra suffix appended to the stamp (a counter, when even the stamped
# name is already taken).
function StampBeforeExtension()
	{
	InsertBeforeExtension "$1" "_${RUNDATE}_${RNDM1}$2"
	}

# Move the file $1 into the directory $2 under the name $3, WITHOUT EVER OVERWRITING
# anything: if that name is already taken, the run stamp (then a counter) is inserted
# before the extension until a free name is found.
#
# Every mv of a geocoded product in this script goes through this function or through
# StampAwayIfPresent: with a plain "mv -f", two versions of the same pair carrying the
# same name (e.g. the former and the newly recomputed ${ATMOCORR} corrected map) meant
# that one of them was silently destroyed instead of being compared and archived.
function MoveAsWithoutOverwriting()
	{
	local SRCFILE="$1"
	local DESTDIR="$2"
	local DESTNAME="$3"
	local TARGET n

	if [ ! -e "${SRCFILE}" ] ; then
		echo "WARNING: ${SRCFILE} does not exist; nothing moved." >&2
		return 1
	fi

	mkdir -p "${DESTDIR}" || return 1

	# -L as well, in order to catch broken symlinks
	TARGET="${DESTDIR}/${DESTNAME}"
	n=1
	while [ -e "${TARGET}" ] || [ -L "${TARGET}" ] ; do
		TARGET="${DESTDIR}/$(StampBeforeExtension "${DESTNAME}" "_${n}")"
		n=$((n + 1))
	done

	# mute the possible complaining message about permissions that can't be preserved,
	# as it may occur when moving from Mac to Linux or Windows
	mv -f -- "${SRCFILE}" "${TARGET}" 2>/dev/null || return 1
	return 0
	}

# Move the file $1 into the directory $2 keeping its name, without ever overwriting.
# $3 = Yes forces the run stamp even when the plain name would be free.
function MoveWithoutOverwriting()
	{
	local SRCFILE="$1"
	local DESTDIR="$2"
	local FORCESTAMP="$3"
	local NAME

	NAME="${SRCFILE##*/}"		# no basename call: portable and no fork
	if [ "${FORCESTAMP}" = "Yes" ] ; then NAME="$(StampBeforeExtension "${NAME}")" ; fi

	MoveAsWithoutOverwriting "${SRCFILE}" "${DESTDIR}" "${NAME}"
	}

# Rename OUT OF THE WAY a file already present in the directory $1 under the name $2,
# by inserting the run stamp _${RUNDATE}_${RNDM1} before its extension. Nothing is
# done if the name is free. Returns 0 in both cases.
#
# Used where the file that is arriving must keep the clean name (the products that
# MSBAS will invert must be the ones just selected), while the version that was there
# before has to survive under a distinguishable name rather than being crushed.
function StampAwayIfPresent()
	{
	local DESTDIR="$1"
	local NAME="$2"
	local EXISTING TARGET n

	EXISTING="${DESTDIR}/${NAME}"
	if [ ! -e "${EXISTING}" ] && [ ! -L "${EXISTING}" ] ; then return 0 ; fi

	TARGET="${DESTDIR}/$(StampBeforeExtension "${NAME}")"
	n=1
	while [ -e "${TARGET}" ] || [ -L "${TARGET}" ] ; do
		TARGET="${DESTDIR}/$(StampBeforeExtension "${NAME}" "_${n}")"
		n=$((n + 1))
	done

	mv -f -- "${EXISTING}" "${TARGET}" 2>/dev/null || return 1
	echo "INFO: ${NAME} was already in ${DESTDIR##*/}; kept as ${TARGET##*/}" >&2
	return 0
	}

function RenameNewDefoProducts()
	{
	unset FILE 
	local FILE
	# all deformationMap except those already renamed, i.e. that contain SATDIR
	for FILE in `ls  | ${PATHGNU}/grep deformationMap  | ${PATHGNU}/grep -v "${SATDIR}" | ${PATHGNU}/grep -v "original" | ${PATHGNU}/grep -v "\.sh$" | ${PATHGNU}/grep -v "\.rev$" | ${PATHGNU}/grep -v "xRef" | ${PATHGNU}/grep -v "yRef" | ${PATHGNU}/grep -v "xRadius" | ${PATHGNU}/grep -v "yRadius" | ${PATHGNU}/grep -v "projMat"`
	do
		FILENOEXT=`echo "${FILE}" |  ${PATHGNU}/gawk '{gsub(/.*[/]|[.]{1}[^.]+$/, "", $0)} 1'`
		FILEEXT=`echo "${FILE}" |  ${PATHGNU}/gawk -F'[.]' '{print $NF}'`
		case ${FILEEXT} in 
			"bil")
				#if [ "${SATDIR}" = "S1" ] && [[ "${ETADPROD}" != "" ]]
				# ETADPROD correction shouldn't happen here though...
				if [ ${SATDIR} == "S1" ] && [[ "${ETADPROD}" =~ ^(ETAD|ETAD111|ETAD110|ETAD101|ETAD011|ETAD001|ETAD010|ETAD100)$ ]] 
					then
						mv ${FILE} ${FILENOEXT}.${ETADPROD}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
						#mv ${FILE} ${FILENOEXT}.bil${ETADPROD}_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
					else
						mv ${FILE} ${FILENOEXT}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
				fi
				;;
			"ras")
				#if [ "${SATDIR}" = "S1" ] && [[ "${ETADPROD}" != "" ]]
				# ETADPROD correction shouldn't happen here though...
				if [ ${SATDIR} == "S1" ] && [[ "${ETADPROD}" =~ ^(ETAD|ETAD111|ETAD110|ETAD101|ETAD011|ETAD001|ETAD010|ETAD100)$ ]] 
					then
						if [ "${FIG}" == "FIGyes"  ] ; then 
							SECONDFILENOEXT=`echo "${FILENOEXT}" |  ${PATHGNU}/gawk '{gsub(/.*[/]|[.]{1}[^.]+$/, "", $0)} 1'`
							SECONDEXT=`echo "${FILENOEXT}" |  ${PATHGNU}/gawk -F'[.]' '{print $NF}'`
							mv ${FILE} ${SECONDFILENOEXT}.${ETADPROD}.${SECONDEXT}_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.ras 
						fi
					else
						if [ "${FIG}" == "FIGyes"  ] ; then 
							mv ${FILE} ${FILENOEXT}_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.ras	
						fi
				fi
				;;
			"hdr")
				#if [ "${SATDIR}" = "S1" ] && [[ "${ETADPROD}" != "" ]]
				# ETADPROD correction shouldn't happen here though...
				if [ ${SATDIR} == "S1" ] && [[ "${ETADPROD}" =~ ^(ETAD|ETAD111|ETAD110|ETAD101|ETAD011|ETAD001|ETAD010|ETAD100)$ ]] 
					then
						mv ${FILE} ${FILENOEXT}.${ETADPROD}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
						#mv ${FILE} ${FILENOEXT}.bil${ETADPROD}_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr

					else
						mv ${FILE} ${FILENOEXT}.bil_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
				fi
				;;
			"interpolated")
				#if [ "${SATDIR}" = "S1" ] && [[ "${ETADPROD}" != "" ]]
				# ETADPROD correction shouldn't happen here though...
				if [ ${SATDIR} == "S1" ] && [[ "${ETADPROD}" =~ ^(ETAD|ETAD111|ETAD110|ETAD101|ETAD011|ETAD001|ETAD010|ETAD100)$ ]] 
					then
						mv ${FILE} ${FILENOEXT}.${ETADPROD}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
						# get any existing hdr and adapt it 
						FORMERHDR=`ls *.hdr | head -1`
						cp ${FORMERHDR} ${FILENOEXT}.${ETADPROD}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
						${PATHGNU}/gsed -i "/Description/c\Description = {${FILENOEXT}.${ETADPROD}.interpolated" ${FILENOEXT}.${ETADPROD}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
					else
						mv ${FILE} ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
						# get any existing hdr and adapt it 
						FORMERHDR=`ls *.hdr | head -1`
						cp ${FORMERHDR} ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
						${PATHGNU}/gsed -i "/Description/c\Description = {${FILENOEXT}.interpolated" ${FILENOEXT}.interpolated_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
				fi
				;;
			"flattened")
				#if [ "${SATDIR}" = "S1" ] && [[ "${ETADPROD}" != "" ]]
				# ETADPROD correction shouldn't happen here though...
				if [ ${SATDIR} == "S1" ] && [[ "${ETADPROD}" =~ ^(ETAD|ETAD111|ETAD110|ETAD101|ETAD011|ETAD001|ETAD010|ETAD100)$ ]] 
					then
						mv ${FILE} ${FILENOEXT}.${ETADPROD}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
						# get any existing hdr and adapt it 
						FORMERHDR=`ls *.hdr | head -1`
						cp ${FORMERHDR} ${FILENOEXT}.${ETADPROD}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
						${PATHGNU}/gsed -i "/Description/c\Description = {${FILENOEXT}.${ETADPROD}.flattened" ${FILENOEXT}.${ETADPROD}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
					else
						mv ${FILE} ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg
						# get any existing hdr and adapt it 
						FORMERHDR=`ls *.hdr | head -1`
						cp ${FORMERHDR} ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
						${PATHGNU}/gsed -i "/Description/c\Description = {${FILENOEXT}.flattened" ${FILENOEXT}.flattened_${SATDIR}_${TRKDIR}-${LOOK}deg_${MASDATE}_${SLVDATE}_Bp${Bp}m_HA${HA}m_BT${BT}days_Head${HEADING}deg.hdr
				fi
				;;
		esac		
	done 
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

# Returns 0 if the file name $1 carries the atmospheric correction tag $2.
#
# The products are named
#	deformationMap[.interpolated]_<TAG>[.flattened][.ras|.hdr|...]
# hence the tag is ALWAYS preceded by "_" and followed by "." or by the end of the
# name. Testing that boundary is what distinguishes GACOS from GACOSIncidMapMEDIAN:
# an unanchored *"GACOS"* glob matches both, and the same holds for any tag of
# AtmoCorrList of which another one is a prefix. Never use a bare *"${CORR}"*
# pattern on these names.
function HasAtmoTag()
	{
	case "${1##*/}" in
		*_"$2")		return 0 ;;		# tag at the end of the name
		*_"$2".*)	return 0 ;;		# tag followed by .flattened, .ras, .hdr, .UTM...
	esac
	return 1
	}

function ConfirmReprocessWithDiffParam()
	{
	while true; do
		read -p "Are you sure you want to re-geocode the data with other parameters ?"  yn
		case $yn in
			[Yy]* ) 
				echo "OK, you know..."
				break ;;
			[Nn]* ) 
				echo "OK, Change your LaunchParameters.txt and relaunch..."
				exit 1	
				break ;;
			* ) echo "Please answer yes or no.";;
		esac
	done
	}

function BackupGeocOrig()
	{
	unset IMG TARGETDIR
	local IMG=$1 # MAS, SLV or BOTH
	local TARGETDIR=$2 # where to store figs

	# keep a link after moving, just in case... 
	EnviToBeCopied=`ls ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR}/*${IMG}*${MASDATE}_${SLVDATE}*deg | ${PATHGNU}/grep -v "_${COMMENT}"`
	EnviHdrToBeCopied=`ls ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR}/*${IMG}*${MASDATE}_${SLVDATE}*deg.hdr | ${PATHGNU}/grep -v "_${COMMENT}"`

	mv -f ${EnviToBeCopied} ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR}_TMP"_${RUNDATE}_${RNDM1}" 2>/dev/null	#  mute possible complaining message that permission can't be preserved, as it may occur when moving from Mac to Linux or Windows 
	#ln -s ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR}/$(basename ${EnviToBeCopied}) ${RUNDIR}/i12/GeoProjection/$(basename ${EnviToBeCopied})
	EchoTee "*${IMG}*${MASDATE}_${SLVDATE}*deg copied to /Geocoded/${TARGETDIR}_TMP"_${RUNDATE}_${RNDM1}" "

	mv -f ${EnviHdrToBeCopied} ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR}_TMP"_${RUNDATE}_${RNDM1}" 2>/dev/null	#  mute possible complaining message that permission can't be preserved, as it may occur when moving from Mac to Linux or Windows 
	#ln -s ${MASSPROCESSPATHLONG}/Geocoded/${TARGETDIR}/$(basename ${EnviHdrToBeCopied}) ${RUNDIR}/i12/GeoProjection/$(basename ${EnviHdrToBeCopied})
	EchoTee "*${IMG}*${MASDATE}_${SLVDATE}*deg.hdr copied to /Geocoded/${TARGETDIR}_TMP"_${RUNDATE}_${RNDM1}" "

	if [ "${FIG}" == "FIGyes" ] 
		then 
			RasToBeCopied=`ls ${MASSPROCESSPATHLONG}/GeocodedRasters/${TARGETDIR}/*${IMG}*${MASDATE}_${SLVDATE}*deg.ras | ${PATHGNU}/grep -v "_${COMMENT}"`
			mv -f ${RasToBeCopied} ${MASSPROCESSPATHLONG}/GeocodedRasters/${TARGETDIR}_TMP"_${RUNDATE}_${RNDM1}"
			EchoTee "*${IMG}*${MASDATE}_${SLVDATE}*deg.ras mv to /GeocodedRasters/${TARGETDIR}_TMP"_${RUNDATE}_${RNDM1}" "
	fi	
	}

function RemovePlaneCorrAtmo()
	{
	if [ "${PROCESSMODE}" != "TOPO" ] # not a good idea to remove plane for DEM because it would be set to sea level etc...
		then 
			# Remove best plane 
			bestPlaneRemoval2 ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt -create
	
			if [ ${INTERPOL} == "BEFORE" ] || [ ${INTERPOL} == "BOTH" ]
				then
					FILETODETREND=${RUNDIR}/i12/InSARProducts/deformationMap.interpolated_${ATMOCORR}
				else
					FILETODETREND=${RUNDIR}/i12/InSARProducts/deformationMap_${ATMOCORR}	
			fi
			EchoTee "Remove best plane from ${FILETODETREND}" 
			XDIMTODETREND=`GetParamFromFile "Deformation measurement range dimension [pix]" InSARParameters.txt`
			YDIMTODETREND=`GetParamFromFile "Deformation measurement azimuth dimension [pix]" InSARParameters.txt`
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt "File to be corrected" ${FILETODETREND} > /dev/null
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt "X dimension of the file to be corrected" ${XDIMTODETREND} > /dev/null
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt "Y dimension of the file to be corrected" ${YDIMTODETREND} > /dev/null
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt "Reference file path or NONE" "NONE" > /dev/null
			updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt "Threshold file" "NONE"  > /dev/null
	
			if [ "${PATHTODIREVENTSMASKS}" != "" ] 
				then 
					# Do not change Masking value: must be 0b00000101 for events mask
					updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt "Mask file" ${RUNDIR}/i12/InSARProducts/slantRangeMask > /dev/null
					updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt "X dimension of the mask file" ${XDIMTODETREND} > /dev/null
					updateParameterFile ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt "Y dimension of the mask file" ${YDIMTODETREND} > /dev/null
			fi
	
			bestPlaneRemoval2 ${RUNDIR}/i12/InSARProducts/bestPlaneRemoval_${ATMOCORR}.txt
	
			# make raster
			MakeFig ${XDIMTODETREND} 1.0 1.2 normal jet 1/1 r4 ${FILETODETREND}.flattened
	fi
	}		

function SortAtmoDefoFiles()
	{
		local SRCDIR SELECTED UNSELECTED FILE NAME DEST NMOVED NFAIL

		if [ $# -ne 3 ]; then
			echo "ERROR: SortAtmoDefoFiles needs 3 args: SRCDIR SELECTED UNSELECTED" >&2
			return 2
		fi
		SRCDIR="$1"
		SELECTED="$2"
		UNSELECTED="$3"

		# --- sanity checks ---------------------------------------------------
		if [ -z "${ATMOCORR}" ]; then
			echo "ERROR: ATMOCORR is empty; every file would match. Skipping." >&2
			return 1
		fi

		if [ ! -d "${SRCDIR}" ]; then
			echo "INFO: ${SRCDIR} does not exist; nothing to do."
			return 0
		fi

		if [ ! -d "${SELECTED}" ]; then
			echo "ERROR: destination folder ${SELECTED} does not exist." >&2
			return 1
		fi
		if [ ! -d "${UNSELECTED}" ]; then
			echo "ERROR: destination folder ${UNSELECTED} does not exist." >&2
			return 1
		fi

		# --- dispatch --------------------------------------------------------
		NMOVED=0
		NFAIL=0
		for FILE in "${SRCDIR}"/*; do
			[ -f "${FILE}" ] || continue		# skips dirs and unmatched glob
			NAME="${FILE##*/}"
			# whole tag, not substring: with ATMOCORR=GACOS, a *_GACOS* glob would also 
			# claim the GACOSIncidMapMEDIAN, GACOSIncidFixMEAN... versions as its own
			if HasAtmoTag "${NAME}" "${ATMOCORR}" 
				then DEST="${SELECTED}" 
				else DEST="${UNSELECTED}" 
			fi
			# The map being dispatched must keep its clean name (it is the one MSBAS will
			# invert), so any homonym already sitting in the destination - e.g. because the
			# script is run twice with the same COMMENT - is first renamed with
			# _${RUNDATE}_${RNDM1} instead of being crushed by "mv -f".
			StampAwayIfPresent "${DEST}" "${NAME}" || EchoTeeRed "WARNING: could not rename the former ${NAME} in ${DEST}"
			if mv -f -- "${FILE}" "${DEST}/${NAME}" ; then
				NMOVED=$((NMOVED + 1))
			else
				echo "WARNING: could not move ${NAME}" >&2
				NFAIL=$((NFAIL + 1))
			fi
		done

		if [ ${NMOVED} -eq 0 ] && [ ${NFAIL} -eq 0 ]; then
			echo "INFO: no files to sort in ${SRCDIR}."
		fi

		[ ${NFAIL} -eq 0 ] || return 1
		return 0
	}
	
# Return the pair directory located in $2 that corresponds to the pair described in $1.
# Handles both conventions:
#     20260418_20260512
#     S1D_88_20260418_A_S1D_88_20260512_A
function GetPairDir()
	{
	local PAIR="$1"
	local PARENT="$2"
	local MAS SLV CAND FOUND NB

	# First two 8-digit tokens of the pair string, whatever surrounds them.
	# tr splits on non-digits, grep -x keeps runs of exactly 8 digits
	# (so a track number or a longer numeric token can't be mistaken for a date).
	####set -- $(echo "${PAIR}" | tr -cs '0-9' '\n' | grep -Ex '[0-9]{8}' | head -2)
	####MAS="$1"
	####SLV="$2"
	DATES=$(GetPairDates "${PAIR}") || {
		echo "GetPairDir: cannot extract two dates from \"${PAIR}\"" >&2
		return 1
		}
	set -- ${DATES}			# unquoted on purpose: splits "MAS SLV"
	MAS="$1"
	SLV="$2"

	if [ -z "${MAS}" ] || [ -z "${SLV}" ] ; then
		echo "GetPairDir: cannot extract two dates from \"${PAIR}\"" >&2
		return 1
	fi

	FOUND=""
	NB=0
	for CAND in "${PARENT}"/*"${MAS}"*"${SLV}"* ; do
		[ -d "${CAND}" ] || continue		# skips the unmatched glob itself
		FOUND="${CAND}"
		NB=$(( NB + 1 ))
	done

	if [ ${NB} -eq 0 ] ; then
		echo "GetPairDir: no directory matching ${MAS} -> ${SLV} in ${PARENT}" >&2
		return 1
	fi
	if [ ${NB} -gt 1 ] ; then
		echo "GetPairDir: ${NB} directories match ${MAS} -> ${SLV} in ${PARENT}:" >&2
		ls -d "${PARENT}"/*"${MAS}"*"${SLV}"* >&2
		return 1
	fi

	echo "${FOUND}"
	}

# Echo "MAS SLV" for a pair name holding exactly two 8-digit date tokens.
# Returns 1 otherwise.
# Accepts   20260418_20260512
#     and   S1D_88_20260418_A_S1D_88_20260512_A
function GetPairDates()
	{
	local REST="${1##*/}_"		# basename only, trailing _ closes the last token
	local TOK NB=0 D1="" D2=""

	while [ -n "${REST}" ] ; do
		TOK="${REST%%_*}"
		REST="${REST#*_}"
		case "${TOK}" in
			[12][09][0-9][0-9][01][0-9][0-3][0-9])
				NB=$(( NB + 1 ))
				if   [ ${NB} -eq 1 ] ; then D1="${TOK}"
				elif [ ${NB} -eq 2 ] ; then D2="${TOK}"
				fi
				;;
		esac
	done

	[ ${NB} -eq 2 ] || return 1
	echo "${D1} ${D2}"
	}
	
# Do not perform ETAD and Mango corrections
###########################################
	if IsInList "${ATMOCORR}" "${AtmoCorrList[@]}" 
		then
			if [ "${SATDIR}" = "S1" ] && [ "${ETADPROD}" != "ETAD000" ] && [[ "${ETADPROD}" =~ ^ETAD([01]{3})?$ ]] ; then
					echo " Do not perform both ETAD and ${ATMOCORR} atmospheric correction "
					exit 1
			fi
		else
			echo " Not sure which atmospheric correction you want. Please choose $(IFS='|' ; echo "${AtmoCorrList[*]}") or adapt script if new method is allowed. "
			echo " Since I do not recognize the atmospheric correction method, I stop here for security."
			exit 1
	fi
	echo 


# Define SMCROPDIR, MASSPROCESSPATHLONG and GEOCDIR
#################################################
	# Define Super Master Crop Dir and place where original data are
	if [ ${CROP} == "CROPyes" ]
		then
			SMCROPDIR=SMCrop_SM_${SUPERMASTER}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}   #_Zoom${ZOOM}_ML${INTERFML}
		else
			SMCROPDIR=SMNoCrop_SM_${SUPERMASTER}  #_Zoom${ZOOM}_ML${INTERFML}
	fi

	MASSPROCESSPATHLONG="${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}"
	GEOCDIR="${MASSPROCESSPATHLONG}/Geocoded"


# Create log file
#################
	eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
	eval RNDM1=`echo $(( $RANDOM % 10000 ))`
	
	LOGFILE=${MASSPROCESSPATHLONG}/LogFile_ReDetrend_Geoc_${RUNDATE}_${RNDM1}.txt


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

# Check the method for Geocoding
################################
	if [ "${GEOCMETHD}" == "ClosestMassProc" ]
		then
			EchoTeeRed " OK you want to keep geocoded pixels as close as possible as original ones although you run a Mass Process."
			EchoTeeRed "   Be aware that you wan't be able to do MSBAS because other modes will be in different grid."
			EchoTeeRed "   It will be ok for a SBAS with only this mode though. You know what you are doing..."
			GEOCMETHD="Closest"
		else 
			if [ "${GEOCMETHD}" != "Forced" ] 
				then 
					EchoTeeRed "Geocoded pixels not forced to fixed grid. You wan't be able to run MSBAS. If you want it anyway, change GEOCMETHD to ClosestMassProc." 
					exit 1
				else  
					EchoTee "Fine, I will re-geocode with forced grid. "
					EchoTeeRed "HOPE YOU HAVE CHECKED THE SIZE OF YOUR GEOCODED PIXELS AND THE COORDINATES OF YOUR FINAL PRODUCTS' CORNERS." 
			fi
	fi
	echo 


# Search for dir where data are stored (eg to get the name of Super Master)
###########################################################################
	# Define Crop Dir
	if [ "${CROP}" == "CROPyes" ]
		then
			CROPDIR="/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}" #_Zoom${ZOOM}_ML${INTERFML}
		else
			CROPDIR="/NoCrop"
	fi
	
	INPUTDATA="${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}"		# needed to get AZ and RG sampling for instance 

# Check S1 mode and define SUPERMASNAME and SUPERMASDIR
#######################################################
	if [ "${SATDIR}" == "S1" ] 
		then  
			# need this definition here for usage in GetParamFromFile
			MASDIR=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${SUPERMASTER}` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
	
			S1ID=`GetParamFromFile "Scene ID" SAR_CSL_SLCImageInfo.txt`
			S1MODE=`echo ${S1ID} | cut -d _ -f 2`	
			if [ "${S1MODE}" == "IW" ] || [ "${S1MODE}" == "EW" ]
					then 
					if [ "${S1COREGMODE}" == "S1SM" ] 
						then 
							S1MODE="WSWATHSM"
 							USESM="Yes"
						else
							S1MODE="WIDESWATH"
							USESM="No"
					fi
					SUPERMASNAME=`ls ${INPUTDATA} | ${PATHGNU}/grep ${SUPERMASTER} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
				else 
					S1MODE="STRIPMAP"
					SUPERMASNAME=`echo ${MASDIR} | cut -d. -f1`		
 					USESM="Yes"
			fi
			EchoTee  "Processing S1 images in mode ${S1MODE}" 

			# S1 IW/EW CSL data are stored in NoCrop: the crop is applied later, at the
			# interferometric processing stage. INPUTDATA must point there, because
			# GetParamFromFile resolves SuperMaster_SLCImageInfo.txt to
			# ${INPUTDATA}/${SUPERMASDIR}/Info/SLCImageInfo.txt, which is read just below
			# to get the pixel size. Same rule as in Proj_AllFiles_in_SltRg.sh.
			if [ "${S1MODE}" == "WIDESWATH" ] || [ "${S1MODE}" == "WSWATHSM" ] ; then
				if [ "${CROPDIR}" != "/NoCrop" ] ; then
					EchoTee "S1 ${S1MODE}: CSL data are in NoCrop; forcing INPUTDATA to NoCrop."
					CROPDIR="/NoCrop"
					INPUTDATA="${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}"
				fi
			fi
 		else 
 			SUPERMASNAME="${SUPERMASTER}" 
 			USESM="Yes"
 	fi
 	if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]&& [ "${ZOOM}" != "1" ] ; then EchoTeeRed "Sentinel IW data processing only possible with zoom factor 1" ; exit 1 ; fi

	SUPERMASDIR="${SUPERMASNAME}".csl

# Compute pixel size
####################

	# Ratio must be computed after Crop and zoom to get info from zoom - NEED INPUTDATA and SUPERMASDIR
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

# Check DEM dir
###############
	if [ -d "${DEMDIR}" ]
		then
		   EchoTee "  // OK: a directory exist where DEM is supposed to be stored." 
		else
			DEMDIR="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$DEMDIR)"
			if [ -d "${DEMDIR}/" ]
				then
					EchoTee "  // Double mount of hp-storeesay. Renamed dir with -1"
				else 
					EchoTee " "
					EchoTee "  // NO expected DEM directory. Can't run..." 
					EchoTee "  // PLEASE REFER TO SCRIPT and  change hard link if needed"
					exit 1		
		   fi
	fi


# Check RESAMPLED dir, if needed
################################
	# Resampled data on SuperMaster in csl format are stored in 
	OUTPUTDATA="${RESAMPDATPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}"
	if [ -d "${OUTPUTDATA}" ]  # Path to dir where resampled data are stored.
		then
		   EchoTee "  // OK: a directory exist where Resampled data on Global Primary (SuperMaster) ${SUPERMASTER} are stored ." 
		   EchoTee "  //    They were most probably computed wth a script SuperMasterCoreg.sh"
		else
		   EchoTee " "
		   EchoTee "  // NO expected ${OUTPUTDATA} directory."
		   EchoTee "  // Can't run wthout these Resampled data on Global Primary (SuperMaster) ${MAS}" 
		   EchoTee "  // PLEASE REFER TO SCRIPT and  change hard link if needed,"
		   EchoTee "  // or run the appropriate script such as SuperMasterCoreg.sh "
		   exit 1
	fi

# Prepare processing dir
########################

# Get there 
	cd "${MASSPROCESSPATHLONG}"

# read the list of pairs and make it an array
	PairsArray=()
	while IFS= read -r line; do
	    PairsArray+=("$line")
	done < "${LISTPAIRS}"
	
# Format pair list to be in the form of yyyymmdd_yyyymmdd
	NormalizedPairs=()
	for raw in "${PairsArray[@]}"; do
	    # Extract two 8-digit numbers from the string
	    dates=($(${PATHGNU}/grep -oE '[0-9]{8}' <<< "$raw"))
	
	    if [[ ${#dates[@]} -eq 2 ]]; then
	        d1="${dates[0]}"
	        d2="${dates[1]}"
	        normalized="${d1}_${d2}"
	        NormalizedPairs+=("$normalized")
	    else
	        echo "Invalid pair format: $raw"
	    fi
	done
	
	# Replace original and ensure there is no duplicated lines 
	#PairsArray=("${NormalizedPairs[@]}")
	PairsArray=($(printf "%s\n" "${NormalizedPairs[@]}" | sort -u))

# Security check: 
#	- only reprocessing data with symetric zoom factor or geocoded pixel
#   - confirm (if you really want to) perform geocoding with different param from existing files 
################################################################################################

	# Read geocoding parameters from original files in first pair dir:
	# extract geocoded info from first pair
	RUNDIR="${MASSPROCESSPATHLONG}/${PairsArray[0]}" 	

	# in the case of S1, RUNDIR are MASNAME_SLVNAME instead of MASDATE_SLVDATE
	if [ "${SATDIR}" == "S1" ] 
		then 
			RUNDIR=$(GetPairDir "${PairsArray[0]}" "${MASSPROCESSPATHLONG}") || exit 1
			
			# Take the opportunity to crate a PairNameArray to be used here after 
			PairNameArray=()
			UnresolvedPairs=()
			
			for PAIR in "${PairsArray[@]}" ; do
				DIR=$(GetPairDir "${PAIR}" "${MASSPROCESSPATHLONG}") || DIR=""
				if [ -z "${DIR}" ] ; then
					PairNameArray+=("")				# keep indices aligned with PairsArray
					UnresolvedPairs+=("${PAIR}")
				else
					PairNameArray+=("${DIR##*/}")	# basename, without forking
				fi
				# Keep track of possible problems
				if [ ${#UnresolvedPairs[@]} -gt 0 ] ; then
					echo "WARNING: ${#UnresolvedPairs[@]} pair(s) without directory in ${MASSPROCESSPATHLONG}:" >&2
					printf '   %s\n' "${UnresolvedPairs[@]}" >&2
				fi
			done
			ARRAY=("${PairNameArray[@]}")
		else 
			ARRAY=("${PairsArray[@]}")
			
	fi 

	echo
	EchoTee " Checking new versus old geocoding parameters"
	EchoTee "**********************************************"
	
	# sampling
		ORIGXSAMP=$(GetParamFromFile "Easting sampling"  "geoProjectionParameters.txt")
		ORIGYSAMP=$(GetParamFromFile "Northing sampling"  "geoProjectionParameters.txt")	
		ORIGXYSAMP="${ORIGXSAMP}x${ORIGYSAMP}"

		# check zoom asymetry
		CheckZOOMasymetry
		
		# Read geocoding parameters from LaunchParam.txt file used for reprocessing 
		if [ "${ZOOMONEVAL}" = "One" ] 
			then 
				FORCEXYSAMP="${FORCEGEOPIXSIZE}x${FORCEGEOPIXSIZE}"
			else
		    	EchoTeeRed "Asymectric ZOOM factor or pixel size. Reprocessing of that kind of processing is not planned yet. Adapt script if needed one day... ; exiting"
				exit 1
		fi
			
		if [ "${ORIGXYSAMP}" == "${FORCEXYSAMP}" ]
			then 
				EchoTee " Same geocoding sampling"
				SAMEGEOC="Yes"
			else 
				EchoTeeRed " Not the same geocoding sampling !" 
				EchoTeeRed "    Original:	${ORIGXYSAMP}"
				EchoTeeRed "	New:	 	${FORCEXYSAMP}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
		fi

	# UTMZONE
		ORIGUTMZONE=$(GetParamFromFile "UTM zone : If defining an UTM area of interest by values, UTM zone can be forced."  "geoProjectionParameters.txt")	
		if [ "${ORIGUTMZONE}" == "${UTMZONE}" ]
			then 
				EchoTee " Same UTM zone"
				SAMEGEOC="Yes"
			else 
				if [ "${UTMZONE}" == "" ]
					then 
						EchoTee " No UTM zone defined. May not be a problem" 
						EchoTee "	Original:	${ORIGUTMZONE}"
						EchoTee "	New:	 	not defined - assume it will be the same"
						SAMEGEOC="Yes"
					
					else 
						EchoTeeRed " Not the same UTM zone !" 
						EchoTeeRed "    Original:	${ORIGUTMZONE}"
						EchoTeeRed "	New:	 	${UTMZONE}"
						ConfirmReprocessWithDiffParam
						SAMEGEOC="No"
				fi
		fi

	#RESAMPMETHD
		ORIGRESAMPMETHD=$(GetParamFromFile "Resampling method : TRI = Triangulation; AV = weighted average; NN = nearest neighbour"  "geoProjectionParameters.txt")	
		if [ "${ORIGRESAMPMETHD}" == "${RESAMPMETHD}" ]
			then 
				EchoTee " Same Resampling Method"
				SAMEGEOC="Yes"
			else 
				EchoTeeRed " Not the same Resampling Method !" 
				EchoTeeRed "    Original:	${ORIGRESAMPMETHD}"
				EchoTeeRed "	New:	 	${RESAMPMETHD}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
		fi
	
	#WEIGHTMETHD
		ORIGWEIGHTMETHD=$(GetParamFromFile "Weighting method : ID = inverse distance; LORENTZ = lorentzian"  "geoProjectionParameters.txt")	
		if [ "${ORIGWEIGHTMETHD}" == "${WEIGHTMETHD}" ]
			then 
				EchoTee " Same Weighting method"
				SAMEGEOC="Yes"
			else 
				EchoTeeRed " Not the same Weighting method !" 
				EchoTeeRed "    Original:	${ORIGWEIGHTMETHD}"
				EchoTeeRed "	New:	 	${WEIGHTMETHD}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
		fi
	
	#IDSMOOTH
		ORIGIDSMOOTH=$(GetParamFromFile "ID smoothing factor"  "geoProjectionParameters.txt")	
		if [ "${ORIGIDSMOOTH}" == "${IDSMOOTH}" ]
			then 
				EchoTee " Same ID smoothing factor"
				SAMEGEOC="Yes"
			else 
				EchoTeeRed " Not the same ID smoothing factor !" 
				EchoTeeRed "    Original:	${ORIGIDSMOOTH}"
				EchoTeeRed "	New:	 	${IDSMOOTH}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
		fi

	#IDWEIGHT
		ORIGIDWEIGHT=$(GetParamFromFile "ID weighting exponent"  "geoProjectionParameters.txt")	
		if [ "${ORIGIDWEIGHT}" == "${IDWEIGHT}" ]
			then 
				EchoTee " Same ID weighting exponent"
				if [ "${SAMEGEOC}" == "No" ] ; then
					# If No once, must keep No forever 
					SAMEGEOC="No"
				else 
					SAMEGEOC="Yes"
				fi
			else 
				EchoTeeRed " Not the same ID weighting exponent !" 
				EchoTeeRed "    Original:	${ORIGIDWEIGHT}"
				EchoTeeRed "	New:	 	${IDWEIGHT}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
		fi

	#FWHM
		ORIGFWHM=$(GetParamFromFile "FWHM : Lorentzian Full Width at Half Maximum"  "geoProjectionParameters.txt")	
		if [ "${ORIGFWHM}" == "${FWHM}" ]
			then 
				EchoTee " Same FWHM"
				if [ "${SAMEGEOC}" == "No" ] ; then
					# If No once, must keep No forever 
					SAMEGEOC="No"
				else 
					SAMEGEOC="Yes"
				fi
			else 
				EchoTeeRed " Not the same FWHM !" 
				EchoTeeRed "    Original:	${ORIGFWHM}"
				EchoTeeRed "	New:	 	${FWHM}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
		fi

	#ZONEINDEX
		ORIGZONEINDEX=$(GetParamFromFile "Zone index if [zoneMap] is selected for masking"  "geoProjectionParameters.txt")	
		if [ "${ORIGZONEINDEX}" == "${ZONEINDEX}" ]
			then 
				EchoTee " Same Zone index"
				if [ "${SAMEGEOC}" == "No" ] ; then
					# If No once, must keep No forever 
					SAMEGEOC="No"
				else 
					SAMEGEOC="Yes"
				fi
			else 
				EchoTeeRed " Not the same Zone index !" 
				EchoTeeRed "    Original:	${ORIGZONEINDEX}"
				EchoTeeRed "	New:	 	${ZONEINDEX}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
		fi

	#ETADGEOC
		# Check that ${MASSPROCESSPATHLONG} contains SAR_MASSPROCESS_ETAD
		if [ "${SATDIR}" == "S1" ] ; then 
			if echo "$MASSPROCESSPATHLONG" | "${PATHGNU}/grep" -qw "SAR_MASSPROCESS_ETAD"
				then 
					ORIGETADGEOC="ETADGEOCyes"
				else 
					ORIGETADGEOC="ETADGEOCno"
			fi
			
			
			if [ "${ETADGEOC}" == "${ORIGETADGEOC}" ] 
				then 
					EchoTee " Request Re-Geocoding with same ETAD option"
					if [ "${SAMEGEOC}" == "No" ] ; then
						# If No once, must keep No forever 
						SAMEGEOC="No"
					else 
						SAMEGEOC="Yes"
					fi
				else 
					EchoTeeRed " Request Re-Geocoding with different ETAD option !" 
					EchoTeeRed "    Original:	${ORIGETADGEOC}"
					EchoTeeRed "	New:	 	${ETADGEOC}"
					ConfirmReprocessWithDiffParam
					SAMEGEOC="No"
			fi
		fi
	
	#XMIN, XMAX, YMIN, YMAX or GEOCKML
		ORIGXMIN=$(GetParamFromFile "xMin"  "geoProjectionParameters.txt")	
		ORIGXMAX=$(GetParamFromFile "xMax"  "geoProjectionParameters.txt")	
		ORIGYMIN=$(GetParamFromFile "yMin"  "geoProjectionParameters.txt")	
		ORIGYMAX=$(GetParamFromFile "yMax"  "geoProjectionParameters.txt")	
		
		ORIGGEOCKML=$(GetParamFromFile "Path to a kml file defining the geoProjection area"  "geoProjectionParameters.txt")	

		if  [ -f "${ORIGGEOCKML}" ] && [ ! -f "${GEOCKML}" ]
			then 
				# you were using kml and now request UTM
				EchoTeeRed " You were geocoding based on a kml and now request UTM coordinates !" 
				EchoTeeRed "    Original kml:	${ORIGGEOCKML}"
				EchoTeeRed "	New UTM coord:	${XMIN}	${XMAX}	${YMIN}	${YMAX}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
			
			elif [ ! -f "${ORIGGEOCKML}" ] && [ -f "${GEOCKML}" ] ; then
				# you were using UTM and now request kml
				EchoTeeRed " You were geocoding based on UTM coordinates and now request kml !" 
				EchoTeeRed "    Original UTM coord:	${ORIGXMIN}	${ORIGXMAX}	${ORIGYMIN}	${ORIGYMAX}"
				EchoTeeRed "	New kml:	${GEOCKML}"
				ConfirmReprocessWithDiffParam
				SAMEGEOC="No"
		
			elif [ ! -f "${GEOCKML}" ] && [ ! -f "${ORIGGEOCKML}" ] ; then
				# you were using UTM and want again UTM
				if [ "${ORIGXMIN}" == "${XMIN}" ] && [ "${ORIGXMAX}" == "${XMAX}" ] && [ "${ORIGYMIN}" == "${YMIN}" ] && [ "${ORIGYMAX}" == "${YMAX}" ] 
					then 
						EchoTee " Same Forced UTM coordinates"
						if [ "${SAMEGEOC}" == "No" ] ; then
							# If No once, must keep No forever 
							SAMEGEOC="No"
						else 
							SAMEGEOC="Yes"
						fi
					else 
						# may differ max-xmin is not an integer multiple of FORCEGEOPIXSIZE 
						# (same in Y direction), but it would not mean that it is a different geocoding param 
						# Check that: 

						TESTSAMEGEOC=$(
						${PATHGNU}/gawk -v xmin="$XMIN" -v xmax="$XMAX" \
						   				-v ymin="$YMIN" -v ymax="$YMAX" \
						   				-v oxmin="$ORIGXMIN" -v oxmax="$ORIGXMAX" \
						   				-v oymin="$ORIGYMIN" -v oymax="$ORIGYMAX" \
						   				-v tol="$FORCEGEOPIXSIZE" '
						function abs(x) { return x < 0 ? -x : x }
						
						BEGIN {
						    # Tolerant comparison for origins
						    if (abs(xmin - oxmin) > tol || abs(ymin - oymin) > tol) {
						        print "no"
						        exit
						    }
						
						    # Width differences
						    dx = abs((xmax - xmin) - (oxmax - oxmin))
						    dy = abs((ymax - ymin) - (oymax - oymin))
						
						    if (dx > tol || dy > tol)
						        print "no"
						    else
						        print "yes"
						}')
						
						if [ "${TESTSAMEGEOC}" = "yes" ]; then
							EchoTee " Same Forced UTM coordinates (+- fraction of a pixel)"
							EchoTee "	Original:	${ORIGXMIN}	${ORIGXMAX}	${ORIGYMIN}	${ORIGYMAX}"
							EchoTee "	New:	 	${XMIN}	${XMAX}	${YMIN}	${YMAX}"
							EchoTee "	Tolerance of difference: $FORCEGEOPIXSIZE (FORCEGEOPIXSIZE)"

							if [ "${SAMEGEOC}" == "No" ] ; then
								# If No once, must keep No forever 
								SAMEGEOC="No"
							else 
								SAMEGEOC="Yes"
							fi
						else
							EchoTeeRed " Not the same Forced UTM coordinates !" 
							EchoTeeRed "	Original:	${ORIGXMIN}	${ORIGXMAX}	${ORIGYMIN}	${ORIGYMAX}"
							EchoTeeRed "	New:	 	${XMIN}	${XMAX}	${YMIN}	${YMAX}"
							ConfirmReprocessWithDiffParam
							SAMEGEOC="No"
						fi
						
				fi
			else # i.e. [ -f "${GEOCKML}" ] && [ -f "${ORIGGEOCKML}" ]
				# you were using kml and want again kml
				if [ "${ORIGGEOCKML}" == "${GEOCKML}" ] 
					then 
						EchoTee " Same Forced kml"
						if [ "${SAMEGEOC}" == "No" ] ; then
							# If No once, must keep No forever 
							SAMEGEOC="No"
						else 
							SAMEGEOC="Yes"
						fi
					else 
						EchoTeeRed " Not the same Forced kml !" 
						EchoTeeRed "    Original:	${ORIGGEOCKML}"
						EchoTeeRed "	New:	 	${GEOCKML}"
						ConfirmReprocessWithDiffParam
						SAMEGEOC="No"
				fi
		fi

echo	

# Reprocess each pair
#####################

# in "${MASSPROCESSPATHLONG}"
for dir in */; do
    PAIRDIR="${dir%/}"			# List directories of pairs already processed

    ### Skip dirs not matching *yyyymmdd*_*yyyymmdd* pattern
    ##[[ "$PAIRDIR" =~ [0-9]{8}_[0-9]{8} ]] || continue
	# Skip dirs that are neither yyyymmdd_yyyymmdd nor S1name_S1name
	GetPairDates "${PAIRDIR}" >/dev/null 2>&1 || continue
	
	i=1
	
#    for pair in "${PairsArray[@]}"; do
	 for pair in "${ARRAY[@]}"; do
        IFS=_ read -r d1 d2 <<< "${pair}"		# for each pair in list of pairs to be reprocessed processed

        if [[ "${PAIRDIR}" == *"$d1"* && "${PAIRDIR}" == *"$d2"* ]]
        	then		# works for both d1_d2 or d2_d1 
				echo "  // === Processing ${PAIRDIR} (match: ${pair}), that is pair $i/${#PairsArray[@]} ==="
				echo
				# Prepare the pair
				##################
					RUNDIR="${MASSPROCESSPATHLONG}/${PAIRDIR}" 		# differs from normal mass processing as it is now in SAR_MASSPROCCESS/PAIR dir 
	
					# Rename path in parameters files in pair dirs 
						cd "${MASSPROCESSPATHLONG}/${PAIRDIR}/i12/TextFiles"
	
						RenamePath_Volumes.sh "${MASSPROCESSPATHLONG}/${PAIRDIR}" # MUST BE RUN BEFORE THE gsed lines below !!
	
						if [ ! -e InSARParameters_original.txt ] ; then cp InSARParameters.txt InSARParameters_original.txt ; fi 
						if [ ! -e geoProjectionParameters_original.txt ] ; then cp geoProjectionParameters.txt geoProjectionParameters_original.txt ; fi 
						${PATHGNU}/gsed "s%^.*/${PAIRDIR}/%${MASSPROCESSPATHLONG}/${PAIRDIR}/%g" InSARParameters_original.txt > InSARParameters.txt
						${PATHGNU}/gsed "s%^.*/${PAIRDIR}/%${MASSPROCESSPATHLONG}/${PAIRDIR}/%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt
    	
					
					cd "${MASSPROCESSPATHLONG}/${PAIRDIR}/i12/InSARProducts" 
		
#					# backup InSARProducts (if exist) with leading original_ (to prevent re-geocoding of old files)
#					backup_original "${RUNDIR}/i12/InSARProducts/bestPlaneRemoval.txt"  
#		
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap"
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap.ras"
#		
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap.interpolated"
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap.interpolated.ras"
#		
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap.interpolated.flattened"
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap.interpolated.flattened.ras"
#	
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap_${ATMOCORR}"
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap_${ATMOCORR}.ras"
#	
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap.interpolated_${ATMOCORR}"
#					backup_original "${RUNDIR}/i12/InSARProducts/deformationMap.interpolated_${ATMOCORR}.ras"
	
					# In case other atmo corr were already performed with another method, 
					# move them to a PARKDIR_TMP dir to avoid re-geocoding them. 
					# This is done by searching those that carry, as a WHOLE TAG, one method 
					# listed in the array AtmoCorrList, except the one that is ATMOCORR.
					# They are moved back from the TMP dir after.
					#
					# The products of the CURRENT correction are excluded FIRST and explicitly: 
					# they are the ones to detrend and to geocode. Testing the other tags with a 
					# substring glob (*"${CORR}"*) was parking them as well as soon as another 
					# tag of AtmoCorrList was a prefix of ATMOCORR (GACOS vs GACOSIncidMapMEDIAN), 
					# leaving bestPlaneRemoval2 without input file.
						PARKDIR_TMP="${RUNDIR}/i12/OtherProcessing_tmp" 
						mkdir -p "${PARKDIR_TMP}"
						
						for f in "${RUNDIR}"/i12/InSARProducts/deformationMap*; do
							[ -e "$f" ] || continue
							HasAtmoTag "$f" "${ATMOCORR}" && continue		# keep current ATMOCORR
							for CORR in "${AtmoCorrList[@]}"; do
								[ "${CORR}" = "${ATMOCORR}" ] && continue	# ignore current ATMOCORR
								if HasAtmoTag "$f" "${CORR}"				# mv all other atmo corr
									then 
										mv -f -- "$f" "${PARKDIR_TMP}" 
										break 
								fi
							done
						done
	
				# Detrend  
				#########
					if [ "${REMOVEPLANE}" == "DETREND" ] 
						then 
							EchoTee "You request (re)detrending. \n" 
							# No need to remove place from original deformationMap
							# RemovePlane
							RemovePlaneCorrAtmo
							
						else 
							EchoTee "You did not request (re)detrending. \n" 
					fi
     			echo  	
				
				# Re-geocode
				############
        	   		# Supposedly all is geocoded but the defo detrended (and interpolated if applicable) 
							#  SLRDEM, MASAMPL, SLVAMPL, COH, INTERF, FILTINTERF, RESINTERF, UNWPHASE
					FILESTOGEOC=`echo "YES NO NO NO NO NO NO NO"`
	
					# change in geoProjectionParameters.txt and InSARParameters.txt 
					#  all path that contains PROCESS and /i12/ to $RUNDIR before /i12/ 
					#  and backup original file with .BeforeReGeoc_${COMMENT}.txt
					if [ ! -f "${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt.BeforeReGeoc_${COMMENT}.txt" ] ; then ${PATHGNU}/gsed -i.BeforeReGeoc_"${COMMENT}".txt "s|^.*/PROCESS/.*\(/i12/.*\)|${RUNDIR}\1|" "${RUNDIR}/i12/TextFiles/geoProjectionParameters.txt" ; fi
					if [ ! -f "${RUNDIR}/i12/TextFiles/InSARParameters.txt.BeforeReGeoc_${COMMENT}.txt" ] ; then ${PATHGNU}/gsed -i.BeforeReGeoc_"${COMMENT}".txt "s|^.*/PROCESS/.*\(/i12/.*\)|${RUNDIR}\1|" "${RUNDIR}/i12/TextFiles/InSARParameters.txt" ; fi
					
					# Need pixel size computed above
					cd "${RUNDIR}"/i12
					if [ "${SAMEGEOC}" == "Yes" ] 
						then 
							# Because geocoding parameters are unchanged, no need to recompute geocoding of former deformationMap, deformationMap.interpolated and deformationMap.interpolated.flattened  
							# Note that these FILES are already backed up as /original_before_${COMMENT}_FILES
								PARKDIR_TMP="${RUNDIR}/i12/OtherProcessing_tmp" 
								mkdir -p "${PARKDIR_TMP}"

								# BEWARE, to geocode deformationMap products, the file deformationMap MUST be in ${RUNDIR}/i12/InSARProducts, because it gets the dimensions of the defo files from that one 
								#mv "${RUNDIR}"/i12/InSARProducts/deformationMap "${PARKDIR_TMP}"/ 2>/dev/null		# NEEDED TO INITIATE THE GEOCIDING OF ALL FILES STARTING BY deformationMap
								mv "${RUNDIR}"/i12/InSARProducts/deformationMap.interpolated "${PARKDIR_TMP}" 2>/dev/null
								mv "${RUNDIR}"/i12/InSARProducts/deformationMap.interpolated.flattened "${PARKDIR_TMP}" 2>/dev/null
								#mv "${RUNDIR}"/i12/InSARProducts/original_before_"${COMMENT}"_* "${PARKDIR_TMP}" 2>/dev/null
								
							GeocUTM ${FILESTOGEOC}

							# Keep track of version
							echo "Last created AMSTer Engine source dir suggest projecting Re-Geocoding with AE version: ${LASTVERSIONMT}" > "${RUNDIR}"/i12/ReGeoc_w_AMSTerEngine_V.txt

						else 
							# Because geocoding parameters differ from original processing, one need to recompute geocoding of former deformationMap, deformationMap.interpolated and deformationMap.interpolated.flattened  
							# Note that these FILES are already backed up as /original_before_${COMMENT}_FILES
							# Other atmo corr processings, if any, are already removed in PARKDIR_TMP
							GeocUTM ${FILESTOGEOC}

							# Keep track of version
							echo "Last created AMSTer Engine source dir suggest projecting Re-Geocoding with AE version: ${LASTVERSIONMT}" > "${RUNDIR}"/i12/ReGeoc_w_AMSTerEngine_V.txt
					fi 
					
					# Restore backud up former atmo corr
						for f in "${PARKDIR_TMP}"/*; do
							[ -e "$f" ] || continue
							mv -f -- "$f" "${RUNDIR}/i12/InSARProducts/"
						done
						rmdir "${PARKDIR_TMP}" 2>/dev/null		# only removes it if empty

				# Re-interpol after geoc (if needed)
				####################################
					cd "${RUNDIR}"/i12/GeoProjection
					
					# get size of geocoded product
					GEOPIXW=`GetParamFromFile "X size of geoprojected products" geoProjectionParameters.txt`
 					GEOPIXL=`GetParamFromFile "Y size of geoprojected products" geoProjectionParameters.txt`	
		
 					case ${INTERPOL} in 
						"AFTER")  
							if [ ${REMOVEPLANE} == "DETREND" ] 
									then 
										EchoTee "Request interpolation of _ATMOCORR flattened defo map after geocoding."
										PATHDEFOGEOMAP=deformationMap_${ATMOCORR}.flattened.${PROJ}.${GEOPIXSIZENAME}.bil
										fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
	
										if [ "${SAMEGEOC}" == "No" ]
											then 
												EchoTee "Also perform interpolation of former flattened defo maps after geocoding because geocoding parameters have changed."
												PATHDEFOGEOMAP=deformationMap.flattened.${PROJ}.${GEOPIXSIZENAME}.bil
												fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
										fi
									else 
										EchoTee "Request interpolation of _ATMOCORR defo map after geocoding."
										PATHDEFOGEOMAP=deformationMap_${ATMOCORR}.${PROJ}.${GEOPIXSIZENAME}.bil
										fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
										#PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZENAME}.bil.interpolated	
	
										if [ "${SAMEGEOC}" == "No" ] 
											then 
												EchoTee "Request interpolation of former defo map after geocoding because geocoding parameters have changed."
												PATHDEFOGEOMAP=deformationMap.${PROJ}.${GEOPIXSIZENAME}.bil
												fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}   
										fi
	
							fi ;;
						"BOTH")  
							if [ ${REMOVEPLANE} == "DETREND" ] 
									then 
										EchoTee "Request interpolation of _ATMOCORR interpolated flattened defo map after geocoding."
										PATHDEFOGEOMAP=deformationMap.interpolated_${ATMOCORR}.flattened.${PROJ}.${GEOPIXSIZENAME}.bil
										fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
										if [ "${SAMEGEOC}" == "No" ] 
											then 
												EchoTee "Also perform interpolation of former interpolated flattened defo maps after geocoding because geocoding parameters have changed."
												PATHDEFOGEOMAP=deformationMap.interpolated.flattened.${PROJ}.${GEOPIXSIZENAME}.bil
												fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
											
										fi
			
									else 
										EchoTee "Request interpolation of _ATMOCORR interpolated defo map after geocoding."
										PATHDEFOGEOMAP=deformationMap.interpolated_${ATMOCORR}.${PROJ}.${GEOPIXSIZENAME}.bil
										fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
										if [ "${SAMEGEOC}" == "No" ] 
											then 
												EchoTee "Also perform interpolation of former interpolated defo maps after geocoding because geocoding parameters have changed"
												PATHDEFOGEOMAP=deformationMap.interpolated.${PROJ}.${GEOPIXSIZENAME}.bil
												fillGapsInImage ${RUNDIR}/i12/GeoProjection/${PATHDEFOGEOMAP} ${GEOPIXW} ${GEOPIXL}
										fi
			
							fi ;;
						"BEFORE") 
							EchoTee "Do not request interpolation after geocoding" 
			
							;;		
					esac
  	
  				# Backup existing geocoded deformation plots (with leading original_) 
  				#####################################################################
				
				cd ${RUNDIR}/i12/GeoProjection/
				
					for f in deformationMap*.ras; do
					    [[ -e "$f" ]] || continue   # protects if no match
					    mv -- "$f" "original_before_${COMMENT}_$f"
					done
 				
				# Plot new geocoded products 
				############################
					PlotGeoc ${FILESTOGEOC}
	
				          
				# Rename and move new geocoded products
				#######################################
					# rename all geocoded products as ${FILENOEXT}_${SATDIR}_${AD}${LOOK}_${TRKDIR}_${MAS}_${SLV}_${Bp}m_${HA}m_${BT}days_${HEADING}deg.${FILEEXT}	
					GetSatOrbDetails
	
	
					MASDATE=`GetParamFromFile "Acquisition date" masterSLCImageInfo.txt`
					SLVDATE=`GetParamFromFile "Acquisition date" slaveSLCImageInfo.txt`
	
					RenameNewDefoProducts
		
 	
				# Backup old geocoded files and move new ones
				#############################################
				# need some param
					# GEOPIXSIZENAME is defined in GeocUTM (i.e. pix size in Rg x Az)
					POLMAS=`GetParamFromFile "Master polarization channel" InSARParameters.txt`
					POLSLV=`GetParamFromFile "Slave polarization channel" InSARParameters.txt`
				
				# ETADPROD correction shouldn't happen here though...
				if [ ${SATDIR} == "S1" ] && [[ "${ETADPROD}" =~ ^(ETAD|ETAD111|ETAD110|ETAD101|ETAD011|ETAD001|ETAD010|ETAD100)$ ]] 
					then
						POSTFIX=".UTM.${GEOPIXSIZENAME}.${ETADPROD}.bil"
						POSTFIX2=".UTM.${GEOPIXSIZENAME}.bil.${ETADPROD}"						# needed for compatibility in fct below when using ETAD
						
						POLPOSTFIX=".${POLMAS}-${POLSLV}.UTM.${GEOPIXSIZENAME}.${ETADPROD}.bil"
						POLPOSTFIXFILT=".${POLMAS}-${POLSLV}.f.UTM.${GEOPIXSIZENAME}.${ETADPROD}.bil"		
					else 
						POSTFIX=".UTM.${GEOPIXSIZENAME}.bil"
						POSTFIX2="${POSTFIX}"						# needed for compatibility in fct below when using ETAD
						
						POLPOSTFIX=".${POLMAS}-${POLSLV}.UTM.${GEOPIXSIZENAME}.bil"
						POLPOSTFIXFILT=".${POLMAS}-${POLSLV}.f.UTM.${GEOPIXSIZENAME}.bil"		
				fi

				# vvvvvvvvvvvvvv Mode table vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
				# Mode ranking, HIGHEST PRIORITY FIRST. This array IS the priority: no other
				# part of the script depends on the order in which the modes are tested.
				#   MODEPREFIX[i]     = geocoded file prefix of the ${ATMOCORR} CORRECTED product
				#   MODEPREFIXORIG[i] = same for the UNCORRECTED product
				# Both are also what MoveGeocRename / BackupGeocOrig expect as first argument.
				#
				# The prefixes follow what actually produces the files:
				#   - bestPlaneRemoval2 writes <file>.flattened, and RemovePlaneCorrAtmo detrends
				#     deformationMap_${ATMOCORR} (or deformationMap.interpolated_${ATMOCORR} when
				#     INTERPOL is BEFORE/BOTH), so the detrended name is
				#     deformationMap_${ATMOCORR}.flattened, NOT deformationMap.flattened_${ATMOCORR}
				#   - fillGapsInImage (INTERPOL AFTER/BOTH) appends .interpolated to the geocoded name
				#   - RenameNewDefoProducts then appends _${SATDIR}_${TRKDIR}-...deg
				#
				# WARNING: Defo MUST stay last. Its prefix would otherwise also match the
				# "interpolated after geocoding" products, which are moved away by the rows above.
				############################################################################
				MODE=( \
					"DefoInterpolx2Detrend" \
					"DefoInterpolDetrend" \
					"DefoDetrend" \
					"DefoDetrend" \
					"DefoInterpolx2" \
					"DefoInterpol" \
					"DefoInterpol" \
					"Defo" )

				MODEPREFIX=( \
					"deformationMap.interpolated_${ATMOCORR}.flattened${POSTFIX2}.interpolated_" \
					"deformationMap.interpolated_${ATMOCORR}.flattened${POSTFIX}_" \
					"deformationMap_${ATMOCORR}.flattened${POSTFIX}.interpolated_" \
					"deformationMap_${ATMOCORR}.flattened${POSTFIX}_" \
					"deformationMap.interpolated_${ATMOCORR}${POSTFIX}.interpolated_" \
					"deformationMap.interpolated_${ATMOCORR}${POSTFIX}_" \
					"deformationMap_${ATMOCORR}${POSTFIX}.interpolated_" \
					"deformationMap_${ATMOCORR}${POSTFIX}_" )

				MODEPREFIXORIG=( \
					"deformationMap.interpolated.flattened${POSTFIX2}.interpolated_" \
					"deformationMap.interpolated.flattened${POSTFIX}_" \
					"deformationMap.flattened${POSTFIX}.interpolated_" \
					"deformationMap.flattened${POSTFIX}_" \
					"deformationMap.interpolated${POSTFIX}.interpolated_" \
					"deformationMap.interpolated${POSTFIX}_" \
					"deformationMap${POSTFIX}.interpolated_" \
					"deformationMap${POSTFIX}_" )
				# ^^^^^^^^^^^^^^ Mode table ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

				# Create the temporary dirs of one mode, in both trees. BackupGeocOrig and
				# MoveGeocRename move the .ras as well, so GeocodedRasters must exist too,
				# otherwise their mv fails and set -e kills the whole run.
				MkModeTmpDirs()
					{
					mkdir -p "${MASSPROCESSPATHLONG}/Geocoded/$1_TMP_${RUNDATE}_${RNDM1}"
					mkdir -p "${MASSPROCESSPATHLONG}/GeocodedRasters/$1_TMP_${RUNDATE}_${RNDM1}"
					}

				# Move EVERY already existing geocoded version of the current pair out of
				# /Geocoded/<MODE> and /GeocodedRasters/<MODE> into <MODE>_TMP_..., so that they
				# all take part in the comparison. "Every version" means: the uncorrected map,
				# but also a map corrected with ANOTHER method during a previous run, since the
				# winner of the previous run is what sits in /Geocoded/<MODE>.
				# No file name prefix is used on purpose: the mode is the directory, so any file
				# of that pair found in it is by definition a version of that mode. Matching a
				# prefix built without ${ATMOCORR} missed every already corrected version, which
				# left one single candidate in the _TMP dir and nothing for _UnselectedVersions.
				BackupAllVersionsOfPair()
					{
					local MODEI="$1"
					local TREE SRC FILE NAME BARE TMPDIRMODE TMPREF TARGETNAME NEWNAMES NB NDUP

					NB=0
					NDUP=0
					# The new maps are already in the _TMP dirs (GatherModesInTmp ran first), so a
					# name clash is DETECTED, not guessed: the former version of a map that has
					# just been recomputed is simply the one whose name is already taken there.
					# Testing the name instead of testing the presence of _${ATMOCORR} in it is what
					# makes this reliable: any naming subtlety (ETAD products, POSTFIX, a correction
					# whose name is a substring of another one...) is covered by construction.
					TMPREF="${MASSPROCESSPATHLONG}/Geocoded/${MODEI}_TMP_${RUNDATE}_${RNDM1}"

					# The list of the names just geocoded is established BEFORE moving anything:
					# testing the _TMP dir on the fly would be wrong, because the dir is being
					# filled by this very loop. A former uncorrected map moved in at the beginning
					# would then make its own .hdr look like a duplicate, and the ENVI pair would
					# end up with one file tagged and the other not.
					# The names produced by AMSTer never contain a space, so a space separated
					# list is enough here (and works with bash 3.2, unlike associative arrays).
					NEWNAMES=" "
					for FILE in "${TMPREF}"/*deg ; do
						[ -f "${FILE}" ] || continue
						NEWNAMES="${NEWNAMES}${FILE##*/} "
					done

					for TREE in Geocoded GeocodedRasters ; do
						SRC="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}"
						[ -d "${SRC}" ] || continue
						TMPDIRMODE="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}_TMP_${RUNDATE}_${RNDM1}"
						# three disjoint globs: the ENVI file, its header, and the raster
						for FILE in "${SRC}"/*"${MASDATE}_${SLVDATE}"*deg \
						            "${SRC}"/*"${MASDATE}_${SLVDATE}"*deg.hdr \
						            "${SRC}"/*"${MASDATE}_${SLVDATE}"*deg.ras ; do
							[ -f "${FILE}" ] || continue
							NAME="${FILE##*/}"
							MkModeTmpDirs "${MODEI}"

							# The decision is taken on the ENVI binary of the family and applied to
							# its .hdr and .ras, so that the three files keep matching names.
							BARE="${NAME%.hdr}"
							BARE="${BARE%.ras}"

							case "${NEWNAMES}" in
								*" ${BARE} "*)
									# A map of that exact name has just been recomputed: keep this
									# former version under the tag _DUPLICATE_${RUNDATE}_${RNDM1};
									# ResolveDuplicateVersions will arbitrate between the two.
									TARGETNAME="$(InsertBeforeExtension "${NAME}" "_DUPLICATE_${RUNDATE}_${RNDM1}")"
									if MoveAsWithoutOverwriting "${FILE}" "${TMPDIRMODE}" "${TARGETNAME}"
										then NDUP=$((NDUP + 1))
										else EchoTeeRed "	could not back up ${NAME} from ${TREE}/${MODEI}"
									fi
									;;
								*)
									# No homonym: the former version keeps its name and takes part in
									# the general comparison, as any other version of that mode.
									if MoveAsWithoutOverwriting "${FILE}" "${TMPDIRMODE}" "${NAME}"
										then NB=$((NB + 1))
										else EchoTeeRed "	could not back up ${NAME} from ${TREE}/${MODEI}"
									fi
									;;
							esac
						done
					done

					if [ ${NB} -gt 0 ] ; then
						EchoTee "	${MODEI}: ${NB} former file(s) of ${MASDATE}_${SLVDATE} backed up in the _TMP dir"
					fi
					if [ ${NDUP} -gt 0 ] ; then
						EchoTee "	${MODEI}: ${NDUP} former file(s) of ${MASDATE}_${SLVDATE} carry the SAME NAME as a map"
						EchoTee "		recomputed now; backed up with the tag _DUPLICATE_${RUNDATE}_${RNDM1}"
					fi
					}

				# Rename the whole family of a geocoded product inside the _TMP dirs of the mode
				# $1: the ENVI file, its .hdr (in /Geocoded) and its .ras (in /GeocodedRasters).
				#	$2 = bare name to rename (bare = without the .hdr / .ras extension)
				#	$3 = new bare name
				RenameProductFamily()
					{
					local MODEI="$1"
					local FROM="$2"
					local TO="$3"
					local TREE DIR EXT

					for TREE in Geocoded GeocodedRasters ; do
						DIR="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}_TMP_${RUNDATE}_${RNDM1}"
						[ -d "${DIR}" ] || continue
						for EXT in "" ".hdr" ".ras" ; do
							[ -f "${DIR}/${FROM}${EXT}" ] || continue
							mv -f -- "${DIR}/${FROM}${EXT}" "${DIR}/${TO}${EXT}" || return 1
						done
					done
					return 0
					}

				# Move the whole family of the bare name $2 out of the _TMP dirs of the mode $1,
				# into <MODE>$3 of the corresponding tree (/Geocoded and /GeocodedRasters).
				MoveProductFamily()
					{
					local MODEI="$1"
					local BARENAME="$2"
					local DESTSUF="$3"
					local TREE SRC DST EXT

					for TREE in Geocoded GeocodedRasters ; do
						SRC="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}_TMP_${RUNDATE}_${RNDM1}"
						DST="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}${DESTSUF}"
						[ -d "${SRC}" ] || continue
						for EXT in "" ".hdr" ".ras" ; do
							[ -f "${SRC}/${BARENAME}${EXT}" ] || continue
							MoveWithoutOverwriting "${SRC}/${BARENAME}${EXT}" "${DST}" No || return 1
						done
					done
					return 0
					}

				# Remove the whole family of the bare name $2 in the _TMP dirs of the mode $1.
				RemoveProductFamily()
					{
					local MODEI="$1"
					local BARENAME="$2"
					local TREE DIR EXT

					for TREE in Geocoded GeocodedRasters ; do
						DIR="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}_TMP_${RUNDATE}_${RNDM1}"
						[ -d "${DIR}" ] || continue
						for EXT in "" ".hdr" ".ras" ; do
							rm -f -- "${DIR}/${BARENAME}${EXT}"
						done
					done
					}

				# Arbitrate between the two versions of the same map that carry the same name:
				# the FORMER one, parked by BackupAllVersionsOfPair in the _TMP dir with the tag
				# _DUPLICATE_${RUNDATE}_${RNDM1}, and the NEW one that has just been recomputed
				# with the same ${ATMOCORR} method and sits there with the clean name.
				#	$1 = mode
				#	$2 = suffix of the dir receiving the loser (e.g. "_UnselectedVersions")
				#
				# Four situations:
				#	- no clean counterpart (that mode was not recomputed): the tag is simply
				#	  removed and the former map takes part in the normal comparison, as usual
				#	- the two files are byte identical: the former one brings nothing, it is removed
				#	- they differ: Select_BestVersion.py arbitrates between the two of them only.
				#	  The winner keeps (or receives) the CLEAN name and goes on with the normal
				#	  dispatching, so that /Geocoded/<MODE> holds one single untagged map per pair.
				#	  The loser gets the _DUPLICATE_${RUNDATE}_${RNDM1} tag and is archived at once
				#	  in <MODE>$2: when the FORMER map wins, the tag is therefore moved from one
				#	  file to the other.
				#	- Select_BestVersion.py cannot decide: the new map is kept as the winner (the
				#	  script was launched to recompute it) and a warning is issued.
				ResolveDuplicateVersions()
					{
					# no "unset" of the two names below: "local" is enough, and unsetting them
					# would also destroy a variable of the same name held by the caller
					local MODEI="$1"
					local SUFOTHER="$2"
					local DUPTAG SRCENVI DUPFILE DUPBARE CLEANBARE CLEANFILE
					local SCRATCH CSVDIR SELECTLIST BESTNAME RCDUP EXT

					DUPTAG="_DUPLICATE_${RUNDATE}_${RNDM1}"
					SRCENVI="${MASSPROCESSPATHLONG}/Geocoded/${MODEI}_TMP_${RUNDATE}_${RNDM1}"
					[ -d "${SRCENVI}" ] || return 0

					# the tag is inserted before the extension, so this glob matches the ENVI
					# binaries only, not their .hdr; the companions follow their binary.
					for DUPFILE in "${SRCENVI}"/*"${DUPTAG}" ; do
						[ -f "${DUPFILE}" ] || continue		# unmatched glob
						DUPBARE="${DUPFILE##*/}"
						CLEANBARE="${DUPBARE%${DUPTAG}}"
						CLEANFILE="${SRCENVI}/${CLEANBARE}"

						# --- that mode was not recomputed: no duplicate after all ------------
						if [ ! -f "${CLEANFILE}" ] ; then
							EchoTee "	${MODEI}: no new version of ${CLEANBARE}; the former one keeps its name"
							RenameProductFamily "${MODEI}" "${DUPBARE}" "${CLEANBARE}" \
								|| EchoTeeRed "	could not remove the ${DUPTAG} tag of ${CLEANBARE}"
							continue
						fi

						# --- strictly identical: no comparison needed ------------------------
						# The former copy is NOT deleted: it is archived like any other loser, so
						# that the run always leaves a visible trace of what was replaced. Such
						# duplicates are the ones that can safely be deleted in bulk afterwards.
						if cmp -s "${DUPFILE}" "${CLEANFILE}" ; then
							EchoTee "	${MODEI}: the recomputed map is BYTE IDENTICAL to the former one:"
							EchoTee "		${CLEANBARE}"
							EchoTee "		no comparison needed; the recomputed one keeps the name and the former"
							EchoTee "		one is archived in ${MODEI}${SUFOTHER} as"
							EchoTee "		${DUPBARE}"
							MoveProductFamily "${MODEI}" "${DUPBARE}" "${SUFOTHER}" \
								|| EchoTeeRed "		could not archive ${DUPBARE}; left in the _TMP dir"
							continue
						fi

						# --- they differ: let Select_BestVersion.py arbitrate ----------------
						EchoTee ""
						EchoTee "	${MODEI}: two DIFFERENT versions of ${CLEANBARE}"
						EchoTee "		(former and recomputed with ${ATMOCORR}); comparing them:"

						# a dedicated dir with these two candidates only, otherwise the comparison
						# would also involve the uncorrected versions sitting in the _TMP dir
						SCRATCH="${SRCENVI}/_DuplicateCheck_${RUNDATE}_${RNDM1}"
						rm -rf "${SCRATCH}"
						mkdir -p "${SCRATCH}"
						for EXT in "" ".hdr" ; do
							[ -f "${SRCENVI}/${DUPBARE}${EXT}" ] && { ln -f -- "${SRCENVI}/${DUPBARE}${EXT}" "${SCRATCH}/${DUPBARE}${EXT}" 2>/dev/null || cp -p -- "${SRCENVI}/${DUPBARE}${EXT}" "${SCRATCH}/${DUPBARE}${EXT}" ; }
							[ -f "${SRCENVI}/${CLEANBARE}${EXT}" ] && { ln -f -- "${SRCENVI}/${CLEANBARE}${EXT}" "${SCRATCH}/${CLEANBARE}${EXT}" 2>/dev/null || cp -p -- "${SRCENVI}/${CLEANBARE}${EXT}" "${SCRATCH}/${CLEANBARE}${EXT}" ; }
						done

						CSVDIR="${MASSPROCESSPATHLONG}/Geocoded/${MODEI}${SUFOTHER}/_Scores_Comparisons"
						mkdir -p "${CSVDIR}"
						SELECTLIST=$(mktemp "${TMPDIR:-/tmp}/DuplicateVersion.XXXXXX")
						RCDUP=0
						EchoTee "		Launch cmd: Select_BestVersion.py ${SCRATCH} -print all"
						Select_BestVersion.py "${SCRATCH}" -csv "${CSVDIR}/${MASDATE}_${SLVDATE}_${COMMENT}_DUPLICATE.csv" -print all > "${SELECTLIST}" || RCDUP=$?
						BESTNAME=$(${PATHGNU}/sed -n '1p' "${SELECTLIST}")
						BESTNAME="${BESTNAME##*/}"
						rm -f "${SELECTLIST}"
						rm -rf "${SCRATCH}"

						case "${BESTNAME}" in
							"${CLEANBARE}")
								EchoTee "		=> the RECOMPUTED version is the best one; it keeps its name"
								;;
							"${DUPBARE}")
								EchoTee "		=> the FORMER version is the best one; the tag is moved to the"
								EchoTee "		   recomputed one, which becomes the archived duplicate"
								# three steps, because the two names must be swapped
								RenameProductFamily "${MODEI}" "${CLEANBARE}" "${CLEANBARE}_SWAP_${RUNDATE}_${RNDM1}" \
									&& RenameProductFamily "${MODEI}" "${DUPBARE}" "${CLEANBARE}" \
									&& RenameProductFamily "${MODEI}" "${CLEANBARE}_SWAP_${RUNDATE}_${RNDM1}" "${DUPBARE}" \
									|| EchoTeeRed "		could not swap the names of ${CLEANBARE}; check the _TMP dir manually"
								;;
							*)
								EchoTeeRed "		Select_BestVersion.py could not designate a best version (exit ${RCDUP})."
								EchoTeeRed "		Keeping the recomputed version and archiving the former one."
								;;
						esac

						# whatever the verdict, the loser now carries the ${DUPTAG} tag: archive it
						# right away, because the tag based dispatching of SortAtmoDefoFiles cannot
						# tell apart two files that both carry _${ATMOCORR}.
						EchoTee "		Archiving ${DUPBARE}"
						EchoTee "		 in ${MODEI}${SUFOTHER}"
						MoveProductFamily "${MODEI}" "${DUPBARE}" "${SUFOTHER}" \
							|| EchoTeeRed "		could not archive ${DUPBARE}; left in the _TMP dir"
						EchoTee ""
					done
					return 0
					}

				# Move the freshly geocoded products of ${RUNDIR}/i12/GeoProjection into
				# <MODE>_TMP_${RUNDATE}_${RNDM1}, and fill MODEFOUND with the modes found,
				# highest priority first (a mode is listed once, even with two prefix rows).
				#	$1 = CORRECTED : only the ${ATMOCORR} corrected products
				#	     BOTH      : the corrected AND the re-geocoded uncorrected ones
				GatherModesInTmp()
					{
					unset WHICH
					local WHICH="$1"
					local i PFX FILE FOUND NBMATCH
					MODEFOUND=()

					i=0
					while [ ${i} -lt ${#MODE[@]} ] ; do
						FOUND="No"
						for PFX in "${MODEPREFIX[${i}]}" "${MODEPREFIXORIG[${i}]}" ; do
							# skip the uncorrected family unless it was re-geocoded too
							if [ "${WHICH}" != "BOTH" ] && [ "${PFX}" = "${MODEPREFIXORIG[${i}]}" ] ; then continue ; fi
							# the glob may match 0, 1 or several files: loop, do not test it
							for FILE in ${RUNDIR}/i12/GeoProjection/${PFX}*deg ; do
								if [ -f "${FILE}" ] && [ -s "${FILE}" ] ; then
									# MoveGeocRename globs *${PFX}*deg (unanchored) and keeps the
									# result of ls in ONE variable, then moves it quoted: on a
									# multiple match it silently moves nothing (error muted by
									# 2>/dev/null). Count first and warn rather than lose the maps.
									NBMATCH=$(ls -1 ${RUNDIR}/i12/GeoProjection/*${PFX}*deg 2>/dev/null | wc -l)
									if [ "${NBMATCH}" -gt 1 ] ; then
										EchoTeeRed "	${NBMATCH} files match *${PFX}*deg, MoveGeocRename handles only one:"
										ls -1 ${RUNDIR}/i12/GeoProjection/*${PFX}*deg
										EchoTeeRed "	=> ${MODE[${i}]} NOT moved; left in i12/GeoProjection for a manual check."
										break
									fi
									MkModeTmpDirs "${MODE[${i}]}"
									#EchoTee "Move and Rename files in ${MODE[${i}]} : $(basename "${FILE}")"
									MoveGeocRename ${PFX} ${MODE[${i}]}_TMP"_${RUNDATE}_${RNDM1}"
									FOUND="Yes"
									break		# one matching file is enough for that prefix
								fi
							done
						done
						# do not list a mode twice (DefoDetrend and DefoInterpol have two prefix rows)
						if [ "${FOUND}" = "Yes" ] ; then
							case " ${MODEFOUND[*]:-} " in
								*" ${MODE[${i}]} "*)	: ;;
								*)	MODEFOUND+=("${MODE[${i}]}") ;;
							esac
						fi
						i=$((i + 1))
					done

					PRIORITY="${MODEFOUND[0]:-}"		# highest available = first element
					}

				# Ask Select_BestVersion.py which version of the highest priority mode is the
				# best, then dispatch every mode accordingly:
				#	$1 = suffix of the dirs receiving the winners  (e.g. "" or "_New_${COMMENT}")
				#	$2 = suffix of the dirs receiving the others   (e.g. "_UnselectedVersions")
				SelectAndDispatchModes()
					{
					unset SUFBEST SUFOTHER
					local SUFBEST="$1"
					local SUFOTHER="$2"
					local SELECTDIR SELECTLIST RCSEL BESTMAP OTHERMAP ATMOWINS MODEI TREE SRCDIR DIRBEST DIROTHER

					if [ ${#MODEFOUND[@]} -eq 0 ] ; then
						EchoTeeRed " No geocoded deformation map found for ${ATMOCORR} in ${RUNDIR}/i12/GeoProjection."
						EchoTeeRed " Nothing to select nor to dispatch for that pair."
						return 0
					fi

					SELECTDIR="${MASSPROCESSPATHLONG}/Geocoded/${PRIORITY}_TMP_${RUNDATE}_${RNDM1}"

					# MoveGeocRename only warns and returns 0 when the destination dir is not
					# writable ("NOT copied ... destination dir was not available"), so make sure
					# the products really arrived before asking to compare them.
					if [ ! -d "${SELECTDIR}" ] || [ -z "$(ls -A "${SELECTDIR}" 2>/dev/null)" ] ; then
						EchoTeeRed " ${SELECTDIR} is missing or empty: the geocoded maps could not be moved"
						EchoTeeRed "  (destination dir not available or not writable ?). Nothing dispatched for that pair."
						return 0
					fi
					
					EchoTee ""
					EchoTee ""
					EchoTee "Assess if ${ATMOCORR} has improved the results (that is reduced the stdv)"
					EchoTee " in ${PRIORITY}_TMP_${RUNDATE}_${RNDM1}, then store the best solution in"
					EchoTee " ${PRIORITY}${SUFBEST} and the other one in ${PRIORITY}${SUFOTHER}."
					EchoTee "All the other Defo modes will be stored accordingly."
					EchoTee "*******************************************************************************"
					EchoTee " Launch cmd: Select_BestVersion.py ${SELECTDIR} -print all"
					EchoTee ""
					# List what is really compared: a single candidate here means that the mode dir
					# held no other version of that pair (e.g. the uncorrected map was archived in
					# ${PRIORITY}_UnselectedVersions by a former run), and the .csv will hold one
					# single line. That is not an error, but it is worth seeing in the log.
					EchoTee " Candidates in ${PRIORITY}_TMP_${RUNDATE}_${RNDM1}:"
					for BESTMAP in "${SELECTDIR}"/* ; do
						[ -f "${BESTMAP}" ] || continue
						case "${BESTMAP##*/}" in
							*.hdr|*.ras)	: ;;
							*)	EchoTee "	${BESTMAP##*/}" ;;
						esac
					done
					BESTMAP=""
					EchoTee ""

					# Absolute path: the cwd is ${RUNDIR}/i12/GeoProjection here, not /Geocoded.
					# Result read from a file and not with two successive "read": when the pair has
					# one single candidate the second read hits EOF, and under set -e that aborts.
					SELECTLIST=$(mktemp "${TMPDIR:-/tmp}/BestVersion.XXXXXX")
					RCSEL=0
					SCRORESDIR="${MASSPROCESSPATHLONG}/Geocoded/${PRIORITY}_UnselectedVersions/_Scores_Comparisons"
					mkdir -p "${SCRORESDIR}"
					Select_BestVersion.py "${SELECTDIR}" -csv "${SCRORESDIR}/${MASDATE}_${SLVDATE}_${COMMENT}.csv" -print all > "${SELECTLIST}" || RCSEL=$?
					BESTMAP=$(${PATHGNU}/sed -n '1p' "${SELECTLIST}")
					OTHERMAP=$(${PATHGNU}/sed -n '2p' "${SELECTLIST}")
					rm -f "${SELECTLIST}"

					if [ -z "${BESTMAP}" ] ; then
						EchoTeeRed " Select_BestVersion.py could not designate a best version (exit ${RCSEL})."
						EchoTeeRed " Everything is LEFT IN the <MODE>_TMP_${RUNDATE}_${RNDM1} dirs for a manual check."
						return 0
					fi

					EchoTee " Best:  $(basename "${BESTMAP}")"
					if [ -n "${OTHERMAP}" ] ; then EchoTee " Other: $(basename "${OTHERMAP}")" ; fi

					# Does the winner carry the ${ATMOCORR} tag ? Anchored on the leading underscore
					# AND terminated by a dot or the end of the name, so that e.g. GACOS matches
					# neither a NoGACOS/MangoGACOS naming nor the GACOSIncidMapMEDIAN version.
					if HasAtmoTag "${BESTMAP}" "${ATMOCORR}" 
						then ATMOWINS="Yes" 
						else ATMOWINS="No"  
					fi

					if [ "${ATMOWINS}" = "Yes" ]
						then
							EchoTee "The ${ATMOCORR} correction has improved the solution (reduced stdv)."
							EchoTee " Shall move all the ${ATMOCORR} corrected solutions in the Defo modes dirs"
							EchoTee "  and the other solutions in ${SUFOTHER}"
						else
							EchoTee "The ${ATMOCORR} correction did not improve the solution (no reduced stdv)."
							EchoTee " Shall move all the solutions without ${ATMOCORR} in the Defo modes dirs"
							EchoTee "  and the ${ATMOCORR} ones in ${SUFOTHER}"
					fi
					EchoTee ""

					# The verdict obtained on the highest priority mode is applied to every mode:
					# they all come from the same interferogram, hence the same correction.
					for MODEI in "${MODEFOUND[@]}" ; do
						for TREE in Geocoded GeocodedRasters ; do
							SRCDIR="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}_TMP_${RUNDATE}_${RNDM1}"
							[ -d "${SRCDIR}" ] || continue
							DIRBEST="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}${SUFBEST}"
							DIROTHER="${MASSPROCESSPATHLONG}/${TREE}/${MODEI}${SUFOTHER}"
							mkdir -p "${DIRBEST}" "${DIROTHER}"

							# SortAtmoDefoFiles sends the files that carry ${ATMOCORR} to its 2nd
							# argument, so swap the two dirs when the correction lost.
							if [ "${ATMOWINS}" = "Yes" ]
								then
									if ! SortAtmoDefoFiles "${SRCDIR}" "${DIRBEST}" "${DIROTHER}" ; then
										EchoTeeRed " Dispatching of ${TREE}/${MODEI} failed; files left in ${SRCDIR}."
									fi
								else
									if ! SortAtmoDefoFiles "${SRCDIR}" "${DIROTHER}" "${DIRBEST}" ; then
										EchoTeeRed " Dispatching of ${TREE}/${MODEI} failed; files left in ${SRCDIR}."
									fi
							fi

							# rmdir and not rm -Rf: if something could not be moved it must survive
							rmdir "${SRCDIR}" 2>/dev/null || EchoTeeRed " ${SRCDIR} not empty; kept for a manual check."
						done
					done
					}

	
				if [ "${SAMEGEOC}" == "Yes"  ]
					then
						# Same geocoding parameters: the new maps live on the same grid as the
						# existing ones, so they can be compared with them and replace them.
							EchoTee " Same geocoding parameters. "
							EchoTee " Shall evaluate if atmo corr has improved the result or not. "
							EchoTee " Best results shall be moved in usual Defo... directories "
							EchoTee "	(e.g. /Geocoded/Defo, /Geocoded/DefoInterpolated etc.)"
							EchoTee " The other results (i.e. with less appropriate quality) shall be moved to"
							EchoTee "    /Geocoded/Defo_UnselectedVersions etc. "
							EchoTee " Same is done for the /GeocodedRasters"
							EchoTee ""
							EchoTee " By doing this, one can mix corrected and uncorrected data in MSBAS processing, "
							EchoTee "   hence skipping corrected data when correction is not appropriate.  "
							EchoTee " If several type of atmo corr are tested, it is always the best one that "
							EchoTee "   will be in usual Defo... directories"
							EchoTee ""
							EchoTee " The assessment of the best solution is performed on the highest priority"
							EchoTee "  mode available, by order of priority: $(IFS='|' ; echo "${MODE[*]}")"
							EchoTee ""

							cd ${RUNDIR}/i12/GeoProjection

						# move the NEW ${ATMOCORR} corrected maps in <MODE>_TMP_...
						# This is done FIRST, before backing up the former versions: the new maps
						# always keep their own name, so a former version whose name is already
						# taken in the _TMP dir is, by construction, the former version OF ONE OF
						# THEM. The clash is then detected with a simple test instead of being
						# predicted from the presence of _${ATMOCORR} in the name, which missed
						# cases and ended up in a map being silently overwritten.
						###########################################################################
							EchoTee "Moving the new ${ATMOCORR} files temporarily in <MODE>_TMP_${RUNDATE}_${RNDM1} for selecting the lowest stdv."
							EchoTee "They will be moved later"
							EchoTee "******************************************"
							EchoTee ""

							GatherModesInTmp CORRECTED

						# Because the geocoding parameters are unchanged, deformationMap${POSTFIX} was
						# recomputed only to initiate the geocoding: it is identical to the one that
						# is still in /Geocoded/Defo, so it can be erased. Guarded, because "ls" on an
						# unmatched glob returns non zero and would abort the script (set -e).
						###########################################################################
							for FILE in ${RUNDIR}/i12/GeoProjection/deformationMap${POSTFIX}_${SATDIR}*deg ; do
								[ -f "${FILE}" ] || continue
								EchoTee "Removing the redundant re-geocoded uncorrected map $(basename "${FILE}")"
								rm -f "${FILE}" "${FILE}.hdr"
							done

						# backup the FORMER geocoded maps of that pair (uncorrected, corrected with
						# another method, or corrected with the SAME method during a previous run) in
						# <MODE>_TMP_..., so that they can be compared with the new ones. They already
						# are on the right grid, so they come from /Geocoded.
						###########################################################################
							EchoTee ""
							EchoTee "Backing up the former geocoded files in <MODE>_TMP_${RUNDATE}_${RNDM1}"
							EchoTee "They will be moved later"
							EchoTee "********************************"
							EchoTee ""

							# MODE holds a mode more than once (two prefix rows for DefoDetrend and
							# DefoInterpol), so back up each mode only once.
							MODEBACKEDUP=""
							i=0
							while [ ${i} -lt ${#MODE[@]} ] ; do
								case " ${MODEBACKEDUP} " in
									*" ${MODE[${i}]} "*)	i=$((i + 1)) ; continue ;;
								esac
								MODEBACKEDUP="${MODEBACKEDUP} ${MODE[${i}]}"
								BackupAllVersionsOfPair "${MODE[${i}]}"
								i=$((i + 1))
							done

							echo

						# settle the maps that carry the same name as a former version of the same
						# ${ATMOCORR} correction, before the general comparison takes place: the
						# best of the two keeps the clean name and the other one is archived with
						# the tag _DUPLICATE_${RUNDATE}_${RNDM1}
						###########################################################################
							EchoTee "Checking whether a former version of the same ${ATMOCORR} correction"
							EchoTee " was carrying the same name as a map recomputed now"
							EchoTee "**********************************************************"
							EchoTee ""

							MODERESOLVED=""
							i=0
							while [ ${i} -lt ${#MODE[@]} ] ; do
								case " ${MODERESOLVED} " in
									*" ${MODE[${i}]} "*)	i=$((i + 1)) ; continue ;;
								esac
								MODERESOLVED="${MODERESOLVED} ${MODE[${i}]}"
								ResolveDuplicateVersions "${MODE[${i}]}" "_UnselectedVersions"
								i=$((i + 1))
							done

							echo

						# assess which version is the best and dispatch accordingly
						###########################################################################
							SelectAndDispatchModes "" "_UnselectedVersions"

					else
						# Not the same geocoding parameters: the new maps are on ANOTHER grid, so they
						# must not be mixed with the existing ones (MSBAS needs one single grid).
						# GeocUTM has re-geocoded BOTH the ${ATMOCORR} corrected maps AND the former
						# uncorrected ones on that new grid, so both are compared with each other and
						# dispatched in a parallel set of dirs suffixed _New_${COMMENT}.
							EchoTee " Not the same geocoding parameters; Shall move: "
							EchoTee "	- the best of (corrected / uncorrected) to /Geocoded/Defo..._New_${COMMENT}"
							EchoTee "	- the other one to /Geocoded/Defo..._New_${COMMENT}_UnselectedVersions"
							EchoTee " and same for /GeocodedRasters"
							EchoTee ""
							EchoTee " The existing /Geocoded/Defo... dirs are left untouched: they hold the"
							EchoTee "   products of the former grid and must not be mixed with the new ones."
							EchoTee ""

							cd ${RUNDIR}/i12/GeoProjection

						# move BOTH families (corrected and re-geocoded uncorrected) in <MODE>_TMP_...
						###########################################################################
							EchoTee "Moving the new files temporarily in <MODE>_TMP_${RUNDATE}_${RNDM1} for selecting the lowest stdv."
							EchoTee "They will be moved later"
							EchoTee "******************************************"
							EchoTee ""

							GatherModesInTmp BOTH

						# assess which version is the best and dispatch in the _New_${COMMENT} dirs
						###########################################################################
							SelectAndDispatchModes "_New_${COMMENT}" "_New_${COMMENT}_UnselectedVersions"
				fi
			
	
				# Back to main directroy  
				########################
				cd ${MASSPROCESSPATHLONG}
		
				break # because there must be only one line in list of masks for a given pair of dates
			else 
				EchoTee "Pair ${PAIRDIR} not requested for re-geocoding in ${LISTPAIRS}"
			
		fi
       
        ((i++))

    done

done

EchoTee ""

echo " "
echo "********************************************************************************"
echo " ${PRG} finished on " ; date
echo "********************************************************************************"
echo " "
