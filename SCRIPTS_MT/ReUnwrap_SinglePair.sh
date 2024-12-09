#!/bin/bash
# Script to re-run the unwrapping PAIR DIRS from a SinglePair.sh processing. 
# Will also interpolate and re-Detrend the new unwrapped phase if required.
#
# Former unwrapped phase is saved as unwrappedPhase....bak.
# If you have enough room on your disk, it might be wise to duplicate the dir where you will reprocess all the unwrappings ?
#
# You can then run a _ReGeoc_FromSinglePair.sh if required. 
#
# Note that this request to run in the same dir and with teh sme computer as the one where SinglePair.sh was performed to avoid path problems
# 
#  !!!!! WARNING: only tested for S1 so far and not in STRIPMAP !!!!!
#
# Need to be run in PAIR DIR
#
# Parameters:	 - File with the parameters needed for the run
#
# HARD CODED: 	- 
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- byte2Float.py, Swap_0_1_in_ByteFile.py 
#
# New in Distro V 1.0:	- Based on developpement version for MASSPRROVCESS
# New in Distro V 1.1:	- debugged for file naming. ATTENTION, files are not renamed after completion of re-unwrapping. 
# New in Distro V 1.2: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 1.3: 	- read UTM zone for geocoding
# New in Distro V 1.4 20231002:	- compatible with new multi-mevel masks where 0 = non masked and 1 or 2 = masked  
#								- add fig snaphuMask and keep copy of unmasked defo map
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20231123:	- Allows naming Radarsat2 as RS in workflow
# New in Distro V 3.0 20241015:	- multi level mask 
# New in Distro V 3.1 20241112:	- debug PATHTOMASK
# New in Distro V 3.3 20241202:	- Mask before interpolation after unwrapping ok with the 3 version of masking methods (old 1=keep; intermediate 1,2=mask in one file, latest 1,2,3 are masked in multiple masks)
#								- swap 0 and 1 before multiply the defo by the thresholdedSlantRangeMask 
#								- take mask(s) basename only if exist  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Dec 02, 2024"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

PARAMFILE=$1	# File with the parameters needed for the run

if [ $# -lt 1 ] ; then echo “Usage $0 PARAMETER_FILE ”; exit; fi

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


REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
DEMNAME=`GetParam "DEMNAME,"`				# DEMNAME, name of DEM inverted by lines and columns

RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data will be stored 

eval PROPATH=${PROROOTPATH}/${SATDIR}/${TRKDIR}	# Path to dir where data will be processed.

source ${FCTFILE}

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

echo ""
echo "Attention : need the Parameters files in TextFiles with the right path and in the format of your mounted disks depending on the OS. "
while true; do
    read -p "Are you sure that all the TextFiles/ have the correct path and format ? [y/n] "  yn
    case $yn in
        [Yy]* ) 
        	echo "OK, let's go again."
		    break ;;
        [Nn]* ) 
        	echo "Please do... "
        	exit 0
        	break ;;
        * ) echo "Please answer yes or no.";;
    esac
done 
echo ""


# Log File
RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
RNDM1=`echo $(( $RANDOM % 10000 ))`
LOGFILE=LogFile_Reunwrap_${RUNDATE}_${RNDM1}.txt

RUNDIR="$(pwd)"
MAS=`echo "${RUNDIR}" | cut -d "_" -f1  ` # select Primary date
SLV=`echo "${RUNDIR}" | cut -d "_" -f2  ` # select Secondary date

echo
echo "*********************************************************"
echo "Shall re-unwrap pair ${RUNDIR}"
echo "*********************************************************"

#needed for mask fig
ISARRG=`GetParamFromFile "Interferometric products range dimension" InSARParameters.txt`

# remove snaphu.conf because it can't handle state variable. Better re-create it
if  [ ${UW_METHOD} == "SNAPHU" ] && [ -f "${RUNDIR}/i12/TextFiles/snaphu.conf" ] && [ -s "${RUNDIR}/i12/TextFiles/snaphu.conf" ] 
	then 
		if [ ! -f ${RUNDIR}/i12/TextFiles/snaphu_original.conf  ] 
			then 
				mv ${RUNDIR}/i12/TextFiles/snaphu.conf ${RUNDIR}/i12/TextFiles/snaphu_original.conf 
			else 
				rm -f ${RUNDIR}/i12/TextFiles/snaphu.conf
		fi
fi

# Need to get back the original names
MASPOL=`GetParamFromFile "Master polarization channel" InSARParameters.txt`
SLVPOL=`GetParamFromFile "Slave polarization channel" InSARParameters.txt`

ORIGCOHFILE=`find ${RUNDIR}/i12/InSARProducts/ -maxdepth 1 -type f -name "coherence.??-??.*days"`
if [ -f "${ORIGCOHFILE}" ] && [ -s "${ORIGCOHFILE}" ] ; then cp -f ${ORIGCOHFILE} ${RUNDIR}/i12/InSARProducts/coherence.${MASPOL}-${SLVPOL} ; fi
ORIGRESINTERFFILTFILE=`find ${RUNDIR}/i12/InSARProducts/ -maxdepth 1 -type f -name "residualInterferogram.??-??.f.*days"`
if [ -f "${ORIGRESINTERFFILTFILE}" ] && [ -s "${ORIGRESINTERFFILTFILE}" ] ; then cp -f ${ORIGRESINTERFFILTFILE} ${RUNDIR}/i12/InSARProducts/residualInterferogram.${MASPOL}-${SLVPOL}.f ; fi
		

case ${SATDIR} in
	"RS"|"RADARSAT") 
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
		EchoTee "You requested an interpolation before geocoding."
		DEFORG=`GetParamFromFile "Deformation measurement range dimension" InSARParameters.txt`
		DEFOAZ=`GetParamFromFile "Deformation measurement azimuth dimension" InSARParameters.txt`

		if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
			then 
				EchoTee "First multiply deformation map with NaN mask."
				if [ -f "${RUNDIR}/i12/InSARProducts/binarySlantRangeMask" ]
					then 
						EchoTee "Suppose multilevel masking where 1 and/or 2 = to be masked and 0 = non masked in a single file, without detrend mask(s)."
						# i.e. use new masking method with multilevel masks where 0 = non masked and 1 or 2 = masked
						byte2Float.py ${RUNDIR}/i12/InSARProducts/snaphuMask
						ffa ${RUNDIR}/i12/InSARProducts/deformationMap N ${RUNDIR}/i12/InSARProducts/snaphuMaskFloat -i
						convert -depth 8 -equalize -size ${DEFORG}x${DEFOAZ} gray:${RUNDIR}/i12/InSARProducts/snaphuMask ${RUNDIR}/i12/InSARProducts/snaphuMask.gif
					else 
						if [ -f "${RUNDIR}/i12/InSARProducts/thresholdedSlantRangeMask" ] 											
							then 
								EchoTee "Suppose multilevel masking where 1 and/or 2 and/or 3 = to be masked and 0 = non masked, that is with possible detrend masks."
								# i.e. use new masking method with multiple masks where 0 = non masked and 1 or 2 or 3 = masked
								Swap_0_1_in_ByteFile.py ${RUNDIR}/i12/InSARProducts/thresholdedSlantRangeMask
								byte2Float.py ${RUNDIR}/i12/InSARProducts/thresholdedSlantRangeMask_Swap01
								ffa ${RUNDIR}/i12/InSARProducts/deformationMap N ${RUNDIR}/i12/InSARProducts/thresholdedSlantRangeMask_Swap01Float -i
								convert -depth 8 -equalize -size ${DEFORG}x${DEFOAZ} gray:${RUNDIR}/i12/InSARProducts/thresholdedSlantRangeMask_Swap01 ${RUNDIR}/i12/InSARProducts/thresholdedSlantRangeMask_Swap01.gif
							else
								if [ ${UW_METHOD} == "CIS" ]
									then 
										EchoTee "CIS unwrapping performed with mask. However, deformation/Topo maps are not shown with masked area because there is no product with the same size. "
										EchoTee "However, you can easily do it manually with any GIS software. "
									else 
										EchoTee "Suppose mask where 0 = to be masked and 1 = non masked."
										# i.e. use old masking method with single level masks where 0 = masked
										ffa ${RUNDIR}/i12/InSARProducts/deformationMap N ${RUNDIR}/i12/InSARProducts/slantRangeMask -i
								fi
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

	
	# Because for S1 STRIPMAP images masters are in the form of a date, one must rename the files as (super)master-name 	
# 	if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "STRIPMAP" ] ; then 
# 		cp ${RUNDIR}/i12/InSARProducts/${MAS}.${POLMAS}.mod ${RUNDIR}/i12/InSARProducts/${MASNAME}.${POLMAS}.mod 
# 	fi			


