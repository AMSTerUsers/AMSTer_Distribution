#!/bin/bash
# Script to run the geocoding of files from a set of pairs computed with ALL2GIF.sh. 
# It will first rename all path in PAIR dirs.
# 
# Need to be run in dir where all AMPLI PAIR DIRS are, 
#   e.g. /.../SAR_SM/AMPLITUDES/SAT/TRK/REGION
#
# Parameters:	- a LaunchParametersForGeocAmpli.txt file where geoproj param are defined. It must contain the folliwng lines 
#		 UTM			# PROJ, Chosen projection (UTM or GEOC - both are ok here)
#		 TRI			# RESAMPMETHD, TRI = Triangulation; AV = weighted average; NN = nearest neighbour
#		 LORENTZ		# WEIGHTMETHD, Weighting method : ID = inverse distance; LORENTZ = lorentzian
#		 1.0			# IDSMOOTH,  ID smoothing factor 
#		 1.0			# IDWEIGHT, ID weighting exponent
#		 1.0			# FWHM, Lorentzian Full Width at Half Maximum
#		 20				# XPIX, Easting sampling [m] if UTM or Longitude sampling [dd] if LatLong
#		 20				# YPIX, Northing sampling [m] if UTM or Latitude sampling [dd] if LatLong
#		pathToKmlFile   # AREAOFINT, Forced footprint of geocoded product : Path_to_a_kml_file or pathToKmlFile to ignore forcing
#
#
# HARD CODED: 	- 
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- __HardCodedLines.sh
#
# New in Distro V 1.1:	- Allows tuning geocoded products (resolution ...) using a param file
# New in Distro V 2.0: - Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20250227:	- replace cp -n with if [ ! -e DEST ] ; then cp SRC DEST ; fi 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Feb 27, 2025"


echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

PARAMFILE=$1

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below:
	# - RenameVolNameToVariable to Rename all path in param files just in case DIR were moved
# ^^^ ----- Hard coded lines to check --- ^^^ 

eval MASSPROCDIR="$(pwd)"

# prepare dir where geocoded results will be stored 
mkdir -p _GEOCAMPLI

# Some fcts
function ChangeGeocParam()
	{
	unset CRITERIA NEW 
	local CRITERIA
	local NEW	
	CRITERIA=$1
	NEW=$2
	
	unset KEY parameterFilePath ORIGINAL
	local KEY
	local parameterFilePath 
	local ORIGINAL
	
	KEY=`echo ${CRITERIA} | tr ' ' _`
	parameterFilePath=./geoProjectionParameters.txt

	ORIGINAL=`updateParameterFile ${parameterFilePath} ${KEY} ${NEW}`
	echo "  // update  ${CRITERIA} = ${NEW}"

	}
	
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
		"InSARParameters.txt") parameterFilePath=${MASSPROCDIR}/${DIR}/i12/TextFiles/InSARParameters.txt ;;
		"SLCImageInfo.txt") parameterFilePath=${MASTERPATH}/Info/SLCImageInfo.txt ;;
		"geoProjectionParameters.txt") parameterFilePath=${MASSPROCDIR}/${DIR}/i12/TextFiles/geoProjectionParameters.txt ;;
	esac
	updateParameterFile ${parameterFilePath} ${KEY}
	}

# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

# Read param file 
PROJ=`GetParam "PROJ,"`						# PROJ, Chosen projection (UTM or GEOC)
XPIX=`GetParam "XPIX,"`						# XPIX, Size of geocoded pixel in East direction (in m if UTM of in dd if LatLong)
YPIX=`GetParam "YPIX,"`						# XPIY, Size of geocoded pixel in North direction (in m if UTM of in dd if LatLong)
RESAMPMETHD=`GetParam "RESAMPMETHD,"`		# TRI = Triangulation; AV = weighted average; NN = nearest neighbour 
WEIGHTMETHD=`GetParam "WEIGHTMETHD,"`		# Weighting method : ID = inverse distance; LORENTZ = lorentzian 
IDSMOOTH=`GetParam "IDSMOOTH,"`				# ID smoothing factor  
IDWEIGHT=`GetParam "IDWEIGHT,"`				# ID weighting exponent 
FWHM=`GetParam "FWHM,"`						# Lorentzian Full Width at Half Maximum
AREAOFINT=`GetParam "AREAOFINT,"`			# AREAOFINT, Forced footprint of geocoded product : Path_to_a_kml_file or pathToKmlFile to ignore forcing

FILENAMING=".${PROJ}.${XPIX}.${YPIX}"
	
# First rename all path in param files just in case DIR were moved
	echo "  // Rename paths..."
	ls -d ????????_????????* | ${PATHGNU}/grep -v ".txt" > Files_To_Rename.txt 

	for DIR in `cat -s Files_To_Rename.txt` 
	do 
		DIRSHORT=`echo ${DIR} | cut -d_ -f1-2`

		cd ${DIR}/i12/TextFiles
		#cp -n InSARParameters.txt InSARParameters_original.txt # do not copy if exist already
		#cp -n geoProjectionParameters.txt geoProjectionParameters_original.txt # do not copy if exist already
		if [ ! -e InSARParameters_original.txt ] ; then cp InSARParameters.txt InSARParameters_original.txt ; fi 
		if [ ! -e geoProjectionParameters_original.txt ] ; then cp geoProjectionParameters.txt geoProjectionParameters_original.txt ; fi 
		
		${PATHGNU}/gsed "s%^.*i12%${MASSPROCDIR}\/${DIR}\/i12%g" InSARParameters_original.txt > InSARParameters.txt
		${PATHGNU}/gsed "s%^.*i12%${MASSPROCDIR}\/${DIR}\/i12%g" geoProjectionParameters_original.txt > geoProjectionParameters.txt

		cp InSARParameters.txt InSARParameters_original_ExtHDpath.txt 
		
		RenameVolNameToVariable InSARParameters_original_ExtHDpath.txt InSARParameters.txt
# 		${PATHGNU}/gsed -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/\$PATH_1650%g 
# 							 s%\/Volumes\/hp-D3600-Data_Share1%\/\$PATH_3600%g 
# 							 s%\/Volumes\/hp-D3601-Data_RAID6%\/\$PATH_3601%g 
# 							 s%\/Volumes\/hp-D3602-Data_RAID5%\/\$PATH_3602%g
# 							 s%\/mnt\/1650%\/\$PATH_1650%g 
# 							 s%\/mnt\/3600%\/\$PATH_3600%g 
# 							 s%\/mnt\/3601%\/\$PATH_3601%g 
# 							 s%\/mnt\/3602%\/\$PATH_3602%g" InSARParameters_original_ExtHDpath.txt > InSARParameters.txt
						 
		cp geoProjectionParameters.txt geoProjectionParameters_original_ExtHDpath.txt 
		RenameVolNameToVariable geoProjectionParameters_original_ExtHDpath.txt geoProjectionParameters.txt
# 			${PATHGNU}/gsed -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/\$PATH_1650%g 
# 								 s%\/Volumes\/hp-D3600-Data_Share1%\/\$PATH_3600%g 
# 								 s%\/Volumes\/hp-D3601-Data_RAID6%\/\$PATH_3601%g 
# 								 s%\/Volumes\/hp-D3602-Data_RAID5%\/\$PATH_3602%g
# 								 s%\/mnt\/1650%\/\$PATH_1650%g 
# 								 s%\/mnt\/3600%\/\$PATH_3600%g 
# 								 s%\/mnt\/3601%\/\$PATH_3601%g 
# 								 s%\/mnt\/3602%\/\$PATH_3602%g" geoProjectionParameters_original_ExtHDpath.txt > geoProjectionParameters.txt
		cd ${MASSPROCDIR}
	done 
	rm -f Files_To_Rename.txt

# geocode 
echo "  // Start geocoding..." 
for DIR in `ls -d ????????_????????* | ${PATHGNU}/grep -v ".txt"` 
do 
	MAS=`echo "${DIR}" | cut -d "_" -f1  ` # select master date
	SLV=`echo "${DIR}" | cut -d "_" -f2  ` # select slave date

	CHECKMAS=`ls ${MASSPROCDIR}/_GEOCAMPLI/${MAS}.*${FILENAMING}* 2> /dev/null | wc -l`
	CHECKSLV=`ls ${MASSPROCDIR}/_GEOCAMPLI/${SLV}.*${FILENAMING}* 2> /dev/null | wc -l`

	if [ ${CHECKSLV} -gt 0 ] 
		then 
			echo "***** Pair ${MAS}_${SLV} already processed as ${FILENAMING}. Skip pair."
		else 
			if [ ${CHECKMAS} -gt 0 ] 
				then 
					# MAS is already geocoded. Skip it
					echo "***** Primary image ${MAS} already geocoded. Skip it and geocode only Secondary image ${SLV}." 
					FILESTOGEOC="NO NO YES NO NO NO NO NO NO"
				else 
					# MAS is not yet geocoded
					echo "***** Geocoding ${MAS} and ${SLV}." 
					FILESTOGEOC="NO YES YES NO NO NO NO NO NO"
			fi
			DEFOMAP=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $1}'`
			MASAMPL=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $2}'`
			SLVAMPL=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $3}'`
			COH=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $4}'`
			INTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $5}'`
			FILTINTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $6}'`
			RESINTERF=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $7}'`
			UNWPHASE=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $8}'`
			INCIDENCE=`echo ${FILESTOGEOC} | ${PATHGNU}/gawk '{print $9}'`	
	
			if [ "${INCIDENCE}" == "YES" ] 
				then 
					echo "  // Will geocode incidence again"
				else 
					echo "  // Temporarily rename indidence to avoid automatic geocoding" 
					if [ -f ${MASSPROCDIR}/${DIR}/i12/InSARProducts/incidence ] ; then mv ${MASSPROCDIR}/${DIR}/i12/InSARProducts/incidence ${MASSPROCDIR}/${DIR}/i12/InSARProducts/BAK_incidence  ; fi
			fi
			echo ""
			# remove possible existing old Projection Map
			rm -f ${MASSPROCDIR}/${DIR}/i12/GeoProjection/projMat.UTM.*

			cd  ${MASSPROCDIR}/${DIR}/i12/TextFiles

			# Update which products to geocode
			ChangeGeocParam "Geoproject measurement" ${DEFOMAP} geoProjectionParameters.txt

			ChangeGeocParam "Geoproject master amplitude" ${MASAMPL} geoProjectionParameters.txt 
			ChangeGeocParam "Geoproject slave amplitude" ${SLVAMPL} geoProjectionParameters.txt

			ChangeGeocParam "Geoproject coherence" ${COH} geoProjectionParameters.txt 
			ChangeGeocParam "Geoproject interferogram" ${INTERF} geoProjectionParameters.txt 
			ChangeGeocParam "Geoproject filtered interferogram" ${FILTINTERF} geoProjectionParameters.txt 
			ChangeGeocParam "Geoproject residual interferogram" ${RESINTERF} geoProjectionParameters.txt 
			ChangeGeocParam "Geoproject unwrapped phase" ${UNWPHASE} geoProjectionParameters.txt 

			# update geoprojection param 
			ChangeGeocParam "Chosen projection (UTM or GEC)" ${PROJ} geoProjectionParameters.txt 		
			if [ "${PROJ}" == "UTM" ] ; then 
					ChangeGeocParam "Easting sampling [m]" ${XPIX} geoProjectionParameters.txt 		
					ChangeGeocParam "Northing sampling [m]" ${YPIX} geoProjectionParameters.txt 		
				else 
					ChangeGeocParam "Longitude sampling [dd]" ${XPIX} geoProjectionParameters.txt 		
					ChangeGeocParam "Latitude sampling [dd] " ${YPIX} geoProjectionParameters.txt 		
			fi
			
			ChangeGeocParam "Geoprojected products generic extension" ${FILENAMING} geoProjectionParameters.txt 		

			ChangeGeocParam "esampling method : TRI = Triangulation; AV = weighted average; NN = nearest neighbour" ${RESAMPMETHD} geoProjectionParameters.txt 		
			ChangeGeocParam "Weighting method : ID = inverse distance; LORENTZ = lorentzian" ${WEIGHTMETHD} geoProjectionParameters.txt 		
			ChangeGeocParam "ID smoothing factor" ${IDSMOOTH} geoProjectionParameters.txt 		
			ChangeGeocParam "ID weighting exponent" ${IDWEIGHT} geoProjectionParameters.txt 		
			ChangeGeocParam "FWHM : Lorentzian Full Width at Half Maximum" ${FWHM} geoProjectionParameters.txt 		
			ChangeGeocParam "Path to a kml file defining the geoProjection area" ${AREAOFINT} geoProjectionParameters.txt 	
			
			MASTERPATH=`GetParamFromFile "Master image file path" InSARParameters.txt `

			cd ${MASSPROCDIR}/${DIR}/i12

			geoProjection -rk ./TextFiles/geoProjectionParameters.txt

			mv ./GeoProjection/* ${MASSPROCDIR}/_GEOCAMPLI/
	
			echo 
			cd  ${MASSPROCDIR}
			
	fi
done 

echo "---------------------------" 
echo " All done... Hope it worked" 
echo "---------------------------" 
