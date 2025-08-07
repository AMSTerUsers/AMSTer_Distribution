#!/bin/bash
# This script aims at splitting a mass COREGISTRATION process in several parts. 
#
# Attention : processes will be shared between several disks. Check their availability and if sufficient space. 
#
# Beware, this script only works if launched from your computer or from 
#        a remote computer with a graphical interface as it must open new Terminal windows. 
#        It does not work if launched from a ssh session !
# If you want to operate it from a ssh session, you must use ssh -X session instead of ssh and ensure that you have:
#   - On the client side, in the ~/.ssh/config file:
#        Host *
#   		ForwardAgent yes
#   		ForwardX11 yes
#   		ForwardX11Trusted yes
#     If the client is a Mac, you must install XQuartz, which contains Xterm, because Terminal.app is not X11 compatible.  
#   - On the server side, in the /etc/ssh/sshd_config file:
#   	X11Forwarding yes
#   	X11DisplayOffset 10
#   	X11UseLocalhost no
#     You should also have xauth installed on the server side (most probably existing by default).
#
#
# Parameters are:
#       - List of images to coregister and to be splitted (must be in the form of name if S1 (e.g. S1x_Trk_DATE_AD.csl) or dates if not S1, in 1 col)
#		- Parameters file (incl path) to be used
#       - Nr of parallel splitted processes
#       - FORCES1DEM: if  FORCE, then recompute DEM for each S1 wide swath image 
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#   			- seq
#               - Appel's osascript for opening terminal windows if OS is Mac
#               - x-termoinal-emulator for opening terminal windows if OS is Linux
#			    - say for Mac or espeak for Linux
#				- scripts LaunchTerminal.sh, MasterDEM.sh and of course SuperMaster_MassProc.sh
#				- __HardCodedLines.sh
#
# Hard coded:	- List and path to available disks (in two places ! See script)
#
# New in Distro V 1.0:	- Based on developpement __SplitSession.sh version 1.9
# New in Distro V 2.0:	- was missing Param file in PROPATH
#						- uniform path to HOMEDATA disk
# 						- read more param... just in case 
# New in Distro V 3.0:	- check that no SuperMasterCoreg.sh is running on this computer 
#						 before attempting to clean directories  
# New in Distro V 3.1: - more robust determination of DISPLAY variable
# New in Distro V 3.2: - even more robust determination of DISPLAY variable
# New in Distro V 4.0: - Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 4.1: - was not escaping the DISPLAY selection loop
# New in Distro V 4.2: - new way to test DISPLAY for Linux and test it only once for all instead of for DEM and split
#					   - clean commented lines
# New in Distro V 5.0: - Big bug correction in case of FORCE DEM 
#					   - remove SUPERMASTER from list to coreg just in case... 
# New in Distro V 6.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 7.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 8.0 20241015:	- multi level mask 
# New in Distro V 8.1 20241202:	- debug PATHTOMASK
# New in Distro V 8.2 20250204:	- zap hidden Gremlins making wc to crash
# New in Distro V 8.3 20250520:	- new param to define crop as GEO or SRA (lines and pixels) coordinates
#								- state that mass processing with asymetric zoom is not allowed (yet). If needed, this might be implemented later
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V8.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on May 20, 2025"

echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "



# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below :
	# - SplitDiskDef for the list of available disks
	# - SplitDiskList for defining a code for each available disk
	# - SplitDiskSelection for selecting the disks for each session
# ^^^ ----- Hard coded lines to check --- ^^^ 

LISTTOCOREG=$1 		# List of images to coregister and to be splitted (must be in the form of name if S1 (e.g. S1x_Trk_DATE_AD.csl) or dates if not S1, in 1 col)
PARAMFILEPATH=$2 	# Usual Parameter file
N=$3 				# eg 5 if you have 100 pairs and want process 5 terminals, each processing 20 pairs
FORCES1DEM=$4		# For S1 processing : if FORCE, then recompute DEM for each S1 image 

if [ "${FORCES1DEM}" != "FORCE" ] 
	then
		FORCES1DEM="NoForce"
fi

if [ $# -lt 3 ] 
	then 
		echo "Usage $0 LIST_OF_IMGNAME.csl_TO_COREG PARAM_FILEPATH NUMBER_OF_PARALLEL_PROCESSES [FORCE]" 
		echo "That is if you have 100 pairs to coreg and chose 5 parallel processes, "
		echo "     it will compute 5 sets of 20 pairs in 5 terminal windows."
		exit
fi

PARAMPATH=`dirname ${PARAMFILEPATH}`
PARAMFILE=`basename ${PARAMFILEPATH}`
PARAMEXT="${PARAMFILEPATH##*.}"

RNDM=`echo $(( $RANDOM % 10000 ))`

# Get the list of disks - see __HardCodedLines.sh
SplitDiskDef	# also get OK from that function

function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${PARAMFILEPATH} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

function SpeakOut()
	{
	unset MESSAGE 
	local MESSAGE
	MESSAGE=$1
	case ${OS} in 
		"Linux") 
			espeak "${MESSAGE}" ;;
		"Darwin")
			say "${MESSAGE}" 	;;
		*)
			echo "${MESSAGE}" 	;;
	esac			
	}
	
SUPERMASTER=`GetParam SUPERMASTER`			# SUPERMASTER, date of the Global Primary image as selected by Prepa_MSBAS.sh in
											# e.g. /Volumes/hp-1650-Data_Share1/SAR_SUPER_MASTERS/MSBAS/VVP/seti/setParametersFile.txt

PROROOTPATH=`GetParam PROROOTPATH`			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name. 
DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 
RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data will be stored 

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

SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping

INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products

REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming

# More Param to be sure... 
DEMDIR=`GetParam DEMDIR`					# DEMDIR, path to dir where DEM is stored
RECOMPDEM=`GetParam "RECOMPDEM,"`			# RECOMPDEM, recompute DEM even if already there (FORCE), or trust the one that would exist (KEEP)
SIMAMP=`GetParam "SIMAMP,"`					# SIMAMP, (SIMAMPno or SIMAMPyes). Option to compute simulated amplitude during Extenral DEM generation - usually not needed.
POP=`GetParam "POP,"`						# POP, option to pop up figs or not (POPno or POPyes)
FIG=`GetParam "FIG,"`						# FIG, option to compute or not the quick look using cpxfiddle (FIGno or FIGyes)
MLAMPLI=`GetParam "MLAMPLI,"`				# MLAMPLI, Multilooking factor for amplitude images reduction (used for coregistration - 4-6 is appropriate). If rectangular pixel, it will be multiplied by corresponding ratio.
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
COHESTIMFACT=`GetParam "COHESTIMFACT,"`		# COHESTIMFACT, Coherence estimator window size
FILTFACTOR=`GetParam "FILTFACTOR,"`			# Range and Az filtering factor for interfero
POWSPECSMOOTFACT=`GetParam "POWSPECSMOOTFACT,"`	# POWSPECSMOOTFACT, Power spectrum filtering factor (for adaptative filtering)
APPLYMASK=`GetParam "APPLYMASK,"`			# APPLYMASK, Apply mask before unwrapping (APPLYMASKyes or APPLYMASKno)
APPLYMASK=`GetParam "APPLYMASK,"`			# APPLYMASK, Apply mask before unwrapping (APPLYMASKyes or APPLYMASKno)

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
DEMNAME=`GetParam "DEMNAME,"`				# DEMNAME, name of DEM inverted by lines and columns
MASSPROCESSPATH=`GetParam MASSPROCESSPATH`	# MASSPROCESSPATH, path to dir where all processed pairs will be stored in sub dir named by the sat/trk name (SATDIR/TRKDIR)
# End of more Param to be sure... 

FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored

PATHFCTFILE=${FCTFILE%/*}

source ${FCTFILE}

PROPATH=${PROROOTPATH}/${SATDIR}/${TRKDIR}/MASSCOREG
mkdir -p ${PROPATH}

# remove SUPERMASTER from list to coreg just in case... 
${PATHGNU}/grep -v ${SUPERMASTER} ${LISTTOCOREG} > ${LISTTOCOREG}_NoSM.txt
LISTTOCOREG=${LISTTOCOREG}_NoSM.txt

TABLEPATH=`dirname ${LISTTOCOREG}`
TABLEFILE=`basename ${LISTTOCOREG}`
TABLEEXT="${LISTTOCOREG##*.}"

# Test asymetric zoom - not allowed for mass processing 
CheckZOOMasymetry
if [ "${ZOOMONEVAL}" == "Two" ] 
	then 
		echo " Performing mass processing with asymetric zoom is not allowed yet. Exiting..." 
		exit 
fi

# Update some infos
	if [ ${CROP} == "CROPyes" ]
		then
			SMCROPDIR=SMCrop_SM_${SUPERMASTER}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}   #_Zoom${ZOOM}_ML${INTERFML}
		else
			SMCROPDIR=SMNoCrop_SM_${SUPERMASTER}  #_Zoom${ZOOM}_ML${INTERFML}
	fi


# Create (if not done yet) the RESAMPDATPATH dirs
mkdir -p ${RESAMPDATPATH}
mkdir -p ${RESAMPDATPATH}/${SATDIR}
mkdir -p ${RESAMPDATPATH}/${SATDIR}/${TRKDIR}
mkdir -p ${RESAMPDATPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}

cd ${PROPATH}

# Do not check what exists yet as it be done in SuperMasterCoreg.sh. 
# This is not optimum as if can dedicate a session to a set of data already processed but that is the user responsibility... 

function ChangeProcessPlace()
	{
	unset FILE
	ORIGINAL=`cat ${PARAMFILEPATH} | ${PATHGNU}/grep PROROOTPATH `
	local NEW=$1
	local FILE=$2
   	echo "      Shall process ${i}th set of pairs in  ${NEW}_${RNDM}"
	${PATHGNU}/gsed -i "s%${ORIGINAL}%${NEW}_${RNDM} 			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name (SATDIR).%" ${FILE}

	}
# Nr of images:
NRIMG=`wc -l < ${LISTTOCOREG}`
# Nr of images per session 
IMGPERSET=`echo "(${NRIMG} + ${N} - 1) / ${N}" | bc` # bash solution for ceiling... 

# Split img file in N
for i in `seq 1 ${N}`
do
	NEWIMGFILE=${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT}

	TOHEAD=`echo "(${i} * ${IMGPERSET}) " | bc` 
	TOTAIL=`echo "${IMGPERSET} " | bc` 
	
	if [ ${TOHEAD} -gt ${NRIMG} ] 
		then 
			LASTSET=`echo "${TOHEAD} - ${NRIMG}" | bc` 
			TOTAIL=`echo "${IMGPERSET} - ${LASTSET}" | bc`
	fi
	
	# Ensure here also that SM is not in file...  
	cat ${LISTTOCOREG} | head -${TOHEAD} | tail -${TOTAIL} | grep -v ${SUPERMASTER} > ${NEWIMGFILE}
	
	
done

# Split Parameter file i order to process in several dir
echo "-------------------------------------------"
echo "Disk space available on your drives are : "
df -h
echo "-------------------------------------------"
echo "Where do you want to process the ${i} set of ${PAIRSPERSET} pairs: "
# List disks and their nr -  see __HardCodedLines.sh
SplitDiskList 

# Check the DISPLAY for Linux
if [ "${OS}" == "Linux" ] ; then 

		# All DISPLAYS
		ps -u $(id -u) -o pid=     | xargs -I PID -r cat /proc/PID/environ 2> /dev/null     | tr '\0' '\n'     | grep ^DISPLAY=:     | sort -u | cut -d = -f2 | grep -v "tty" > all_displays.tmp

		NRMYDISPLAYWHO=`who -m | grep -v tty | cut -d "(" -f 2  | cut -d ")" -f 1 | wc -l`
		case ${NRMYDISPLAYWHO} in 
			1) 
				# only one DISPLAY; I guess it is the good one
				eval MYDISPLAY=`who -m | grep -v tty | cut -d "(" -f 2  | cut -d ")" -f 1 ` 
				# Test if it is listed in all the displays though; if not, ask manually
				if [ `grep "${MYDISPLAY}" all_displays.tmp | wc -l` -ne 1 ] 
					then 
						ASKDISPLAY="YES"
				fi
				;;
			0) 
				# no DISPLAY; try with who without -m
				NRMYDISPLAYWHO=`who | grep -v tty | cut -d "(" -f 2  | cut -d ")" -f 1 | wc -l`
				if [ ${NRMYDISPLAYWHO} -eq 1 ]
					then 
						# only one DISPLAY; I guess it is the good one
						eval MYDISPLAY=`who | grep -v tty | cut -d "(" -f 2  | cut -d ")" -f 1 ` 
						# Test if it is listed in all the displays though; if not, ask manually
						if [ `grep "${MYDISPLAY}" all_displays.tmp | wc -l` -ne 1 ] 
							then 
								ASKDISPLAY="YES"
						fi
					else 
						ASKDISPLAY="YES"
				fi
				;;
			*) 
				# more than one DISPLAY
				ASKDISPLAY="YES"
				;;
		esac

		if [ "${ASKDISPLAY}" == "YES" ]
			then 
				echo "I can't find out which is your current DISPLAY value. "
				echo "I can however see that you have the following DISPLAYs on your server:"
				# The following line list all the DISPLAYs:
				ps -u $(id -u) -o pid=     | xargs -I PID -r cat /proc/PID/environ 2> /dev/null     | tr '\0' '\n'     | grep ^DISPLAY=:     | sort -u
				
				while true; do
					read -p "Which one do you want to use (answer someting like \":0.0\" without the quotes) ? "  MYDISPLAY
					echo "If no Terminal pops up here after, cancel the current script and start again with another DISPLAY"
					break
				done
				eval MYDISPLAY=`echo ${MYDISPLAY}`
		fi 

		echo "  // Your current session runs on DISPLAY ${MYDISPLAY}"
		rm -f all_displays.tmp
fi

cp ${PARAMFILEPATH} ${PROPATH}/${PARAMFILE}

for i in `seq 1 ${N}`
do
	NEWPARAMFILE=${PROPATH}/${PARAMFILE}_Part${i}_${RNDM}.${PARAMEXT}
	cp ${PROPATH}/${PARAMFILE} ${NEWPARAMFILE}

		while true; do
			read -p "Provide the number of disk from list above and ensure there is enough space: "  DISK
			# Select disk by their nrs -  see __HardCodedLines.sh
			SplitDiskSelection  
			break

		done
		ChangeProcessPlace ${DISKPATH} ${NEWPARAMFILE}
		DISKPATH[$i]=${DISKPATH}
		echo "	${i}th processing will be on ${DISKPATH[$i]} "
done

echo ""

# First take care of the DEM of the Global Primary. ManageDEM will take care of forcing it or computing if not existing

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
			else 
				S1MODE="STRIPMAP"
		fi
		;;
	*)
		S1MODE="DUMMY"  #Just un case... 
		;;
esac	

# Supermaster directory name based on date given in LaunchParameters file
	if [ ${SATDIR} == "S1" ] ; then 
			SUPERMASNAME=`ls  ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${SUPERMASTER}  | cut -d . -f 1` 		 # i.e. if S1 is not wideswath, crop is possible, so one must search for the name in NoCrop; MASNAME is now the full name of the image anyway
		else
			SUPERMASNAME=${SUPERMASTER} 
	fi	
	SUPERMASDIR=${SUPERMASNAME}.csl
	
EchoTee " Before splitting the coregistration, I must take care of the DEM of the Global Primary (SuperMaster) ${SUPERMASNAME}"

	if [ "${SATDIR}" == "S1" ] && [ "${FORCES1DEM}" == "FORCE" ] 
		then
			RECOMPDEM="FORCE"
	fi
	# will check if FORCE (from Param file) or if exist already or not
	IMGWITHDEM=${SUPERMASNAME}
	
	# Need this for ManageDEM
	INPUTDATA=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/
	RGSAMP=`GetParamFromFile "Range sampling [m]" SuperMaster_SLCImageInfo.txt`   # not rounded 
	EchoTee "Range sampling : ${RGSAMP}"
	AZSAMP=`GetParamFromFile "Azimuth sampling [m]" SuperMaster_SLCImageInfo.txt` # not rounded
	EchoTee "Azimuth sampling : ${AZSAMP}"
	PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
	PIXSIZERG=`echo "${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 

	PARAMFILE=${PARAMFILEPATH}
	ManageDEM
	PARAMFILE=`basename ${PARAMFILEPATH}`

echo "-------------------------------------------"
echo
while true ; do
	read -p "Do you want to run the Mass Coregistration in separate Terminal windows ? "  yn
	case $yn in
		[Yy]* ) 
			# launch the processing in separate Terminal windows
			echo "OK, I launch them for you now..."
			for i in `seq 1 ${N}`
 			do
 				sleep 5
 				case ${OS} in 
					"Linux") 
						# Must remove the computation of DEM for SuperMaster in every SuperMasterCoreg.sh for each session because it was already done before
						${PATHGNU}/gawk '/^IMGWITHDEM=\${SUPERMASNAME}$/ {print; getline; print "#" $0; next} 1'  ${PATH_SCRIPTS}/SCRIPTS_MT/SuperMasterCoreg.sh > ${PROPATH}/SuperMasterCoreg_Part${i}_${RNDM}.sh
						chmod +x ${PROPATH}/SuperMasterCoreg_Part${i}_${RNDM}.sh
						
						export DISPLAY=${MYDISPLAY} ; x-terminal-emulator -e ${PATHFCTFILE}/LaunchTerminal.sh ${PROPATH}/SuperMasterCoreg_Part${i}_${RNDM}.sh ${PROPATH}/${PARAMFILE}_Part${i}_${RNDM}.${PARAMEXT} ${FORCES1DEM} ${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT} &
						;;
					"Darwin")
						# Must remove the computation of DEM for SuperMaster in every SuperMasterCoreg.sh for each session because it was already done before
						${PATHGNU}/gawk '/^IMGWITHDEM=\${SUPERMASNAME}$/ {print; getline; print "#" $0; next} 1'  ${PATH_SCRIPTS}/SCRIPTS_MT/SuperMasterCoreg.sh > ${PROPATH}/SuperMasterCoreg_Part${i}_${RNDM}.sh
						chmod +x ${PROPATH}/SuperMasterCoreg_Part${i}_${RNDM}.sh
						
 						osascript -e 'tell app "Terminal"
 						do script "${PROPATH}/SuperMasterCoreg_Part${i}_${RNDM}.sh '"${PROPATH}/${PARAMFILE}_Part${i}_${RNDM}.${PARAMEXT} ${FORCES1DEM} ${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT}"'"
 						end tell'
 						;;
					*)
						echo "I can't figure out what is you opeating system. Please check"
						exit 0
						;;
				esac	
 			done 
			break ;;
		[Nn]* ) 
			echo ""
			echo "OK, launch them manually when you are ready"    
			break ;;
    	* ) echo "Please answer yes or no." ;;	
    esac	
done

echo
echo "WAIT FOR FINISHING WORK IN ALL TERMINALS BEFORE ATTEMPTING CLEANING THE DIRECTORIES." 

# Check what is running 
while true ; do
	read -p "All process are finished and you want to try cleaning the working directories [y/n] ? : "  yn
		case $yn in
		[Yy]* ) 
			if [ `ps -eaf | grep SuperMasterCoreg.sh | grep -v grep | wc -l ` -eq 0 ] 
				then 
					echo "Indeed, no more SuperMasterCoreg.sh  are running on this computer. You can proceed : "
					break 
				else 
					echo "Sorry, not finished yet."
					while true ; do
						read -p "Do you want to force the cleaning anyway ? Beware that it will cause the running processes to crash [y/n] ? : "  yn
							case $yn in
							[Yy]* ) 
								echo "OK, I guess you checked that the running SuperMasterCoreg.sh is not part of the __SplitCoreg.sh run... "
								echo "Proceed to cleaning :"
								break 
								;;
							[Nn]* ) 
								echo "OK, then I wait..."    
								;;
					    	* ) echo "Please answer yes [Yy] or no [Nn]." ;;	
					    esac	
					done
			fi 
			break ;;
		[Nn]* ) 
			echo "OK, then I wait..."    
			;;
    	* ) echo "Please answer yes [Yy] or no [Nn]." ;;	
    esac	
done

# Some cleaning 
while true ; do
	read -p "	Do you want to clean ${PROPATH} ? "  yn
		case $yn in
		[Yy]* ) 
			echo "	Remove this: "
			ls -l ${PROPATH}
			rm -Rf ${PROPATH}
			break ;;
		[Nn]* ) 
			echo "	OK, clean manually this:"    
			ls -l ${PROPATH}
			break ;;
    	* ) echo "	Please answer yes [Yy] or no [Nn]." ;;	
    esac	
done
	
echo 
		
# Some cleaning 
while true ; do
	read -p "	Do you want to clean Processing dirs ? "  yn
		case $yn in
		[Yy]* ) 
			for i in `seq 1 ${N}`
				do
					echo "	Removing  ${DISKPATH[$i]}*"
					rm -Rf ${DISKPATH[$i]}*
					echo
			done
			break ;;
		[Nn]* ) 
			echo "	OK, clean manually this:"    
			for i in `seq 1 ${N}`
				do
					echo "	${DISKPATH[$i]}*"
			done
			break ;;
    	* ) echo "	Please answer yes [Yy] or no [Nn]." ;;	
    esac	
done

rm -f ${LISTTOCOREG}_NoSM.txt