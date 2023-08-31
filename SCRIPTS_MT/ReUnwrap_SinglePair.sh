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
#
# New in Distro V 1.0:	- Based on developpement version for MASSPRROVCESS
# New in Distro V 1.1:	- debugged for file naming. ATTENTION, files are not renamed after completion of re-unwrapping. 
# New in Distro V 1.2: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 1.3: 	- read UTM zone for geocoding
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2018/03/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.3 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 29, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

PARAMFILE=$1	# File with the parameters needed for the run

if [ $# -lt 1 ] ; then echo “Usage $0 PARAMETER_FILE ”; exit; fi

# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

SUPERMASTER=`GetParam SUPERMASTER`			# SUPERMASTER, date of the super master as selected by Prepa_MSBAS.sh in
											# e.g. /Volumes/hp-1650-Data_Share1/SAR_SUPER_MASTERS/MSBAS/VVP/seti/setParametersFile.txt

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

RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data are stored 

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
MAS=`echo "${RUNDIR}" | cut -d "_" -f1  ` # select master date
SLV=`echo "${RUNDIR}" | cut -d "_" -f2  ` # select slave date

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
		EchoTee "You requested an interpolation before geocoding. First multiply deformation map with NaN mask."
		if [ "${APPLYMASK}" == "APPLYMASKyes" ] 
			then 
				ffa ${RUNDIR}/i12/InSARProducts/deformationMap N ${RUNDIR}/i12/InSARProducts/slantRangeMask -i
		fi
		DEFORG=`GetParamFromFile "Deformation measurement range dimension" InSARParameters.txt`
		DEFOAZ=`GetParamFromFile "Deformation measurement azimuth dimension" InSARParameters.txt`
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


